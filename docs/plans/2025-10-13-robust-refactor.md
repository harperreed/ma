# Robust Refactor Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Transform the Music Assistant Player from 30% complete to shipping-quality by building a solid foundation (services → viewmodels → views → integration).

**Architecture:** Bottom-up refactoring starting with services/models layer (data + business logic), then viewmodels (state transformation), then views (presentation), then integration. Each layer fully complete and tested before moving up.

**Tech Stack:** Swift 5.9+, SwiftUI, Combine, MusicAssistantKit, XCTest

---

## LAYER 1: SERVICES & MODELS

### Task 1: Create Domain Error Types

**Files:**
- Create: `Sources/MusicAssistantPlayer/Services/QueueError.swift`
- Create: `Sources/MusicAssistantPlayer/Services/LibraryError.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/QueueErrorTests.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/LibraryErrorTests.swift`

**Step 1: Write failing test for QueueError**

Create `Tests/MusicAssistantPlayerTests/Services/QueueErrorTests.swift`:

```swift
import XCTest
@testable import MusicAssistantPlayer

final class QueueErrorTests: XCTestCase {
    func testQueueErrorLocalizedDescription() {
        let error = QueueError.queueNotFound("test-queue-id")
        XCTAssertTrue(error.localizedDescription.contains("test-queue-id"))
    }

    func testCommandFailedError() {
        let error = QueueError.commandFailed("shuffle", reason: "network timeout")
        XCTAssertTrue(error.localizedDescription.contains("shuffle"))
        XCTAssertTrue(error.localizedDescription.contains("network timeout"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter QueueErrorTests`
Expected: FAIL with "QueueError not defined"

**Step 3: Write QueueError implementation**

Create `Sources/MusicAssistantPlayer/Services/QueueError.swift`:

```swift
// ABOUTME: Domain-specific errors for queue operations
// ABOUTME: Provides detailed error context for queue management failures

import Foundation

enum QueueError: Error, LocalizedError {
    case queueNotFound(String)
    case itemNotFound(String)
    case networkError(String)
    case commandFailed(String, reason: String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .queueNotFound(let queueId):
            return "Queue not found: \(queueId)"
        case .itemNotFound(let itemId):
            return "Queue item not found: \(itemId)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .commandFailed(let command, let reason):
            return "Queue command '\(command)' failed: \(reason)"
        case .parseError(let message):
            return "Failed to parse queue data: \(message)"
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter QueueErrorTests`
Expected: PASS

**Step 5: Write failing test for LibraryError**

Create `Tests/MusicAssistantPlayerTests/Services/LibraryErrorTests.swift`:

```swift
import XCTest
@testable import MusicAssistantPlayer

final class LibraryErrorTests: XCTestCase {
    func testLibraryErrorLocalizedDescription() {
        let error = LibraryError.networkError("connection timeout")
        XCTAssertTrue(error.localizedDescription.contains("connection timeout"))
    }

    func testCategoryNotImplemented() {
        let error = LibraryError.categoryNotImplemented(.radio)
        XCTAssertTrue(error.localizedDescription.contains("radio"))
    }
}
```

**Step 6: Run test to verify it fails**

Run: `swift test --filter LibraryErrorTests`
Expected: FAIL with "LibraryError not defined"

**Step 7: Write LibraryError implementation**

Create `Sources/MusicAssistantPlayer/Services/LibraryError.swift`:

```swift
// ABOUTME: Domain-specific errors for library operations
// ABOUTME: Provides detailed error context for library browsing and search failures

import Foundation

enum LibraryError: Error, LocalizedError {
    case networkError(String)
    case parseError(String)
    case searchFailed(String)
    case categoryNotImplemented(LibraryCategory)
    case noClientAvailable

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .parseError(let message):
            return "Failed to parse library data: \(message)"
        case .searchFailed(let query):
            return "Search failed for query: \(query)"
        case .categoryNotImplemented(let category):
            return "Category not yet implemented: \(category.displayName)"
        case .noClientAvailable:
            return "Music Assistant client not available"
        }
    }
}
```

**Step 8: Run test to verify it passes**

Run: `swift test --filter LibraryErrorTests`
Expected: PASS

**Step 9: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/QueueError.swift \
        Sources/MusicAssistantPlayer/Services/LibraryError.swift \
        Tests/MusicAssistantPlayerTests/Services/QueueErrorTests.swift \
        Tests/MusicAssistantPlayerTests/Services/LibraryErrorTests.swift
git commit -m "feat: add domain error types for Queue and Library services"
```

---

### Task 2: Expand EventParser for Missing State

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/EventParser.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/EventParserTests.swift`

**Step 1: Write failing test for shuffle state parsing**

Add to `Tests/MusicAssistantPlayerTests/Services/EventParserTests.swift`:

```swift
func testParseShuffleState() {
    let data: [String: AnyCodable] = [
        "shuffle": AnyCodable(true)
    ]

    let isShuffled = EventParser.parseShuffleState(from: data)
    XCTAssertTrue(isShuffled)
}

func testParseShuffleStateDefault() {
    let data: [String: AnyCodable] = [:]

    let isShuffled = EventParser.parseShuffleState(from: data)
    XCTAssertFalse(isShuffled)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter EventParserTests`
Expected: FAIL with "parseShuffleState not found"

**Step 3: Add parseShuffleState implementation**

Add to `Sources/MusicAssistantPlayer/Services/EventParser.swift`:

```swift
static func parseShuffleState(from data: [String: AnyCodable]) -> Bool {
    if let shuffle = data["shuffle"]?.value as? Bool {
        return shuffle
    }
    // Also check queue_settings if present
    if let queueSettings = data["queue_settings"] as? [String: Any],
       let shuffle = queueSettings["shuffle"] as? Bool {
        return shuffle
    }
    return false
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter EventParserTests`
Expected: PASS

**Step 5: Write failing test for repeat mode parsing**

Add to test file:

```swift
func testParseRepeatMode() {
    let dataOff: [String: AnyCodable] = ["repeat": AnyCodable("off")]
    XCTAssertEqual(EventParser.parseRepeatMode(from: dataOff), "off")

    let dataAll: [String: AnyCodable] = ["repeat": AnyCodable("all")]
    XCTAssertEqual(EventParser.parseRepeatMode(from: dataAll), "all")

    let dataOne: [String: AnyCodable] = ["repeat": AnyCodable("one")]
    XCTAssertEqual(EventParser.parseRepeatMode(from: dataOne), "one")
}

func testParseRepeatModeDefault() {
    let data: [String: AnyCodable] = [:]
    XCTAssertEqual(EventParser.parseRepeatMode(from: data), "off")
}
```

**Step 6: Run test to verify it fails**

Run: `swift test --filter EventParserTests`
Expected: FAIL

**Step 7: Add parseRepeatMode implementation**

```swift
static func parseRepeatMode(from data: [String: AnyCodable]) -> String {
    if let repeatMode = data["repeat"]?.value as? String {
        return repeatMode
    }
    // Also check queue_settings if present
    if let queueSettings = data["queue_settings"] as? [String: Any],
       let repeatMode = queueSettings["repeat"] as? String {
        return repeatMode
    }
    return "off"
}
```

**Step 8: Run test to verify it passes**

Run: `swift test --filter EventParserTests`
Expected: PASS

**Step 9: Write failing test for group status parsing**

```swift
func testParseGroupStatus() {
    let dataGrouped: [String: AnyCodable] = [
        "group_childs": AnyCodable(["child1", "child2"])
    ]
    let grouped = EventParser.parseGroupStatus(from: dataGrouped)
    XCTAssertTrue(grouped.isGrouped)
    XCTAssertEqual(grouped.childIds, ["child1", "child2"])

    let dataSingle: [String: AnyCodable] = [:]
    let single = EventParser.parseGroupStatus(from: dataSingle)
    XCTAssertFalse(single.isGrouped)
    XCTAssertTrue(single.childIds.isEmpty)
}
```

**Step 10: Run test to verify it fails**

Run: `swift test --filter EventParserTests`
Expected: FAIL

**Step 11: Add parseGroupStatus implementation**

```swift
struct GroupStatus {
    let isGrouped: Bool
    let childIds: [String]
}

static func parseGroupStatus(from data: [String: AnyCodable]) -> GroupStatus {
    if let childIds = data["group_childs"]?.value as? [String], !childIds.isEmpty {
        return GroupStatus(isGrouped: true, childIds: childIds)
    }
    return GroupStatus(isGrouped: false, childIds: [])
}
```

**Step 12: Run test to verify it passes**

Run: `swift test --filter EventParserTests`
Expected: PASS

**Step 13: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/EventParser.swift \
        Tests/MusicAssistantPlayerTests/Services/EventParserTests.swift
