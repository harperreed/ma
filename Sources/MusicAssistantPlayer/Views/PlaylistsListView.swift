// ABOUTME: List view displaying playlists with artwork, name, and track count
// ABOUTME: Supports hover interactions for play and queue actions

import SwiftUI

struct PlaylistsListView: View {
    let playlists: [Playlist]
    let onPlayNow: (Playlist) -> Void
    let onAddToQueue: (Playlist) -> Void

    var body: some View {
        VStack(spacing: 1) {
            ForEach(playlists) { playlist in
                PlaylistRow(
                    playlist: playlist,
                    onPlayNow: { onPlayNow(playlist) },
                    onAddToQueue: { onAddToQueue(playlist) }
                )
            }
        }
        .padding()
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    let onPlayNow: () -> Void
    let onAddToQueue: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Artwork
            ZStack {
                if let artworkURL = playlist.artworkURL {
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
                        Image(systemName: "music.note.list")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                // Play button overlay (visible on hover)
                if isHovered {
                    Button(action: onPlayNow) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.black)
                                    .font(.system(size: 16))
                                    .offset(x: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Playlist info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let owner = playlist.owner {
                        Text("By \(owner)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Text("\(playlist.trackCount) track\(playlist.trackCount == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

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
        .padding(.vertical, 8)
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
    PlaylistsListView(
        playlists: [
            Playlist(id: "1", name: "My Favorites", artworkURL: nil, trackCount: 50, duration: 12000, owner: "harper"),
            Playlist(id: "2", name: "Workout Mix", artworkURL: nil, trackCount: 30, duration: 7200, owner: nil)
        ],
        onPlayNow: { _ in },
        onAddToQueue: { _ in }
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
