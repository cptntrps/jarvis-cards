# Jarvis Cards

Editorial-minimal Home Assistant kiosk pages — pure HTML/CSS/JS, single-file, vanilla. No build step, no framework, no bundler.

One canonical source — `kiosk/index.html` — drives every panel. Per-device differences come from URL params at runtime, not from build-time variants.

## Faces

- **`home`** — at-rest face: huge clock, date, breathing hairline, ambient meta strip (outside temp + ETA to two destinations)
- **`weather`** — current conditions with state-driven SVG ambient animation (rays / arcs / rain / snow / wind / pulse)
- **`commute`** — alternating ETA hero between two destinations + animated PATH-line glyphs
- **`grocery`** — vertically rolling list of low/out items; touch tap to pause, swipe ≥35% to remove
- **`floorplan`** — interactive top-down map with per-room light + sensors, tap room to control
- **`listening`** — concentric pulsing rings while voice satellite is processing
- **`ack`** — character-pop reveal of any spoken response without its own card

The active face is driven by HA helper `input_select.jarvis_card`. Voice intents flip it; the page reactively swaps faces.

## Per-device URL params

| Param | Effect |
|---|---|
| `?live=1` | Bind to live HA via WebSocket (default: demo mode with synthetic fixtures) |
| `?form=display` | Passive display: hide nav-bar, hide mode toggle, disable all touch handlers |
| `?mode=voice\|touch\|both` | Lock this device to a mode (overrides shared HA helper) |
| `?here=<room_id>` | Tag this device's home room; shows "this room" pill labeled accordingly |
| `?hide=name1,name2` | Hide nav pills by `data-nav-id` (`home`, `weather`, `commute`, `grocery`, `map`, room labels) |
| `?face=<id>` | Lock the visible face (used in demo mode and embeds) |
| `?width=<n>&height=<n>` | Used by `tools/preview.sh` headless renderer; the kiosk itself uses real screen size |

## Concrete URLs

| Panel | URL |
|---|---|
| Pi 7" (living room, touch) | `http://<ha-host>:8123/local/jarvis/index.html?live=1&here=living` |
| Echo Show 8 (office, touch) | `http://<ha-host>:8123/local/jarvis/index.html?live=1&mode=touch&here=bedroom2&hide=grocery,office` |
| Any passive display | `http://<ha-host>:8123/local/jarvis/index.html?live=1&form=display` |

## Cross-cutting features

- **Demo mode** — boots in self-driving demo by default (fixtures rotate every 6 s). Append `?live=1` to bind to live HA state.
- **Connection hairline** — 1 px terracotta bar at the top pulses when the WebSocket to HA drops.
- **Burn-in protection** — after 5 min of no interaction the active face slowly drifts ±6 px and dims slightly.
- **Per-face mood themes** — `listening` and `ack` flip to a dark cosmic palette; `commute` swaps the accent to a transit blue.
- **Token via localStorage** — `__HA_TOKEN__` placeholder is the default; can be overridden at runtime via `localStorage.ha_token`.

## Deploy

Two scripts handle the canonical workflow. Both run preview first, abort on failure.

```bash
# Required env: HA_TOKEN (long-lived access token).
# Read from $HOME/.credentials.env if not in env.
tools/deploy-pi.sh                    # → 192.168.50.4
tools/deploy-echo.sh                  # → 192.168.50.81 (also redeploys to Pi)
```

Manually verify a render before deploying:

```bash
tools/preview.sh "?live=1&here=living"                                # Pi 7"  1024×600
tools/preview.sh "?live=1&mode=touch&here=bedroom2&width=1280&height=800"   # Echo 8 1280×800
tools/preview.sh "?live=1&form=display&width=1280&height=800"          # Passive display
```

`preview.sh` extracts the embedded `<script>` block, runs `node --check`, headless-renders with chromium, and asserts the output isn't suspiciously small. Exits non-zero on any failure.

## Repo layout

```
jarvis-cards/
├── kiosk/
│   └── index.html         # canonical source (~70 KB; all faces, all logic)
├── tools/
│   ├── preview.sh
│   ├── deploy-pi.sh
│   ├── deploy-echo.sh
│   └── floorplan-tracer/   # standalone polygon tracer for the floorplan face
├── docs/
│   ├── design-system.md
│   ├── ha-setup.md
│   ├── floorplan-face.md
│   ├── deploy-pi.md
│   └── deploy-echo.md
├── setup/
│   ├── ha-config.yaml
│   ├── kiosk-launcher.sh
│   └── dashboard.yaml
└── README.md
```

## Documentation

- [Design system](docs/design-system.md) — palette, type, motion, prompt template
- [Home Assistant setup](docs/ha-setup.md) — helpers, intents, automations
- [Floorplan face](docs/floorplan-face.md) — wiring rooms, sensors, the stylization prompt
- [Deploy: Raspberry Pi 7"](docs/deploy-pi.md)
- [Deploy: Echo Show 8 (LineageOS)](docs/deploy-echo.md)

## Contributing rules (self-imposed)

1. **One logical change per commit.** Don't merge unrelated edits.
2. **Run `tools/preview.sh` before every deploy.** No exceptions.
3. **Visually verify the rendered PNG.** A passing exit code is necessary, not sufficient.
4. **No regex transforms on JS source code.** Use a CSS class or runtime branch instead.
5. **Touch the live panel only via `tools/deploy-*.sh`.** Manual `scp` is forbidden.

## License

MIT.
