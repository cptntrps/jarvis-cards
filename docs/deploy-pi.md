# Deploy: Raspberry Pi 7" panel

Tested on Raspberry Pi OS Bookworm with `labwc` (Wayland). Should work on `wayfire` with the same launcher.

## 1. Install Chromium

```bash
sudo apt install -y chromium-browser unclutter
```

## 2. Auto-launch on session start

Create `~/.config/labwc/autostart` (or `~/.config/wayfire.ini` `[autostart]`):

```bash
#!/bin/sh
wlr-randr --output HDMI-A-1 --on 2>/dev/null
sleep 5
chromium-browser \
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
  --user-data-dir=$HOME/.config/chromium-kiosk \
  'http://<ha-host>:8123/local/jarvis/index.html' &
```

Make executable:

```bash
chmod +x ~/.config/labwc/autostart
```

## 3. First-time login

Once Chromium opens, you'll see HA's login screen. Sign in with the user that owns the long-lived token in your `index.html`. With "Keep me logged in" checked, the session persists in `~/.config/chromium-kiosk` across reboots.

## 4. (Optional) Hide HA chrome

If you want HA's header/sidebar hidden (the kiosk page does this on its own — but if you ever embed the page inside an HA dashboard view, install [`kiosk-mode`](https://github.com/NemesisRE/kiosk-mode)).

## 5. Skip if not using touch variant

The touch variant works without setup — Wayland delivers touch events to Chromium and the page handles them. No calibration needed for the official 7" panel.
