#!/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load safe env
. "$SCRIPT_DIR/../.env.safe"

echo $CURRENT_TAG
echo $HERMES_HOME

# # Build a completely new image
# podman build --no-cache --pull=always --tag hermes:$CURRENT_TAG .

# # Check the image was built successfully and output its versions
# podman run --rm -it hermes:$CURRENT_TAG bash -lc '
#   whoami
#   node --version
#   python3 --version
#   command -v hermes
#   hermes --version || hermes version || true
# '
