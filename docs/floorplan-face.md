# Floorplan face

A top-down interactive map of your home overlaid on a stylized floor plan. Each room is a clickable SVG polygon. Tap a room → toggle its light. Hold a slider on the side panel → set brightness. Lit rooms render with a soft warm fill; the active selection gets a thicker stroke; motion sensors animate as a slow pulse dot.

## Concepts

| Element | Source |
|---|---|
| Floor plan image | `floorplan.jpg` next to `index.html` (you supply this — see [stylization prompt](#stylized-floorplan-image)) |
| Room polygons | `const ROOMS = [...]` in the page's JS |
| Light state | `light.<room.id>` HA entity |
| Motion state | (optional) per-room sensor; pulse dot animates while motion is detected |
| Temperature | (optional) `sensor.temp_<room.id>` shown in the side panel |

## Wiring up your apartment

### 1. Style your floor plan

Use [the stylization prompt](#stylized-floorplan-image) below to turn a leasing-document floor plan into the editorial-minimal version. Save the result as `floorplan.jpg` in the same folder as `index.html`.

### 2. Trace rooms

Open [`tools/floorplan-tracer/index.html`](../tools/floorplan-tracer/), load your styled floor plan, click polygons over each room. Export. Paste the resulting `ROOMS = [...]` into the page, replacing the example array inside the JS block.

### 3. Match HA entities

For each room with a light, name the HA entity `light.<room.id>`. The page uses simple `light.turn_on` / `light.turn_off` services. If your existing entity names don't match, either:

- Rename them in HA (cleanest), or
- Edit `callLightService` in the page to map `roomId → entity_id` for your setup

### 4. (Optional) Motion + temperature

```js
{
  id: "bedroom1",
  label: "Bedroom 1",
  poly: "...",
  motionAt: [940, 1440],            // pixel coords for the pulse dot
  tempEntity: "sensor.temp_bedroom1"
}
```

Add the matching binary_sensor / sensor entity to the page's `ENTITIES` array so they're subscribed.

### 5. Demo mode

The page boots in **demo mode** by default — fixtures rotate through faces every 6 s, lights toggle synthetically. To run live against HA, append `?live=1` to the URL:

```
http://<ha-host>:8123/local/jarvis/index.html?live=1
```

This is a deliberate choice so the kiosk works offline as a beautiful idle display even before HA is reachable.

## Stylized floorplan image

Use this prompt with any image-generation model (nano-banana, gpt-image-1, Imagen) to render a leasing-doc floor plan in the editorial-minimal style:

```
Re-render the attached architectural floor plan in editorial-minimalist
line-art style. Reference: NYT Magazine architectural cutaways, Apple Maps
indoor view, Dieter Rams instructional diagrams.

Layout:
- Preserve the EXACT room geometry, wall positions, doors, and proportions
- Top-down orthographic projection. Flat. No 3D, no isometric.
- Output aspect ratio matches the source.

Palette:
- Background: warm off-white #F2EFE9
- Ink (walls, fixtures): near-black #1A1A1A
- Secondary (hairlines): muted warm gray #4A4640 at 18% opacity
- One accent: muted terracotta #C75A3D, used only on door arc indicators
- No fills inside rooms — pure background so overlays sit on top cleanly

Lines:
- Exterior walls: 2.5 px solid ink
- Interior walls: 1.5 px solid ink
- Door swings: 1 px terracotta arcs
- Closet folding doors: 1 px ink dashed (3,2)
- Round line caps, no miters

NO text anywhere — drop every label, dimension, callout. Pure geometry.

Furniture (subtle):
- Render plumbing and kitchen fixtures (toilet, sink, tub, shower, stove,
  fridge, dishwasher, washer/dryer) as 1 px line-art icons in secondary gray
- NO furniture in main rooms (bedrooms, living, dining)

Hard rules:
- No emoji, no decoration, no patterns, no textures, no shadows, no logos
- No "you are here" markers, no arrows, no compass, no scale bar
- 2D top-down only
```

## Privacy

`floorplan.jpg` is your apartment. Don't commit it to a public repo — the variant's `<img>` tag points at it but the file itself is in `.gitignore` by default. Distribute the page + image as a pair to whoever needs it.
