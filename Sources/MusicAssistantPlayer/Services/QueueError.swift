// ABOUTME: Domain-specific errors for queue operations
// ABOUTME: Provides detailed error context for queue management failures

import Foundation

enum QueueError: Error, LocalizedError {
    case queueNotFound(String)
    case itemNotFound(String)
    case networkError(String)
    case commandFailed(String, reason: String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .queueNotFound(let queueId):
            return "Queue not found: \(queueId)"
        case .itemNotFound(let itemId):
            return "Queue item not found: \(itemId)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .commandFailed(let command, let reason):
            return "Queue command '\(command)' failed: \(reason)"
        case .parseError(let message):
            return "Failed to parse queue data: \(message)"
        }
    }
}
