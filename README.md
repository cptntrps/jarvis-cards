# Jarvis Cards

Editorial-minimal Home Assistant kiosk pages for ambient + voice-activated displays. Pure HTML/CSS/JS, single-file, vanilla — no build step, no framework.

Built for two panels and two interaction modes:

| Variant | Resolution | Touch |
|---|---|---|
| [`pi7-touch`](variants/pi7-touch/) | 1024×600 (Raspberry Pi 7" official) | yes — taps + swipes |
| [`pi7-display`](variants/pi7-display/) | 1024×600 | no — passive display |
| [`echo8-touch`](variants/echo8-touch/) | 1280×800 (Echo Show 8 / LineageOS) | yes |
| [`echo8-display`](variants/echo8-display/) | 1280×800 | no |

All four share the same seven **faces** (state-driven, one shown at a time):

- **`home`** — at-rest face: huge clock, date, breathing hairline, ambient meta strip (outside temp + ETA to two destinations)
- **`weather`** — current conditions with state-driven SVG ambient animation (rays / arcs / rain / snow / wind / pulse)
- **`commute`** — alternating ETA hero between two destinations + animated PATH-line glyphs with train dots gliding at speed proportional to next-train countdown
- **`grocery`** — vertically rolling list of low/out items with status pill; touch variants support swipe-to-remove and tap-to-pause
- **`listening`** — concentric pulsing rings while voice satellite is processing
- **`ack`** — character-by-character pop-in of any spoken response that doesn't have its own card
- **`floorplan`** — top-down interactive map of your home with per-room light + motion + temperature state. Touch variants tap rooms to toggle lights. See [docs/floorplan-face.md](docs/floorplan-face.md).

Plus a few cross-cutting niceties:

- **Demo mode** — boots in self-driving demo by default (fixtures rotate every 6 s). Append `?live=1` to the URL to bind to live HA state.
- **Connection hairline** — 1 px terracotta bar at the top pulses when the WebSocket to HA drops.
- **Burn-in protection** — after 90 s of no interaction the active face slowly drifts ±6 px and dims slightly.
- **Per-face mood themes** — `listening` and `ack` flip to a dark cosmic palette; `commute` swaps the accent to a transit blue.
- **Token via localStorage** — variants ship with `__HA_TOKEN__` placeholder; you can also set `localStorage.ha_token` at runtime so the source stays clean.

The active face is driven by a single Home Assistant helper, `input_select.jarvis_card`. Intents flip the helper, the page reactively swaps faces.

## Quick start

```bash
# 1. Copy the variant you want into HA's www folder
scp variants/pi7-touch/index.html ha-host:~/homeassistant/config/www/jarvis/index.html

# 2. Replace the token placeholder in the file
sed -i 's|__HA_TOKEN__|<your-long-lived-token>|' ~/homeassistant/config/www/jarvis/index.html

# 3. Apply HA-side helpers, dashboards, and automations
# See setup/ha-config.yaml for the snippets you need to merge into configuration.yaml
```

The page is then served at `http://<ha-host>:8123/local/jarvis/index.html`.

## Documentation

- [Design system](docs/design-system.md) — the palette, type, and motion rules + the prompt template used to generate new cards
- [Home Assistant setup](docs/ha-setup.md) — required helpers, dashboards, and automations
- [Floorplan face](docs/floorplan-face.md) — how to wire your apartment in, including the image-stylization prompt
- [Deploy: Raspberry Pi 7"](docs/deploy-pi.md) — Chromium kiosk on Wayland (labwc/wayfire)
- [Deploy: Echo Show 8 (LineageOS)](docs/deploy-echo.md) — Fully Kiosk Browser via ADB

## Tools

- [`tools/floorplan-tracer/`](tools/floorplan-tracer/) — single-file HTML utility to trace polygons over a floor plan image and export them as the `ROOMS` array the floorplan face consumes.

## Repo layout

```
jarvis-cards/
├── docs/
├── setup/
│   ├── ha-config.yaml         # input_select, input_text, sample automations
│   └── kiosk-launcher.sh      # Chromium kiosk autostart for Wayland
├── tools/
│   └── floorplan-tracer/      # standalone polygon tracer for the floorplan face
└── variants/
    ├── echo8-touch/index.html
    ├── echo8-display/index.html
    ├── pi7-touch/index.html
    └── pi7-display/index.html
```

## License

MIT.
