#!/bin/bash
# Loads /stack.env (the repo's .env) into the environment, then runs the given command.
# Read at runtime because compose substitutes ${...} before init-env has created .env.

set -euo pipefail

set -a
# shellcheck source=/dev/null
. /stack.env
set +a

exec "$@"
