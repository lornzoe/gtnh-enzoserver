#!/bin/bash
# Deletes all but the newest KEEP backups in backups/ (default 20, about 5 days at 6h).
# Runs inside the backups container because backups/ is owned by root.
# Usage: scripts/prune-backups.sh [--dry-run]    KEEP=N scripts/prune-backups.sh

set -euo pipefail

cd "$(dirname "$0")/.."

KEEP="${KEEP:-20}"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

if ! [[ $KEEP =~ ^[0-9]+$ ]] || (( KEEP < 1 )); then
  echo "KEEP must be a positive integer" >&2
  exit 1
fi

docker compose exec -T -e KEEP="$KEEP" -e DRY_RUN="$DRY_RUN" backups bash -c '
  shopt -s nullglob
  files=(/backups/*.tar*)
  (( ${#files[@]} )) || { echo "No backups found"; exit 0; }
  mapfile -t old < <(ls -1t -- "${files[@]}" | tail -n +$((KEEP + 1)))
  echo "${#files[@]} backups, keeping newest $KEEP, ${#old[@]} to delete"
  (( ${#old[@]} )) || exit 0
  if [[ $DRY_RUN == true ]]; then
    printf "  would delete %s\n" "${old[@]}"
  else
    rm -v -- "${old[@]}"
  fi
'
