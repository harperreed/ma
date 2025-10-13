// ABOUTME: ViewModel managing library browsing state and user interactions
// ABOUTME: Coordinates between LibraryService and UI, handles category selection and search

import Foundation
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var selectedCategory: LibraryCategory = .artists
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false

    // Task 16: Search, sort, filter properties
    @Published var selectedSort: LibrarySortOption = .nameAsc
    @Published var selectedFilter: LibraryFilter = LibraryFilter()

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

    var tracks: [Track] {
        libraryService.tracks
    }

    var errorMessage: String? {
        libraryService.lastError?.localizedDescription
    }

    // Methods to load content based on category
    func loadContent() async {
        isLoading = true
        defer { isLoading = false }

        libraryService.resetPagination()

        do {
            switch selectedCategory {
            case .artists:
                try await libraryService.fetchArtists()
            case .albums:
                try await libraryService.fetchAlbums(for: nil)
            case .tracks:
                try await libraryService.fetchTracks(for: nil)
            case .playlists:
                try await libraryService.fetchPlaylists()
            case .radio:
                try await libraryService.fetchRadios()
            case .genres:
                try await libraryService.fetchGenres()
            }
        } catch {
            // Error already set in service
        }
    }

    // MARK: - Task 16: Search Methods

    func performSearch(query: String) async {
        searchQuery = query
        isLoading = true
        defer { isLoading = false }

        do {
            try await libraryService.search(query: query, in: selectedCategory)
        } catch {
            // Error already set in service
        }
    }

    // MARK: - Task 16: Sort Methods

    func updateSort(_ sort: LibrarySortOption) async {
        selectedSort = sort
        libraryService.currentSort = sort
        libraryService.resetPagination()
        await loadContent()
    }

    // MARK: - Task 16: Filter Methods

    func updateFilter(_ filter: LibraryFilter) async {
        selectedFilter = filter
        libraryService.currentFilter = filter
        libraryService.resetPagination()
        await loadContent()
    }

    // MARK: - Task 16: Pagination Methods

    func loadMore() async {
        guard libraryService.hasMoreItems else { return }

        do {
            try await libraryService.loadNextPage(for: selectedCategory)
        } catch {
            // Error handled by service
        }
    }

    var hasMoreItems: Bool {
        libraryService.hasMoreItems
    }

    // MARK: - Utility Methods

    func clearError() {
        libraryService.lastError = nil
    }
}
