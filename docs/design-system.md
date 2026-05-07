# Design system

Editorial-minimalist. Reference: NYT Magazine cover graphics, Apple WWDC microsites, claude.ai prompt-gallery line art. Generous negative space, monochrome with one accent at most, line art only.

## Palette

```css
/* Light (default) */
--bg:        #F2EFE9;   /* warm off-white */
--ink:       #1A1A1A;   /* near-black */
--secondary: #4A4640;   /* warm gray */
--accent:    #C75A3D;   /* muted terracotta — used sparingly */
--hairline:  rgba(26, 26, 26, 0.35);

/* Dark / cosmic (auto for clear-night weather state) */
--bg:        #0A0A0A;
--ink:       #F5F5F5;
--secondary: #8A8378;
--hairline:  rgba(245, 245, 245, 0.35);
```

## Typography

System stack — **never** load a custom web font (kiosks may be offline-tolerant).

```css
font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
```

Sizes (use `clamp()` so the same code works at 1024×600 and 1280×800):

- Hero: `clamp(48px, 14vw, 168px)`, weight 200
- Mega numeric (clock): `clamp(96px, 22vw, 264px)`, weight 200
- Body: `clamp(16px, 2vw, 22px)`, weight 400
- Caption / label: `13px`, uppercase, letter-spacing `0.22em`

## Motion

- Easing: `cubic-bezier(.25, .1, .25, 1)`
- Transitions: 600–1200 ms
- Ambient loops: 6–20 s
- Never bounce, never elastic
- Respect `@media (prefers-reduced-motion: reduce)` by freezing animations

## Vector art

Inline SVG only, stroke-based:

```css
fill: none;
stroke: var(--ink);
stroke-width: 1.6;
stroke-linecap: round;
vector-effect: non-scaling-stroke;
```

For SVG transforms (rotation, scale), always set:

```css
transform-box: fill-box;
transform-origin: 50% 50%;
```

Otherwise the rotation orbits the viewbox origin instead of the element's center.

## Hard rules

- No emoji anywhere
- No gradients louder than 8% luminance change
- No drop shadows — use a 1 px hairline border instead
- No skeuomorphic icons — geometric primitives only
- Never `position: fixed` for main content (kiosks don't scroll)
- If live data is unavailable, render an em-dash `—`, never "loading…"

## Prompt template (for generating new cards)

```
You are designing a single self-contained HTML page that will run as a
full-screen kiosk on a {{RES}} px panel. The page is one of several "cards"
rendered against a Home Assistant backend. Treat this like an art-directed
product surface, not a dashboard.

[full design system as above]

# What to fill in per card

- {{CARD_NAME}}:    short slug, e.g. weather, commute
- {{CARD_PURPOSE}}: one sentence on what the card communicates
- {{LIVE_ENTITIES}}: HA entity IDs the card reads, with attributes used
- {{ANIMATION_IDEA}}: the ambient motion (CSS-keyframe preferred)
- {{OUT_OF_SCOPE}}:  what NOT to add

# Output format

1. A 2-3 sentence design rationale.
2. The complete index.html file in one fenced code block.
3. A "preview prompt" line for iteration.
```
