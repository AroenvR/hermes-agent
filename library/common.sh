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
  local fn_name="set_skill_env_vars"

  local start_dir="$1"
  [[ -n "$start_dir" ]] || fail "$fn_name: no start directory given"
  [[ -d "$start_dir" ]] || fail "$fn_name: not a directory: $start_dir"

  require_var HERMES_HOME
  require_var PROJECT_ROOT

  local skill_dir
  local dir
  local parent
  local max_steps=5
  local step

  skill_dir="$(cd -- "$start_dir" && pwd -P)" ||
    fail "$fn_name: could not resolve directory: $start_dir"

  dir="$skill_dir"

  for ((step = 0; step <= max_steps; step++)); do
    if [[ "$dir" == "$PROJECT_ROOT" ]]; then
      fail "$fn_name: reached PROJECT_ROOT without finding skills ancestor: $start_dir"
    fi

    if [[ "$dir" == "$HOME" ]]; then
      fail "$fn_name: reached HOME without finding skills ancestor: $start_dir"
    fi

    parent="$(dirname "$dir")"

    if [[ "$(basename "$parent")" == "skills" ]]; then
      SKILL_CATEGORY="$(basename "$dir")"
      break
    fi

    if [[ "$parent" == "$dir" ]]; then
      fail "$fn_name: reached filesystem root without finding skills ancestor: $start_dir"
    fi

    dir="$parent"
  done

  [[ -n "${SKILL_CATEGORY:-}" ]] ||
    fail "$fn_name: no 'skills' ancestor found within $max_steps levels above $start_dir"

  SKILL_NAME="$(basename "$skill_dir")"
  DESTINATION_DIR="$HERMES_HOME/skills/$SKILL_CATEGORY/$SKILL_NAME"

  log "Located skill: $SKILL_NAME - category: $SKILL_CATEGORY"
}

copy_missing_files() {
  local src="$1"
  local dest="$2"

  [[ -d "$src" ]] || fail "Source directory is missing: $src"

  if [[ -e "$dest" && ! -d "$dest" ]]; then
    fail "Path exists but is not a directory: $dest"
  fi

  ensure_dir "$dest"

  # Recurse into subdirectories first, then copy files at this level.
  # Reuses ensure_dir / copy_file_if_missing so the non-destructive,
  # "leave existing unchanged" contract holds for every entry.
  local entry name
  for entry in "$src"/*; do
    # Guard against a literal '*' when a directory has no matching entries.
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"

    if [[ -d "$entry" ]]; then
      copy_missing_files "$entry" "$dest/$name"
    elif [[ -f "$entry" ]]; then
      copy_file_if_missing "$entry" "$dest/$name"
    else
      log "Skipping non-regular entry: $entry"
    fi
  done
}

require_file "$ENV_FILE"

# shellcheck source=/dev/null
. "$ENV_FILE"