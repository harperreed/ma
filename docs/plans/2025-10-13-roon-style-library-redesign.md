# Roon-Style Library Browser Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Transform the app from now-playing-centric to library-browsing-centric with persistent mini player bar, matching Roon's UX paradigm.

**Architecture:** Clean slate redesign with library browsing as main view, mini player bar at bottom, expanded now-playing accessible via click. Library sidebar with collapsible categories (Library, Providers), Spotify-style hover interactions for play/queue actions, global and contextual search.

**Tech Stack:** SwiftUI, MusicAssistantKit, existing service layer patterns, TDD with XCTest

---

## Phase 1: Foundation - Models & Library Service

### Task 1: Create Artist Model

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/Artist.swift`
- Create: `Tests/MusicAssistantPlayerTests/Models/ArtistTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/MusicAssistantPlayerTests/Models/ArtistTests.swift
import XCTest
@testable import MusicAssistantPlayer

final class ArtistTests: XCTestCase {
    func testArtistInitialization() {
        let artist = Artist(
            id: "artist-123",
            name: "Test Artist",
            artworkURL: URL(string: "https://example.com/art.jpg"),
            albumCount: 5
        )

        XCTAssertEqual(artist.id, "artist-123")
        XCTAssertEqual(artist.name, "Test Artist")
        XCTAssertEqual(artist.artworkURL?.absoluteString, "https://example.com/art.jpg")
        XCTAssertEqual(artist.albumCount, 5)
    }

