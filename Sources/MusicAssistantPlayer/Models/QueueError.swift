// ABOUTME: Error types for queue operations with user-friendly messages
// ABOUTME: Translates technical errors into actionable UI feedback

import Foundation

enum QueueError: LocalizedError, Equatable {
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

    static func == (lhs: QueueError, rhs: QueueError) -> Bool {
        switch (lhs, rhs) {
        case (.networkFailure, .networkFailure),
             (.queueEmpty, .queueEmpty):
            return true
        case (.unknown(let a), .unknown(let b)):
            return a == b
        default:
            return false
        }
    }
}
