# Code Review Critical Fixes Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Address critical code review issues including memory management, error handling, state consistency, and input validation to make the app production-ready.

**Architecture:** Add proper error propagation layer with user-facing messages, fix async task memory management with proper weak references, implement state binding instead of value passing, and add comprehensive input validation for network configuration.

**Tech Stack:** SwiftUI, Combine, async/await, XCTest

---

## Task 1: Fix Memory Management in PlayerService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/PlayerService.swift:44-65`
- Test: `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`

**Step 1: Write test for proper task cancellation**

Add test to verify event subscription is properly cancelled:

```swift
@MainActor
func testEventSubscriptionCancellation() async {
    let service = PlayerService(client: mockClient)

    // Start subscription
    service.subscribeToPlayerEvents()

    // Verify task is running
    XCTAssertNotNil(service.eventTask)

    // Cancel task
    service.eventTask?.cancel()

    // Wait a moment for cancellation to propagate
    try? await Task.sleep(nanoseconds: 100_000_000)

    // Verify task is cancelled
    XCTAssertTrue(service.eventTask?.isCancelled ?? false)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PlayerServiceTests/testEventSubscriptionCancellation`
Expected: Compilation error or test failure (eventTask not accessible, or cancellation not working)

**Step 3: Fix async task memory management**

In `PlayerService.swift`, update `subscribeToPlayerEvents()`:

```swift
func subscribeToPlayerEvents() {
    eventTask?.cancel() // Cancel any existing task

    eventTask = Task { [weak self] in
        guard let client = self?.client else { return }

        for await event in await client.events.playerUpdates.values {
            guard let self = self else { return }

            await MainActor.run { [weak self] in
                guard let self = self,
                      let selectedPlayer = self.selectedPlayer,
                      event.playerId == selectedPlayer.id else {
                    return
                }

                // Parse playback state
                if let state = EventParser.parsePlaybackState(from: event.data) {
                    self.playbackState = state
                }

                // Parse track info
                if let track = EventParser.parseTrack(from: event.data) {
                    self.currentTrack = track
                }

                // Parse progress
                if let progress = EventParser.parseProgress(from: event.data) {
                    self.progress = progress
                }
            }
        }
    }
}
```

**Step 4: Verify test passes**

Run: `swift test --filter PlayerServiceTests/testEventSubscriptionCancellation`
Expected: PASS

**Step 5: Run all tests**

Run: `swift test`
Expected: All 23+ tests passing

**Step 6: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/PlayerService.swift
git add Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift
git commit -m "fix: prevent memory leaks in PlayerService async event handling"
```

---

## Task 2: Add Error Domain and User-Facing Messages

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/PlayerError.swift`
- Test: `Tests/MusicAssistantPlayerTests/Models/PlayerErrorTests.swift`

**Step 1: Write test for error descriptions**

Create `Tests/MusicAssistantPlayerTests/Models/PlayerErrorTests.swift`:

```swift
import XCTest
@testable import MusicAssistantPlayer

final class PlayerErrorTests: XCTestCase {
    func testErrorDescriptions() {
        let networkError = PlayerError.networkError("Connection failed")
        XCTAssertEqual(networkError.userMessage, "Unable to connect to the server. Please check your connection.")

        let commandError = PlayerError.commandFailed("play", reason: "Player offline")
        XCTAssertEqual(commandError.userMessage, "Unable to play. The player may be offline.")

        let invalidConfig = PlayerError.invalidConfiguration("Invalid host")
        XCTAssertEqual(invalidConfig.userMessage, "Server configuration is invalid. Please check your settings.")
    }

    func testErrorEquality() {
        let error1 = PlayerError.networkError("test")
        let error2 = PlayerError.networkError("test")
        XCTAssertEqual(error1, error2)

        let error3 = PlayerError.commandFailed("play", reason: "test")
        XCTAssertNotEqual(error1, error3)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PlayerErrorTests`
Expected: FAIL with "No such module 'PlayerError'"

**Step 3: Create PlayerError type**

Create `Sources/MusicAssistantPlayer/Models/PlayerError.swift`:

