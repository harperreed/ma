# Music Assistant Player MVP Implementation Plan

> **For Claude:** Use `${CLAUDE_PLUGIN_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Build a Roon-inspired macOS music player with beautiful now-playing display, queue management, and playback controls using MusicAssistantKit.

**Architecture:** MVVM with service layer. Services wrap MusicAssistantKit and expose Combine publishers. ViewModels consume services and expose simple @Published properties. SwiftUI views observe ViewModels. Read-only except playback controls.

**Tech Stack:** SwiftUI (macOS 14+), MusicAssistantKit, Combine, Swift Concurrency

---

## Task 1: Project Setup & Dependencies

**Files:**
- Create: `Package.swift`
- Create: `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift`
- Create: `.gitignore`

**Step 1: Create Swift Package with macOS app target**

```bash
mkdir -p Sources/MusicAssistantPlayer
mkdir -p Tests/MusicAssistantPlayerTests
mkdir -p Resources
```

**Step 2: Write Package.swift**

Create `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MusicAssistantPlayer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MusicAssistantPlayer",
            targets: ["MusicAssistantPlayer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/harperreed/MusicAssistantKit.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MusicAssistantPlayer",
            dependencies: ["MusicAssistantKit"],
            path: "Sources/MusicAssistantPlayer"
        ),
        .testTarget(
            name: "MusicAssistantPlayerTests",
            dependencies: ["MusicAssistantPlayer"],
            path: "Tests/MusicAssistantPlayerTests"
        )
    ]
)
```

**Step 3: Create basic app entry point**

Create `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift`:

```swift
// ABOUTME: Main entry point for Music Assistant Player macOS application
// ABOUTME: Initializes SwiftUI app lifecycle and main window

import SwiftUI

@main
struct MusicAssistantPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Music Assistant Player")
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
```

**Step 4: Create .gitignore**

Create `.gitignore`:

```
.DS_Store
/.build
/Packages
xcuserdata/
DerivedData/
.swiftpm/
*.xcodeproj
```

**Step 5: Verify build works**

Run: `swift build`
Expected: Build succeeds, downloads MusicAssistantKit

**Step 6: Commit**

```bash
git init
git add Package.swift Sources/ Tests/ .gitignore
git commit -m "feat: initial project setup with MusicAssistantKit dependency"
```

---

## Task 2: Core Models

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/Track.swift`
- Create: `Sources/MusicAssistantPlayer/Models/Player.swift`
- Create: `Sources/MusicAssistantPlayer/Models/PlaybackState.swift`
- Create: `Tests/MusicAssistantPlayerTests/Models/TrackTests.swift`

**Step 1: Write Track model test**

Create `Tests/MusicAssistantPlayerTests/Models/TrackTests.swift`:

```swift
// ABOUTME: Unit tests for Track model
// ABOUTME: Validates track metadata parsing and display formatting

import XCTest
@testable import MusicAssistantPlayer

final class TrackTests: XCTestCase {
    func testTrackInitialization() {
        let track = Track(
            id: "track_123",
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera",
            duration: 354.0,
            artworkURL: URL(string: "https://example.com/art.jpg")
        )

        XCTAssertEqual(track.id, "track_123")
        XCTAssertEqual(track.title, "Bohemian Rhapsody")
        XCTAssertEqual(track.artist, "Queen")
        XCTAssertEqual(track.album, "A Night at the Opera")
        XCTAssertEqual(track.duration, 354.0)
    }

    func testFormattedDuration() {
        let track = Track(
            id: "1",
            title: "Test",
            artist: "Artist",
            album: "Album",
            duration: 125.0,
            artworkURL: nil
        )

        XCTAssertEqual(track.formattedDuration, "2:05")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter TrackTests`
Expected: FAIL with "no such module 'MusicAssistantPlayer'" or Track not defined

**Step 3: Create Track model**

Create `Sources/MusicAssistantPlayer/Models/Track.swift`:

```swift
// ABOUTME: Track model representing a music track with metadata
// ABOUTME: Provides formatted display properties for UI consumption

import Foundation

struct Track: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artworkURL: URL?

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter TrackTests`
Expected: PASS (2 tests)

**Step 5: Write Player model test**

Add to `Tests/MusicAssistantPlayerTests/Models/TrackTests.swift` (or create PlayerTests.swift):

