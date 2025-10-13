// ABOUTME: Main window layout composing sidebar, now playing, and queue views
// ABOUTME: Three-column Roon-inspired layout with service injection and client management

import SwiftUI
import MusicAssistantKit
import os.log

struct MainWindowView: View {
    let client: MusicAssistantClient
    let serverConfig: ServerConfig

    @StateObject private var playerService: PlayerService
    @StateObject private var queueService: QueueService
    @StateObject private var nowPlayingViewModel: NowPlayingViewModel
    @StateObject private var imageCacheService: ImageCacheService

    @State private var selectedPlayer: Player?
    @State private var availablePlayers: [Player] = []
    @State private var playerUpdateTask: Task<Void, Never>?

    // MARK: - Responsive Layout Constants

    private enum LayoutBreakpoint {
        static let miniplayerWidth: CGFloat = 700
        static let queueHideWidth: CGFloat = 1000
        static let mediumWindow: CGFloat = 800
        static let largeWindow: CGFloat = 1200
    }

    private enum SidebarWidth {
        static let small: CGFloat = 180
        static let medium: CGFloat = 200
        static let large: CGFloat = 280
        static let extraLarge: CGFloat = 300
    }

    private enum QueueWidth {
        static let small: CGFloat = 280
        static let large: CGFloat = 300
    }

    init(client: MusicAssistantClient, serverConfig: ServerConfig) {
        self.client = client
        self.serverConfig = serverConfig

        // Create services
        let playerSvc = PlayerService(client: client)
        let queueSvc = QueueService(client: client)
        let imageCacheSvc = ImageCacheService()

        // Initialize StateObjects
        _playerService = StateObject(wrappedValue: playerSvc)
        _queueService = StateObject(wrappedValue: queueSvc)
        _nowPlayingViewModel = StateObject(wrappedValue: NowPlayingViewModel(playerService: playerSvc))
        _imageCacheService = StateObject(wrappedValue: imageCacheSvc)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar (responsive width, hides in miniplayer mode)
                if shouldShowSidebar(for: geometry.size) {
                    SidebarView(
                        selectedPlayer: $selectedPlayer,
                        availablePlayers: availablePlayers,
                        connectionState: playerService.connectionState,
                        serverHost: serverConfig.host,
                        onRetry: handleRetry
                    )
                    .frame(width: sidebarWidth(for: geometry.size))
                    .onChange(of: selectedPlayer) { oldValue, newValue in
                        if let player = newValue {
                            handlePlayerSelection(player)
                        }
                    }
                }

                // Now Playing (center hero)
                NowPlayingView(
                    viewModel: nowPlayingViewModel,
                    selectedPlayer: $selectedPlayer,
                    availablePlayers: availablePlayers,
                    imageCacheService: imageCacheService
                )
                .frame(maxWidth: .infinity)
                .onAppear {
                    // Set up callback for player selection from miniplayer menu
                    nowPlayingViewModel.onPlayerSelectionChange = { player in
                        selectedPlayer = player
                    }
                }

                // Queue (right panel, responsive width)
                if shouldShowQueue(for: geometry.size) {
                    QueueView(
                        viewModel: QueueViewModel(queueService: queueService)
                    )
                    .frame(width: queueWidth(for: geometry.size))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .task {
            await fetchInitialData()
            subscribeToPlayerUpdates()
        }
        .onDisappear {
            playerUpdateTask?.cancel()
        }
    }

    // MARK: - Responsive Layout

    private func sidebarWidth(for size: CGSize) -> CGFloat {
        if size.width < LayoutBreakpoint.mediumWindow {
            return SidebarWidth.small
        } else if size.width < LayoutBreakpoint.queueHideWidth {
            return SidebarWidth.medium
        } else if size.width < LayoutBreakpoint.largeWindow {
            return SidebarWidth.large
        } else {
            return SidebarWidth.extraLarge
        }
    }

    private func queueWidth(for size: CGSize) -> CGFloat {
        if size.width < LayoutBreakpoint.queueHideWidth {
            return QueueWidth.small
        } else if size.width < LayoutBreakpoint.largeWindow {
            return QueueWidth.small
        } else {
            return QueueWidth.large
        }
    }

    private func shouldShowQueue(for size: CGSize) -> Bool {
        // Hide queue on smaller windows to prioritize now playing with large album art
        size.width >= LayoutBreakpoint.queueHideWidth
    }

    private func shouldShowSidebar(for size: CGSize) -> Bool {
        // Hide sidebar on very small windows for miniplayer mode
        size.width >= LayoutBreakpoint.miniplayerWidth
    }

    private func fetchInitialData() async {
        do {
            // Fetch players
            if let result = try await client.getPlayers() {
                let players = PlayerMapper.parsePlayers(from: result)

                await MainActor.run {
                    self.availablePlayers = players

                    // Auto-select first active player
                    if let firstActive = players.first(where: { $0.isActive }) {
                        self.selectedPlayer = firstActive
                        self.playerService.selectedPlayer = firstActive
                    } else if let first = players.first {
                        self.selectedPlayer = first
                        self.playerService.selectedPlayer = first
                    }

                    // Fetch initial state and queue for selected player
                    if let player = selectedPlayer {
                        Task {
                            await playerService.fetchPlayerState(for: player.id)
                            try? await queueService.fetchQueue(for: player.id)
                        }
                    }
                }
            }
        } catch {
            AppLogger.network.error("Failed to fetch players: \(error.localizedDescription)")
        }
    }

    private func handlePlayerSelection(_ player: Player) {
        playerService.selectedPlayer = player

        Task {
            // Fetch initial player state
            await playerService.fetchPlayerState(for: player.id)

            // Fetch queue
            try? await queueService.fetchQueue(for: player.id)
        }
    }

    private func handleRetry() {
        Task {
            await fetchInitialData()
        }
    }

    private func subscribeToPlayerUpdates() {
        // Cancel existing subscription to prevent multiple concurrent listeners
        playerUpdateTask?.cancel()

        playerUpdateTask = Task { @MainActor in
            // Subscribe to player update events
            for await _ in await client.events.playerUpdates.values {
                // When any player updates, refresh the player list
                // This catches sync/unsync changes, power state changes, etc.
                await refreshPlayerList()
            }
        }
    }

    private func refreshPlayerList() async {
        do {
            if let result = try await client.getPlayers() {
                let players = PlayerMapper.parsePlayers(from: result)

                await MainActor.run {
                    self.availablePlayers = players

                    // Update selected player if it still exists, otherwise select first active or first player
                    if let currentlySelected = selectedPlayer,
                       let updatedPlayer = players.first(where: { $0.id == currentlySelected.id }) {
                        self.selectedPlayer = updatedPlayer
                        self.playerService.selectedPlayer = updatedPlayer
                    } else if selectedPlayer != nil {
                        // Previously selected player no longer exists, select a new one
                        if let firstActive = players.first(where: { $0.isActive }) {
                            self.selectedPlayer = firstActive
                            self.playerService.selectedPlayer = firstActive
                        } else if let first = players.first {
                            self.selectedPlayer = first
                            self.playerService.selectedPlayer = first
                        } else {
                            // No players available
                            self.selectedPlayer = nil
                            self.playerService.selectedPlayer = nil
                        }
                    }
                }
            }
        } catch {
            AppLogger.network.error("Failed to refresh players: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ServerConfig(host: "192.168.200.113", port: 8095)
    let client = MusicAssistantClient(host: config.host, port: config.port)

    return MainWindowView(client: client, serverConfig: config)
        .frame(width: 1200, height: 800)
}