git commit -m "feat: add shuffle, repeat, and group status parsing to EventParser"
```

---

### Task 3: Add Shuffle/Repeat to PlayerService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/PlayerService.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`

**Step 1: Add published properties for shuffle/repeat state**

Add to `PlayerService` class after existing `@Published` properties:

```swift
@Published var isShuffled: Bool = false
@Published var repeatMode: String = "off" // "off", "all", "one"
```

**Step 2: Write failing test for setShuffle**

Add to `PlayerServiceTests`:

```swift
func testSetShufflePublishesError() async {
    let service = PlayerService(client: nil)

    await service.setShuffle(enabled: true)

    XCTAssertNotNil(service.lastError)
    if case .networkError = service.lastError {
        // Expected
    } else {
        XCTFail("Expected networkError")
    }
}
```

**Step 3: Run test to verify it fails**

Run: `swift test --filter PlayerServiceTests/testSetShuffle`
Expected: FAIL with "setShuffle not found"

**Step 4: Implement setShuffle method**

Add to `PlayerService`:

```swift
func setShuffle(enabled: Bool) async {
    // Optimistically update for immediate UI feedback
    self.isShuffled = enabled

    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        AppLogger.player.info("Setting shuffle to: \(enabled) on player: \(player.name)")

        // Music Assistant API: player_queues/queue_command with shuffle
        try await client.sendCommand(
            command: "player_queues/queue_command",
            args: [
                "queue_id": player.id,
                "command": "shuffle",
                "shuffle": enabled
            ]
        )
        lastError = nil
    } catch let error as PlayerError {
        AppLogger.errors.logPlayerError(error, context: "setShuffle(\(enabled))")
        lastError = error
        // Rollback on failure
        self.isShuffled = !enabled
    } catch {
        AppLogger.errors.logError(error, context: "setShuffle(\(enabled))")
        lastError = .commandFailed("setShuffle", reason: error.localizedDescription)
        self.isShuffled = !enabled
    }
}
```

**Step 5: Run test to verify it passes**

Run: `swift test --filter PlayerServiceTests/testSetShuffle`
Expected: PASS

**Step 6: Write failing test for setRepeat**

```swift
func testSetRepeatPublishesError() async {
    let service = PlayerService(client: nil)

    await service.setRepeat(mode: "all")

    XCTAssertNotNil(service.lastError)
}
```

**Step 7: Run test to verify it fails**

Run: `swift test --filter PlayerServiceTests/testSetRepeat`
Expected: FAIL

**Step 8: Implement setRepeat method**

```swift
func setRepeat(mode: String) async {
    // Optimistically update for immediate UI feedback
    self.repeatMode = mode

    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        AppLogger.player.info("Setting repeat to: \(mode) on player: \(player.name)")

        // Music Assistant API: player_queues/queue_command with repeat
        try await client.sendCommand(
            command: "player_queues/queue_command",
            args: [
                "queue_id": player.id,
                "command": "repeat",
                "repeat": mode
            ]
        )
        lastError = nil
    } catch let error as PlayerError {
        AppLogger.errors.logPlayerError(error, context: "setRepeat(\(mode))")
        lastError = error
        // Rollback on failure
        self.repeatMode = mode == "off" ? "all" : "off"
    } catch {
        AppLogger.errors.logError(error, context: "setRepeat(\(mode))")
        lastError = .commandFailed("setRepeat", reason: error.localizedDescription)
        self.repeatMode = mode == "off" ? "all" : "off"
    }
}
```

**Step 9: Run test to verify it passes**

Run: `swift test --filter PlayerServiceTests/testSetRepeat`
Expected: PASS

**Step 10: Update subscribeToPlayerEvents to parse shuffle/repeat**

Add to `subscribeToPlayerEvents` method in the MainActor.run block after volume parsing:

```swift
// Parse shuffle state
let newShuffled = EventParser.parseShuffleState(from: event.data)
if newShuffled != self.isShuffled {
    AppLogger.player.debug("Shuffle update: \(newShuffled)")
    self.isShuffled = newShuffled
}

// Parse repeat mode
let newRepeatMode = EventParser.parseRepeatMode(from: event.data)
if newRepeatMode != self.repeatMode {
    AppLogger.player.debug("Repeat mode update: \(newRepeatMode)")
    self.repeatMode = newRepeatMode
}
```

**Step 11: Update fetchPlayerState to parse shuffle/repeat**

Add after volume parsing in `fetchPlayerState`:

```swift
// Parse shuffle state
isShuffled = EventParser.parseShuffleState(from: anyCodableData)

// Parse repeat mode
repeatMode = EventParser.parseRepeatMode(from: anyCodableData)
```

**Step 12: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/PlayerService.swift \
        Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift
git commit -m "feat: add shuffle and repeat functionality to PlayerService"
```

---

### Task 4: Add Like/Favorite to PlayerService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/PlayerService.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`

**Step 1: Add published property for favorite state**

Add to `PlayerService`:

```swift
@Published var isFavorite: Bool = false
```

**Step 2: Write failing test for toggleFavorite**

```swift
func testToggleFavoritePublishesError() async {
    let service = PlayerService(client: nil)

    await service.toggleFavorite(trackId: "test-track-id")

    XCTAssertNotNil(service.lastError)
}
```

**Step 3: Run test to verify it fails**

Run: `swift test --filter PlayerServiceTests/testToggleFavorite`
Expected: FAIL

**Step 4: Implement toggleFavorite method**

```swift
func toggleFavorite(trackId: String) async {
    // Optimistically toggle for immediate UI feedback
    self.isFavorite.toggle()
    let newState = self.isFavorite

    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }

        AppLogger.player.info("Toggling favorite for track: \(trackId) to: \(newState)")

        // Music Assistant API: music/tracks/favorite
        try await client.sendCommand(
            command: "music/tracks/favorite",
            args: [
                "item_id": trackId,
                "favorite": newState
            ]
        )
        lastError = nil
    } catch let error as PlayerError {
        AppLogger.errors.logPlayerError(error, context: "toggleFavorite(\(trackId))")
        lastError = error
        // Rollback on failure
        self.isFavorite = !newState
    } catch {
        AppLogger.errors.logError(error, context: "toggleFavorite(\(trackId))")
        lastError = .commandFailed("toggleFavorite", reason: error.localizedDescription)
        self.isFavorite = !newState
    }
}
```

**Step 5: Run test to verify it passes**

Run: `swift test --filter PlayerServiceTests/testToggleFavorite`
Expected: PASS

**Step 6: Add method to check if track is favorite**

```swift
func checkIfFavorite(trackId: String) async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }

        // Music Assistant API: music/tracks/get
        let result = try await client.sendCommand(
            command: "music/tracks/get",
            args: ["item_id": trackId]
        )

        // Parse favorite status from result
        if let result = result,
           let trackData = result.value as? [String: Any],
           let favorite = trackData["favorite"] as? Bool {
            self.isFavorite = favorite
        } else {
            self.isFavorite = false
        }

        lastError = nil
    } catch let error as PlayerError {
        AppLogger.errors.logPlayerError(error, context: "checkIfFavorite(\(trackId))")
        lastError = error
    } catch {
        AppLogger.errors.logError(error, context: "checkIfFavorite(\(trackId))")
        lastError = .commandFailed("checkIfFavorite", reason: error.localizedDescription)
    }
}
```

**Step 7: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/PlayerService.swift \
        Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift
git commit -m "feat: add favorite/like functionality to PlayerService"
```

---

### Task 5: Add Queue Manipulation to QueueService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/QueueService.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift`

**Step 1: Update error handling to use QueueError**

Change the QueueService initializer and add import:

```swift
import Foundation
import MusicAssistantKit
import os.log

@MainActor
class QueueService: ObservableObject {
    // ... existing properties ...
    @Published var lastError: QueueError?

    // Remove the string error property if it exists
}
```

**Step 2: Write failing test for removeItem**

Add to `QueueServiceTests`:

```swift
func testRemoveItemPublishesError() async {
    let service = QueueService(client: nil)

    do {
        try await service.removeItem(itemId: "test-item", from: "test-queue")
        XCTFail("Should throw error")
    } catch {
        XCTAssertTrue(error is QueueError)
    }
}
```

**Step 3: Run test to verify it fails**

Run: `swift test --filter QueueServiceTests/testRemoveItem`
Expected: FAIL

**Step 4: Implement removeItem method**

Add to `QueueService`:

