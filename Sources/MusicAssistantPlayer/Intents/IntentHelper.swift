// ABOUTME: Singleton bridge between AppIntents and PlayerService
// ABOUTME: Provides shared access to PlayerService for Siri/Shortcuts integration

import Foundation

@MainActor
class IntentHelper {
    static let shared = IntentHelper()

    // Weak reference to avoid retain cycles
    weak var playerService: PlayerService?

    private init() {
        AppLogger.intents.info("IntentHelper initialized")
    }

    /// Wire PlayerService to IntentHelper for Siri/Shortcuts integration.
    /// Must be called synchronously on the main actor during app startup before intents can be delivered.
    func setup(playerService: PlayerService) {
        self.playerService = playerService
        AppLogger.intents.info("PlayerService wired to IntentHelper")
    }
}
