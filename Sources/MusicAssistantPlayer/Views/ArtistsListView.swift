// ABOUTME: List view for displaying artists from Music Assistant
// ABOUTME: Provides play, queue, and selection actions for artists

import SwiftUI

struct ArtistsListView: View {
    let artists: [Artist]
    let onPlayNow: (Artist) -> Void
    let onAddToQueue: (Artist) -> Void
    let onArtistSelected: (Artist) -> Void
    let onLoadMore: (() -> Void)?

    @State private var hoveredArtist: Artist.ID?

    var body: some View {
        ScrollView {
            if artists.isEmpty {
                Text("No artists found")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(artists) { artist in
                        artistRow(artist)
                            .onHover { isHovered in
                                hoveredArtist = isHovered ? artist.id : nil
                            }
                    }

                    // Load more trigger
                    if let loadMore = onLoadMore {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                loadMore()
                            }
                    }
                }
            }
        }
    }

    private func artistRow(_ artist: Artist) -> some View {
        Button(action: { onArtistSelected(artist) }) {
            HStack(spacing: 12) {
                // Artwork
                if let artworkURL = artist.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "music.mic")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }

                // Artist info
                VStack(alignment: .leading, spacing: 2) {
                    Text(artist.name)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if artist.albumCount > 0 {
                        Text("\(artist.albumCount) album\(artist.albumCount == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Action buttons (show on hover)
                if hoveredArtist == artist.id {
                    HStack(spacing: 8) {
                        Button(action: { onPlayNow(artist) }) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { onAddToQueue(artist) }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.gray.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                hoveredArtist == artist.id ?
                    Color.white.opacity(0.1) : Color.clear
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    let sampleArtists = [
        Artist(id: "1", name: "The Beatles", artworkURL: nil, albumCount: 13),
        Artist(id: "2", name: "Pink Floyd", artworkURL: nil, albumCount: 15),
        Artist(id: "3", name: "Led Zeppelin", artworkURL: nil, albumCount: 8)
    ]

    return ArtistsListView(
        artists: sampleArtists,
        onPlayNow: { _ in },
        onAddToQueue: { _ in },
        onArtistSelected: { _ in },
        onLoadMore: nil
    )
    .frame(width: 600, height: 400)
    .background(Color.black)
}
