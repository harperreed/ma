// ABOUTME: Main library browsing view with search, content display, and category-based navigation
// ABOUTME: Displays artists, albums, playlists in grid or list format based on category

import SwiftUI

struct LibraryBrowseView: View {
    @ObservedObject var viewModel: LibraryViewModel
    let onPlayNow: (String, LibraryItemType) -> Void
    let onAddToQueue: (String, LibraryItemType) -> Void
    let serverHost: String?
    let serverPort: Int?
    let connectionState: ConnectionState?
    let onDisconnect: (() -> Void)?
    let onChangeServer: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            HStack(spacing: 12) {
                // Search bar - now with debouncing handled in ViewModel
                SearchBar(
                    text: $viewModel.searchQuery,
                    placeholder: "Search \(viewModel.selectedCategory.displayName.lowercased())..."
                )
            }
            .padding()

            // Sort and Filter toolbar
            LibraryToolbar(viewModel: viewModel)

            // Event-driven library - no hydration progress needed!

            Divider()
                .background(Color.white.opacity(0.1))

            // Error banner - dismissable, non-blocking
            if let error = viewModel.errorMessage, !viewModel.isLoading {
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
                    Button("Retry", action: {
                        viewModel.clearError()
                        Task { await viewModel.loadContent() }
                    })
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(6)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.2))
            }

            // Content area
            ScrollView {
                if viewModel.isLoading && viewModel.artists.isEmpty && viewModel.albums.isEmpty && viewModel.tracks.isEmpty && viewModel.playlists.isEmpty {
                    // Only show full-screen loading on initial load
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        VStack(spacing: 0) {
            // Show navigation breadcrumbs and back button
            if viewModel.selectedArtist != nil || viewModel.selectedAlbum != nil {
                HStack {
                    Button(action: {
                        viewModel.goBack()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    if let artist = viewModel.selectedArtist {
                        Text(" / \(artist.name)")
                            .foregroundColor(.white.opacity(0.7))
                        if let album = viewModel.selectedAlbum {
                            Text(" / \(album.title)")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.05))
            }

            // Show appropriate content based on navigation state
            if let album = viewModel.selectedAlbum {
                // Album detail: show tracks
                TracksListView(
                    tracks: viewModel.tracks,
                    onPlayNow: { onPlayNow($0.id, .track) },
                    onAddToQueue: { onAddToQueue($0.id, .track) },
                    onLoadMore: nil // No pagination for album tracks
                )
            } else if let artist = viewModel.selectedArtist {
                // Artist detail: show albums grouped by type
                GroupedAlbumsView(
                    albums: viewModel.albums,
                    onPlayNow: { onPlayNow($0.id, .album) },
                    onAddToQueue: { onAddToQueue($0.id, .album) },
                    onAlbumSelected: { album in
                        Task {
                            await viewModel.selectAlbum(album)
                        }
                    }
                )
            } else {
                // Main library view
                switch viewModel.selectedCategory {
                case .artists:
                    ArtistsListView(
                        artists: viewModel.artists,
                        onPlayNow: { onPlayNow($0.id, .artist) },
                        onAddToQueue: { onAddToQueue($0.id, .artist) },
                        onArtistSelected: { artist in
                            Task {
                                await viewModel.selectArtist(artist)
                            }
                        },
                        onLoadMore: {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    )
                case .albums:
                    AlbumsGridView(
                        albums: viewModel.albums,
                        onPlayNow: { onPlayNow($0.id, .album) },
                        onAddToQueue: { onAddToQueue($0.id, .album) },
                        onLoadMore: {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    )
                case .tracks:
                    TracksListView(
                        tracks: viewModel.tracks,
                        onPlayNow: { onPlayNow($0.id, .track) },
                        onAddToQueue: { onAddToQueue($0.id, .track) },
                        onLoadMore: {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    )
                case .playlists:
                    PlaylistsListView(
                        playlists: viewModel.playlists,
                        onPlayNow: { onPlayNow($0.id, .playlist) },
                        onAddToQueue: { onAddToQueue($0.id, .playlist) },
                        onLoadMore: {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    )
                case .radio:
                    RadiosListView(
                        radios: viewModel.radios,
                        onPlayNow: { onPlayNow($0.id, .radio) },
                        onAddToQueue: { onAddToQueue($0.id, .radio) },
                        onLoadMore: {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    )
                case .genres:
                    Text("Coming Soon")
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // Pagination UI - Load More button
            if viewModel.hasMoreItems {
                Button(action: {
                    Task {
                        await viewModel.loadMore()
                    }
                }) {
                    HStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                                .tint(.white.opacity(0.7))
                        }
                        Text(viewModel.isLoading ? "Loading..." : "Load More")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .padding()
                .disabled(viewModel.isLoading)
            }
        }
    }
}

enum LibraryItemType {
    case artist
    case album
    case playlist
    case track
    case radio
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search library..."

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))

            TextField(placeholder, text: $text)
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
    let libraryService = LibraryService(client: nil)
    let viewModel = LibraryViewModel(libraryService: libraryService)

    LibraryBrowseView(
        viewModel: viewModel,
        onPlayNow: { _, _ in },
        onAddToQueue: { _, _ in },
        serverHost: "localhost",
        serverPort: 8095,
        connectionState: .connected,
        onDisconnect: {},
        onChangeServer: {}
    )
}
