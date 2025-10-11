// ABOUTME: Player model representing a Music Assistant playback device
// ABOUTME: Tracks device identity and active state for multi-room control

import Foundation

struct Player: Identifiable, Equatable {
    let id: String
    let name: String
    let isActive: Bool
}
