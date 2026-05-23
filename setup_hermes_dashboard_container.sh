#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUADLET_DIR="$HOME/.config/containers/systemd"

log() { printf '[dashboard-setup] %s\n' "$*"; }

mkdir -p "$QUADLET_DIR"

# Always overwrite — file is the source of truth.
cp "$SCRIPT_DIR/hermes-dashboard.container" "$QUADLET_DIR/hermes-dashboard.container"
log "Installed hermes-dashboard.container"

# Reload systemd to pick up the new/changed unit definition.
systemctl --user daemon-reload
log "Reloaded systemd user units"

# Restart the service to apply.
systemctl --user restart hermes-dashboard.service
log "Restarted hermes-dashboard"

# Show status.
systemctl --user status hermes-dashboard.service --no-pager | head -10

log "Open an SSH tunnel with 'ssh -L 9119:127.0.0.1:9119 USER@SERVER_IP' to access the dashboard on your local machine at http://127.0.0.1:9119/kanban"