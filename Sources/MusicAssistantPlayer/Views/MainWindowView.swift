// ABOUTME: Main window layout composing sidebar, now playing, and queue views
// ABOUTME: Three-column Roon-inspired layout with service injection

import SwiftUI

struct MainWindowView: View {
    @StateObject private var playerService = PlayerService()
    @StateObject private var queueService = QueueService()

    @State private var selectedPlayer: Player?
    @State private var availablePlayers: [Player] = []

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
    }
}

#Preview {
    let playerService = PlayerService()
    playerService.currentTrack = Track(
        id: "1",
        title: "Bohemian Rhapsody",
        artist: "Queen",
        album: "A Night at the Opera",
        duration: 354.0,
        artworkURL: nil
    )
    playerService.playbackState = .playing
    playerService.progress = 120.0

    let queueService = QueueService()
    queueService.upcomingTracks = [
        Track(id: "2", title: "We Will Rock You", artist: "Queen", album: "News of the World", duration: 122.0, artworkURL: nil),
        Track(id: "3", title: "We Are the Champions", artist: "Queen", album: "News of the World", duration: 179.0, artworkURL: nil)
    ]

    return MainWindowView()
        .frame(width: 1200, height: 800)
}
