// ABOUTME: Utility for parsing Music Assistant event data into app models
// ABOUTME: Handles extraction of track metadata, playback state, and progress from event dictionaries

import Foundation
import MusicAssistantKit

enum EventParser {
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

        let title = currentMedia["title"] as? String ?? "Unknown Track"
        let artist = currentMedia["artist"] as? String ?? "Unknown Artist"
        let album = currentMedia["album"] as? String ?? "Unknown Album"
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

    static func parseQueueItems(from data: [String: AnyCodable]) -> [Track] {
        guard let itemsWrapper = data["items"],
              let items = itemsWrapper.value as? [[String: Any]]
        else {
            return []
        }

        return items.compactMap { item in
            let title = item["title"] as? String ?? "Unknown Track"
            let artist = item["artist"] as? String ?? "Unknown Artist"
            let album = item["album"] as? String ?? "Unknown Album"
            let duration = parseDuration(from: item["duration"])

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
