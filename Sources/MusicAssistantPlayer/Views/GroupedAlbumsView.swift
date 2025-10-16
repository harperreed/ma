// ABOUTME: Grouped album view that organizes albums by type (Albums, Singles, EPs, etc)
// ABOUTME: Used for artist detail pages to show organized discography

import SwiftUI

struct GroupedAlbumsView: View {
    let albums: [Album]
    let onPlayNow: (Album) -> Void
    let onAddToQueue: (Album) -> Void
    let onAlbumSelected: ((Album) -> Void)?

    private var groupedAlbums: [(AlbumType, [Album])] {
        let grouped = Dictionary(grouping: albums, by: { $0.albumType })
        return grouped
            .sorted { $0.key.sortOrder < $1.key.sortOrder }
            .map { ($0.key, $0.value.sorted { ($0.year ?? 0) > ($1.year ?? 0) }) }
            .filter { !$0.1.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                ForEach(groupedAlbums, id: \.0) { albumType, typeAlbums in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section header with count
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(albumType.displayName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            Text("(\(typeAlbums.count))")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal)

                        // Albums grid for this type
                        AlbumsGridView(
                            albums: typeAlbums,
                            onPlayNow: onPlayNow,
                            onAddToQueue: onAddToQueue,
                            onAlbumSelected: onAlbumSelected,
                            onLoadMore: nil
                        )
                    }
                }

                if groupedAlbums.isEmpty {
                    Text("No albums found")
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    GroupedAlbumsView(
        albums: [
            Album(id: "1", title: "Studio Album", artist: "Test Artist", artworkURL: nil, trackCount: 12, year: 2024, duration: 3600, albumType: .album),
            Album(id: "2", title: "Greatest Hits", artist: "Test Artist", artworkURL: nil, trackCount: 20, year: 2023, duration: 4800, albumType: .compilation),
            Album(id: "3", title: "New Single", artist: "Test Artist", artworkURL: nil, trackCount: 1, year: 2024, duration: 240, albumType: .single),
            Album(id: "4", title: "EP Release", artist: "Test Artist", artworkURL: nil, trackCount: 5, year: 2023, duration: 1200, albumType: .ep)
        ],
        onPlayNow: { _ in },
        onAddToQueue: { _ in },
        onAlbumSelected: { _ in }
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
