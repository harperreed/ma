// ABOUTME: Structured logging utility using os.Logger for macOS
// ABOUTME: Provides category-based loggers with consistent formatting

import Foundation
import os.log

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.musicassistant.player"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let player = Logger(subsystem: subsystem, category: "player")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let cache = Logger(subsystem: subsystem, category: "cache")
    static let errors = Logger(subsystem: subsystem, category: "errors")
    static let intents = Logger(subsystem: subsystem, category: "intents")
}

// MARK: - Convenience Extensions

extension Logger {
    func logError(_ error: Error, context: String) {
        self.error("\(context): \(error.localizedDescription)")
    }

    func logPlayerError(_ error: PlayerError, context: String) {
        self.error("\(context): \(error.userMessage) - \(error.technicalDetails)")
    }
}
