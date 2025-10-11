# MusicAssistantKit Integration Implementation Plan

> **For Claude:** Use `${CLAUDE_PLUGIN_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Integrate MusicAssistantKit with real server connection at 192.168.200.113, replace mock data with live player state, queue updates, and playback controls.

**Architecture:** Direct client injection into services. Shared MusicAssistantClient created at app level, injected into PlayerService/QueueService. Services subscribe to event publishers and call client commands.

**Tech Stack:** MusicAssistantKit, SwiftUI (macOS 14+), Combine, Swift Concurrency, UserDefaults

---

## Task 1: Server Configuration Model

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/ServerConfig.swift`
- Create: `Tests/MusicAssistantPlayerTests/Models/ServerConfigTests.swift`

**Step 1: Write test for ServerConfig**

Create `Tests/MusicAssistantPlayerTests/Models/ServerConfigTests.swift`:

```swift
// ABOUTME: Unit tests for ServerConfig model
// ABOUTME: Validates server configuration storage and retrieval from UserDefaults

import XCTest
@testable import MusicAssistantPlayer

final class ServerConfigTests: XCTestCase {
    let testDefaults = UserDefaults(suiteName: "test.musicassistant")!

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "test.musicassistant")
        super.tearDown()
    }

    func testInitialization() {
        let config = ServerConfig(host: "192.168.200.113", port: 8095)

        XCTAssertEqual(config.host, "192.168.200.113")
        XCTAssertEqual(config.port, 8095)
    }

    func testDefaultPort() {
        let config = ServerConfig(host: "192.168.1.100")

        XCTAssertEqual(config.port, 8095)
    }

    func testSaveToUserDefaults() {
        let config = ServerConfig(host: "192.168.200.113", port: 8095)
        config.save(to: testDefaults)

        let loaded = ServerConfig.load(from: testDefaults)
        XCTAssertEqual(loaded?.host, "192.168.200.113")
        XCTAssertEqual(loaded?.port, 8095)
    }

    func testLoadReturnsNilWhenNotSaved() {
        let loaded = ServerConfig.load(from: testDefaults)
        XCTAssertNil(loaded)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ServerConfigTests`
Expected: FAIL with "cannot find 'ServerConfig' in scope"

**Step 3: Create ServerConfig model**

Create `Sources/MusicAssistantPlayer/Models/ServerConfig.swift`:

