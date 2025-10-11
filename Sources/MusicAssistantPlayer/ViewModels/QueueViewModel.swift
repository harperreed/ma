// ABOUTME: ViewModel for queue display and upcoming tracks
// ABOUTME: Exposes read-only queue state from QueueService

import Foundation
import Combine

@MainActor
class QueueViewModel: ObservableObject {
    private let queueService: QueueService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var tracks: [Track] = []

    init(queueService: QueueService) {
        self.queueService = queueService
        setupBindings()
    }

    private func setupBindings() {
        queueService.$upcomingTracks
            .assign(to: &$tracks)
    }
}
