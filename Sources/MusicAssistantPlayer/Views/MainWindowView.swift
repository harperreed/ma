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
                availablePlayers: availablePlayers
            )
            .frame(width: 220)

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
        // Fetch players
        // Will implement in next task
    }
}

#Preview {
    let config = ServerConfig(host: "192.168.200.113", port: 8095)
    let client = MusicAssistantClient(host: config.host, port: config.port)

    return MainWindowView(client: client, serverConfig: config)
        .frame(width: 1200, height: 800)
}