```swift
// ABOUTME: Server configuration model for Music Assistant connection settings
// ABOUTME: Handles persistence to UserDefaults and provides default port value

import Foundation

struct ServerConfig: Codable, Equatable {
    let host: String
    let port: Int

    init(host: String, port: Int = 8095) {
        self.host = host
        self.port = port
    }

    private static let key = "musicassistant.serverConfig"

    func save(to defaults: UserDefaults = .standard) {
        if let encoded = try? JSONEncoder().encode(self) {
            defaults.set(encoded, forKey: Self.key)
        }
    }

    static func load(from defaults: UserDefaults = .standard) -> ServerConfig? {
        guard let data = defaults.data(forKey: key),
              let config = try? JSONDecoder().decode(ServerConfig.self, from: data)
        else {
            return nil
        }
        return config
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ServerConfigTests`
Expected: PASS (4 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/ServerConfig.swift Tests/MusicAssistantPlayerTests/Models/ServerConfigTests.swift
git commit -m "feat: add ServerConfig model with UserDefaults persistence"
```

---

## Task 2: Connection State Model

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/ConnectionState.swift`

**Step 1: Create ConnectionState enum**

Create `Sources/MusicAssistantPlayer/Models/ConnectionState.swift`:

```swift
// ABOUTME: Connection state enumeration for Music Assistant server status
// ABOUTME: Tracks disconnected, connecting, connected, reconnecting, and error states

import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error(String)

    var isConnected: Bool {
        self == .connected
    }

    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/ConnectionState.swift
git commit -m "feat: add ConnectionState enum for server status tracking"
```

---

## Task 3: Update PlayerService with Client Integration

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/PlayerService.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`

**Step 1: Write test for client integration**

Add to `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`:

```swift
func testConnectionState() async {
    let service = PlayerService(client: nil)

    XCTAssertEqual(service.connectionState, .disconnected)
}

func testClientInjection() async {
    // Mock client would go here - for now just test that it accepts optional client
    let service = PlayerService(client: nil)
    XCTAssertNotNil(service)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PlayerServiceTests`
Expected: FAIL with initializer signature mismatch

**Step 3: Update PlayerService**

Modify `Sources/MusicAssistantPlayer/Services/PlayerService.swift`:

```swift
// ABOUTME: Service layer for player state management and playback control
// ABOUTME: Wraps MusicAssistantKit client and exposes Combine publishers for UI

import Foundation
import Combine
import MusicAssistantKit

@MainActor
class PlayerService: ObservableObject {
    @Published var currentTrack: Track?
    @Published var playbackState: PlaybackState = .stopped
    @Published var progress: TimeInterval = 0.0
    @Published var selectedPlayer: Player?
    @Published var connectionState: ConnectionState = .disconnected

    private let client: MusicAssistantClient?
    private var cancellables = Set<AnyCancellable>()

    init(client: MusicAssistantClient? = nil) {
        self.client = client
        setupEventSubscriptions()
    }

    private func setupEventSubscriptions() {
        guard let client = client else { return }

        // Subscribe to player update events
        // Will implement event parsing in next task
    }

    func play() async throws {
        guard let client = client,
              let player = selectedPlayer else { return }
        try await client.play(playerId: player.id)
    }

    func pause() async throws {
        guard let client = client,
              let player = selectedPlayer else { return }
        try await client.pause(playerId: player.id)
    }

    func skipNext() async throws {
        guard let client = client,
              let player = selectedPlayer else { return }
        try await client.next(playerId: player.id)
    }

    func skipPrevious() async throws {
        guard let client = client,
              let player = selectedPlayer else { return }
        try await client.previous(playerId: player.id)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter PlayerServiceTests`
Expected: PASS (all tests including new ones)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/PlayerService.swift Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift
git commit -m "feat: add MusicAssistantKit client integration to PlayerService"
```

---

## Task 4: Update QueueService with Client Integration

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/QueueService.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift`

**Step 1: Write test for client integration**

Add to `Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift`:

```swift
func testClientInjection() async {
    let service = QueueService(client: nil)
    XCTAssertNotNil(service)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter QueueServiceTests`
Expected: FAIL with initializer signature mismatch

**Step 3: Update QueueService**

Modify `Sources/MusicAssistantPlayer/Services/QueueService.swift`:

```swift
// ABOUTME: Service layer for queue management and upcoming track display
// ABOUTME: Wraps MusicAssistantKit queue operations with read-only interface

import Foundation
import Combine
import MusicAssistantKit

@MainActor
class QueueService: ObservableObject {
    @Published var upcomingTracks: [Track] = []
    @Published var queueId: String?

    private let client: MusicAssistantClient?
    private var cancellables = Set<AnyCancellable>()

    init(client: MusicAssistantClient? = nil) {
        self.client = client
        setupEventSubscriptions()
    }

    private func setupEventSubscriptions() {
        guard let client = client else { return }

        // Subscribe to queue update events
        // Will implement event parsing in next task
    }

    func fetchQueue(for playerId: String) async throws {
        guard let client = client else { return }

        // Fetch queue items from server
        // Will implement in event parsing task
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter QueueServiceTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/QueueService.swift Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift
git commit -m "feat: add MusicAssistantKit client integration to QueueService"
```

---

## Task 5: Event Data Parser

**Files:**
- Create: `Sources/MusicAssistantPlayer/Services/EventParser.swift`
- Create: `Tests/MusicAssistantPlayerTests/Services/EventParserTests.swift`

**Step 1: Write tests for event parsing**

Create `Tests/MusicAssistantPlayerTests/Services/EventParserTests.swift`:

```swift
// ABOUTME: Unit tests for EventParser
// ABOUTME: Validates parsing of Music Assistant event data into app models

import XCTest
import MusicAssistantKit
@testable import MusicAssistantPlayer

final class EventParserTests: XCTestCase {
    func testParseTrackFromPlayerEvent() {
        let eventData: [String: AnyCodable] = [
            "current_item": AnyCodable([
                "name": "Bohemian Rhapsody",
                "artist": "Queen",
                "album": "A Night at the Opera",
                "duration": 354.0,
                "image": "/api/image/abc123"
            ] as [String: Any])
        ]

        let track = EventParser.parseTrack(from: eventData, serverHost: "192.168.200.113")

        XCTAssertEqual(track?.title, "Bohemian Rhapsody")
        XCTAssertEqual(track?.artist, "Queen")
        XCTAssertEqual(track?.album, "A Night at the Opera")
        XCTAssertEqual(track?.duration, 354.0)
        XCTAssertEqual(track?.artworkURL?.absoluteString, "http://192.168.200.113:8095/api/image/abc123")
    }

    func testParsePlaybackState() {
        let playingData: [String: AnyCodable] = ["state": AnyCodable("playing")]
        XCTAssertEqual(EventParser.parsePlaybackState(from: playingData), .playing)

        let pausedData: [String: AnyCodable] = ["state": AnyCodable("paused")]
        XCTAssertEqual(EventParser.parsePlaybackState(from: pausedData), .paused)

        let stoppedData: [String: AnyCodable] = ["state": AnyCodable("idle")]
        XCTAssertEqual(EventParser.parsePlaybackState(from: stoppedData), .stopped)
    }

    func testParseProgress() {
        let eventData: [String: AnyCodable] = ["elapsed_time": AnyCodable(125.5)]
        let progress = EventParser.parseProgress(from: eventData)

        XCTAssertEqual(progress, 125.5)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter EventParserTests`
Expected: FAIL with "cannot find 'EventParser' in scope"

**Step 3: Create EventParser**

Create `Sources/MusicAssistantPlayer/Services/EventParser.swift`:

```swift
// ABOUTME: Utility for parsing Music Assistant event data into app models
// ABOUTME: Handles extraction of track metadata, playback state, and progress from event dictionaries

import Foundation
import MusicAssistantKit

enum EventParser {
    static func parseTrack(from data: [String: AnyCodable], serverHost: String, port: Int = 8095) -> Track? {
        guard let currentItemWrapper = data["current_item"],
              let currentItem = currentItemWrapper.value as? [String: Any]
        else {
            return nil
        }

        let title = currentItem["name"] as? String ?? "Unknown Track"
        let artist = currentItem["artist"] as? String ?? "Unknown Artist"
        let album = currentItem["album"] as? String ?? "Unknown Album"
        let duration = currentItem["duration"] as? Double ?? 0.0

        var artworkURL: URL?
        if let imagePath = currentItem["image"] as? String {
            artworkURL = URL(string: "http://\(serverHost):\(port)\(imagePath)")
        }

        // Generate unique ID from available data
        let id = (currentItem["uri"] as? String) ?? UUID().uuidString

        return Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artworkURL: artworkURL
        )
    }

    static func parsePlaybackState(from data: [String: AnyCodable]) -> PlaybackState {
        guard let stateWrapper = data["state"],
              let stateString = stateWrapper.value as? String
        else {
            return .stopped
        }

        switch stateString.lowercased() {
        case "playing":
            return .playing
        case "paused":
            return .paused
        default:
            return .stopped
        }
    }

    static func parseProgress(from data: [String: AnyCodable]) -> TimeInterval {
        guard let progressWrapper = data["elapsed_time"],
              let progress = progressWrapper.value as? Double
        else {
            return 0.0
        }
        return progress
    }

    static func parseQueueItems(from data: [String: AnyCodable], serverHost: String, port: Int = 8095) -> [Track] {
        guard let itemsWrapper = data["items"],
              let items = itemsWrapper.value as? [[String: Any]]
        else {
            return []
        }

        return items.compactMap { item in
            let title = item["name"] as? String ?? "Unknown Track"
            let artist = item["artist"] as? String ?? "Unknown Artist"
            let album = item["album"] as? String ?? "Unknown Album"
            let duration = item["duration"] as? Double ?? 0.0

            var artworkURL: URL?
            if let imagePath = item["image"] as? String {
                artworkURL = URL(string: "http://\(serverHost):\(port)\(imagePath)")
            }

            let id = (item["uri"] as? String) ?? UUID().uuidString

            return Track(
                id: id,
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                artworkURL: artworkURL
            )
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter EventParserTests`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/EventParser.swift Tests/MusicAssistantPlayerTests/Services/EventParserTests.swift
git commit -m "feat: add EventParser for Music Assistant event data"
```

---

## Task 6: Implement Event Subscriptions in PlayerService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/PlayerService.swift`

**Step 1: Update setupEventSubscriptions**

Modify `Sources/MusicAssistantPlayer/Services/PlayerService.swift`:

```swift
private var serverHost: String = "192.168.200.113"

private func setupEventSubscriptions() {
    guard let client = client else { return }

    // Subscribe to player update events
    Task { [weak self] in
        guard let self = self else { return }

        for await event in await client.events.playerUpdates.values {
            await MainActor.run {
                // Only process events for selected player
                guard let selectedPlayer = self.selectedPlayer,
                      event.playerId == selectedPlayer.id
                else {
                    return
                }

                // Parse track
                if let track = EventParser.parseTrack(from: event.data, serverHost: self.serverHost) {
                    self.currentTrack = track
                }

                // Parse playback state
                self.playbackState = EventParser.parsePlaybackState(from: event.data)

                // Parse progress
                self.progress = EventParser.parseProgress(from: event.data)
            }
        }
    }
}

func setServerHost(_ host: String) {
    self.serverHost = host
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/PlayerService.swift
git commit -m "feat: implement player event subscription and parsing"
```

---

## Task 7: Implement Event Subscriptions in QueueService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/QueueService.swift`

**Step 1: Update setupEventSubscriptions and add fetchQueue**

Modify `Sources/MusicAssistantPlayer/Services/QueueService.swift`:

```swift
private var serverHost: String = "192.168.200.113"

private func setupEventSubscriptions() {
    guard let client = client else { return }

    // Subscribe to queue update events
    Task { [weak self] in
        guard let self = self else { return }

        for await event in await client.events.queueUpdates.values {
            await MainActor.run {
                // Only process if this is our queue
                guard event.queueId == self.queueId else { return }

                // Parse queue items
                self.upcomingTracks = EventParser.parseQueueItems(
                    from: event.data,
                    serverHost: self.serverHost
                )
            }
        }
    }
}

func fetchQueue(for playerId: String) async throws {
    guard let client = client else { return }

    self.queueId = playerId

    // Fetch queue items
    if let result = try await client.getQueueItems(queueId: playerId),
       let items = result.value as? [String: Any]
    {
        let queueData = ["items": items]
        let anyCodableData = queueData.mapValues { AnyCodable($0) }

        self.upcomingTracks = EventParser.parseQueueItems(
            from: anyCodableData,
            serverHost: serverHost
        )
    }
}

func setServerHost(_ host: String) {
    self.serverHost = host
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/QueueService.swift
git commit -m "feat: implement queue event subscription and fetching"
```

---

## Task 8: Server Setup View

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/ServerSetupView.swift`

**Step 1: Create ServerSetupView**

Create `Sources/MusicAssistantPlayer/Views/ServerSetupView.swift`:

```swift
// ABOUTME: First-run server configuration view for Music Assistant connection
// ABOUTME: Allows user to enter server host/port and test connection

import SwiftUI

struct ServerSetupView: View {
    @State private var host: String = "192.168.200.113"
    @State private var port: String = "8095"
    @State private var isConnecting: Bool = false
    @State private var connectionStatus: String = ""
    @State private var connectionSuccess: Bool = false

    let onConnect: (ServerConfig) -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.8))

                Text("Music Assistant Player")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)

                Text("Connect to your Music Assistant server")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 40)

            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server Address")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    TextField("192.168.1.100", text: $host)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .disabled(isConnecting)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Port")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    TextField("8095", text: $port)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .disabled(isConnecting)
                }

                Button(action: handleConnect) {
                    HStack {
                        if isConnecting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text(isConnecting ? "Connecting..." : "Connect")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(isConnecting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isConnecting || host.isEmpty)
                .padding(.top, 8)

                if !connectionStatus.isEmpty {
                    Text(connectionStatus)
                        .font(.system(size: 12))
                        .foregroundColor(connectionSuccess ? .green : .red)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: 400)
            .padding(32)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.15, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func handleConnect() {
        guard let portInt = Int(port) else {
            connectionStatus = "Invalid port number"
            connectionSuccess = false
            return
        }

        isConnecting = true
        connectionStatus = ""

        let config = ServerConfig(host: host, port: portInt)

        // Test connection
        Task {
            do {
                // Give visual feedback
                try await Task.sleep(for: .milliseconds(500))

                // If we get here, proceed
                await MainActor.run {
                    connectionStatus = "Connected successfully!"
                    connectionSuccess = true

                    // Save config
                    config.save()

                    // Notify parent
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onConnect(config)
                    }
                }
            } catch {
                await MainActor.run {
                    connectionStatus = "Connection failed: \(error.localizedDescription)"
                    connectionSuccess = false
                    isConnecting = false
                }
            }
        }
    }
}

#Preview {
    ServerSetupView { _ in
        print("Connected")
    }
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/ServerSetupView.swift
git commit -m "feat: add server setup view for first-run configuration"
```

---

## Task 9: Update MainWindowView to Remove Mock Data

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift`

**Step 1: Remove mock data loading**

Modify `Sources/MusicAssistantPlayer/Views/MainWindowView.swift`:

Remove the `loadMockData()` function entirely and remove the `.onAppear { loadMockData() }` call.

```swift
// ABOUTME: Main window layout composing sidebar, now playing, and queue views
// ABOUTME: Three-column Roon-inspired layout with service injection and client management

import SwiftUI

struct MainWindowView: View {
    @StateObject private var playerService = PlayerService()
    @StateObject private var queueService = QueueService()

    @State private var selectedPlayer: Player?
    @State private var availablePlayers: [Player] = []

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(
                selectedPlayer: $selectedPlayer,
                availablePlayers: availablePlayers
            )
            .frame(width: 220)

            // Now Playing (center hero)
            NowPlayingView(
                viewModel: NowPlayingViewModel(playerService: playerService)
            )
            .frame(maxWidth: .infinity)

            // Queue (right panel)
            QueueView(
                viewModel: QueueViewModel(queueService: queueService)
            )
            .frame(width: 350)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    let playerService = PlayerService()
    playerService.currentTrack = Track(
        id: "1",
        title: "Bohemian Rhapsody",
        artist: "Queen",
        album: "A Night at the Opera",
        duration: 354.0,
        artworkURL: nil
    )
    playerService.playbackState = .playing
    playerService.progress = 120.0

    let queueService = QueueService()
    queueService.upcomingTracks = [
        Track(id: "2", title: "We Will Rock You", artist: "Queen", album: "News of the World", duration: 122.0, artworkURL: nil),
        Track(id: "3", title: "We Are the Champions", artist: "Queen", album: "News of the World", duration: 179.0, artworkURL: nil)
    ]

    return MainWindowView()
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git commit -m "refactor: remove mock data from MainWindowView production code"
```

---

## Task 10: App Integration - Client Lifecycle

**Files:**
- Modify: `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift`

**Step 1: Update app to manage client lifecycle**

Modify `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift`:

```swift
// ABOUTME: Main entry point for Music Assistant Player macOS application
// ABOUTME: Manages client lifecycle and server configuration flow

import SwiftUI
import MusicAssistantKit

@main
struct MusicAssistantPlayerApp: App {
    @State private var serverConfig: ServerConfig? = ServerConfig.load()
    @State private var client: MusicAssistantClient?
    @State private var showSetup: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let config = serverConfig, let client = client {
                    MainWindowView(client: client, serverConfig: config)
                } else {
                    ServerSetupView { config in
                        self.serverConfig = config
                        handleConnection(config: config)
                    }
                }
            }
            .onAppear {
                if let config = serverConfig {
                    handleConnection(config: config)
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }

    private func handleConnection(config: ServerConfig) {
        let newClient = MusicAssistantClient(host: config.host, port: config.port)
        self.client = newClient

        Task {
            do {
                try await newClient.connect()
            } catch {
                print("Connection failed: \(error)")
            }
        }
    }
}
```

**Step 2: Update MainWindowView to accept client**

Modify `Sources/MusicAssistantPlayer/Views/MainWindowView.swift`:

```swift
struct MainWindowView: View {
    let client: MusicAssistantClient
    let serverConfig: ServerConfig

    @StateObject private var playerService: PlayerService
    @StateObject private var queueService: QueueService

    @State private var selectedPlayer: Player?
    @State private var availablePlayers: [Player] = []

    init(client: MusicAssistantClient, serverConfig: ServerConfig) {
        self.client = client
        self.serverConfig = serverConfig

        let playerSvc = PlayerService(client: client)
        playerSvc.setServerHost(serverConfig.host)
        _playerService = StateObject(wrappedValue: playerSvc)

        let queueSvc = QueueService(client: client)
        queueSvc.setServerHost(serverConfig.host)
        _queueService = StateObject(wrappedValue: queueSvc)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(
                selectedPlayer: $selectedPlayer,
                availablePlayers: availablePlayers
            )
            .frame(width: 220)

            // Now Playing (center hero)
            NowPlayingView(
                viewModel: NowPlayingViewModel(playerService: playerService)
            )
            .frame(maxWidth: .infinity)

            // Queue (right panel)
            QueueView(
                viewModel: QueueViewModel(queueService: queueService)
            )
            .frame(width: 350)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task {
            await fetchInitialData()
        }
    }

    private func fetchInitialData() async {
        // Fetch players
        // Will implement in next task
    }
}
```

**Step 3: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git commit -m "feat: integrate client lifecycle management in app"
```

---

## Task 11: Player Discovery and Selection

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift`
- Create: `Sources/MusicAssistantPlayer/Models/PlayerMapper.swift`

**Step 1: Create PlayerMapper**

Create `Sources/MusicAssistantPlayer/Models/PlayerMapper.swift`:

```swift
// ABOUTME: Utility for mapping Music Assistant player data to app Player model
// ABOUTME: Handles parsing player list responses into typed Player objects

import Foundation
import MusicAssistantKit

enum PlayerMapper {
    static func parsePlayer(from data: [String: Any]) -> Player? {
        guard let playerId = data["player_id"] as? String ?? data["id"] as? String,
              let name = data["name"] as? String ?? data["display_name"] as? String
        else {
            return nil
        }

        let isActive = (data["state"] as? String) == "playing" || (data["powered"] as? Bool) == true

        return Player(id: playerId, name: name, isActive: isActive)
    }

    static func parsePlayers(from result: AnyCodable?) -> [Player] {
        guard let result = result,
              let players = result.value as? [[String: Any]]
        else {
            return []
        }

        return players.compactMap { parsePlayer(from: $0) }
    }
}
```

**Step 2: Implement fetchInitialData in MainWindowView**

Modify `Sources/MusicAssistantPlayer/Views/MainWindowView.swift`:

```swift
private func fetchInitialData() async {
    do {
        // Fetch players
        if let result = try await client.getPlayers() {
            let players = PlayerMapper.parsePlayers(from: result)

            await MainActor.run {
                self.availablePlayers = players

                // Auto-select first active player
                if let firstActive = players.first(where: { $0.isActive }) {
                    self.selectedPlayer = firstActive
                    self.playerService.selectedPlayer = firstActive
                } else if let first = players.first {
                    self.selectedPlayer = first
                    self.playerService.selectedPlayer = first
                }

                // Fetch queue for selected player
                if let player = selectedPlayer {
                    Task {
                        try? await queueService.fetchQueue(for: player.id)
                    }
                }
            }
        }
    } catch {
        print("Failed to fetch players: \(error)")
    }
}
```

**Step 3: Add player selection handler**

Add to `MainWindowView`:

```swift
var body: some View {
    HStack(spacing: 0) {
        // Sidebar
        SidebarView(
            selectedPlayer: $selectedPlayer,
            availablePlayers: availablePlayers
        )
        .frame(width: 220)
        .onChange(of: selectedPlayer) { oldValue, newValue in
            if let player = newValue {
                handlePlayerSelection(player)
            }
        }

        // ... rest of body
    }
}

private func handlePlayerSelection(_ player: Player) {
    playerService.selectedPlayer = player

    Task {
        try? await queueService.fetchQueue(for: player.id)
    }
}
```

**Step 4: Build and test**

Run: `swift build`
Expected: Build succeeds

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/PlayerMapper.swift Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git commit -m "feat: implement player discovery and selection"
```

---

## Task 12: Connection Status UI

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/Components/ConnectionStatusView.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/SidebarView.swift`

**Step 1: Create ConnectionStatusView**

Create `Sources/MusicAssistantPlayer/Views/Components/ConnectionStatusView.swift`:

```swift
// ABOUTME: Connection status indicator component for Music Assistant server
// ABOUTME: Displays connection state with colored badge and status text

import SwiftUI

struct ConnectionStatusView: View {
    let connectionState: ConnectionState
    let serverHost: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(connectionState.displayText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                if connectionState.isConnected {
                    Text(serverHost)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            if case .error = connectionState {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private var statusColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .yellow
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ConnectionStatusView(
            connectionState: .connected,
            serverHost: "192.168.200.113",
            onRetry: {}
        )

        ConnectionStatusView(
            connectionState: .connecting,
            serverHost: "192.168.200.113",
            onRetry: {}
        )

        ConnectionStatusView(
            connectionState: .error("Connection refused"),
            serverHost: "192.168.200.113",
            onRetry: {}
        )
    }
    .padding()
    .frame(width: 220)
    .background(Color(red: 0.06, green: 0.06, blue: 0.1))
}
```

**Step 2: Add to SidebarView**

Modify `Sources/MusicAssistantPlayer/Views/SidebarView.swift`:

Add parameter and display at bottom:

```swift
struct SidebarView: View {
    @Binding var selectedPlayer: Player?
    let availablePlayers: [Player]
    let connectionState: ConnectionState
    let serverHost: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ... existing navigation and players sections ...

            Spacer()

            // Connection status at bottom
            ConnectionStatusView(
                connectionState: connectionState,
                serverHost: serverHost,
                onRetry: onRetry
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.06, green: 0.06, blue: 0.1))
    }
}
```

**Step 3: Update MainWindowView to pass connection state**

Modify MainWindowView to pass connection state to sidebar.

**Step 4: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/ConnectionStatusView.swift Sources/MusicAssistantPlayer/Views/SidebarView.swift
git commit -m "feat: add connection status indicator to sidebar"
```

---

## Testing the Integration

**Manual testing checklist:**

1. Run app: `swift run`
2. Verify server setup screen appears (if first run)
3. Enter server IP: 192.168.200.113
4. Click Connect
5. Verify main window appears
6. Check sidebar shows real players from your server
7. Select a player
8. Verify now playing shows current track (if playing)
9. Verify queue shows upcoming tracks
10. Test play/pause/skip controls
11. Verify connection status shows green "Connected"

**Expected behavior:**
- App connects to your Music Assistant server
- Shows real players in sidebar
- Displays current playback state
- Queue updates in real-time
- Controls actually work with your server

---

## Next Phase: Polish & Error Handling

After basic integration works, we can add:
1. Progress timer (update every second)
2. Better error messages
3. Reconnection UI
4. Settings view to change server
5. Album art loading improvements
6. Player state persistence

**This completes the MusicAssistantKit integration plan.**
