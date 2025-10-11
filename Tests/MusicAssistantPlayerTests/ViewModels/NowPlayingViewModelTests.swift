// ABOUTME: Unit tests for NowPlayingViewModel
// ABOUTME: Validates view state derivation from PlayerService

import XCTest
import Combine
@testable import MusicAssistantPlayer

final class NowPlayingViewModelTests: XCTestCase {
    var playerService: PlayerService!
    var cancellables: Set<AnyCancellable> = []

    @MainActor
    override func setUp() {
        super.setUp()
        playerService = PlayerService()
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    @MainActor
    func testInitialization() {
        let viewModel = NowPlayingViewModel(playerService: playerService)

        XCTAssertEqual(viewModel.trackTitle, "No Track Playing")
        XCTAssertEqual(viewModel.artistName, "")
        XCTAssertEqual(viewModel.albumName, "")
        XCTAssertFalse(viewModel.isPlaying)
    }

    @MainActor
    func testTrackDisplayWhenPlaying() {
        let track = Track(
            id: "1",
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            artworkURL: nil
        )

        playerService.currentTrack = track
        playerService.playbackState = .playing

        let viewModel = NowPlayingViewModel(playerService: playerService)

        XCTAssertEqual(viewModel.trackTitle, "Test Song")
        XCTAssertEqual(viewModel.artistName, "Test Artist")
        XCTAssertEqual(viewModel.albumName, "Test Album")
        XCTAssertTrue(viewModel.isPlaying)
    }
}
