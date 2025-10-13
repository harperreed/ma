// ABOUTME: Queue display showing upcoming tracks in order
// ABOUTME: Scrollable list of tracks with metadata and artwork thumbnails

import SwiftUI

struct QueueView: View {
    @ObservedObject var viewModel: QueueViewModel
    let currentTrack: Track?

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
