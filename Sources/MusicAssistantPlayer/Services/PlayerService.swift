// ABOUTME: Service layer for player state management and playback control
// ABOUTME: Wraps MusicAssistantKit client and exposes Combine publishers for UI

import Foundation
import Combine
import MusicAssistantKit
import os.log

/// Atomic state container for player properties to prevent race conditions
struct PlayerState: Equatable {
    var currentTrack: Track?
    var playbackState: PlaybackState = .stopped
    var progress: TimeInterval = 0.0
    var volume: Double = 50.0
    var isShuffled: Bool = false
    var repeatMode: String = "off" // "off", "all", "one"
    var isFavorite: Bool = false
    var lastProgressUpdate: Date = Date() // Include timestamp for atomic updates

    // Custom Equatable to exclude lastProgressUpdate from comparison
    // This prevents excessive updates when only the timestamp changes
    static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
        return lhs.currentTrack?.id == rhs.currentTrack?.id &&
               lhs.playbackState == rhs.playbackState &&
               lhs.progress == rhs.progress &&
               lhs.volume == rhs.volume &&
               lhs.isShuffled == rhs.isShuffled &&
               lhs.repeatMode == rhs.repeatMode &&
               lhs.isFavorite == rhs.isFavorite
    }
}

@MainActor
class PlayerService: ObservableObject {
    @Published private(set) var state = PlayerState() {
        didSet {
            // Handle playback state changes when state updates
            if oldValue.playbackState != state.playbackState {
                handlePlaybackStateChange(oldValue: oldValue.playbackState, newValue: state.playbackState)
            }
        }
    }

    @Published var selectedPlayer: Player?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: PlayerError?

    // Convenience accessors for backward compatibility
    var currentTrack: Track? {
        get { state.currentTrack }
        set { state.currentTrack = newValue }
    }
    var playbackState: PlaybackState {
        get { state.playbackState }
        set { state.playbackState = newValue }
    }
    var progress: TimeInterval {
        get { state.progress }
        set { state.progress = newValue }
    }
    var volume: Double {
        get { state.volume }
        set { state.volume = newValue }
    }
    var isShuffled: Bool {
        get { state.isShuffled }
        set { state.isShuffled = newValue }
    }
    var repeatMode: String {
        get { state.repeatMode }
        set { state.repeatMode = newValue }
    }
    var isFavorite: Bool {
        get { state.isFavorite }
        set { state.isFavorite = newValue }
    }

    private let client: MusicAssistantClient?
    internal var cancellables = Set<AnyCancellable>()
    internal var eventTask: Task<Void, Never>?
    private var connectionMonitorTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?

