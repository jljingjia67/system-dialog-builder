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
cp dialog.html "${APP_DIR}/Contents/Resources/" 2>/dev/null || true

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
echo "Done! Double-click to run:"
echo "  $(pwd)/${APP_DIR}"
echo ""
echo "Or drag it to your Applications folder."
