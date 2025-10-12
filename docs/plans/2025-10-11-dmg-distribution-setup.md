# DMG Distribution Setup Implementation Plan

> **For Claude:** Use `${CLAUDE_PLUGIN_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Create a professional DMG distribution package for Music Assistant Player with proper .app bundle, fancy installer UI, and automated build scripts.

**Architecture:** Xcode project for .app bundle generation, shell scripts for DMG creation with custom background and layout, automated build pipeline.

**Tech Stack:** Xcode, Swift Package Manager, create-dmg or manual hdiutil, shell scripts

---

## Task 1: Generate Xcode Project

**Files:**
- Create: `MusicAssistantPlayer.xcodeproj/` (via xcodebuild or manual generation)
- Keep: `Package.swift` (for dependencies)

**Step 1: Generate Xcode project from Package.swift**

```bash
swift package generate-xcodeproj
```

**Step 2: Verify project structure**

Check that:
- MusicAssistantPlayer.xcodeproj exists
- Has proper target configuration
- Links to Package.swift dependencies

**Step 3: Test build**

```bash
xcodebuild -project MusicAssistantPlayer.xcodeproj -scheme MusicAssistantPlayer -configuration Release build
```

Expected: Builds successfully and creates .app in DerivedData

**Step 4: Commit Xcode project**

```bash
git add MusicAssistantPlayer.xcodeproj .gitignore
git commit -m "feat: add Xcode project for app bundle generation"
```

---

## Task 2: Create Info.plist

**Files:**
- Create: `Resources/Info.plist`

**Step 1: Create Resources directory if needed**

```bash
mkdir -p Resources
```

**Step 2: Create Info.plist**

Create `Resources/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>com.harperreed.musicassistantplayer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Music Assistant Player</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 Harper Reed. All rights reserved.</string>
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.music</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
```

**Step 3: Update Xcode project to use Info.plist**

Update build settings to point to Resources/Info.plist

**Step 4: Build to verify**

```bash
xcodebuild -project MusicAssistantPlayer.xcodeproj -scheme MusicAssistantPlayer -configuration Release build
```

**Step 5: Commit Info.plist**

```bash
git add Resources/Info.plist
git commit -m "feat: add Info.plist with app metadata"
```

---

## Task 3: Create App Icon

**Files:**
- Create: `Resources/AppIcon.icns`
- Create: `Resources/icon-sources/` (for generating icon)

**Step 1: Create placeholder icon**

For now, create a simple placeholder. Can be replaced with real design later.

Use `sips` to create icon from SF Symbol or placeholder:

```bash
mkdir -p Resources/icon-sources
# Create a 1024x1024 placeholder image
# For this task, we'll use iconutil to create .icns from .iconset
```

**Step 2: Create icon generation script**

Create `scripts/generate-icon.sh`:

```bash
#!/bin/bash
# Generates AppIcon.icns from a source image

SOURCE_IMAGE="Resources/icon-sources/icon-1024.png"
ICONSET="Resources/icon-sources/AppIcon.iconset"
OUTPUT="Resources/AppIcon.icns"

# Create iconset directory
mkdir -p "$ICONSET"

# Generate all required sizes
sips -z 16 16     "$SOURCE_IMAGE" --out "$ICONSET/icon_16x16.png"
sips -z 32 32     "$SOURCE_IMAGE" --out "$ICONSET/icon_16x16@2x.png"
sips -z 32 32     "$SOURCE_IMAGE" --out "$ICONSET/icon_32x32.png"
sips -z 64 64     "$SOURCE_IMAGE" --out "$ICONSET/icon_32x32@2x.png"
sips -z 128 128   "$SOURCE_IMAGE" --out "$ICONSET/icon_128x128.png"
sips -z 256 256   "$SOURCE_IMAGE" --out "$ICONSET/icon_128x128@2x.png"
sips -z 256 256   "$SOURCE_IMAGE" --out "$ICONSET/icon_256x256.png"
sips -z 512 512   "$SOURCE_IMAGE" --out "$ICONSET/icon_256x256@2x.png"
sips -z 512 512   "$SOURCE_IMAGE" --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ICONSET/icon_512x512@2x.png"

