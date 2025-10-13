// ABOUTME: List view displaying tracks with artwork, title, artist, album, and duration
// ABOUTME: Supports hover interactions for play and queue actions

import SwiftUI

struct TracksListView: View {
    let tracks: [Track]
    let onPlayNow: (Track) -> Void
    let onAddToQueue: (Track) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(tracks) { track in
                    TrackRow(
                        track: track,
                        onPlayNow: { onPlayNow(track) },
                        onAddToQueue: { onAddToQueue(track) }
                    )
                }
            }
            .padding()
        }
    }
}

struct TrackRow: View {
    let track: Track
    let onPlayNow: () -> Void
    let onAddToQueue: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Artwork
            ZStack {
                if let artworkURL = track.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                } else {
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                // Play button overlay (visible on hover)
                if isHovered {
                    Button(action: onPlayNow) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.black)
                                    .font(.system(size: 12))
                                    .offset(x: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)

                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))

                    Text(track.album)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Duration
            Text(track.formattedDuration)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 50, alignment: .trailing)

            // Three-dot menu button (visible on hover)
            if isHovered {
                Menu {
                    Button("Play Now") { onPlayNow() }
                    Button("Add to Queue") { onAddToQueue() }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(isHovered ? Color.white.opacity(0.05) : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Play Now") { onPlayNow() }
            Button("Add to Queue") { onAddToQueue() }
        }
    }
}

#Preview {
    TracksListView(
        tracks: [
            Track(id: "1", title: "Song Title", artist: "Artist Name", album: "Album Name", duration: 240, artworkURL: nil),
            Track(id: "2", title: "Another Song", artist: "Different Artist", album: "Another Album", duration: 180, artworkURL: nil)
        ],
        onPlayNow: { _ in },
        onAddToQueue: { _ in }
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
