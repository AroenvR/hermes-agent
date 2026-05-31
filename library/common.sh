#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CURRENT_SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env.safe"

log() {
  printf '[%s] %s\n' "${SCRIPT_NAME:-script}" "$*"
}

fail() {
  printf '[%s] ERROR: %s\n' "${SCRIPT_NAME:-script}" "$*" >&2
  exit 1
}

require_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    fail "Expected file not found: $file"
  fi
}

ensure_dir() {
  local dir="$1"
  log "Ensuring directory: $dir"

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

require_var() {
  local var_name="$1"

  if [[ -z "${!var_name:-}" ]]; then
    fail "$var_name must be set"
  fi
}

set_skill_env_vars() {
  local start_dir="$1"
  [[ -n "$start_dir" ]] || fail "skill_self_locate: no start directory given"
  [[ -d "$start_dir" ]] || fail "skill_self_locate: not a directory: $start_dir"

  require_var HERMES_HOME

  local skill_dir="$start_dir"
  local dir="$start_dir"
  local parent

  # Walk up until the parent of the current dir is named "skills".
  while true; do
    parent="$(dirname "$dir")"
    if [[ "$(basename "$parent")" == "skills" ]]; then
      SKILL_CATEGORY="$(basename "$(dirname "$dir")")"   # placeholder; see note
      break
    fi
    if [[ "$parent" == "$dir" ]]; then
      fail "skill_self_locate: no 'skills' ancestor found above $start_dir"
    fi
    dir="$parent"
  done

  SKILL_NAME="$(basename "$skill_dir")"
  log "Located skill: $SKILL_NAME"

  SKILL_CATEGORY="$(basename "$dir")"
  log "Skill category: $SKILL_CATEGORY"

  DESTINATION_DIR="$HERMES_HOME/skills/$SKILL_CATEGORY/$SKILL_NAME"
  log "Skill destination: '$DESTINATION_DIR'"
}

require_file "$ENV_FILE"

# shellcheck source=/dev/null
. "$ENV_FILE"