#!/usr/bin/env bash
#
# hermes-debug.sh — quick first-glance diagnostic snapshot for the
# Hermes gateway + dashboard containers and their recent logs.
#
# Read-only. Changes nothing. Safe to run any time.
#
# Usage:
#   bash hermes-debug.sh            # prints to terminal
#   bash hermes-debug.sh > out.txt  # capture to file for sharing
#
# If output overflows the terminal scrollback, redirect to a file
# and page it: bash hermes-debug.sh > ~/hermes-debug.out 2>&1; less ~/hermes-debug.out

set -uo pipefail   # not -e: several checks are allowed to fail; that's data

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env.safe"

if [[ ! -f "$ENV_FILE" ]]; then
  printf 'ERROR: expected env file not found: %s\n' "$ENV_FILE" >&2
  exit 1
fi

# Load safe env
. "$ENV_FILE"

GATEWAY="hermes-gateway"
DASHBOARD="hermes-dashboard"
HERMES_LOGS="$HERMES_HOME/logs"

section() { printf '\n========== %s ==========\n' "$*"; }

section "TIMESTAMP"
date -Iseconds

section "CONTAINER STATE"
podman ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}' 2>&1

section "GATEWAY SYSTEMD STATUS"
systemctl --user status "${GATEWAY}.service" --no-pager 2>&1 | head -15

section "GATEWAY CONTAINER INSPECT"
podman inspect "$GATEWAY" --format \
  'running={{.State.Running}} | restarts={{.RestartCount}} | started={{.State.StartedAt}} | exit={{.State.ExitCode}} | OOM={{.State.OOMKilled}}' 2>&1

section "GATEWAY LOGS — last 60 lines (container stdout)"
podman logs --tail 60 "$GATEWAY" 2>&1 | tail -80

section "HERMES ERROR LOG — last 40 lines"
tail -40 "$HERMES_LOGS/errors.log" 2>/dev/null || echo "(no errors.log at $HERMES_LOGS)"

section "HERMES GATEWAY LOG — last 40 lines"
tail -40 "$HERMES_LOGS/gateway.log" 2>/dev/null || echo "(no gateway.log at $HERMES_LOGS)"

section "RECENT NoneType / iterable / Telegram ERRORS (grep across hermes logs)"
if [[ -d "$HERMES_LOGS" ]]; then
  grep -rinE 'nonetype|not iterable|traceback|telegram.*error|httpx|fallback' "$HERMES_LOGS" 2>/dev/null \
    | tail -40 || echo "(no matching lines)"
else
  echo "(no logs dir at $HERMES_LOGS)"
fi

section "TELEGRAM REACHABILITY (from container)"
podman exec "$GATEWAY" curl -sS -m 8 -o /dev/null -w "api.telegram.org → HTTP %{http_code} in %{time_total}s\n" \
  https://api.telegram.org/ 2>&1 || echo "(curl from container failed)"

section "OPENAI REACHABILITY (from container)"
podman exec "$GATEWAY" curl -sS -m 8 -o /dev/null -w "api.openai.com → HTTP %{http_code} in %{time_total}s\n" \
  https://api.openai.com/ 2>&1 || echo "(curl from container failed)"

section "HERMES VERSION (inside container)"
podman exec "$GATEWAY" hermes --version 2>&1 | head -3 || echo "(version check failed)"

section "MEMORY / DISK"
free -h
echo "---"
df -h / "$HOME" 2>&1 | grep -vE '^Filesystem'

section "RECENT GATEWAY JOURNAL (systemd, last 30)"
journalctl --user -u "${GATEWAY}.service" --no-pager --since "30 minutes ago" 2>&1 | tail -30

section "DONE"
echo "If sharing: redirect to a file and paste, or summarize the ERROR sections."