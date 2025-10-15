# macOS Integration Phase 1 Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Integrate Music Assistant Player with macOS Now Playing Center and App Intents for media key control and Siri/Shortcuts support.

**Architecture:** Extend existing PlayerService with Now Playing integration via Swift extension. Create separate AppIntents module that bridges Siri/Shortcuts to PlayerService through IntentHelper singleton. All updates flow one direction (PlayerService → OS), media keys/Siri flow back through existing PlayerService async methods.

**Tech Stack:** MediaPlayer framework (MPNowPlayingInfoCenter, MPRemoteCommandCenter), AppIntents framework, Combine for reactive updates

---

## Task 1: Add Intents Logger Category

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Utilities/AppLogger.swift:14`

**Step 1: Add intents logger to AppLogger enum**

In `AppLogger.swift`, add the new logger after line 14:

```swift
static let intents = Logger(subsystem: subsystem, category: "intents")
```

**Step 2: Verify it compiles**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Utilities/AppLogger.swift
git commit -m "feat: add intents logger category for App Intents debugging"
```

---

## Task 2: Create Now Playing Integration Extension

**Files:**
- Create: `Sources/MusicAssistantPlayer/Services/PlayerService+NowPlaying.swift`
- Modify: `Sources/MusicAssistantPlayer/Services/PlayerService.swift:36`

**Step 1: Create PlayerService+NowPlaying.swift**

Create the file with this complete implementation:

```swift
// ABOUTME: Now Playing Center integration for media keys and Control Center
// ABOUTME: Observes PlayerService state and updates MPNowPlayingInfoCenter

import Foundation
import MediaPlayer
import Combine

extension PlayerService {
    func setupNowPlayingIntegration() {
        setupRemoteCommandCenter()
        setupNowPlayingObservers()
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.play()
            }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.pause()
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.skipNext()
            }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.skipPrevious()
            }
            return .success
        }

        AppLogger.player.info("Now Playing remote commands registered")
    }

    private func setupNowPlayingObservers() {
        // Observe track changes
        $currentTrack
            .sink { [weak self] track in
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)

        // Observe playback state changes
        $playbackState
            .sink { [weak self] _ in
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)

        // Observe progress changes (throttle to avoid excessive updates)
        $progress
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)

        AppLogger.player.info("Now Playing observers registered")
    }

    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()

        if let track = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progress

            // TODO: Add artwork support when available
            // if let artworkURL = track.artworkURL {
            //     // Fetch and set MPMediaItemArtwork
            // }
        }

        // Set playback rate (0.0 for paused, 1.0 for playing)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = (playbackState == .playing) ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        AppLogger.player.debug("Now Playing info updated: \(track?.title ?? "no track")")
    }
}
```

**Step 2: Call setupNowPlayingIntegration from PlayerService.init**

In `PlayerService.swift`, add after line 36 (after `monitorConnection()`):

```swift
setupNowPlayingIntegration()
```

**Step 3: Verify it compiles**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 4: Manual test - Media keys**

1. Run the app
2. Play a track
3. Press media keys on keyboard (play/pause, next, previous)
Expected: App responds to media keys

**Step 5: Manual test - Control Center**

1. While track is playing, open Control Center
Expected: See track title, artist, album in Now Playing widget

**Step 6: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/PlayerService+NowPlaying.swift Sources/MusicAssistantPlayer/Services/PlayerService.swift
git commit -m "feat: add Now Playing Center integration with media key support

- Register MPRemoteCommandCenter handlers for play/pause/next/previous
- Observe PlayerService state via Combine and update MPNowPlayingInfoCenter
- Throttle progress updates to avoid excessive Now Playing updates
- Add logging for Now Playing events"
```

---

## Task 3: Create Intent Helper Singleton

**Files:**
- Create: `Sources/MusicAssistantPlayer/Intents/IntentHelper.swift`

**Step 1: Create Intents directory and IntentHelper.swift**

```bash
mkdir -p Sources/MusicAssistantPlayer/Intents
```

Then create `IntentHelper.swift` with this implementation:

```swift
// ABOUTME: Singleton bridge between AppIntents and PlayerService
// ABOUTME: Provides shared access to PlayerService for Siri/Shortcuts integration

