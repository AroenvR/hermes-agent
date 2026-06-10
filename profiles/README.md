TODO

This directory manages agent profiles.
bootstrap profiles script is a WIP!

Quick template:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="bootstrap_profiles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common script
. "$SCRIPT_DIR/../library/common.sh"
require_var HERMES_HOME

# TODO: Get profile from the sub directory's name
PROFILE="skillwright"
# TODO: Get description from the subdirectory's description.md file
DESCRIPTION="Designs, writes, and validates safe, portable Hermes Agent skills for new profiles."
DST="$HERMES_HOME/profiles/$PROFILE"

podman exec -it hermes-gateway hermes profile create "$PROFILE" --no-alias --no-skills --description "$DESCRIPTION" &&
install -m 600 "$HERMES_HOME/.env" "$DST/.env" &&
install -m 600 "$HERMES_HOME/config.yaml" "$DST/config.yaml"

podman exec -it hermes-gateway hermes -p "$PROFILE" config check || true

# TODO: Install skills if the subdirectory contains a skills.csv file using the following command:
# podman exec -it hermes-gateway hermes -p "$PROFILE" skills reset "$skill" --restore --yes
# TODO: Use the SOUL.md file from the directory
```