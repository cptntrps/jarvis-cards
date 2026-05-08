#!/usr/bin/env bash
# Deploy kiosk/index.html to the Raspberry Pi running HA.
# Pre-flight: lint + headless render. Aborts on failure.
#
# Usage: tools/deploy-pi.sh [PI_HOST] [HA_TOKEN_VAR] [REMOTE_PATH]
# Defaults:
#   PI_HOST       192.168.50.4
#   HA_TOKEN_VAR  HA_TOKEN  (read from env or ~/.credentials.env)
#   REMOTE_PATH   ~/homeassistant/config/www/jarvis/index.html
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PI_HOST="${1:-192.168.50.4}"
TOKEN_VAR="${2:-HA_TOKEN}"
REMOTE_PATH="${3:-homeassistant/config/www/jarvis/index.html}"

# Source HA_TOKEN from credentials file if not in env
if [ -z "${!TOKEN_VAR:-}" ] && [ -f "$HOME/.credentials.env" ]; then
  set +u; . "$HOME/.credentials.env"; set -u
fi
TOKEN="${!TOKEN_VAR:-}"
[ -z "$TOKEN" ] && { echo "ERROR: $TOKEN_VAR not set"; exit 1; }

echo "==> Pre-flight check"
"$REPO_ROOT/tools/preview.sh" "?live=1&here=living" "/tmp/jarvis-preview-pi.png" || {
  echo "ERROR: preview failed; refusing to deploy."
  exit 1
}

echo "==> Substituting placeholders"
TMP=$(mktemp --suffix=.html)
trap 'rm -f "$TMP"' EXIT
sed -e "s|__HA_TOKEN__|$TOKEN|" \
    -e "s|__HA_HOST__|$PI_HOST|" \
    "$REPO_ROOT/kiosk/index.html" > "$TMP"

# Verify substitutions happened (no leftover placeholders)
if grep -q '__HA_TOKEN__\|__HA_HOST__' "$TMP"; then
  echo "ERROR: placeholders not fully substituted"
  exit 1
fi

echo "==> scp → $PI_HOST:$REMOTE_PATH"
scp -q "$TMP" "$PI_HOST:$REMOTE_PATH"

# Sync any static assets (PNGs etc) that live next to the source.
REMOTE_DIR="${REMOTE_PATH%/*}"
shopt -s nullglob
ASSETS=("$REPO_ROOT/kiosk/"*.png "$REPO_ROOT/kiosk/"*.svg "$REPO_ROOT/kiosk/"*.jpg)
shopt -u nullglob
if [ "${#ASSETS[@]}" -gt 0 ]; then
  echo "==> scp ${#ASSETS[@]} static asset(s) → $PI_HOST:$REMOTE_DIR/"
  scp -q "${ASSETS[@]}" "$PI_HOST:$REMOTE_DIR/"
fi

echo "==> Trigger Chromium reload via wtype"
ssh -o ConnectTimeout=3 -o PreferredAuthentications=publickey -o IdentitiesOnly=yes "$PI_HOST" \
  "export WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/\$(id -u); \
   wtype -M ctrl -M shift r -m ctrl -m shift" 2>&1 | tail -1
echo "==> Deployed."
