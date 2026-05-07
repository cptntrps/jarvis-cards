#!/bin/sh
# Chromium kiosk autostart for Wayland (labwc / wayfire).
# Drop into ~/.config/labwc/autostart and chmod +x.
#
# Usage: edit HA_HOST and VARIANT below, then place at ~/.config/labwc/autostart.

HA_HOST="${HA_HOST:-192.168.1.10:8123}"
VARIANT="${VARIANT:-jarvis}"   # subfolder under /local/

# Ensure HDMI output is on
wlr-randr --output HDMI-A-1 --on 2>/dev/null

# Wait for compositor to settle and HA to be reachable
sleep 5

exec chromium-browser \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --no-first-run \
  --ozone-platform=wayland \
  --enable-features=UseOzonePlatform \
  --start-fullscreen \
  --disable-session-crashed-bubble \
  --disable-features=TranslateUI \
  --password-store=basic \
  --user-data-dir="$HOME/.config/chromium-kiosk" \
  "http://$HA_HOST/local/$VARIANT/index.html"
