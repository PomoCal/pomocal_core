#!/bin/bash

# Configuration
APP_NAME="PomodoroCalendar"
BIN_PATH=$(swift build --show-bin-path)

# Create App Bundle Structure
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# Copy Binary
cp "$BIN_PATH/$APP_NAME" "$APP_NAME.app/Contents/MacOS/"

# Create basic PkgInfo
echo "APPL????" > "$APP_NAME.app/Contents/PkgInfo"

# Copy Info.plist
cp Info.plist "$APP_NAME.app/Contents/"

# Copy App Icon
cp AppIcon.icns "$APP_NAME.app/Contents/Resources/AppIcon.icns"

# Set Permissions
chmod +x "$APP_NAME.app/Contents/MacOS/$APP_NAME"

# Sign the app with entitlements (MUST be last step)
echo "Signing with entitlements..."
codesign --force --deep --sign - --entitlements Entitlements.plist "$APP_NAME.app"

echo "App bundle created at $APP_NAME.app"

# Create DMG
echo "Creating DMG..."
DMG_NAME="$APP_NAME.dmg"
# Remove existing DMG if it exists
rm -f "$DMG_NAME"
# Create a temporary folder for DMG contents to include a symlink to Applications
DMG_SRC_DIR="dmg_source"
rm -rf "$DMG_SRC_DIR"
mkdir -p "$DMG_SRC_DIR"
cp -r "$APP_NAME.app" "$DMG_SRC_DIR/"
ln -s /Applications "$DMG_SRC_DIR/Applications"

# Create the DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_SRC_DIR" -ov -format UDZO "$DMG_NAME"

# Cleanup
rm -rf "$DMG_SRC_DIR"

echo "DMG created at $DMG_NAME"
echo "You can open it with: open $DMG_NAME"
