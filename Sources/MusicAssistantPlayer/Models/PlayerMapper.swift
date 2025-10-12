// ABOUTME: Utility for mapping Music Assistant player data to app Player model
// ABOUTME: Handles parsing player list responses into typed Player objects

import Foundation
import MusicAssistantKit

enum PlayerMapper {
    static func parsePlayer(from data: [String: Any]) -> Player? {
        guard let playerId = data["player_id"] as? String ?? data["id"] as? String,
              let name = data["name"] as? String ?? data["display_name"] as? String
        else {
            return nil
        }

        let isActive = (data["state"] as? String) == "playing" || (data["powered"] as? Bool) == true

        // Parse player type
        let typeString = data["type"] as? String ?? "player"
        let type = PlayerType(rawValue: typeString) ?? .player

        // Parse group children (for groups)
        let groupChildIds = data["group_childs"] as? [String] ?? []

        // Parse synced_to (for players synced to a group)
        let syncedTo: String?
        if let syncedToValue = data["synced_to"] {
            // Check if it's NSNull
            if syncedToValue is NSNull {
                syncedTo = nil
            } else {
                syncedTo = syncedToValue as? String
            }
        } else {
            syncedTo = nil
        }

        // Parse active_group
        let activeGroup: String?
        if let activeGroupValue = data["active_group"] {
            if activeGroupValue is NSNull {
                activeGroup = nil
            } else {
                activeGroup = activeGroupValue as? String
            }
        } else {
            activeGroup = nil
        }

        return Player(
            id: playerId,
            name: name,
            isActive: isActive,
            type: type,
            groupChildIds: groupChildIds,
            syncedTo: syncedTo,
            activeGroup: activeGroup
        )
    }

    static func parsePlayers(from result: AnyCodable?) -> [Player] {
        guard let result = result else {
            return []
        }

        // Try to parse as array of dictionaries
        if let players = result.value as? [[String: Any]] {
            return players.compactMap { parsePlayer(from: $0) }
        }

        // Try to parse as dictionary containing players array
        if let dict = result.value as? [String: Any],
           let players = dict["players"] as? [[String: Any]] {
            return players.compactMap { parsePlayer(from: $0) }
        }

        return []
    }
}
