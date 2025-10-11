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

    @MainActor
    func testConnectionState() async {
        let service = PlayerService(client: nil)

        XCTAssertEqual(service.connectionState, .disconnected)
    }

    @MainActor
    func testClientInjection() async {
        // Mock client would go here - for now just test that it accepts optional client
        let service = PlayerService(client: nil)
        XCTAssertNotNil(service)
    }
}
