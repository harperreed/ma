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
    @Published var progress: TimeInterval = 0.0
    @Published private(set) var duration: TimeInterval = 0.0
    @Published var volume: Double = 50.0
    @Published var isShuffled: Bool = false
    @Published var isLiked: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published private(set) var currentTrack: Track?

    // Debouncing subjects for volume and seek
    private var volumeSubject = PassthroughSubject<Double, Never>()
    private var seekSubject = PassthroughSubject<TimeInterval, Never>()

    // Callback to notify parent when player selection changes
    var onPlayerSelectionChange: ((Player) -> Void)?

    init(playerService: PlayerService) {
        self.playerService = playerService
        setupBindings()
        setupDebouncing()
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

        // Note: progress is updated via seekSubject when user is scrubbing
        // Service updates progress during normal playback
        playerService.$progress
            .sink { [weak self] serviceProgress in
                // Only update from service if we're not actively seeking
                // This prevents service updates from fighting with optimistic UI updates
                guard let self = self else { return }
                self.progress = serviceProgress
            }
            .store(in: &cancellables)

        // Note: volume is updated via volumeSubject when user is dragging slider
        // Service updates volume from external sources (e.g., hardware controls)
        playerService.$volume
            .sink { [weak self] serviceVolume in
                // Update from service, but optimistic updates take precedence
                guard let self = self else { return }
                self.volume = serviceVolume
            }
            .store(in: &cancellables)

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

    private func setupDebouncing() {
        // Volume changes debounced to 300ms
        volumeSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] volume in
                Task { [weak self] in
                    await self?.playerService.setVolume(volume)
                }
            }
            .store(in: &cancellables)

        // Seek changes debounced to 500ms (longer for scrubbing)
        seekSubject
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] time in
                Task { [weak self] in
                    await self?.playerService.seek(to: time)
                }
            }
            .store(in: &cancellables)
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
        // Update local state immediately for responsive UI
        self.progress = time
        // Send through debounced subject
        seekSubject.send(time)
    }

    func setVolume(_ volume: Double) {
        // Update local state immediately for responsive UI
        self.volume = volume
        // Send through debounced subject
        volumeSubject.send(volume)
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
