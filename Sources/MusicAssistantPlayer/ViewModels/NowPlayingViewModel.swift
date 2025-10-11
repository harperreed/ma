// ABOUTME: ViewModel for now playing display and playback controls
// ABOUTME: Transforms PlayerService state into UI-friendly computed properties

import Foundation
import Combine

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

    init(playerService: PlayerService) {
        self.playerService = playerService
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
}
