# TODO:
# - This script should create the wikilinks-vault skill (~/hermes/skills/note-taking/wikilinks-vault)
# - This script should copy the SKILL.md file to the skill's directory
# - This script should check if the wikilinks' vault directory exists, and if it does not, it should create it (just incase this script is not ran first, and another skill already created the directory).
# - This script should create the empty /vault/INDEX.md file
# - This script should create the empty /vault/TODO.md file

#!/usr/bin/env bash
set -euo pipefail

echo "Setting up the wikilinks-vault skill"

# Source directory: the directory this script lives in.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Runtime Hermes home.
# Override with HERMES_HOME=/some/path if needed.
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

# Installed skill destination.
SKILL_DEST_DIR="$HERMES_HOME/skills/note-taking/wikilinks-vault"

# Wikilinks vault destination.
VAULT_DIR="$HERMES_HOME/vault"

SKILL_SRC_FILE="$SCRIPT_DIR/SKILL.md"
SKILL_DEST_FILE="$SKILL_DEST_DIR/SKILL.md"

log() {
  printf '[wikilinks-vault] %s\n' "$*"
}

fail() {
  printf '[wikilinks-vault] ERROR: %s\n' "$*" >&2
  exit 1
}

create_file_if_missing() {
  local file="$1"

  if [[ -e "$file" ]]; then
    log "Exists, leaving unchanged: $file"
    return 0
  fi

  mkdir -p "$(dirname "$file")"
  : > "$file"
  log "Created: $file"
}

main() {
  [[ -f "$SKILL_SRC_FILE" ]] || fail "Missing source SKILL.md: $SKILL_SRC_FILE"

  mkdir -p "$SKILL_DEST_DIR"
  log "Ensured skill directory: $SKILL_DEST_DIR"

  if [[ -e "$SKILL_DEST_FILE" ]]; then
    log "SKILL.md already exists, leaving unchanged: $SKILL_DEST_FILE"
  else
    cp "$SKILL_SRC_FILE" "$SKILL_DEST_FILE"
    log "Installed SKILL.md: $SKILL_DEST_FILE"
  fi

  mkdir -p "$VAULT_DIR"
  log "Ensured vault directory: $VAULT_DIR"

  create_file_if_missing "$VAULT_DIR/INDEX.md"
  create_file_if_missing "$VAULT_DIR/TODO.md"

  log "Done"
}

main "$@"