    init(client: MusicAssistantClient? = nil) {
        self.client = client
        subscribeToPlayerEvents()
        monitorConnection()
        setupNowPlayingIntegration()
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
                          self.state.playbackState == .playing,
                          let duration = self.state.currentTrack?.duration,
                          self.state.progress < duration else {
                        return
                    }

                    // Increment progress by elapsed time
                    let now = Date()
                    let elapsed = now.timeIntervalSince(self.state.lastProgressUpdate)

                    // Update state atomically - includes timestamp to prevent race conditions
                    var newState = self.state
                    newState.progress += elapsed
                    newState.lastProgressUpdate = now
                    self.state = newState
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

            var retryDelay: Duration = .seconds(2)
            let maxRetryDelay: Duration = .seconds(60)

            // Retry loop with exponential backoff for resilience
            while !Task.isCancelled {
                // Reset retry delay at start of each attempt
                let eventStream = await client.events.playerUpdates.values

                // Ensure stream cleanup on exit/error
                defer {
                    AppLogger.network.debug("Player event stream iteration ended, cleanup complete")
                }

                do {
                    for await event in eventStream {
                        // Check if self is still alive
                        guard let self = self else {
                            AppLogger.player.warning("PlayerService deallocated, stopping event subscription")
                            return
                        }

                        // Reset retry delay on successful event reception
                        retryDelay = .seconds(2)

                        // Process event on MainActor
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

                            // Parse all state updates atomically
                            var newState = self.state

                            // Parse track
                            if let track = EventParser.parseTrack(from: event.data) {
                                newState.currentTrack = track
                                AppLogger.player.debug("Updated track: \(track.title)")
                            }

                            // Parse playback state
                            let parsedPlaybackState = EventParser.parsePlaybackState(from: event.data)
                            if parsedPlaybackState != newState.playbackState {
                                AppLogger.player.debug("Playback state changed: \(newState.playbackState) -> \(parsedPlaybackState)")
                                newState.playbackState = parsedPlaybackState
                            }

                            // Parse progress
                            let newProgress = EventParser.parseProgress(from: event.data)
                            AppLogger.player.debug("Progress update: \(newProgress)s")
                            newState.progress = newProgress

                            // Parse volume
                            let newVolume = EventParser.parseVolume(from: event.data)
                            if newVolume != newState.volume {
                                AppLogger.player.debug("Volume update: \(newVolume)")
                                newState.volume = newVolume
                            }

                            // Parse shuffle state
                            let newShuffled = EventParser.parseShuffleState(from: event.data)
                            if newShuffled != newState.isShuffled {
                                AppLogger.player.debug("Shuffle update: \(newShuffled)")
                                newState.isShuffled = newShuffled
                            }

                            // Parse repeat mode
                            let newRepeatMode = EventParser.parseRepeatMode(from: event.data)
                            if newRepeatMode != newState.repeatMode {
                                AppLogger.player.debug("Repeat mode update: \(newRepeatMode)")
                                newState.repeatMode = newRepeatMode
                            }

                            // Atomic state update - single notification to observers
                            newState.lastProgressUpdate = Date()
                            self.state = newState
                        }
                    }

                    // If loop completes normally (stream ended), log and retry
                    AppLogger.network.warning("Player event stream ended normally, will retry")
                } catch {
                    // Catch any unexpected errors from the stream
                    AppLogger.network.error("Player event stream error: \(error.localizedDescription)")
                }

                // Update connection state to indicate error
                await MainActor.run { [weak self] in
                    self?.connectionState = .error("Event stream disconnected")
                }

                // Don't retry if task is cancelled
                guard !Task.isCancelled else { return }

                // Exponential backoff retry
                AppLogger.network.info("Retrying player event subscription in \(retryDelay.components.seconds)s")
                try? await Task.sleep(for: retryDelay)

                // Increase delay for next retry, capped at max
                if retryDelay < maxRetryDelay {
                    retryDelay = retryDelay * 2
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

                // Parse all state atomically
                var newState = self.state

                // Parse track
                if let track = EventParser.parseTrack(from: anyCodableData) {
                    newState.currentTrack = track
                } else {
                    newState.currentTrack = nil
                }

                // Parse playback state
                newState.playbackState = EventParser.parsePlaybackState(from: anyCodableData)

                // Parse progress
                newState.progress = EventParser.parseProgress(from: anyCodableData)

                // Parse volume
                newState.volume = EventParser.parseVolume(from: anyCodableData)

                // Parse shuffle state
                newState.isShuffled = EventParser.parseShuffleState(from: anyCodableData)

                // Parse repeat mode
                newState.repeatMode = EventParser.parseRepeatMode(from: anyCodableData)

                // Atomic state update
                newState.lastProgressUpdate = Date()
                self.state = newState
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
        var newState = state
        newState.progress = position
        newState.lastProgressUpdate = Date()
        state = newState

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
        var newState = state
        newState.volume = volume
        state = newState

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

    func setShuffle(enabled: Bool) async {
        // Optimistically update for immediate UI feedback
        var newState = state
        newState.isShuffled = enabled
        state = newState

        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.info("Setting shuffle to: \(enabled) on player: \(player.name)")

            // Music Assistant API: player_queues/queue_command with shuffle
            try await client.sendCommand(
                command: "player_queues/queue_command",
                args: [
                    "queue_id": player.id,
                    "command": "shuffle",
                    "shuffle": enabled
                ]
            )
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "setShuffle(\(enabled))")
            lastError = error
            // Rollback on failure
            var rollbackState = state
            rollbackState.isShuffled = !enabled
            state = rollbackState
        } catch {
            AppLogger.errors.logError(error, context: "setShuffle(\(enabled))")
            lastError = .commandFailed("setShuffle", reason: error.localizedDescription)
            var rollbackState = state
            rollbackState.isShuffled = !enabled
            state = rollbackState
        }
    }

