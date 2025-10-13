import XCTest
@testable import MusicAssistantPlayer

final class QueueErrorTests: XCTestCase {
    func testQueueErrorLocalizedDescription() {
        let error = QueueError.queueNotFound("test-queue-id")
        XCTAssertTrue(error.localizedDescription.contains("test-queue-id"))
    }

    func testCommandFailedError() {
        let error = QueueError.commandFailed("shuffle", reason: "network timeout")
        XCTAssertTrue(error.localizedDescription.contains("shuffle"))
        XCTAssertTrue(error.localizedDescription.contains("network timeout"))
    }
}