```swift
final class PlayerTests: XCTestCase {
    func testPlayerInitialization() {
        let player = Player(
            id: "player_kitchen",
            name: "Kitchen Speaker",
            isActive: true
        )

        XCTAssertEqual(player.id, "player_kitchen")
        XCTAssertEqual(player.name, "Kitchen Speaker")
        XCTAssertTrue(player.isActive)
    }
}
```

**Step 6: Run test to verify it fails**

Run: `swift test --filter PlayerTests`
Expected: FAIL with Player not defined

**Step 7: Create Player model**

Create `Sources/MusicAssistantPlayer/Models/Player.swift`:

```swift
// ABOUTME: Player model representing a Music Assistant playback device
// ABOUTME: Tracks device identity and active state for multi-room control

import Foundation

struct Player: Identifiable, Equatable {
    let id: String
    let name: String
    let isActive: Bool
}
```

**Step 8: Run test to verify it passes**

Run: `swift test --filter PlayerTests`
Expected: PASS

**Step 9: Create PlaybackState enum**

Create `Sources/MusicAssistantPlayer/Models/PlaybackState.swift`:

```swift
// ABOUTME: Playback state enumeration for player status
// ABOUTME: Represents playing, paused, stopped states with simple enum

import Foundation

enum PlaybackState: Equatable {
    case playing
    case paused
    case stopped
}
```

**Step 10: Commit models**

```bash
git add Sources/MusicAssistantPlayer/Models/ Tests/MusicAssistantPlayerTests/Models/
git commit -m "feat: add core models (Track, Player, PlaybackState)"
```

---

## Task 3: PlayerService Foundation

**Files:**
- Create: `Sources/MusicAssistantPlayer/Services/PlayerService.swift`
- Create: `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`

**Step 1: Write PlayerService initialization test**

Create `Tests/MusicAssistantPlayerTests/Services/PlayerServiceTests.swift`:

```swift
// ABOUTME: Unit tests for PlayerService
// ABOUTME: Validates player state management and MusicAssistantKit integration

import XCTest
import Combine
@testable import MusicAssistantPlayer

final class PlayerServiceTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testInitialState() {
        let service = PlayerService()

        XCTAssertNil(service.currentTrack)
        XCTAssertEqual(service.playbackState, .stopped)
        XCTAssertEqual(service.progress, 0.0)
        XCTAssertNil(service.selectedPlayer)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PlayerServiceTests`
Expected: FAIL with PlayerService not defined

**Step 3: Create PlayerService skeleton**

Create `Sources/MusicAssistantPlayer/Services/PlayerService.swift`:

```swift
// ABOUTME: Service layer for player state management and playback control
// ABOUTME: Wraps MusicAssistantKit client and exposes Combine publishers for UI

import Foundation
import Combine

@MainActor
class PlayerService: ObservableObject {
    @Published var currentTrack: Track?
    @Published var playbackState: PlaybackState = .stopped
    @Published var progress: TimeInterval = 0.0
    @Published var selectedPlayer: Player?

    init() {
        // Initialization will be expanded in next steps
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter PlayerServiceTests`
Expected: PASS

**Step 5: Commit PlayerService foundation**

```bash
git add Sources/MusicAssistantPlayer/Services/ Tests/MusicAssistantPlayerTests/Services/
git commit -m "feat: add PlayerService foundation with published properties"
```

---

## Task 4: QueueService Foundation

**Files:**
- Create: `Sources/MusicAssistantPlayer/Services/QueueService.swift`
- Create: `Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift`

**Step 1: Write QueueService initialization test**

Create `Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift`:

```swift
// ABOUTME: Unit tests for QueueService
// ABOUTME: Validates queue state management and track ordering

import XCTest
import Combine
@testable import MusicAssistantPlayer

final class QueueServiceTests: XCTestCase {
    func testInitialState() {
        let service = QueueService()

        XCTAssertTrue(service.upcomingTracks.isEmpty)
        XCTAssertNil(service.queueId)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter QueueServiceTests`
Expected: FAIL with QueueService not defined

**Step 3: Create QueueService skeleton**

Create `Sources/MusicAssistantPlayer/Services/QueueService.swift`:

```swift
// ABOUTME: Service layer for queue management and upcoming track display
// ABOUTME: Wraps MusicAssistantKit queue operations with read-only interface

import Foundation
import Combine

@MainActor
class QueueService: ObservableObject {
    @Published var upcomingTracks: [Track] = []
    @Published var queueId: String?

    init() {
        // Initialization will be expanded in next steps
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter QueueServiceTests`
Expected: PASS

