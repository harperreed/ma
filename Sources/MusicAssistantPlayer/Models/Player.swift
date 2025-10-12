// ABOUTME: Player model representing a Music Assistant playback device
// ABOUTME: Tracks device identity, active state, and grouping information for multi-room control

import Foundation

enum PlayerType: String, Codable {
    case player
    case group
}

struct Player: Identifiable, Equatable {
    let id: String
    let name: String
    let isActive: Bool
    let type: PlayerType
    let groupChildIds: [String]  // For groups: IDs of child players
    let syncedTo: String?  // For players: ID of group they're synced to
    let activeGroup: String?  // Active group ID if applicable

    var isGroup: Bool {
        type == .group
    }

    var isSynced: Bool {
        syncedTo != nil
    }
}
