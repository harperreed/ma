// ABOUTME: Unit tests for EventParser
// ABOUTME: Validates parsing of Music Assistant event data into app models

import XCTest
import MusicAssistantKit
@testable import MusicAssistantPlayer

final class EventParserTests: XCTestCase {
    func testParseTrackFromPlayerEvent() {
        let eventData: [String: AnyCodable] = [
            "current_media": AnyCodable([
                "title": "Bohemian Rhapsody",
                "artist": "Queen",
                "album": "A Night at the Opera",
                "duration": 354,
                "image_url": "https://example.com/album-art.jpg"
            ] as [String: Any])
        ]

        let track = EventParser.parseTrack(from: eventData, serverHost: "192.168.200.113")

        XCTAssertEqual(track?.title, "Bohemian Rhapsody")
        XCTAssertEqual(track?.artist, "Queen")
        XCTAssertEqual(track?.album, "A Night at the Opera")
        XCTAssertEqual(track?.duration, 354.0)
        XCTAssertEqual(track?.artworkURL?.absoluteString, "https://example.com/album-art.jpg")
    }

    func testParsePlaybackState() {
        let playingData: [String: AnyCodable] = ["state": AnyCodable("playing")]
        XCTAssertEqual(EventParser.parsePlaybackState(from: playingData), .playing)

        let pausedData: [String: AnyCodable] = ["state": AnyCodable("paused")]
        XCTAssertEqual(EventParser.parsePlaybackState(from: pausedData), .paused)

        let stoppedData: [String: AnyCodable] = ["state": AnyCodable("idle")]
        XCTAssertEqual(EventParser.parsePlaybackState(from: stoppedData), .stopped)
    }

    func testParseProgress() {
        let eventData: [String: AnyCodable] = ["elapsed_time": AnyCodable(125.5)]
        let progress = EventParser.parseProgress(from: eventData)

        XCTAssertEqual(progress, 125.5)
    }
}
