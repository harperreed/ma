// ABOUTME: Unit tests for Track model
// ABOUTME: Validates track metadata parsing and display formatting

import XCTest
@testable import MusicAssistantPlayer

final class TrackTests: XCTestCase {
    func testTrackInitialization() {
        let track = Track(
            id: "track_123",
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera",
            duration: 354.0,
            artworkURL: URL(string: "https://example.com/art.jpg")
        )

        XCTAssertEqual(track.id, "track_123")
        XCTAssertEqual(track.title, "Bohemian Rhapsody")
        XCTAssertEqual(track.artist, "Queen")
        XCTAssertEqual(track.album, "A Night at the Opera")
        XCTAssertEqual(track.duration, 354.0)
    }

    func testFormattedDuration() {
        let track = Track(
            id: "1",
            title: "Test",
            artist: "Artist",
            album: "Album",
            duration: 125.0,
            artworkURL: nil
        )

        XCTAssertEqual(track.formattedDuration, "2:05")
    }
}
