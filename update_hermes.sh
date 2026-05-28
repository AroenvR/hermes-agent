#!/usr/bin/env bash
set -e

# load env (only safe if .env.safe contains simple VAR=value lines)
. .env.safe

echo $CURRENT_TAG

# podman build --no-cache --pull=always --tag hermes:$CURRENT_TAG .

# podman run --rm -it hermes:$CURRENT_TAG bash -lc '
#   whoami
#   node --version
#   python3 --version
#   command -v hermes
#   hermes --version || hermes version || true
# '
