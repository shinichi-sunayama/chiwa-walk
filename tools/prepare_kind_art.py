# Prepare a button illustration drawn by Gemini on a white background (docs/art/buttons.md).
# Removes the white around the picture (flood fill from the edges, so white inside the outline stays),
# crops to the picture, adds a small margin and saves a 512x512 transparent PNG.
# Usage: python tools/prepare_kind_art.py <source image> <kind: pee|poop|water|food>
import sys
from collections import deque
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
src, kind = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
w, h = im.size
px = im.load()

def whitish(p):
    return p[0] > 225 and p[1] > 225 and p[2] > 225

seen = bytearray(w * h)
q = deque((x, y) for x in range(w) for y in (0, h - 1))
q.extend((x, y) for y in range(h) for x in (0, w - 1))
while q:
    x, y = q.popleft()
    i = y * w + x
    if seen[i] or not whitish(px[x, y]):
        continue
    seen[i] = 1
    px[x, y] = (255, 255, 255, 0)
    if x > 0: q.append((x - 1, y))
    if x < w - 1: q.append((x + 1, y))
    if y > 0: q.append((x, y - 1))
    if y < h - 1: q.append((x, y + 1))

box = im.getbbox()
im = im.crop(box)
side = int(max(im.size) * 1.08)
canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
canvas.paste(im, ((side - im.width) // 2, (side - im.height) // 2), im)
out = ROOT / "assets" / "kinds" / f"{kind}.png"
canvas.resize((512, 512), Image.LANCZOS).save(out)
print("wrote", out)
