# Floorplan Tracer

Standalone single-file HTML tool to turn a floor-plan image into the polygon data the [`floorplan` face](../../docs/floorplan-face.md) uses.

## How to use

1. Open `index.html` in any browser (no install, no server needed).
2. Click **Load image** and pick your floor plan (`.png`, `.jpg`, `.svg`).
3. For each room:
   - Type a room name (e.g. `Kitchen`) and press <kbd>Enter</kbd> to start.
   - Click around the room's perimeter to drop polygon points.
   - Drag points to fine-tune. <kbd>Esc</kbd> closes the polygon.
4. When you've traced every room, click **Export** to copy a `ROOMS = [...]` JS array to your clipboard.
5. Paste that array into the variant `index.html`, replacing the placeholder `ROOMS` constant inside the floorplan section.

## Output format

```js
const ROOMS = [
  {
    id: "kitchen",
    label: "Kitchen",
    poly: "532,229 740,229 740,283 ...",  // space-separated x,y pairs
    motionAt: [630, 540],                  // optional: where the motion-pulse dot lives
    tempEntity: "sensor.temp_kitchen"      // optional: the HA temp sensor for this room
  },
  ...
]
```

The `poly` string is in the SVG `viewBox` coordinate space; the tracer scales coordinates relative to the image dimensions automatically.

## Tips

- **Snap to grid:** hold <kbd>Shift</kbd> while clicking to snap to the nearest 10-px grid line — gives cleaner polygons.
- **Closets and small alcoves:** trace them as separate rooms with `id` like `closet_main` so you can light them separately.
- **W/D, fixtures:** trace as their own tiny "rooms" if you want a hotspot, otherwise omit.
- **Motion dot placement:** click the room's interior center and copy those coords into `motionAt` — the pulse animation reads from there.
