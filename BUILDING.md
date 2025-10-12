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

## Automated Release (GitHub Actions)

The repository includes a GitHub Actions workflow for automated releases:

```bash
# Create and push a tag to trigger release build
git tag v0.1.0
git push origin v0.1.0
```

The workflow will:
1. Run all tests
2. Build the app bundle (unsigned)
3. Create a styled DMG
4. Create a GitHub Release with the DMG attached

**Code Signing:** The workflow includes commented-out steps for code signing and notarization. See [docs/CODE_SIGNING.md](docs/CODE_SIGNING.md) for setup instructions when ready.

## Distribution

The DMG file can be distributed directly. Users will:
1. Download the DMG
2. Open it
3. Drag the app to Applications
4. Launch from Applications folder

**Note:** App is unsigned, so users will need to right-click → Open the first time.