```swift
// ABOUTME: Application-specific error types with user-facing messages
// ABOUTME: Wraps underlying errors and provides context for UI display

import Foundation

enum PlayerError: Error, Equatable {
    case networkError(String)
    case commandFailed(String, reason: String)
    case invalidConfiguration(String)
    case parseError(String)
    case playerNotFound(String)

    var userMessage: String {
        switch self {
        case .networkError:
            return "Unable to connect to the server. Please check your connection."
        case .commandFailed(let command, _):
            return "Unable to \(command). The player may be offline."
        case .invalidConfiguration:
            return "Server configuration is invalid. Please check your settings."
        case .parseError:
            return "Unable to process server response. The server may need updating."
        case .playerNotFound:
            return "Player not found. Please select a different player."
        }
    }

    var technicalDetails: String {
        switch self {
        case .networkError(let details),
             .invalidConfiguration(let details),
             .parseError(let details),
             .playerNotFound(let details):
            return details
        case .commandFailed(let command, let reason):
            return "Command '\(command)' failed: \(reason)"
        }
    }

    static func == (lhs: PlayerError, rhs: PlayerError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let a), .networkError(let b)),
             (.invalidConfiguration(let a), .invalidConfiguration(let b)),
             (.parseError(let a), .parseError(let b)),
             (.playerNotFound(let a), .playerNotFound(let b)):
            return a == b
        case (.commandFailed(let cmd1, let reason1), .commandFailed(let cmd2, let reason2)):
            return cmd1 == cmd2 && reason1 == reason2
        default:
            return false
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter PlayerErrorTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/PlayerError.swift
git add Tests/MusicAssistantPlayerTests/Models/PlayerErrorTests.swift
git commit -m "feat: add PlayerError domain with user-facing messages"
```

---

## Task 3: Add Error State to PlayerService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/PlayerService.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`

**Step 1: Write test for error state**

Add to `PlayerServiceTests.swift`:

```swift
@MainActor
func testErrorStatePublished() async {
    let service = PlayerService(client: nil)

    // Initially no error
    XCTAssertNil(service.lastError)

    // Trigger error by calling play without client
    await service.play()

    // Verify error is published
    XCTAssertNotNil(service.lastError)
    XCTAssertTrue(service.lastError is PlayerError)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PlayerServiceTests/testErrorStatePublished`
