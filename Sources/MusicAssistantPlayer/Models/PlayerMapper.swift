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

        return Player(id: playerId, name: name, isActive: isActive)
    }

    static func parsePlayers(from result: AnyCodable?) -> [Player] {
        guard let result = result,
              let players = result.value as? [[String: Any]]
        else {
            return []
        }

        return players.compactMap { parsePlayer(from: $0) }
    }
}
