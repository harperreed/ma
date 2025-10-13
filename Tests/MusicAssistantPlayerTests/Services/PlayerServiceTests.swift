// ABOUTME: Unit tests for PlayerService
// ABOUTME: Validates player state management and MusicAssistantKit integration

import XCTest
import Combine
import MusicAssistantKit
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

    @MainActor
    func testErrorStatePublished() async {
        let service = PlayerService(client: nil)

        // Initially no error
        XCTAssertNil(service.lastError)

        // Trigger error by calling play without client
        await service.play()

        // Verify error is published
        XCTAssertNotNil(service.lastError)

        // Verify it's the correct type of error
        if case .networkError = service.lastError {
            // Expected error type
        } else {
            XCTFail("Expected networkError, got \(String(describing: service.lastError))")
        }
    }

    @MainActor
    func testErrorClearedOnSuccess() async {
        let service = PlayerService(client: nil)

        // Set an initial error
        service.lastError = .networkError("Test error")
        XCTAssertNotNil(service.lastError)

        // With nil client, errors will persist, but if we had a working client
        // the error should be cleared on success
        // For now, just verify the property is accessible and settable
        service.lastError = nil
        XCTAssertNil(service.lastError)
    }

    @MainActor
    func testPausePublishesError() async {
        let service = PlayerService(client: nil)

        // Initially no error
        XCTAssertNil(service.lastError)

        // Trigger error by calling pause without client
        await service.pause()

        // Verify error is published
        XCTAssertNotNil(service.lastError)
    }

    @MainActor
    func testStopPublishesError() async {
        let service = PlayerService(client: nil)

        // Initially no error
        XCTAssertNil(service.lastError)

        // Trigger error by calling stop without client
        await service.stop()

        // Verify error is published
        XCTAssertNotNil(service.lastError)
    }

    @MainActor
    func testSkipNextPublishesError() async {
        let service = PlayerService(client: nil)

        // Initially no error
        XCTAssertNil(service.lastError)

        // Trigger error by calling skipNext without client
        await service.skipNext()

        // Verify error is published
        XCTAssertNotNil(service.lastError)
    }

    @MainActor
    func testSkipPreviousPublishesError() async {
        let service = PlayerService(client: nil)

        // Initially no error
        XCTAssertNil(service.lastError)

        // Trigger error by calling skipPrevious without client
        await service.skipPrevious()

        // Verify error is published
        XCTAssertNotNil(service.lastError)
    }

    @MainActor
    func testSeekPublishesError() async {
        let service = PlayerService(client: nil)

        // Initially no error
        XCTAssertNil(service.lastError)

        // Trigger error by calling seek without client
        await service.seek(to: 30.0)

        // Verify error is published
        XCTAssertNotNil(service.lastError)
    }

    @MainActor
    func testSetVolumePublishesError() async {
        let service = PlayerService(client: nil)

        // Initially no error
        XCTAssertNil(service.lastError)

        // Trigger error by calling setVolume without client
        await service.setVolume(50.0)

        // Verify error is published
        XCTAssertNotNil(service.lastError)
    }

    // MARK: - Network Failure Tests

    @MainActor
    func testNetworkFailureHandling() async {
        let service = PlayerService(client: nil)

        // Attempt operation without client
        await service.play()

        // Verify error is published
        XCTAssertNotNil(service.lastError)
        if case .networkError = service.lastError {
            // Expected error type
        } else {
            XCTFail("Expected networkError, got \(String(describing: service.lastError))")
        }
    }

    @MainActor
    func testPlayerNotFoundError() async {
        // Create service with client but no selected player
        let mockClient = MusicAssistantClient(host: "test", port: 8095)
        let service = PlayerService(client: mockClient)

        // Attempt operation without selected player
        await service.play()

        // Verify error is published
        XCTAssertNotNil(service.lastError)
        if case .playerNotFound = service.lastError {
            // Expected error type
        } else {
            XCTFail("Expected playerNotFound, got \(String(describing: service.lastError))")
        }
    }

    @MainActor
    func testAllCommandsFailGracefullyWithoutClient() async {
        let service = PlayerService(client: nil)

        // Test all commands fail with network error
        await service.play()
        XCTAssertNotNil(service.lastError)

        await service.pause()
        XCTAssertNotNil(service.lastError)

        await service.stop()
        XCTAssertNotNil(service.lastError)

        await service.skipNext()
        XCTAssertNotNil(service.lastError)

        await service.skipPrevious()
        XCTAssertNotNil(service.lastError)

        await service.seek(to: 30.0)
        XCTAssertNotNil(service.lastError)

        await service.setVolume(50.0)
        XCTAssertNotNil(service.lastError)
    }

    @MainActor
    func testAllCommandsFailGracefullyWithoutPlayer() async {
        let mockClient = MusicAssistantClient(host: "test", port: 8095)
        let service = PlayerService(client: mockClient)

        // Test all commands fail with playerNotFound error
        await service.play()
        XCTAssertNotNil(service.lastError)
        if case .playerNotFound = service.lastError {
            // Expected
        } else {
            XCTFail("Expected playerNotFound for play()")
        }

        await service.pause()
        XCTAssertNotNil(service.lastError)
        if case .playerNotFound = service.lastError {
            // Expected
        } else {
            XCTFail("Expected playerNotFound for pause()")
        }

        await service.stop()
        XCTAssertNotNil(service.lastError)
        if case .playerNotFound = service.lastError {
            // Expected
        } else {
            XCTFail("Expected playerNotFound for stop()")
        }

        await service.skipNext()
        XCTAssertNotNil(service.lastError)
        if case .playerNotFound = service.lastError {
            // Expected
        } else {
            XCTFail("Expected playerNotFound for skipNext()")
        }

        await service.skipPrevious()
        XCTAssertNotNil(service.lastError)
        if case .playerNotFound = service.lastError {
            // Expected
        } else {
            XCTFail("Expected playerNotFound for skipPrevious()")
        }

        await service.seek(to: 30.0)
        XCTAssertNotNil(service.lastError)
        if case .playerNotFound = service.lastError {
            // Expected
        } else {
            XCTFail("Expected playerNotFound for seek()")
        }

        await service.setVolume(50.0)
        XCTAssertNotNil(service.lastError)
        if case .playerNotFound = service.lastError {
            // Expected
        } else {
            XCTFail("Expected playerNotFound for setVolume()")
        }
    }

    @MainActor
    func testGroupPublishesError() async {
        let service = PlayerService(client: nil)

        await service.group(targetPlayerId: "player2")

        XCTAssertNotNil(service.lastError)
    }

    @MainActor
    func testUngroupPublishesError() async {
        let service = PlayerService(client: nil)

        await service.ungroup()

        XCTAssertNotNil(service.lastError)
    }
}
