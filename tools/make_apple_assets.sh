#!/bin/bash
# Make the asset catalogs for the iPhone and Watch apps (needs macOS: uses sips).
# Run from the repository root: bash tools/make_apple_assets.sh
# Inputs: the icon (docs/art/icon/app_icon_gemini.png or .jpg once chosen; until then the placeholder made by
#         tools/make_placeholder_icon.py) and the dog pictures assets/dogs/*.png.
# Outputs (not kept in git): apple/Generated/iOS.xcassets and apple/Generated/Watch.xcassets
set -euo pipefail

ICON_SRC=""
for f in docs/art/icon/app_icon_gemini.png docs/art/icon/app_icon_gemini.jpg docs/art/icon/app_icon_placeholder.png; do
  if [ -f "$f" ]; then ICON_SRC=$f; break; fi
done
echo "icon: $ICON_SRC"
OUT=apple/Generated
rm -rf "$OUT/iOS.xcassets" "$OUT/Watch.xcassets"

catalog() { # $1 = catalog dir, $2 = platform (ios / watchos)
  local cat=$1 platform=$2
  mkdir -p "$cat/AppIcon.appiconset"
  echo '{"info":{"author":"xcode","version":1}}' > "$cat/Contents.json"
  # 1024x1024 PNG with no transparency (the App Store refuses transparent icons).
  sips -s format png -z 1024 1024 "$ICON_SRC" --out "$cat/AppIcon.appiconset/icon-1024.png" > /dev/null
  cat > "$cat/AppIcon.appiconset/Contents.json" <<EOF
{"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"$platform","size":"1024x1024"}],"info":{"author":"xcode","version":1}}
EOF
  # Button illustrations (assets/kinds/pee.png or pee.svg etc., optional: the app shows emoji when missing).
  # SVG is kept as a vector (sharp at any size).
  for f in assets/kinds/*.png assets/kinds/*.svg; do
    [ -f "$f" ] || continue
    local file kname props
    file=$(basename "$f")
    kname=${file%.*}
    props=""
    case "$file" in *.svg) props=',"properties":{"preserves-vector-representation":true}' ;; esac
    mkdir -p "$cat/kind_$kname.imageset"
    cp "$f" "$cat/kind_$kname.imageset/$file"
    cat > "$cat/kind_$kname.imageset/Contents.json" <<EOF
{"images":[{"filename":"$file","idiom":"universal"}],"info":{"author":"xcode","version":1}$props}
EOF
  done
  for f in assets/dogs/*.png; do
    local name
    name=$(basename "$f" .png)
    mkdir -p "$cat/dog_$name.imageset"
    cp "$f" "$cat/dog_$name.imageset/$name.png"
    cat > "$cat/dog_$name.imageset/Contents.json" <<EOF
{"images":[{"filename":"$name.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}
EOF
  done
}

catalog "$OUT/iOS.xcassets" ios
catalog "$OUT/Watch.xcassets" watchos
echo "asset catalogs written to $OUT"
