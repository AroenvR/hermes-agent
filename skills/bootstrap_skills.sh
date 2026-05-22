#!/usr/bin/env bash
set -Eeuo pipefail

# bootstrap_skills.sh
#
# Install repo-managed Hermes skills into the local Hermes skills directory.
#
# Expected source layout:
#   skills/<category>/<skill-name>/SKILL.md
#
# Destination:
#   ${HERMES_HOME:-$HOME/.hermes}/skills/<category>/<skill-name>/SKILL.md
#
# Usage:
#   ./bootstrap_skills.sh
#   ./bootstrap_skills.sh --dry-run
#
# Optional env overrides:
#   REPO_ROOT=/path/to/repo ./bootstrap_skills.sh
#   SKILLS_SRC_DIR=/path/to/skills ./bootstrap_skills.sh
#   HERMES_HOME=/path/to/hermes-home ./bootstrap_skills.sh

DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      sed -n '1,35p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Use --help for usage." >&2
      exit 2
      ;;
  esac
done

log() {
  printf '[bootstrap-skills] %s\n' "$*"
}

die() {
  printf '[bootstrap-skills] ERROR: %s\n' "$*" >&2
  exit 1
}

require_dir() {
  local path="$1"
  local label="$2"

  [[ -d "$path" ]] || die "$label does not exist or is not a directory: $path"
}

real_path() {
  python3 - "$1" <<'PY'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
}

# Resolve repo root.
if [[ -z "${REPO_ROOT:-}" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

  if git -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
  elif [[ "$(basename "$SCRIPT_DIR")" == "scripts" ]]; then
    REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
  else
    REPO_ROOT="$SCRIPT_DIR"
  fi
fi

SKILLS_SRC_DIR="${SKILLS_SRC_DIR:-$REPO_ROOT/skills}"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKILLS_DEST_DIR="${SKILLS_DEST_DIR:-$HERMES_HOME/skills}"

require_dir "$REPO_ROOT" "Repo root"
require_dir "$SKILLS_SRC_DIR" "Skills source directory"

mkdir -p "$SKILLS_DEST_DIR"

REPO_ROOT_REAL="$(real_path "$REPO_ROOT")"
SRC_REAL="$(real_path "$SKILLS_SRC_DIR")"
DEST_REAL="$(real_path "$SKILLS_DEST_DIR")"

[[ "$SRC_REAL" != "$DEST_REAL" ]] || die "Source and destination are the same directory: $SRC_REAL"

case "$DEST_REAL" in
  "$HERMES_HOME"/skills|"$HERMES_HOME"/skills/*)
    ;;
  *)
    die "Destination must be inside HERMES_HOME/skills. Refusing destination: $DEST_REAL"
    ;;
esac

validate_skill() {
  local skill_file="$1"

  [[ -f "$skill_file" ]] || return 1

  # Byte-zero frontmatter check.
  local first_line
  first_line="$(head -n 1 "$skill_file")"
  [[ "$first_line" == "---" ]] || {
    log "Skipping invalid skill, missing opening frontmatter: $skill_file"
    return 1
  }

  grep -q '^name:[[:space:]]*[^[:space:]]' "$skill_file" || {
    log "Skipping invalid skill, missing frontmatter name: $skill_file"
    return 1
  }

  grep -q '^description:[[:space:]]*' "$skill_file" || {
    log "Skipping invalid skill, missing frontmatter description: $skill_file"
    return 1
  }

  return 0
}

copy_skill_dir() {
  local src_dir="$1"
  local rel_dir="$2"
  local dest_dir="$SKILLS_DEST_DIR/$rel_dir"
  local tmp_dir="${dest_dir}.tmp.$$"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Would install: $rel_dir"
    return 0
  fi

  rm -rf "$tmp_dir"
  mkdir -p "$(dirname "$tmp_dir")"

  # Copy to a temp directory first so partial installs do not replace a working skill.
  cp -a "$src_dir" "$tmp_dir"

  # Atomic-ish replacement on the same filesystem.
  rm -rf "$dest_dir"
  mv "$tmp_dir" "$dest_dir"

  log "Installed: $rel_dir"
}

log "Repo root: $REPO_ROOT_REAL"
log "Skills source: $SRC_REAL"
log "Skills destination: $DEST_REAL"

installed_count=0
skipped_count=0

while IFS= read -r -d '' skill_file; do
  skill_dir="$(dirname "$skill_file")"
  rel_dir="${skill_dir#"$SKILLS_SRC_DIR"/}"

  if validate_skill "$skill_file"; then
copy_skill_dir "$skill_dir" "$rel_dir"
    installed_count=$((installed_count + 1))
  else
    skipped_count=$((skipped_count + 1))
  fi
done < <(find "$SKILLS_SRC_DIR" -type f -name 'SKILL.md' -print0 | sort -z)

if [[ "$installed_count" -eq 0 ]]; then
  die "No valid skills found under: $SKILLS_SRC_DIR"
fi

log "Done. Installed: $installed_count, skipped: $skipped_count"

if command -v hermes >/dev/null 2>&1; then
  log "Tip: run 'hermes skills list' or start a fresh session to verify skill loading."
else
  log "Hermes CLI not found on PATH; skipping CLI verification hint."
fi
