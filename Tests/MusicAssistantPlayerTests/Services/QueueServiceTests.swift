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
}