    func testArtistWithoutArtwork() {
        let artist = Artist(
            id: "artist-456",
            name: "Another Artist",
            artworkURL: nil,
            albumCount: 0
        )

        XCTAssertNil(artist.artworkURL)
        XCTAssertEqual(artist.albumCount, 0)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ArtistTests`
Expected: FAIL with "Cannot find 'Artist' in scope"

**Step 3: Write minimal implementation**

```swift
// Sources/MusicAssistantPlayer/Models/Artist.swift
// ABOUTME: Artist model representing a music artist from Music Assistant library
// ABOUTME: Contains artist metadata including name, artwork, and album count

import Foundation

struct Artist: Identifiable, Equatable {
    let id: String
    let name: String
    let artworkURL: URL?
    let albumCount: Int
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ArtistTests`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/Artist.swift Tests/MusicAssistantPlayerTests/Models/ArtistTests.swift
git commit -m "feat: add Artist model

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: Create Album Model

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/Album.swift`
- Create: `Tests/MusicAssistantPlayerTests/Models/AlbumTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/MusicAssistantPlayerTests/Models/AlbumTests.swift
import XCTest
@testable import MusicAssistantPlayer

final class AlbumTests: XCTestCase {
    func testAlbumInitialization() {
        let album = Album(
            id: "album-123",
            title: "Test Album",
            artist: "Test Artist",
            artworkURL: URL(string: "https://example.com/album.jpg"),
            trackCount: 12,
            year: 2024,
            duration: 3600.0
        )

        XCTAssertEqual(album.id, "album-123")
        XCTAssertEqual(album.title, "Test Album")
        XCTAssertEqual(album.artist, "Test Artist")
        XCTAssertEqual(album.trackCount, 12)
        XCTAssertEqual(album.year, 2024)
        XCTAssertEqual(album.duration, 3600.0)
    }

    func testAlbumWithoutOptionalFields() {
        let album = Album(
            id: "album-456",
            title: "Minimal Album",
            artist: "Unknown",
            artworkURL: nil,
            trackCount: 0,
            year: nil,
            duration: 0.0
        )

        XCTAssertNil(album.artworkURL)
        XCTAssertNil(album.year)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AlbumTests`
Expected: FAIL with "Cannot find 'Album' in scope"

**Step 3: Write minimal implementation**

```swift
// Sources/MusicAssistantPlayer/Models/Album.swift
// ABOUTME: Album model representing a music album from Music Assistant library
// ABOUTME: Contains album metadata including title, artist, artwork, track count, and release year

import Foundation

struct Album: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let artworkURL: URL?
    let trackCount: Int
    let year: Int?
    let duration: Double
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AlbumTests`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/Album.swift Tests/MusicAssistantPlayerTests/Models/AlbumTests.swift
git commit -m "feat: add Album model

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: Create Playlist Model

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/Playlist.swift`
- Create: `Tests/MusicAssistantPlayerTests/Models/PlaylistTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/MusicAssistantPlayerTests/Models/PlaylistTests.swift
import XCTest
@testable import MusicAssistantPlayer

final class PlaylistTests: XCTestCase {
    func testPlaylistInitialization() {
        let playlist = Playlist(
            id: "playlist-123",
            name: "My Playlist",
            artworkURL: URL(string: "https://example.com/playlist.jpg"),
            trackCount: 25,
            duration: 5400.0,
            owner: "harper"
        )

        XCTAssertEqual(playlist.id, "playlist-123")
        XCTAssertEqual(playlist.name, "My Playlist")
        XCTAssertEqual(playlist.trackCount, 25)
        XCTAssertEqual(playlist.duration, 5400.0)
        XCTAssertEqual(playlist.owner, "harper")
    }

    func testPlaylistWithoutOptionalFields() {
        let playlist = Playlist(
            id: "playlist-456",
            name: "Empty Playlist",
            artworkURL: nil,
            trackCount: 0,
            duration: 0.0,
            owner: nil
        )

        XCTAssertNil(playlist.artworkURL)
        XCTAssertNil(playlist.owner)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PlaylistTests`
Expected: FAIL with "Cannot find 'Playlist' in scope"

**Step 3: Write minimal implementation**

```swift
// Sources/MusicAssistantPlayer/Models/Playlist.swift
// ABOUTME: Playlist model representing a music playlist from Music Assistant library
// ABOUTME: Contains playlist metadata including name, artwork, track count, and owner

import Foundation

struct Playlist: Identifiable, Equatable {
    let id: String
    let name: String
    let artworkURL: URL?
    let trackCount: Int
    let duration: Double
    let owner: String?
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter PlaylistTests`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/Playlist.swift Tests/MusicAssistantPlayerTests/Models/PlaylistTests.swift
git commit -m "feat: add Playlist model

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: Create LibraryCategory Enum

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/LibraryCategory.swift`
- Create: `Tests/MusicAssistantPlayerTests/Models/LibraryCategoryTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/MusicAssistantPlayerTests/Models/LibraryCategoryTests.swift
import XCTest
@testable import MusicAssistantPlayer

final class LibraryCategoryTests: XCTestCase {
    func testLibraryCategoryDisplayNames() {
        XCTAssertEqual(LibraryCategory.artists.displayName, "Artists")
        XCTAssertEqual(LibraryCategory.albums.displayName, "Albums")
        XCTAssertEqual(LibraryCategory.tracks.displayName, "Tracks")
        XCTAssertEqual(LibraryCategory.playlists.displayName, "Playlists")
        XCTAssertEqual(LibraryCategory.radio.displayName, "Radio")
        XCTAssertEqual(LibraryCategory.genres.displayName, "Genres")
    }

    func testLibraryCategoryIcons() {
        XCTAssertEqual(LibraryCategory.artists.iconName, "person.2")
        XCTAssertEqual(LibraryCategory.albums.iconName, "square.stack")
        XCTAssertEqual(LibraryCategory.tracks.iconName, "music.note")
        XCTAssertEqual(LibraryCategory.playlists.iconName, "music.note.list")
        XCTAssertEqual(LibraryCategory.radio.iconName, "dot.radiowaves.left.and.right")
        XCTAssertEqual(LibraryCategory.genres.iconName, "guitars")
    }

    func testAllCasesContainsAllCategories() {
        XCTAssertEqual(LibraryCategory.allCases.count, 6)
        XCTAssertTrue(LibraryCategory.allCases.contains(.artists))
        XCTAssertTrue(LibraryCategory.allCases.contains(.albums))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LibraryCategoryTests`
Expected: FAIL with "Cannot find 'LibraryCategory' in scope"

**Step 3: Write minimal implementation**

```swift
// Sources/MusicAssistantPlayer/Models/LibraryCategory.swift
// ABOUTME: Enumeration of library browsing categories for sidebar navigation
// ABOUTME: Each category has a display name and SF Symbol icon

import Foundation

enum LibraryCategory: String, CaseIterable, Identifiable {
    case artists
    case albums
    case tracks
    case playlists
    case radio
    case genres

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .artists: return "Artists"
        case .albums: return "Albums"
        case .tracks: return "Tracks"
        case .playlists: return "Playlists"
        case .radio: return "Radio"
        case .genres: return "Genres"
        }
    }

    var iconName: String {
        switch self {
        case .artists: return "person.2"
        case .albums: return "square.stack"
        case .tracks: return "music.note"
        case .playlists: return "music.note.list"
        case .radio: return "dot.radiowaves.left.and.right"
        case .genres: return "guitars"
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter LibraryCategoryTests`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/LibraryCategory.swift Tests/MusicAssistantPlayerTests/Models/LibraryCategoryTests.swift
git commit -m "feat: add LibraryCategory enum for sidebar navigation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: Create LibraryService Skeleton

**Files:**
- Create: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`
- Create: `Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
import XCTest
@testable import MusicAssistantPlayer
import MusicAssistantKit

final class LibraryServiceTests: XCTestCase {
    var libraryService: LibraryService!
    var mockClient: MockMusicAssistantClient!

    override func setUp() {
        super.setUp()
        mockClient = MockMusicAssistantClient(host: "localhost", port: 8095)
        libraryService = LibraryService(client: mockClient)
    }

    override func tearDown() {
        libraryService = nil
        mockClient = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(libraryService.artists.isEmpty)
        XCTAssertTrue(libraryService.albums.isEmpty)
        XCTAssertTrue(libraryService.playlists.isEmpty)
        XCTAssertNil(libraryService.error)
    }

    func testClientInjection() {
        XCTAssertNotNil(libraryService.client)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LibraryServiceTests`
Expected: FAIL with "Cannot find 'LibraryService' in scope"

**Step 3: Write minimal implementation**

```swift
// Sources/MusicAssistantPlayer/Services/LibraryService.swift
// ABOUTME: Service for fetching and managing Music Assistant library content
// ABOUTME: Provides methods to fetch artists, albums, tracks, playlists, and perform playback actions

import Foundation
import MusicAssistantKit
import Combine

@MainActor
class LibraryService: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var albums: [Album] = []
    @Published var playlists: [Playlist] = []
    @Published var error: String?

    private(set) var client: MusicAssistantClient?

    init(client: MusicAssistantClient?) {
        self.client = client
    }

    // Methods will be added in subsequent tasks:
    // - fetchArtists()
    // - fetchAlbums(for artistId: String?)
    // - fetchTracks(for albumId: String)
    // - fetchPlaylists()
    // - playNow(item:on:)
    // - addToQueue(item:for:)
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter LibraryServiceTests`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/LibraryService.swift Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
git commit -m "feat: add LibraryService skeleton with initial state

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Phase 2: Library Service - Data Fetching

### Task 6: Implement fetchArtists Method

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift`

**Step 1: Write the failing test**

```swift
// Add to LibraryServiceTests.swift
func testFetchArtistsSuccess() async throws {
    // Mock client will need to return artist data
    mockClient.mockArtistsResponse = [
        "items": AnyCodable([
            [
                "item_id": "artist-1",
                "name": "Artist One",
                "image_url": "https://example.com/art1.jpg",
                "album_count": 5
            ],
            [
                "item_id": "artist-2",
                "name": "Artist Two",
                "image_url": nil,
                "album_count": 3
            ]
        ])
    ]

    try await libraryService.fetchArtists()

    XCTAssertEqual(libraryService.artists.count, 2)
    XCTAssertEqual(libraryService.artists[0].id, "artist-1")
    XCTAssertEqual(libraryService.artists[0].name, "Artist One")
    XCTAssertEqual(libraryService.artists[0].albumCount, 5)
    XCTAssertNil(libraryService.error)
}

func testFetchArtistsFailure() async throws {
    mockClient.shouldThrowError = true

    do {
        try await libraryService.fetchArtists()
        XCTFail("Expected error to be thrown")
    } catch {
        XCTAssertNotNil(libraryService.error)
        XCTAssertTrue(libraryService.artists.isEmpty)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LibraryServiceTests.testFetchArtists`
Expected: FAIL with "Value of type 'LibraryService' has no member 'fetchArtists'"

**Step 3: Write minimal implementation**

Add to LibraryService.swift:

```swift
func fetchArtists() async throws {
    guard let client = client else {
        self.error = "No client available"
        throw NSError(domain: "LibraryService", code: -1)
    }

    do {
        // TODO: Replace with actual MusicAssistantKit API call when available
        // For now, this is a placeholder structure
        if let result = try await client.getLibraryArtists() {
            let parsedArtists = parseArtists(from: result)
            self.artists = parsedArtists
            self.error = nil
        }
    } catch {
        self.error = "Failed to fetch artists: \(error.localizedDescription)"
        throw error
    }
}

private func parseArtists(from data: [String: AnyCodable]) -> [Artist] {
    guard let itemsWrapper = data["items"],
          let items = itemsWrapper.value as? [[String: Any]]
    else {
        return []
    }

    return items.compactMap { item in
        guard let id = item["item_id"] as? String,
              let name = item["name"] as? String
        else {
            return nil
        }

        let artworkURL: URL?
        if let imageURLString = item["image_url"] as? String {
            artworkURL = URL(string: imageURLString)
        } else {
            artworkURL = nil
        }

        let albumCount = item["album_count"] as? Int ?? 0

        return Artist(
            id: id,
            name: name,
            artworkURL: artworkURL,
            albumCount: albumCount
        )
    }
}
```

**Note:** The actual MusicAssistantKit API method name may differ. You'll need to check the MusicAssistantKit documentation or source code for the correct method. If it doesn't exist yet, you may need to add it to MusicAssistantKit first or use a lower-level API call.

**Step 4: Run test to verify it passes**

Run: `swift test --filter LibraryServiceTests.testFetchArtists`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/LibraryService.swift Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
git commit -m "feat: implement fetchArtists in LibraryService

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 7: Implement fetchAlbums Method

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift`

**Step 1: Write the failing test**

```swift
// Add to LibraryServiceTests.swift
func testFetchAlbumsSuccess() async throws {
    mockClient.mockAlbumsResponse = [
        "items": AnyCodable([
            [
                "item_id": "album-1",
                "name": "Album One",
                "artist": "Artist Name",
                "image_url": "https://example.com/album1.jpg",
                "track_count": 12,
                "year": 2024,
                "duration": 3600.0
            ],
            [
                "item_id": "album-2",
                "name": "Album Two",
                "artist": "Another Artist",
                "image_url": nil,
                "track_count": 8,
                "year": nil,
                "duration": 2400.0
            ]
        ])
    ]

    try await libraryService.fetchAlbums(for: nil)

    XCTAssertEqual(libraryService.albums.count, 2)
    XCTAssertEqual(libraryService.albums[0].id, "album-1")
    XCTAssertEqual(libraryService.albums[0].title, "Album One")
    XCTAssertEqual(libraryService.albums[0].artist, "Artist Name")
    XCTAssertEqual(libraryService.albums[0].trackCount, 12)
    XCTAssertEqual(libraryService.albums[0].year, 2024)
    XCTAssertNil(libraryService.error)
}

func testFetchAlbumsForSpecificArtist() async throws {
    mockClient.mockAlbumsResponse = [
        "items": AnyCodable([
            [
                "item_id": "album-1",
                "name": "Album One",
                "artist": "Artist Name",
                "image_url": nil,
                "track_count": 10,
                "year": 2023,
                "duration": 3000.0
            ]
        ])
    ]

    try await libraryService.fetchAlbums(for: "artist-123")

    XCTAssertEqual(libraryService.albums.count, 1)
    XCTAssertEqual(libraryService.albums[0].id, "album-1")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LibraryServiceTests.testFetchAlbums`
Expected: FAIL with "Value of type 'LibraryService' has no member 'fetchAlbums'"

**Step 3: Write minimal implementation**

Add to LibraryService.swift:

```swift
func fetchAlbums(for artistId: String? = nil) async throws {
    guard let client = client else {
        self.error = "No client available"
        throw NSError(domain: "LibraryService", code: -1)
    }

    do {
        // TODO: Replace with actual MusicAssistantKit API call
        let result: [String: AnyCodable]?
        if let artistId = artistId {
            result = try await client.getLibraryAlbums(forArtist: artistId)
        } else {
            result = try await client.getLibraryAlbums()
        }

        if let result = result {
            let parsedAlbums = parseAlbums(from: result)
            self.albums = parsedAlbums
            self.error = nil
        }
    } catch {
        self.error = "Failed to fetch albums: \(error.localizedDescription)"
        throw error
    }
}

private func parseAlbums(from data: [String: AnyCodable]) -> [Album] {
    guard let itemsWrapper = data["items"],
          let items = itemsWrapper.value as? [[String: Any]]
    else {
        return []
    }

    return items.compactMap { item in
        guard let id = item["item_id"] as? String,
              let title = item["name"] as? String,
              let artist = item["artist"] as? String
        else {
            return nil
        }

        let artworkURL: URL?
        if let imageURLString = item["image_url"] as? String {
            artworkURL = URL(string: imageURLString)
        } else {
            artworkURL = nil
        }

        let trackCount = item["track_count"] as? Int ?? 0
        let year = item["year"] as? Int
        let duration = item["duration"] as? Double ?? 0.0

        return Album(
            id: id,
            title: title,
            artist: artist,
            artworkURL: artworkURL,
            trackCount: trackCount,
            year: year,
            duration: duration
        )
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter LibraryServiceTests.testFetchAlbums`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/LibraryService.swift Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
git commit -m "feat: implement fetchAlbums in LibraryService

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 8: Implement fetchPlaylists Method

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`
- Modify: `Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift`

**Step 1: Write the failing test**

```swift
// Add to LibraryServiceTests.swift
func testFetchPlaylistsSuccess() async throws {
    mockClient.mockPlaylistsResponse = [
        "items": AnyCodable([
            [
                "item_id": "playlist-1",
                "name": "My Favorites",
                "image_url": "https://example.com/pl1.jpg",
                "track_count": 50,
                "duration": 12000.0,
                "owner": "harper"
            ],
            [
                "item_id": "playlist-2",
                "name": "Workout Mix",
                "image_url": nil,
                "track_count": 30,
                "duration": 7200.0,
                "owner": nil
            ]
        ])
    ]

    try await libraryService.fetchPlaylists()

    XCTAssertEqual(libraryService.playlists.count, 2)
    XCTAssertEqual(libraryService.playlists[0].id, "playlist-1")
    XCTAssertEqual(libraryService.playlists[0].name, "My Favorites")
    XCTAssertEqual(libraryService.playlists[0].trackCount, 50)
    XCTAssertEqual(libraryService.playlists[0].owner, "harper")
    XCTAssertNil(libraryService.error)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LibraryServiceTests.testFetchPlaylists`
Expected: FAIL with "Value of type 'LibraryService' has no member 'fetchPlaylists'"

**Step 3: Write minimal implementation**

Add to LibraryService.swift:

```swift
func fetchPlaylists() async throws {
    guard let client = client else {
        self.error = "No client available"
        throw NSError(domain: "LibraryService", code: -1)
    }

    do {
        // TODO: Replace with actual MusicAssistantKit API call
        if let result = try await client.getLibraryPlaylists() {
            let parsedPlaylists = parsePlaylists(from: result)
            self.playlists = parsedPlaylists
            self.error = nil
        }
    } catch {
        self.error = "Failed to fetch playlists: \(error.localizedDescription)"
        throw error
    }
}

private func parsePlaylists(from data: [String: AnyCodable]) -> [Playlist] {
    guard let itemsWrapper = data["items"],
          let items = itemsWrapper.value as? [[String: Any]]
    else {
        return []
    }

    return items.compactMap { item in
        guard let id = item["item_id"] as? String,
              let name = item["name"] as? String
        else {
            return nil
        }

        let artworkURL: URL?
        if let imageURLString = item["image_url"] as? String {
            artworkURL = URL(string: imageURLString)
        } else {
            artworkURL = nil
        }

        let trackCount = item["track_count"] as? Int ?? 0
        let duration = item["duration"] as? Double ?? 0.0
        let owner = item["owner"] as? String

        return Playlist(
            id: id,
            name: name,
            artworkURL: artworkURL,
            trackCount: trackCount,
            duration: duration,
            owner: owner
        )
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter LibraryServiceTests.testFetchPlaylists`
Expected: PASS (1 test)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/LibraryService.swift Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
git commit -m "feat: implement fetchPlaylists in LibraryService

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Phase 3: UI Components - Mini Player Bar

### Task 9: Create MiniPlayerBar Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/MiniPlayerBar.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift` (for preview testing)

**Step 1: Write the component**

```swift
// Sources/MusicAssistantPlayer/Views/MiniPlayerBar.swift
// ABOUTME: Persistent mini player bar at bottom with player selection, track info, and basic controls
// ABOUTME: Clicking artwork or track info expands to full now-playing view

import SwiftUI

struct MiniPlayerBar: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @Binding var selectedPlayer: Player?
    let availablePlayers: [Player]
    let imageCacheService: ImageCacheService
    let onExpand: () -> Void
    let onPlayerSelection: (Player) -> Void

    private let barHeight: CGFloat = 90

    var body: some View {
        HStack(spacing: 16) {
            // Left: Artwork + Track Info + Player Selector
            HStack(spacing: 12) {
                // Artwork (clickable to expand)
                Button(action: onExpand) {
                    if let artworkURL = nowPlayingViewModel.artworkURL {
                        CachedAsyncImage(
                            url: artworkURL,
                            imageCacheService: imageCacheService
                        ) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(4)
                    } else {
                        Color.gray.opacity(0.3)
                            .frame(width: 60, height: 60)
                            .cornerRadius(4)
                    }
                }
                .buttonStyle(.plain)

                // Track info (clickable to expand)
                Button(action: onExpand) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nowPlayingViewModel.trackTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(nowPlayingViewModel.artist)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .frame(width: 200, alignment: .leading)
                }
                .buttonStyle(.plain)

                // Player selector dropdown
                Menu {
                    ForEach(availablePlayers) { player in
                        Button(action: { onPlayerSelection(player) }) {
                            HStack {
                                Text(player.name)
                                if player.id == selectedPlayer?.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 12))
                        Text(selectedPlayer?.name ?? "No Player")
                            .font(.system(size: 12))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 400, alignment: .leading)

            Spacer()

            // Center: Transport controls
            HStack(spacing: 20) {
                Button(action: { Task { await nowPlayingViewModel.skipToPrevious() } }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(!nowPlayingViewModel.isPlayerAvailable)

                Button(action: { Task { await nowPlayingViewModel.togglePlayPause() } }) {
                    Image(systemName: nowPlayingViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(!nowPlayingViewModel.isPlayerAvailable)

                Button(action: { Task { await nowPlayingViewModel.skipToNext() } }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(!nowPlayingViewModel.isPlayerAvailable)
            }

            Spacer()

            // Right: Progress bar with time
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(nowPlayingViewModel.formattedProgress)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .monospacedDigit()

                    ProgressView(value: nowPlayingViewModel.progress, total: nowPlayingViewModel.duration)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                        .tint(.white)

                    Text(nowPlayingViewModel.formattedDuration)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .monospacedDigit()
                }
            }
            .frame(width: 300, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .frame(height: barHeight)
        .background(Color.black.opacity(0.9))
    }
}

#Preview {
    let config = ServerConfig(host: "192.168.200.113", port: 8095)
    let client = MusicAssistantClient(host: config.host, port: config.port)
    let playerService = PlayerService(client: client)
    let nowPlayingViewModel = NowPlayingViewModel(playerService: playerService)
    let imageCacheService = ImageCacheService()

    return MiniPlayerBar(
        nowPlayingViewModel: nowPlayingViewModel,
        selectedPlayer: .constant(Player(id: "test", name: "Test Player", isActive: true)),
        availablePlayers: [
            Player(id: "test", name: "Test Player", isActive: true),
            Player(id: "test2", name: "Kitchen", isActive: false)
        ],
        imageCacheService: imageCacheService,
        onExpand: {},
        onPlayerSelection: { _ in }
    )
    .frame(height: 90)
}
```

**Step 2: Build and preview**

Run: `swift build`
Expected: SUCCESS
Preview the component in Xcode to verify layout

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/MiniPlayerBar.swift
git commit -m "feat: add MiniPlayerBar component with player selection and controls

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Phase 4: UI Components - Library Sidebar

### Task 10: Create LibrarySidebarView Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/LibrarySidebarView.swift`

**Step 1: Write the component**

```swift
// Sources/MusicAssistantPlayer/Views/LibrarySidebarView.swift
// ABOUTME: Collapsible sidebar for library navigation with categories and providers
// ABOUTME: Displays library categories (Artists, Albums, etc.) and music providers (Spotify, Tidal, etc.)

import SwiftUI

struct LibrarySidebarView: View {
    @Binding var selectedCategory: LibraryCategory?
    let providers: [String] // Provider names from Music Assistant

    @State private var isLibraryExpanded = true
    @State private var isProvidersExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Library Section
            DisclosureGroup(
                isExpanded: $isLibraryExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(LibraryCategory.allCases) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.top, 8)
                },
                label: {
                    Text("LIBRARY")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 8)
                }
            )
            .padding(.horizontal, 12)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)

            // Providers Section
            DisclosureGroup(
                isExpanded: $isProvidersExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(providers, id: \.self) { provider in
                            ProviderButton(
                                name: provider,
                                action: {
                                    // TODO: Implement provider filtering
                                }
                            )
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.top, 8)
                },
                label: {
                    Text("PROVIDERS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 8)
                }
            )
            .padding(.horizontal, 12)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct CategoryButton: View {
    let category: LibraryCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.system(size: 14))
                    .frame(width: 16)

                Text(category.displayName)
                    .font(.system(size: 13))

                Spacer()
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct ProviderButton: View {
    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "music.note.house")
                    .font(.system(size: 14))
                    .frame(width: 16)

                Text(name)
                    .font(.system(size: 13))

                Spacer()
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LibrarySidebarView(
        selectedCategory: .constant(.artists),
        providers: ["Spotify", "Tidal", "Local Files"]
    )
    .frame(width: 200, height: 600)
}
```

**Step 2: Build and preview**

Run: `swift build`
Expected: SUCCESS

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/LibrarySidebarView.swift
git commit -m "feat: add LibrarySidebarView with collapsible library categories

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Phase 5: Integration - New Main Window

### Task 11: Create CenterViewMode Enum

**Files:**
- Create: `Sources/MusicAssistantPlayer/Models/CenterViewMode.swift`
- Create: `Tests/MusicAssistantPlayerTests/Models/CenterViewModeTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/MusicAssistantPlayerTests/Models/CenterViewModeTests.swift
import XCTest
@testable import MusicAssistantPlayer

final class CenterViewModeTests: XCTestCase {
    func testCenterViewModeCases() {
        let library = CenterViewMode.library
        let expanded = CenterViewMode.expandedNowPlaying

        XCTAssertNotEqual(library, expanded)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter CenterViewModeTests`
Expected: FAIL with "Cannot find 'CenterViewMode' in scope"

**Step 3: Write minimal implementation**

```swift
// Sources/MusicAssistantPlayer/Models/CenterViewMode.swift
// ABOUTME: Enum representing which view is displayed in the center area
// ABOUTME: Switches between library browsing and expanded now-playing

import Foundation

enum CenterViewMode {
    case library
    case expandedNowPlaying
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter CenterViewModeTests`
Expected: PASS (1 test)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Models/CenterViewMode.swift Tests/MusicAssistantPlayerTests/Models/CenterViewModeTests.swift
git commit -m "feat: add CenterViewMode enum for view switching

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 12: Create LibraryViewModel

**Files:**
- Create: `Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift`
- Create: `Tests/MusicAssistantPlayerTests/ViewModels/LibraryViewModelTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/MusicAssistantPlayerTests/ViewModels/LibraryViewModelTests.swift
import XCTest
@testable import MusicAssistantPlayer

final class LibraryViewModelTests: XCTestCase {
    var viewModel: LibraryViewModel!
    var libraryService: LibraryService!

    override func setUp() {
        super.setUp()
        let mockClient = MockMusicAssistantClient(host: "localhost", port: 8095)
        libraryService = LibraryService(client: mockClient)
        viewModel = LibraryViewModel(libraryService: libraryService)
    }

    override func tearDown() {
        viewModel = nil
        libraryService = nil
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertEqual(viewModel.selectedCategory, .artists)
        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testCategorySelection() async {
        viewModel.selectedCategory = .albums
        XCTAssertEqual(viewModel.selectedCategory, .albums)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LibraryViewModelTests`
Expected: FAIL with "Cannot find 'LibraryViewModel' in scope"

**Step 3: Write minimal implementation**

```swift
// Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift
// ABOUTME: ViewModel managing library browsing state and user interactions
// ABOUTME: Coordinates between LibraryService and UI, handles category selection and search

import Foundation
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var selectedCategory: LibraryCategory = .artists
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false

    private let libraryService: LibraryService

    init(libraryService: LibraryService) {
        self.libraryService = libraryService
    }

    // Properties exposing service data
    var artists: [Artist] {
        libraryService.artists
    }

    var albums: [Album] {
        libraryService.albums
    }

    var playlists: [Playlist] {
        libraryService.playlists
    }

    var errorMessage: String? {
        libraryService.error
    }

    // Methods to load content based on category
    func loadContent() async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch selectedCategory {
            case .artists:
                try await libraryService.fetchArtists()
            case .albums:
                try await libraryService.fetchAlbums(for: nil)
            case .playlists:
                try await libraryService.fetchPlaylists()
            default:
                // TODO: Implement other categories
                break
            }
        } catch {
            // Error already set in service
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter LibraryViewModelTests`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift Tests/MusicAssistantPlayerTests/ViewModels/LibraryViewModelTests.swift
git commit -m "feat: add LibraryViewModel for library browsing state

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Implementation Note

**Doctor Biz:** This is a comprehensive plan covering the foundational structure. Due to the scope of this redesign, I've detailed the first 12 tasks covering:

1. ✅ Foundation models (Artist, Album, Playlist, LibraryCategory)
2. ✅ LibraryService skeleton with fetch methods
3. ✅ Mini player bar component
4. ✅ Library sidebar component
5. ✅ View mode switching
6. ✅ LibraryViewModel

**Remaining work (to be added in continuation or separate tasks):**

- **Phase 6:** LibraryBrowseView with grid/list layouts
- **Phase 7:** Spotify-style hover interactions and context menus
- **Phase 8:** SearchService and SearchViewModel
- **Phase 9:** Global search (Command+K)
- **Phase 10:** ExpandedNowPlayingView (adapted from current)
- **Phase 11:** RoonStyleMainWindowView integration
- **Phase 12:** Responsive layout and breakpoints
- **Phase 13:** End-to-end testing

Each phase follows the same TDD pattern established above. The MusicAssistantKit API calls are placeholders and will need to be verified/implemented based on actual API availability.

---

**Ready to start execution?**
