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
    @Published private(set) var currentTrack: Track?

    // Callback to notify parent when player selection changes
    var onPlayerSelectionChange: ((Player) -> Void)?

    init(playerService: PlayerService) {
        self.playerService = playerService
        setupBindings()
    }

    private func setupBindings() {
        playerService.$currentTrack
            .sink { [weak self] track in
                self?.currentTrack = track
                self?.trackTitle = track?.title ?? "No Track Playing"
                self?.artistName = track?.artist ?? ""
                self?.albumName = track?.album ?? ""
                self?.artworkURL = track?.artworkURL
                self?.duration = track?.duration ?? 0.0

                // Check if new track is favorited
                if let trackId = track?.id {
                    Task { [weak self] in
                        // Verify track hasn't changed before updating state
                        guard self?.currentTrack?.id == trackId else { return }
                        await self?.playerService.checkIfFavorite(trackId: trackId)
                    }
                }
            }
            .store(in: &cancellables)

        playerService.$playbackState
            .map { $0 == .playing }
            .assign(to: &$isPlaying)

        playerService.$progress
            .assign(to: &$progress)

        playerService.$volume
            .assign(to: &$volume)

        playerService.$isShuffled
            .assign(to: &$isShuffled)

        playerService.$repeatMode
            .map { mode -> RepeatMode in
                switch mode {
                case "all": return .all
                case "one": return .one
                default: return .off
                }
            }
            .assign(to: &$repeatMode)

        playerService.$isFavorite
            .assign(to: &$isLiked)
    }

    func play() {
        Task {
            await playerService.play()
        }
    }

    func pause() {
        Task {
            await playerService.pause()
        }
    }

    func skipNext() {
        Task {
            await playerService.skipNext()
        }
    }

    func skipPrevious() {
        Task {
            await playerService.skipPrevious()
        }
    }

    func seek(to time: TimeInterval) {
        Task {
            await playerService.seek(to: time)
        }
    }

    func setVolume(_ volume: Double) {
        Task {
            await playerService.setVolume(volume)
        }
    }

    func toggleShuffle() {
        Task {
            await playerService.setShuffle(enabled: !isShuffled)
        }
    }

    func toggleLike() {
        guard let trackId = currentTrack?.id else {
            return
        }

        Task {
            await playerService.toggleFavorite(trackId: trackId)
        }
    }

    func cycleRepeatMode() {
        let nextMode: String
        switch repeatMode {
        case .off: nextMode = "all"
        case .all: nextMode = "one"
        case .one: nextMode = "off"
        }

        Task {
            await playerService.setRepeat(mode: nextMode)
        }
    }

    func handlePlayerSelection(_ player: Player) {
        playerService.selectedPlayer = player
        onPlayerSelectionChange?(player)

        Task {
            await playerService.fetchPlayerState(for: player.id)
        }
    }

    var lastError: PlayerError? {
        playerService.lastError
    }

    func clearError() {
        playerService.lastError = nil
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
