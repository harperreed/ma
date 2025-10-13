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

        let track = EventParser.parseTrack(from: eventData)

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

    // MARK: - Malformed Data Tests

    func testParseMalformedTrackData() {
        let malformedData: [String: AnyCodable] = [
            "current_media": AnyCodable("invalid string instead of dict")
        ]

        let track = EventParser.parseTrack(from: malformedData)
        XCTAssertNil(track, "Should return nil for malformed data")
    }

    func testParseTrackWithMissingFields() {
        let incompleteData: [String: AnyCodable] = [
            "current_media": AnyCodable([
                "uri": "test:uri"
                // Missing name, artists, etc.
            ] as [String: Any])
        ]

        let track = EventParser.parseTrack(from: incompleteData)
        // Should handle gracefully with default values
        XCTAssertNotNil(track)
        XCTAssertEqual(track?.title, "Unknown Track")
        XCTAssertEqual(track?.artist, "Unknown Artist")
        XCTAssertEqual(track?.album, "Unknown Album")
        XCTAssertEqual(track?.duration, 0.0)
    }

    func testParseProgressWithInvalidData() {
        let invalidData: [String: AnyCodable] = [
            "elapsed_time": AnyCodable("not a number")
        ]

        let progress = EventParser.parseProgress(from: invalidData)
        XCTAssertEqual(progress, 0.0, "Should return 0.0 for invalid progress data")
    }

    func testParseProgressWithMissingData() {
        let emptyData: [String: AnyCodable] = [:]

        let progress = EventParser.parseProgress(from: emptyData)
        XCTAssertEqual(progress, 0.0, "Should return 0.0 for missing progress data")
    }

    func testParseTrackWithNoCurrentMedia() {
        let emptyData: [String: AnyCodable] = [:]

        let track = EventParser.parseTrack(from: emptyData)
        XCTAssertNil(track, "Should return nil when current_media is missing")
    }

    func testParsePlaybackStateWithInvalidData() {
        let invalidData: [String: AnyCodable] = [
            "state": AnyCodable(123) // number instead of string
        ]

        let state = EventParser.parsePlaybackState(from: invalidData)
        XCTAssertEqual(state, .stopped, "Should default to stopped for invalid state data")
    }

    func testParsePlaybackStateWithMissingData() {
        let emptyData: [String: AnyCodable] = [:]

        let state = EventParser.parsePlaybackState(from: emptyData)
        XCTAssertEqual(state, .stopped, "Should default to stopped for missing state data")
    }

    func testParsePlaybackStateWithUnknownValue() {
        let unknownData: [String: AnyCodable] = [
            "state": AnyCodable("buffering") // unknown state
        ]

        let state = EventParser.parsePlaybackState(from: unknownData)
        XCTAssertEqual(state, .stopped, "Should default to stopped for unknown state values")
    }

    func testParseTrackWithInvalidDuration() {
        let eventData: [String: AnyCodable] = [
            "current_media": AnyCodable([
                "title": "Test Track",
                "artist": "Test Artist",
                "album": "Test Album",
                "duration": "invalid string duration"
            ] as [String: Any])
        ]

        let track = EventParser.parseTrack(from: eventData)
        XCTAssertNotNil(track)
        XCTAssertEqual(track?.duration, 0.0, "Should default to 0.0 for invalid duration")
    }

    func testParseTrackWithInvalidArtworkURL() {
        let eventData: [String: AnyCodable] = [
            "current_media": AnyCodable([
                "title": "Test Track",
                "artist": "Test Artist",
                "album": "Test Album",
                "duration": 180,
                "image_url": "not a valid url scheme://invalid"
            ] as [String: Any])
        ]

        let track = EventParser.parseTrack(from: eventData)
        XCTAssertNotNil(track)
        // URL init will fail for invalid URLs, so artworkURL should be nil
        XCTAssertNil(track?.artworkURL, "Should be nil for invalid URL strings")
    }

    func testParseQueueItemsWithNestedMediaItem() {
        let queueData: [String: AnyCodable] = [
            "items": AnyCodable([
                [
                    "queue_item_id": "queue-1",
                    "media_item": [
                        "title": "Test Track 1",
                        "artist": "Test Artist 1",
                        "album": "Test Album 1",
                        "duration": 180,
                        "uri": "test:uri:1",
                        "image_url": "https://example.com/art1.jpg"
                    ]
                ],
                [
                    "queue_item_id": "queue-2",
                    "media_item": [
                        "title": "Test Track 2",
                        "artist": "Test Artist 2",
                        "album": "Test Album 2",
                        "duration": 240,
                        "uri": "test:uri:2"
                    ]
                ]
            ] as [[String: Any]])
        ]

        let queueItems = EventParser.parseQueueItems(from: queueData)
        XCTAssertEqual(queueItems.count, 2, "Should parse 2 queue items")

        XCTAssertEqual(queueItems[0].title, "Test Track 1")
        XCTAssertEqual(queueItems[0].artist, "Test Artist 1")
        XCTAssertEqual(queueItems[0].album, "Test Album 1")
        XCTAssertEqual(queueItems[0].duration, 180.0)
        XCTAssertEqual(queueItems[0].artworkURL?.absoluteString, "https://example.com/art1.jpg")

        XCTAssertEqual(queueItems[1].title, "Test Track 2")
        XCTAssertEqual(queueItems[1].artist, "Test Artist 2")
        XCTAssertEqual(queueItems[1].duration, 240.0)
        XCTAssertNil(queueItems[1].artworkURL, "Should be nil when image_url is missing")
    }

    func testParseQueueItemsWithEmptyArray() {
        let emptyQueueData: [String: AnyCodable] = [
            "items": AnyCodable([])
        ]

        let queueItems = EventParser.parseQueueItems(from: emptyQueueData)
        XCTAssertEqual(queueItems.count, 0, "Should return empty array for empty queue")
    }

    func testParseQueueItemsWithMissingData() {
        let missingData: [String: AnyCodable] = [:]

        let queueItems = EventParser.parseQueueItems(from: missingData)
        XCTAssertEqual(queueItems.count, 0, "Should return empty array when items is missing")
    }

    func testParseQueueItemsWithInvalidData() {
        let invalidData: [String: AnyCodable] = [
            "items": AnyCodable("not an array")
        ]

        let queueItems = EventParser.parseQueueItems(from: invalidData)
        XCTAssertEqual(queueItems.count, 0, "Should return empty array for invalid items data")
    }

    func testParseProgressWithIntValue() {
        let intData: [String: AnyCodable] = [
            "elapsed_time": AnyCodable(42)
        ]

        let progress = EventParser.parseProgress(from: intData)
        XCTAssertEqual(progress, 42.0, "Should convert Int to Double correctly")
    }

    func testParseTrackDurationWithIntValue() {
        let eventData: [String: AnyCodable] = [
            "current_media": AnyCodable([
                "title": "Test Track",
                "duration": 180 // Int instead of Double
            ] as [String: Any])
        ]

        let track = EventParser.parseTrack(from: eventData)
        XCTAssertNotNil(track)
        XCTAssertEqual(track?.duration, 180.0, "Should convert Int duration to Double")
    }

    // MARK: - Shared Duration Parsing Tests

    func testParseDuration() {
        // Test with Double value
        let validDuration = EventParser.parseDuration(from: 354.5)
        XCTAssertEqual(validDuration, 354.5, "Should parse Double duration correctly")

        // Test with Int value
        let intDuration = EventParser.parseDuration(from: 180)
        XCTAssertEqual(intDuration, 180.0, "Should convert Int duration to Double")

        // Test with nil value
        let zeroDuration = EventParser.parseDuration(from: nil)
        XCTAssertEqual(zeroDuration, 0.0, "Should return 0.0 for nil duration")

        // Test with invalid type
        let invalidDuration = EventParser.parseDuration(from: "not a number")
        XCTAssertEqual(invalidDuration, 0.0, "Should return 0.0 for invalid duration type")
    }
}