import Foundation

@MainActor
class IntentHelper {
    static let shared = IntentHelper()

    // Weak reference to avoid retain cycles
    weak var playerService: PlayerService?

    private init() {
        AppLogger.intents.info("IntentHelper initialized")
    }
}
```

**Step 2: Verify it compiles**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Intents/IntentHelper.swift
git commit -m "feat: add IntentHelper singleton for AppIntents bridge"
```

---

## Task 4: Create App Intents

**Files:**
- Create: `Sources/MusicAssistantPlayer/Intents/PlayerIntents.swift`

**Step 1: Create PlayerIntents.swift**

Create the file with all five intents:

```swift
// ABOUTME: App Intents for Siri and Shortcuts integration
// ABOUTME: Provides playback control via voice commands and automation

import Foundation
import AppIntents

struct PlayIntent: AppIntent {
    static let title: LocalizedStringResource = "Play Music"
    static let description = IntentDescription("Resume playback in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("PlayIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("PlayIntent: No PlayerService available")
            return .result()
        }

        await playerService.play()
        return .result()
    }
}

struct PauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Pause Music"
    static let description = IntentDescription("Pause playback in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("PauseIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("PauseIntent: No PlayerService available")
            return .result()
        }

        await playerService.pause()
        return .result()
    }
}

struct StopIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Music"
    static let description = IntentDescription("Stop playback in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("StopIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("StopIntent: No PlayerService available")
            return .result()
        }

        await playerService.stop()
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Track"
    static let description = IntentDescription("Skip to next track in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("NextTrackIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("NextTrackIntent: No PlayerService available")
            return .result()
        }

        await playerService.skipNext()
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Previous Track"
    static let description = IntentDescription("Skip to previous track in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("PreviousTrackIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("PreviousTrackIntent: No PlayerService available")
            return .result()
        }

        await playerService.skipPrevious()
        return .result()
    }
}
```

**Step 2: Verify it compiles**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Intents/PlayerIntents.swift
git commit -m "feat: add App Intents for Siri and Shortcuts playback control

- Add PlayIntent, PauseIntent, StopIntent, NextTrackIntent, PreviousTrackIntent
- All intents access PlayerService via IntentHelper singleton
- Add logging for intent triggers and failures
- Silent no-op if PlayerService unavailable"
```

---

## Task 5: Register App Shortcuts

**Files:**
- Modify: `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift:8`
- Modify: `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift:73`

**Step 1: Add AppIntents import**

At the top of `MusicAssistantPlayerApp.swift`, add after line 5:

```swift
import AppIntents
```

**Step 2: Create AppShortcutsProvider**

Add this after the closing brace of the `MusicAssistantPlayerApp` struct (after line 73):

```swift
struct MusicAssistantAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayIntent(),
            phrases: [
                "Play music in \(.applicationName)",
                "Resume music in \(.applicationName)"
            ],
            shortTitle: "Play",
            systemImageName: "play.fill"
        )

        AppShortcut(
            intent: PauseIntent(),
            phrases: [
                "Pause music in \(.applicationName)",
                "Pause \(.applicationName)"
            ],
            shortTitle: "Pause",
            systemImageName: "pause.fill"
        )

        AppShortcut(
            intent: StopIntent(),
            phrases: [
                "Stop music in \(.applicationName)",
                "Stop \(.applicationName)"
            ],
            shortTitle: "Stop",
            systemImageName: "stop.fill"
        )

        AppShortcut(
            intent: NextTrackIntent(),
            phrases: [
                "Next track in \(.applicationName)",
                "Skip song in \(.applicationName)"
            ],
            shortTitle: "Next",
            systemImageName: "forward.fill"
        )

        AppShortcut(
            intent: PreviousTrackIntent(),
            phrases: [
                "Previous track in \(.applicationName)",
                "Go back in \(.applicationName)"
            ],
            shortTitle: "Previous",
            systemImageName: "backward.fill"
        )
    }
}
```

**Step 3: Verify it compiles**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift
git commit -m "feat: register App Shortcuts for Siri voice commands

- Add AppShortcutsProvider with suggested phrases for all intents
- Define system icons for each shortcut
- Enable Siri integration with natural language phrases"
```

