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

    // Navigation state
    @Published var selectedArtist: Artist? = nil
    @Published var selectedAlbum: Album? = nil

    let libraryService: LibraryService // Public for UI access to hydration progress
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    init(libraryService: LibraryService) {
        self.libraryService = libraryService
        setupSearchDebouncing()

        // Event-driven library - no hydration needed!
        // LibraryService subscribes to events automatically
    }

    private func setupSearchDebouncing() {
        // Debounce search query changes to avoid searching on every keystroke
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchTask?.cancel()
                self?.searchTask = Task { [weak self] in
                    await self?.handleSearchQueryChange(query: query)
                }
            }
            .store(in: &cancellables)
    }

    private func handleSearchQueryChange(query: String) async {
        if query.isEmpty {
            // Clear search - reload regular content
            await loadContent()
        } else if query.count >= 2 {
            // Only search if query is at least 2 characters
            await performSearch(query: query)
        }
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

    var radios: [Radio] {
        libraryService.radios
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
                // Lazy load first page of artists
                try await libraryService.fetchArtists()
            case .albums:
                try await libraryService.fetchAlbums(for: nil)
            case .tracks:
                try await libraryService.fetchTracks(for: nil)
            case .playlists:
                try await libraryService.fetchPlaylists()
            case .radio:
                try await libraryService.fetchRadios(
                    limit: nil,
                    offset: 0,
                    sort: selectedSort,
                    filter: selectedFilter,
                    forceRefresh: false
                )
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

    // MARK: - Navigation Methods

    func selectArtist(_ artist: Artist) async {
        selectedArtist = artist
        selectedAlbum = nil
        isLoading = true
        defer { isLoading = false }

        do {
            print("📱 [LibraryViewModel] Loading albums for artist: \(artist.name) (id: \(artist.id))")
            try await libraryService.fetchAlbums(for: artist.id)
            print("📱 [LibraryViewModel] Loaded \(libraryService.albums.count) albums (cached or fresh)")
        } catch {
            print("📱 [LibraryViewModel] Error loading albums: \(error.localizedDescription)")
        }
    }

    func selectAlbum(_ album: Album) async {
        selectedAlbum = album
        isLoading = true
        defer { isLoading = false }

        do {
            print("📱 [LibraryViewModel] Loading tracks for album: \(album.title)")
            try await libraryService.fetchTracks(for: album.id)
            print("📱 [LibraryViewModel] Loaded \(libraryService.tracks.count) tracks")
        } catch {
            print("📱 [LibraryViewModel] Error loading tracks: \(error.localizedDescription)")
        }
    }

    func goBack() {
        if selectedAlbum != nil {
            // Go back from album to artist
            selectedAlbum = nil
        } else if selectedArtist != nil {
            // Go back from artist to artists list
            selectedArtist = nil
        }
    }

    // MARK: - Utility Methods

    func clearError() {
        libraryService.lastError = nil
    }
}
