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
}
