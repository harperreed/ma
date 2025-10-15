// ABOUTME: Utility for parsing Music Assistant event data into app models
// ABOUTME: Handles extraction of track metadata, playback state, progress, and volume from event dictionaries

import Foundation
import MusicAssistantKit

enum EventParser {
    // MARK: - Supporting Types

    struct GroupStatus {
        let isGrouped: Bool
        let childIds: [String]
    }

    // MARK: - Shared Parsing Utilities

    static func parseDuration(from value: Any?) -> Double {
        if let duration = value as? Double {
            return duration
        } else if let duration = value as? Int {
            return Double(duration)
        }
        return 0.0
    }

    // MARK: - Event Parsing

    static func parseTrack(from data: [String: AnyCodable]) -> Track? {
        guard let currentMediaWrapper = data["current_media"],
              let currentMedia = currentMediaWrapper.value as? [String: Any]
        else {
            return nil
        }

        // Music Assistant API uses "name" for track title, not "title"
        let title = currentMedia["name"] as? String ?? currentMedia["title"] as? String ?? "Unknown Track"

        // Music Assistant API uses "artists" (plural array) not "artist" (singular string)
        let artist: String
        if let artistsArray = currentMedia["artists"] as? [[String: Any]], !artistsArray.isEmpty {
            // Extract artist names from array of artist objects
            let artistNames = artistsArray.compactMap { $0["name"] as? String }
            if !artistNames.isEmpty {
                artist = artistNames.joined(separator: ", ")
            } else {
                artist = "Unknown Artist"
            }
        } else if let artistString = currentMedia["artist"] as? String {
            // Fallback to singular "artist" if present
            artist = artistString
        } else {
            artist = "Unknown Artist"
        }

        let album: String
        if let albumDict = currentMedia["album"] as? [String: Any], let albumName = albumDict["name"] as? String {
            album = albumName
        } else if let albumString = currentMedia["album"] as? String {
            album = albumString
        } else {
            album = "Unknown Album"
        }

        let duration = parseDuration(from: currentMedia["duration"])

        var artworkURL: URL?
        if let imageURLString = currentMedia["image_url"] as? String {
            artworkURL = URL(string: imageURLString)
        }

        // Generate unique ID from available data
        let id = (currentMedia["uri"] as? String) ?? UUID().uuidString

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
        guard let progressWrapper = data["elapsed_time"] else {
            return 0.0
        }

        // elapsed_time can be Int or Double
        if let progressInt = progressWrapper.value as? Int {
            return Double(progressInt)
        } else if let progressDouble = progressWrapper.value as? Double {
            return progressDouble
        }

        return 0.0
    }

    static func parseVolume(from data: [String: AnyCodable]) -> Double {
        guard let volumeWrapper = data["volume_level"] else {
            return 50.0 // Default to 50% if not present
        }

        // volume_level can be Int or Double
        if let volumeInt = volumeWrapper.value as? Int {
            return Double(volumeInt)
        } else if let volumeDouble = volumeWrapper.value as? Double {
            return volumeDouble
        }

        return 50.0
    }

    static func parseShuffleState(from data: [String: AnyCodable]) -> Bool {
        if let shuffle = data["shuffle"]?.value as? Bool {
            return shuffle
        }
        // Also check queue_settings if present
        if let queueSettingsWrapper = data["queue_settings"],
           let queueSettings = queueSettingsWrapper.value as? [String: Any],
           let shuffle = queueSettings["shuffle"] as? Bool {
            return shuffle
        }
        return false
    }

    static func parseRepeatMode(from data: [String: AnyCodable]) -> String {
        if let repeatMode = data["repeat"]?.value as? String {
            return repeatMode
        }
        // Also check queue_settings if present
        if let queueSettingsWrapper = data["queue_settings"],
           let queueSettings = queueSettingsWrapper.value as? [String: Any],
           let repeatMode = queueSettings["repeat"] as? String {
            return repeatMode
        }
        return "off"
    }

    static func parseGroupStatus(from data: [String: AnyCodable]) -> GroupStatus {
        if let childIds = data["group_childs"]?.value as? [String], !childIds.isEmpty {
            return GroupStatus(isGrouped: true, childIds: childIds)
        }
        return GroupStatus(isGrouped: false, childIds: [])
    }

    static func parseQueueItems(from data: [String: AnyCodable]) -> [Track] {
        guard let itemsWrapper = data["items"],
              let items = itemsWrapper.value as? [[String: Any]]
        else {
            return []
        }

        return items.enumerated().compactMap { arrayIndex, item in
            // Queue items have track data nested under "media_item" or directly on the item
            let mediaItem = item["media_item"] as? [String: Any] ?? item["media"] as? [String: Any] ?? item

            // Music Assistant API uses "name" for track title, not "title"
            let title = mediaItem["name"] as? String ?? mediaItem["title"] as? String ?? "Unknown Track"

            // Music Assistant API uses "artists" (plural array) not "artist" (singular string)
            let artist: String
            if let artistsArray = mediaItem["artists"] as? [[String: Any]], !artistsArray.isEmpty {
                // Extract artist names from array of artist objects
                let artistNames = artistsArray.compactMap { $0["name"] as? String }
                if !artistNames.isEmpty {
                    artist = artistNames.joined(separator: ", ")
                } else {
                    artist = "Unknown Artist"
                }
            } else if let artistString = mediaItem["artist"] as? String {
                // Fallback to singular "artist" if present
                artist = artistString
            } else {
                artist = "Unknown Artist"
            }

            let album: String
            if let albumDict = mediaItem["album"] as? [String: Any], let albumName = albumDict["name"] as? String {
                album = albumName
            } else if let albumString = mediaItem["album"] as? String {
                album = albumString
            } else {
                album = "Unknown Album"
            }

            let duration = parseDuration(from: mediaItem["duration"])

            var artworkURL: URL?
            if let imageURLString = mediaItem["image_url"] as? String {
                artworkURL = URL(string: imageURLString)
            }

            let id = (mediaItem["uri"] as? String) ?? (item["queue_item_id"] as? String) ?? UUID().uuidString

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