    func setRepeat(mode: String) async {
        // Store old mode for rollback
        let oldMode = state.repeatMode

        // Optimistically update for immediate UI feedback
        var newState = state
        newState.repeatMode = mode
        state = newState

        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }
            guard let player = selectedPlayer else {
                throw PlayerError.playerNotFound("No player selected")
            }
            AppLogger.player.info("Setting repeat to: \(mode) on player: \(player.name)")

            // Music Assistant API: player_queues/queue_command with repeat
            try await client.sendCommand(
                command: "player_queues/queue_command",
                args: [
                    "queue_id": player.id,
                    "command": "repeat",
                    "repeat": mode
                ]
            )
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "setRepeat(\(mode))")
            lastError = error
            // Rollback on failure
            var rollbackState = state
            rollbackState.repeatMode = oldMode
            state = rollbackState
        } catch {
            AppLogger.errors.logError(error, context: "setRepeat(\(mode))")
            lastError = .commandFailed("setRepeat", reason: error.localizedDescription)
            var rollbackState = state
            rollbackState.repeatMode = oldMode
            state = rollbackState
        }
    }

    func toggleFavorite(trackId: String) async {
        // Optimistically toggle for immediate UI feedback
        var newState = state
        newState.isFavorite.toggle()
        let newFavoriteState = newState.isFavorite
        state = newState

        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }

            AppLogger.player.info("Toggling favorite for track: \(trackId) to: \(newFavoriteState)")

            // Music Assistant API: music/tracks/favorite
            try await client.sendCommand(
                command: "music/tracks/favorite",
                args: [
                    "item_id": trackId,
                    "favorite": newFavoriteState
                ]
            )
            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "toggleFavorite(\(trackId))")
            lastError = error
            // Rollback on failure
            var rollbackState = state
            rollbackState.isFavorite = !newFavoriteState
            state = rollbackState
        } catch {
            AppLogger.errors.logError(error, context: "toggleFavorite(\(trackId))")
            lastError = .commandFailed("toggleFavorite", reason: error.localizedDescription)
            var rollbackState = state
            rollbackState.isFavorite = !newFavoriteState
            state = rollbackState
        }
    }

    func checkIfFavorite(trackId: String) async {
        do {
            guard let client = client else {
                throw PlayerError.networkError("No client available")
            }

            // Music Assistant API: music/tracks/get
            let result = try await client.sendCommand(
                command: "music/tracks/get",
                args: ["item_id": trackId]
            )

            // Parse favorite status from result
            if let result = result,
               let trackData = result.value as? [String: Any],
               let favorite = trackData["favorite"] as? Bool {
                // Verify track hasn't changed before updating state
                guard self.state.currentTrack?.id == trackId else { return }
                var newState = state
                newState.isFavorite = favorite
                state = newState
            } else {
                // Verify track hasn't changed before updating state
                guard self.state.currentTrack?.id == trackId else { return }
                var newState = state
                newState.isFavorite = false
                state = newState
            }

            lastError = nil
        } catch let error as PlayerError {
            AppLogger.errors.logPlayerError(error, context: "checkIfFavorite(\(trackId))")
            lastError = error
        } catch {
            AppLogger.errors.logError(error, context: "checkIfFavorite(\(trackId))")
            lastError = .commandFailed("checkIfFavorite", reason: error.localizedDescription)
        }
    }
}
