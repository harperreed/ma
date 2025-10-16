// ABOUTME: Grid view displaying artists with artwork, name, and album count
// ABOUTME: Supports hover interactions for play and queue actions

import SwiftUI

struct ArtistsGridView: View {
    let artists: [Artist]
    let onPlayNow: (Artist) -> Void
    let onAddToQueue: (Artist) -> Void
    var onArtistSelected: ((Artist) -> Void)? = nil
    var onLoadMore: (() -> Void)? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 20)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(artists) { artist in
                ArtistCard(
                    artist: artist,
                    onPlayNow: { onPlayNow(artist) },
                    onAddToQueue: { onAddToQueue(artist) },
                    onTap: onArtistSelected != nil ? { onArtistSelected?(artist) } : nil
                )
                .onAppear {
                    // Trigger load more when the last item appears
                    if artist.id == artists.last?.id {
                        onLoadMore?()
                    }
                }
            }
        }
        .padding()
    }
}

struct ArtistCard: View {
    let artist: Artist
    let onPlayNow: () -> Void
    let onAddToQueue: () -> Void
    var onTap: (() -> Void)? = nil

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Artwork with play button overlay
            ZStack(alignment: .bottomTrailing) {
                if let artworkURL = artist.artworkURL {
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
                        Image(systemName: "person.2")
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

            // Artist info
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text("\(artist.albumCount) album\(artist.albumCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

#Preview {
    ArtistsGridView(
        artists: [
            Artist(id: "1", name: "Test Artist", artworkURL: nil, albumCount: 5),
            Artist(id: "2", name: "Another Artist", artworkURL: nil, albumCount: 12)
        ],
        onPlayNow: { _ in },
        onAddToQueue: { _ in }
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
