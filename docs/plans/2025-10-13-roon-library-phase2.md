# Roon-Style Library Browser - Phase 2 Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Continue Roon-style library implementation with LibraryBrowseView, search functionality, and final integration.

**Prerequisites:** Phase 1 complete (Tasks 1-12) - Models, LibraryService, MiniPlayerBar, LibrarySidebarView, ViewModels all implemented.

**Tech Stack:** SwiftUI, MusicAssistantKit, existing service layer patterns, TDD with XCTest

---

## Phase 6: Library Browse View

### Task 13: Create LibraryBrowseView Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift`

**Step 1: Write the component**

```swift
// Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift
// ABOUTME: Main library browsing view with search, content display, and category-based navigation
// ABOUTME: Displays artists, albums, playlists in grid or list format based on category

import SwiftUI

struct LibraryBrowseView: View {
    @ObservedObject var viewModel: LibraryViewModel
    let onPlayNow: (String, LibraryItemType) -> Void
    let onAddToQueue: (String, LibraryItemType) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $viewModel.searchQuery)
                .padding()

            // Content area
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task { await viewModel.loadContent() }
                    }
                } else {
                    contentView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task {
            await viewModel.loadContent()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.selectedCategory {
        case .artists:
            ArtistsGridView(
                artists: viewModel.artists,
                onPlayNow: { onPlayNow($0.id, .artist) },
                onAddToQueue: { onAddToQueue($0.id, .artist) }
            )
        case .albums:
            AlbumsGridView(
                albums: viewModel.albums,
                onPlayNow: { onPlayNow($0.id, .album) },
                onAddToQueue: { onAddToQueue($0.id, .album) }
            )
        case .playlists:
            PlaylistsListView(
                playlists: viewModel.playlists,
                onPlayNow: { onPlayNow($0.id, .playlist) },
                onAddToQueue: { onAddToQueue($0.id, .playlist) }
            )
        default:
            Text("Coming Soon")
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

enum LibraryItemType {
    case artist
    case album
    case playlist
    case track
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))

            TextField("Search library...", text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(.white)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.7))

            Text(message)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button("Retry", action: onRetry)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
        }
        .padding()
    }
}

#Preview {
    let mockClient = MockMusicAssistantClient(host: "localhost", port: 8095)
    let libraryService = LibraryService(client: mockClient)
    let viewModel = LibraryViewModel(libraryService: libraryService)

    return LibraryBrowseView(
        viewModel: viewModel,
        onPlayNow: { _, _ in },
        onAddToQueue: { _, _ in }
    )
}
```

**Step 2: Build and verify**

Run: `swift build`
Expected: SUCCESS

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift
git commit -m "feat: add LibraryBrowseView with search and content switching

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 14: Create ArtistsGridView Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/ArtistsGridView.swift`

**Step 1: Write the component**

```swift
// Sources/MusicAssistantPlayer/Views/ArtistsGridView.swift
// ABOUTME: Grid view displaying artists with artwork, name, and album count
// ABOUTME: Supports hover interactions for play and queue actions

import SwiftUI

struct ArtistsGridView: View {
    let artists: [Artist]
    let onPlayNow: (Artist) -> Void
    let onAddToQueue: (Artist) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 20)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(artists) { artist in
                ArtistCard(
                    artist: artist,
                    onPlayNow: { onPlayNow(artist) },
                    onAddToQueue: { onAddToQueue(artist) }
                )
            }
        }
        .padding()
    }
}