# Convert to icns
iconutil -c icns "$ICONSET" -o "$OUTPUT"

echo "Icon generated at $OUTPUT"
```

**Step 3: Create temporary placeholder icon**

For MVP, just create a simple colored square as placeholder.

**Step 4: Update Xcode project**

Add AppIcon.icns to Resources and configure in build settings.

**Step 5: Commit icon resources**

```bash
git add Resources/AppIcon.icns scripts/generate-icon.sh
git commit -m "feat: add app icon placeholder"
```

---

## Task 4: DMG Background Image

**Files:**
- Create: `dmg-resources/background.png`
- Create: `dmg-resources/background@2x.png`

**Step 1: Create DMG resources directory**

```bash
mkdir -p dmg-resources
```

**Step 2: Create background image**

Create a 600x400 background image with:
- Gradient background (dark, matching app theme)
- Text: "Drag Music Assistant Player to Applications"
- Roon-inspired aesthetic

For now, can be simple. Generate using script or tool.

**Step 3: Create background generation script**

Create `scripts/generate-dmg-background.sh`:

```bash
#!/bin/bash
# Generates DMG background image

OUTPUT="dmg-resources/background.png"
OUTPUT_2X="dmg-resources/background@2x.png"

# Use ImageMagick or native tools to create background
# For MVP, can be simple gradient with text

convert -size 600x400 \
    gradient:'#1a1a1f-#25252a' \
    -gravity center \
    -pointsize 24 \
    -fill white \
    -annotate +0+150 'Drag to Applications folder to install' \
    "$OUTPUT"

convert -size 1200x800 \
    gradient:'#1a1a1f-#25252a' \
    -gravity center \
    -pointsize 48 \
    -fill white \
    -annotate +0+300 'Drag to Applications folder to install' \
    "$OUTPUT_2X"

echo "Background images generated"
```

**Step 4: Generate backgrounds**

```bash
chmod +x scripts/generate-dmg-background.sh
./scripts/generate-dmg-background.sh
```

**Step 5: Commit DMG resources**

```bash
git add dmg-resources/ scripts/generate-dmg-background.sh
git commit -m "feat: add DMG background images"
```

---

## Task 5: DMG Creation Script

**Files:**
- Create: `scripts/create-dmg.sh`

**Step 1: Create DMG creation script**

Create `scripts/create-dmg.sh`:

```bash
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

echo "🔨 Building app..."
xcodebuild -project MusicAssistantPlayer.xcodeproj \
    -scheme MusicAssistantPlayer \
    -configuration Release \
    -derivedDataPath build \
    clean build

# Find the built app
BUILT_APP=$(find build -name "${APP_BUNDLE}" -type d | head -1)

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Failed to find built app"
    exit 1
fi

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
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | \
    grep -E '^/dev/' | sed 1q | awk '{print $NF}')

echo "Mounted at: $MOUNT_DIR"

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
        set background picture of viewOptions to file ".background:background.png"

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
```

**Step 2: Make script executable**

```bash
chmod +x scripts/create-dmg.sh
```

**Step 3: Test DMG creation**

```bash
./scripts/create-dmg.sh
```

Expected: Creates `MusicAssistantPlayer-0.1.0.dmg`

**Step 4: Commit DMG script**

```bash
git add scripts/create-dmg.sh
git commit -m "feat: add DMG creation script with fancy styling"
```

---

## Task 6: Build Automation Script

**Files:**
- Create: `scripts/build-release.sh`
- Update: `.gitignore`

**Step 1: Create comprehensive build script**

Create `scripts/build-release.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Music Assistant Player - Release Build"
echo "========================================"

