# Code Review Improvements Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Implement remaining medium and low priority improvements from code review: album art caching, error path testing, extract magic numbers, structured logging, and reduce parsing duplication.

**Architecture:** Add NSCache-based caching layer for images and colors, create comprehensive error scenario tests, extract responsive layout constants, implement os.Logger for structured logging, and consolidate EventParser duration parsing logic.

**Tech Stack:** SwiftUI, NSCache, XCTest, os.Logger (macOS 11+)

---

## Task 1: Implement Album Art and Color Caching

**Files:**
- Create: `Sources/MusicAssistantPlayer/Services/ImageCacheService.swift`
- Create: `Tests/MusicAssistantPlayerTests/Services/ImageCacheServiceTests.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/Components/BlurredArtworkBackground.swift:47-60`

**Step 1: Write test for image caching**

Create `Tests/MusicAssistantPlayerTests/Services/ImageCacheServiceTests.swift`:

```swift
import XCTest
@testable import MusicAssistantPlayer
#if canImport(AppKit)
import AppKit
#endif

@MainActor
final class ImageCacheServiceTests: XCTestCase {
    var cacheService: ImageCacheService!

    override func setUp() async throws {
        cacheService = ImageCacheService()
    }

    func testCacheImageAndRetrieve() {
        let url = URL(string: "https://example.com/image.jpg")!
        let testImage = NSImage(size: NSSize(width: 100, height: 100))

        // Cache image
        cacheService.cacheImage(testImage, for: url)

        // Retrieve image
        let cachedImage = cacheService.getImage(for: url)

        XCTAssertNotNil(cachedImage)
        XCTAssertEqual(cachedImage?.size, testImage.size)
    }

    func testCacheColorAndRetrieve() {
        let url = URL(string: "https://example.com/image.jpg")!
        let testColor = NSColor.red

        // Cache color
        cacheService.cacheColor(testColor, for: url)

        // Retrieve color
        let cachedColor = cacheService.getColor(for: url)

        XCTAssertNotNil(cachedColor)
        XCTAssertEqual(cachedColor, testColor)
    }

    func testCacheMissReturnsNil() {
        let url = URL(string: "https://example.com/nonexistent.jpg")!

        XCTAssertNil(cacheService.getImage(for: url))
        XCTAssertNil(cacheService.getColor(for: url))
    }

    func testClearCache() {
        let url = URL(string: "https://example.com/image.jpg")!
        let testImage = NSImage(size: NSSize(width: 100, height: 100))

        cacheService.cacheImage(testImage, for: url)
        XCTAssertNotNil(cacheService.getImage(for: url))

        cacheService.clearCache()
        XCTAssertNil(cacheService.getImage(for: url))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ImageCacheServiceTests`
Expected: FAIL with "No such module ImageCacheService"

**Step 3: Create ImageCacheService**

Create `Sources/MusicAssistantPlayer/Services/ImageCacheService.swift`:

```swift
// ABOUTME: Caching service for album artwork images and extracted colors
// ABOUTME: Uses NSCache for automatic memory management and eviction policies

#if canImport(AppKit)
import AppKit
import SwiftUI

@MainActor
class ImageCacheService {
    private let imageCache = NSCache<NSURL, NSImage>()
    private let colorCache = NSCache<NSURL, NSColor>()

    init() {
        // Configure cache limits
        imageCache.countLimit = 50 // Max 50 images
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB

        colorCache.countLimit = 100 // Colors are small, cache more
    }

    // MARK: - Image Caching

    func cacheImage(_ image: NSImage, for url: URL) {
        imageCache.setObject(image, forKey: url as NSURL)
    }

    func getImage(for url: URL) -> NSImage? {
        return imageCache.object(forKey: url as NSURL)
    }

    // MARK: - Color Caching

    func cacheColor(_ color: NSColor, for url: URL) {
        colorCache.setObject(color, forKey: url as NSURL)
    }

    func getColor(for url: URL) -> NSColor? {
        return colorCache.object(forKey: url as NSURL)
    }

    // MARK: - Cache Management

    func clearCache() {
        imageCache.removeAllObjects()
        colorCache.removeAllObjects()
    }
}
#endif
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ImageCacheServiceTests`
Expected: All 4 tests passing

**Step 5: Update BlurredArtworkBackground to use cache**

In `BlurredArtworkBackground.swift`, add cache property and update extractColor:

