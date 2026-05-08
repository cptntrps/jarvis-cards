#!/usr/bin/env bash
# Headless render the kiosk page and verify it isn't broken.
# Pre-flight check before any deploy.
#
# Usage: tools/preview.sh [URL_PARAMS] [OUTPUT_PNG]
#   tools/preview.sh "?live=1&here=living"
#   tools/preview.sh "?live=1&form=display" /tmp/x.png
#   tools/preview.sh "?form=display&width=1280&height=800"
set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$REPO_ROOT/kiosk/index.html"
PARAMS="${1:-?live=1}"
OUTPUT="${2:-/tmp/jarvis-preview.png}"

WIDTH=$(echo "$PARAMS" | grep -oE 'width=[0-9]+' | head -1 | cut -d= -f2)
HEIGHT=$(echo "$PARAMS" | grep -oE 'height=[0-9]+' | head -1 | cut -d= -f2)
WIDTH="${WIDTH:-1024}"
HEIGHT="${HEIGHT:-600}"

[ -f "$SOURCE" ] || { echo "ERROR: $SOURCE missing"; exit 1; }

# 1. Lint the embedded <script> block
TMP_JS=$(mktemp --suffix=.js)
trap 'rm -f "$TMP_JS"' EXIT
python3 - <<PY >/dev/null
import re, sys
src = open("$SOURCE").read()
m = re.search(r'<script>(.*?)</script>', src, re.DOTALL)
if not m:
    print("ERROR: no <script> block", file=sys.stderr); sys.exit(1)
open("$TMP_JS", "w").write(m.group(1))
PY
[ -s "$TMP_JS" ] || { echo "ERROR: extracted JS empty"; exit 1; }
node --check "$TMP_JS" >/dev/null 2>&1 || { echo "ERROR: JS syntax invalid"; node --check "$TMP_JS"; exit 1; }
echo "  ✓ JS syntax OK"

# 2. Headless render — chromium snap can only write inside its home; render in a
#    workdir under $HOME, then move to OUTPUT.
WORKDIR=$(mktemp -d --tmpdir="$HOME" jarvis-preview-XXXX)
trap 'rm -rf "$TMP_JS" "$WORKDIR"' EXIT

# Stub the placeholders so the page can boot during render
sed -e 's|__HA_TOKEN__|preview|' -e 's|__HA_HOST__|localhost|' "$SOURCE" > "$WORKDIR/index.html"

CHROMIUM=$(command -v chromium || command -v chromium-browser)
[ -n "$CHROMIUM" ] || { echo "ERROR: no chromium found"; exit 1; }

(
  cd "$WORKDIR"
  "$CHROMIUM" --headless --disable-gpu --no-sandbox --hide-scrollbars \
    --window-size="$WIDTH","$HEIGHT" \
    --virtual-time-budget=4000 \
    --screenshot="$WORKDIR/out.png" \
    "file://$WORKDIR/index.html$PARAMS" >/dev/null 2>&1
) || true

if [ ! -f "$WORKDIR/out.png" ]; then
  echo "ERROR: no screenshot produced"
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"
cp "$WORKDIR/out.png" "$OUTPUT"
SIZE=$(stat -c%s "$OUTPUT")
echo "  ✓ rendered ${WIDTH}x${HEIGHT} → $OUTPUT (${SIZE} bytes)"

# 3. Sanity floor: a fully-blank or near-blank PNG at this size compresses small.
#    Empirical: blank ~6 KB, content ~50+ KB. 12 KB is a permissive lower bound.
if [ "$SIZE" -lt 12000 ]; then
  echo "  ⚠ render is suspiciously small (${SIZE} bytes) — page may be blank"
  echo "    Inspect $OUTPUT before deploying."
  exit 1
fi
echo "  ✓ preview OK"
