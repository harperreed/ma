// ABOUTME: Service for fetching and managing Music Assistant library content
// ABOUTME: Provides methods to fetch artists, albums, tracks, playlists, and perform playback actions

import Foundation
import MusicAssistantKit
import Combine
import os.log

@MainActor
class LibraryService: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var albums: [Album] = []
    @Published var playlists: [Playlist] = []
    @Published var tracks: [Track] = []
    @Published var radios: [Radio] = []
    @Published var genres: [Genre] = []
    @Published var providers: [String] = []
    @Published var lastError: LibraryError?
    @Published var hasMoreItems: Bool = false
    @Published var currentOffset: Int = 0
    @Published var currentSort: LibrarySortOption = .nameAsc
    @Published var currentFilter: LibraryFilter = LibraryFilter()
    @Published var hydrationProgress: Double? = nil // nil = not running, 0.0-1.0 = progress
    @Published var hydrationStatus: String? = nil // Status message
    private let pageSize: Int = 50
    let cache = LibraryCache(ttl: 3600) // 1 hour TTL for regular cache, Public for ViewModel access to hydrated cache

    private(set) var client: MusicAssistantClient?

    init(client: MusicAssistantClient?) {
        self.client = client
    }

    // MARK: - Library Hydration

    /// Invalidate hydration cache to force fresh download
    func invalidateHydrationCache() {
        let cacheKey = "hydrated_library_artists"
        cache.remove(forKey: cacheKey)
        print("🗑️ [LibraryService] Hydration cache invalidated")
    }

    /// Background hydration - runs asynchronously without blocking UI
    func hydrateLibraryInBackground(forceRefresh: Bool = false) async {
        // Check if we have cached hydrated data
        let cacheKey = "hydrated_library_artists"
        if !forceRefresh, cache.get(forKey: cacheKey) as [Artist]? != nil {
            print("✅ [LibraryService] Hydrated data already cached, skipping background hydration")
            return
        }

        print("🔄 [LibraryService] Starting background library hydration...")

        await MainActor.run {
            self.hydrationProgress = 0.0
            self.hydrationStatus = "Starting..."
        }

        do {
            guard let client = client else {
                print("❌ [LibraryService] No client available for background hydration")
                await MainActor.run {
                    self.hydrationProgress = nil
                    self.hydrationStatus = nil
                }
                return
            }

            // Fetch all albums in background
            var allAlbums: [Album] = []
            var albumOffset = 0
            let fetchLimit = 200
            var hasMore = true
            var batchCount = 0

            await MainActor.run {
                self.hydrationStatus = "Loading albums..."
            }

            while hasMore { // No limit - fetch all albums
                let result = try await client.sendCommand(
                    command: "music/albums/library_items",
                    args: [
                        "limit": fetchLimit,
                        "offset": albumOffset,
                        "order_by": "name"
                    ]
                )

                if let result = result {
                    let batch = parseAlbums(from: result)
                    allAlbums.append(contentsOf: batch)
                    albumOffset += batch.count
                    hasMore = batch.count == fetchLimit
                    batchCount += 1

                    // Update progress (albums = 50% of total work)
                    let albumProgress = min(Double(batchCount) / 50.0, 1.0) * 0.5
                    await MainActor.run {
                        self.hydrationProgress = albumProgress
                        self.hydrationStatus = "Loading albums (\(allAlbums.count))..."
                    }

                    print("📦 [LibraryService] Background: fetched \(allAlbums.count) albums so far...")
                } else {
                    hasMore = false
                }
            }

            print("✅ [LibraryService] Background: fetched \(allAlbums.count) total albums")

            // Build artist -> album count mapping
            var artistAlbumCounts: [String: Int] = [:]
            for album in allAlbums {
                artistAlbumCounts[album.artist, default: 0] += 1
            }

            // Fetch all artists
            var allArtists: [Artist] = []
            var artistOffset = 0
            hasMore = true
            batchCount = 0

            await MainActor.run {
                self.hydrationStatus = "Loading artists..."
            }

            while hasMore { // No limit - fetch all artists
                let result = try await client.sendCommand(
                    command: "music/artists/library_items",
                    args: [
                        "limit": fetchLimit,
                        "offset": artistOffset,
                        "order_by": "name"
                    ]
                )

                if let result = result {
                    let batch = parseArtists(from: result)
                    allArtists.append(contentsOf: batch)
                    artistOffset += batch.count
                    hasMore = batch.count == fetchLimit
                    batchCount += 1

                    // Update progress (artists = remaining 50% of work)
                    let artistProgress = 0.5 + (min(Double(batchCount) / 25.0, 1.0) * 0.5)
                    await MainActor.run {
                        self.hydrationProgress = artistProgress
                        self.hydrationStatus = "Loading artists (\(allArtists.count))..."
                    }

                    print("👤 [LibraryService] Background: fetched \(allArtists.count) artists so far...")
                } else {
                    hasMore = false
                }
            }

            print("✅ [LibraryService] Background: fetched \(allArtists.count) total artists")

            // Hydrate artists with album counts
            let hydratedArtists = allArtists.map { artist in
                let albumCount = artistAlbumCounts[artist.name] ?? 0
                return Artist(
                    id: artist.id,
                    name: artist.name,
                    artworkURL: artist.artworkURL,
                    albumCount: albumCount
                )
            }

            // Cache the results
            cache.set(hydratedArtists, forKey: cacheKey)
            print("✅ [LibraryService] Background hydration complete! Cached \(hydratedArtists.count) artists with album counts")

            // Update UI if we're on the artists view
            await MainActor.run {
                self.hydrationProgress = 1.0
                self.hydrationStatus = "Complete!"

                if self.artists.isEmpty || self.artists.allSatisfy({ $0.albumCount == 0 }) {
                    self.artists = hydratedArtists
                    print("🔄 [LibraryService] Updated UI with hydrated artists")
                }

                // Clear progress after a moment
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    await MainActor.run {
                        self.hydrationProgress = nil
                        self.hydrationStatus = nil
                    }
                }
            }

        } catch {
            print("❌ [LibraryService] Background hydration error: \(error.localizedDescription)")
            await MainActor.run {
                self.hydrationProgress = nil
                self.hydrationStatus = "Failed"
            }
        }
    }

    func hydrateLibrary(forceRefresh: Bool = false) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            AppLogger.network.error("❌ Hydration failed: no client available")
            throw error
        }

        // Check if we have cached hydrated data
        let cacheKey = "hydrated_library_artists"
        if !forceRefresh, let cached: [Artist] = cache.get(forKey: cacheKey) {
            AppLogger.network.info("✅ Using cached hydrated library data (\(cached.count) artists)")
            self.artists = cached
            return
        }

        do {
            print("🔄 [LibraryService] Starting library hydration...")
            AppLogger.network.info("🔄 Starting library hydration...")

            // Fetch all albums to build artist -> album count mapping
            var allAlbums: [Album] = []
            var albumOffset = 0
            let fetchLimit = 200 // Larger batches for hydration
            var hasMore = true

            while hasMore {
                AppLogger.network.debug("Fetching albums batch: offset=\(albumOffset)")

                let result = try await client.sendCommand(
                    command: "music/albums/library_items",
                    args: [
                        "limit": fetchLimit,
                        "offset": albumOffset,
                        "order_by": "name"
                    ]
                )

                if let result = result {
                    let batch = parseAlbums(from: result)
                    allAlbums.append(contentsOf: batch)
                    albumOffset += batch.count
                    hasMore = batch.count == fetchLimit
                    AppLogger.network.debug("Fetched \(batch.count) albums, total: \(allAlbums.count)")
                } else {
                    AppLogger.network.warning("⚠️ Albums API returned nil, stopping album fetch")
                    hasMore = false
                }
            }

            AppLogger.network.info("✅ Fetched \(allAlbums.count) total albums")

            // Build artist ID -> album count mapping
            var artistAlbumCounts: [String: Int] = [:]
            for album in allAlbums {
                // Need to map album.artist (string) to artist IDs
                // This is a limitation - we'll count by artist name for now
                artistAlbumCounts[album.artist, default: 0] += 1
            }

            AppLogger.network.debug("Built album count map for \(artistAlbumCounts.count) unique artists")

            // Fetch all artists
            var allArtists: [Artist] = []
            var artistOffset = 0
            hasMore = true

            while hasMore {
                AppLogger.network.debug("Fetching artists batch: offset=\(artistOffset)")

                let result = try await client.sendCommand(
                    command: "music/artists/library_items",
                    args: [
                        "limit": fetchLimit,
                        "offset": artistOffset,
                        "order_by": "name"
                    ]
                )

                if let result = result {
                    let batch = parseArtists(from: result)
                    allArtists.append(contentsOf: batch)
                    artistOffset += batch.count
                    hasMore = batch.count == fetchLimit
                    AppLogger.network.debug("Fetched \(batch.count) artists, total: \(allArtists.count)")
                } else {
                    AppLogger.network.warning("⚠️ Artists API returned nil, stopping artist fetch")
                    hasMore = false
                }
            }

            AppLogger.network.info("✅ Fetched \(allArtists.count) total artists")

            // Hydrate artists with correct album counts
            let hydratedArtists = allArtists.map { artist in
                let albumCount = artistAlbumCounts[artist.name] ?? 0
                return Artist(
                    id: artist.id,
                    name: artist.name,
                    artworkURL: artist.artworkURL,
                    albumCount: albumCount
                )
            }

            print("✅ [LibraryService] Library hydration complete! \(hydratedArtists.count) artists with album counts")
            AppLogger.network.info("✅ Library hydration complete! \(hydratedArtists.count) artists with album counts")

            // Update state and cache
            self.artists = hydratedArtists
            cache.set(hydratedArtists, forKey: cacheKey)
            lastError = nil

        } catch let error as LibraryError {
            print("❌ [LibraryService] Hydration error (LibraryError): \(error.localizedDescription)")
            AppLogger.errors.logError(error, context: "hydrateLibrary")
            lastError = error
            throw error
        } catch {
            print("❌ [LibraryService] Hydration error (generic): \(error.localizedDescription)")
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "hydrateLibrary")
            lastError = libError
            throw libError
        }
    }

    // MARK: - Task 6: Fetch Artists (with Task 7 pagination and Task 8 sorting/filtering)

    func fetchArtists(
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Reset pagination if sort or filter changed
        if sortBy != currentSort || filterBy != currentFilter {
            currentOffset = 0
            hasMoreItems = false
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset

        // Build cache key from sort and filter parameters
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "artists_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Artist] = cache.get(forKey: cacheKey) {
            AppLogger.network.debug("Using cached artists (sort: \(sortBy.rawValue), filter: \(filterKey))")
            self.artists = cached
            return
        }

        do {
            var args: [String: Any] = [
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching artists: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            // Music Assistant API with pagination, sorting, and filtering
            let result = try await client.sendCommand(
                command: "music/artists/library_items",
                args: args
            )

            if let result = result {
                let parsedArtists = parseArtists(from: result)

                // Since class is @MainActor, we're already on MainActor
                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.artists = parsedArtists
                    // Cache first page results
                    cache.set(parsedArtists, forKey: cacheKey)
                } else {
                    // Subsequent pages - append
                    self.artists.append(contentsOf: parsedArtists)
                }

                // Update pagination state
                self.currentOffset = fetchOffset + parsedArtists.count
                self.hasMoreItems = parsedArtists.count == fetchLimit
                lastError = nil
            } else {
                self.artists = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchArtists")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchArtists")
            lastError = libError
            throw libError
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

            // Album count will be hydrated separately via hydrateLibrary()
            let albumCount = item["album_count"] as? Int ?? 0

            return Artist(
                id: id,
                name: name,
                artworkURL: artworkURL,
                albumCount: albumCount
            )
        }
    }

    // MARK: - Task 7: Fetch Albums (with pagination and Task 8 sorting/filtering)

    func fetchAlbums(
        for artistId: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset
        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Build cache key from sort, filter, and artist parameters
        let artistKey = artistId ?? "all"
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "albums_\(artistKey)_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Album] = cache.get(forKey: cacheKey) {
            print("💾 [LibraryService] Using cached albums for artist \(artistKey): \(cached.count) albums")
            AppLogger.network.debug("Using cached albums (artist: \(artistKey), sort: \(sortBy.rawValue))")
            self.albums = cached
            return
        }

        do {
            var args: [String: Any] = [
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // If artistId is provided, filter by artist
            if let artistId = artistId {
                args["artist"] = artistId
            }

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching albums: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            let result = try await client.sendCommand(
                command: "music/albums/library_items",
                args: args
            )

            if let result = result {
                let parsedAlbums = parseAlbums(from: result)

                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.albums = parsedAlbums
                    // Cache first page results
                    cache.set(parsedAlbums, forKey: cacheKey)
                } else {
                    // Subsequent pages - append
                    self.albums.append(contentsOf: parsedAlbums)
                }

                // Update pagination state
                self.currentOffset = fetchOffset + parsedAlbums.count
                self.hasMoreItems = parsedAlbums.count == fetchLimit

                lastError = nil
            } else {
                self.albums = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchAlbums")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchAlbums")
            lastError = libError
            throw libError
        }
    }

    private func parseAlbums(from data: AnyCodable) -> [Album] {
        guard let items = data.value as? [[String: Any]] else {
            print("❌ [parseAlbums] Data is not an array of dictionaries")
            return []
        }

        print("🔍 [parseAlbums] Parsing \(items.count) items")

        return items.compactMap { item in
            // Debug: print item type if available
            if let mediaType = item["media_type"] as? String {
                if mediaType != "album" {
                    print("⚠️ [parseAlbums] Non-album item detected: \(mediaType) - \(item["name"] as? String ?? "unknown")")
                }
            }

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

            // Parse album type - Music Assistant uses "album_type" field
            let albumType: AlbumType
            if let typeString = item["album_type"] as? String {
                albumType = AlbumType(rawValue: typeString.lowercased()) ?? .unknown
            } else {
                // Fallback: guess based on track count
                if trackCount <= 3 {
                    albumType = .single
                } else if trackCount <= 7 {
                    albumType = .ep
                } else {
                    albumType = .album
                }
            }

            return Album(
                id: id,
                title: title,
                artist: artist,
                artworkURL: artworkURL,
                trackCount: trackCount,
                year: year,
                duration: duration,
                albumType: albumType
            )
        }
    }

    // MARK: - Fetch Playlists (with pagination and Task 8 sorting/filtering)

    func fetchPlaylists(
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset
        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Build cache key
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "playlists_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Playlist] = cache.get(forKey: cacheKey) {
            AppLogger.network.debug("Using cached playlists (sort: \(sortBy.rawValue))")
            self.playlists = cached
            return
        }

        do {
            var args: [String: Any] = [
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching playlists: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            // Music Assistant API: music/playlists/library_items
            let result = try await client.sendCommand(
                command: "music/playlists/library_items",
                args: args
            )

            if let result = result {
                let parsedPlaylists = parsePlaylists(from: result)

                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.playlists = parsedPlaylists
                    // Cache first page results
                    cache.set(parsedPlaylists, forKey: cacheKey)
                } else {
                    // Subsequent pages - append
                    self.playlists.append(contentsOf: parsedPlaylists)
                }

                // Update pagination state
                self.currentOffset = fetchOffset + parsedPlaylists.count
                self.hasMoreItems = parsedPlaylists.count == fetchLimit

                lastError = nil
            } else {
                self.playlists = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchPlaylists")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchPlaylists")
            lastError = libError
            throw libError
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

    // MARK: - Fetch Tracks (with pagination and Task 8 sorting/filtering)

    func fetchTracks(
        for albumId: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset
        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Build cache key
        let albumKey = albumId ?? "all"
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "tracks_\(albumKey)_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Track] = cache.get(forKey: cacheKey) {
            AppLogger.network.debug("Using cached tracks (album: \(albumKey), sort: \(sortBy.rawValue))")
            self.tracks = cached
            return
        }

        do {
            var args: [String: Any] = [
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // If albumId is provided, filter by album
            if let albumId = albumId {
                args["album"] = albumId
            }

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching tracks: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            let result = try await client.sendCommand(
                command: "music/tracks/library_items",
                args: args
            )

            if let result = result {
                let parsedTracks = parseTracks(from: result)

                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.tracks = parsedTracks
                    // Cache first page results
                    cache.set(parsedTracks, forKey: cacheKey)
                } else {
                    // Subsequent pages - append
                    self.tracks.append(contentsOf: parsedTracks)
                }

                // Update pagination state
                self.currentOffset = fetchOffset + parsedTracks.count
                self.hasMoreItems = parsedTracks.count == fetchLimit

                lastError = nil
            } else {
                self.tracks = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchTracks")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchTracks")
            lastError = libError
            throw libError
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

    // MARK: - Task 9: Fetch Radios (with pagination, sorting, and filtering)

    func fetchRadios(
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset
        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Build cache key
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "radios_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Radio] = cache.get(forKey: cacheKey) {
            AppLogger.network.debug("Using cached radios (sort: \(sortBy.rawValue))")
            self.radios = cached
            return
        }

        do {
            var args: [String: Any] = [
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching radios: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            // Music Assistant API: music/radios/library_items
            let result = try await client.sendCommand(
                command: "music/radios/library_items",
                args: args
            )

            if let result = result {
                let parsedRadios = parseRadios(from: result)

                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.radios = parsedRadios
                    // Cache first page results
                    cache.set(parsedRadios, forKey: cacheKey)
                } else {
                    // Subsequent pages - append
                    self.radios.append(contentsOf: parsedRadios)
                }

                // Update pagination state
                self.currentOffset = fetchOffset + parsedRadios.count
                self.hasMoreItems = parsedRadios.count == fetchLimit

                lastError = nil
            } else {
                self.radios = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchRadios")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchRadios")
            lastError = libError
            throw libError
        }
    }

    private func parseRadios(from data: AnyCodable) -> [Radio] {
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

            let provider = item["provider"] as? String

            return Radio(
                id: id,
                name: name,
                artworkURL: artworkURL,
                provider: provider
            )
        }
    }

    // MARK: - Task 9: Fetch Genres (with pagination, sorting, and filtering)

    func fetchGenres(
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset
        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Build cache key
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "genres_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Genre] = cache.get(forKey: cacheKey) {
            AppLogger.network.debug("Using cached genres (sort: \(sortBy.rawValue))")
            self.genres = cached
            return
        }

        do {
            var args: [String: Any] = [
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching genres: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            // Music Assistant API: music/genres/library_items
            let result = try await client.sendCommand(
                command: "music/genres/library_items",
                args: args
            )

            if let result = result {
                let parsedGenres = parseGenres(from: result)

                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.genres = parsedGenres
                    // Cache first page results
                    cache.set(parsedGenres, forKey: cacheKey)
                } else {
                    // Subsequent pages - append
                    self.genres.append(contentsOf: parsedGenres)
                }

                // Update pagination state
                self.currentOffset = fetchOffset + parsedGenres.count
                self.hasMoreItems = parsedGenres.count == fetchLimit

                lastError = nil
            } else {
                self.genres = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchGenres")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchGenres")
            lastError = libError
            throw libError
        }
    }

    private func parseGenres(from data: AnyCodable) -> [Genre] {
        guard let items = data.value as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item in
            guard let id = item["item_id"] as? String,
                  let name = item["name"] as? String
            else {
                return nil
            }

            let itemCount = item["item_count"] as? Int ?? 0

            return Genre(
                id: id,
                name: name,
                itemCount: itemCount
            )
        }
    }

    // MARK: - Fetch Providers

    func fetchProviders() async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        do {
            // Music Assistant API: get configured music providers
            let result = try await client.sendCommand(command: "music/providers")

            if let result = result {
                let providerNames = parseProviders(from: result)
                self.providers = providerNames
                self.lastError = nil
            } else {
                self.providers = []
                self.lastError = nil
            }
        } catch let error as LibraryError {
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            lastError = libError
            throw libError
        }
    }

    private func parseProviders(from data: AnyCodable) -> [String] {
        guard let items = data.value as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item in
            // Extract provider name - try different possible keys
            if let name = item["name"] as? String {
                return name
            } else if let type = item["type"] as? String {
                return type
            } else if let instanceId = item["instance_id"] as? String {
                return instanceId
            }
            return nil
        }
    }

    // MARK: - Search

    func search(query: String, in category: LibraryCategory) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        guard !query.isEmpty else {
            // Empty query - just fetch all for category
            switch category {
            case .artists:
                try await fetchArtists()
            case .albums:
                try await fetchAlbums(for: nil)
            case .tracks:
                try await fetchTracks(for: nil)
            case .playlists:
                try await fetchPlaylists()
            case .radio:
                try await fetchRadios()
            case .genres:
                try await fetchGenres()
            }
            return
        }

        do {
            AppLogger.network.info("Searching \(category.displayName) for: \(query)")

            // Music Assistant API: music/search
            let result = try await client.sendCommand(
                command: "music/search",
                args: [
                    "query": query,
                    "media_type": category.apiMediaType
                ]
            )

            if let result = result {
                // Parse results based on category
                switch category {
                case .artists:
                    self.artists = parseArtists(from: result)
                case .albums:
                    self.albums = parseAlbums(from: result)
                case .tracks:
                    self.tracks = parseTracks(from: result)
                case .playlists:
                    self.playlists = parsePlaylists(from: result)
                case .radio:
                    self.radios = parseRadios(from: result)
                case .genres:
                    self.genres = parseGenres(from: result)
                }
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "search")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.searchFailed(query)
            AppLogger.errors.logError(error, context: "search")
            lastError = libError
            throw libError
        }
    }

    // MARK: - Pagination Methods

    func loadNextPage(for category: LibraryCategory) async throws {
        guard hasMoreItems else {
            AppLogger.network.debug("No more items to load")
            return
        }

        switch category {
        case .artists:
            try await fetchArtists(limit: pageSize, offset: currentOffset)
        case .albums:
            try await fetchAlbums(for: nil, limit: pageSize, offset: currentOffset)
        case .tracks:
            try await fetchTracks(for: nil, limit: pageSize, offset: currentOffset)
        case .playlists:
            try await fetchPlaylists(limit: pageSize, offset: currentOffset)
        case .radio:
            try await fetchRadios(limit: pageSize, offset: currentOffset)
        case .genres:
            try await fetchGenres(limit: pageSize, offset: currentOffset)
        }
    }

    func resetPagination() {
        currentOffset = 0
        hasMoreItems = false
    }

    // MARK: - Task 10: Cache Management

    func clearCache() {
        cache.clear()
        AppLogger.network.debug("Library cache cleared")
    }

    func invalidateCache(for category: LibraryCategory) {
        // Note: Currently clears the entire cache regardless of category.
        // LibraryCache doesn't yet support prefix-based filtering. Since cache
        // is per-instance and rebuilds quickly, clearing all cache is acceptable.
        //
        // Future improvement: Implement prefix-based cache removal in LibraryCache
        // to only clear entries matching category prefixes like:
        // artists_, albums_, tracks_, playlists_, radios_, genres_

        // Clear entire cache (not category-specific yet)
        cache.clear()
        AppLogger.network.debug("Library cache cleared (requested for: \(category.displayName))")
    }

    func refreshCache(for category: LibraryCategory) async throws {
        // Invalidate existing cache and fetch fresh data
        invalidateCache(for: category)

        // Fetch fresh data with forceRefresh
        switch category {
        case .artists:
            try await fetchArtists(forceRefresh: true)
        case .albums:
            try await fetchAlbums(for: nil, forceRefresh: true)
        case .tracks:
            try await fetchTracks(for: nil, forceRefresh: true)
        case .playlists:
            try await fetchPlaylists(forceRefresh: true)
        case .radio:
            try await fetchRadios(forceRefresh: true)
        case .genres:
            try await fetchGenres(forceRefresh: true)
        }
    }

    // MARK: - Task 11: Favorites Methods

    func fetchFavoriteArtists(
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Reset pagination if sort or filter changed
        if sortBy != currentSort || filterBy != currentFilter {
            currentOffset = 0
            hasMoreItems = false
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset

        // Build cache key from sort and filter parameters
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "artists_favorite_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Artist] = cache.get(forKey: cacheKey) {
            AppLogger.network.debug("Using cached favorite artists (sort: \(sortBy.rawValue), filter: \(filterKey))")
            self.artists = cached
            return
        }

        do {
            var args: [String: Any] = [
                "favorite": true,
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching favorite artists: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            let result = try await client.sendCommand(
                command: "music/artists/library_items",
                args: args
            )

            if let result = result {
                let parsedArtists = parseArtists(from: result)

                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.artists = parsedArtists
                    // Cache first page results
                    cache.set(parsedArtists, forKey: cacheKey)
                } else {
                    self.artists.append(contentsOf: parsedArtists)
                }

                self.currentOffset = fetchOffset + parsedArtists.count
                self.hasMoreItems = parsedArtists.count == fetchLimit
                lastError = nil
            } else {
                self.artists = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchFavoriteArtists")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchFavoriteArtists")
            lastError = libError
            throw libError
        }
    }

    func fetchFavoriteAlbums(
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Reset pagination if sort or filter changed
        if sortBy != currentSort || filterBy != currentFilter {
            currentOffset = 0
            hasMoreItems = false
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset

        // Build cache key from sort and filter parameters
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "albums_favorite_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Album] = cache.get(forKey: cacheKey) {
            AppLogger.network.debug("Using cached favorite albums (sort: \(sortBy.rawValue), filter: \(filterKey))")
            self.albums = cached
            return
        }

        do {
            var args: [String: Any] = [
                "favorite": true,
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching favorite albums: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            let result = try await client.sendCommand(
                command: "music/albums/library_items",
                args: args
            )

            if let result = result {
                let parsedAlbums = parseAlbums(from: result)

                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.albums = parsedAlbums
                    // Cache first page results
                    cache.set(parsedAlbums, forKey: cacheKey)
                } else {
                    self.albums.append(contentsOf: parsedAlbums)
                }

                self.currentOffset = fetchOffset + parsedAlbums.count
                self.hasMoreItems = parsedAlbums.count == fetchLimit
                lastError = nil
            } else {
                self.albums = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchFavoriteAlbums")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchFavoriteAlbums")
            lastError = libError
            throw libError
        }
    }

    func fetchFavoriteTracks(
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Reset pagination if sort or filter changed
        if sortBy != currentSort || filterBy != currentFilter {
            currentOffset = 0
            hasMoreItems = false
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset

        // Build cache key from sort and filter parameters
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "tracks_favorite_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Track] = cache.get(forKey: cacheKey) {
            AppLogger.network.debug("Using cached favorite tracks (sort: \(sortBy.rawValue), filter: \(filterKey))")
            self.tracks = cached
            return
        }

        do {
            var args: [String: Any] = [
                "favorite": true,
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching favorite tracks: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            let result = try await client.sendCommand(
                command: "music/tracks/library_items",
                args: args
            )

            if let result = result {
                let parsedTracks = parseTracks(from: result)

                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.tracks = parsedTracks
                    // Cache first page results
                    cache.set(parsedTracks, forKey: cacheKey)
                } else {
                    self.tracks.append(contentsOf: parsedTracks)
                }

                self.currentOffset = fetchOffset + parsedTracks.count
                self.hasMoreItems = parsedTracks.count == fetchLimit
                lastError = nil
            } else {
                self.tracks = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchFavoriteTracks")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchFavoriteTracks")
            lastError = libError
            throw libError
        }
    }

    func fetchFavoritePlaylists(
        limit: Int? = nil,
        offset: Int? = nil,
        sort: LibrarySortOption? = nil,
        filter: LibraryFilter? = nil,
        forceRefresh: Bool = false
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let sortBy = sort ?? currentSort
        let filterBy = filter ?? currentFilter

        // Reset pagination if sort or filter changed
        if sortBy != currentSort || filterBy != currentFilter {
            currentOffset = 0
            hasMoreItems = false
        }

        let fetchLimit = limit ?? pageSize
        let fetchOffset = offset ?? currentOffset

        // Build cache key from sort and filter parameters
        let filterKey = filterBy.isEmpty ? "default" : filterBy.cacheKey
        let cacheKey = "playlists_favorite_\(sortBy.rawValue)_\(filterKey)"

        // Check cache first (if not forcing refresh and first page)
        if !forceRefresh && fetchOffset == 0,
           let cached: [Playlist] = cache.get(forKey: cacheKey) {
            AppLogger.network.debug("Using cached favorite playlists (sort: \(sortBy.rawValue), filter: \(filterKey))")
            self.playlists = cached
            return
        }

        do {
            var args: [String: Any] = [
                "favorite": true,
                "limit": fetchLimit,
                "offset": fetchOffset,
                "order_by": sortBy.rawValue
            ]

            // Merge filter args
            args.merge(filterBy.toAPIArgs()) { (_, new) in new }

            AppLogger.network.info("Fetching favorite playlists: limit=\(fetchLimit), offset=\(fetchOffset), sort=\(sortBy.rawValue)")

            let result = try await client.sendCommand(
                command: "music/playlists/library_items",
                args: args
            )

            if let result = result {
                let parsedPlaylists = parsePlaylists(from: result)

                if offset == 0 || offset == nil && currentOffset == 0 {
                    // First page - replace
                    self.playlists = parsedPlaylists
                    // Cache first page results
                    cache.set(parsedPlaylists, forKey: cacheKey)
                } else {
                    self.playlists.append(contentsOf: parsedPlaylists)
                }

                self.currentOffset = fetchOffset + parsedPlaylists.count
                self.hasMoreItems = parsedPlaylists.count == fetchLimit
                lastError = nil
            } else {
                self.playlists = []
                self.hasMoreItems = false
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchFavoritePlaylists")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchFavoritePlaylists")
            lastError = libError
            throw libError
        }
    }

    // MARK: - Task 11: Recently Played Methods

    func fetchRecentlyPlayed(
        limit: Int? = nil
    ) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        let fetchLimit = limit ?? 20 // Smaller limit for recently played

        do {
            AppLogger.network.info("Fetching recently played items: limit=\(fetchLimit)")

            // Music Assistant API: Fetch recently played tracks sorted by timestamp
            let result = try await client.sendCommand(
                command: "music/tracks/library_items",
                args: [
                    "order_by": "timestamp_played",
                    "limit": fetchLimit
                ]
            )

            if let result = result {
                self.tracks = parseTracks(from: result)
                lastError = nil
            } else {
                self.tracks = []
                lastError = nil
            }
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "fetchRecentlyPlayed")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "fetchRecentlyPlayed")
            lastError = libError
            throw libError
        }
    }

    // MARK: - Task 11: Add/Remove Favorites Methods

    func addToFavorites(itemId: String, mediaType: String) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        do {
            AppLogger.network.info("Adding item \(itemId) to favorites (type: \(mediaType))")

            // Music Assistant API: Set favorite flag to true
            _ = try await client.sendCommand(
                command: "music/\(mediaType)s/favorite",
                args: [
                    "item_id": itemId,
                    "favorite": true
                ]
            )

            // Invalidate cache to ensure fresh data on next fetch
            invalidateCache(for: categoryFromMediaType(mediaType))
            lastError = nil
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "addToFavorites")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "addToFavorites")
            lastError = libError
            throw libError
        }
    }

    func removeFromFavorites(itemId: String, mediaType: String) async throws {
        guard let client = client else {
            let error = LibraryError.noClientAvailable
            lastError = error
            throw error
        }

        do {
            AppLogger.network.info("Removing item \(itemId) from favorites (type: \(mediaType))")

            // Music Assistant API: Set favorite flag to false
            _ = try await client.sendCommand(
                command: "music/\(mediaType)s/favorite",
                args: [
                    "item_id": itemId,
                    "favorite": false
                ]
            )

            // Invalidate cache to ensure fresh data on next fetch
            invalidateCache(for: categoryFromMediaType(mediaType))
            lastError = nil
        } catch let error as LibraryError {
            AppLogger.errors.logError(error, context: "removeFromFavorites")
            lastError = error
            throw error
        } catch {
            let libError = LibraryError.networkError(error.localizedDescription)
            AppLogger.errors.logError(error, context: "removeFromFavorites")
            lastError = libError
            throw libError
        }
    }

    // Helper to convert media type string to LibraryCategory for cache invalidation
    func categoryFromMediaType(_ mediaType: String) -> LibraryCategory {
        switch mediaType {
        case "artist":
            return .artists
        case "album":
            return .albums
        case "track":
            return .tracks
        case "playlist":
            return .playlists
        case "radio":
            return .radio
        case "genre":
            return .genres
        default:
            return .tracks // Default fallback
        }
    }

    // Methods to be added in subsequent tasks:
    // - playNow(item:on:)
    // - addToQueue(item:for:)
}
