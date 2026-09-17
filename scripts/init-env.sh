#!/bin/bash
# Creates .env with a random RCON password if it doesn't exist yet.
# Runs as the init-env service before the other services start; /stack is the repo.

set -euo pipefail

env_file=/stack/.env

if [[ -e $env_file ]]; then
  echo "[init-env] $env_file exists, leaving it alone"
  exit 0
fi

password=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')

tmp=$(mktemp /stack/.env.XXXXXX)
echo "RCON_PASSWORD=$password" > "$tmp"
chmod 600 "$tmp"
# Match the repo's owner rather than root, so compose on the host can read it
chown --reference=/stack "$tmp"
mv "$tmp" "$env_file"

echo "[init-env] Created $env_file with a new RCON password"
