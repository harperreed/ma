// ABOUTME: Error types for queue operations with user-friendly messages
// ABOUTME: Translates technical errors into actionable UI feedback

import Foundation

enum QueueError: LocalizedError {
    case networkFailure
    case queueEmpty
    case unknown(String)

    var userMessage: String {
        switch self {
        case .networkFailure:
            return "Network connection failed. Check your connection and try again."
        case .queueEmpty:
            return "Queue is empty."
        case .unknown(let message):
            return "An error occurred: \(message)"
        }
    }

    var errorDescription: String? {
        userMessage
    }
}
