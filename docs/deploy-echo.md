# Deploy: Echo Show 8 (LineageOS)

Tested on Echo Show 8 (1st gen, codename `crown`) running [LineageOS 18.1 unofficial](https://xdaforums.com/t/rom-unofficial-11-crown-lineageos-18-1-for-the-amazon-echo-show-8-2019.4766709/). Same approach should work on any Android device.

## 1. Enable ADB

On the device: Settings → System → About → tap Build number 7 times to enable Developer mode → Settings → System → Developer options → toggle Wireless debugging (or USB debugging).

If using wireless: note the IP. Otherwise plug in USB.

## 2. Connect

```bash
# Wireless
adb connect 192.168.x.x:5555

# OR USB (you may need a udev rule for the Echo's vendor ID 1949):
sudo bash -c 'cat > /etc/udev/rules.d/51-android.rules <<EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="1949", MODE="0666", GROUP="plugdev"
EOF
udevadm control --reload-rules && udevadm trigger'
```

Tap **Allow** + ✓ **Always allow from this computer** when the prompt appears on the Echo.

## 3. Install Fully Kiosk Browser (free version, no nag)

Download the **non-EMM** APK from [fully-kiosk.com](https://www.fully-kiosk.com/) (the EMM version shows a "PLUS Features Activated" nag forever).

```bash
adb install Fully-Kiosk-Browser-v1.60.1.apk
```

Optionally also install Fully Kiosk's free version's PLUS-license-free remote admin alternative — you don't need it; configuration via in-app menu works fine.

## 4. Quick Start config

```bash
# Pre-grant permissions so the first launch is smooth
adb shell pm grant de.ozerov.fully android.permission.SYSTEM_ALERT_WINDOW
adb shell appops set de.ozerov.fully SYSTEM_ALERT_WINDOW allow

# Launch with start URL
adb shell "am start -n de.ozerov.fully/de.ozerov.fully.FullyActivity \
  -e url 'http://<ha-host>:8123/local/jarvis/index.html'"
```

The first launch shows the Quick Start dialog. Tap into the Start URL field, paste the URL, enable **Fullscreen Mode**, disable **Show Action Bar** and **Show Address Bar**, then **START USING FULLY**.

## 5. Auto-launch on boot

In Fully: swipe from left edge → menu → enter PIN (default `1234`) → **Settings** → **Device Management** → enable **Launch on Boot** + **Keep Screen On**.

## 6. (Optional) Make Fully the default home app

Free Fully cannot be set as default launcher (PLUS-only). Workaround: leave the system launcher (Trebuchet) as default. Fully's "Launch on Boot" still puts it in foreground a few seconds after boot.

## 7. Touch interactions

Both touch variants work out of the box. Echo Show panels are 1280×800 capacitive, Wayland/Android delivers events to the Chromium webview inside Fully.

## Audio I/O on Echo Show 8 (caveat)

Echo Show 8 (1st gen) on LineageOS has a known **mic/speaker hardware-routing limitation**: the 4-mic array data flows through Lab126's proprietary AOP/DSP firmware that LineageOS does not expose to the standard Android audio HAL. With root + direct ALSA configuration (DMIC mode + ADC boost + MICPGA max + per-channel mixing) it's possible to extract usable mic input — but the speaker-amp path is locked behind a `/vendor/etc/audio_em.xml` config that's hard to override.

Pragmatic recommendation: use the Echo Show as a **display-only** target (the `echo8-display` variant). For voice in the same room, drop in a Pi Zero 2 W + USB mic + the existing `wyoming-satellite` stack — same software your other voice satellites run.
