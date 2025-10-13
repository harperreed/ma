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
