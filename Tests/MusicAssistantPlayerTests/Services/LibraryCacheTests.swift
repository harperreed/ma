// Tests/MusicAssistantPlayerTests/Services/LibraryCacheTests.swift
import XCTest
@testable import MusicAssistantPlayer

final class LibraryCacheTests: XCTestCase {
    @MainActor
    func testCacheStoresAndRetrievesArtists() {
        let cache = LibraryCache()
        let artists = [
            Artist(id: "1", name: "Test Artist", artworkURL: nil, albumCount: 5)
        ]

        cache.set(artists, forKey: "artists")

        let retrieved: [Artist]? = cache.get(forKey: "artists")
        XCTAssertEqual(retrieved?.count, 1)
        XCTAssertEqual(retrieved?.first?.name, "Test Artist")
    }

    @MainActor
    func testCacheExpiresAfterTTL() async {
        let cache = LibraryCache(ttl: 0.1) // 100ms TTL
        let artists = [
            Artist(id: "1", name: "Test Artist", artworkURL: nil, albumCount: 5)
        ]

        cache.set(artists, forKey: "artists")

        // Wait for expiration
        try? await Task.sleep(for: .milliseconds(150))

        let retrieved: [Artist]? = cache.get(forKey: "artists")
        XCTAssertNil(retrieved)
    }

    @MainActor
    func testCacheReturnsNilForNonExistentKey() {
        let cache = LibraryCache()

        let retrieved: [Artist]? = cache.get(forKey: "nonexistent")
        XCTAssertNil(retrieved)
    }

    @MainActor
    func testCacheClearRemovesAllEntries() {
        let cache = LibraryCache()
        let artists = [
            Artist(id: "1", name: "Test Artist", artworkURL: nil, albumCount: 5)
        ]
        let albums = [
            Album(id: "1", title: "Test Album", artist: "Test Artist", artworkURL: nil, trackCount: 10, year: 2023, duration: 3600.0)
        ]

        cache.set(artists, forKey: "artists")
        cache.set(albums, forKey: "albums")

        cache.clear()

        let retrievedArtists: [Artist]? = cache.get(forKey: "artists")
        let retrievedAlbums: [Album]? = cache.get(forKey: "albums")
        XCTAssertNil(retrievedArtists)
        XCTAssertNil(retrievedAlbums)
    }

    @MainActor
    func testCacheRemoveRemovesSpecificKey() {
        let cache = LibraryCache()
        let artists = [
            Artist(id: "1", name: "Test Artist", artworkURL: nil, albumCount: 5)
        ]
        let albums = [
            Album(id: "1", title: "Test Album", artist: "Test Artist", artworkURL: nil, trackCount: 10, year: 2023, duration: 3600.0)
        ]

        cache.set(artists, forKey: "artists")
        cache.set(albums, forKey: "albums")

        cache.remove(forKey: "artists")

        let retrievedArtists: [Artist]? = cache.get(forKey: "artists")
        let retrievedAlbums: [Album]? = cache.get(forKey: "albums")
        XCTAssertNil(retrievedArtists)
        XCTAssertNotNil(retrievedAlbums)
    }

    @MainActor
    func testCacheStoresAndRetrievesTracks() {
        let cache = LibraryCache()
        let tracks = [
            Track(id: "1", title: "Test Track", artist: "Test Artist", album: "Test Album", duration: 180.0, artworkURL: nil)
        ]

        cache.set(tracks, forKey: "tracks")

        let retrieved: [Track]? = cache.get(forKey: "tracks")
        XCTAssertEqual(retrieved?.count, 1)
        XCTAssertEqual(retrieved?.first?.title, "Test Track")
    }
}
