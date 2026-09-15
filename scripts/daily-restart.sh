#!/bin/bash
# Stops the Minecraft server over RCON at RESTART_TIME every day.
# The mc service's restart policy brings it back up.
# Uses RCON_HOST / RCON_PASSWORD from the environment (read by rcon-cli).

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

  log "Stopping server"
  if ! rcon-cli stop; then
    log "RCON stop failed (server already down?)"
  fi
  sleep 60
done
