# Make the round-icon pictures of the five dogs (head and chest, square, transparent) from the
# 3D-model sprites of chiwa-photo (about 340px tall; the old assets were 118x180 and looked blurry).
# Usage: python tools/make_dog_faces.py <folder with <name>_quarter.png>
# (e.g. C:\Users\sunay\Claude\chiwa-photo\Assets\_Game\Art\Sprites\Dogs). Output: assets/dogs/<name>.png (320x320)
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = Path(sys.argv[1])
# Square crop boxes (left, top, size) around each head, in sprite pixels; chosen by eye (top may be < 0: empty margin above the ears).
BOXES = {
    "ohagi": (50, -20, 255),
    "shiratama": (65, -20, 245),
    "kinako": (85, -20, 245),
    "yokan": (115, 0, 245),
    "dorayaki": (80, 0, 250),
}
for name, (x, y, s) in BOXES.items():
    im = Image.open(SRC / f"{name}_quarter.png").convert("RGBA")
    crop = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    crop.paste(im.crop((x, y, x + s, y + s)), (0, 0))
    out = ROOT / "assets" / "dogs" / f"{name}.png"
    crop.resize((320, 320), Image.LANCZOS).save(out)
    print("wrote", out)
