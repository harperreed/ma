// ABOUTME: Unit tests for QueueViewModel
// ABOUTME: Validates queue display and track ordering

import XCTest
@testable import MusicAssistantPlayer

final class QueueViewModelTests: XCTestCase {
    var queueService: QueueService!

    @MainActor
    override func setUp() {
        super.setUp()
        queueService = QueueService()
    }

    @MainActor
    func testInitialization() {
        let viewModel = QueueViewModel(queueService: queueService)

        XCTAssertTrue(viewModel.tracks.isEmpty)
    }

    @MainActor
    func testTracksFromService() {
        let tracks = [
            Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
            Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 200, artworkURL: nil)
        ]

        queueService.upcomingTracks = tracks
        let viewModel = QueueViewModel(queueService: queueService)

        XCTAssertEqual(viewModel.tracks.count, 2)
        XCTAssertEqual(viewModel.tracks[0].title, "Track 1")
    }

    @MainActor
    func testClearQueue() async {
        let service = QueueService(client: nil)
        service.queueId = "test-queue"
        let viewModel = QueueViewModel(queueService: service)

        do {
            try await viewModel.clearQueue()
            XCTFail("Should throw error when client is nil")
        } catch let error as QueueError {
            // Expected - should throw network error
            XCTAssertTrue(error.localizedDescription.contains("Network error"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testClearQueueErrorHandling() async {
        let service = QueueService(client: nil)
        let viewModel = QueueViewModel(queueService: service)

        do {
            try await viewModel.clearQueue()
            XCTFail("Should throw error")
        } catch {
            // Expected
        }
    }

    @MainActor
    func testShuffle() async {
        let service = QueueService(client: nil)
        service.queueId = "test-queue"
        let viewModel = QueueViewModel(queueService: service)

        do {
            try await viewModel.shuffle(enabled: true)
            XCTFail("Should throw error when client is nil")
        } catch let error as QueueError {
            XCTAssertTrue(error.localizedDescription.contains("Network error"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testSetRepeat() async {
        let service = QueueService(client: nil)
        service.queueId = "test-queue"
        let viewModel = QueueViewModel(queueService: service)

        do {
            try await viewModel.setRepeat(mode: "one")
            XCTFail("Should throw error when client is nil")
        } catch let error as QueueError {
            XCTAssertTrue(error.localizedDescription.contains("Network error"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testQueueStatistics() {
        let service = QueueService()
        service.upcomingTracks = [
            Track(id: "1", title: "Track 1", artist: "Artist", album: "Album", duration: 180, artworkURL: nil),
            Track(id: "2", title: "Track 2", artist: "Artist", album: "Album", duration: 200, artworkURL: nil)
        ]
        let viewModel = QueueViewModel(queueService: service)

        XCTAssertEqual(viewModel.trackCount, 2)
        XCTAssertEqual(viewModel.totalDuration, "6:20")
    }
}
