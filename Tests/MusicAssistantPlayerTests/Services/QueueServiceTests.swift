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

    @MainActor
    func testClientInjection() async {
        let service = QueueService(client: nil)
        XCTAssertNotNil(service)
    }

    @MainActor
    func testClearQueue() async throws {
        let service = QueueService(client: nil)
        service.queueId = "test-queue"

        do {
            try await service.clearQueue()
            XCTFail("Should throw error when client is nil")
        } catch let error as QueueError {
            XCTAssertEqual(error, .networkFailure)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testClearQueueWithoutQueueId() async {
        let service = QueueService(client: nil)

        do {
            try await service.clearQueue()
            XCTFail("Should throw error when queueId is nil")
        } catch let error as QueueError {
            XCTAssertEqual(error, .queueEmpty)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testShuffle() async throws {
        let service = QueueService(client: nil)
        service.queueId = "test-queue"

        do {
            try await service.shuffle(enabled: true)
            XCTFail("Should throw error when client is nil")
        } catch let error as QueueError {
            XCTAssertEqual(error, .networkFailure)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testShuffleWithoutQueueId() async {
        let service = QueueService(client: nil)

        do {
            try await service.shuffle(enabled: true)
            XCTFail("Should throw error when queueId is nil")
        } catch let error as QueueError {
            XCTAssertEqual(error, .queueEmpty)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testSetRepeatMode() async throws {
        let service = QueueService(client: nil)
        service.queueId = "test-queue"

        do {
            try await service.setRepeat(mode: "all")
            XCTFail("Should throw error when client is nil")
        } catch let error as QueueError {
            XCTAssertEqual(error, .networkFailure)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    @MainActor
    func testSetRepeatModeWithoutQueueId() async {
        let service = QueueService(client: nil)

        do {
            try await service.setRepeat(mode: "all")
            XCTFail("Should throw error when queueId is nil")
        } catch let error as QueueError {
            XCTAssertEqual(error, .queueEmpty)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
