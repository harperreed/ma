// ABOUTME: App Intents for Siri and Shortcuts integration
// ABOUTME: Provides playback control via voice commands and automation

import Foundation
import AppIntents

struct PlayIntent: AppIntent {
    static let title: LocalizedStringResource = "Play Music"
    static let description = IntentDescription("Resume playback in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("PlayIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("PlayIntent: No PlayerService available")
            return .result()
        }

        await playerService.play()
        return .result()
    }
}

struct PauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Pause Music"
    static let description = IntentDescription("Pause playback in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("PauseIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("PauseIntent: No PlayerService available")
            return .result()
        }

        await playerService.pause()
        return .result()
    }
}

struct StopIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Music"
    static let description = IntentDescription("Stop playback in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("StopIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("StopIntent: No PlayerService available")
            return .result()
        }

        await playerService.stop()
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Track"
    static let description = IntentDescription("Skip to next track in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("NextTrackIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("NextTrackIntent: No PlayerService available")
            return .result()
        }

        await playerService.skipNext()
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Previous Track"
    static let description = IntentDescription("Skip to previous track in Music Assistant Player")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.intents.info("PreviousTrackIntent triggered")

        guard let playerService = IntentHelper.shared.playerService else {
            AppLogger.intents.warning("PreviousTrackIntent: No PlayerService available")
            return .result()
        }

        await playerService.skipPrevious()
        return .result()
    }
}
