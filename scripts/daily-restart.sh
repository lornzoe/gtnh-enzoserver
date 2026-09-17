#!/bin/bash
# Backs up and then stops the Minecraft server over RCON at RESTART_TIME every day.
# The mc service's restart policy brings it back up (installing any GTNH update).
# Uses RCON_HOST / RCON_PASSWORD from the environment (read by rcon-cli), and the
# mc-backup settings shared with the backups service.

set -uo pipefail

: "${RESTART_TIME:=06:00}"
WARN_SECONDS=300

log() { echo "$(date '+%F %T %Z') $*"; }
say() { rcon-cli say "$*" >/dev/null 2>&1; }

players_online() {
  local count
  count=$(mc-monitor status --host "$RCON_HOST" --show-player-count 2>/dev/null)
  [[ $count =~ ^[0-9]+$ ]] && echo "$count" || echo 0
}

# Runs a one-off backup; succeeds only if a new archive actually appeared, since
# `backup now` exits 0 even when the backup fails.
backup_before_restart() {
  local marker
  marker=$(mktemp)
  backup now
  local status=$?
  local new
  new=$(find /backups -maxdepth 1 -name '*.tar*' -newer "$marker" | head -1)
  rm -f "$marker"
  (( status == 0 )) && [[ -n $new ]]
}

next_restart() {
  local now target
  now=$(date +%s)
  target=$(date -d "today $RESTART_TIME" +%s)
  if (( target - WARN_SECONDS <= now )); then
    target=$(date -d "tomorrow $RESTART_TIME" +%s)
  fi
  echo "$target"
}

while true; do
  target=$(next_restart)
  log "Next restart at $(date -d "@$target" '+%F %T %Z')"

  # Poll instead of one long sleep so a suspended host doesn't delay the restart
  while (( $(date +%s) < target - WARN_SECONDS )); do
    sleep 30
  done

  if (( $(players_online) > 0 )); then
    log "Players online, warning before restart"
    say "Server restarting in 5 minutes"
    sleep $(( WARN_SECONDS - 60 ))
    say "Server restarting in 1 minute"
    sleep 50
    for i in {10..1}; do
      say "Server restarting in $i..."
      sleep 1
    done
  else
    sleep "$WARN_SECONDS"
  fi

  log "Backing up before restart"
  say "Backing up before restart..."
  if ! backup_before_restart; then
    log "Backup failed, skipping today's restart so an update can't run without a backup"
    say "Pre-restart backup failed, restart skipped"
    sleep 60
    continue
  fi

  log "Stopping server"
  if ! rcon-cli stop; then
    log "RCON stop failed (server already down?)"
  fi
  sleep 60
done
