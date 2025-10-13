// ABOUTME: Queue display showing upcoming tracks in order
// ABOUTME: Scrollable list of tracks with metadata and artwork thumbnails

import SwiftUI

struct QueueView: View {
    @ObservedObject var viewModel: QueueViewModel
    let currentTrack: Track?

    @State private var showClearConfirmation = false
    @State private var isShuffleEnabled = false
    @State private var repeatMode = "off" // "off", "all", "one"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Up Next")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    if !viewModel.tracks.isEmpty {
                        Text("\(viewModel.trackCount) tracks • \(viewModel.totalDuration)")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                Spacer()
            }
            .padding()

            Divider()
                .background(Color.white.opacity(0.1))

            // Error banner
            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        viewModel.errorMessage = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.2))
            }

            // Queue list
            if viewModel.tracks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, track in
                            QueueTrackRow(
                                track: track,
                                index: index + 1,
                                isCurrentTrack: track.id == currentTrack?.id
                            )

                            if index < viewModel.tracks.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .toolbar {
            ToolbarItemGroup {
                // Shuffle button
                Button(action: {
                    isShuffleEnabled.toggle()
                    Task {
                        try? await viewModel.shuffle(enabled: isShuffleEnabled)
                    }
                }) {
                    Image(systemName: isShuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                        .foregroundColor(isShuffleEnabled ? .green : .white.opacity(0.7))
                }
                .help("Shuffle")

                // Repeat button
                Button(action: {
                    cycleRepeatMode()
                }) {
                    Image(systemName: repeatModeIcon)
                        .foregroundColor(repeatMode != "off" ? .green : .white.opacity(0.7))
                }
                .help("Repeat: \(repeatMode)")

                // Clear queue button
                Button(action: {
                    showClearConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.white.opacity(0.7))
                }
                .help("Clear Queue")
                .disabled(viewModel.tracks.isEmpty)
            }
        }
        .alert("Clear Queue", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    try? await viewModel.clearQueue()
                }
            }
        } message: {
            Text("Are you sure you want to clear all tracks from the queue?")
        }
    }

    private var repeatModeIcon: String {
        switch repeatMode {
        case "all":
            return "repeat.circle.fill"
        case "one":
            return "repeat.1.circle.fill"
        default:
            return "repeat"
        }
    }

    private func cycleRepeatMode() {
        switch repeatMode {
        case "off":
            repeatMode = "all"
        case "all":
            repeatMode = "one"
        case "one":
            repeatMode = "off"
        default:
            repeatMode = "off"
        }

        Task {
            try? await viewModel.setRepeat(mode: repeatMode)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            Text("Queue is empty")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct QueueTrackRow: View {
    let track: Track
    let index: Int
    let isCurrentTrack: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Index or now playing indicator
            if isCurrentTrack {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .frame(width: 30, alignment: .trailing)
            } else {
                Text("\(index)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 30, alignment: .trailing)
            }

            // Thumbnail
            if let artworkURL = track.artworkURL {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder
                }
                .frame(width: 40, height: 40)
                .cornerRadius(4)
            } else {
                thumbnailPlaceholder
            }

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 14, weight: isCurrentTrack ? .semibold : .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if isCurrentTrack {
                        Text("Now Playing")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        Text(track.artist)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    Text(track.formattedDuration)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isCurrentTrack ? Color.green.opacity(0.1) : Color.clear)
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.1))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            )
    }
}

#Preview {
    let queueService = QueueService()
    queueService.upcomingTracks = [
        Track(id: "1", title: "Track One", artist: "Artist One", album: "Album", duration: 180, artworkURL: nil),
        Track(id: "2", title: "Track Two", artist: "Artist Two", album: "Album", duration: 200, artworkURL: nil),
        Track(id: "3", title: "Track Three", artist: "Artist Three", album: "Album", duration: 220, artworkURL: nil)
    ]

    return QueueView(
        viewModel: QueueViewModel(queueService: queueService),
        currentTrack: Track(id: "1", title: "Track One", artist: "Artist One", album: "Album", duration: 180, artworkURL: nil)
    )
        .frame(width: 350, height: 600)
}
