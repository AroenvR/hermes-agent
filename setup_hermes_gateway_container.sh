#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUADLET_DIR="$HOME/.config/containers/systemd"

log() { printf '[gateway-setup] %s\n' "$*"; }

mkdir -p "$QUADLET_DIR"

# Always overwrite — file is the source of truth.
cp "$SCRIPT_DIR/hermes-gateway.container" "$QUADLET_DIR/hermes-gateway.container"
log "Installed hermes-gateway.container"

# Reload systemd to pick up the new/changed unit definition.
systemctl --user daemon-reload
log "Reloaded systemd user units"

# Restart the service to apply.
systemctl --user restart hermes-gateway.service
log "Restarted hermes-gateway"

# Show status.
systemctl --user status hermes-gateway.service --no-pager | head -10