// ABOUTME: Application-specific error types with user-facing messages
// ABOUTME: Wraps underlying errors and provides context for UI display

import Foundation

enum PlayerError: Error, Equatable {
    case networkError(String)
    case commandFailed(String, reason: String)
    case invalidConfiguration(String)
    case parseError(String)
    case playerNotFound(String)

    var userMessage: String {
        switch self {
        case .networkError:
            return "Unable to connect to the server. Please check your connection."
        case .commandFailed(let command, _):
            return "Unable to \(command). The player may be offline."
        case .invalidConfiguration:
            return "Server configuration is invalid. Please check your settings."
        case .parseError:
            return "Unable to process server response. The server may need updating."
        case .playerNotFound:
            return "Player not found. Please select a different player."
        }
    }

    var technicalDetails: String {
        switch self {
        case .networkError(let details),
             .invalidConfiguration(let details),
             .parseError(let details),
             .playerNotFound(let details):
            return details
        case .commandFailed(let command, let reason):
            return "Command '\(command)' failed: \(reason)"
        }
    }

    static func == (lhs: PlayerError, rhs: PlayerError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let a), .networkError(let b)),
             (.invalidConfiguration(let a), .invalidConfiguration(let b)),
             (.parseError(let a), .parseError(let b)),
             (.playerNotFound(let a), .playerNotFound(let b)):
            return a == b
        case (.commandFailed(let cmd1, let reason1), .commandFailed(let cmd2, let reason2)):
            return cmd1 == cmd2 && reason1 == reason2
        default:
            return false
        }
    }
}
