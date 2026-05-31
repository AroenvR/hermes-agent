#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="skill setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common script
. "$SCRIPT_DIR/../../../library/common.sh"

main() {
  set_skill_env_vars $SCRIPT_DIR

  log "Setting up $SKILL_NAME"

  ensure_dir "$DESTINATION_DIR"
  copy_file_if_missing "$SCRIPT_DIR/SKILL.md" "$DESTINATION_DIR/SKILL.md"

  log "Done"
}

main "$@"