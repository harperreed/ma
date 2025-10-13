// ABOUTME: ViewModel for queue display and management operations
// ABOUTME: Exposes queue state and wraps service operations with error handling

import Foundation
import Combine

@MainActor
class QueueViewModel: ObservableObject {
    private let queueService: QueueService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var tracks: [Track] = []
    @Published var errorMessage: String?

    init(queueService: QueueService) {
        self.queueService = queueService
        setupBindings()
    }

    private func setupBindings() {
        queueService.$upcomingTracks
            .assign(to: &$tracks)
    }

    // MARK: - Queue Operations

    func clearQueue() async throws {
        do {
            try await queueService.clearQueue()
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.userMessage
            throw error
        }
    }

    func shuffle(enabled: Bool) async throws {
        do {
            try await queueService.shuffle(enabled: enabled)
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.userMessage
            throw error
        }
    }

    func setRepeat(mode: String) async throws {
        do {
            try await queueService.setRepeat(mode: mode)
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.userMessage
            throw error
        }
    }

    // MARK: - Statistics

    var trackCount: Int {
        queueService.trackCount
    }

    var totalDuration: String {
        queueService.formattedTotalDuration
    }
}
