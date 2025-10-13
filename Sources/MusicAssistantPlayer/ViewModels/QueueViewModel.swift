// ABOUTME: ViewModel for queue display and management operations
// ABOUTME: Exposes queue state and wraps service operations with error handling

import Foundation
import Combine

@MainActor
class QueueViewModel: ObservableObject {
    private let queueService: QueueService
    private let playerService: PlayerService?
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var tracks: [Track] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isShuffled: Bool = false
    @Published var repeatMode: String = "off" // "off", "all", "one"

    init(queueService: QueueService, playerService: PlayerService? = nil) {
        self.queueService = queueService
        self.playerService = playerService
        setupBindings()
    }

    private func setupBindings() {
        queueService.$upcomingTracks
            .assign(to: &$tracks)

        // Bind shuffle/repeat state from PlayerService
        playerService?.$isShuffled
            .assign(to: &$isShuffled)

        playerService?.$repeatMode
            .assign(to: &$repeatMode)
    }

    // MARK: - Queue Operations

    func clearQueue() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await queueService.clearQueue()
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func shuffle(enabled: Bool) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await queueService.shuffle(enabled: enabled)
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func setRepeat(mode: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await queueService.setRepeat(mode: mode)
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func toggleShuffle() async {
        guard let playerService = playerService else { return }
        await playerService.setShuffle(enabled: !isShuffled)
    }

    func cycleRepeatMode() async {
        guard let playerService = playerService else { return }
        let nextMode: String
        switch repeatMode {
        case "off": nextMode = "all"
        case "all": nextMode = "one"
        case "one": nextMode = "off"
        default: nextMode = "off"
        }
        await playerService.setRepeat(mode: nextMode)
    }

    // MARK: - Queue Manipulation

    func removeTrack(id: String, from queueId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await queueService.removeItem(itemId: id, from: queueId)
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to remove track"
        }
    }

    func moveTrack(id: String, from oldIndex: Int, to newIndex: Int, in queueId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await queueService.moveItem(itemId: id, from: oldIndex, to: newIndex, in: queueId)
            errorMessage = nil
        } catch let error as QueueError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to move track"
        }
    }

    // MARK: - Error Handling

    func clearError() {
        queueService.lastError = nil
        errorMessage = nil
    }

    // MARK: - Computed Properties

    var queueId: String? {
        playerService?.selectedPlayer?.id
    }

    // MARK: - Statistics

    var trackCount: Int {
        queueService.trackCount
    }

    var totalDuration: String {
        queueService.formattedTotalDuration
    }
}
