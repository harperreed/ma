# Queue Management Phase 1 Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Add queue management controls (clear, shuffle, repeat) and rich context display (now playing indicator, queue stats, loading states) to the queue view.

**Architecture:** Extend QueueService with command methods backed by MusicAssistantKit APIs. Add computed properties for queue stats. Update QueueView with toolbar controls and enhanced track display with current track indicator.

**Tech Stack:** Swift, SwiftUI, MusicAssistantKit, Combine

**Phase 1 Limitations:** This phase implements operations available in current MusicAssistantKit. Jump-to-track, remove, and reorder require additional APIs and will be Phase 2.

---

## Task 1: Add QueueError enum and result types

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/QueueError.swift`
- Test: `Tests/MusicAssistantPlayerTests/Models/QueueErrorTests.swift`

**Step 1: Write the failing test**

Create `Tests/MusicAssistantPlayerTests/Models/QueueErrorTests.swift`:

```swift
// ABOUTME: Tests for queue operation error types and user-facing messages
// ABOUTME: Verifies error descriptions are user-friendly and actionable

import XCTest
@testable import MusicAssistantPlayer

final class QueueErrorTests: XCTestCase {
    func testNetworkFailureErrorDescription() {
        let error = QueueError.networkFailure
        XCTAssertEqual(error.userMessage, "Network connection failed. Check your connection and try again.")
    }

    func testQueueEmptyErrorDescription() {
        let error = QueueError.queueEmpty
        XCTAssertEqual(error.userMessage, "Queue is empty.")
    }

