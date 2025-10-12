// ABOUTME: Tests for color extraction from images
// ABOUTME: Validates dominant color detection and gradient generation

import XCTest
@testable import MusicAssistantPlayer
#if canImport(AppKit)
import AppKit
#endif

final class ColorExtractorTests: XCTestCase {
    func testExtractDominantColor() {
        // Create a solid red image
        let size = CGSize(width: 100, height: 100)
        let image = createSolidColorImage(color: .red, size: size)

        let extractor = ColorExtractor()
        let dominantColor = extractor.extractDominantColor(from: image)

        XCTAssertNotNil(dominantColor)
        // Red should be dominant
        let components = dominantColor?.cgColor?.components
        XCTAssertNotNil(components)
        XCTAssertGreaterThan(components?[0] ?? 0, 0.8) // Red channel
    }

    func testExtractColorPalette() {
        let size = CGSize(width: 100, height: 100)
        let image = createSolidColorImage(color: .blue, size: size)

        let extractor = ColorExtractor()
        let palette = extractor.extractPalette(from: image, count: 3)

        XCTAssertEqual(palette.count, 3)
        XCTAssertNotNil(palette.first)
    }

    private func createSolidColorImage(color: NSColor, size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }
}
