#!/usr/bin/bash
set -e

# Load safe env
. .env.safe

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
