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

require_file "$ENV_FILE"

# shellcheck source=/dev/null
. "$ENV_FILE"