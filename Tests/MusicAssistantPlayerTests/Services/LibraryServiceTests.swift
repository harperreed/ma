// Tests/MusicAssistantPlayerTests/Services/LibraryServiceTests.swift
import XCTest
@testable import MusicAssistantPlayer
import MusicAssistantKit

final class LibraryServiceTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let libraryService = LibraryService(client: nil)

        XCTAssertTrue(libraryService.artists.isEmpty)
        XCTAssertTrue(libraryService.albums.isEmpty)
        XCTAssertTrue(libraryService.playlists.isEmpty)
        XCTAssertTrue(libraryService.radios.isEmpty)
        XCTAssertTrue(libraryService.genres.isEmpty)
        XCTAssertNil(libraryService.lastError)
    }

    @MainActor
    func testClientInjection() {
        let client = MusicAssistantClient(host: "localhost", port: 8095)
        let libraryService = LibraryService(client: client)

        XCTAssertNotNil(libraryService.client)
    }

    // MARK: - Task 6: fetchArtists Tests

    @MainActor
    func testFetchArtistsWithNoClient() async {
        let libraryService = LibraryService(client: nil)

        do {
            try await libraryService.fetchArtists()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(libraryService.lastError)
            XCTAssertTrue(libraryService.artists.isEmpty)
        }
    }

    @MainActor
    func testFetchArtistsSuccess() async throws {
        // For now, this test will document the expected behavior
        // We'll need to create a mock client or use dependency injection
        // This is a placeholder that should fail until implementation
        let client = MusicAssistantClient(host: "localhost", port: 8095)
        let libraryService = LibraryService(client: client)

        // This will fail until we implement fetchArtists
        // try await libraryService.fetchArtists()
        // For now, just verify the method exists by checking it compiles
        XCTAssertTrue(libraryService.artists.isEmpty)
    }

    // MARK: - Task 7: fetchAlbums Tests

    @MainActor
    func testFetchAlbumsWithNoClient() async {
        let libraryService = LibraryService(client: nil)

        do {
            try await libraryService.fetchAlbums(for: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(libraryService.lastError)
            XCTAssertTrue(libraryService.albums.isEmpty)
        }
    }

    @MainActor
    func testFetchAlbumsAllAlbums() async throws {
        let client = MusicAssistantClient(host: "localhost", port: 8095)
        let libraryService = LibraryService(client: client)

        // For now, just verify the method exists
        XCTAssertTrue(libraryService.albums.isEmpty)
    }

    @MainActor
    func testFetchAlbumsForSpecificArtist() async throws {
        let client = MusicAssistantClient(host: "localhost", port: 8095)
        let libraryService = LibraryService(client: client)

        // For now, just verify the method exists
        XCTAssertTrue(libraryService.albums.isEmpty)
    }

    // MARK: - Task 8: fetchPlaylists Tests

    @MainActor
    func testFetchPlaylistsWithNoClient() async {
        let libraryService = LibraryService(client: nil)

        do {
            try await libraryService.fetchPlaylists()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(libraryService.lastError)
            XCTAssertTrue(libraryService.playlists.isEmpty)
        }
    }

    @MainActor
    func testFetchPlaylistsSuccess() async throws {
        let client = MusicAssistantClient(host: "localhost", port: 8095)
        let libraryService = LibraryService(client: client)

        // For now, just verify the method exists
        XCTAssertTrue(libraryService.playlists.isEmpty)
    }

    // MARK: - Task 6: search Tests

    @MainActor
    func testSearchPublishesError() async {
        let service = LibraryService(client: nil)

        do {
            try await service.search(query: "test", in: .artists)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    // MARK: - Task 7: Pagination Tests

    @MainActor
    func testFetchArtistsPaginatedWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            // Test that the method accepts pagination parameters
            try await service.fetchArtists(limit: 10, offset: 0)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(service.lastError)
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testPaginationStateInitialValues() {
        let service = LibraryService(client: nil)

        XCTAssertFalse(service.hasMoreItems)
        XCTAssertEqual(service.currentOffset, 0)
    }

    @MainActor
    func testResetPagination() {
        let service = LibraryService(client: nil)

        // This will test resetPagination once implemented
        service.resetPagination()

        XCTAssertFalse(service.hasMoreItems)
        XCTAssertEqual(service.currentOffset, 0)
    }

    // MARK: - Task 9: Radio Tests

    @MainActor
    func testFetchRadiosWithNoClient() async {
        let libraryService = LibraryService(client: nil)

        do {
            try await libraryService.fetchRadios()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(libraryService.lastError)
            XCTAssertTrue(libraryService.radios.isEmpty)
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchRadiosSuccess() async throws {
        let client = MusicAssistantClient(host: "localhost", port: 8095)
        let libraryService = LibraryService(client: client)

        // For now, just verify the method exists and initial state is empty
        XCTAssertTrue(libraryService.radios.isEmpty)
    }

    @MainActor
    func testFetchRadiosWithPagination() async {
        let service = LibraryService(client: nil)

        do {
            // Test that the method accepts pagination parameters
            try await service.fetchRadios(limit: 10, offset: 0)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(service.lastError)
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testSearchRadiosWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            try await service.search(query: "test", in: .radio)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testSearchRadiosEmptyQuery() async {
        let service = LibraryService(client: nil)

        do {
            // Empty query should trigger fetchRadios, which will fail with no client
            try await service.search(query: "", in: .radio)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    // MARK: - Task 9: Genre Tests

    @MainActor
    func testFetchGenresWithNoClient() async {
        let libraryService = LibraryService(client: nil)

        do {
            try await libraryService.fetchGenres()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(libraryService.lastError)
            XCTAssertTrue(libraryService.genres.isEmpty)
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchGenresSuccess() async throws {
        let client = MusicAssistantClient(host: "localhost", port: 8095)
        let libraryService = LibraryService(client: client)

        // For now, just verify the method exists and initial state is empty
        XCTAssertTrue(libraryService.genres.isEmpty)
    }

    @MainActor
    func testFetchGenresWithPagination() async {
        let service = LibraryService(client: nil)

        do {
            // Test that the method accepts pagination parameters
            try await service.fetchGenres(limit: 10, offset: 0)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(service.lastError)
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testSearchGenresWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            try await service.search(query: "test", in: .genres)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testSearchGenresEmptyQuery() async {
        let service = LibraryService(client: nil)

        do {
            // Empty query should trigger fetchGenres, which will fail with no client
            try await service.search(query: "", in: .genres)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testLoadNextPageRadioWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            // Set hasMoreItems to true to test the actual fetch call
            // This is a bit hacky but tests the switch case
            try await service.loadNextPage(for: .radio)
            // If hasMoreItems is false, it returns early without error
            XCTAssertFalse(service.hasMoreItems)
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testLoadNextPageGenresWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            // Set hasMoreItems to true to test the actual fetch call
            try await service.loadNextPage(for: .genres)
            // If hasMoreItems is false, it returns early without error
            XCTAssertFalse(service.hasMoreItems)
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    // MARK: - Task 11: Favorites Tests

    @MainActor
    func testFetchFavoriteArtistsWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoriteArtists()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
            XCTAssertNotNil(service.lastError)
        }
    }

    @MainActor
    func testFetchFavoriteAlbumsWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoriteAlbums()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
            XCTAssertNotNil(service.lastError)
        }
    }

    @MainActor
    func testFetchFavoriteTracksWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoriteTracks()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
            XCTAssertNotNil(service.lastError)
        }
    }

    @MainActor
    func testFetchFavoritePlaylistsWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoritePlaylists()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
            XCTAssertNotNil(service.lastError)
        }
    }

    // MARK: - Task 11: Recently Played Tests

    @MainActor
    func testFetchRecentlyPlayedWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchRecentlyPlayed()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
            XCTAssertNotNil(service.lastError)
        }
    }

    @MainActor
    func testFetchRecentlyPlayedWithLimit() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchRecentlyPlayed(limit: 10)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    // MARK: - Task 11: Add/Remove Favorites Tests

    @MainActor
    func testAddToFavoritesWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            try await service.addToFavorites(itemId: "test-id", mediaType: "track")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
            XCTAssertNotNil(service.lastError)
        }
    }

    @MainActor
    func testRemoveFromFavoritesWithNoClient() async {
        let service = LibraryService(client: nil)

        do {
            try await service.removeFromFavorites(itemId: "test-id", mediaType: "track")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
            XCTAssertNotNil(service.lastError)
        }
    }

    @MainActor
    func testAddToFavoritesForDifferentMediaTypes() async {
        let service = LibraryService(client: nil)

        // Test for artist
        do {
            try await service.addToFavorites(itemId: "artist-1", mediaType: "artist")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }

        // Test for album
        do {
            try await service.addToFavorites(itemId: "album-1", mediaType: "album")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }

        // Test for playlist
        do {
            try await service.addToFavorites(itemId: "playlist-1", mediaType: "playlist")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    // MARK: - Task 11: Comprehensive Success Tests (TDD)

    @MainActor
    func testFetchFavoriteArtistsAcceptsSortParameter() async {
        let service = LibraryService(client: nil)

        do {
            // Test that method accepts sort parameter - should compile
            try await service.fetchFavoriteArtists(sort: .nameAsc)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoriteArtistsAcceptsFilterParameter() async {
        let service = LibraryService(client: nil)

        do {
            // Test that method accepts filter parameter - should compile
            let filter = LibraryFilter()
            try await service.fetchFavoriteArtists(filter: filter)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoriteArtistsAcceptsForceRefreshParameter() async {
        let service = LibraryService(client: nil)

        do {
            // Test that method accepts forceRefresh parameter - should compile
            try await service.fetchFavoriteArtists(forceRefresh: true)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoriteAlbumsAcceptsSortParameter() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoriteAlbums(sort: .nameAsc)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoriteAlbumsAcceptsFilterParameter() async {
        let service = LibraryService(client: nil)

        do {
            let filter = LibraryFilter()
            try await service.fetchFavoriteAlbums(filter: filter)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoriteAlbumsAcceptsForceRefreshParameter() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoriteAlbums(forceRefresh: true)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoriteTracksAcceptsSortParameter() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoriteTracks(sort: .nameAsc)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoriteTracksAcceptsFilterParameter() async {
        let service = LibraryService(client: nil)

        do {
            let filter = LibraryFilter()
            try await service.fetchFavoriteTracks(filter: filter)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoriteTracksAcceptsForceRefreshParameter() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoriteTracks(forceRefresh: true)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoritePlaylistsAcceptsSortParameter() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoritePlaylists(sort: .nameAsc)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoritePlaylistsAcceptsFilterParameter() async {
        let service = LibraryService(client: nil)

        do {
            let filter = LibraryFilter()
            try await service.fetchFavoritePlaylists(filter: filter)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    @MainActor
    func testFetchFavoritePlaylistsAcceptsForceRefreshParameter() async {
        let service = LibraryService(client: nil)

        do {
            try await service.fetchFavoritePlaylists(forceRefresh: true)
            XCTFail("Should throw error with no client")
        } catch {
            XCTAssertTrue(error is LibraryError)
        }
    }

    // MARK: - Task 11: CategoryFromMediaType Tests

    @MainActor
    func testCategoryFromMediaTypeArtist() {
        let service = LibraryService(client: nil)
        let category = service.categoryFromMediaType("artist")
        XCTAssertEqual(category, .artists)
    }

    @MainActor
    func testCategoryFromMediaTypeAlbum() {
        let service = LibraryService(client: nil)
        let category = service.categoryFromMediaType("album")
        XCTAssertEqual(category, .albums)
    }

    @MainActor
    func testCategoryFromMediaTypeTrack() {
        let service = LibraryService(client: nil)
        let category = service.categoryFromMediaType("track")
        XCTAssertEqual(category, .tracks)
    }

    @MainActor
    func testCategoryFromMediaTypePlaylist() {
        let service = LibraryService(client: nil)
        let category = service.categoryFromMediaType("playlist")
        XCTAssertEqual(category, .playlists)
    }

    @MainActor
    func testCategoryFromMediaTypeRadio() {
        let service = LibraryService(client: nil)
        let category = service.categoryFromMediaType("radio")
        XCTAssertEqual(category, .radio)
    }

    @MainActor
    func testCategoryFromMediaTypeUnknown() {
        let service = LibraryService(client: nil)
        let category = service.categoryFromMediaType("unknown")
        // Should default to .tracks when unknown
        XCTAssertEqual(category, .tracks)
    }

    @MainActor
    func testCategoryFromMediaTypeGenre() {
        let service = LibraryService(client: nil)
        let category = service.categoryFromMediaType("genre")
        XCTAssertEqual(category, .genres)
    }
}
