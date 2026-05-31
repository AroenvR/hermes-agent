#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="skill setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common script
. "$SCRIPT_DIR/../../../library/common.sh"

main() {
  set_skill_env_vars $SCRIPT_DIR # Provides $SKILL_NAME, $SKILL_CATEGORY, $DESTINATION_DIR
  log "Setting up $SKILL_NAME"

  copy_missing_files "$SCRIPT_DIR" "$DESTINATION_DIR"
  log "Done"
}

main "$@"