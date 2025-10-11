// ABOUTME: Unit tests for PlayerService
// ABOUTME: Validates player state management and MusicAssistantKit integration

import XCTest
import Combine
@testable import MusicAssistantPlayer

final class PlayerServiceTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    @MainActor
    func testInitialState() {
        let service = PlayerService()

        XCTAssertNil(service.currentTrack)
        XCTAssertEqual(service.playbackState, .stopped)
        XCTAssertEqual(service.progress, 0.0)
        XCTAssertNil(service.selectedPlayer)
    }
}