**Step 5: Commit QueueService foundation**

```bash
git add Sources/MusicAssistantPlayer/Services/QueueService.swift Tests/MusicAssistantPlayerTests/Services/QueueServiceTests.swift
git commit -m "feat: add QueueService foundation"
```

---

## Task 5: NowPlayingViewModel

**Files:**
- Create: `Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift`
- Create: `Tests/MusicAssistantPlayerTests/ViewModels/NowPlayingViewModelTests.swift`

**Step 1: Write ViewModel initialization test**

Create `Tests/MusicAssistantPlayerTests/ViewModels/NowPlayingViewModelTests.swift`:

```swift
// ABOUTME: Unit tests for NowPlayingViewModel
// ABOUTME: Validates view state derivation from PlayerService

import XCTest
import Combine
@testable import MusicAssistantPlayer

final class NowPlayingViewModelTests: XCTestCase {
    var playerService: PlayerService!
    var cancellables: Set<AnyCancellable> = []

    @MainActor
    override func setUp() {
        super.setUp()
        playerService = PlayerService()
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    @MainActor
    func testInitialization() {
        let viewModel = NowPlayingViewModel(playerService: playerService)

        XCTAssertEqual(viewModel.trackTitle, "No Track Playing")
        XCTAssertEqual(viewModel.artistName, "")
        XCTAssertEqual(viewModel.albumName, "")
        XCTAssertFalse(viewModel.isPlaying)
    }

    @MainActor
    func testTrackDisplayWhenPlaying() {
        let track = Track(
            id: "1",
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            artworkURL: nil
        )

        playerService.currentTrack = track
        playerService.playbackState = .playing

        let viewModel = NowPlayingViewModel(playerService: playerService)

        XCTAssertEqual(viewModel.trackTitle, "Test Song")
        XCTAssertEqual(viewModel.artistName, "Test Artist")
        XCTAssertEqual(viewModel.albumName, "Test Album")
        XCTAssertTrue(viewModel.isPlaying)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter NowPlayingViewModelTests`
Expected: FAIL with NowPlayingViewModel not defined

**Step 3: Create NowPlayingViewModel**

Create `Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift`:

```swift
// ABOUTME: ViewModel for now playing display and playback controls
// ABOUTME: Transforms PlayerService state into UI-friendly computed properties

import Foundation
import Combine

@MainActor
class NowPlayingViewModel: ObservableObject {
    private let playerService: PlayerService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var trackTitle: String = "No Track Playing"
    @Published private(set) var artistName: String = ""
    @Published private(set) var albumName: String = ""
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var artworkURL: URL?
    @Published private(set) var progress: TimeInterval = 0.0
    @Published private(set) var duration: TimeInterval = 0.0

    init(playerService: PlayerService) {
        self.playerService = playerService
        setupBindings()
    }

    private func setupBindings() {
        playerService.$currentTrack
            .sink { [weak self] track in
                self?.trackTitle = track?.title ?? "No Track Playing"
                self?.artistName = track?.artist ?? ""
                self?.albumName = track?.album ?? ""
                self?.artworkURL = track?.artworkURL
                self?.duration = track?.duration ?? 0.0
            }
            .store(in: &cancellables)

        playerService.$playbackState
            .map { $0 == .playing }
            .assign(to: &$isPlaying)

        playerService.$progress
            .assign(to: &$progress)
    }

    func play() {
        // Will implement with MusicAssistantKit integration
    }

    func pause() {
        // Will implement with MusicAssistantKit integration
    }

    func skipNext() {
        // Will implement with MusicAssistantKit integration
    }

    func skipPrevious() {
        // Will implement with MusicAssistantKit integration
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter NowPlayingViewModelTests`
Expected: PASS (2 tests)

**Step 5: Commit NowPlayingViewModel**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/ Tests/MusicAssistantPlayerTests/ViewModels/
git commit -m "feat: add NowPlayingViewModel with service bindings"
```

---

## Task 6: QueueViewModel

**Files:**
- Create: `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`
- Create: `Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift`

**Step 1: Write QueueViewModel test**

Create `Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift`:

```swift
// ABOUTME: Unit tests for QueueViewModel
// ABOUTME: Validates queue display and track ordering