```swift
func removeItem(itemId: String, from queueId: String) async throws {
    guard let client = client else {
        let error = QueueError.networkError("No client available")
        lastError = error
        throw error
    }

    do {
        AppLogger.player.info("Removing item \(itemId) from queue \(queueId)")

        // Music Assistant API: player_queues/queue_command with delete
        try await client.sendCommand(
            command: "player_queues/queue_command",
            args: [
                "queue_id": queueId,
                "command": "delete",
                "item_id": itemId
            ]
        )

        // Refresh queue after removal
        try await fetchQueue(for: queueId)
        lastError = nil
    } catch let error as QueueError {
        AppLogger.errors.logError(error, context: "removeItem")
        lastError = error
        throw error
    } catch {
        let queueError = QueueError.commandFailed("removeItem", reason: error.localizedDescription)
        AppLogger.errors.logError(error, context: "removeItem")
        lastError = queueError
        throw queueError
    }
}
```

**Step 5: Run test to verify it passes**

Run: `swift test --filter QueueServiceTests/testRemoveItem`
Expected: PASS

**Step 6: Write failing test for moveItem**

```swift
func testMoveItemPublishesError() async {
    let service = QueueService(client: nil)

    do {
        try await service.moveItem(itemId: "test-item", from: 0, to: 5, in: "test-queue")
        XCTFail("Should throw error")
    } catch {
        XCTAssertTrue(error is QueueError)
    }
}
```

**Step 7: Run test to verify it fails**

Run: `swift test --filter QueueServiceTests/testMoveItem`
Expected: FAIL

**Step 8: Implement moveItem method**

```swift
func moveItem(itemId: String, from oldIndex: Int, to newIndex: Int, in queueId: String) async throws {
    guard let client = client else {
        let error = QueueError.networkError("No client available")
        lastError = error
        throw error
    }

    do {
        AppLogger.player.info("Moving item \(itemId) from index \(oldIndex) to \(newIndex)")

        // Music Assistant API: player_queues/queue_command with move
        try await client.sendCommand(
            command: "player_queues/queue_command",
            args: [
                "queue_id": queueId,
                "command": "move",
                "queue_item_id": itemId,
                "pos_shift": newIndex - oldIndex
            ]
        )

        // Refresh queue after move
        try await fetchQueue(for: queueId)
        lastError = nil
    } catch let error as QueueError {
        AppLogger.errors.logError(error, context: "moveItem")
        lastError = error
        throw error
    } catch {
        let queueError = QueueError.commandFailed("moveItem", reason: error.localizedDescription)
        AppLogger.errors.logError(error, context: "moveItem")
        lastError = queueError
        throw queueError
    }
}
```

**Step 9: Run test to verify it passes**

Run: `swift test --filter QueueServiceTests/testMoveItem`
Expected: PASS

**Step 10: Write failing test for addToQueue with position**

```swift
func testAddToQueueAtPositionPublishesError() async {
    let service = QueueService(client: nil)

    do {
        try await service.addToQueue(uri: "track://test", queueId: "test-queue", at: 3)
        XCTFail("Should throw error")
    } catch {
        XCTAssertTrue(error is QueueError)
    }
}
```

**Step 11: Run test to verify it fails**

Run: `swift test --filter QueueServiceTests/testAddToQueueAtPosition`
Expected: FAIL

**Step 12: Implement addToQueue with optional position**

```swift
func addToQueue(uri: String, queueId: String, at position: Int? = nil) async throws {
    guard let client = client else {
        let error = QueueError.networkError("No client available")
        lastError = error
        throw error
    }

    do {
        AppLogger.player.info("Adding \(uri) to queue \(queueId) at position \(position?.description ?? "end")")

        var args: [String: Any] = [
            "queue_id": queueId,
            "command": "add",
            "media_items": [uri]
        ]

        if let position = position {
            args["insert_at_index"] = position
        }

        try await client.sendCommand(
            command: "player_queues/queue_command",
            args: args
        )

        // Refresh queue after addition
        try await fetchQueue(for: queueId)
        lastError = nil
    } catch let error as QueueError {
        AppLogger.errors.logError(error, context: "addToQueue")
        lastError = error
        throw error
    } catch {
        let queueError = QueueError.commandFailed("addToQueue", reason: error.localizedDescription)
        AppLogger.errors.logError(error, context: "addToQueue")
        lastError = queueError
        throw queueError
    }
}
```

**Step 13: Run test to verify it passes**

Run: `swift test --filter QueueServiceTests/testAddToQueueAtPosition`
Expected: PASS

**Step 14: Update shuffle/repeat/clearQueue methods to use QueueError**

Update each method to throw and publish `QueueError` instead of string errors.

**Step 15: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/QueueService.swift \
        Sources/MusicAssistantPlayer/Services/QueueError.swift \
        Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift
git commit -m "feat: add queue manipulation methods (remove, move, add-at-position)"
```

---

### Task 6: Add Search to LibraryService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift`

**Step 1: Update error handling to use LibraryError**

Add to top of file:

```swift
@Published var lastError: LibraryError?
```

Remove the string `error` property.

**Step 2: Write failing test for search**

Add to `LibraryServiceTests`:

```swift
func testSearchPublishesError() async {
    let service = LibraryService(client: nil)

    do {
        try await service.search(query: "test", in: .artists)
        XCTFail("Should throw error")
    } catch {
        XCTAssertTrue(error is LibraryError)
    }
}
```

**Step 3: Run test to verify it fails**

Run: `swift test --filter LibraryServiceTests/testSearch`
Expected: FAIL

**Step 4: Implement search method**

Add to `LibraryService`:

```swift
func search(query: String, in category: LibraryCategory) async throws {
    guard let client = client else {
        let error = LibraryError.noClientAvailable
        lastError = error
        throw error
    }

    guard !query.isEmpty else {
        // Empty query - just fetch all for category
        switch category {
        case .artists:
            try await fetchArtists()
        case .albums:
            try await fetchAlbums(for: nil)
        case .tracks:
            try await fetchTracks(for: nil)
        case .playlists:
            try await fetchPlaylists()
        case .radio, .genres:
            let error = LibraryError.categoryNotImplemented(category)
            lastError = error
            throw error
        }
        return
    }

    do {
        AppLogger.network.info("Searching \(category.displayName) for: \(query)")

        // Music Assistant API: music/search
        let result = try await client.sendCommand(
            command: "music/search",
            args: [
                "query": query,
                "media_type": category.apiMediaType
            ]
        )

        if let result = result {
            // Parse results based on category
            switch category {
            case .artists:
                self.artists = parseArtists(from: result)
            case .albums:
                self.albums = parseAlbums(from: result)
            case .tracks:
                self.tracks = parseTracks(from: result)
            case .playlists:
                self.playlists = parsePlaylists(from: result)
            case .radio, .genres:
                let error = LibraryError.categoryNotImplemented(category)
                lastError = error
                throw error
            }
            lastError = nil
        }
    } catch let error as LibraryError {
        AppLogger.errors.logError(error, context: "search")
        lastError = error
        throw error
    } catch {
        let libError = LibraryError.searchFailed(query)
        AppLogger.errors.logError(error, context: "search")
        lastError = libError
        throw libError
    }
}
```

**Step 5: Add apiMediaType to LibraryCategory**

Add to `Sources/MusicAssistantPlayer/Models/LibraryCategory.swift`:

```swift
var apiMediaType: String {
    switch self {
    case .artists:
        return "artist"
    case .albums:
        return "album"
    case .tracks:
        return "track"
    case .playlists:
        return "playlist"
    case .radio:
        return "radio"
    case .genres:
        return "genre"
    }
}
```

**Step 6: Run test to verify it passes**

Run: `swift test --filter LibraryServiceTests/testSearch`
Expected: PASS

**Step 7: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/LibraryService.swift \
        Sources/MusicAssistantPlayer/Models/LibraryCategory.swift \
        Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
git commit -m "feat: add search functionality to LibraryService"
```

---

### Task 7: Add Pagination to LibraryService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift`

**Step 1: Add pagination properties**

Add to `LibraryService`:

```swift
@Published var hasMoreItems: Bool = false
@Published var currentOffset: Int = 0
private let pageSize: Int = 50
```

**Step 2: Write failing test for paginated fetch**

```swift
func testFetchArtistsPaginated() async throws {
    let mockClient = MockMusicAssistantClient()
    let service = LibraryService(client: mockClient)

    try await service.fetchArtists(limit: 10, offset: 0)

    // Verify the command was called with correct pagination args
    XCTAssertEqual(mockClient.lastCommand, "music/artists/library_items")
    XCTAssertEqual(mockClient.lastArgs?["limit"] as? Int, 10)
    XCTAssertEqual(mockClient.lastArgs?["offset"] as? Int, 0)
}
```

**Step 3: Run test to verify it fails**

Run: `swift test --filter LibraryServiceTests/testFetchArtistsPaginated`
Expected: FAIL

**Step 4: Update fetchArtists with pagination**

Update the method signature and implementation:

