// ABOUTME: Utility for parsing Music Assistant event data into app models
// ABOUTME: Handles extraction of track metadata, playback state, and progress from event dictionaries

import Foundation
import MusicAssistantKit

enum EventParser {
    static func parseTrack(from data: [String: AnyCodable], serverHost: String, port: Int = 8095) -> Track? {
        guard let currentMediaWrapper = data["current_media"],
              let currentMedia = currentMediaWrapper.value as? [String: Any]
        else {
            return nil
        }

        let title = currentMedia["title"] as? String ?? "Unknown Track"
        let artist = currentMedia["artist"] as? String ?? "Unknown Artist"
        let album = currentMedia["album"] as? String ?? "Unknown Album"

        // Duration can be Int or Double
        let duration: Double
        if let durationInt = currentMedia["duration"] as? Int {
            duration = Double(durationInt)
        } else if let durationDouble = currentMedia["duration"] as? Double {
            duration = durationDouble
        } else {
            duration = 0.0
        }

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

    static func parseQueueItems(from data: [String: AnyCodable], serverHost: String, port: Int = 8095) -> [Track] {
        guard let itemsWrapper = data["items"],
              let items = itemsWrapper.value as? [[String: Any]]
        else {
            return []
        }

        return items.compactMap { item in
            let title = item["title"] as? String ?? "Unknown Track"
            let artist = item["artist"] as? String ?? "Unknown Artist"
            let album = item["album"] as? String ?? "Unknown Album"

            // Duration can be Int or Double
            let duration: Double
            if let durationInt = item["duration"] as? Int {
                duration = Double(durationInt)
            } else if let durationDouble = item["duration"] as? Double {
                duration = durationDouble
            } else {
                duration = 0.0
            }

            var artworkURL: URL?
            if let imageURLString = item["image_url"] as? String {
                artworkURL = URL(string: imageURLString)
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
