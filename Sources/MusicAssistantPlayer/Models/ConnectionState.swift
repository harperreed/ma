// ABOUTME: Connection state enumeration for Music Assistant server status
// ABOUTME: Tracks disconnected, connecting, connected, reconnecting, and error states

import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error(String)

    var isConnected: Bool {
        self == .connected
    }

    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
