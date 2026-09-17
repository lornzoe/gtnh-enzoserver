#!/bin/bash
# Reapplies server config tweaks on every start, since GTNH updates replace config/.
# Each tweak rewrites an existing Forge-style "T:key=value" line; missing files or
# keys are reported and skipped.

set -uo pipefail

log() { echo "[apply-config] $*"; }

# set_cfg FILE KEY VALUE, where KEY includes the type prefix, e.g. I:autoPlaceBudget
set_cfg() {
  local file=$1 key=$2 value=$3
  if [[ ! -f $file ]]; then
    log "WARN: $file not found, skipping $key"
    return
  fi
  if ! grep -qE "^\s*${key}=" "$file"; then
    log "WARN: $key not found in $file, skipping"
    return
  fi
  sed -i -E "s/^(\s*)${key}=.*/\1${key}=${value}/" "$file"
  log "$file: $key=$value"
}

# StructureLib hologram projector auto place (interval is in milliseconds)
set_cfg /data/config/structurelib.cfg I:autoPlaceBudget 200
set_cfg /data/config/structurelib.cfg I:autoPlaceInterval 50

# ServerUtilities chunk claiming
set_cfg /data/serverutilities/serverutilities.cfg B:chunk_claiming true