```swift
func fetchArtists(limit: Int? = nil, offset: Int? = nil) async throws {
    guard let client = client else {
        let error = LibraryError.noClientAvailable
        lastError = error
        throw error
    }

    let fetchLimit = limit ?? pageSize
    let fetchOffset = offset ?? currentOffset

    do {
        AppLogger.network.info("Fetching artists: limit=\(fetchLimit), offset=\(fetchOffset)")

        // Music Assistant API with pagination
        let result = try await client.sendCommand(
            command: "music/artists/library_items",
            args: [
                "limit": fetchLimit,
                "offset": fetchOffset
            ]
        )

        if let result = result {
            let parsedArtists = parseArtists(from: result)

            if offset == 0 || offset == nil {
                // First page - replace
                self.artists = parsedArtists
            } else {
                // Subsequent pages - append
                self.artists.append(contentsOf: parsedArtists)
            }

            // Update pagination state
            self.currentOffset = fetchOffset + parsedArtists.count
            self.hasMoreItems = parsedArtists.count == fetchLimit

            lastError = nil
        } else {
            self.artists = []
            self.hasMoreItems = false
            lastError = nil
        }
    } catch let error as LibraryError {
        AppLogger.errors.logError(error, context: "fetchArtists")
        lastError = error
        throw error
    } catch {
        let libError = LibraryError.networkError(error.localizedDescription)
        AppLogger.errors.logError(error, context: "fetchArtists")
        lastError = libError
        throw libError
    }
}
```

**Step 5: Run test to verify it passes**

Run: `swift test --filter LibraryServiceTests/testFetchArtistsPaginated`
Expected: PASS

**Step 6: Add loadNextPage method**

```swift
func loadNextPage(for category: LibraryCategory) async throws {
    guard hasMoreItems else {
        AppLogger.network.debug("No more items to load")
        return
    }

    switch category {
    case .artists:
        try await fetchArtists(limit: pageSize, offset: currentOffset)
    case .albums:
        try await fetchAlbums(for: nil, limit: pageSize, offset: currentOffset)
    case .tracks:
        try await fetchTracks(for: nil, limit: pageSize, offset: currentOffset)
    case .playlists:
        try await fetchPlaylists(limit: pageSize, offset: currentOffset)
    case .radio, .genres:
        let error = LibraryError.categoryNotImplemented(category)
        lastError = error
        throw error
    }
}

func resetPagination() {
    currentOffset = 0
    hasMoreItems = false
}
```

**Step 7: Update fetchAlbums, fetchTracks, fetchPlaylists with pagination**

Apply the same pagination pattern to the other fetch methods.

**Step 8: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/LibraryService.swift \
        Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
git commit -m "feat: add pagination to LibraryService"
```

---

### Task 8: Add Sorting and Filtering to LibraryService

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/LibrarySortOption.swift`
- Create: `Sources/MusicAssistantPlayer/Models/LibraryFilter.swift`
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`

**Step 1: Create sort options enum**

Create `Sources/MusicAssistantPlayer/Models/LibrarySortOption.swift`:

```swift
// ABOUTME: Sort options for library browsing
// ABOUTME: Defines available sort criteria for each library category

import Foundation

enum LibrarySortOption: String, CaseIterable {
    case nameAsc = "name"
    case nameDesc = "name_desc"
    case recentlyAdded = "timestamp_added"
    case recentlyPlayed = "timestamp_played"
    case playCount = "play_count"
    case albumCount = "album_count" // Artists only
    case year = "year" // Albums only
    case duration = "duration"

    var displayName: String {
        switch self {
        case .nameAsc: return "Name (A-Z)"
        case .nameDesc: return "Name (Z-A)"
        case .recentlyAdded: return "Recently Added"
        case .recentlyPlayed: return "Recently Played"
        case .playCount: return "Most Played"
        case .albumCount: return "Album Count"
        case .year: return "Year"
        case .duration: return "Duration"
        }
    }

    static func options(for category: LibraryCategory) -> [LibrarySortOption] {
        switch category {
        case .artists:
            return [.nameAsc, .nameDesc, .recentlyAdded, .playCount, .albumCount]
        case .albums:
            return [.nameAsc, .nameDesc, .recentlyAdded, .year, .recentlyPlayed]
        case .tracks:
            return [.nameAsc, .nameDesc, .recentlyAdded, .recentlyPlayed, .playCount]
        case .playlists:
            return [.nameAsc, .nameDesc, .recentlyAdded, .duration]
        case .radio, .genres:
            return [.nameAsc, .nameDesc]
        }
    }
}
```

**Step 2: Create filter options struct**

Create `Sources/MusicAssistantPlayer/Models/LibraryFilter.swift`:

```swift
// ABOUTME: Filter options for library browsing
// ABOUTME: Defines available filters for narrowing library results

import Foundation

struct LibraryFilter {
    var provider: String?
    var genre: String?
    var yearRange: ClosedRange<Int>?
    var favoriteOnly: Bool = false

    var isEmpty: Bool {
        provider == nil && genre == nil && yearRange == nil && !favoriteOnly
    }

    func toAPIArgs() -> [String: Any] {
        var args: [String: Any] = [:]

        if let provider = provider {
            args["provider"] = provider
        }

        if let genre = genre {
            args["genre"] = genre
        }

        if let yearRange = yearRange {
            args["year_min"] = yearRange.lowerBound
            args["year_max"] = yearRange.upperBound
        }

        if favoriteOnly {
            args["favorite"] = true
        }

        return args
    }
}
```

**Step 3: Add sort and filter to LibraryService**

Add properties:

```swift
@Published var currentSort: LibrarySortOption = .nameAsc
@Published var currentFilter: LibraryFilter = LibraryFilter()
```

**Step 4: Update fetchArtists to support sorting and filtering**

```swift
func fetchArtists(
    limit: Int? = nil,
    offset: Int? = nil,
    sort: LibrarySortOption? = nil,
    filter: LibraryFilter? = nil
) async throws {
    guard let client = client else {
        let error = LibraryError.noClientAvailable
        lastError = error
        throw error
    }

    let fetchLimit = limit ?? pageSize
    let fetchOffset = offset ?? currentOffset
    let sortBy = sort ?? currentSort
    let filterBy = filter ?? currentFilter

    do {
        var args: [String: Any] = [
            "limit": fetchLimit,
            "offset": fetchOffset,
            "order_by": sortBy.rawValue
        ]

        // Merge filter args
        args.merge(filterBy.toAPIArgs()) { (_, new) in new }

        AppLogger.network.info("Fetching artists with sort: \(sortBy.rawValue)")

        let result = try await client.sendCommand(
            command: "music/artists/library_items",
            args: args
        )

        // ... rest of implementation
    }
}
```

**Step 5: Apply same pattern to other fetch methods**

Update fetchAlbums, fetchTracks, fetchPlaylists with sort/filter parameters.

**Step 6: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/LibrarySortOption.swift \
        Sources/MusicAssistantPlayer/Models/LibraryFilter.swift \
        Sources/MusicAssistantPlayer/Services/LibraryService.swift
git commit -m "feat: add sorting and filtering to LibraryService"
```

---

### Task 9: Implement Radio and Genres Categories

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`
- Create: `Sources/MusicAssistantPlayer/Models/Radio.swift`
- Create: `Sources/MusicAssistantPlayer/Models/Genre.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift`

**Step 1: Create Radio model**

Create `Sources/MusicAssistantPlayer/Models/Radio.swift`:

```swift
// ABOUTME: Radio station model
// ABOUTME: Represents a streaming radio station with metadata

import Foundation

