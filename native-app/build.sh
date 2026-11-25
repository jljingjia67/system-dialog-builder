#!/bin/bash
set -e
cd "$(dirname "$0")"

APP_NAME="System Dialog"
APP_DIR="${APP_NAME}.app"

echo "Building ${APP_NAME}..."

# Compile
swiftc main.swift -o system-dialog \
  -framework Cocoa \
  -framework WebKit \
  -O

# Create .app bundle
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

mv system-dialog "${APP_DIR}/Contents/MacOS/system-dialog"

# Bundle the full web builder UI. prompt-ui.html (repo root, one level up) is in
# "artifact format" (starts with <title>/<style>, no <!DOCTYPE>/<html>/<head>/<body>),
# so wrap it in a valid standalone HTML skeleton as builder.html.
{
  printf '%s' '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head><body>'
  cat ../prompt-ui.html
  printf '%s' '</body></html>'
} > "${APP_DIR}/Contents/Resources/builder.html"

# Bundle the standalone popup dialog template. It is already a complete HTML
# document, so copy it as-is (no skeleton wrapping needed).
cp popup.html "${APP_DIR}/Contents/Resources/popup.html"

cat > "${APP_DIR}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>system-dialog</string>
    <key>CFBundleIdentifier</key>
    <string>com.dialog.builder</string>
    <key>CFBundleName</key>
    <string>System Dialog</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo ""
echo "Done! Launching ${APP_NAME}..."
echo "App location: $(pwd)/${APP_DIR}"
echo "(Drag it to your Applications folder to keep it.)"
echo ""

# Launch it. Because it was just compiled locally (not downloaded),
# it has no quarantine flag, so it opens with no Gatekeeper prompt.
open "${APP_DIR}"
