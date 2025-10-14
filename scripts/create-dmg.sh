#!/bin/bash
set -e

# Configuration
APP_NAME="Music Assistant Player"
APP_BUNDLE="MusicAssistantPlayer.app"
DMG_NAME="MusicAssistantPlayer"
VERSION="0.1.0"
DMG_FINAL="${DMG_NAME}-${VERSION}.dmg"
DMG_TEMP="${DMG_NAME}-temp.dmg"
VOLUME_NAME="${APP_NAME}"
BACKGROUND_IMAGE="dmg-resources/background.png"

# Build locations
BUILD_DIR="build/Release"
DMG_DIR="dmg-staging"

# Use the pre-built and signed app from xcodebuild
echo "📦 Using pre-built signed app..."
BUILT_APP="build/Build/Products/Release/${APP_BUNDLE}"

# Verify the signed app exists
if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Pre-built app not found at: $BUILT_APP"
    echo "Expected path: build/Build/Products/Release/${APP_BUNDLE}"
    exit 1
fi

# Verify code signature
echo "🔍 Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "$BUILT_APP"

echo "✅ Built app at: $BUILT_APP"

# Create staging directory
echo "📦 Creating DMG staging area..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# Copy app to staging
cp -R "$BUILT_APP" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create temporary DMG
echo "💾 Creating temporary DMG..."
hdiutil create -volname "${VOLUME_NAME}" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    "$DMG_TEMP"

# Mount temporary DMG
echo "🔧 Mounting DMG for customization..."
MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP")
MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | grep -E '/Volumes/' | sed 1q | awk '{$1=$2=""; print $0}' | xargs)

echo "Mounted at: $MOUNT_DIR"

if [ -z "$MOUNT_DIR" ] || [ ! -d "$MOUNT_DIR" ]; then
    echo "❌ Failed to mount DMG"
    echo "Mount output: $MOUNT_OUTPUT"
    exit 1
fi

# Wait for mount
sleep 2

# Set background and icon positions
echo "🎨 Customizing DMG appearance..."

# Copy background image
mkdir -p "$MOUNT_DIR/.background"
cp "$BACKGROUND_IMAGE" "$MOUNT_DIR/.background/background.png"

# Use AppleScript to set up the DMG appearance
osascript <<EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to POSIX file "${MOUNT_DIR}/.background/background.png"

        -- Position app icon
        set position of item "${APP_BUNDLE}" of container window to {150, 200}

        -- Position Applications symlink
        set position of item "Applications" of container window to {450, 200}

        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

echo "⏳ Finalizing..."
sleep 2

# Unmount
hdiutil detach "$MOUNT_DIR"

# Convert to compressed DMG
echo "🗜️  Compressing final DMG..."
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL"

# Clean up
rm -f "$DMG_TEMP"
rm -rf "$DMG_DIR"

echo "✅ DMG created: $DMG_FINAL"
echo "📦 Size: $(du -h "$DMG_FINAL" | cut -f1)"
