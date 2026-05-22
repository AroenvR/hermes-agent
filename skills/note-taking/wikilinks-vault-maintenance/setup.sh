#!/usr/bin/env bash
set -euo pipefail

echo
echo "Setting up the wikilinks-vault-maintenance skill"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target Hermes home.
#
# Default:
#   /home/$USER/hermes
#
# Override if needed:
#   HERMES_HOME=/some/path bash setup.sh
HERMES_HOME="${HERMES_HOME:-/home/$USER/hermes}"

SKILL_DIR="$HERMES_HOME/skills/note-taking/wikilinks-vault-maintenance"
VAULT_DIR="$HERMES_HOME/vault"

SOURCE_SKILL_MD="$SCRIPT_DIR/SKILL.md"
DEST_SKILL_MD="$SKILL_DIR/SKILL.md"

SOURCE_GITIGNORE="$SCRIPT_DIR/gitignore"
DEST_GITIGNORE="$VAULT_DIR/.gitignore"

log() {
  printf '[wikilinks-vault-maintenance] %s\n' "$*"
}

fail() {
  printf '[wikilinks-vault-maintenance] ERROR: %s\n' "$*" >&2
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

ensure_git_available() {
  if ! command -v git >/dev/null 2>&1; then
    fail "git is not available on PATH"
  fi
}

ensure_git_repo() {
  ensure_git_available
  ensure_dir "$VAULT_DIR"

  if git -C "$VAULT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Git repository exists, leaving unchanged: $VAULT_DIR"
  else
    git -C "$VAULT_DIR" init
    log "Initialized git repository: $VAULT_DIR"
  fi

  if git -C "$VAULT_DIR" config --get user.name >/dev/null; then
    log "Git user.name already configured, leaving unchanged"
  else
    git -C "$VAULT_DIR" config user.name "Maintainer"
    log "Configured git user.name: Maintainer"
  fi

  if git -C "$VAULT_DIR" config --get user.email >/dev/null; then
    log "Git user.email already configured, leaving unchanged"
  else
    git -C "$VAULT_DIR" config user.email "maintainer@hermes.local"
    log "Configured git user.email: maintainer@hermes.local"
  fi
}

merge_gitignore_if_missing() {
  [[ -f "$SOURCE_GITIGNORE" ]] || fail "Source gitignore is missing: $SOURCE_GITIGNORE"

  if [[ ! -f "$DEST_GITIGNORE" ]]; then
    cp "$SOURCE_GITIGNORE" "$DEST_GITIGNORE"
    log "Created file: $DEST_GITIGNORE"
    return 0
  fi

  if [[ -e "$DEST_GITIGNORE" && ! -f "$DEST_GITIGNORE" ]]; then
    fail "Path exists but is not a regular file: $DEST_GITIGNORE"
  fi

  local changed=0
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Keep the merge simple:
    # - ignore blank lines from the source
    # - append only entries that are not already present exactly
    [[ -n "$line" ]] || continue

    if ! grep -Fxq "$line" "$DEST_GITIGNORE"; then
      printf '%s\n' "$line" >> "$DEST_GITIGNORE"
      changed=1
    fi
  done < "$SOURCE_GITIGNORE"

  if [[ "$changed" -eq 1 ]]; then
    log "Updated file with missing gitignore entries: $DEST_GITIGNORE"
  else
    log "Gitignore already contains required entries, leaving unchanged: $DEST_GITIGNORE"
  fi
}

main() {
  log "USER: $USER"
  log "HERMES_HOME: $HERMES_HOME"
  log "Source skill: $SOURCE_SKILL_MD"
  log "Skill destination: $SKILL_DIR"
  log "Vault destination: $VAULT_DIR"

  ensure_dir "$SKILL_DIR"
  copy_file_if_missing "$SOURCE_SKILL_MD" "$DEST_SKILL_MD"

  ensure_git_repo
  merge_gitignore_if_missing

  log "Done"
}

main "$@"