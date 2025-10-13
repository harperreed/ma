// ABOUTME: Service layer for player state management and playback control
// ABOUTME: Wraps MusicAssistantKit client and exposes Combine publishers for UI

import Foundation
import Combine
import MusicAssistantKit
import os.log

@MainActor
class PlayerService: ObservableObject {
    @Published var currentTrack: Track?
    @Published var playbackState: PlaybackState = .stopped {
        didSet {
            handlePlaybackStateChange(oldValue: oldValue, newValue: playbackState)
        }
    }
    @Published var progress: TimeInterval = 0.0
    @Published var volume: Double = 50.0
    @Published var selectedPlayer: Player?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: PlayerError?

    private let client: MusicAssistantClient?
    private var cancellables = Set<AnyCancellable>()
    internal var eventTask: Task<Void, Never>?
    private var connectionMonitorTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    private var lastProgressUpdate = Date()

    init(client: MusicAssistantClient? = nil) {
        self.client = client
        subscribeToPlayerEvents()
        monitorConnection()
    }

    deinit {
        eventTask?.cancel()
        connectionMonitorTask?.cancel()
        progressTask?.cancel()
    }

    private func handlePlaybackStateChange(oldValue: PlaybackState, newValue: PlaybackState) {
        if newValue == .playing {
            startLocalProgressTracking()
        } else {
            stopLocalProgressTracking()
        }
    }

    private func startLocalProgressTracking() {
        stopLocalProgressTracking()

        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100)) // Update every 100ms

                await MainActor.run { [weak self] in
                    guard let self = self,
                          self.playbackState == .playing,
                          let duration = self.currentTrack?.duration,
                          self.progress < duration else {
                        return
                    }

                    // Increment progress by elapsed time
                    let now = Date()
                    let elapsed = now.timeIntervalSince(self.lastProgressUpdate)
                    self.progress += elapsed
                    self.lastProgressUpdate = now
                }
            }
        }
    }

    private func stopLocalProgressTracking() {
        progressTask?.cancel()
        progressTask = nil
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
                guard let self = self else {
                    AppLogger.player.warning("PlayerService deallocated, stopping event subscription")
                    return
                }

                await MainActor.run { [weak self] in
                    guard let self = self else { return }

                    // Log ALL received events for debugging
                    AppLogger.player.debug("Received player event for player: \(event.playerId)")

                    // If no player selected yet, log and skip (but don't lose the event loop)
                    guard let selectedPlayer = self.selectedPlayer else {
                        AppLogger.player.debug("No player selected, skipping event for: \(event.playerId)")
                        return
                    }

                    // If event is for different player, log and skip
                    guard event.playerId == selectedPlayer.id else {
                        AppLogger.player.debug("Event for different player (received: \(event.playerId), selected: \(selectedPlayer.id)), skipping")
                        return
                    }

                    AppLogger.player.debug("Processing event for selected player: \(selectedPlayer.name)")

                    // Parse track
                    if let track = EventParser.parseTrack(from: event.data) {
                        self.currentTrack = track
                        AppLogger.player.debug("Updated track: \(track.title)")
                    }

                    // Parse playback state
                    let newState = EventParser.parsePlaybackState(from: event.data)
                    if newState != self.playbackState {
                        AppLogger.player.debug("Playback state changed: \(self.playbackState) -> \(newState)")
                        self.playbackState = newState
                    }

                    // Parse progress and update timestamp
                    let newProgress = EventParser.parseProgress(from: event.data)
                    AppLogger.player.debug("Progress update: \(newProgress)s")
                    self.progress = newProgress
                    self.lastProgressUpdate = Date()

                    // Parse volume
                    let newVolume = EventParser.parseVolume(from: event.data)
                    if newVolume != self.volume {
                        AppLogger.player.debug("Volume update: \(newVolume)")
                        self.volume = newVolume
                    }
                }
            }
        }
    }

    func fetchPlayerState(for playerId: String) async {
        guard let client = client else {
            AppLogger.player.warning("No client to fetch player state")
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

                // Parse progress and update timestamp for local tracking sync
                progress = EventParser.parseProgress(from: anyCodableData)
                lastProgressUpdate = Date()

                // Parse volume
                volume = EventParser.parseVolume(from: anyCodableData)
            }
        } catch {
            AppLogger.errors.logError(error, context: "fetchPlayerState(for: \(playerId))")
        }
    }

    func play() async {
        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.info("Playing on player: \(player.name)")
            try await client.play(playerId: player.id)
            lastError = nil // Clear on success
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "play()")
            lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "play()")
            lastError = .commandFailed("play", reason: error.localizedDescription)
        }
    }

    func pause() async {
        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.info("Pausing player: \(player.name)")
            try await client.pause(playerId: player.id)
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "pause()")
            lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "pause()")
            lastError = .commandFailed("pause", reason: error.localizedDescription)
        }
    }

    func stop() async {
        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.info("Stopping player: \(player.name)")
            try await client.stop(playerId: player.id)
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "stop()")
            lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "stop()")
            lastError = .commandFailed("stop", reason: error.localizedDescription)
        }
    }

    func skipNext() async {
        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.info("Skipping to next track on player: \(player.name)")
            try await client.next(playerId: player.id)
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "skipNext()")
            lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "skipNext()")
            lastError = .commandFailed("skip next", reason: error.localizedDescription)
        }
    }

    func skipPrevious() async {
        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.info("Skipping to previous track on player: \(player.name)")
            try await client.previous(playerId: player.id)
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "skipPrevious()")
            lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "skipPrevious()")
            lastError = .commandFailed("skip previous", reason: error.localizedDescription)
        }
    }

    func seek(to position: Double) async {
        // Optimistically update progress for immediate UI feedback (bidirectional sync)
        progress = position
        lastProgressUpdate = Date()

        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.debug("Seeking to position: \(position) on player: \(player.name)")
            // Use queue-level seek (queueId is same as playerId in Music Assistant)
            try await client.seek(queueId: player.id, position: position)
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "seek(to: \(position))")
            lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "seek(to: \(position))")
            lastError = .commandFailed("seek", reason: error.localizedDescription)
        }
    }

    func setVolume(_ volume: Double) async {
        // Optimistically update volume for immediate UI feedback (bidirectional sync)
        self.volume = volume

        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.debug("Setting volume to: \(volume) on player: \(player.name)")
            try await client.setVolume(playerId: player.id, volume: volume)
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "setVolume(\(volume))")
            lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "setVolume(\(volume))")
            lastError = .commandFailed("set volume", reason: error.localizedDescription)
        }
    }

    func group(targetPlayerId: String) async {
        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.info("Grouping player \(player.name) with \(targetPlayerId)")
            try await client.group(playerId: player.id, targetPlayer: targetPlayerId)
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "group(targetPlayerId:)")
            self.lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "group(targetPlayerId:)")
            self.lastError = .commandFailed("group", reason: error.localizedDescription)
        }
    }

    func ungroup() async {
        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.info("Ungrouping player \(player.name)")
            try await client.ungroup(playerId: player.id)
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "ungroup()")
            self.lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "ungroup()")
            self.lastError = .commandFailed("ungroup", reason: error.localizedDescription)
        }
    }
}
