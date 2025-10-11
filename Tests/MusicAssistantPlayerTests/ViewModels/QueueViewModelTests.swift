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
}
