#!/usr/bin/env bash
set -euo pipefail

echo
echo "Setting up the wikilinks-vault-maintenance skill"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Hermes home.
# Override if needed:
#   HERMES_HOME=/some/path bash setup.sh
HERMES_HOME="${HERMES_HOME:-/home/$USER/hermes}"

SKILL_DIR="$HERMES_HOME/skills/note-taking/wikilinks-vault-maintenance"
VAULT_DIR="$HERMES_HOME/vault"
LOG_DIR="$HERMES_HOME/logs"

SOURCE_SKILL_MD="$SCRIPT_DIR/SKILL.md"
DEST_SKILL_MD="$SKILL_DIR/SKILL.md"

SOURCE_GITIGNORE="$SCRIPT_DIR/gitignore"
DEST_GITIGNORE="$VAULT_DIR/.gitignore"

CRON_NAME="wikilinks-vault-maintenance"
CRON_BEGIN="# BEGIN $CRON_NAME"
CRON_END="# END $CRON_NAME"
CRON_LOG="$LOG_DIR/$CRON_NAME.log"

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

merge_gitignore() {
  [[ -f "$SOURCE_GITIGNORE" ]] || fail "Source gitignore is missing: $SOURCE_GITIGNORE"

  if [[ ! -f "$DEST_GITIGNORE" ]]; then
    cp "$SOURCE_GITIGNORE" "$DEST_GITIGNORE"
    log "Created gitignore: $DEST_GITIGNORE"
    return 0
  fi

  if [[ ! -w "$DEST_GITIGNORE" ]]; then
    fail "Existing .gitignore is not writable: $DEST_GITIGNORE"
  fi

  local changed=0
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue

    if ! grep -Fxq "$line" "$DEST_GITIGNORE"; then
      printf '%s\n' "$line" >> "$DEST_GITIGNORE"
      changed=1
    fi
  done < "$SOURCE_GITIGNORE"

  if [[ "$changed" -eq 1 ]]; then
    log "Updated gitignore with missing entries: $DEST_GITIGNORE"
  else
    log "Gitignore already contains required entries: $DEST_GITIGNORE"
  fi
}

ensure_git_repo() {
  ensure_dir "$VAULT_DIR"

  if git -C "$VAULT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Git repository exists, leaving unchanged: $VAULT_DIR"
  else
    git -C "$VAULT_DIR" init
    log "Initialized git repository: $VAULT_DIR"
  fi

  # Local repo identity only. Do not overwrite if already configured.
  if ! git -C "$VAULT_DIR" config --get user.name >/dev/null; then
    git -C "$VAULT_DIR" config user.name "Maintainer"
    log "Configured git user.name: Maintainer"
  else
    log "Git user.name already configured, leaving unchanged"
  fi

  if ! git -C "$VAULT_DIR" config --get user.email >/dev/null; then
    git -C "$VAULT_DIR" config user.email "maintainer@hermes.local"
    log "Configured git user.email: maintainer@hermes.local"
  else
    log "Git user.email already configured, leaving unchanged"
  fi
}

install_cron_job() {
  local hermes_bin
  hermes_bin="$(command -v hermes || true)"

  if [[ -z "$hermes_bin" ]]; then
    log "Hermes CLI not found on PATH; skipping cron setup."
    log "Install cron manually after Hermes is available."
    return 0
  fi

  ensure_dir "$LOG_DIR"

  local cron_command
  cron_command="0 3 * * * HERMES_HOME=\"$HERMES_HOME\" \"$hermes_bin\" chat -Q -s wikilinks-vault,wikilinks-vault-maintenance -q 'Run the canonical wikilinks vault maintenance flow for the vault at $VAULT_DIR. Respect the skill rules: local git only, no remotes, no branches, no history rewriting, process bounded TODO/inbox work, write a maintenance log, and advance the maintenance marker only after a successful run.' >> \"$CRON_LOG\" 2>&1"

  local existing_cron
  existing_cron="$(crontab -l 2>/dev/null || true)"

  # Remove any previous managed block, then append the current one.
  {
    printf '%s\n' "$existing_cron" \
      | sed "/^$CRON_BEGIN$/,/^$CRON_END$/d" \
      | sed '/^[[:space:]]*$/N;/^\n$/D'

    printf '%s\n' "$CRON_BEGIN"
    printf '%s\n' "$cron_command"
    printf '%s\n' "$CRON_END"
  } | crontab -

  log "Installed nightly cron job: $CRON_NAME"
  log "Cron log: $CRON_LOG"
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
  merge_gitignore
  install_cron_job

  log "Done"
}

main "$@"


# TODO:
# - This script should create the wikilinks-vault-maintenance skill (~/hermes/skills/note-taking/wikilinks-vault-maintenance)
# - This script should copy the SKILL.md file to the skill's directory
# - This script should check if the wikilinks' vault directory exists, and if it does not, it should create it (just incase this script is ran first).
# - This script should initialize a git repository inside the wikilinks' vault directory (or at least ensure it exists, incase it does not yet)
# - This script should copy the `gitignore` file to the wikilinks' vault directory as `.gitignore`.
# - This script should setup a nightly cron job to kickstart this skill.