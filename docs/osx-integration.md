Of course\! Based on the extensive codebase you've provided for your Music Assistant Player, it's clear you have a solid MVVM architecture. This makes integrating with macOS features quite straightforward. Here's a plan for several high-impact OS integrations.

-----

## 🎵 Now Playing Center & Media Keys

This is the **highest priority** integration for any media app. It allows your app to publish its current playback state to the system, making it appear in the Control Center's "Now Playing" widget and enabling the physical media keys (play/pause, next, previous) on Mac keyboards to control your app.

### Implementation Plan

The logic for this should live almost entirely within your **`PlayerService.swift`**, as it's the single source of truth for playback state.

1.  **Import MediaPlayer:** Add `import MediaPlayer` to the top of `PlayerService.swift`.

2.  **Update Now Playing Info:** Create a function that populates the system's `nowPlayingInfo` dictionary whenever the state changes.

    ```swift
    // In PlayerService.swift

    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        if let track = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progress
        }

        // Set the playback rate (0.0 for paused, 1.0 for playing)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = (playbackState == .playing) ? 1.0 : 0.0

        // Set the info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    ```

3.  **Register Remote Commands:** In the `init` method of `PlayerService`, set up handlers for the media keys. These handlers will call your existing service methods.

    ```swift
    // In PlayerService.swift's init()

    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.addTarget { [weak self] event in
        Task { await self?.play() }
        return .success
    }

    commandCenter.pauseCommand.addTarget { [weak self] event in
        Task { await self?.pause() }
        return .success
    }

    commandCenter.nextTrackCommand.addTarget { [weak self] event in
        Task { await self?.skipNext() }
        return .success
    }

    commandCenter.previousTrackCommand.addTarget { [weak self] event in
        Task { await self?.skipPrevious() }
        return .success
    }
    ```

4.  **Trigger Updates:** Call your new `updateNowPlayingInfo()` function whenever `currentTrack`, `playbackState`, or `progress` changes. You can do this easily by adding it inside the `.sink` and `.assign` blocks in your `NowPlayingViewModel`'s `setupBindings` method, or preferably, directly in the `PlayerService` by observing its own publishers.

-----

## 🚀 App Intents & Shortcuts

This allows users to control your app using Siri or the Shortcuts app, creating powerful automations. For example, a user could create a "Work Focus" shortcut that sets a specific playlist to play on their office speaker.

### Implementation Plan

1.  **Define App Intents:** Create a new Swift file for your intents. Define simple, verb-based actions.

    ```swift
    // In a new file, e.g., PlayerIntents.swift
    import AppIntents

    struct PlayIntent: AppIntent {
        static let title: LocalizedStringResource = "Play Music"

        // This would need a way to access your PlayerService,
        // often through a shared singleton or by passing the client info.
        @MainActor
        func perform() async throws -> some IntentResult {
            // Logic to get the PlayerService and call play()
            return .result()
        }
    }

    // You could also create intents with parameters
    struct PlayOnSpeakerIntent: AppIntent {
        static let title: LocalizedStringResource = "Play on Speaker"

        @Parameter(title: "Speaker Name")
        var speakerName: String

        @MainActor
        func perform() async throws -> some IntentResult {
            // Logic to find the speaker by name and command it to play
            return .result()
        }
    }
    ```

2.  **Expose Intents:** Create an `AppShortcutsProvider` to make your intents available to the system.

    ```swift
    // In MusicAssistantPlayerApp.swift
    static var shortcuts: AppShortcuts {
        AppShortcutsCollection {
            AppShortcut(
                intent: PlayIntent(),
                phrases: ["Play music in \(.applicationName)"]
            )
            AppShortcut(
                intent: PlayOnSpeakerIntent(),
                phrases: ["Play music on \(\.$speakerName) in \(.applicationName)"]
            )
        }
    }
    ```

-----

## 🧩 Desktop Widgets (WidgetKit)

A "Now Playing" widget for the desktop or Notification Center would be a fantastic addition, especially with macOS Sonoma's interactive widgets.

### Implementation Plan

1.  **Add a Widget Extension Target:** Add a new "Widget Extension" target to your project.

2.  **Enable App Groups:** To share data between your main app and the widget, enable the "App Groups" capability for both targets. This allows them to share a `UserDefaults` suite.

3.  **Share Data:** In `PlayerService.swift`, whenever the state changes, write the current track info and playback state to the shared `UserDefaults`.

    ```swift
    // In PlayerService.swift, after updating state
    if let sharedDefaults = UserDefaults(suiteName: "group.com.harperreed.musicassistantplayer") {
        // Encode track info to JSON or save individual properties
        sharedDefaults.set(track.title, forKey: "nowPlayingTitle")
        sharedDefaults.set(isPlaying, forKey: "isPlaying")
        // ... and so on
    }
    WidgetCenter.shared.reloadAllTimelines() // Tell widgets to update
    ```

4.  **Build the Widget View:** In your widget extension, create a SwiftUI view that displays the album art, track title, and artist.

5.  **Create a Timeline Provider:** The widget's timeline provider will read from the shared `UserDefaults` to get the current state and create a timeline entry to display the view. You can also implement interactive buttons (play/pause) using the new interactive widget APIs.

-----

## 🔔 User Notifications

Inform the user when the track changes, especially if the app isn't in the foreground.

### Implementation Plan

This is another feature that fits perfectly in **`PlayerService.swift`**.

1.  **Request Authorization:** In `MusicAssistantPlayerApp.swift`, request permission to send notifications when the app starts.

    ```swift
    // In onAppear or init of the main App struct
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
        // Handle result
    }
    ```

2.  **Trigger Notification on Track Change:** In the `PlayerService`'s subscription to `$currentTrack`, schedule a notification.

    ```swift
    // Inside playerService.$currentTrack.sink { [weak self] track in ... }
    // After updating the view model properties:

    // Make sure we have a new track and it's different from the last one shown
    if let track = track, track.id != self.lastNotifiedTrackId {
        self.lastNotifiedTrackId = track.id
        postTrackChangeNotification(for: track)
    }

    // ... function to implement
    func postTrackChangeNotification(for track: Track) {
        let content = UNMutableNotificationContent()
        content.title = track.title
        content.subtitle = track.artist
        content.body = track.album

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    ```
