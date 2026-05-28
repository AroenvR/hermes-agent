#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load safe env
. "$SCRIPT_DIR/../../.env.safe"

QUADLET_DIR="$HOME/.config/containers/systemd"
IMAGE_NAME="localhost/hermes:$CURRENT_TAG"

log() { printf '[dashboard-setup] %s\n' "$*"; }
fail() { printf '[dashboard-setup] ERROR: %s\n' "$*" >&2; exit 1; }

# Pre-flight: image must exist before systemd tries to start a container from it.
if ! podman image exists "$IMAGE_NAME"; then
  fail "Image '$IMAGE_NAME' not found. Build it first with: podman build --tag $IMAGE_NAME -f /path/to/Containerfile ."
fi

mkdir -p "$QUADLET_DIR"

# Always overwrite — file is the source of truth.
sed "s|__CURRENT_TAG__|$CURRENT_TAG|g" \
  "$SCRIPT_DIR/hermes-dashboard.container" \
  > "$QUADLET_DIR/hermes-dashboard.container"
log "Installed hermes-dashboard.container"

# Stop the existing service (if any) so the next start uses the new spec cleanly.
systemctl --user stop hermes-dashboard.service 2>/dev/null || true
log "Stopped existing hermes-dashboard service (if any)"

# Reload systemd to pick up the new/changed unit definition.
systemctl --user daemon-reload
log "Reloaded systemd user units"

# Start the service.
systemctl --user start hermes-dashboard.service
log "Started hermes-dashboard"

# Show status.
systemctl --user status hermes-dashboard.service --no-pager | head -10

log "Open an SSH tunnel with 'ssh -L 9119:127.0.0.1:9119 USER@SERVER_IP' to access the dashboard on your local machine at http://127.0.0.1:9119"