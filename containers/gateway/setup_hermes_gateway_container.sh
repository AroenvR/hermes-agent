#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../../.env.safe"

if [[ ! -f "$ENV_FILE" ]]; then
  printf 'ERROR: expected env file not found: %s\n' "$ENV_FILE" >&2
  exit 1
fi

# Load safe env
. "$ENV_FILE"

QUADLET_DIR="$HOME/.config/containers/systemd"
IMAGE_NAME="localhost/hermes:$CURRENT_TAG"

log() { printf '[gateway-setup] %s\n' "$*"; }
fail() { printf '[gateway-setup] ERROR: %s\n' "$*" >&2; exit 1; }

# Pre-flight: image must exist before systemd tries to start a container from it.
if ! podman image exists "$IMAGE_NAME"; then
  fail "Image '$IMAGE_NAME' not found. Build it first with: podman build --tag $IMAGE_NAME -f /path/to/Containerfile ."
fi

mkdir -p "$QUADLET_DIR"

# Always overwrite — file is the source of truth.
sed "s|__CURRENT_TAG__|$CURRENT_TAG|g" \
  "$SCRIPT_DIR/hermes-gateway.container" \
  > "$QUADLET_DIR/hermes-gateway.container"
log "Installed hermes-gateway.container"

# Stop the existing service (if any) so the next start uses the new spec cleanly.
systemctl --user stop hermes-gateway.service 2>/dev/null || true
log "Stopped existing hermes-gateway service (if any)"

# Reload systemd to pick up the new/changed unit definition.
systemctl --user daemon-reload
log "Reloaded systemd user units"

# Start the service.
systemctl --user start hermes-gateway.service
log "Started hermes-gateway"

# Show status.
systemctl --user status hermes-gateway.service --no-pager | head -10