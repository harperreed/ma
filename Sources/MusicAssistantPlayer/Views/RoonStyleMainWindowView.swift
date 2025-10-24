// ABOUTME: Complete Roon-style layout integrating library, now-playing, queue, and mini player
// ABOUTME: Main application view with collapsible sidebar, switchable center view, and persistent bottom player bar

import SwiftUI
import MusicAssistantKit
import os.log

struct RoonStyleMainWindowView: View {
    let client: MusicAssistantClient
    let serverConfig: ServerConfig
    let streamingPlayer: StreamingPlayer
    let onDisconnect: () -> Void
    let onChangeServer: () -> Void

    // MARK: - Services
    @StateObject private var playerService: PlayerService
    @StateObject private var queueService: QueueService
    @StateObject private var libraryService: LibraryService
    @StateObject private var imageCacheService: ImageCacheService

    // MARK: - ViewModels
    @StateObject private var nowPlayingViewModel: NowPlayingViewModel
    @StateObject private var queueViewModel: QueueViewModel
    @StateObject private var libraryViewModel: LibraryViewModel

    // MARK: - State
    @State private var selectedPlayer: Player?
    @State private var availablePlayers: [Player] = []
    @State private var centerViewMode: CenterViewMode = .library
    @State private var isLibrarySidebarVisible: Bool = true
    @State private var playerUpdateTask: Task<Void, Never>?
    @State private var selectedLibraryCategory: LibraryCategory? = .artists

    // MARK: - Layout Constants
    private enum LayoutConstants {
        static let miniPlayerHeight: CGFloat = 90
        static let sidebarWidth: CGFloat = 220
        static let queueWidth: CGFloat = 320
        static let miniBreakpoint: CGFloat = 800
        static let mediumBreakpoint: CGFloat = 1100
        static let largeBreakpoint: CGFloat = 1400
    }

    // MARK: - Initialization
    init(
        client: MusicAssistantClient,
        serverConfig: ServerConfig,
        streamingPlayer: StreamingPlayer,
        onDisconnect: @escaping () -> Void,
        onChangeServer: @escaping () -> Void
    ) {
        self.client = client
        self.serverConfig = serverConfig
        self.streamingPlayer = streamingPlayer
        self.onDisconnect = onDisconnect
        self.onChangeServer = onChangeServer

        // Create services
        let playerSvc = PlayerService(client: client, streamingPlayer: streamingPlayer)
        let queueSvc = QueueService(client: client)
        let librarySvc = LibraryService(client: client)
        let imageCacheSvc = ImageCacheService()

        // Initialize StateObjects
        _playerService = StateObject(wrappedValue: playerSvc)
        _queueService = StateObject(wrappedValue: queueSvc)
        _libraryService = StateObject(wrappedValue: librarySvc)
        _imageCacheService = StateObject(wrappedValue: imageCacheSvc)

        // Initialize ViewModels
        _nowPlayingViewModel = StateObject(wrappedValue: NowPlayingViewModel(playerService: playerSvc))
        _queueViewModel = StateObject(wrappedValue: QueueViewModel(queueService: queueSvc))
        _libraryViewModel = StateObject(wrappedValue: LibraryViewModel(libraryService: librarySvc))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Main content area (everything above mini player)
                HStack(spacing: 0) {
                    // Left: Library Sidebar (collapsible)
                    if isLibrarySidebarVisible && shouldShowSidebar(for: geometry.size) {
                        LibrarySidebarView(
                            selectedCategory: $selectedLibraryCategory,
                            providers: libraryService.providers,
                            currentTrackTitle: nowPlayingViewModel.currentTrack?.title,
                            currentArtist: nowPlayingViewModel.currentTrack?.artist,
                            onNowPlayingTap: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    centerViewMode = .expandedNowPlaying
                                }
                            }
                        )
                        .frame(width: LayoutConstants.sidebarWidth)
                        .onChange(of: selectedLibraryCategory) { _, newCategory in
                            // Sync with view model and reload content when category changes
                            if let newCategory = newCategory {
                                libraryViewModel.selectedCategory = newCategory
                                Task {
                                    await libraryViewModel.loadContent()
                                }
                                // Switch to library view when a category is selected
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    centerViewMode = .library
                                }
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(0.1))
                    }