import XCTest
@testable import MusicAssistantPlayer

final class QueueViewModelTests: XCTestCase {
    var queueService: QueueService!

    @MainActor
    override func setUp() {
        super.setUp()
        queueService = QueueService()
    }

    @MainActor
    func testInitialization() {
        let viewModel = QueueViewModel(queueService: queueService)

        XCTAssertTrue(viewModel.tracks.isEmpty)
    }

    @MainActor
    func testTracksFromService() {
        let tracks = [
            Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
            Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 200, artworkURL: nil)
        ]

        queueService.upcomingTracks = tracks
        let viewModel = QueueViewModel(queueService: queueService)

        XCTAssertEqual(viewModel.tracks.count, 2)
        XCTAssertEqual(viewModel.tracks[0].title, "Track 1")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter QueueViewModelTests`
Expected: FAIL with QueueViewModel not defined

**Step 3: Create QueueViewModel**

Create `Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift`:

```swift
// ABOUTME: ViewModel for queue display and upcoming tracks
// ABOUTME: Exposes read-only queue state from QueueService

import Foundation
import Combine

@MainActor
class QueueViewModel: ObservableObject {
    private let queueService: QueueService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var tracks: [Track] = []

    init(queueService: QueueService) {
        self.queueService = queueService
        setupBindings()
    }

    private func setupBindings() {
        queueService.$upcomingTracks
            .assign(to: &$tracks)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter QueueViewModelTests`
Expected: PASS (2 tests)

**Step 5: Commit QueueViewModel**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/QueueViewModel.swift Tests/MusicAssistantPlayerTests/ViewModels/QueueViewModelTests.swift
git commit -m "feat: add QueueViewModel"
```

---

## Task 7: AlbumArtView Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/Components/AlbumArtView.swift`

**Step 1: Create AlbumArtView**

Create `Sources/MusicAssistantPlayer/Views/Components/AlbumArtView.swift`:

```swift
// ABOUTME: Album artwork display component with placeholder fallback
// ABOUTME: Handles async image loading and adaptive background blur effect

import SwiftUI

struct AlbumArtView: View {
    let artworkURL: URL?
    let size: CGFloat

    var body: some View {
        ZStack {
            if let url = artworkURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .gray.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.3))
                    .foregroundColor(.white.opacity(0.6))
            )
            .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 40) {
        AlbumArtView(artworkURL: nil, size: 300)
        AlbumArtView(
            artworkURL: URL(string: "https://picsum.photos/300"),
            size: 300
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit AlbumArtView**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/AlbumArtView.swift
git commit -m "feat: add AlbumArtView component with placeholder"
```

---

## Task 8: PlayerControlsView Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/Components/PlayerControlsView.swift`

**Step 1: Create PlayerControlsView**

Create `Sources/MusicAssistantPlayer/Views/Components/PlayerControlsView.swift`:

```swift
// ABOUTME: Playback control buttons (play/pause, skip, progress bar)
// ABOUTME: Provides transport controls and progress scrubbing interface

import SwiftUI

struct PlayerControlsView: View {
    let isPlaying: Bool
    let progress: TimeInterval
    let duration: TimeInterval
    let onPlay: () -> Void
    let onPause: () -> Void
    let onSkipPrevious: () -> Void
    let onSkipNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: progressWidth(geometry: geometry), height: 4)
                    }
                }
                .frame(height: 4)

                // Time labels
                HStack {
                    Text(formatTime(progress))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(formatTime(duration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Transport controls
            HStack(spacing: 32) {
                Button(action: onSkipPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: isPlaying ? onPause : onPlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: onSkipNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        guard duration > 0 else { return 0 }
        return geometry.size.width * CGFloat(progress / duration)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 40) {
        PlayerControlsView(
            isPlaying: false,
            progress: 45,
            duration: 180,
            onPlay: {},
            onPause: {},
            onSkipPrevious: {},
            onSkipNext: {}
        )

        PlayerControlsView(
            isPlaying: true,
            progress: 120,
            duration: 240,
            onPlay: {},
            onPause: {},
            onSkipPrevious: {},
            onSkipNext: {}
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit PlayerControlsView**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/PlayerControlsView.swift
git commit -m "feat: add PlayerControlsView with transport controls and progress"
```

---

## Task 9: NowPlayingView

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/NowPlayingView.swift`

**Step 1: Create NowPlayingView**

Create `Sources/MusicAssistantPlayer/Views/NowPlayingView.swift`:

```swift
// ABOUTME: Main now playing display with album art and metadata
// ABOUTME: Central hero section showing current track and playback controls

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var viewModel: NowPlayingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Album art
            AlbumArtView(
                artworkURL: viewModel.artworkURL,
                size: 320
            )

            // Track metadata
            VStack(spacing: 8) {
                Text(viewModel.trackTitle)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(viewModel.artistName)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))