```swift
struct BlurredArtworkBackground: View {
    let artworkURL: URL?
    let cacheService: ImageCacheService

    @State private var dominantColor: Color?
    @State private var loadedImage: NSImage?

    var body: some View {
        // ... existing body
    }

    #if canImport(AppKit)
    private func extractColor(from url: URL) async {
        // Check cache first
        if let cachedColor = cacheService.getColor(for: url) {
            await MainActor.run {
                self.dominantColor = Color(cachedColor)
            }
            return
        }

        // Check for cached image
        if let cachedImage = cacheService.getImage(for: url) {
            extractAndCacheColor(from: cachedImage, url: url)
            return
        }

        // Download and extract color from actual image
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let nsImage = NSImage(data: data) else {
            return
        }

        // Cache the downloaded image
        cacheService.cacheImage(nsImage, for: url)

        extractAndCacheColor(from: nsImage, url: url)
    }

    private func extractAndCacheColor(from image: NSImage, url: URL) {
        let extractor = ColorExtractor()
        if let nsColor = extractor.extractDominantColor(from: image) {
            // Cache the extracted color
            cacheService.cacheColor(nsColor, for: url)

            MainActor.run {
                self.dominantColor = Color(nsColor)
            }
        }
    }
    #endif
}
```

**Step 6: Update MainWindowView to pass cache service**

Add `@StateObject` for cache service in MainWindowView and pass to components.

**Step 7: Run all tests**

Run: `swift test`
Expected: All tests passing

**Step 8: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/ImageCacheService.swift
git add Tests/MusicAssistantPlayerTests/Services/ImageCacheServiceTests.swift
git add Sources/MusicAssistantPlayer/Views/Components/BlurredArtworkBackground.swift
git add Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git commit -m "feat: add album art and color caching for improved performance"
```

---

## Task 2: Add Comprehensive Error Path Testing

**Files:**
- Modify: `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Models/EventParserTests.swift`

**Step 1: Add network failure tests**

Add to `PlayerServiceTests.swift`:

```swift
func testNetworkFailureHandling() async {
    let service = PlayerService(client: nil)

    // Attempt operation without client
    await service.play()

    // Verify error is published
    XCTAssertNotNil(service.lastError)
    if case .networkError = service.lastError {
        // Expected error type
    } else {
        XCTFail("Expected networkError, got \(String(describing: service.lastError))")
    }
}

func testPlayerNotFoundError() async {
    // Create service with client but no selected player
    let mockClient = MusicAssistantClient(host: "test", port: 8095)
    let service = PlayerService(client: mockClient)

    // Attempt operation without selected player
    await service.play()

    // Verify error is published
    XCTAssertNotNil(service.lastError)
    if case .playerNotFound = service.lastError {
        // Expected error type
    } else {
        XCTFail("Expected playerNotFound, got \(String(describing: service.lastError))")
    }
}
```

**Step 2: Add malformed data parsing tests**

Add to `EventParserTests.swift`:

```swift
func testParseMalformedTrackData() {
    let malformedData: [String: AnyCodable] = [
        "current_media": AnyCodable("invalid string instead of dict")
    ]

    let track = EventParser.parseTrack(from: malformedData)
    XCTAssertNil(track, "Should return nil for malformed data")
}

func testParseTrackWithMissingFields() {
    let incompleteData: [String: AnyCodable] = [
        "current_media": AnyCodable([
            "uri": "test:uri"
            // Missing name, artists, etc.
        ] as [String: Any])
    ]

    let track = EventParser.parseTrack(from: incompleteData)
    // Should handle gracefully with default values
    XCTAssertNotNil(track)
    XCTAssertEqual(track?.title, "Unknown Track")
}

func testParseProgressWithInvalidData() {
    let invalidData: [String: AnyCodable] = [
        "elapsed_time": AnyCodable("not a number")
    ]

    let progress = EventParser.parseProgress(from: invalidData)
    XCTAssertNil(progress, "Should return nil for invalid progress data")
}
```

**Step 3: Run tests to verify they fail or pass appropriately**

Run: `swift test`
Expected: New tests may reveal bugs or pass if error handling is already robust

**Step 4: Fix any issues found**

If tests reveal bugs, fix the error handling in EventParser or PlayerService.

**Step 5: Commit**

```bash
git add Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift
git add Tests/MusicAssistantPlayerTests/Models/EventParserTests.swift
git commit -m "test: add comprehensive error path testing"
```

---

## Task 3: Extract Magic Numbers to Constants

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift:89-122`
- Modify: `Sources/MusicAssistantPlayer/Views/NowPlayingView.swift:103-131`

