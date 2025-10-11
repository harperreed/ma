// ABOUTME: Service layer for player state management and playback control
// ABOUTME: Wraps MusicAssistantKit client and exposes Combine publishers for UI

import Foundation
import Combine
import MusicAssistantKit

@MainActor
class PlayerService: ObservableObject {
    @Published var currentTrack: Track?
    @Published var playbackState: PlaybackState = .stopped
    @Published var progress: TimeInterval = 0.0
    @Published var selectedPlayer: Player?
    @Published var connectionState: ConnectionState = .disconnected

    private let client: MusicAssistantClient?
    private var cancellables = Set<AnyCancellable>()

    init(client: MusicAssistantClient? = nil) {
        self.client = client
        setupEventSubscriptions()
    }

    private func setupEventSubscriptions() {
        guard let client = client else { return }

        // Subscribe to player update events
        // Will implement event parsing in next task
    }

    func play() async throws {
        guard let client = client,
              let player = selectedPlayer else { return }
        try await client.play(playerId: player.id)
    }

    func pause() async throws {
        guard let client = client,
              let player = selectedPlayer else { return }
        try await client.pause(playerId: player.id)
    }

    func stop() async throws {
        guard let client = client,
              let player = selectedPlayer else { return }
        try await client.stop(playerId: player.id)
    }

    // Note: Skip next/previous methods to be implemented when API support is added
    // func skipNext() async throws {
    //     guard let client = client,
    //           let player = selectedPlayer else { return }
    //     // TODO: Implement when API supports next track command
    // }
    //
    // func skipPrevious() async throws {
    //     guard let client = client,
    //           let player = selectedPlayer else { return }
    //     // TODO: Implement when API supports previous track command
    // }
}
