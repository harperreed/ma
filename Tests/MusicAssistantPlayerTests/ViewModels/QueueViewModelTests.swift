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

    @MainActor
    func testShuffleStateBindsToPlayerService() {
        let playerService = PlayerService(client: nil)
        let queueService = QueueService(client: nil)
        let viewModel = QueueViewModel(queueService: queueService, playerService: playerService)

        // Initially false
        XCTAssertFalse(viewModel.isShuffled)

        // Update PlayerService state
        playerService.isShuffled = true

        // Should propagate to ViewModel
        XCTAssertTrue(viewModel.isShuffled)
    }

    @MainActor
    func testRepeatModeBindsToPlayerService() {
        let playerService = PlayerService(client: nil)
        let queueService = QueueService(client: nil)
        let viewModel = QueueViewModel(queueService: queueService, playerService: playerService)

        // Initially "off"
        XCTAssertEqual(viewModel.repeatMode, "off")

        // Update PlayerService state
        playerService.repeatMode = "all"

        // Should propagate to ViewModel
        XCTAssertEqual(viewModel.repeatMode, "all")

        playerService.repeatMode = "one"
        XCTAssertEqual(viewModel.repeatMode, "one")
    }

    @MainActor
    func testToggleShuffleCallsPlayerService() async {
        let playerService = PlayerService(client: nil)
        let queueService = QueueService(client: nil)
        let viewModel = QueueViewModel(queueService: queueService, playerService: playerService)

        // Initially false
        XCTAssertFalse(viewModel.isShuffled)

        // Toggle shuffle (will fail due to no client, but method is called)
        await viewModel.toggleShuffle()

        // PlayerService rollback happens when there's no client
        // The important thing is the method was called
        // In real usage with a client, the state would persist
        XCTAssertFalse(playerService.isShuffled) // Rolled back due to no client
        XCTAssertNotNil(playerService.lastError) // Error was set
    }

    @MainActor
    func testCycleRepeatModeCallsPlayerService() async {
        let playerService = PlayerService(client: nil)
        let queueService = QueueService(client: nil)
        let viewModel = QueueViewModel(queueService: queueService, playerService: playerService)

        // Initially "off"
        XCTAssertEqual(viewModel.repeatMode, "off")

        // Cycle: off -> all (will rollback due to no client)
        await viewModel.cycleRepeatMode()
        // Rolled back due to no client
        XCTAssertEqual(playerService.repeatMode, "off")
        XCTAssertNotNil(playerService.lastError)

        // The method itself works correctly - rollback is expected behavior when client is nil
    }
}