**Step 1: No test needed**

This is a refactoring that maintains behavior.

**Step 2: Add constants to MainWindowView**

At top of MainWindowView struct, add:

```swift
// MARK: - Responsive Layout Constants

private enum LayoutBreakpoint {
    static let miniplayerWidth: CGFloat = 700
    static let queueHideWidth: CGFloat = 1000
    static let mediumWindow: CGFloat = 800
    static let largeWindow: CGFloat = 1200
}

private enum SidebarWidth {
    static let small: CGFloat = 180
    static let medium: CGFloat = 200
    static let large: CGFloat = 280
    static let extraLarge: CGFloat = 300
}

private enum QueueWidth {
    static let small: CGFloat = 280
    static let large: CGFloat = 300
}
```

**Step 3: Replace magic numbers in MainWindowView**

Update responsive layout methods:

```swift
private func sidebarWidth(for size: CGSize) -> CGFloat {
    if size.width < LayoutBreakpoint.mediumWindow {
        return SidebarWidth.small
    } else if size.width < LayoutBreakpoint.queueHideWidth {
        return SidebarWidth.medium
    } else if size.width < LayoutBreakpoint.largeWindow {
        return SidebarWidth.large
    } else {
        return SidebarWidth.extraLarge
    }
}

private func queueWidth(for size: CGSize) -> CGFloat {
    if size.width < LayoutBreakpoint.queueHideWidth {
        return QueueWidth.small
    } else if size.width < LayoutBreakpoint.largeWindow {
        return QueueWidth.small
    } else {
        return QueueWidth.large
    }
}

private func shouldShowQueue(for size: CGSize) -> Bool {
    size.width >= LayoutBreakpoint.queueHideWidth
}

private func shouldShowSidebar(for size: CGSize) -> Bool {
    size.width >= LayoutBreakpoint.miniplayerWidth
}
```

**Step 4: Add constants to NowPlayingView**

Add at top of NowPlayingView:

```swift
// MARK: - Responsive Layout Constants

private enum LayoutBreakpoint {
    static let miniplayerWidth: CGFloat = 700
    static let smallWindow: CGFloat = 800
    static let largeWindow: CGFloat = 1200
}

private enum AlbumArtSize {
    static let sizeMultiplier: CGFloat = 0.55
    static let maximum: CGFloat = 800
}

private enum FontSize {
    static let titleSmall: CGFloat = 24
    static let titleLarge: CGFloat = 28
    static let metadataSmall: CGFloat = 14
    static let metadataLarge: CGFloat = 18
}

private enum Spacing {
    static let small: CGFloat = 16
    static let large: CGFloat = 24
}

private enum ControlsWidth {
    static let standard: CGFloat = 600
    static let large: CGFloat = 700
}
```

**Step 5: Replace magic numbers in NowPlayingView**

Update responsive sizing methods:

```swift
private func albumArtSize(for size: CGSize) -> CGFloat {
    let baseSize = min(size.width, size.height) * AlbumArtSize.sizeMultiplier
    return min(baseSize, AlbumArtSize.maximum)
}

private func titleFontSize(for size: CGSize) -> CGFloat {
    size.width < LayoutBreakpoint.smallWindow ? FontSize.titleSmall : FontSize.titleLarge
}

private func metadataFontSize(for size: CGSize) -> CGFloat {
    size.width < LayoutBreakpoint.smallWindow ? FontSize.metadataSmall : FontSize.metadataLarge
}

private func responsiveSpacing(for size: CGSize) -> CGFloat {
    size.width < LayoutBreakpoint.smallWindow ? Spacing.small : Spacing.large
}

private func controlsMaxWidth(for size: CGSize) -> CGFloat {
    size.width > LayoutBreakpoint.largeWindow ? ControlsWidth.large : ControlsWidth.standard
}
```

**Step 6: Update miniplayer check in overlay**

```swift
if geometry.size.width < LayoutBreakpoint.miniplayerWidth {
```

**Step 7: Run all tests**

Run: `swift test`
Expected: All tests passing (behavior unchanged)

