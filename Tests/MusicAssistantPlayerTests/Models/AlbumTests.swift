// ABOUTME: Unit tests for Album model testing initialization and optional fields
// ABOUTME: Verifies Album model correctly handles metadata including artwork, year, and track count

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
            duration: 3600.0,
            albumType: .album
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
            duration: 0.0,
            albumType: .album
        )

        XCTAssertNil(album.artworkURL)
        XCTAssertNil(album.year)
    }
}
