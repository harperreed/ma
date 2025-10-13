// ABOUTME: Playback state enumeration for player status
// ABOUTME: Represents playing, paused, stopped states with simple enum

import Foundation

enum PlaybackState: Equatable, CustomStringConvertible {
    case playing
    case paused
    case stopped

    var description: String {
        switch self {
        case .playing: return "playing"
        case .paused: return "paused"
        case .stopped: return "stopped"
        }
    }
}
