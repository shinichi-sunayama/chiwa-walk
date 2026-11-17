#!/bin/bash
# Take App Store screenshots with simulators (needs macOS + Xcode; used by .github/workflows/screenshots.yml).
# Run from the repository root after: bash tools/make_apple_assets.sh && xcodegen generate --spec apple/project.yml
# Output: shots/iphone/*.png (iPhone 6.3", 1206x2622) and shots/watch/*.png (Apple Watch)
set -euo pipefail

OUT=shots
DERIVED=derived-sim
mkdir -p "$OUT/iphone" "$OUT/watch"

pick_device() { # $1 = name regex; prints the UDID of the newest matching available device
  xcrun simctl list devices available -j | python3 -c '
import json, re, sys
pat = re.compile(sys.argv[1])
found = []
for runtime, devs in json.load(sys.stdin)["devices"].items():
    for d in devs:
        if pat.search(d["name"]):
            found.append((runtime, d["name"], d["udid"]))
found.sort()
if not found:
    sys.exit("no simulator matches " + sys.argv[1])
print(found[-1][2])
print(found[-1][1], file=sys.stderr)
' "$1"
}

xcrun simctl list runtimes
PHONE=$(pick_device '^iPhone 1[6-9] Pro$')  # 6.3" = 1206x2622, the size App Store Connect accepted for the other apps
WATCH=$(pick_device '^Apple Watch (Ultra|Series 1[01] \(46mm\))')

xcrun simctl boot "$PHONE" || true
xcrun simctl boot "$WATCH" || true
xcrun simctl bootstatus "$PHONE" -b
xcrun simctl bootstatus "$WATCH" -b
xcrun simctl status_bar "$PHONE" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true

xcodebuild build -project apple/Osanpo.xcodeproj -scheme Osanpo -configuration Debug \
  -destination "id=$PHONE" -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -n 30
xcodebuild build -project apple/Osanpo.xcodeproj -scheme OsanpoWatch -configuration Debug \
  -destination "id=$WATCH" -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO 2>&1 | tail -n 30

xcrun simctl install "$PHONE" "$DERIVED/Build/Products/Debug-iphonesimulator/Osanpo.app"
xcrun simctl install "$WATCH" "$DERIVED/Build/Products/Debug-watchsimulator/OsanpoWatch.app"

shoot() { # $1 device, $2 bundle id, $3 output file, rest = launch arguments
  local dev=$1 bundle=$2 file=$3
  shift 3
  xcrun simctl terminate "$dev" "$bundle" 2>/dev/null || true
  sleep 2
  xcrun simctl launch "$dev" "$bundle" -AppleLanguages "(ja)" -AppleLocale ja_JP "$@"
  sleep 9 # sheets slide in after launch
  xcrun simctl io "$dev" screenshot "$file"
  echo "saved $file"
}

APP=com.ohagikinakokobo.osanpo
WAPP=com.ohagikinakokobo.osanpo.watchkitapp
# -shotDemo YES fills in sample dogs and records (WalkCore DemoData); nothing is saved.
shoot "$PHONE" $APP "$OUT/iphone/1_today.png" -shotDemo YES -shotTab 0
shoot "$PHONE" $APP "$OUT/iphone/2_history.png" -shotDemo YES -shotTab 1
shoot "$PHONE" $APP "$OUT/iphone/3_settings.png" -shotDemo YES -shotTab 2
shoot "$WATCH" $WAPP "$OUT/watch/1_record.png" -shotDemo YES -shotPage 0
shoot "$WATCH" $WAPP "$OUT/watch/2_status.png" -shotDemo YES -shotPage 1

sips -g pixelWidth -g pixelHeight "$OUT"/iphone/*.png "$OUT"/watch/*.png
