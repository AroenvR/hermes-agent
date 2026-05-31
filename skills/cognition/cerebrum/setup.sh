#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="skill setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common script
. "$SCRIPT_DIR/../../../library/common.sh"

main() {
  read -r a b c < <(skill_self_locate "$SCRIPT_DIR")

  log "SKILL_NAME: $a, SKILL_CATEGORY: $b, DESTINATION_DIR: $c"
}

main "$@"