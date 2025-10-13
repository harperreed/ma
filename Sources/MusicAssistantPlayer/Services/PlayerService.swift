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
    internal var eventTask: Task<Void, Never>?
    private var connectionMonitorTask: Task<Void, Never>?

    init(client: MusicAssistantClient? = nil) {
        self.client = client
        subscribeToPlayerEvents()
        monitorConnection()
    }

    deinit {
        eventTask?.cancel()
        connectionMonitorTask?.cancel()
    }

    private func monitorConnection() {
        connectionMonitorTask?.cancel()

        connectionMonitorTask = Task { [weak self] in
            guard let client = self?.client else {
                await MainActor.run { [weak self] in
                    self?.connectionState = .disconnected
                }
                return
            }

            // Check connection status periodically
            await MainActor.run { [weak self] in
                self?.connectionState = .connecting
            }

            // Wait a bit for initial connection
            try? await Task.sleep(for: .seconds(2))

            let isConnected = await client.isConnected
            await MainActor.run { [weak self] in
                self?.connectionState = isConnected ? .connected : .error("Not connected")
            }
        }
    }

    func subscribeToPlayerEvents() {
        // Cancel any existing task to prevent memory leaks
        eventTask?.cancel()

        eventTask = Task { [weak self] in
            guard let client = self?.client else { return }

            for await event in await client.events.playerUpdates.values {
                guard let self = self else { return }

                await MainActor.run { [weak self] in
                    guard let self = self,
                          let selectedPlayer = self.selectedPlayer,
                          event.playerId == selectedPlayer.id else {
                        return
                    }

                    // Parse track
                    if let track = EventParser.parseTrack(from: event.data) {
                        self.currentTrack = track
                    }

                    // Parse playback state
                    self.playbackState = EventParser.parsePlaybackState(from: event.data)

                    // Parse progress
                    self.progress = EventParser.parseProgress(from: event.data)
                }
            }
        }
    }

    func fetchPlayerState(for playerId: String) async {
        guard let client = client else {
            print("⚠️ [PlayerService] No client to fetch player state")
            return
        }

        do {
            // Get all players and find the specific one
            if let result = try await client.getPlayers() {
                // Parse as array of player dictionaries
                guard let playersArray = result.value as? [[String: Any]] else {
                    return
                }

                // Find our specific player
                guard let playerData = playersArray.first(where: { dict in
                    let id = dict["player_id"] as? String ?? dict["id"] as? String
                    return id == playerId
                }) else {
                    return
                }

                // Convert to AnyCodable dictionary for EventParser
                let anyCodableData = playerData.mapValues { AnyCodable($0) }

                // Parse track
                if let track = EventParser.parseTrack(from: anyCodableData) {
                    currentTrack = track
                } else {
                    currentTrack = nil
                }

                // Parse playback state
                playbackState = EventParser.parsePlaybackState(from: anyCodableData)

                // Parse progress
                progress = EventParser.parseProgress(from: anyCodableData)
            }
        } catch {
            print("❌ [PlayerService] Failed to fetch player state: \(error)")
        }
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
