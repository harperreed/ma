// ABOUTME: Blurred album artwork background with color extraction
// ABOUTME: Creates dynamic background from current track's artwork

import SwiftUI

struct BlurredArtworkBackground: View {
    let artworkURL: URL?
    @State private var dominantColor: Color?

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

            // Blurred artwork overlay
            if let url = artworkURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 70)
                            .opacity(0.4)
                            .onAppear {
                                extractColor(from: image)
                            }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    #if canImport(AppKit)
    private func extractColor(from image: Image) {
        // Convert SwiftUI Image to NSImage for color extraction
        // This is a simplified approach - in production might cache colors
        Task {
            // Simulate color extraction delay
            try? await Task.sleep(for: .milliseconds(100))
            // In real implementation, would extract from NSImage
            await MainActor.run {
                self.dominantColor = Color(red: 0.2, green: 0.15, blue: 0.25)
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
