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
