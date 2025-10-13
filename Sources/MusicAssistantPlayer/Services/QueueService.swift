// ABOUTME: Service layer for queue management and upcoming track display
// ABOUTME: Wraps MusicAssistantKit queue operations with read-only interface

import Foundation
import Combine
import MusicAssistantKit

@MainActor
class QueueService: ObservableObject {
    @Published var upcomingTracks: [Track] = []
    @Published var queueId: String?

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
            throw QueueError.queueEmpty
        }
        guard let client = client else {
            throw QueueError.networkFailure
        }

        do {
            try await client.clearQueue(queueId: queueId)
            await MainActor.run {
                self.upcomingTracks = []
            }
        } catch {
            throw QueueError.networkFailure
        }
    }

    func shuffle(enabled: Bool) async throws {
        guard let queueId = queueId else {
            throw QueueError.queueEmpty
        }
        guard let client = client else {
            throw QueueError.networkFailure
        }

        do {
            try await client.shuffle(queueId: queueId, enabled: enabled)
        } catch {
            throw QueueError.networkFailure
        }
    }

    func setRepeat(mode: String) async throws {
        guard let queueId = queueId else {
            throw QueueError.queueEmpty
        }
        guard let client = client else {
            throw QueueError.networkFailure
        }

        do {
            try await client.setRepeat(queueId: queueId, mode: mode)
        } catch {
            throw QueueError.networkFailure
        }
    }
}
