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

require_var() {
  local var_name="$1"

  if [[ -z "${!var_name:-}" ]]; then
    fail "$var_name must be set"
  fi
}

require_file "$ENV_FILE"

# shellcheck source=/dev/null
. "$ENV_FILE"