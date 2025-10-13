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

    // Methods will be added in subsequent tasks:
    // - fetchArtists()
    // - fetchAlbums(for artistId: String?)
    // - fetchTracks(for albumId: String)
    // - fetchPlaylists()
    // - playNow(item:on:)
    // - addToQueue(item:for:)
}
