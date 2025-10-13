# Add Player Grouping Functionality

> **For Claude:** Quick implementation to add group/ungroup player controls.

**Goal:** Add player grouping/ungrouping functionality using the new MusicAssistantKit APIs.

**Architecture:** Add group() and ungroup() methods to PlayerService with error handling, then add UI controls to sidebar for grouping players.

**Tech Stack:** SwiftUI, MusicAssistantKit (group/ungroup APIs)

---

## Task 1: Add Group/Ungroup to PlayerService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/PlayerService.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`

**Step 1: Add tests for group/ungroup**

Add to PlayerServiceTests.swift:

```swift
func testGroupPublishesError() async {
    let service = PlayerService(client: nil)

    await service.group(targetPlayerId: "player2")

    XCTAssertNotNil(service.lastError)
}

func testUngroupPublishesError() async {
    let service = PlayerService(client: nil)

    await service.ungroup()

    XCTAssertNotNil(service.lastError)
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter PlayerServiceTests`
Expected: FAIL (methods don't exist)

**Step 3: Add group and ungroup methods to PlayerService**

Add after the setVolume method:

```swift
func group(targetPlayerId: String) async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        AppLogger.player.info("Grouping player \(player.name) with \(targetPlayerId)")
        try await client.group(playerId: player.id, targetPlayer: targetPlayerId)
        lastError = nil
    } catch let error as PlayerError {
        AppLogger.errors.logPlayerError(error, context: "group(targetPlayerId:)")
        self.lastError = error
    } catch {
        AppLogger.errors.logError(error, context: "group(targetPlayerId:)")
        self.lastError = .commandFailed("group", reason: error.localizedDescription)
    }
}

func ungroup() async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        AppLogger.player.info("Ungrouping player \(player.name)")
        try await client.ungroup(playerId: player.id)
        lastError = nil
    } catch let error as PlayerError {
        AppLogger.errors.logPlayerError(error, context: "ungroup()")
        self.lastError = error
    } catch {
        AppLogger.errors.logError(error, context: "ungroup()")
        self.lastError = .commandFailed("ungroup", reason: error.localizedDescription)
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test`
Expected: All tests passing

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/PlayerService.swift
git add Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift
git commit -m "feat: add player group and ungroup functionality"
```

---

## Success Criteria

✅ Group and ungroup methods added to PlayerService
✅ Error handling with logging
✅ Tests for error scenarios
✅ All 69+ tests passing
✅ Ready for UI integration

## Notes

UI controls for grouping can be added later to the sidebar - for now we have the service layer ready.
