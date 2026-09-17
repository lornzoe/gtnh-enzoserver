#!/bin/bash
# Entrypoint for the mc service. GTNH updates replace config/ and mods/, so config
# tweaks are applied between setup (install/update, MODS downloads) and launch.

set -euo pipefail

# Pass 1: set up the server and exit before Java starts. RCON_CMDS_STARTUP is
# blanked so the RCON commands daemon only starts once, in pass 2.
SETUP_ONLY=true RCON_CMDS_STARTUP= /image/scripts/start

bash /scripts/apply-config.sh

# Pass 2: the pack is already current, so this goes straight to launching the server.
exec /image/scripts/start
