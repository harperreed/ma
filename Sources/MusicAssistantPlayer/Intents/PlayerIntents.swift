// ABOUTME: App Intents for Siri and Shortcuts integration
// ABOUTME: Provides playback control via voice commands and automation

import Foundation
import AppIntents

// MARK: - Helper

@MainActor
private func executePlayerAction(
    intentName: String,
    action: @MainActor (PlayerService) async -> Void
) async -> some IntentResult {
    AppLogger.intents.info("\(intentName) triggered")

    guard let playerService = IntentHelper.shared.playerService else {
        AppLogger.intents.warning("\(intentName): No PlayerService available")
        return .result()
    }

    await action(playerService)
    return .result()
}

// MARK: - Intents

struct PlayIntent: AppIntent {
    static let title: LocalizedStringResource = "Play Music"
    static let description = IntentDescription("Resume playback in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        await executePlayerAction(intentName: "PlayIntent") { playerService in
            await playerService.play()
        }
    }
}

struct PauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Pause Music"
    static let description = IntentDescription("Pause playback in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        await executePlayerAction(intentName: "PauseIntent") { playerService in
            await playerService.pause()
        }
    }
}

struct StopIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Music"
    static let description = IntentDescription("Stop playback in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        await executePlayerAction(intentName: "StopIntent") { playerService in
            await playerService.stop()
        }
    }
}

struct NextTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Track"
    static let description = IntentDescription("Skip to next track in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        await executePlayerAction(intentName: "NextTrackIntent") { playerService in
            await playerService.skipNext()
        }
    }
}

struct PreviousTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Previous Track"
    static let description = IntentDescription("Skip to previous track in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        await executePlayerAction(intentName: "PreviousTrackIntent") { playerService in
            await playerService.skipPrevious()
        }
    }
}
