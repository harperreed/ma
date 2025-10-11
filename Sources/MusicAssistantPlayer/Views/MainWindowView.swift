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

    init(client: MusicAssistantClient, serverConfig: ServerConfig) {
        self.client = client
        self.serverConfig = serverConfig

        let playerSvc = PlayerService(client: client)
        playerSvc.setServerHost(serverConfig.host)
        _playerService = StateObject(wrappedValue: playerSvc)

        let queueSvc = QueueService(client: client)
        queueSvc.setServerHost(serverConfig.host)
        _queueService = StateObject(wrappedValue: queueSvc)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(
                selectedPlayer: $selectedPlayer,
                availablePlayers: availablePlayers,
                connectionState: playerService.connectionState,
                serverHost: serverConfig.host,
                onRetry: handleRetry
            )
            .frame(width: 220)
            .onChange(of: selectedPlayer) { oldValue, newValue in
                if let player = newValue {
                    handlePlayerSelection(player)
                }
            }

            // Now Playing (center hero)
            NowPlayingView(
                viewModel: NowPlayingViewModel(playerService: playerService)
            )
            .frame(maxWidth: .infinity)

            // Queue (right panel)
            QueueView(
                viewModel: QueueViewModel(queueService: queueService)
            )
            .frame(width: 350)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task {
            await fetchInitialData()
        }
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

                    // Fetch queue for selected player
                    if let player = selectedPlayer {
                        Task {
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
            try? await queueService.fetchQueue(for: player.id)
        }
    }

    private func handleRetry() {
        Task {
            await fetchInitialData()
        }
    }
}

#Preview {
    let config = ServerConfig(host: "192.168.200.113", port: 8095)
    let client = MusicAssistantClient(host: config.host, port: config.port)

    return MainWindowView(client: client, serverConfig: config)
        .frame(width: 1200, height: 800)
}