**Step 8: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git add Sources/MusicAssistantPlayer/Views/NowPlayingView.swift
git commit -m "refactor: extract responsive layout magic numbers to named constants"
```

---

## Task 4: Implement Structured Logging

**Files:**
- Create: `Sources/MusicAssistantPlayer/Utilities/AppLogger.swift`
- Modify: `Sources/MusicAssistantPlayer/Services/PlayerService.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift`

**Step 1: No test needed**

Logging is typically not unit tested, verified through runtime observation.

**Step 2: Create AppLogger utility**

Create `Sources/MusicAssistantPlayer/Utilities/AppLogger.swift`:

```swift
// ABOUTME: Structured logging utility using os.Logger for macOS
// ABOUTME: Provides category-based loggers with consistent formatting

import Foundation
import os.log

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.musicassistant.player"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let player = Logger(subsystem: subsystem, category: "player")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let cache = Logger(subsystem: subsystem, category: "cache")
    static let errors = Logger(subsystem: subsystem, category: "errors")
}

// MARK: - Convenience Extensions

extension Logger {
    func logError(_ error: Error, context: String) {
        self.error("\(context): \(error.localizedDescription)")
    }

    func logPlayerError(_ error: PlayerError, context: String) {
        self.error("\(context): \(error.userMessage) - \(error.technicalDetails)")
    }
}
```

**Step 3: Replace print statements in PlayerService**

Update PlayerService to use structured logging:

```swift
// Replace print statements with logging
import os.log

func play() async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        AppLogger.player.info("Playing on player: \(player.name)")
        try await client.play(playerId: player.id)
        lastError = nil
    } catch let error as PlayerError {
        AppLogger.errors.logPlayerError(error, context: "play()")
        self.lastError = error
    } catch {
        AppLogger.errors.logError(error, context: "play()")
        self.lastError = .commandFailed("play", reason: error.localizedDescription)
    }
}
```

**Step 4: Replace print in MainWindowView**

Update error handling and debug messages:

```swift
do {
    if let result = try await client.getPlayers() {
        // ... existing code
    }
} catch {
    AppLogger.network.error("Failed to fetch players: \(error.localizedDescription)")
}
```

**Step 5: Add logging to cache operations**

In ImageCacheService:

```swift
func cacheImage(_ image: NSImage, for url: URL) {
    imageCache.setObject(image, forKey: url as NSURL)
    AppLogger.cache.debug("Cached image for URL: \(url.absoluteString)")
}
```

**Step 6: Run and verify logs**

Run: `swift run`
Expected: Structured logs appear in Console.app under subsystem filter

**Step 7: Commit**

```bash
git add Sources/MusicAssistantPlayer/Utilities/AppLogger.swift
git add Sources/MusicAssistantPlayer/Services/PlayerService.swift
git add Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git commit -m "feat: implement structured logging with os.Logger"
```

---

## Task 5: Reduce Code Duplication in EventParser

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Models/EventParser.swift`

**Step 1: Write test for shared duration parsing**

Add to `EventParserTests.swift`:

```swift
func testParseDuration() {
    let validDuration = EventParser.parseDuration(from: 354.5)
    XCTAssertEqual(validDuration, 354.5)

    let zeroDuration = EventParser.parseDuration(from: nil)
    XCTAssertEqual(zeroDuration, 0.0)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter EventParserTests/testParseDuration`
Expected: FAIL (method doesn't exist)

**Step 3: Extract common duration parsing logic**

In `EventParser.swift`, add shared method:

```swift
static func parseDuration(from value: Any?) -> Double {
    if let duration = value as? Double {
        return duration
    } else if let duration = value as? Int {
        return Double(duration)
    }
    return 0.0
}
```

**Step 4: Update parseTrack to use shared method**

Replace duration parsing in `parseTrack`:

```swift
duration: parseDuration(from: currentMedia["duration"])
```

**Step 5: Update parseQueueItems to use shared method**

Replace duration parsing in `parseQueueItems`:

```swift
duration: parseDuration(from: item["duration"])
```

**Step 6: Run tests to verify**

Run: `swift test`
Expected: All tests passing, including new duration test

**Step 7: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/EventParser.swift
git add Tests/MusicAssistantPlayerTests/Models/EventParserTests.swift
git commit -m "refactor: consolidate duration parsing logic in EventParser"
```

---

## Success Criteria

✅ Album art and color caching implemented with NSCache
✅ Comprehensive error path testing added (network, malformed data)
✅ All magic numbers extracted to named constants
✅ Structured logging with os.Logger implemented
✅ Duration parsing logic consolidated in EventParser
✅ All tests passing (43+ existing + new tests)
✅ No regressions in functionality

## Notes

**After completion:**
- Monitor cache hit rates in production logs
- Review Console.app logs to verify structured logging
- Consider adding cache size metrics to UI (future enhancement)
