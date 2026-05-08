#!/usr/bin/env bash
# Deploy to the Echo Show 8 running Fully Kiosk Browser.
# Pushes nothing to the Echo directly — the Echo loads from HA's /local/jarvis/.
# This script just runs the pre-flight + Pi deploy, then force-restarts Fully
# so it picks up the fresh file.
#
# Usage: tools/deploy-echo.sh [ECHO_HOST] [PI_HOST]
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ECHO_HOST="${1:-192.168.50.81}"
PI_HOST="${2:-192.168.50.4}"

echo "==> Deploying to Pi (Echo serves from there)"
"$REPO_ROOT/tools/deploy-pi.sh" "$PI_HOST"

echo "==> Restarting Fully Kiosk on Echo Show ($ECHO_HOST)"
adb connect "$ECHO_HOST:5555" >/dev/null 2>&1 || true
adb -s "$ECHO_HOST:5555" shell am force-stop de.ozerov.fully
adb -s "$ECHO_HOST:5555" shell "rm -rf /data/data/de.ozerov.fully/cache /data/data/de.ozerov.fully/app_webview/Default/Cache 2>/dev/null"
sleep 1
adb -s "$ECHO_HOST:5555" shell "monkey -p de.ozerov.fully -c android.intent.category.LAUNCHER 1" 2>&1 | tail -1
echo "==> Echo reloaded"
