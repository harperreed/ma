// ABOUTME: Main window layout composing sidebar, now playing, and queue views
// ABOUTME: Three-column Roon-inspired layout with service injection and client management

import SwiftUI
import MusicAssistantKit

struct MainWindowView: View {
    let client: MusicAssistantClient
    let serverConfig: ServerConfig

    @StateObject private var playerService: PlayerService
    @StateObject private var queueService: QueueService

    @State private var selectedPlayer: Player?
    @State private var availablePlayers: [Player] = []
    @State private var playerUpdateTask: Task<Void, Never>?

    init(client: MusicAssistantClient, serverConfig: ServerConfig) {
        self.client = client
        self.serverConfig = serverConfig

        // Create services
        let playerSvc = PlayerService(client: client)
        let queueSvc = QueueService(client: client)

        // Initialize StateObjects
        _playerService = StateObject(wrappedValue: playerSvc)
        _queueService = StateObject(wrappedValue: queueSvc)
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
                    viewModel: {
                        let vm = NowPlayingViewModel(
                            playerService: playerService,
                            selectedPlayer: selectedPlayer,
                            availablePlayers: availablePlayers
                        )
                        vm.onPlayerSelectionChange = { [self] player in
                            self.selectedPlayer = player
                        }
                        return vm
                    }()
                )
                .frame(maxWidth: .infinity)

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
        if size.width < 800 {
            return 180  // Narrower on small screens
        } else if size.width < 1000 {
            return 200
        } else {
            return 220  // Full width on larger screens
        }
    }

    private func queueWidth(for size: CGSize) -> CGFloat {
        if size.width < 1000 {
            return 280  // Narrower on small screens
        } else if size.width < 1200 {
            return 320
        } else {
            return 350  // Full width on larger screens
        }
    }

    private func shouldShowQueue(for size: CGSize) -> Bool {
        // Hide queue on smaller windows to prioritize now playing with large album art
        size.width >= 1000
    }

    private func shouldShowSidebar(for size: CGSize) -> Bool {
        // Hide sidebar on very small windows for miniplayer mode
        size.width >= 700
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
            print("Failed to fetch players: \(error)")
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
            print("Failed to refresh players: \(error)")
        }
    }
}

#Preview {
    let config = ServerConfig(host: "192.168.200.113", port: 8095)
    let client = MusicAssistantClient(host: config.host, port: config.port)

    return MainWindowView(client: client, serverConfig: config)
        .frame(width: 1200, height: 800)
}