                    // Center: Library Browse or Expanded Now Playing
                    centerView
                        .frame(maxWidth: .infinity)

                    // Right: Players and Queue Panel
                    if shouldShowQueue(for: geometry.size) {
                        Divider()
                            .background(Color.white.opacity(0.1))

                        VStack(spacing: 12) {
                            // Queue Card
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Text("QUEUE")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.5))

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                QueueView(
                                    viewModel: queueViewModel,
                                    currentTrack: nowPlayingViewModel.currentTrack
                                )
                            }
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                            // Players Card
                            PlayersCard(
                                players: availablePlayers,
                                selectedPlayer: $selectedPlayer,
                                onPlayerSelection: handlePlayerSelection
                            )
                            .frame(maxHeight: 300)
                        }
                        .padding(12)
                        .frame(width: LayoutConstants.queueWidth)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Bottom: Mini Player Bar (always visible)
                MiniPlayerBar(
                    nowPlayingViewModel: nowPlayingViewModel,
                    selectedPlayer: $selectedPlayer,
                    availablePlayers: availablePlayers,
                    imageCacheService: imageCacheService,
                    onExpand: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            centerViewMode = .expandedNowPlaying
                        }
                    },
                    onPlayerSelection: handlePlayerSelection
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .task {
            await initializeServices()
        }
        .onDisappear {
            playerUpdateTask?.cancel()
        }
        .onAppear {
            // Set up callback for player selection from now playing view
            nowPlayingViewModel.onPlayerSelectionChange = { player in
                selectedPlayer = player
            }
        }
    }

    // MARK: - Center View

    @ViewBuilder
    private var centerView: some View {
        switch centerViewMode {
        case .library:
            libraryBrowseView
                .transition(.opacity)

        case .expandedNowPlaying:
            expandedNowPlayingView
                .transition(.opacity)
        }
    }

    private var libraryBrowseView: some View {
        VStack(spacing: 0) {
            // Header with connection status and controls
            HStack {
                Text(libraryViewModel.selectedCategory.displayName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // Connection status indicator
                ConnectionStatusIndicator(
                    serverHost: serverConfig.host,
                    serverPort: serverConfig.port,
                    connectionState: playerService.connectionState,
                    onDisconnect: onDisconnect,
                    onChangeServer: onChangeServer
                )

                // Toggle sidebar button
                Button(action: {
                    withAnimation {
                        isLibrarySidebarVisible.toggle()
                    }
                }) {
                    Image(systemName: isLibrarySidebarVisible ? "sidebar.left" : "sidebar.left.slash")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Toggle Sidebar")
                .padding(.leading, 8)
            }
            .padding()

            Divider()
                .background(Color.white.opacity(0.1))

            // Library content
            LibraryBrowseView(
                viewModel: libraryViewModel,
                onPlayNow: handlePlayNow,
                onAddToQueue: handleAddToQueue,
                serverHost: serverConfig.host,
                serverPort: serverConfig.port,
                connectionState: playerService.connectionState,
                onDisconnect: onDisconnect,
                onChangeServer: onChangeServer
            )
        }
        .background(Color.black)
    }

    private var expandedNowPlayingView: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        centerViewMode = .library
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back to Library")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()

            Divider()
                .background(Color.white.opacity(0.1))

            // Now Playing View
            NowPlayingView(
                viewModel: nowPlayingViewModel,
                selectedPlayer: $selectedPlayer,
                availablePlayers: availablePlayers,
                imageCacheService: imageCacheService
            )
        }
        .background(Color.black)
    }

    // MARK: - Responsive Layout Helpers

    private func shouldShowSidebar(for size: CGSize) -> Bool {
        // Show sidebar on medium+ screens
        size.width >= LayoutConstants.miniBreakpoint
    }

    private func shouldShowQueue(for size: CGSize) -> Bool {
        // Show queue on large screens
        size.width >= LayoutConstants.mediumBreakpoint
    }

    // MARK: - Initialization & Data Loading

    private func initializeServices() async {
        await fetchInitialData()
        subscribeToPlayerUpdates()

        // Load initial library content (default category is artists)
        await libraryViewModel.loadContent()

        // Fetch music providers for sidebar
        try? await libraryService.fetchProviders()
    }

    private func fetchInitialData() async {
        do {
            // Fetch players from Music Assistant
            var allPlayers: [Player] = []

            if let result = try await client.getPlayers() {
                allPlayers = PlayerMapper.parsePlayers(from: result)
            }

            // Add StreamingPlayer to the list if it has been registered
            if let playerId = await streamingPlayer.currentPlayerId {
                let streamingPlayerModel = Player(
                    id: playerId,
                    name: "Music Assistant Player",
                    isActive: true,
                    type: .player,
                    groupChildIds: [],
                    syncedTo: nil,
                    activeGroup: nil
                )
                allPlayers.insert(streamingPlayerModel, at: 0)
            }

            await MainActor.run {
                // Log available players for debugging
                AppLogger.network.debug("Available players:")
                for player in allPlayers {
                    AppLogger.network.debug("  - \(player.name) (id: \(player.id), active: \(player.isActive))")
                }

                // Auto-select "This device" player by default (case-insensitive search)
                if let thisDevice = allPlayers.first(where: { $0.name.trimmingCharacters(in: .whitespaces).lowercased() == "this device" }) {
                    AppLogger.network.info("Auto-selecting 'This device' player: \(thisDevice.name)")
                    self.selectedPlayer = thisDevice
                    self.playerService.selectedPlayer = thisDevice
                } else if let firstActive = allPlayers.first(where: { $0.isActive }) {
                    AppLogger.network.info("No 'This device' found, selecting first active player: \(firstActive.name)")
                    self.selectedPlayer = firstActive
                    self.playerService.selectedPlayer = firstActive
                } else if let first = allPlayers.first {
                    AppLogger.network.info("No active players found, selecting first player: \(first.name)")
                    self.selectedPlayer = first
                    self.playerService.selectedPlayer = first
                }

                // Reorder players list to put selected player at the top
                if let selected = self.selectedPlayer {
                    allPlayers.removeAll(where: { $0.id == selected.id })
                    allPlayers.insert(selected, at: 0)
                }

                self.availablePlayers = allPlayers

                // Fetch initial state and queue for selected player
                if let player = selectedPlayer {
                    Task {
                        await playerService.fetchPlayerState(for: player.id)
                        try? await queueService.fetchQueue(for: player.id)
                    }
                }
            }
        } catch {
            AppLogger.network.error("Failed to fetch players: \(error.localizedDescription)")
        }
    }

    private func subscribeToPlayerUpdates() {
        // Cancel existing subscription to prevent multiple concurrent listeners
        playerUpdateTask?.cancel()

        playerUpdateTask = Task { @MainActor in
            // Subscribe to player update events
            for await _ in await client.events.playerUpdates.values {
                // When any player updates, refresh the player list
                await refreshPlayerList()
            }
        }
    }

    private func refreshPlayerList() async {
        do {
            // Fetch players from Music Assistant
            var allPlayers: [Player] = []

            if let result = try await client.getPlayers() {
                allPlayers = PlayerMapper.parsePlayers(from: result)
            }

            // Add StreamingPlayer to the list if it has been registered
            if let playerId = await streamingPlayer.currentPlayerId {
                let streamingPlayerModel = Player(
                    id: playerId,
                    name: "Music Assistant Player",
                    isActive: true,
                    type: .player,
                    groupChildIds: [],
                    syncedTo: nil,
                    activeGroup: nil
                )
                allPlayers.insert(streamingPlayerModel, at: 0)
            }

            await MainActor.run {
                // Update selected player if it still exists
                if let currentlySelected = selectedPlayer,
                   let updatedPlayer = allPlayers.first(where: { $0.id == currentlySelected.id }) {
                    self.selectedPlayer = updatedPlayer
                    self.playerService.selectedPlayer = updatedPlayer
                } else {
                    // No player selected OR previously selected player no longer exists
                    // Select a new one, preferring "This device"
                    if let thisDevice = allPlayers.first(where: { $0.name.trimmingCharacters(in: .whitespaces).lowercased() == "this device" }) {
                        AppLogger.network.info("Auto-selecting 'This device' player: \(thisDevice.name)")
                        self.selectedPlayer = thisDevice
                        self.playerService.selectedPlayer = thisDevice
                    } else if let firstActive = allPlayers.first(where: { $0.isActive }) {
                        AppLogger.network.info("No 'This device' found, selecting first active player: \(firstActive.name)")
                        self.selectedPlayer = firstActive
                        self.playerService.selectedPlayer = firstActive
                    } else if let first = allPlayers.first {
                        AppLogger.network.info("No active players found, selecting first player: \(first.name)")
                        self.selectedPlayer = first
                        self.playerService.selectedPlayer = first
                    } else {
                        self.selectedPlayer = nil
                        self.playerService.selectedPlayer = nil
                    }
                }

                // Reorder players list to put selected player at the top
                if let selected = self.selectedPlayer {
                    allPlayers.removeAll(where: { $0.id == selected.id })
                    allPlayers.insert(selected, at: 0)
                }

                self.availablePlayers = allPlayers
            }
        } catch {
            AppLogger.network.error("Failed to refresh players: \(error.localizedDescription)")
        }
    }

    // MARK: - Action Handlers

    private func handlePlayerSelection(_ player: Player) {
        selectedPlayer = player
        playerService.selectedPlayer = player

        // Reorder players list to put selected player at the top
        var reorderedPlayers = availablePlayers
        reorderedPlayers.removeAll(where: { $0.id == player.id })
        reorderedPlayers.insert(player, at: 0)
        availablePlayers = reorderedPlayers

        Task {
            // Fetch initial player state
            await playerService.fetchPlayerState(for: player.id)

            // Fetch queue
            try? await queueService.fetchQueue(for: player.id)
        }
    }

    private func handlePlayNow(itemId: String, itemType: LibraryItemType) {
        guard let player = selectedPlayer else {
            AppLogger.player.warning("Cannot play now: no player selected")
            return
        }

        Task {
            do {
                // Build URI based on item type
                let uri = buildMediaItemURI(itemId: itemId, itemType: itemType)

                AppLogger.player.info("Playing now: \(uri) on player: \(player.name)")

                // Use Music Assistant play_media command
                _ = try await client.sendCommand(
                    command: "player_queues/play_media",
                    args: [
                        "queue_id": player.id,
                        "media": [uri]
                    ]
                )

                // Switch to now playing view after queuing
                withAnimation(.easeInOut(duration: 0.3)) {
                    centerViewMode = .expandedNowPlaying
                }

            } catch {
                AppLogger.errors.logError(error, context: "handlePlayNow")
            }
        }
    }

    private func handleAddToQueue(itemId: String, itemType: LibraryItemType) {
        guard let player = selectedPlayer else {
            AppLogger.player.warning("Cannot add to queue: no player selected")
            return
        }

        Task {
            do {
                // Build URI based on item type
                let uri = buildMediaItemURI(itemId: itemId, itemType: itemType)

                AppLogger.player.info("Adding to queue: \(uri) on player: \(player.name)")

                // Use Music Assistant queue_command
                _ = try await client.sendCommand(
                    command: "player_queues/queue_command",
                    args: [
                        "queue_id": player.id,
                        "command": "add",
                        "media_items": [uri]
                    ]
                )

                // Refresh queue
                try? await queueService.fetchQueue(for: player.id)

            } catch {
                AppLogger.errors.logError(error, context: "handleAddToQueue")
            }
        }
    }

    private func buildMediaItemURI(itemId: String, itemType: LibraryItemType) -> String {
        switch itemType {
        case .artist:
            return "artist://\(itemId)"
        case .album:
            return "album://\(itemId)"
        case .playlist:
            return "playlist://\(itemId)"
        case .track:
            return "track://\(itemId)"
        case .radio:
            return "radio://\(itemId)"
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ServerConfig(host: "192.168.200.113", port: 8095)
    let client = MusicAssistantClient(host: config.host, port: config.port)
    let player = StreamingPlayer(client: client, playerName: "Preview Player")

    RoonStyleMainWindowView(
        client: client,
        serverConfig: config,
        streamingPlayer: player,
        onDisconnect: {},
        onChangeServer: {}
    )
    .frame(width: 1400, height: 900)
}