---

## Task 6: Wire IntentHelper to PlayerService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift:62`

**Step 1: Set IntentHelper.playerService when client connects**

In `MusicAssistantPlayerApp.swift`, inside the `handleConnection` method, after line 61 (after `self.client = newClient`), add:

```swift
// Create PlayerService and wire to IntentHelper
let playerService = PlayerService(client: newClient)
IntentHelper.shared.playerService = playerService
AppLogger.intents.info("PlayerService wired to IntentHelper")
```

**Note:** This requires refactoring how PlayerService is created. Currently it's created implicitly. We need to check where PlayerService instance is created and ensure IntentHelper gets the reference.

**Step 2: Find where PlayerService is instantiated**

Run: `grep -r "PlayerService()" Sources/`
Expected: Find the location where PlayerService is created

**Step 3: Update based on findings**

This step depends on the current architecture. If PlayerService is created in a ViewModel or elsewhere, we need to pass it to IntentHelper at that location.

**Placeholder for now - will need to investigate codebase structure**

**Step 4: Verify it compiles**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 5: Manual test - Shortcuts app**

1. Run the app and connect to server
2. Open Shortcuts app
3. Create new shortcut with "Play Music" action from Music Assistant Player
4. Run the shortcut
Expected: Music starts playing

**Step 6: Manual test - Siri**

1. "Hey Siri, play music in Music Assistant Player"
Expected: Siri executes command, music plays

**Step 7: Commit**

```bash
git add Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift
git commit -m "feat: wire PlayerService to IntentHelper for Siri integration

- Set IntentHelper.playerService reference when client connects
- Enable App Intents to access PlayerService for playback control
- Add logging for IntentHelper wiring"
```

---

## Task 7: Add Entitlements (if needed)

**Files:**
- Modify: `Resources/MusicAssistantPlayer.entitlements` (if Siri entitlement needed)

**Step 1: Check if Siri entitlement is required**

AppIntents on macOS may require specific entitlements. Check Apple documentation and test behavior.

**Step 2: If needed, add to entitlements file**

Add if required:
```xml
<key>com.apple.security.app-intents</key>
<true/>
```

**Step 3: Verify app still builds and runs**

Run: `swift build && swift run`
Expected: App launches successfully

**Step 4: Commit if changes made**

```bash
git add Resources/MusicAssistantPlayer.entitlements
git commit -m "feat: add App Intents entitlement for Siri integration"
```

---

## Testing Checklist

After all tasks complete:

### Now Playing Center
- [ ] Track info appears in Control Center
- [ ] Album, artist, title all show correctly
- [ ] Playback time updates during playback
- [ ] Media keys control playback (play/pause)
- [ ] Next/previous keys skip tracks
- [ ] Paused state shows in Control Center

### App Intents
- [ ] Shortcuts app lists Music Assistant Player intents
- [ ] "Play Music" shortcut works
- [ ] "Pause Music" shortcut works
- [ ] "Stop Music" shortcut works
- [ ] "Next Track" shortcut works
- [ ] "Previous Track" shortcut works
- [ ] Siri voice commands work for all intents
- [ ] Intents fail gracefully when app not connected

### Edge Cases
- [ ] Media keys when no player selected (no crash)
- [ ] Siri command when app not running (launches app)
- [ ] Now Playing clears when playback stops
- [ ] No memory leaks from Combine subscriptions

---

## Future Enhancements (Not in this plan)

- Album artwork in Now Playing (requires image fetching/caching)
- Widgets (requires Widget Extension target + App Groups)
- User notifications with preference toggle (requires Settings.bundle)
- Seek position support via media scrubber
- Volume control via Now Playing

---

## Notes

- Follow TDD principles where possible (AppIntents and MediaPlayer are hard to unit test, focus on integration testing)
- Use DRY - leverage existing PlayerService methods, don't duplicate logic
- YAGNI - No artwork, widgets, or notifications in phase 1
- Commit frequently after each task
- Test manually after each major component (Now Playing, then Intents)
