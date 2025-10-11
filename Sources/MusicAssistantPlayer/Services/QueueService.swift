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

    init(client: MusicAssistantClient? = nil) {
        self.client = client
        setupEventSubscriptions()
    }

    private func setupEventSubscriptions() {
        guard let client = client else { return }

        // Subscribe to queue update events
        // Will implement event parsing in next task
    }

    func fetchQueue(for playerId: String) async throws {
        guard let client = client else { return }

        // Fetch queue items from server
        // Will implement in event parsing task
    }
}
