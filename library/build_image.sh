#!/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env.safe"

if [[ ! -f "$ENV_FILE" ]]; then
  printf 'ERROR: expected env file not found: %s\n' "$ENV_FILE" >&2
  exit 1
fi

# Load safe env
. "$ENV_FILE"

# Build a completely new image
podman build --no-cache --pull=always --tag hermes:$CURRENT_TAG .

# Check the image was built successfully and output its versions
podman run --rm -it hermes:$CURRENT_TAG bash -lc '
  whoami
  node --version
  python3 --version
  command -v hermes
  hermes --version || hermes version || true
'
