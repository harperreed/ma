// ABOUTME: Utility for parsing Music Assistant event data into app models
// ABOUTME: Handles extraction of track metadata, playback state, and progress from event dictionaries

import Foundation
import MusicAssistantKit

enum EventParser {
    static func parseTrack(from data: [String: AnyCodable], serverHost: String, port: Int = 8095) -> Track? {
        guard let currentItemWrapper = data["current_item"],
              let currentItem = currentItemWrapper.value as? [String: Any]
        else {
            return nil
        }

        let title = currentItem["name"] as? String ?? "Unknown Track"
        let artist = currentItem["artist"] as? String ?? "Unknown Artist"
        let album = currentItem["album"] as? String ?? "Unknown Album"
        let duration = currentItem["duration"] as? Double ?? 0.0

        var artworkURL: URL?
        if let imagePath = currentItem["image"] as? String {
            artworkURL = URL(string: "http://\(serverHost):\(port)\(imagePath)")
        }

        // Generate unique ID from available data
        let id = (currentItem["uri"] as? String) ?? UUID().uuidString

        return Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artworkURL: artworkURL
        )
    }

    static func parsePlaybackState(from data: [String: AnyCodable]) -> PlaybackState {
        guard let stateWrapper = data["state"],
              let stateString = stateWrapper.value as? String
        else {
            return .stopped
        }

        switch stateString.lowercased() {
        case "playing":
            return .playing
        case "paused":
            return .paused
        default:
            return .stopped
        }
    }

    static func parseProgress(from data: [String: AnyCodable]) -> TimeInterval {
        guard let progressWrapper = data["elapsed_time"],
              let progress = progressWrapper.value as? Double
        else {
            return 0.0
        }
        return progress
    }

    static func parseQueueItems(from data: [String: AnyCodable], serverHost: String, port: Int = 8095) -> [Track] {
        guard let itemsWrapper = data["items"],
              let items = itemsWrapper.value as? [[String: Any]]
        else {
            return []
        }

        return items.compactMap { item in
            let title = item["name"] as? String ?? "Unknown Track"
            let artist = item["artist"] as? String ?? "Unknown Artist"
            let album = item["album"] as? String ?? "Unknown Album"
            let duration = item["duration"] as? Double ?? 0.0

            var artworkURL: URL?
            if let imagePath = item["image"] as? String {
                artworkURL = URL(string: "http://\(serverHost):\(port)\(imagePath)")
            }

            let id = (item["uri"] as? String) ?? UUID().uuidString

            return Track(
                id: id,
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                artworkURL: artworkURL
            )
        }
    }
}
