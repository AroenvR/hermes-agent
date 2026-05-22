#!/bin/bash
#
# host-bootstrap.sh — one-time host-side setup for the server.
#
# What it does:
#   1. Enables systemd lingering for the current user (containers
#      survive SSH disconnects and session cleanup).
#   2. Grants the current user passwordless sudo for journalctl
#      (used by for diagnostics).
#   3. Verifies both took effect.
#
# Run once per fresh server. Safe to re-run — idempotent.
#
# Usage:
#   chmod +x host-bootstrap.sh
#   ./host-bootstrap.sh

set -euo pipefail

user="$(id -un)"
uid="$(id -u)"

echo "host-bootstrap — running as ${user} (uid ${uid})"
echo ""

# ─── Sanity check: don't run this as root ─────────────────────────
# We want linger on the actual user that will own the container, not root.
if [ "$uid" -eq 0 ]; then
  echo "ERROR: do not run this as root. Run as the regular user that"
  echo "       will own the containers (e.g. 'atoll')."
  exit 1
fi

# ─── 1. Enable linger ─────────────────────────────────────────────
# Without linger, systemd stops user@<uid>.service when the user's
# last session ends (e.g. SSH disconnect), which kills all rootless
# Podman containers regardless of --restart=always. Linger tells
# systemd to keep user@<uid>.service running across logouts.

current_linger="$(loginctl show-user "$user" -p Linger --value 2>/dev/null || echo "unknown")"

if [ "$current_linger" = "yes" ]; then
  echo "[1/2] linger: already enabled — skipping"
else
  echo "[1/2] linger: enabling (needs sudo)"
  sudo loginctl enable-linger "$user"
  # Verify it stuck
  new_linger="$(loginctl show-user "$user" -p Linger --value)"
  if [ "$new_linger" != "yes" ]; then
    echo "      ERROR: enable-linger ran but Linger is still '$new_linger'"
    exit 1
  fi
  echo "      OK — Linger=yes"
fi

# ─── 2. Sudoers entry for journalctl ──────────────────────────────
# Used for diagnostics. Narrowly scoped —
# this user can run journalctl without a password, nothing else.

sudoers_file="/etc/sudoers.d/${user}-journalctl"
expected_line="${user} ALL=(ALL) NOPASSWD: /usr/bin/journalctl"

if sudo test -f "$sudoers_file" && \
   sudo grep -qF "$expected_line" "$sudoers_file" 2>/dev/null; then
  echo "[2/2] sudoers journalctl: already configured — skipping"
else
  echo "[2/2] sudoers journalctl: writing $sudoers_file"
  # Write via sudo tee — never edit /etc/sudoers.d directly without visudo,
  # but a single-line file from a known template is safe.
  echo "$expected_line" | sudo tee "$sudoers_file" >/dev/null
  sudo chmod 440 "$sudoers_file"
  # Validate sudoers syntax before trusting it.
  if ! sudo visudo -c -f "$sudoers_file" >/dev/null; then
    echo "      ERROR: sudoers file failed validation. Removing."
    sudo rm -f "$sudoers_file"
    exit 1
  fi
  echo "      OK — written and validated"
fi

# ─── Final verification ───────────────────────────────────────────
echo ""
echo "Verification:"
echo "  Linger: $(loginctl show-user "$user" -p Linger --value)"
if sudo -n journalctl --since "1 minute ago" >/dev/null 2>&1; then
  echo "  Passwordless journalctl: OK"
else
  echo "  Passwordless journalctl: FAILED — check $sudoers_file manually"
  exit 1
fi

echo ""
echo "host-bootstrap complete."

# TODO: Run the `./skills/bootstrap_skills.sh` script to setup our custom skills.