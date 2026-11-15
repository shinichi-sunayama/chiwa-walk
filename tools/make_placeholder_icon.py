# Temporary app icon until the Gemini icon is chosen (docs/art/icon.md).
# Needs Pillow. Usage (from the repository root): python tools/make_placeholder_icon.py
# Output: docs/art/icon/app_icon_placeholder.png (1024x1024, no transparency)
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "art" / "icon" / "app_icon_placeholder.png"
SIZE = 1024

img = Image.new("RGB", (SIZE, SIZE))
draw = ImageDraw.Draw(img)
top, bottom = (0xCF, 0xE9, 0xF7), (0xFB, 0xF3, 0xE4)  # sky -> cream (Theme.swift)
for y in range(SIZE):
    t = y / (SIZE - 1)
    draw.line([(0, y), (SIZE, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))

# A notebook page with a few colored dots (the four buttons), and おはぎ in front.
draw.rounded_rectangle([170, 150, 854, 780], radius=60, fill=(0xFF, 0xFD, 0xF8), outline=(0xE6, 0xD8, 0xBF), width=14)
for i, color in enumerate([(0xF2, 0xC2, 0x30), (0xA8, 0x75, 0x4A), (0x4F, 0xA3, 0xE0), (0xF3, 0x9A, 0x4C)]):
    y = 250 + i * 120
    draw.ellipse([250, y, 330, y + 80], fill=color)
    draw.rounded_rectangle([370, y + 25, 760, y + 55], radius=15, fill=(0xF2, 0xE9, 0xD8))

dog = Image.open(ROOT / "assets" / "dogs" / "ohagi.png").convert("RGBA")
scale = 560 / dog.height
dog = dog.resize((round(dog.width * scale), 560), Image.LANCZOS)
img.paste(dog, (SIZE - dog.width - 90, SIZE - dog.height - 50), dog)

OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT)
print("wrote", OUT)
