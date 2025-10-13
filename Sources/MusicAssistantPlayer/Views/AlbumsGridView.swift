// ABOUTME: Grid view displaying albums with artwork, title, artist, and track info
// ABOUTME: Supports hover interactions for play and queue actions

import SwiftUI

struct AlbumsGridView: View {
    let albums: [Album]
    let onPlayNow: (Album) -> Void
    let onAddToQueue: (Album) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 20)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(albums) { album in
                AlbumCard(
                    album: album,
                    onPlayNow: { onPlayNow(album) },
                    onAddToQueue: { onAddToQueue(album) }
                )
            }
        }
        .padding()
    }
}

struct AlbumCard: View {
    let album: Album
    let onPlayNow: () -> Void
    let onAddToQueue: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Artwork with play button overlay
            ZStack(alignment: .bottomTrailing) {
                if let artworkURL = album.artworkURL {
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
                        Image(systemName: "square.stack")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                // Play button (visible on hover)
                if isHovered {
                    Button(action: onPlayNow) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.black)
                                    .offset(x: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            .contextMenu {
                Button("Play Now") { onPlayNow() }
                Button("Add to Queue") { onAddToQueue() }
            }

            // Album info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(album.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)

                if let year = album.year {
                    Text("\(year) • \(album.trackCount) track\(album.trackCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                } else {
                    Text("\(album.trackCount) track\(album.trackCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

#Preview {
    AlbumsGridView(
        albums: [
            Album(id: "1", title: "Test Album", artist: "Test Artist", artworkURL: nil, trackCount: 12, year: 2024, duration: 3600),
            Album(id: "2", title: "Another Album", artist: "Another Artist", artworkURL: nil, trackCount: 8, year: nil, duration: 2400)
        ],
        onPlayNow: { _ in },
        onAddToQueue: { _ in }
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
