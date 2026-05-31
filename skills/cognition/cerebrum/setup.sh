#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="skill setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common script
. "$SCRIPT_DIR/../../../library/common.sh"

# require_var HERMES_HOME
# SKILL_DIR="$HERMES_HOME/skills/cognition/cerebrum"

# SOURCE_SKILL_MD="$SCRIPT_DIR/SKILL.md"
# DEST_SKILL_MD="$SKILL_DIR/SKILL.md"

main() {
  read a b c < <(skill_self_locate $SCRIPT_DIR)
  
  log "Setting up $SKILL_NAME"

  log "a: $a, b: $b, c: $c"

  # ensure_dir "$DESTINATION_DIR"
#   copy_file_if_missing "$SOURCE_SKILL_MD" "$DEST_SKILL_MD"

#   copy_file_if_missing "$SOURCE_INDEX_MD" "$DEST_INDEX_MD"
#   copy_file_if_missing "$SOURCE_TODO_MD" "$DEST_TODO_MD"

  log "Done"
}

main "$@"