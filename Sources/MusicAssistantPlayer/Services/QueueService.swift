// ABOUTME: Service layer for queue management and upcoming track display
// ABOUTME: Wraps MusicAssistantKit queue operations with read-only interface

import Foundation
import Combine
import MusicAssistantKit

@MainActor
class QueueService: ObservableObject {
    @Published var upcomingTracks: [Track] = []
    @Published var queueId: String?
    @Published var lastError: QueueError?
    @Published var currentIndex: Int = 0  // Track which item is currently playing

    private let client: MusicAssistantClient?
    private var cancellables = Set<AnyCancellable>()
    private var eventTask: Task<Void, Never>?

    // MARK: - Queue Statistics

    var totalDuration: Int {
        Int(upcomingTracks.reduce(0) { $0 + $1.duration })
    }

    var formattedTotalDuration: String {
        let total = totalDuration
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var trackCount: Int {
        upcomingTracks.count
    }

    init(client: MusicAssistantClient? = nil) {
        self.client = client
        setupEventSubscriptions()
    }

    deinit {
        eventTask?.cancel()
    }

    private func setupEventSubscriptions() {
        guard let client = client else { return }

        // Subscribe to queue update events and store the task
        eventTask = Task { [weak self] in
            var retryDelay: Duration = .seconds(2)
            let maxRetryDelay: Duration = .seconds(60)

            // Retry loop with exponential backoff for resilience
            while !Task.isCancelled {
                let eventStream = await client.events.queueUpdates.values

                // Ensure stream cleanup on exit/error
                defer {
                    AppLogger.network.debug("Queue event stream iteration ended, cleanup complete")
                }

                do {
                    for await event in eventStream {
                        // Check if self is still alive
                        guard let self = self else { return }

                        // Reset retry delay on successful event reception
                        retryDelay = .seconds(2)

                        // Only process if this is our queue
                        guard await MainActor.run(body: { event.queueId == self.queueId }) else {
                            continue
                        }

                        // Extract current index from the event
                        if let currentIndexWrapper = event.data["current_index"],
                           let idx = currentIndexWrapper.value as? Int {
                            await MainActor.run {
                                self.currentIndex = idx
                            }
                        }

                        // Queue events don't contain the full item data, just metadata
                        // We need to fetch the actual queue items
                        do {
                            try await self.fetchQueue(for: event.queueId)
                        } catch {
                            AppLogger.errors.logError(error, context: "QueueService.queueUpdates")
                        }
                    }

                    // If loop completes normally (stream ended), log and retry
                    AppLogger.network.warning("Queue event stream ended normally, will retry")
                }

                // Update error state
                await MainActor.run { [weak self] in
                    self?.lastError = .networkError("Event stream disconnected")
                }

                // Don't retry if task is cancelled
                guard !Task.isCancelled else { return }

                // Exponential backoff retry
                AppLogger.network.info("Retrying queue event subscription in \(retryDelay.components.seconds)s")
                try? await Task.sleep(for: retryDelay)

                // Increase delay for next retry, capped at max
                if retryDelay < maxRetryDelay {
                    retryDelay = retryDelay * 2
                }
            }
        }
    }

    func fetchQueue(for playerId: String) async throws {
        guard let client = client else { return }

        await MainActor.run {
            self.queueId = playerId
        }

        // Fetch queue items
        if let result = try await client.getQueueItems(queueId: playerId) {
            // The result could be in different formats, try both
            if let itemsDict = result.value as? [String: Any] {
                // Extract current index if available
                var currentIdx = 0
                if let idx = itemsDict["current_index"] as? Int {
                    currentIdx = idx
                } else if let idx = itemsDict["current_item"] as? Int {
                    currentIdx = idx
                }

                let anyCodableData = itemsDict.mapValues { AnyCodable($0) }
                let allTracks = EventParser.parseQueueItems(from: anyCodableData)

                // Filter to show only upcoming tracks (after current index)
                // Current track at index X means tracks 0..<X have played, X is playing, X+1...end are upcoming
                let upcomingOnly = Array(allTracks.dropFirst(currentIdx + 1))

                await MainActor.run {
                    self.currentIndex = currentIdx
                    self.upcomingTracks = upcomingOnly
                }
            } else if let itemsArray = result.value as? [[String: Any]] {
                // If it's directly an array of items, use stored current_index for filtering
                let queueData = ["items": itemsArray]
                let anyCodableData = queueData.mapValues { AnyCodable($0) }
                let allTracks = EventParser.parseQueueItems(from: anyCodableData)

                // Use stored currentIndex to filter
                let currentIdx = await MainActor.run { self.currentIndex }
                let upcomingOnly = Array(allTracks.dropFirst(currentIdx + 1))

                await MainActor.run {
                    self.upcomingTracks = upcomingOnly
                }
            }
        }
    }

    func clearQueue() async throws {
        guard let queueId = queueId else {
            throw QueueError.queueNotFound("No queue ID available")
        }
        guard let client = client else {
            throw QueueError.networkError("No client available")
        }

        do {
            try await client.clearQueue(queueId: queueId)
            self.upcomingTracks = []
        } catch {
            throw QueueError.networkError(error.localizedDescription)
        }
    }

    func shuffle(enabled: Bool) async throws {
        guard let queueId = queueId else {
            throw QueueError.queueNotFound("No queue ID available")
        }
        guard let client = client else {
            throw QueueError.networkError("No client available")
        }

        do {
            try await client.shuffle(queueId: queueId, enabled: enabled)
        } catch {
            throw QueueError.networkError(error.localizedDescription)
        }
    }

    func setRepeat(mode: String) async throws {
        guard let queueId = queueId else {
            throw QueueError.queueNotFound("No queue ID available")
        }
        guard let client = client else {
            throw QueueError.networkError("No client available")
        }

        do {
            try await client.setRepeat(queueId: queueId, mode: mode)
        } catch {
            throw QueueError.networkError(error.localizedDescription)
        }
    }

    func removeItem(itemId: String, from queueId: String) async throws {
        guard let client = client else {
            let error = QueueError.networkError("No client available")
            lastError = error
            throw error
        }

        do {
            AppLogger.player.info("Removing item \(itemId) from queue \(queueId)")

            _ = try await client.sendCommand(
                command: "player_queues/queue_command",
                args: [
                    "queue_id": queueId,
                    "command": "delete",
                    "item_id": itemId
                ]
            )

            // Refresh queue after removal
            try await fetchQueue(for: queueId)
            lastError = nil
        } catch let error as QueueError {
            AppLogger.errors.logError(error, context: "removeItem")
            lastError = error
            throw error
        } catch {
            let queueError = QueueError.commandFailed("removeItem", reason: error.localizedDescription)
            AppLogger.errors.logError(error, context: "removeItem")
            lastError = queueError
            throw queueError
        }
    }

    func moveItem(itemId: String, from oldIndex: Int, to newIndex: Int, in queueId: String) async throws {
        guard let client = client else {
            let error = QueueError.networkError("No client available")
            lastError = error
            throw error
        }

        do {
            AppLogger.player.info("Moving item \(itemId) from index \(oldIndex) to \(newIndex)")

            _ = try await client.sendCommand(
                command: "player_queues/queue_command",
                args: [
                    "queue_id": queueId,
                    "command": "move",
                    "queue_item_id": itemId,
                    "pos_shift": newIndex - oldIndex
                ]
            )

            // Refresh queue after move
            try await fetchQueue(for: queueId)
            lastError = nil
        } catch let error as QueueError {
            AppLogger.errors.logError(error, context: "moveItem")
            lastError = error
            throw error
        } catch {
            let queueError = QueueError.commandFailed("moveItem", reason: error.localizedDescription)
            AppLogger.errors.logError(error, context: "moveItem")
            lastError = queueError
            throw queueError
        }
    }

    func addToQueue(uri: String, queueId: String, at position: Int? = nil) async throws {
        guard let client = client else {
            let error = QueueError.networkError("No client available")
            lastError = error
            throw error
        }

        do {
            AppLogger.player.info("Adding \(uri) to queue \(queueId) at position \(position?.description ?? "end")")

            var args: [String: Any] = [
                "queue_id": queueId,
                "command": "add",
                "media_items": [uri]
            ]

            if let position = position {
                args["insert_at_index"] = position
            }

            _ = try await client.sendCommand(
                command: "player_queues/queue_command",
                args: args
            )

            // Refresh queue after addition
            try await fetchQueue(for: queueId)
            lastError = nil
        } catch let error as QueueError {
            AppLogger.errors.logError(error, context: "addToQueue")
            lastError = error
            throw error
        } catch {
            let queueError = QueueError.commandFailed("addToQueue", reason: error.localizedDescription)
            AppLogger.errors.logError(error, context: "addToQueue")
            lastError = queueError
            throw queueError
        }
    }
}
