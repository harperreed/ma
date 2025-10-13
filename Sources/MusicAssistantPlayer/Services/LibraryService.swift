// ABOUTME: Service for fetching and managing Music Assistant library content
// ABOUTME: Provides methods to fetch artists, albums, tracks, playlists, and perform playback actions

import Foundation
import MusicAssistantKit
import Combine

@MainActor
class LibraryService: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var albums: [Album] = []
    @Published var playlists: [Playlist] = []
    @Published var error: String?

    private(set) var client: MusicAssistantClient?

    init(client: MusicAssistantClient?) {
        self.client = client
    }

    // MARK: - Task 6: Fetch Artists

    func fetchArtists() async throws {
        guard let client = client else {
            self.error = "No client available"
            throw NSError(domain: "LibraryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No client available"])
        }

        do {
            // Music Assistant API: music/artists/library_items
            let result = try await client.sendCommand(command: "music/artists/library_items")

            if let result = result {
                let parsedArtists = parseArtists(from: result)
                self.artists = parsedArtists
                self.error = nil
            } else {
                self.artists = []
                self.error = nil
            }
        } catch {
            self.error = "Failed to fetch artists: \(error.localizedDescription)"
            throw error
        }
    }

    private func parseArtists(from data: AnyCodable) -> [Artist] {
        guard let items = data.value as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item in
            guard let id = item["item_id"] as? String,
                  let name = item["name"] as? String
            else {
                return nil
            }

            let artworkURL: URL?
            if let metadata = item["metadata"] as? [String: Any],
               let imageURLString = metadata["image"] as? String {
                artworkURL = URL(string: imageURLString)
            } else {
                artworkURL = nil
            }

            // Album count might not be in the response, defaulting to 0
            let albumCount = item["album_count"] as? Int ?? 0

            return Artist(
                id: id,
                name: name,
                artworkURL: artworkURL,
                albumCount: albumCount
            )
        }
    }

    // Methods to be added in subsequent tasks:
    // - fetchAlbums(for artistId: String?)
    // - fetchTracks(for albumId: String)
    // - fetchPlaylists()
    // - playNow(item:on:)
    // - addToQueue(item:for:)
}
