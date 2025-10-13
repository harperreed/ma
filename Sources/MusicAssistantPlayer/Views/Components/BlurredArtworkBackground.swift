// ABOUTME: Blurred album artwork background with color extraction
// ABOUTME: Creates dynamic background from current track's artwork

import SwiftUI

struct BlurredArtworkBackground: View {
    let artworkURL: URL?
    @State private var dominantColor: Color?
    @State private var loadedImage: NSImage?

    var body: some View {
        ZStack {
            // Base gradient using extracted color or default
            LinearGradient(
                colors: [
                    (dominantColor ?? Color(red: 0.1, green: 0.1, blue: 0.15)),
                    (dominantColor?.opacity(0.6) ?? Color(red: 0.15, green: 0.15, blue: 0.2))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.8), value: dominantColor)

            // Blurred artwork overlay
            if let url = artworkURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .blur(radius: 70)
                            .opacity(0.4)
                            .transition(.opacity)
                            .task {
                                await extractColor(from: url)
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    #if canImport(AppKit)
    private func extractColor(from url: URL) async {
        // Download and extract color from actual image
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let nsImage = NSImage(data: data) else {
            return
        }

        let extractor = ColorExtractor()
        if let color = extractor.extractDominantColor(from: nsImage) {
            await MainActor.run {
                self.dominantColor = color
            }
        }
    }
    #endif
}

#Preview {
    BlurredArtworkBackground(
        artworkURL: URL(string: "https://picsum.photos/400")
    )
}
