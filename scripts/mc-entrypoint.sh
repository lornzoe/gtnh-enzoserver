#!/bin/bash
# Entrypoint for the mc service. GTNH updates replace config/ and mods/, so config
# tweaks are applied between setup (install/update, MODS downloads) and launch.

set -euo pipefail

# Pass 1: set up the server and exit before Java starts. RCON_CMDS_STARTUP is
# blanked so the RCON commands daemon only starts once, in pass 2.
SETUP_ONLY=true RCON_CMDS_STARTUP= /image/scripts/start

bash /scripts/apply-config.sh

# The image's default MOTD shows GTNH_PACK_VERSION as written (e.g. latest-beta), so
# use the installed version instead, e.g. GT_New_Horizons_2.9.0-beta-3_Server_... -> 2.9.0-beta-3
if [[ -z ${MOTD:-} && -f /data/.gtnh-version ]]; then
  gtnh_version=$(sed -E 's/^GT_New_Horizons_(.+)_Server.*/\1/' /data/.gtnh-version)
  export MOTD="GT New Horizons ${gtnh_version}"
  echo "[mc-entrypoint] MOTD=$MOTD"
fi

# Pass 2: the pack is already current, so this goes straight to launching the server.
exec /image/scripts/start
