#!/usr/bin/bash
set -e

SCRIPT_NAME="build_image"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common script
. "$SCRIPT_DIR/../library/common.sh"
require_var CURRENT_TAG

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
