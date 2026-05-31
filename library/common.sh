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

  if [[ -d "$dir" ]]; then
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
  local fn_name="set_skill_env_vars"

  local src="$1"
  local dest="$2"

  [[ -d "$src" ]] || fail "$fn_name: Source directory is missing: $src"

  if [[ -e "$dest" && ! -d "$dest" ]]; then
    fail "$fn_name: Path exists but is not a directory: $dest"
  fi

  ensure_dir "$dest"

  # Walk the source tree with `find` (handles arbitrary depth — no recursion
  # in our code, no while loop) and copy each regular file that's missing at
  # the destination. The skill's own setup.sh is excluded so it isn't deployed.
  # Reuses copy_file_if_missing to keep the non-destructive contract.
  #
  # Note: paths containing newlines are not supported (find is newline-delimited
  # here); skill files never contain them. Spaces in names ARE handled.
  local src_file rel dest_file
  local IFS=$'\n'
  for src_file in $(find "$src" -type f ! -name 'setup.sh'); do
    rel="${src_file#"$src"/}"          # path relative to src root
    dest_file="$dest/$rel"
    ensure_dir "$(dirname "$dest_file")"
    copy_file_if_missing "$src_file" "$dest_file"
  done
}

require_file "$ENV_FILE"

# shellcheck source=/dev/null
. "$ENV_FILE"