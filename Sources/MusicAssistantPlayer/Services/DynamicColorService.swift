// ABOUTME: Service for extracting and managing dynamic colors from album artwork
// ABOUTME: Provides color extraction, caching, and reactive updates via Combine

import SwiftUI
import Combine

struct ExtractedColors: Equatable {
    let dominant: Color
    let vibrant: Color
    let muted: Color
    let lightAccent: Color
    let darkAccent: Color

    init(dominant: Color, vibrant: Color, muted: Color, lightAccent: Color, darkAccent: Color) {
        self.dominant = dominant
        self.vibrant = vibrant
        self.muted = muted
        self.lightAccent = lightAccent
        self.darkAccent = darkAccent
    }

    static let fallback = ExtractedColors(
        dominant: Color(white: 0.15),
        vibrant: Color(white: 0.25),
        muted: Color(white: 0.1),
        lightAccent: Color(white: 0.3),
        darkAccent: Color(white: 0.05)
    )
}

@MainActor
class DynamicColorService: ObservableObject {
    @Published private(set) var currentColors: ExtractedColors = .fallback

    private var colorCache: [URL: ExtractedColors] = [:]

    nonisolated init() {}

    func extractColors(from artworkURL: URL?) async {
        guard let artworkURL = artworkURL else {
            currentColors = .fallback
            return
        }

        // Check cache first
        if let cached = colorCache[artworkURL] {
            currentColors = cached
            return
        }

        // For now, just return fallback colors
        // TODO: Implement actual color extraction from image
        let extracted = ExtractedColors.fallback

        // Cache and publish
        colorCache[artworkURL] = extracted
        currentColors = extracted
    }
}

// MARK: - Environment Key

struct DynamicColorServiceKey: EnvironmentKey {
    static let defaultValue = DynamicColorService()
}

extension EnvironmentValues {
    var dynamicColorService: DynamicColorService {
        get { self[DynamicColorServiceKey.self] }
        set { self[DynamicColorServiceKey.self] = newValue }
    }
}
