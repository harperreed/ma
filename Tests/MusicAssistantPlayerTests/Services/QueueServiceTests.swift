// ABOUTME: Unit tests for QueueService
// ABOUTME: Validates queue state management and track ordering

import XCTest
import Combine
@testable import MusicAssistantPlayer

final class QueueServiceTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let service = QueueService()

        XCTAssertTrue(service.upcomingTracks.isEmpty)
        XCTAssertNil(service.queueId)
    }

    @MainActor
    func testClientInjection() async {
        let service = QueueService(client: nil)
        XCTAssertNotNil(service)
    }

    @MainActor
    func testClearQueue() async throws {
        let service = QueueService(client: nil)
        service.queueId = "test-queue"

        do {
            try await service.clearQueue()
            XCTFail("Should throw error when client is nil")
        } catch let error as QueueError {
            XCTAssertTrue(error.localizedDescription.contains("Network error"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testClearQueueWithoutQueueId() async {
        let service = QueueService(client: nil)

        do {
            try await service.clearQueue()
            XCTFail("Should throw error when queueId is nil")
        } catch let error as QueueError {
            XCTAssertTrue(error.localizedDescription.contains("Queue not found"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testShuffle() async throws {
        let service = QueueService(client: nil)
        service.queueId = "test-queue"

        do {
            try await service.shuffle(enabled: true)
            XCTFail("Should throw error when client is nil")
        } catch let error as QueueError {
            XCTAssertTrue(error.localizedDescription.contains("Network error"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testShuffleWithoutQueueId() async {
        let service = QueueService(client: nil)

        do {
            try await service.shuffle(enabled: true)
            XCTFail("Should throw error when queueId is nil")
        } catch let error as QueueError {
            XCTAssertTrue(error.localizedDescription.contains("Queue not found"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testSetRepeatMode() async throws {
        let service = QueueService(client: nil)
        service.queueId = "test-queue"

        do {
            try await service.setRepeat(mode: "all")
            XCTFail("Should throw error when client is nil")
        } catch let error as QueueError {
            XCTAssertTrue(error.localizedDescription.contains("Network error"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testSetRepeatModeWithoutQueueId() async {
        let service = QueueService(client: nil)

        do {
            try await service.setRepeat(mode: "all")
            XCTFail("Should throw error when queueId is nil")
        } catch let error as QueueError {
            XCTAssertTrue(error.localizedDescription.contains("Queue not found"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testTotalDuration() {
        let service = QueueService()
        service.upcomingTracks = [
            Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
            Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 200, artworkURL: nil),
            Track(id: "3", title: "Track 3", artist: "Artist", album: "Album", duration: 120, artworkURL: nil)
        ]

        XCTAssertEqual(service.totalDuration, 500)
    }

    @MainActor
    func testFormattedTotalDuration() {
        let service = QueueService()
        service.upcomingTracks = [
            Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
            Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 3600, artworkURL: nil)
        ]

        XCTAssertEqual(service.formattedTotalDuration, "1:03:00")
    }

    @MainActor
    func testTrackCount() {
        let service = QueueService()
        service.upcomingTracks = [
            Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
            Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 200, artworkURL: nil)
        ]

        XCTAssertEqual(service.trackCount, 2)
    }
}