                    if !viewModel.albumName.isEmpty {
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        Text(viewModel.albumName)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .lineLimit(1)
            }
            .padding(.horizontal)

            // Player controls
            PlayerControlsView(
                isPlaying: viewModel.isPlaying,
                progress: viewModel.progress,
                duration: viewModel.duration,
                onPlay: viewModel.play,
                onPause: viewModel.pause,
                onSkipPrevious: viewModel.skipPrevious,
                onSkipNext: viewModel.skipNext
            )
            .frame(maxWidth: 500)

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

    return NowPlayingView(
        viewModel: NowPlayingViewModel(playerService: playerService)
    )
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit NowPlayingView**

```bash
git add Sources/MusicAssistantPlayer/Views/NowPlayingView.swift
git commit -m "feat: add NowPlayingView with metadata and controls"
```

---

## Task 10: QueueView

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/QueueView.swift`

**Step 1: Create QueueView**

Create `Sources/MusicAssistantPlayer/Views/QueueView.swift`:

```swift
// ABOUTME: Queue display showing upcoming tracks in order
// ABOUTME: Scrollable list of tracks with metadata and artwork thumbnails

import SwiftUI

struct QueueView: View {
    @ObservedObject var viewModel: QueueViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Up Next")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding()

            Divider()
                .background(Color.white.opacity(0.1))

