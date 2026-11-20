#!/usr/bin/env bash
# Собирает build/LimitsWidget.app (FR-011). Переменные: BUNDLE_ID (по умолчанию local.limitswidget).
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID="${BUNDLE_ID:-local.limitswidget}"
VERSION="${VERSION:-1.0.0}"
APP="build/LimitsWidget.app"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/LimitsWidget" "$APP/Contents/MacOS/LimitsWidget"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleName</key><string>LimitsWidget</string>
    <key>CFBundleExecutable</key><string>LimitsWidget</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

plutil -lint "$APP/Contents/Info.plist"
codesign --force -s - "$APP"
echo "Готово: $APP"
