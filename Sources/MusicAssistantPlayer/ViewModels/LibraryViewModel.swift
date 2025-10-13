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
