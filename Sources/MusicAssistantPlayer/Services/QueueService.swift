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
    private var serverHost: String = "192.168.200.113"

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
                    self.upcomingTracks = EventParser.parseQueueItems(
                        from: event.data,
                        serverHost: self.serverHost
                    )
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
                self.upcomingTracks = EventParser.parseQueueItems(
                    from: anyCodableData,
                    serverHost: serverHost
                )
            } else if let itemsArray = result.value as? [[String: Any]] {
                // If it's directly an array of items
                let queueData = ["items": itemsArray]
                let anyCodableData = queueData.mapValues { AnyCodable($0) }
                self.upcomingTracks = EventParser.parseQueueItems(
                    from: anyCodableData,
                    serverHost: serverHost
                )
            }
        }
    }

    func setServerHost(_ host: String) {
        self.serverHost = host
    }
}
