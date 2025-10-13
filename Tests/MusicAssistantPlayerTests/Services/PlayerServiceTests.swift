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

    @MainActor
    func testEventSubscriptionCancellation() async {
        let service = PlayerService(client: nil)

        // Start subscription - creates task even with nil client (exits early)
        service.subscribeToPlayerEvents()

        // Verify task is created
        XCTAssertNotNil(service.eventTask)

        // Store reference to first task
        let firstTask = service.eventTask

        // Now test that calling subscribeToPlayerEvents() again
        // properly cancels the existing task and creates a new one
        service.subscribeToPlayerEvents()

        // Wait a moment for cancellation to propagate
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Verify first task was cancelled
        XCTAssertTrue(firstTask?.isCancelled ?? false)

        // Verify new task was created
        XCTAssertNotNil(service.eventTask)

        // Verify service is still functional
        XCTAssertNotNil(service)
        XCTAssertEqual(service.connectionState, .disconnected)
    }
}
