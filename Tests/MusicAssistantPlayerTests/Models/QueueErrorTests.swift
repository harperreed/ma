// ABOUTME: Tests for queue operation error types and user-facing messages
// ABOUTME: Verifies error descriptions are user-friendly and actionable

import XCTest
@testable import MusicAssistantPlayer

final class QueueErrorTests: XCTestCase {
    func testNetworkFailureErrorDescription() {
        let error = QueueError.networkFailure
        XCTAssertEqual(error.userMessage, "Network connection failed. Check your connection and try again.")
    }

    func testQueueEmptyErrorDescription() {
        let error = QueueError.queueEmpty
        XCTAssertEqual(error.userMessage, "Queue is empty.")
    }

    func testUnknownErrorDescription() {
        let error = QueueError.unknown("Something went wrong")
        XCTAssertEqual(error.userMessage, "An error occurred: Something went wrong")
    }

    func testEquatableNetworkFailure() {
        XCTAssertEqual(QueueError.networkFailure, QueueError.networkFailure)
    }

    func testEquatableQueueEmpty() {
        XCTAssertEqual(QueueError.queueEmpty, QueueError.queueEmpty)
    }

    func testEquatableUnknown() {
        XCTAssertEqual(QueueError.unknown("test"), QueueError.unknown("test"))
        XCTAssertNotEqual(QueueError.unknown("test1"), QueueError.unknown("test2"))
    }

    func testNotEqualDifferentCases() {
        XCTAssertNotEqual(QueueError.networkFailure, QueueError.queueEmpty)
    }
}
