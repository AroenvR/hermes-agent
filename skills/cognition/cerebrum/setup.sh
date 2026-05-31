#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="skill setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common script
. "$SCRIPT_DIR/../../../library/common.sh"

main() {
  set_skill_env_vars $SCRIPT_DIR # Provides $SKILL_NAME, $SKILL_CATEGORY, $DESTINATION_DIR

  log "Setting up $SKILL_NAME"

  ensure_dir "$DESTINATION_DIR"
  copy_missing_files $SCRIPT_DIR $DESTINATION_DIR

  # copy_file_if_missing "$SCRIPT_DIR/SKILL.md" "$DESTINATION_DIR/SKILL.md"

  # REFERENCES="references"
  # ensure_dir "$DESTINATION_DIR/$REFERENCES"
  # copy_file_if_missing "$SCRIPT_DIR/$REFERENCES/archiving.md" "$DESTINATION_DIR/$REFERENCES/archiving.md"
  # copy_file_if_missing "$SCRIPT_DIR/$REFERENCES/maintenance.md" "$DESTINATION_DIR/$REFERENCES/maintenance.md"
  # copy_file_if_missing "$SCRIPT_DIR/$REFERENCES/retrieval.md" "$DESTINATION_DIR/$REFERENCES/retrieval.md"
  # copy_file_if_missing "$SCRIPT_DIR/$REFERENCES/tooling.md" "$DESTINATION_DIR/$REFERENCES/tooling.md"

  # SCRIPTS="scripts"
  # ensure_dir "$DESTINATION_DIR/$SCRIPTS"
  # copy_file_if_missing "$SCRIPT_DIR/$SCRIPTS/make_metadata.py" "$DESTINATION_DIR/$SCRIPTS/make_metadata.py"

  log "Done"
}

main "$@"