Expected: FAIL (lastError property doesn't exist)

**Step 3: Add error state to PlayerService**

In `PlayerService.swift`, add error state property:

```swift
@Published var lastError: PlayerError?

// Update play() to propagate errors
func play() async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        try await client.play(playerId: player.id)
        lastError = nil // Clear on success
    } catch let error as PlayerError {
        await MainActor.run {
            self.lastError = error
        }
    } catch {
        await MainActor.run {
            self.lastError = .commandFailed("play", reason: error.localizedDescription)
        }
    }
}

// Update pause() similarly
func pause() async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        try await client.pause(playerId: player.id)
        lastError = nil
    } catch let error as PlayerError {
        await MainActor.run {
            self.lastError = error
        }
    } catch {
        await MainActor.run {
            self.lastError = .commandFailed("pause", reason: error.localizedDescription)
        }
    }
}

// Update skipNext() similarly
func skipNext() async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        try await client.next(playerId: player.id)
        lastError = nil
    } catch let error as PlayerError {
        await MainActor.run {
            self.lastError = error
        }
    } catch {
        await MainActor.run {
            self.lastError = .commandFailed("skip next", reason: error.localizedDescription)
        }
    }
}

// Update skipPrevious() similarly
func skipPrevious() async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        try await client.previous(playerId: player.id)
        lastError = nil
    } catch let error as PlayerError {
        await MainActor.run {
            self.lastError = error
        }
    } catch {
        await MainActor.run {
            self.lastError = .commandFailed("skip previous", reason: error.localizedDescription)
        }
    }
}

// Update seek() similarly
func seek(to position: Double) async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        try await client.seek(playerId: player.id, position: position)
        lastError = nil
    } catch let error as PlayerError {
        await MainActor.run {
            self.lastError = error
        }
    } catch {
        await MainActor.run {
            self.lastError = .commandFailed("seek", reason: error.localizedDescription)
        }
    }
}

// Update setVolume() similarly
func setVolume(_ volume: Double) async {
    do {
        guard let client = client else {
            throw PlayerError.networkError("No client available")
        }
        guard let player = selectedPlayer else {
            throw PlayerError.playerNotFound("No player selected")
        }
        try await client.setVolume(playerId: player.id, volume: volume)
        lastError = nil
    } catch let error as PlayerError {
        await MainActor.run {
            self.lastError = error
        }
    } catch {
        await MainActor.run {
            self.lastError = .commandFailed("set volume", reason: error.localizedDescription)
        }
    }
}
```

**Step 4: Verify test passes**

Run: `swift test --filter PlayerServiceTests/testErrorStatePublished`
Expected: PASS

**Step 5: Run all tests**

Run: `swift test`
Expected: All tests passing

**Step 6: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/PlayerService.swift
git add Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift
git commit -m "feat: add error state publishing to PlayerService"
```

---

## Task 4: Add Error Banner to NowPlayingView

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/NowPlayingView.swift`
- Create: `Sources/MusicAssistantPlayer/Views/Components/ErrorBanner.swift`

**Step 1: No test needed for UI component**

This is a visual component that will be verified by running the app.

**Step 2: Create ErrorBanner component**

Create `Sources/MusicAssistantPlayer/Views/Components/ErrorBanner.swift`:

```swift
// ABOUTME: Error notification banner for user-facing error messages
// ABOUTME: Shows at top of view with dismiss action and auto-dismissal

import SwiftUI

struct ErrorBanner: View {
    let error: PlayerError
    let onDismiss: () -> Void

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.userMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(error.technicalDetails)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.red.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    dismiss()
                }
            }
        }
    }

    private func dismiss() {
        withAnimation {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}
```

**Step 3: Add error banner to NowPlayingView**

In `NowPlayingView.swift`, update body to show error banner:

```swift
var body: some View {
    GeometryReader { geometry in
        ZStack {
            // Content
            VStack(spacing: responsiveSpacing(for: geometry.size)) {
                // Error banner at top
                if let error = viewModel.lastError {
                    ErrorBanner(error: error) {
                        viewModel.clearError()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                Spacer()

                // ... existing album art and controls
```

**Step 4: Add clearError to NowPlayingViewModel**

In `NowPlayingViewModel.swift`:

```swift
var lastError: PlayerError? {
    playerService.lastError
}

func clearError() {
    playerService.lastError = nil
}
```

**Step 5: Verify visually**

Run: `swift run`
Expected: Error banner appears when operations fail, auto-dismisses after 5 seconds

**Step 6: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/ErrorBanner.swift
git add Sources/MusicAssistantPlayer/Views/NowPlayingView.swift
git add Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift
git commit -m "feat: add error banner UI for user feedback"
```

---

## Task 5: Fix State Consistency in MainWindowView

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift:43-63`
- Modify: `Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift`

**Step 1: No test for architectural change**

This is a structural fix verified through app behavior.

**Step 2: Update NowPlayingViewModel to use bindings**

In `NowPlayingViewModel.swift`, change from value-based to binding-based initialization:

```swift
@Published var selectedPlayer: Player?
@Published var availablePlayers: [Player] = []

private let playerService: PlayerService
var onPlayerSelectionChange: ((Player) -> Void)?

// Keep subscription
private var cancellables = Set<AnyCancellable>()

init(playerService: PlayerService) {
    self.playerService = playerService

    // Subscribe to player service state
    playerService.$playbackState
        .assign(to: &$playbackState)

    playerService.$currentTrack
        .sink { [weak self] track in
            self?.trackTitle = track?.title ?? "No Track Playing"
            self?.artistName = track?.artist ?? "Unknown Artist"
            self?.albumName = track?.album ?? ""
            self?.artworkURL = track?.artworkURL
        }
        .store(in: &cancellables)

    playerService.$progress
        .assign(to: &$progress)

    playerService.$volume
        .assign(to: &$volume)

    // Compute duration from current track
    playerService.$currentTrack
        .map { $0?.duration ?? 0 }
        .assign(to: &$duration)
}
```

**Step 3: Update MainWindowView to pass service reference**

In `MainWindowView.swift`, simplify NowPlayingView creation:

```swift
// Now Playing (center hero)
NowPlayingView(
    viewModel: nowPlayingViewModel,
    selectedPlayer: $selectedPlayer,
    availablePlayers: availablePlayers
)
.frame(maxWidth: .infinity)

// Add property for view model at top of struct
@StateObject private var nowPlayingViewModel: NowPlayingViewModel

// Update init to create view model
init(client: MusicAssistantClient, serverConfig: ServerConfig) {
    self.client = client
    self.serverConfig = serverConfig

    // Create services
    let playerSvc = PlayerService(client: client)
    let queueSvc = QueueService(client: client)

    // Initialize StateObjects
    _playerService = StateObject(wrappedValue: playerSvc)
    _queueService = StateObject(wrappedValue: queueSvc)
    _nowPlayingViewModel = StateObject(wrappedValue: NowPlayingViewModel(playerService: playerSvc))
}
```

**Step 4: Update NowPlayingView to accept bindings**

In `NowPlayingView.swift`, update to accept external bindings:

```swift
struct NowPlayingView: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    @Binding var selectedPlayer: Player?
    let availablePlayers: [Player]

    var body: some View {
        GeometryReader { geometry in
            // ... existing content

            .overlay(
                Group {
                    if geometry.size.width < 700 {
                        MiniPlayerMenuButton(
                            selectedPlayer: $selectedPlayer,
                            availablePlayers: availablePlayers,
                            onPlayerSelect: { player in
                                viewModel.handlePlayerSelection(player)
                            },
                            onShowQueue: {
                                print("Show queue requested")
                            }
                        )
                    }
                }
            )
        }
    }
}
```

**Step 5: Run all tests**

Run: `swift test`
Expected: All tests passing

**Step 6: Verify state synchronization**

Run: `swift run`
Expected: Player selection stays synchronized between sidebar and miniplayer menu

**Step 7: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git add Sources/MusicAssistantPlayer/Views/NowPlayingView.swift
git add Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift
git commit -m "fix: use bindings for state consistency in MainWindowView"
```

---

## Task 6: Add Input Validation for Server Configuration

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/ServerSetupView.swift:96-104`
- Create: `Sources/MusicAssistantPlayer/Utils/NetworkValidator.swift`
- Create: `Tests/MusicAssistantPlayerTests/Utils/NetworkValidatorTests.swift`

**Step 1: Write tests for network validation**

Create `Tests/MusicAssistantPlayerTests/Utils/NetworkValidatorTests.swift`:

```swift
import XCTest
@testable import MusicAssistantPlayer

final class NetworkValidatorTests: XCTestCase {
    func testValidIPv4Addresses() {
        XCTAssertTrue(NetworkValidator.isValidHost("192.168.1.1"))
        XCTAssertTrue(NetworkValidator.isValidHost("10.0.0.1"))
        XCTAssertTrue(NetworkValidator.isValidHost("127.0.0.1"))
    }

    func testInvalidIPv4Addresses() {
        XCTAssertFalse(NetworkValidator.isValidHost("256.1.1.1"))
        XCTAssertFalse(NetworkValidator.isValidHost("192.168.1"))
        XCTAssertFalse(NetworkValidator.isValidHost("192.168.1.1.1"))
        XCTAssertFalse(NetworkValidator.isValidHost(""))
    }

    func testValidHostnames() {
        XCTAssertTrue(NetworkValidator.isValidHost("localhost"))
        XCTAssertTrue(NetworkValidator.isValidHost("music.local"))
        XCTAssertTrue(NetworkValidator.isValidHost("my-server.example.com"))
    }

    func testInvalidHostnames() {
        XCTAssertFalse(NetworkValidator.isValidHost("-invalid"))
        XCTAssertFalse(NetworkValidator.isValidHost("invalid-.com"))
        XCTAssertFalse(NetworkValidator.isValidHost("inv alid.com"))
    }

    func testValidPorts() {
        XCTAssertTrue(NetworkValidator.isValidPort(80))
        XCTAssertTrue(NetworkValidator.isValidPort(8095))
        XCTAssertTrue(NetworkValidator.isValidPort(65535))
        XCTAssertTrue(NetworkValidator.isValidPort(1))
    }

    func testInvalidPorts() {
        XCTAssertFalse(NetworkValidator.isValidPort(0))
        XCTAssertFalse(NetworkValidator.isValidPort(-1))
        XCTAssertFalse(NetworkValidator.isValidPort(65536))
        XCTAssertFalse(NetworkValidator.isValidPort(100000))
    }

    func testValidateServerConfig() {
        let valid = NetworkValidator.validateServerConfig(host: "192.168.1.1", port: 8095)
        XCTAssertNil(valid) // nil means no error

        let invalidHost = NetworkValidator.validateServerConfig(host: "256.1.1.1", port: 8095)
        XCTAssertNotNil(invalidHost)
        XCTAssertTrue(invalidHost!.contains("host"))

        let invalidPort = NetworkValidator.validateServerConfig(host: "192.168.1.1", port: 99999)
        XCTAssertNotNil(invalidPort)
        XCTAssertTrue(invalidPort!.contains("port"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter NetworkValidatorTests`
Expected: FAIL (NetworkValidator doesn't exist)

**Step 3: Create NetworkValidator utility**

Create `Sources/MusicAssistantPlayer/Utils/NetworkValidator.swift`:

```swift
// ABOUTME: Network address validation for server configuration
// ABOUTME: Validates IP addresses, hostnames, and port numbers

import Foundation

struct NetworkValidator {
    /// Validate if string is a valid IPv4 address or hostname
    static func isValidHost(_ host: String) -> Bool {
        if host.isEmpty {
            return false
        }

        // Try IPv4 validation
        if isValidIPv4(host) {
            return true
        }

        // Try hostname validation
        return isValidHostname(host)
    }

    /// Validate if port is in valid range (1-65535)
    static func isValidPort(_ port: Int) -> Bool {
        return port >= 1 && port <= 65535
    }

    /// Validate server configuration, returns error message if invalid
    static func validateServerConfig(host: String, port: Int) -> String? {
        if !isValidHost(host) {
            return "Invalid host address. Please enter a valid IP address or hostname."
        }

        if !isValidPort(port) {
            return "Invalid port number. Must be between 1 and 65535."
        }

        return nil // Valid
    }

    // MARK: - Private Helpers

    private static func isValidIPv4(_ address: String) -> Bool {
        let components = address.split(separator: ".")

        guard components.count == 4 else {
            return false
        }

        for component in components {
            guard let value = Int(component),
                  value >= 0,
                  value <= 255 else {
                return false
            }
        }

        return true
    }

    private static func isValidHostname(_ hostname: String) -> Bool {
        // Basic hostname validation
        // - Must start and end with alphanumeric
        // - Can contain hyphens and dots
        // - Labels must not start or end with hyphen

        let pattern = "^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"

        return hostname.range(of: pattern, options: .regularExpression) != nil
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter NetworkValidatorTests`
Expected: All tests passing

**Step 5: Update ServerSetupView to use validation**

In `ServerSetupView.swift`, update `handleConnect()`:

```swift
private func handleConnect() {
    guard let portInt = Int(port) else {
        connectionStatus = "Invalid port number"
        connectionSuccess = false
        return
    }

    // Validate configuration
    if let error = NetworkValidator.validateServerConfig(host: host, port: portInt) {
        connectionStatus = error
        connectionSuccess = false
        return
    }

    // ... existing connection logic
}
```

**Step 6: Run all tests**

Run: `swift test`
Expected: All tests passing

**Step 7: Verify validation in UI**

Run: `swift run`
Expected:
- Enter invalid host (e.g., "256.1.1.1") - see error message
- Enter invalid port (e.g., "99999") - see error message
- Enter valid config - connection proceeds

**Step 8: Commit**

```bash
git add Sources/MusicAssistantPlayer/Utils/NetworkValidator.swift
git add Sources/MusicAssistantPlayer/Views/ServerSetupView.swift
git add Tests/MusicAssistantPlayerTests/Utils/NetworkValidatorTests.swift
git commit -m "feat: add comprehensive input validation for server configuration"
```

---

## Task 7: Fix Task Cancellation Race Condition

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift:171-180`

**Step 1: No test needed**

This is a defensive fix for async task management.

**Step 2: Add task cancellation before creating new task**

In `MainWindowView.swift`, update `subscribeToPlayerUpdates()`:

```swift
private func subscribeToPlayerUpdates() {
    // Cancel existing subscription to prevent multiple concurrent listeners
    playerUpdateTask?.cancel()

    playerUpdateTask = Task { @MainActor in
        // Subscribe to player update events
        for await _ in await client.events.playerUpdates.values {
            // When any player updates, refresh the player list
            // This catches sync/unsync changes, power state changes, etc.
            await refreshPlayerList()
        }
    }
}
```

**Step 3: Run all tests**

Run: `swift test`
Expected: All tests passing

**Step 4: Verify no double subscriptions**

Run: `swift run`
Expected: Player list updates correctly without duplicated events

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git commit -m "fix: prevent race condition in player update subscriptions"
```

---

## Success Criteria

✅ Memory leaks fixed in PlayerService async tasks
✅ Proper error domain with user-facing messages
✅ Error state published and displayed in UI
✅ State consistency fixed with proper bindings
✅ Comprehensive input validation for server config
✅ Task cancellation race condition fixed
✅ All existing tests passing (23+)
✅ New tests added for error handling and validation
✅ Visual verification of error banner and validation

## Notes

**After completion:**
- Consider implementing caching for album art (medium priority)
- Add comprehensive error path testing (medium priority)
- Fix BlurredArtworkBackground layout issues (tracked in TODO)
- Extract magic numbers to constants (low priority)