struct Radio: Identifiable, Hashable {
    let id: String
    let name: String
    let artworkURL: URL?
    let provider: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

**Step 2: Create Genre model**

Create `Sources/MusicAssistantPlayer/Models/Genre.swift`:

```swift
// ABOUTME: Genre model
// ABOUTME: Represents a music genre with item count

import Foundation

struct Genre: Identifiable, Hashable {
    let id: String
    let name: String
    let itemCount: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

**Step 3: Add published properties to LibraryService**

```swift
@Published var radios: [Radio] = []
@Published var genres: [Genre] = []
```

**Step 4: Write failing test for fetchRadios**

```swift
func testFetchRadiosPublishesError() async {
    let service = LibraryService(client: nil)

    do {
        try await service.fetchRadios()
        XCTFail("Should throw error")
    } catch {
        XCTAssertTrue(error is LibraryError)
    }
}
```

**Step 5: Run test to verify it fails**

Run: `swift test --filter LibraryServiceTests/testFetchRadios`
Expected: FAIL

**Step 6: Implement fetchRadios**

```swift
func fetchRadios(
    limit: Int? = nil,
    offset: Int? = nil,
    sort: LibrarySortOption? = nil,
    filter: LibraryFilter? = nil
) async throws {
    guard let client = client else {
        let error = LibraryError.noClientAvailable
        lastError = error
        throw error
    }

    let fetchLimit = limit ?? pageSize
    let fetchOffset = offset ?? currentOffset
    let sortBy = sort ?? currentSort
    let filterBy = filter ?? currentFilter

    do {
        var args: [String: Any] = [
            "limit": fetchLimit,
            "offset": fetchOffset,
            "order_by": sortBy.rawValue
        ]

        args.merge(filterBy.toAPIArgs()) { (_, new) in new }

        let result = try await client.sendCommand(
            command: "music/radios/library_items",
            args: args
        )

        if let result = result {
            let parsedRadios = parseRadios(from: result)

            if offset == 0 || offset == nil {
                self.radios = parsedRadios
            } else {
                self.radios.append(contentsOf: parsedRadios)
            }

            self.currentOffset = fetchOffset + parsedRadios.count
            self.hasMoreItems = parsedRadios.count == fetchLimit
            lastError = nil
        } else {
            self.radios = []
            self.hasMoreItems = false
            lastError = nil
        }
    } catch let error as LibraryError {
        AppLogger.errors.logError(error, context: "fetchRadios")
        lastError = error
        throw error
    } catch {
        let libError = LibraryError.networkError(error.localizedDescription)
        AppLogger.errors.logError(error, context: "fetchRadios")
        lastError = libError
        throw libError
    }
}

private func parseRadios(from data: AnyCodable) -> [Radio] {
    guard let items = data.value as? [[String: Any]] else {
        return []
    }

    return items.compactMap { item in
        guard let id = item["item_id"] as? String,
              let name = item["name"] as? String
        else {
            return nil
        }

        let artworkURL: URL?
        if let metadata = item["metadata"] as? [String: Any],
           let imageURLString = metadata["image"] as? String {
            artworkURL = URL(string: imageURLString)
        } else {
            artworkURL = nil
        }

        let provider = item["provider"] as? String

        return Radio(
            id: id,
            name: name,
            artworkURL: artworkURL,
            provider: provider
        )
    }
}
```

**Step 7: Run test to verify it passes**

Run: `swift test --filter LibraryServiceTests/testFetchRadios`
Expected: PASS

**Step 8: Implement fetchGenres similarly**

Follow same pattern for genres.

**Step 9: Update loadContent switch to handle radio/genres**

Update in `LibraryViewModel` (we'll do this in Layer 2).

**Step 10: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/Radio.swift \
        Sources/MusicAssistantPlayer/Models/Genre.swift \
        Sources/MusicAssistantPlayer/Services/LibraryService.swift \
        Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
git commit -m "feat: implement radio and genres categories"
```

---

### Task 10: Add Caching to LibraryService

**Files:**
- Create: `Sources/MusicAssistantPlayer/Services/LibraryCache.swift`
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/LibraryCacheTests.swift`

**Step 1: Write failing test for cache**

Create `Tests/MusicAssistantPlayerTests/Services/LibraryCacheTests.swift`:

```swift
import XCTest
@testable import MusicAssistantPlayer

final class LibraryCacheTests: XCTestCase {
    func testCacheStoresAndRetrievesArtists() {
        let cache = LibraryCache()
        let artists = [
            Artist(id: "1", name: "Test Artist", artworkURL: nil, albumCount: 5)
        ]

        cache.set(artists, forKey: "artists")

        let retrieved: [Artist]? = cache.get(forKey: "artists")
        XCTAssertEqual(retrieved?.count, 1)
        XCTAssertEqual(retrieved?.first?.name, "Test Artist")
    }

