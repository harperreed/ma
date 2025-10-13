// ABOUTME: ViewModel for now playing display and playback controls
// ABOUTME: Transforms PlayerService state into UI-friendly computed properties

import Foundation
import Combine
import SwiftUI

@MainActor
class NowPlayingViewModel: ObservableObject {
    private let playerService: PlayerService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var trackTitle: String = "No Track Playing"
    @Published private(set) var artistName: String = ""
    @Published private(set) var albumName: String = ""
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var artworkURL: URL?
    @Published private(set) var progress: TimeInterval = 0.0
    @Published private(set) var duration: TimeInterval = 0.0

    @Published var volume: Double = 50.0
    @Published var isShuffled: Bool = false
    @Published var isLiked: Bool = false
    @Published var repeatMode: RepeatMode = .off

    // Miniplayer menu support
    @Published var selectedPlayer: Player?
    @Published var availablePlayers: [Player] = []

    // Callback to notify parent when player selection changes
    var onPlayerSelectionChange: ((Player) -> Void)?

    init(playerService: PlayerService, selectedPlayer: Player? = nil, availablePlayers: [Player] = []) {
        self.playerService = playerService
        self.selectedPlayer = selectedPlayer
        self.availablePlayers = availablePlayers
        setupBindings()
    }

    private func setupBindings() {
        playerService.$currentTrack
            .sink { [weak self] track in
                self?.trackTitle = track?.title ?? "No Track Playing"
                self?.artistName = track?.artist ?? ""
                self?.albumName = track?.album ?? ""
                self?.artworkURL = track?.artworkURL
                self?.duration = track?.duration ?? 0.0
            }
            .store(in: &cancellables)

        playerService.$playbackState
            .map { $0 == .playing }
            .assign(to: &$isPlaying)

        playerService.$progress
            .assign(to: &$progress)
    }

    func play() {
        Task {
            try? await playerService.play()
        }
    }

    func pause() {
        Task {
            try? await playerService.pause()
        }
    }

    func skipNext() {
        // TODO: Implement when MusicAssistantKit adds next() method
    }

    func skipPrevious() {
        // TODO: Implement when MusicAssistantKit adds previous() method
    }

    func seek(to time: TimeInterval) {
        // TODO: Call Music Assistant API when seek is supported
        // For now, just log the attempt - don't update progress directly
        // as it's bound to playerService and will be overwritten
        print("Seek to \(time) (not yet implemented in API)")
    }

    func toggleShuffle() {
        isShuffled.toggle()
        // TODO: Call Music Assistant API
        print("Shuffle: \(isShuffled) (not yet implemented)")
    }

    func toggleLike() {
        isLiked.toggle()
        // TODO: Persist to favorites
        print("Liked: \(isLiked)")
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
        // TODO: Call Music Assistant API
        print("Repeat mode: \(repeatMode)")
    }

    func handlePlayerSelection(_ player: Player) {
        selectedPlayer = player
        playerService.selectedPlayer = player
        onPlayerSelectionChange?(player)

        Task {
            await playerService.fetchPlayerState(for: player.id)
        }
    }

    enum RepeatMode {
        case off
        case all
        case one

        var icon: String {
            switch self {
            case .off: return "repeat"
            case .all: return "repeat"
            case .one: return "repeat.1"
            }
        }

        var isActive: Bool {
            self != .off
        }
    }
}