            // Queue list
            if viewModel.tracks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, track in
                            QueueTrackRow(track: track, index: index + 1)

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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            Text("Queue is empty")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct QueueTrackRow: View {
    let track: Track
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            // Index
            Text("\(index)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 30, alignment: .trailing)

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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
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

#Preview {
    let queueService = QueueService()
    queueService.upcomingTracks = [
        Track(id: "1", title: "Track One", artist: "Artist One", album: "Album", duration: 180, artworkURL: nil),
        Track(id: "2", title: "Track Two", artist: "Artist Two", album: "Album", duration: 200, artworkURL: nil),
        Track(id: "3", title: "Track Three", artist: "Artist Three", album: "Album", duration: 220, artworkURL: nil)
    ]

    return QueueView(viewModel: QueueViewModel(queueService: queueService))
        .frame(width: 350, height: 600)
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit QueueView**

```bash
git add Sources/MusicAssistantPlayer/Views/QueueView.swift
git commit -m "feat: add QueueView with track list display"
```

---

## Task 11: SidebarView

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/SidebarView.swift`

**Step 1: Create SidebarView**

Create `Sources/MusicAssistantPlayer/Views/SidebarView.swift`:

```swift
// ABOUTME: Navigation sidebar with section navigation and player selection
// ABOUTME: Shows available Music Assistant players and navigation options

import SwiftUI

struct SidebarView: View {
    @Binding var selectedPlayer: Player?
    let availablePlayers: [Player]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation
            VStack(alignment: .leading, spacing: 8) {
                Text("MUSIC ASSISTANT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal)
                    .padding(.top)

                SidebarItem(icon: "play.circle.fill", title: "Now Playing", isSelected: true)
                SidebarItem(icon: "music.note.list", title: "Library", isSelected: false)
                SidebarItem(icon: "magnifyingglass", title: "Search", isSelected: false)
            }
            .padding(.bottom, 24)

            Divider()
                .background(Color.white.opacity(0.1))

            // Players
            VStack(alignment: .leading, spacing: 8) {
                Text("PLAYERS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal)
                    .padding(.top)

                if availablePlayers.isEmpty {
                    Text("No players found")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                } else {
                    ForEach(availablePlayers) { player in
                        Button(action: {
                            selectedPlayer = player
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: player.isActive ? "circle.fill" : "circle")
                                    .font(.system(size: 8))
                                    .foregroundColor(player.isActive ? .green : .white.opacity(0.3))

                                Text(player.name)
                                    .font(.system(size: 13))
                                    .foregroundColor(selectedPlayer?.id == player.id ? .white : .white.opacity(0.7))

                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(
                                selectedPlayer?.id == player.id ?
                                    Color.white.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.06, green: 0.06, blue: 0.1))
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .padding(.horizontal, 8)
    }
}

#Preview {
    SidebarView(
        selectedPlayer: .constant(Player(id: "1", name: "Kitchen", isActive: true)),
        availablePlayers: [
            Player(id: "1", name: "Kitchen", isActive: true),
            Player(id: "2", name: "Bedroom", isActive: false),
            Player(id: "3", name: "Living Room", isActive: true)
        ]
    )
    .frame(width: 220, height: 600)
}
```

**Step 2: Build to verify compilation**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit SidebarView**

```bash
git add Sources/MusicAssistantPlayer/Views/SidebarView.swift
git commit -m "feat: add SidebarView with navigation and player list"
```

---

## Task 12: MainWindowView Assembly

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift`

**Step 1: Create MainWindowView**

Create `Sources/MusicAssistantPlayer/Views/MainWindowView.swift`:

```swift
// ABOUTME: Main window layout composing sidebar, now playing, and queue views
// ABOUTME: Three-column Roon-inspired layout with service injection

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
        .onAppear {
            loadMockData()
        }
    }

    // Temporary mock data for UI testing
    private func loadMockData() {
        // Mock players
        availablePlayers = [
            Player(id: "kitchen", name: "Kitchen Speaker", isActive: true),
            Player(id: "bedroom", name: "Bedroom", isActive: false)
        ]
        selectedPlayer = availablePlayers.first

        // Mock current track
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
        playerService.selectedPlayer = availablePlayers.first

        // Mock queue
        queueService.upcomingTracks = [
            Track(id: "2", title: "We Will Rock You", artist: "Queen", album: "News of the World", duration: 122.0, artworkURL: nil),
            Track(id: "3", title: "We Are the Champions", artist: "Queen", album: "News of the World", duration: 179.0, artworkURL: nil),
            Track(id: "4", title: "Another One Bites the Dust", artist: "Queen", album: "The Game", duration: 215.0, artworkURL: nil)
        ]
    }
}

#Preview {
    MainWindowView()
        .frame(width: 1200, height: 800)
}
```

**Step 2: Update app entry point**

Modify `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift`:

```swift
// ABOUTME: Main entry point for Music Assistant Player macOS application
// ABOUTME: Initializes SwiftUI app lifecycle and main window

import SwiftUI

@main
struct MusicAssistantPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
```

**Step 3: Build and run**

Run: `swift run`
Expected: App window opens with mock data displayed in three-column layout

**Step 4: Commit MainWindowView**

```bash
git add Sources/MusicAssistantPlayer/Views/MainWindowView.swift Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift
git commit -m "feat: add MainWindowView with three-column layout and mock data"
```

---

## Task 13: MusicAssistantKit Integration Planning

**Note:** The following tasks will integrate real MusicAssistantKit functionality. This requires:
- Your Music Assistant server URL
- Understanding of available players on your network
- Real-time WebSocket connection

**Files to create:**
- `Sources/MusicAssistantPlayer/Services/MusicAssistantClientWrapper.swift` - Wraps MusicAssistantKit client
- Configuration for server connection
- Error handling for connection failures

**Next steps after MVP UI is validated:**
1. Add app configuration (server URL input)
2. Integrate MusicAssistantKit client initialization
3. Wire up PlayerService to receive real events
4. Wire up QueueService to receive real events
5. Implement playback control commands
6. Add reconnection UI feedback
7. Handle edge cases (no players, connection failures)

---

## Testing the MVP

**Manual testing checklist:**

1. Run app: `swift run`
2. Verify three-column layout appears
3. Check mock track displays in center
4. Verify queue shows 3 upcoming tracks
5. Verify sidebar shows 2 players
6. Check all UI elements render correctly
7. Test window resizing behavior

**UI should match Roon aesthetic:**
- Dark theme with subtle gradients
- Clean typography and spacing
- Album art with shadow
- Smooth visual hierarchy

---

## Next Phase: Real Integration

After UI is validated, we'll:
1. Replace mock data with MusicAssistantKit WebSocket connection
2. Implement playback control commands
3. Add player discovery and selection
4. Handle real-time updates from server
5. Add error handling and reconnection UI

**This completes the MVP UI implementation plan.**