struct ArtistCard: View {
    let artist: Artist
    let onPlayNow: () -> Void
    let onAddToQueue: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Artwork with play button overlay
            ZStack(alignment: .bottomTrailing) {
                if let artworkURL = artist.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                } else {
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "person.2")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                // Play button (visible on hover)
                if isHovered {
                    Button(action: onPlayNow) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.black)
                                    .offset(x: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            .contextMenu {
                Button("Play Now") { onPlayNow() }
                Button("Add to Queue") { onAddToQueue() }
            }

            // Artist info
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text("\(artist.albumCount) album\(artist.albumCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

#Preview {
    ArtistsGridView(
        artists: [
            Artist(id: "1", name: "Test Artist", artworkURL: nil, albumCount: 5),
            Artist(id: "2", name: "Another Artist", artworkURL: nil, albumCount: 12)
        ],
        onPlayNow: { _ in },
        onAddToQueue: { _ in }
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
```

**Step 2: Build and verify**

Run: `swift build`
Expected: SUCCESS

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/ArtistsGridView.swift
git commit -m "feat: add ArtistsGridView with hover interactions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 15: Create AlbumsGridView Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/AlbumsGridView.swift`

**Step 1: Write the component**

```swift
// Sources/MusicAssistantPlayer/Views/AlbumsGridView.swift
// ABOUTME: Grid view displaying albums with artwork, title, artist, and track info
// ABOUTME: Supports hover interactions for play and queue actions

import SwiftUI

struct AlbumsGridView: View {
    let albums: [Album]
    let onPlayNow: (Album) -> Void
    let onAddToQueue: (Album) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 20)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(albums) { album in
                AlbumCard(
                    album: album,
                    onPlayNow: { onPlayNow(album) },
                    onAddToQueue: { onAddToQueue(album) }
                )
            }
        }
        .padding()
    }
}

struct AlbumCard: View {
    let album: Album
    let onPlayNow: () -> Void
    let onAddToQueue: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Artwork with play button overlay
            ZStack(alignment: .bottomTrailing) {
                if let artworkURL = album.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                } else {
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "square.stack")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                // Play button (visible on hover)
                if isHovered {
                    Button(action: onPlayNow) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.black)
                                    .offset(x: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            .contextMenu {
                Button("Play Now") { onPlayNow() }
                Button("Add to Queue") { onAddToQueue() }
            }

            // Album info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(album.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)

                if let year = album.year {
                    Text("\(year) • \(album.trackCount) track\(album.trackCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                } else {
                    Text("\(album.trackCount) track\(album.trackCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

#Preview {
    AlbumsGridView(
        albums: [
            Album(id: "1", title: "Test Album", artist: "Test Artist", artworkURL: nil, trackCount: 12, year: 2024, duration: 3600),
            Album(id: "2", title: "Another Album", artist: "Another Artist", artworkURL: nil, trackCount: 8, year: nil, duration: 2400)
        ],
        onPlayNow: { _ in },
        onAddToQueue: { _ in }
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
```

**Step 2: Build and verify**

Run: `swift build`
Expected: SUCCESS

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/AlbumsGridView.swift
git commit -m "feat: add AlbumsGridView with hover interactions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 16: Create PlaylistsListView Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/PlaylistsListView.swift`

**Step 1: Write the component**

```swift
// Sources/MusicAssistantPlayer/Views/PlaylistsListView.swift
// ABOUTME: List view displaying playlists with artwork, name, and track count
// ABOUTME: Supports hover interactions for play and queue actions

import SwiftUI

struct PlaylistsListView: View {
    let playlists: [Playlist]
    let onPlayNow: (Playlist) -> Void
    let onAddToQueue: (Playlist) -> Void

    var body: some View {
        VStack(spacing: 1) {
            ForEach(playlists) { playlist in
                PlaylistRow(
                    playlist: playlist,
                    onPlayNow: { onPlayNow(playlist) },
                    onAddToQueue: { onAddToQueue(playlist) }
                )
            }
        }
        .padding()
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    let onPlayNow: () -> Void
    let onAddToQueue: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Artwork
            ZStack {
                if let artworkURL = playlist.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                } else {
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                // Play button overlay (visible on hover)
                if isHovered {
                    Button(action: onPlayNow) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.black)
                                    .font(.system(size: 16))
                                    .offset(x: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Playlist info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let owner = playlist.owner {
                        Text("By \(owner)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Text("\(playlist.trackCount) track\(playlist.trackCount == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            // Three-dot menu button (visible on hover)
            if isHovered {
                Menu {
                    Button("Play Now") { onPlayNow() }
                    Button("Add to Queue") { onAddToQueue() }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHovered ? Color.white.opacity(0.05) : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Play Now") { onPlayNow() }
            Button("Add to Queue") { onAddToQueue() }
        }
    }
}

#Preview {
    PlaylistsListView(
        playlists: [
            Playlist(id: "1", name: "My Favorites", artworkURL: nil, trackCount: 50, duration: 12000, owner: "harper"),
            Playlist(id: "2", name: "Workout Mix", artworkURL: nil, trackCount: 30, duration: 7200, owner: nil)
        ],
        onPlayNow: { _ in },
        onAddToQueue: { _ in }
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
```

**Step 2: Build and verify**

Run: `swift build`
Expected: SUCCESS

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/PlaylistsListView.swift
git commit -m "feat: add PlaylistsListView with hover interactions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Summary

**Phase 6 complete!** This phase delivers the core library browsing experience with:
- LibraryBrowseView: Main container with search and content switching
- ArtistsGridView: Grid display for artists with hover play buttons
- AlbumsGridView: Grid display for albums with metadata
- PlaylistsListView: List display for playlists with inline actions

All components follow Spotify's interaction patterns with hover states, context menus, and green play buttons.

**Next:** Phase 7-13 would cover search functionality, global shortcuts, ExpandedNowPlayingView adaptation, RoonStyleMainWindowView integration, responsive design, and end-to-end testing.
