// ABOUTME: List view for displaying radio stations from Music Assistant
// ABOUTME: Provides play and queue actions for radio stations

import SwiftUI

struct RadiosListView: View {
    let radios: [Radio]
    let onPlayNow: (Radio) -> Void
    let onAddToQueue: (Radio) -> Void
    let onLoadMore: (() -> Void)?

    @State private var hoveredRadio: Radio.ID?

    var body: some View {
        ScrollView {
            if radios.isEmpty {
                Text("No radio stations found")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(radios) { radio in
                        radioRow(radio)
                            .onHover { isHovered in
                                hoveredRadio = isHovered ? radio.id : nil
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

    private func radioRow(_ radio: Radio) -> some View {
        HStack(spacing: 12) {
            // Artwork
            if let artworkURL = radio.artworkURL {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 40, height: 40)
                .cornerRadius(4)
            } else {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(4)
            }

            // Station info
            VStack(alignment: .leading, spacing: 2) {
                Text(radio.name)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let provider = radio.provider {
                    Text(provider)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Action buttons (show on hover)
            if hoveredRadio == radio.id {
                HStack(spacing: 8) {
                    Button(action: { onPlayNow(radio) }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { onAddToQueue(radio) }) {
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
            hoveredRadio == radio.id ?
                Color.white.opacity(0.1) : Color.clear
        )
    }
}

// MARK: - Preview
#Preview {
    let sampleRadios = [
        Radio(id: "1", name: "KEXP 90.3 FM", artworkURL: nil, provider: "Radio Browser"),
        Radio(id: "2", name: "BBC Radio 6", artworkURL: nil, provider: "TuneIn"),
        Radio(id: "3", name: "NTS Radio", artworkURL: nil, provider: "Radio Browser")
    ]

    return RadiosListView(
        radios: sampleRadios,
        onPlayNow: { _ in },
        onAddToQueue: { _ in },
        onLoadMore: nil
    )
    .frame(width: 600, height: 400)
    .background(Color.black)
}
