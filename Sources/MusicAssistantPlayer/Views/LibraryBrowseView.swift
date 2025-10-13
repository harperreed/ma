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
    let libraryService = LibraryService(client: nil)
    let viewModel = LibraryViewModel(libraryService: libraryService)

    LibraryBrowseView(
        viewModel: viewModel,
        onPlayNow: { _, _ in },
        onAddToQueue: { _, _ in }
    )
}