    func testUnknownErrorDescription() {
        let error = QueueError.unknown("Something went wrong")
        XCTAssertEqual(error.userMessage, "An error occurred: Something went wrong")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter QueueErrorTests`
Expected: FAIL - QueueError type does not exist

**Step 3: Write minimal implementation**

Create `Sources/MusicAssistantPlayer/Models/QueueError.swift`:

```swift
// ABOUTME: Error types for queue operations with user-friendly messages
// ABOUTME: Translates technical errors into actionable UI feedback

import Foundation

enum QueueError: LocalizedError {
    case networkFailure
    case queueEmpty
    case unknown(String)

    var userMessage: String {
        switch self {
        case .networkFailure:
            return "Network connection failed. Check your connection and try again."
        case .queueEmpty:
            return "Queue is empty."
        case .unknown(let message):
            return "An error occurred: \(message)"
        }
    }

    var errorDescription: String? {
        userMessage
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter QueueErrorTests`
Expected: PASS - 3 tests

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/QueueError.swift Tests/MusicAssistantPlayerTests/Models/QueueErrorTests.swift
git commit -m "feat: add QueueError enum with user-friendly messages

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: Add queue management operations to QueueService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/QueueService.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift`

**Step 1: Write the failing tests**

Add to `Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift`:

```swift
func testClearQueue() async throws {
    let mockClient = MockMusicAssistantClient()
    let service = QueueService(client: mockClient)

    service.queueId = "test-queue"

    try await service.clearQueue()

    XCTAssertEqual(mockClient.lastCommand, "player_queues/clear")
    XCTAssertEqual(mockClient.lastArgs?["queue_id"] as? String, "test-queue")
}

func testClearQueueWithoutQueueId() async {
    let mockClient = MockMusicAssistantClient()
    let service = QueueService(client: mockClient)

    do {
        try await service.clearQueue()
        XCTFail("Should throw error when queueId is nil")
    } catch let error as QueueError {
        XCTAssertEqual(error, .queueEmpty)
    } catch {
        XCTFail("Wrong error type: \(error)")
    }
}

func testShuffle() async throws {
    let mockClient = MockMusicAssistantClient()
    let service = QueueService(client: mockClient)

    service.queueId = "test-queue"

    try await service.shuffle(enabled: true)

    XCTAssertEqual(mockClient.lastCommand, "player_queues/shuffle")
    XCTAssertEqual(mockClient.lastArgs?["queue_id"] as? String, "test-queue")
    XCTAssertEqual(mockClient.lastArgs?["shuffle"] as? Bool, true)
}

func testSetRepeatMode() async throws {
    let mockClient = MockMusicAssistantClient()
    let service = QueueService(client: mockClient)

    service.queueId = "test-queue"

    try await service.setRepeat(mode: "all")

    XCTAssertEqual(mockClient.lastCommand, "player_queues/repeat")
    XCTAssertEqual(mockClient.lastArgs?["queue_id"] as? String, "test-queue")
    XCTAssertEqual(mockClient.lastArgs?["repeat_mode"] as? String, "all")
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter QueueServiceTests`
Expected: FAIL - clearQueue, shuffle, setRepeat methods don't exist

**Step 3: Write minimal implementation**

Add to `Sources/MusicAssistantPlayer/Services/QueueService.swift`:

```swift
// Add after fetchQueue method

func clearQueue() async throws {
    guard let client = client else {
        throw QueueError.networkFailure
    }
    guard let queueId = queueId else {
        throw QueueError.queueEmpty
    }

    do {
        try await client.clearQueue(queueId: queueId)
        await MainActor.run {
            self.upcomingTracks = []
        }
    } catch {
        throw QueueError.networkFailure
    }
}

func shuffle(enabled: Bool) async throws {
    guard let client = client else {
        throw QueueError.networkFailure
    }
    guard queueId != nil else {
        throw QueueError.queueEmpty
    }

    do {
        try await client.shuffle(queueId: queueId!, enabled: enabled)
    } catch {
        throw QueueError.networkFailure
    }
}

func setRepeat(mode: String) async throws {
    guard let client = client else {
        throw QueueError.networkFailure
    }
    guard queueId != nil else {
        throw QueueError.queueEmpty
    }

    do {
        try await client.setRepeat(queueId: queueId!, mode: mode)
    } catch {
        throw QueueError.networkFailure
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter QueueServiceTests`
Expected: PASS - all tests including new ones

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/QueueService.swift Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift
git commit -m "feat: add queue management operations (clear, shuffle, repeat)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3: Add computed properties for queue statistics

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/QueueService.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift`

**Step 1: Write the failing tests**

Add to `Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift`:

```swift
func testTotalDuration() {
    let service = QueueService()
    service.upcomingTracks = [
        Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
        Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 200, artworkURL: nil),
        Track(id: "3", title: "Track 3", artist: "Artist", album: "Album", duration: 120, artworkURL: nil)
    ]

    XCTAssertEqual(service.totalDuration, 500)
}

func testFormattedTotalDuration() {
    let service = QueueService()
    service.upcomingTracks = [
        Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
        Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 3600, artworkURL: nil)
    ]

    XCTAssertEqual(service.formattedTotalDuration, "1:03:00")
}

func testTrackCount() {
    let service = QueueService()
    service.upcomingTracks = [
        Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
        Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 200, artworkURL: nil)
    ]

    XCTAssertEqual(service.trackCount, 2)
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter QueueServiceTests`
Expected: FAIL - properties don't exist

**Step 3: Write minimal implementation**

Add to `Sources/MusicAssistantPlayer/Services/QueueService.swift`:

```swift
// Add as computed properties after upcomingTracks

var totalDuration: Int {
    upcomingTracks.reduce(0) { $0 + $1.duration }
}

var formattedTotalDuration: String {
    let total = totalDuration
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%d:%02d", minutes, seconds)
    }
}

var trackCount: Int {
    upcomingTracks.count
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter QueueServiceTests`
Expected: PASS - all tests

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/QueueService.swift Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift
git commit -m "feat: add queue statistics computed properties

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: Expose queue operations in QueueViewModel

**Files:**
- Modify: `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`
- Modify: `Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift`

**Step 1: Write the failing tests**

Add to `Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift`:

```swift
func testClearQueue() async throws {
    let mockClient = MockMusicAssistantClient()
    let service = QueueService(client: mockClient)
    service.queueId = "test-queue"
    let viewModel = QueueViewModel(queueService: service)

    try await viewModel.clearQueue()

    XCTAssertEqual(mockClient.lastCommand, "player_queues/clear")
}

func testClearQueueErrorHandling() async {
    let service = QueueService(client: nil)
    let viewModel = QueueViewModel(queueService: service)

    do {
        try await viewModel.clearQueue()
        XCTFail("Should throw error")
    } catch {
        // Expected
    }
}

func testShuffle() async throws {
    let mockClient = MockMusicAssistantClient()
    let service = QueueService(client: mockClient)
    service.queueId = "test-queue"
    let viewModel = QueueViewModel(queueService: service)

    try await viewModel.shuffle(enabled: true)

    XCTAssertEqual(mockClient.lastArgs?["shuffle"] as? Bool, true)
}

func testSetRepeat() async throws {
    let mockClient = MockMusicAssistantClient()
    let service = QueueService(client: mockClient)
    service.queueId = "test-queue"
    let viewModel = QueueViewModel(queueService: service)

    try await viewModel.setRepeat(mode: "one")

    XCTAssertEqual(mockClient.lastArgs?["repeat_mode"] as? String, "one")
}

func testQueueStatistics() {
    let service = QueueService()
    service.upcomingTracks = [
        Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
        Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 200, artworkURL: nil)
    ]
    let viewModel = QueueViewModel(queueService: service)

    XCTAssertEqual(viewModel.trackCount, 2)
    XCTAssertEqual(viewModel.totalDuration, "6:20")
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter QueueViewModelTests`
Expected: FAIL - methods don't exist

**Step 3: Write minimal implementation**

Replace contents of `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`:

```swift
// ABOUTME: ViewModel for queue display and management operations
// ABOUTME: Exposes queue state and wraps service operations with error handling

import Foundation
import Combine

@MainActor
class QueueViewModel: ObservableObject {
    private let queueService: QueueService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var tracks: [Track] = []
    @Published var errorMessage: String?

    init(queueService: QueueService) {
        self.queueService = queueService
        setupBindings()
    }

    private func setupBindings() {
        queueService.$upcomingTracks
            .assign(to: &$tracks)
    }

    // MARK: - Queue Operations

    func clearQueue() async throws {
        do {
            try await queueService.clearQueue()
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.userMessage
            throw error
        }
    }

    func shuffle(enabled: Bool) async throws {
        do {
            try await queueService.shuffle(enabled: enabled)
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.userMessage
            throw error
        }
    }

    func setRepeat(mode: String) async throws {
        do {
            try await queueService.setRepeat(mode: mode)
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.userMessage
            throw error
        }
    }

    // MARK: - Statistics

    var trackCount: Int {
        queueService.trackCount
    }

    var totalDuration: String {
        queueService.formattedTotalDuration
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter QueueViewModelTests`
Expected: PASS - all tests

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift
git commit -m "feat: expose queue operations in QueueViewModel

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 5: Add current track indicator to QueueView

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/QueueView.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift` (pass currentTrack)

**Step 1: Update QueueView to accept current track**

Modify `Sources/MusicAssistantPlayer/Views/QueueView.swift`:

```swift
// Update QueueView struct signature
struct QueueView: View {
    @ObservedObject var viewModel: QueueViewModel
    let currentTrack: Track?  // ADD THIS

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ... existing code ...

            // Update the ForEach to pass currentTrack to row
            if viewModel.tracks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, track in
                            QueueTrackRow(
                                track: track,
                                index: index + 1,
                                isCurrentTrack: track.id == currentTrack?.id  // ADD THIS
                            )

                            if index < viewModel.tracks.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    }

    // ... existing emptyState ...
}

// Update QueueTrackRow
struct QueueTrackRow: View {
    let track: Track
    let index: Int
    let isCurrentTrack: Bool  // ADD THIS

    var body: some View {
        HStack(spacing: 12) {
            // Index or now playing indicator
            if isCurrentTrack {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .frame(width: 30, alignment: .trailing)
            } else {
                Text("\(index)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 30, alignment: .trailing)
            }

            // ... rest of existing HStack content (thumbnail, track info) ...
            // Thumbnail
            if let artworkURL = track.artworkURL {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder
                }
                .frame(width: 40, height: 40)
                .cornerRadius(4)
            } else {
                thumbnailPlaceholder
            }

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 14, weight: isCurrentTrack ? .semibold : .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if isCurrentTrack {
                        Text("Now Playing")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        Text(track.artist)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    Text(track.formattedDuration)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isCurrentTrack ? Color.green.opacity(0.1) : Color.clear)
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.1))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            )
    }
}

// Update Preview
#Preview {
    let queueService = QueueService()
    queueService.upcomingTracks = [
        Track(id: "1", title: "Track One", artist: "Artist One", album: "Album", duration: 180, artworkURL: nil),
        Track(id: "2", title: "Track Two", artist: "Artist Two", album: "Album", duration: 200, artworkURL: nil),
        Track(id: "3", title: "Track Three", artist: "Artist Three", album: "Album", duration: 220, artworkURL: nil)
    ]

    return QueueView(
        viewModel: QueueViewModel(queueService: queueService),
        currentTrack: Track(id: "1", title: "Track One", artist: "Artist One", album: "Album", duration: 180, artworkURL: nil)
    )
        .frame(width: 350, height: 600)
}
```

**Step 2: Update MainWindowView to pass currentTrack**

Find where QueueView is instantiated in `Sources/MusicAssistantPlayer/Views/MainWindowView.swift` and update:

```swift
// Find the QueueView instantiation and update it:
QueueView(
    viewModel: queueViewModel,
    currentTrack: nowPlayingViewModel.currentTrack  // ADD THIS
)
```

**Step 3: Build and run to verify visually**

Run: `swift build && swift run`
Expected: Build succeeds, app runs, queue shows green "play" icon for current track

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/QueueView.swift Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git commit -m "feat: add current track indicator to queue view

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 6: Add queue statistics header to QueueView

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/QueueView.swift`

**Step 1: Update QueueView header section**

Modify the header in `Sources/MusicAssistantPlayer/Views/QueueView.swift`:

```swift
// Replace the existing header section with:
VStack(alignment: .leading, spacing: 0) {
    // Header with stats
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text("Up Next")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            if !viewModel.tracks.isEmpty {
                Text("\(viewModel.trackCount) tracks • \(viewModel.totalDuration)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        Spacer()
    }
    .padding()

    Divider()
        .background(Color.white.opacity(0.1))

    // ... rest of body (ScrollView, etc) ...
}
```

**Step 2: Build and run to verify visually**

Run: `swift build && swift run`
Expected: Queue header shows "12 tracks • 47:23" below "Up Next"

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/QueueView.swift
git commit -m "feat: add queue statistics to header (track count and duration)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 7: Add queue management toolbar to QueueView

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/QueueView.swift`

**Step 1: Add toolbar with queue management buttons**

Add toolbar to `Sources/MusicAssistantPlayer/Views/QueueView.swift`:

```swift
// Add @State for showing alerts
@State private var showClearConfirmation = false
@State private var isShuffleEnabled = false
@State private var repeatMode = "off" // "off", "all", "one"

// Add .toolbar modifier to the VStack (after .background):
.toolbar {
    ToolbarItemGroup {
        // Shuffle button
        Button(action: {
            isShuffleEnabled.toggle()
            Task {
                try? await viewModel.shuffle(enabled: isShuffleEnabled)
            }
        }) {
            Image(systemName: isShuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                .foregroundColor(isShuffleEnabled ? .green : .white.opacity(0.7))
        }
        .help("Shuffle")

        // Repeat button
        Button(action: {
            cycleRepeatMode()
        }) {
            Image(systemName: repeatModeIcon)
                .foregroundColor(repeatMode != "off" ? .green : .white.opacity(0.7))
        }
        .help("Repeat: \(repeatMode)")

        // Clear queue button
        Button(action: {
            showClearConfirmation = true
        }) {
            Image(systemName: "trash")
                .foregroundColor(.white.opacity(0.7))
        }
        .help("Clear Queue")
        .disabled(viewModel.tracks.isEmpty)
    }
}
.alert("Clear Queue", isPresented: $showClearConfirmation) {
    Button("Cancel", role: .cancel) {}
    Button("Clear", role: .destructive) {
        Task {
            try? await viewModel.clearQueue()
        }
    }
} message: {
    Text("Are you sure you want to clear all tracks from the queue?")
}

// Add helper computed property and method after body:
private var repeatModeIcon: String {
    switch repeatMode {
    case "all":
        return "repeat.circle.fill"
    case "one":
        return "repeat.1.circle.fill"
    default:
        return "repeat"
    }
}

private func cycleRepeatMode() {
    switch repeatMode {
    case "off":
        repeatMode = "all"
    case "all":
        repeatMode = "one"
    case "one":
        repeatMode = "off"
    default:
        repeatMode = "off"
    }

    Task {
        try? await viewModel.setRepeat(mode: repeatMode)
    }
}
```

**Step 2: Build and run to verify**

Run: `swift build && swift run`
Expected: Toolbar appears with shuffle, repeat, and clear buttons. Clicking clear shows confirmation dialog.

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/QueueView.swift
git commit -m "feat: add queue management toolbar (shuffle, repeat, clear)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 8: Add error banner to QueueView

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/QueueView.swift`

**Step 1: Add error banner to QueueView**

Add after the header, before the ScrollView in `Sources/MusicAssistantPlayer/Views/QueueView.swift`:

```swift
// Add after Divider, before the if viewModel.tracks.isEmpty check:

if let errorMessage = viewModel.errorMessage {
    HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
        Text(errorMessage)
            .font(.system(size: 13))
            .foregroundColor(.white)
        Spacer()
        Button(action: {
            viewModel.errorMessage = nil
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

**Step 2: Make errorMessage settable in ViewModel**

Update `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`:

```swift
// Change from:
@Published var errorMessage: String?

// To:
@Published var errorMessage: String? = nil
```

**Step 3: Build and run to verify**

Run: `swift build && swift run`
Expected: Error banner appears when operations fail (test by disconnecting network)

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/QueueView.swift Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift
git commit -m "feat: add error banner to queue view

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 9: Add loading states to queue operations

**Files:**
- Modify: `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/QueueView.swift`

**Step 1: Add loading state to ViewModel**

Add to `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`:

```swift
@Published var isLoading = false

// Update each operation to set loading state:
func clearQueue() async throws {
    isLoading = true
    defer { isLoading = false }

    do {
        try await queueService.clearQueue()
        errorMessage = nil
    } catch let error as QueueError {
        errorMessage = error.userMessage
        throw error
    }
}

func shuffle(enabled: Bool) async throws {
    isLoading = true
    defer { isLoading = false }

    do {
        try await queueService.shuffle(enabled: enabled)
        errorMessage = nil
    } catch let error as QueueError {
        errorMessage = error.userMessage
        throw error
    }
}

func setRepeat(mode: String) async throws {
    isLoading = true
    defer { isLoading = false }

    do {
        try await queueService.setRepeat(mode: mode)
        errorMessage = nil
    } catch let error as QueueError {
        errorMessage = error.userMessage
        throw error
    }
}
```

**Step 2: Show loading indicator in View**

Add to `Sources/MusicAssistantPlayer/Views/QueueView.swift`:

```swift
// Add overlay after .alert modifier:
.overlay(alignment: .center) {
    if viewModel.isLoading {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.white)
        }
    }
}
```

**Step 3: Build and run to verify**

Run: `swift build && swift run`
Expected: Loading spinner appears during operations

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift Sources/MusicAssistantPlayer/Views/QueueView.swift
git commit -m "feat: add loading states to queue operations

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 10: Run full test suite and verify

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests pass with pristine output

**Step 2: Build and run app**

Run: `swift build && swift run`
Expected: Clean build, app runs successfully

**Step 3: Manual testing checklist**

Test each feature:
- [ ] Queue displays with current track indicator (green play icon)
- [ ] Header shows correct track count and duration
- [ ] Shuffle button toggles and calls API
- [ ] Repeat button cycles through off/all/one
- [ ] Clear button shows confirmation and empties queue
- [ ] Error banner appears on failures and is dismissible
- [ ] Loading spinner shows during operations
- [ ] Empty state shows when queue is empty

**Step 4: Final commit if any fixes needed**

If bugs found, fix them and commit:

```bash
git add <files>
git commit -m "fix: <description>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Completion

Queue Phase 1 is complete! The queue now has:
- ✅ Queue management controls (clear, shuffle, repeat)
- ✅ Current track indicator with visual distinction
- ✅ Queue statistics (count and duration)
- ✅ Error handling with user-friendly messages
- ✅ Loading states for all operations
- ✅ Comprehensive test coverage

**Phase 2 Prerequisites:**
To implement jump-to-track, remove, and reorder operations, add these methods to MusicAssistantKit (see spec at top of this document).
