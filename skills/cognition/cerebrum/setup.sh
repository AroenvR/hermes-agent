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
#   log "USER: $USER"
#   log "HERMES_HOME: $HERMES_HOME"
#   log "Source skill: $SOURCE_SKILL_MD"
#   log "Skill destination: $SKILL_DIR"

  skill_self_locate $SCRIPT_DIR

#   ensure_dir "$SKILL_DIR"
#   copy_file_if_missing "$SOURCE_SKILL_MD" "$DEST_SKILL_MD"

#   copy_file_if_missing "$SOURCE_INDEX_MD" "$DEST_INDEX_MD"
#   copy_file_if_missing "$SOURCE_TODO_MD" "$DEST_TODO_MD"

  log "Done"
}

main "$@"