    func testCacheExpiresAfterTTL() async {
        let cache = LibraryCache(ttl: 0.1) // 100ms TTL
        let artists = [
            Artist(id: "1", name: "Test Artist", artworkURL: nil, albumCount: 5)
        ]

        cache.set(artists, forKey: "artists")

        // Wait for expiration
        try? await Task.sleep(for: .milliseconds(150))

        let retrieved: [Artist]? = cache.get(forKey: "artists")
        XCTAssertNil(retrieved)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LibraryCacheTests`
Expected: FAIL

**Step 3: Implement LibraryCache**

Create `Sources/MusicAssistantPlayer/Services/LibraryCache.swift`:

```swift
// ABOUTME: In-memory cache for library items
// ABOUTME: Reduces API calls by caching frequently accessed library data

import Foundation

@MainActor
class LibraryCache {
    private var cache: [String: CacheEntry] = [:]
    private let ttl: TimeInterval // Time to live in seconds

    init(ttl: TimeInterval = 300) { // 5 minutes default
        self.ttl = ttl
    }

    func set<T>(_ value: T, forKey key: String) {
        let entry = CacheEntry(
            value: value,
            timestamp: Date()
        )
        cache[key] = entry
    }

    func get<T>(forKey key: String) -> T? {
        guard let entry = cache[key] else {
            return nil
        }

        // Check if expired
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            cache.removeValue(forKey: key)
            return nil
        }

        return entry.value as? T
    }

    func clear() {
        cache.removeAll()
    }

    func remove(forKey key: String) {
        cache.removeValue(forKey: key)
    }

    private struct CacheEntry {
        let value: Any
        let timestamp: Date
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter LibraryCacheTests`
Expected: PASS

**Step 5: Add cache to LibraryService**

```swift
private let cache = LibraryCache()
```

**Step 6: Update fetchArtists to use cache**

```swift
func fetchArtists(
    limit: Int? = nil,
    offset: Int? = nil,
    sort: LibrarySortOption? = nil,
    filter: LibraryFilter? = nil,
    forceRefresh: Bool = false
) async throws {
    // Build cache key
    let cacheKey = "artists_\(sort?.rawValue ?? "default")_\(offset ?? 0)"

    // Check cache first (if not forcing refresh and first page)
    if !forceRefresh && (offset ?? 0) == 0,
       let cached: [Artist] = cache.get(forKey: cacheKey) {
        AppLogger.network.debug("Using cached artists")
        self.artists = cached
        return
    }

    // ... existing fetch implementation ...

    // After successful fetch, cache the results (first page only)
    if (offset ?? 0) == 0 {
        cache.set(self.artists, forKey: cacheKey)
    }
}
```

**Step 7: Apply caching to other fetch methods**

**Step 8: Add method to clear cache when needed**

```swift
func clearCache() {
    cache.clear()
}

func invalidateCache(for category: LibraryCategory) {
    // Clear all cache entries for this category
    // This is called when content changes (e.g., after favorite toggle)
}
```

**Step 9: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/LibraryCache.swift \
        Sources/MusicAssistantPlayer/Services/LibraryService.swift \
        Tests/MusicAssistantPlayerTests/Services/LibraryCacheTests.swift
git commit -m "feat: add caching to LibraryService to reduce API calls"
```

---

### Task 11: Add Favorites/Recently Played

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`
- Test: `Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift`

**Step 1: Write failing test for fetchFavorites**

```swift
func testFetchFavoritesPublishesError() async {
    let service = LibraryService(client: nil)

    do {
        try await service.fetchFavorites(for: .tracks)
        XCTFail("Should throw error")
    } catch {
        XCTAssertTrue(error is LibraryError)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LibraryServiceTests/testFetchFavorites`
Expected: FAIL

**Step 3: Implement fetchFavorites**

```swift
func fetchFavorites(
    for category: LibraryCategory,
    limit: Int? = nil,
    offset: Int? = nil
) async throws {
    guard let client = client else {
        let error = LibraryError.noClientAvailable
        lastError = error
        throw error
    }

    let fetchLimit = limit ?? pageSize
    let fetchOffset = offset ?? currentOffset

    do {
        let command: String
        switch category {
        case .artists:
            command = "music/artists/library_items"
        case .albums:
            command = "music/albums/library_items"
        case .tracks:
            command = "music/tracks/library_items"
        case .playlists:
            command = "music/playlists/library_items"
        case .radio:
            command = "music/radios/library_items"
        case .genres:
            let error = LibraryError.categoryNotImplemented(category)
            lastError = error
            throw error
        }

        let result = try await client.sendCommand(
            command: command,
            args: [
                "favorite": true,
                "limit": fetchLimit,
                "offset": fetchOffset
            ]
        )

        if let result = result {
            switch category {
            case .artists:
                self.artists = parseArtists(from: result)
            case .albums:
                self.albums = parseAlbums(from: result)
            case .tracks:
                self.tracks = parseTracks(from: result)
            case .playlists:
                self.playlists = parsePlaylists(from: result)
            case .radio:
                self.radios = parseRadios(from: result)
            case .genres:
                break
            }
            lastError = nil
        }
    } catch let error as LibraryError {
        AppLogger.errors.logError(error, context: "fetchFavorites")
        lastError = error
        throw error
    } catch {
        let libError = LibraryError.networkError(error.localizedDescription)
        AppLogger.errors.logError(error, context: "fetchFavorites")
        lastError = libError
        throw libError
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter LibraryServiceTests/testFetchFavorites`
Expected: PASS

**Step 5: Write failing test for fetchRecentlyPlayed**

```swift
func testFetchRecentlyPlayedPublishesError() async {
    let service = LibraryService(client: nil)

    do {
        try await service.fetchRecentlyPlayed(for: .tracks)
        XCTFail("Should throw error")
    } catch {
        XCTAssertTrue(error is LibraryError)
    }
}
```

**Step 6: Run test to verify it fails**

Run: `swift test --filter LibraryServiceTests/testFetchRecentlyPlayed`
Expected: FAIL

**Step 7: Implement fetchRecentlyPlayed**

```swift
func fetchRecentlyPlayed(
    for category: LibraryCategory,
    limit: Int? = nil
) async throws {
    guard let client = client else {
        let error = LibraryError.noClientAvailable
        lastError = error
        throw error
    }

    let fetchLimit = limit ?? 20 // Smaller limit for recently played

    do {
        let command: String
        switch category {
        case .artists:
            command = "music/artists/library_items"
        case .albums:
            command = "music/albums/library_items"
        case .tracks:
            command = "music/tracks/library_items"
        case .playlists:
            command = "music/playlists/library_items"
        case .radio:
            command = "music/radios/library_items"
        case .genres:
            let error = LibraryError.categoryNotImplemented(category)
            lastError = error
            throw error
        }

        let result = try await client.sendCommand(
            command: command,
            args: [
                "order_by": "timestamp_played",
                "limit": fetchLimit
            ]
        )

        if let result = result {
            switch category {
            case .artists:
                self.artists = parseArtists(from: result)
            case .albums:
                self.albums = parseAlbums(from: result)
            case .tracks:
                self.tracks = parseTracks(from: result)
            case .playlists:
                self.playlists = parsePlaylists(from: result)
            case .radio:
                self.radios = parseRadios(from: result)
            case .genres:
                break
            }
            lastError = nil
        }
    } catch let error as LibraryError {
        AppLogger.errors.logError(error, context: "fetchRecentlyPlayed")
        lastError = error
        throw error
    } catch {
        let libError = LibraryError.networkError(error.localizedDescription)
        AppLogger.errors.logError(error, context: "fetchRecentlyPlayed")
        lastError = libError
        throw libError
    }
}
```

**Step 8: Run test to verify it passes**

Run: `swift test --filter LibraryServiceTests/testFetchRecentlyPlayed`
Expected: PASS

**Step 9: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/LibraryService.swift \
        Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
git commit -m "feat: add favorites and recently played fetching"
```

---

## LAYER 2: VIEWMODELS

### Task 12: Wire Up Shuffle/Repeat/Like in NowPlayingViewModel

**Files:**
- Modify: `Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift`
- Test: `Tests/MusicAssistantPlayerTests/ViewModels/NowPlayingViewModelTests.swift`

**Step 1: Add bindings for shuffle/repeat/favorite from service**

Update `setupBindings()` method:

```swift
private func setupBindings() {
    // ... existing bindings ...

    playerService.$isShuffled
        .assign(to: &$isShuffled)

    // Update repeatMode binding
    playerService.$repeatMode
        .map { mode -> RepeatMode in
            switch mode {
            case "all": return .all
            case "one": return .one
            default: return .off
            }
        }
        .assign(to: &$repeatMode)

    playerService.$isFavorite
        .assign(to: &$isLiked)
}
```

**Step 2: Update toggleShuffle to call service**

Replace the stub implementation:

```swift
func toggleShuffle() {
    Task {
        await playerService.setShuffle(enabled: !isShuffled)
    }
}
```

**Step 3: Update cycleRepeatMode to call service**

```swift
func cycleRepeatMode() {
    let nextMode: String
    switch repeatMode {
    case .off: nextMode = "all"
    case .all: nextMode = "one"
    case .one: nextMode = "off"
    }

    Task {
        await playerService.setRepeat(mode: nextMode)
    }
}
```

**Step 4: Update toggleLike to call service**

```swift
func toggleLike() {
    guard let trackId = currentTrack?.id else {
        return
    }

    Task {
        await playerService.toggleFavorite(trackId: trackId)
    }
}
```

**Step 5: Check favorite status when track changes**

Update the track binding in `setupBindings()`:

```swift
playerService.$currentTrack
    .sink { [weak self] track in
        self?.currentTrack = track
        self?.trackTitle = track?.title ?? "No Track Playing"
        self?.artistName = track?.artist ?? ""
        self?.albumName = track?.album ?? ""
        self?.artworkURL = track?.artworkURL
        self?.duration = track?.duration ?? 0.0

        // Check if new track is favorited
        if let trackId = track?.id {
            Task { [weak self] in
                await self?.playerService.checkIfFavorite(trackId: trackId)
            }
        }
    }
    .store(in: &cancellables)
```

**Step 6: Remove debug print statements**

Delete the print statements at lines 82, 89, 98, 104, 114.

**Step 7: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift
git commit -m "feat: wire up shuffle/repeat/like to PlayerService in NowPlayingViewModel"
```

---

### Task 13: Add Debouncing for Volume and Seek

**Files:**
- Modify: `Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift`

**Step 1: Add Combine publishers for debouncing**

Add properties:

```swift
private var volumeSubject = PassthroughSubject<Double, Never>()
private var seekSubject = PassthroughSubject<TimeInterval, Never>()
```

**Step 2: Set up debouncing in init**

```swift
init(playerService: PlayerService) {
    self.playerService = playerService
    setupBindings()
    setupDebouncing()
}

private func setupDebouncing() {
    // Volume changes debounced to 300ms
    volumeSubject
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] volume in
            Task { [weak self] in
                await self?.playerService.setVolume(volume)
            }
        }
        .store(in: &cancellables)

    // Seek changes debounced to 500ms (longer for scrubbing)
    seekSubject
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] time in
            Task { [weak self] in
                await self?.playerService.seek(to: time)
            }
        }
        .store(in: &cancellables)
}
```

**Step 3: Update setVolume to use subject**

```swift
func setVolume(_ volume: Double) {
    // Update local state immediately for responsive UI
    self.volume = volume
    // Send through debounced subject
    volumeSubject.send(volume)
}
```

**Step 4: Update seek to use subject**

```swift
func seek(to time: TimeInterval) {
    // Update local state immediately for responsive UI
    self.progress = time
    // Send through debounced subject
    seekSubject.send(time)
}
```

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift
git commit -m "feat: add debouncing to volume and seek controls"
```

---

### Task 14: Move Shuffle/Repeat State to QueueViewModel

**Files:**
- Modify: `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/QueueView.swift`
- Test: `Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift`

**Step 1: Add shuffle/repeat state to QueueViewModel**

Add properties:

```swift
@Published var isShuffleEnabled: Bool = false
@Published var repeatMode: String = "off" // "off", "all", "one"
```

**Step 2: Move shuffle/repeat methods from service binding**

Update `shuffle` method to manage state:

```swift
func shuffle(enabled: Bool) async throws {
    let previousState = isShuffleEnabled
    isShuffleEnabled = enabled

    do {
        try await queueService.shuffle(enabled: enabled)
    } catch {
        // Rollback on failure
        isShuffleEnabled = previousState
        throw error
    }
}
```

**Step 3: Add setRepeat method**

```swift
func setRepeat(mode: String) async throws {
    let previousMode = repeatMode
    repeatMode = mode

    do {
        try await queueService.setRepeat(mode: mode)
    } catch {
        // Rollback on failure
        repeatMode = previousMode
        throw error
    }
}
```

**Step 4: Update QueueView to use ViewModel state**

Remove the `@State` variables for shuffle/repeat and bind to ViewModel:

```swift
// Remove these:
// @State private var isShuffleEnabled = false
// @State private var repeatMode = "off"

// Update button bindings to use viewModel properties:
Button(action: {
    Task {
        do {
            try await viewModel.shuffle(enabled: !viewModel.isShuffleEnabled)
        } catch {
            // Error handled by viewModel
        }
    }
}) {
    Image(systemName: viewModel.isShuffleEnabled ? "shuffle.circle.fill" : "shuffle")
        .foregroundColor(viewModel.isShuffleEnabled ? .green : .white.opacity(0.7))
}
```

**Step 5: Update repeat button similarly**

**Step 6: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift \
        Sources/MusicAssistantPlayer/Views/QueueView.swift \
        Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift
git commit -m "refactor: move shuffle/repeat state management to QueueViewModel"
```

---

### Task 15: Add Queue Manipulation to QueueViewModel

**Files:**
- Modify: `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`
- Test: `Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift`

**Step 1: Add removeTrack method**

```swift
func removeTrack(id: String, from queueId: String) async {
    isLoading = true
    defer { isLoading = false }

    do {
        try await queueService.removeItem(itemId: id, from: queueId)
        errorMessage = nil
    } catch let error as QueueError {
        errorMessage = error.localizedDescription
    } catch {
        errorMessage = "Failed to remove track"
    }
}
```

**Step 2: Add moveTrack method**

```swift
func moveTrack(id: String, from oldIndex: Int, to newIndex: Int, in queueId: String) async {
    isLoading = true
    defer { isLoading = false }

    do {
        try await queueService.moveItem(itemId: id, from: oldIndex, to: newIndex, in: queueId)
        errorMessage = nil
    } catch let error as QueueError {
        errorMessage = error.localizedDescription
    } catch {
        errorMessage = "Failed to move track"
    }
}
```

**Step 3: Write tests**

```swift
func testRemoveTrackSetsLoading() async {
    let service = QueueService(client: nil)
    let viewModel = QueueViewModel(queueService: service)

    await viewModel.removeTrack(id: "test", from: "queue")

    XCTAssertNotNil(viewModel.errorMessage)
}
```

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift \
        Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift
git commit -m "feat: add queue manipulation methods to QueueViewModel"
```

---

### Task 16: Implement Search, Sort, Filter in LibraryViewModel

**Files:**
- Modify: `Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift`
- Test: `Tests/MusicAssistantPlayerTests/ViewModels/LibraryViewModelTests.swift`

**Step 1: Add sort and filter properties**

```swift
@Published var currentSort: LibrarySortOption = .nameAsc
@Published var currentFilter: LibraryFilter = LibraryFilter()
@Published var showFavoritesOnly: Bool = false
@Published var showRecentlyPlayed: Bool = false
```

**Step 2: Add search method**

```swift
func search(query: String) async {
    searchQuery = query
    isLoading = true
    defer { isLoading = false }

    do {
        try await libraryService.search(query: query, in: selectedCategory)
    } catch {
        // Error already set in service
    }
}
```

**Step 3: Add sort method**

```swift
func updateSort(_ sort: LibrarySortOption) async {
    currentSort = sort
    libraryService.currentSort = sort
    libraryService.resetPagination()
    await loadContent()
}
```

**Step 4: Add filter method**

```swift
func updateFilter(_ filter: LibraryFilter) async {
    currentFilter = filter
    libraryService.currentFilter = filter
    libraryService.resetPagination()
    await loadContent()
}
```

**Step 5: Add toggle favorites/recently played**

```swift
func toggleFavoritesOnly() async {
    showFavoritesOnly.toggle()
    showRecentlyPlayed = false // Mutually exclusive

    isLoading = true
    defer { isLoading = false }

    do {
        if showFavoritesOnly {
            try await libraryService.fetchFavorites(for: selectedCategory)
        } else {
            try await loadContent()
        }
    } catch {
        // Error handled by service
    }
}

func toggleRecentlyPlayed() async {
    showRecentlyPlayed.toggle()
    showFavoritesOnly = false // Mutually exclusive

    isLoading = true
    defer { isLoading = false }

    do {
        if showRecentlyPlayed {
            try await libraryService.fetchRecentlyPlayed(for: selectedCategory)
        } else {
            try await loadContent()
        }
    } catch {
        // Error handled by service
    }
}
```

**Step 6: Update loadContent to handle radio/genres**

```swift
func loadContent() async {
    isLoading = true
    defer { isLoading = false }

    libraryService.resetPagination()

    do {
        switch selectedCategory {
        case .artists:
            try await libraryService.fetchArtists()
        case .albums:
            try await libraryService.fetchAlbums(for: nil)
        case .tracks:
            try await libraryService.fetchTracks(for: nil)
        case .playlists:
            try await libraryService.fetchPlaylists()
        case .radio:
            try await libraryService.fetchRadios()
        case .genres:
            try await libraryService.fetchGenres()
        }
    } catch {
        // Error already set in service
    }
}
```

**Step 7: Add pagination support**

```swift
func loadNextPage() async {
    guard libraryService.hasMoreItems else { return }

    do {
        try await libraryService.loadNextPage(for: selectedCategory)
    } catch {
        // Error handled by service
    }
}

var hasMoreItems: Bool {
    libraryService.hasMoreItems
}
```

**Step 8: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift \
        Tests/MusicAssistantPlayerTests/ViewModels/LibraryViewModelTests.swift
git commit -m "feat: implement search, sort, filter, and pagination in LibraryViewModel"
```

---

## LAYER 3: VIEWS

### Task 17: Add Queue Item Context Menu (Remove/Move)

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/QueueView.swift`

**Step 1: Add context menu to QueueTrackRow**

Update `QueueTrackRow` body:

```swift
var body: some View {
    HStack(spacing: 12) {
        // ... existing content ...
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(isCurrentTrack ? Color.green.opacity(0.1) : Color.clear)
    .contextMenu {
        Button(action: onRemove) {
            Label("Remove from Queue", systemImage: "trash")
        }

        if !isCurrentTrack {
            Button(action: onMoveUp) {
                Label("Move Up", systemImage: "arrow.up")
            }

            Button(action: onMoveDown) {
                Label("Move Down", systemImage: "arrow.down")
            }
        }
    }
}
```

**Step 2: Add callbacks to QueueTrackRow**

Add properties:

```swift
let onRemove: () -> Void
let onMoveUp: () -> Void
let onMoveDown: () -> Void
```

**Step 3: Wire up callbacks in QueueView**

Update ForEach:

```swift
ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, track in
    QueueTrackRow(
        track: track,
        index: index + 1,
        isCurrentTrack: track.id == currentTrack?.id,
        onRemove: {
            Task {
                guard let queueId = viewModel.queueId else { return }
                await viewModel.removeTrack(id: track.id, from: queueId)
            }
        },
        onMoveUp: {
            guard index > 0 else { return }
            Task {
                guard let queueId = viewModel.queueId else { return }
                await viewModel.moveTrack(
                    id: track.id,
                    from: index,
                    to: index - 1,
                    in: queueId
                )
            }
        },
        onMoveDown: {
            guard index < viewModel.tracks.count - 1 else { return }
            Task {
                guard let queueId = viewModel.queueId else { return }
                await viewModel.moveTrack(
                    id: track.id,
                    from: index,
                    to: index + 1,
                    in: queueId
                )
            }
        }
    )

    if index < viewModel.tracks.count - 1 {
        Divider()
            .background(Color.white.opacity(0.05))
            .padding(.leading, 60)
    }
}
```

**Step 4: Add queueId to QueueViewModel**

Add property:

```swift
var queueId: String? {
    // Get from current player - will wire this up in integration layer
    return nil // TODO: Get from PlayerService
}
```

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/QueueView.swift \
        Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift
git commit -m "feat: add queue item context menu for remove and reorder"
```

---

### Task 18: Add Search Bar to Library Views

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift`

**Step 1: Add search bar to LibraryBrowseView**

Add above the content:

```swift
.searchable(
    text: $viewModel.searchQuery,
    placement: .toolbar,
    prompt: "Search \(viewModel.selectedCategory.displayName)"
)
.onSubmit(of: .search) {
    Task {
        await viewModel.search(query: viewModel.searchQuery)
    }
}
.onChange(of: viewModel.searchQuery) { oldValue, newValue in
    // Search as user types (debounced in ViewModel)
    if newValue.isEmpty {
        Task {
            await viewModel.loadContent()
        }
    } else if newValue.count >= 3 {
        Task {
            await viewModel.search(query: newValue)
        }
    }
}
```

**Step 2: Add debouncing to ViewModel search**

Add to LibraryViewModel:

```swift
private var searchSubject = PassthroughSubject<String, Never>()

private func setupSearchDebouncing() {
    searchSubject
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] query in
            Task { [weak self] in
                await self?.performSearch(query: query)
            }
        }
        .store(in: &cancellables)
}

private func performSearch(query: String) async {
    isLoading = true
    defer { isLoading = false }

    do {
        if query.isEmpty {
            try await loadContent()
        } else {
            try await libraryService.search(query: query, in: selectedCategory)
        }
    } catch {
        // Error handled by service
    }
}

func search(query: String) async {
    searchSubject.send(query)
}
```

**Step 3: Update init to call setupSearchDebouncing**

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift \
        Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift
git commit -m "feat: add search bar to library views with debouncing"
```

---

### Task 19: Add Sort/Filter Controls to Library

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/LibraryToolbar.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift`

**Step 1: Create LibraryToolbar component**

Create `Sources/MusicAssistantPlayer/Views/LibraryToolbar.swift`:

```swift
// ABOUTME: Toolbar for library browsing with sort, filter, and view options
// ABOUTME: Provides controls for customizing library display and filtering results

import SwiftUI

struct LibraryToolbar: View {
    @ObservedObject var viewModel: LibraryViewModel

    @State private var showingSortMenu = false
    @State private var showingFilterSheet = false

    var body: some View {
        HStack(spacing: 12) {
            // Favorites toggle
            Button(action: {
                Task {
                    await viewModel.toggleFavoritesOnly()
                }
            }) {
                Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                    .foregroundColor(viewModel.showFavoritesOnly ? .pink : .white.opacity(0.7))
            }
            .help("Show Favorites Only")

            // Recently played toggle
            Button(action: {
                Task {
                    await viewModel.toggleRecentlyPlayed()
                }
            }) {
                Image(systemName: viewModel.showRecentlyPlayed ? "clock.fill" : "clock")
                    .foregroundColor(viewModel.showRecentlyPlayed ? .blue : .white.opacity(0.7))
            }
            .help("Show Recently Played")

            Spacer()

            // Sort menu
            Menu {
                ForEach(LibrarySortOption.options(for: viewModel.selectedCategory), id: \.self) { option in
                    Button(action: {
                        Task {
                            await viewModel.updateSort(option)
                        }
                    }) {
                        HStack {
                            Text(option.displayName)
                            if viewModel.currentSort == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("Sort")
                }
                .foregroundColor(.white.opacity(0.7))
            }

            // Filter button
            Button(action: {
                showingFilterSheet = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: currentFilter.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    Text("Filter")
                }
                .foregroundColor(currentFilter.isEmpty ? .white.opacity(0.7) : .blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(
                filter: viewModel.currentFilter,
                category: viewModel.selectedCategory,
                onApply: { filter in
                    Task {
                        await viewModel.updateFilter(filter)
                    }
                }
            )
        }
    }

    private var currentFilter: LibraryFilter {
        viewModel.currentFilter
    }
}
```

**Step 2: Create FilterSheet component**

Add to same file:

```swift
struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss

    let filter: LibraryFilter
    let category: LibraryCategory
    let onApply: (LibraryFilter) -> Void

    @State private var editedFilter: LibraryFilter

    init(filter: LibraryFilter, category: LibraryCategory, onApply: @escaping (LibraryFilter) -> Void) {
        self.filter = filter
        self.category = category
        self.onApply = onApply
        _editedFilter = State(initialValue: filter)
    }

    var body: some View {
        NavigationView {
            Form {
                // TODO: Add filter controls based on category
                // - Provider selection
                // - Genre selection (if applicable)
                // - Year range (for albums)

                Section {
                    Toggle("Favorites Only", isOn: $editedFilter.favoriteOnly)
                }
            }
            .navigationTitle("Filter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(editedFilter)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button("Clear All") {
                        editedFilter = LibraryFilter()
                    }
                }
            }
        }
    }
}
```

**Step 3: Add toolbar to LibraryBrowseView**

Add above the content:

```swift
VStack(spacing: 0) {
    LibraryToolbar(viewModel: viewModel)

    Divider()
        .background(Color.white.opacity(0.1))

    // Existing content ScrollView...
}
```

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/LibraryToolbar.swift \
        Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift
git commit -m "feat: add sort and filter controls to library toolbar"
```

---

### Task 20: Add Pagination Indicator to Library

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift`

**Step 1: Add "Load More" button at bottom of list**

Add to ScrollView content:

```swift
// At the end of the list
if viewModel.hasMoreItems {
    Button(action: {
        Task {
            await viewModel.loadNextPage()
        }
    }) {
        HStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            }
            Text("Load More")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.7))
        .frame(maxWidth: .infinity)
        .padding()
    }
    .buttonStyle(.plain)
}
```

**Step 2: Add infinite scroll trigger**

Alternatively, automatically load when scrolled to bottom:

```swift
.onAppear {
    // Check if this is the last item
    if item == viewModel.items.last && viewModel.hasMoreItems {
        Task {
            await viewModel.loadNextPage()
        }
    }
}
```

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift
git commit -m "feat: add pagination support to library views"
```

---

### Task 21: Improve Error Display in Views

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/NowPlayingView.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/QueueView.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift`

**Step 1: Update NowPlayingView error banner**

The error banner already exists (lines 47-52). Update it to use the error from PlayerService:

```swift
if let error = viewModel.lastError {
    ErrorBanner(
        title: "Playback Error",
        message: error.localizedDescription,
        onDismiss: {
            viewModel.clearError()
        }
    )
    .padding(.horizontal)
    .padding(.top, 8)
}
```

**Step 2: Update QueueView error banner**

Update the existing error banner (lines 37-56):

```swift
if let error = viewModel.lastError {
    HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
        Text(error.localizedDescription)
            .font(.system(size: 13))
            .foregroundColor(.white)
        Spacer()
        Button(action: {
            viewModel.clearError()
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.white.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(Color.orange.opacity(0.2))
}
```

**Step 3: Add clearError method to QueueViewModel**

```swift
func clearError() {
    queueService.lastError = nil
    errorMessage = nil
}
```

**Step 4: Add error banner to LibraryBrowseView**

Add at the top:

```swift
if let error = viewModel.errorMessage {
    HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
        Text(error)
            .font(.system(size: 13))
            .foregroundColor(.white)
        Spacer()
        Button(action: {
            viewModel.clearError()
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.white.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(Color.orange.opacity(0.2))
}
```

**Step 5: Add clearError to LibraryViewModel**

```swift
func clearError() {
    libraryService.lastError = nil
}
```

**Step 6: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/NowPlayingView.swift \
        Sources/MusicAssistantPlayer/Views/QueueView.swift \
        Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift \
        Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift \
        Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift
git commit -m "feat: improve error display across all views"
```

---

## LAYER 4: INTEGRATION & POLISH

### Task 22: Wire Up QueueViewModel with PlayerService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/RoonStyleMainWindowView.swift`

**Step 1: Add playerService reference to QueueViewModel**

```swift
private let playerService: PlayerService?

init(queueService: QueueService, playerService: PlayerService? = nil) {
    self.queueService = queueService
    self.playerService = playerService
}

var queueId: String? {
    playerService?.selectedPlayer?.id
}
```

**Step 2: Update RoonStyleMainWindowView initialization**

Update the initialization:

```swift
_queueViewModel = StateObject(wrappedValue: QueueViewModel(
    queueService: queueSvc,
    playerService: playerSvc
))
```

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift \
        Sources/MusicAssistantPlayer/Views/RoonStyleMainWindowView.swift
git commit -m "feat: wire up QueueViewModel with PlayerService for queue manipulation"
```

---

### Task 23: Run Full Test Suite

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests PASS

**Step 2: Fix any failing tests**

Address any failures that emerged during refactoring.

**Step 3: Check test coverage**

Run: `swift test --enable-code-coverage`

**Step 4: Commit any test fixes**

```bash
git add Tests/
git commit -m "test: fix failing tests and improve coverage"
```

---

### Task 24: Build and Manual Smoke Test

**Step 1: Build the app**

Run: `swift build -c release`
Expected: Build succeeds with no errors

**Step 2: Run the app**

Run: `swift run`

**Step 3: Execute smoke test flow**

1. Connect to server
2. Pick a player
3. Browse to an album
4. Play it
5. Skip a track, adjust volume
6. Check the queue
7. Test shuffle/repeat
8. Test search
9. Test favorites

**Step 4: Document any issues found**

Create issues for any bugs discovered during smoke test.

**Step 5: Commit final polish**

```bash
git add .
git commit -m "chore: final polish and smoke test validation"
```

---

## Summary

This plan transforms the Music Assistant Player from 30% complete to shipping quality by:

**Layer 1 (Services & Models):**
- Domain error types for better error handling
- Expanded EventParser for all state
- Shuffle/repeat/like in PlayerService
- Queue manipulation (remove, move, add-at-position)
- Search, pagination, sorting, filtering in LibraryService
- Radio and Genres categories
- Caching layer
- Favorites and recently played

**Layer 2 (ViewModels):**
- Wire shuffle/repeat/like to services
- Debouncing for volume/seek
- Queue state management
- Search/sort/filter state management
- Pagination support

**Layer 3 (Views):**
- Queue context menu for manipulation
- Search bar
- Sort/filter toolbar
- Pagination UI
- Improved error display

**Layer 4 (Integration):**
- Wire all components together
- Full test suite
- Smoke test validation

**Execution time:** ~1-2 weeks for implementation + testing + polish.
