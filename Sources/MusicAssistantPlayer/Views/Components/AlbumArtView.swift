// ABOUTME: Album artwork display component with placeholder fallback
// ABOUTME: Handles async image loading and adaptive background blur effect

import SwiftUI

struct AlbumArtView: View {
    let artworkURL: URL?
    let size: CGFloat

    var body: some View {
        ZStack {
            if let url = artworkURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
                            // Add subtle glow effect
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: size, height: size)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .gray.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.3))
                    .foregroundColor(.white.opacity(0.6))
            )
            .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 40) {
        AlbumArtView(artworkURL: nil, size: 300)
        AlbumArtView(
            artworkURL: URL(string: "https://picsum.photos/300"),
            size: 300
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
