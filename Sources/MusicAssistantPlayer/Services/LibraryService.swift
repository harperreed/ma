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
    @Published var tracks: [Track] = []
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

    // MARK: - Task 7: Fetch Albums

    func fetchAlbums(for artistId: String? = nil) async throws {
        guard let client = client else {
            self.error = "No client available"
            throw NSError(domain: "LibraryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No client available"])
        }

        do {
            // Music Assistant API: music/albums/library_items
            // If artistId is provided, we can filter by artist
            let result: AnyCodable?
            if let artistId = artistId {
                // Fetch albums for specific artist
                result = try await client.sendCommand(
                    command: "music/albums/library_items",
                    args: ["artist": artistId]
                )
            } else {
                // Fetch all albums
                result = try await client.sendCommand(command: "music/albums/library_items")
            }

            if let result = result {
                let parsedAlbums = parseAlbums(from: result)
                self.albums = parsedAlbums
                self.error = nil
            } else {
                self.albums = []
                self.error = nil
            }
        } catch {
            self.error = "Failed to fetch albums: \(error.localizedDescription)"
            throw error
        }
    }

    private func parseAlbums(from data: AnyCodable) -> [Album] {
        guard let items = data.value as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item in
            guard let id = item["item_id"] as? String,
                  let title = item["name"] as? String
            else {
                return nil
            }

            // Extract artist name - could be a string or array of artist objects
            let artist: String
            if let artistName = item["artist"] as? String {
                artist = artistName
            } else if let artists = item["artists"] as? [[String: Any]],
                      let firstArtist = artists.first,
                      let artistName = firstArtist["name"] as? String {
                artist = artistName
            } else {
                artist = "Unknown Artist"
            }

            let artworkURL: URL?
            if let metadata = item["metadata"] as? [String: Any],
               let imageURLString = metadata["image"] as? String {
                artworkURL = URL(string: imageURLString)
            } else {
                artworkURL = nil
            }

            let trackCount = item["track_count"] as? Int ?? 0
            let year = item["year"] as? Int
            let duration = item["duration"] as? Double ?? 0.0

            return Album(
                id: id,
                title: title,
                artist: artist,
                artworkURL: artworkURL,
                trackCount: trackCount,
                year: year,
                duration: duration
            )
        }
    }

    // MARK: - Task 8: Fetch Playlists

    func fetchPlaylists() async throws {
        guard let client = client else {
            self.error = "No client available"
            throw NSError(domain: "LibraryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No client available"])
        }

        do {
            // Music Assistant API: music/playlists/library_items
            let result = try await client.sendCommand(command: "music/playlists/library_items")

            if let result = result {
                let parsedPlaylists = parsePlaylists(from: result)
                self.playlists = parsedPlaylists
                self.error = nil
            } else {
                self.playlists = []
                self.error = nil
            }
        } catch {
            self.error = "Failed to fetch playlists: \(error.localizedDescription)"
            throw error
        }
    }

    private func parsePlaylists(from data: AnyCodable) -> [Playlist] {
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

            let trackCount = item["track_count"] as? Int ?? 0
            let duration = item["duration"] as? Double ?? 0.0
            let owner = item["owner"] as? String

            return Playlist(
                id: id,
                name: name,
                artworkURL: artworkURL,
                trackCount: trackCount,
                duration: duration,
                owner: owner
            )
        }
    }

    // MARK: - Fetch Tracks

    func fetchTracks(for albumId: String? = nil) async throws {
        guard let client = client else {
            self.error = "No client available"
            throw NSError(domain: "LibraryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No client available"])
        }

        do {
            // Music Assistant API: music/tracks/library_items
            let result: AnyCodable?
            if let albumId = albumId {
                // Fetch tracks for specific album
                result = try await client.sendCommand(
                    command: "music/tracks/library_items",
                    args: ["album": albumId]
                )
            } else {
                // Fetch all tracks
                result = try await client.sendCommand(command: "music/tracks/library_items")
            }

            if let result = result {
                let parsedTracks = parseTracks(from: result)
                self.tracks = parsedTracks
                self.error = nil
            } else {
                self.tracks = []
                self.error = nil
            }
        } catch {
            self.error = "Failed to fetch tracks: \(error.localizedDescription)"
            throw error
        }
    }

    private func parseTracks(from data: AnyCodable) -> [Track] {
        guard let items = data.value as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item in
            guard let id = item["item_id"] as? String,
                  let title = item["name"] as? String
            else {
                return nil
            }

            // Extract artist name
            let artist: String
            if let artistName = item["artist"] as? String {
                artist = artistName
            } else if let artists = item["artists"] as? [[String: Any]],
                      let firstArtist = artists.first,
                      let artistName = firstArtist["name"] as? String {
                artist = artistName
            } else {
                artist = "Unknown Artist"
            }

            // Extract album name
            let album: String
            if let albumDict = item["album"] as? [String: Any],
               let albumName = albumDict["name"] as? String {
                album = albumName
            } else if let albumName = item["album"] as? String {
                album = albumName
            } else {
                album = "Unknown Album"
            }

            let artworkURL: URL?
            if let metadata = item["metadata"] as? [String: Any],
               let imageURLString = metadata["image"] as? String {
                artworkURL = URL(string: imageURLString)
            } else {
                artworkURL = nil
            }

            let duration = item["duration"] as? Double ?? 0.0

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

    // Methods to be added in subsequent tasks:
    // - playNow(item:on:)
    // - addToQueue(item:for:)
}
