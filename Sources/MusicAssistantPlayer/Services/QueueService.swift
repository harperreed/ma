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
            guard let self = self else { return }

            for await event in await client.events.queueUpdates.values {
                await MainActor.run {
                    // Only process if this is our queue
                    guard event.queueId == self.queueId else { return }

                    // Parse queue items
                    self.upcomingTracks = EventParser.parseQueueItems(from: event.data)
                }
            }
        }
    }

    func fetchQueue(for playerId: String) async throws {
        guard let client = client else { return }

        self.queueId = playerId

        // Fetch queue items
        if let result = try await client.getQueueItems(queueId: playerId) {
            // The result could be in different formats, try both
            if let itemsDict = result.value as? [String: Any] {
                // If it's already a dictionary with "items" key
                let anyCodableData = itemsDict.mapValues { AnyCodable($0) }
                self.upcomingTracks = EventParser.parseQueueItems(from: anyCodableData)
            } else if let itemsArray = result.value as? [[String: Any]] {
                // If it's directly an array of items
                let queueData = ["items": itemsArray]
                let anyCodableData = queueData.mapValues { AnyCodable($0) }
                self.upcomingTracks = EventParser.parseQueueItems(from: anyCodableData)
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
