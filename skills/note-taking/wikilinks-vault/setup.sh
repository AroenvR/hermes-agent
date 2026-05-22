#!/usr/bin/env bash
set -euo pipefail

echo
echo "Setting up the wikilinks-vault skill"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target Hermes home.
#
# Default:
#   /home/$USER/hermes
#
# Override if needed:
#   HERMES_HOME=/some/path bash setup.sh
HERMES_HOME="${HERMES_HOME:-/home/$USER/hermes}"

SKILL_DIR="$HERMES_HOME/skills/note-taking/wikilinks-vault"
VAULT_DIR="$HERMES_HOME/vault"

SOURCE_SKILL_MD="$SCRIPT_DIR/SKILL.md"
DEST_SKILL_MD="$SKILL_DIR/SKILL.md"

SOURCE_INDEX_MD="$SCRIPT_DIR/INDEX.md"
DEST_INDEX_MD="$VAULT_DIR/INDEX.md"

SOURCE_TODO_MD="$SCRIPT_DIR/TODO.md"
DEST_TODO_MD="$VAULT_DIR/TODO.md"

log() {
  printf '[wikilinks-vault] %s\n' "$*"
}

fail() {
  printf '[wikilinks-vault] ERROR: %s\n' "$*" >&2
  exit 1
}

ensure_dir() {
  local dir="$1"

  if [[ -d "$dir" ]]; then
    log "Directory exists, leaving unchanged: $dir"
    return 0
  fi

  if [[ -e "$dir" ]]; then
    fail "Path exists but is not a directory: $dir"
  fi

  mkdir -p "$dir"
  log "Created directory: $dir"
}

copy_file_if_missing() {
  local src="$1"
  local dest="$2"

  [[ -f "$src" ]] || fail "Source file is missing: $src"

  if [[ -f "$dest" ]]; then
    log "File exists, leaving unchanged: $dest"
    return 0
  fi

  if [[ -e "$dest" ]]; then
    fail "Path exists but is not a regular file: $dest"
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  log "Created file: $dest"
}

main() {
  log "USER: $USER"
  log "HERMES_HOME: $HERMES_HOME"
  log "Source skill: $SOURCE_SKILL_MD"
  log "Skill destination: $SKILL_DIR"
  log "Vault destination: $VAULT_DIR"

  ensure_dir "$SKILL_DIR"
  copy_file_if_missing "$SOURCE_SKILL_MD" "$DEST_SKILL_MD"

  ensure_dir "$VAULT_DIR"
  copy_file_if_missing "$SOURCE_INDEX_MD" "$DEST_INDEX_MD"
  copy_file_if_missing "$SOURCE_TODO_MD" "$DEST_TODO_MD"

  log "Done"
}

main "$@"
