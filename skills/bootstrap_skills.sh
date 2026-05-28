#!/usr/bin/env bash
set -euo pipefail

# Run every skill setup script under this skills directory.
#
# Expected layout:
#   skills/
#     bootstrap_skills.sh
#     <category>/
#       <skill-name>/
#         setup.sh
#
# This script does not install, copy, link, or modify skills directly.
# Each skill's setup.sh is responsible for its own setup behavior.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common script
. "$SCRIPT_DIR/../library/common.sh"

log() {
  printf '[bootstrap-skills] %s\n' "$*"
}

fail() {
  printf '[bootstrap-skills] ERROR: %s\n' "$*" >&2
  exit 1
}

run_setup() {
  local setup_file="$1"
  local skill_dir
  skill_dir="$(dirname "$setup_file")"

  local rel_path
  rel_path="${skill_dir#"$SCRIPT_DIR"/}"

  log "Running setup: $rel_path"

  (
    cd "$skill_dir"
    bash "./setup.sh"
  )
}

main() {
  [[ -d "$SCRIPT_DIR" ]] || fail "Could not determine skills directory: $SCRIPT_DIR"

  local found=0

  while IFS= read -r -d '' setup_file; do
    found=$((found + 1))
    run_setup "$setup_file"
  done < <(
    find "$SCRIPT_DIR" \
      -mindepth 3 \
      -maxdepth 3 \
      -type f \
      -name 'setup.sh' \
      -print0 \
      | sort -z
  )

  if [[ "$found" -eq 0 ]]; then
    log "No skill setup files found."
    return 0
  fi

  log "Completed $found skill setup script(s)."
}

main "$@"