# Check for required tools
command -v xcodebuild >/dev/null 2>&1 || { echo "❌ xcodebuild not found"; exit 1; }
command -v iconutil >/dev/null 2>&1 || { echo "❌ iconutil not found"; exit 1; }

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/
rm -f *.dmg

# Run tests
echo "🧪 Running tests..."
swift test

# Generate icon (if source exists)
if [ -f "Resources/icon-sources/icon-1024.png" ]; then
    echo "🎨 Generating app icon..."
    ./scripts/generate-icon.sh
fi

# Create DMG
echo "📦 Creating DMG..."
./scripts/create-dmg.sh

echo ""
echo "✅ Build complete!"
echo "📦 DMG: $(ls -1 *.dmg)"
echo ""
echo "To install:"
echo "  1. Open the DMG"
echo "  2. Drag Music Assistant Player to Applications"
echo "  3. Launch from Applications folder"
```

**Step 2: Make executable**

```bash
chmod +x scripts/build-release.sh
```

**Step 3: Update .gitignore**

Add to `.gitignore`:

```
# Xcode
build/
DerivedData/
*.xcodeproj/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/

# DMG outputs
*.dmg
dmg-staging/

# Icon generation
Resources/icon-sources/*.iconset/
```

**Step 4: Test full build**

```bash
./scripts/build-release.sh
```

Expected: Complete build from tests → app → DMG

**Step 5: Commit build automation**

```bash
git add scripts/build-release.sh .gitignore
git commit -m "feat: add automated release build script"
```

---

## Task 7: Documentation

**Files:**
- Update: `README.md`
- Create: `BUILDING.md`

**Step 1: Create BUILDING.md**

Create `BUILDING.md`:

```markdown
# Building Music Assistant Player

## Requirements

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Development Build

```bash
# Build and run
swift run

# Or use Xcode
open MusicAssistantPlayer.xcodeproj
```

## Release Build (DMG)

```bash
./scripts/build-release.sh
```

This will:
1. Run all tests
2. Build the app bundle
3. Create a styled DMG installer
4. Output: `MusicAssistantPlayer-0.1.0.dmg`

## Manual Steps

### Build App

```bash
xcodebuild -project MusicAssistantPlayer.xcodeproj \
    -scheme MusicAssistantPlayer \
    -configuration Release \
    build
```

### Create DMG

```bash
./scripts/create-dmg.sh
```

## Distribution

The DMG file can be distributed directly. Users will:
1. Download the DMG
2. Open it
3. Drag the app to Applications
4. Launch from Applications folder

**Note:** App is unsigned, so users will need to right-click → Open the first time.
```

**Step 2: Update README.md**

Add installation section to README.md:

```markdown
## Installation

### From DMG

1. Download `MusicAssistantPlayer-0.1.0.dmg`
2. Open the DMG file
3. Drag Music Assistant Player to Applications folder
4. Launch from Applications
5. On first run, right-click the app and select "Open" (unsigned app warning)

### From Source

```bash
git clone [repo-url]
cd ma
swift run
```

## Building

See [BUILDING.md](BUILDING.md) for detailed build instructions.
```

**Step 3: Commit documentation**

```bash
git add BUILDING.md README.md
git commit -m "docs: add build and installation documentation"
```

---

## Testing the Distribution

**Manual testing checklist:**

1. Run `./scripts/build-release.sh`
2. Verify DMG created successfully
3. Open the DMG
4. Verify background image displays
5. Verify app icon looks correct
6. Verify Applications symlink works
7. Drag app to Applications
8. Launch app from Applications
9. Verify app connects to Music Assistant server
10. Verify all functionality works

**Clean install test:**
1. Delete app from Applications if exists
2. Clear UserDefaults: `defaults delete com.harperreed.musicassistantplayer`
3. Install from DMG
4. Launch - should show server setup
5. Enter server details
6. Verify connection and player discovery

**This completes the DMG distribution setup plan.**
