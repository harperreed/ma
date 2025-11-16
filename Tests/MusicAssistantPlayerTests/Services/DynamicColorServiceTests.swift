// ABOUTME: Tests for dynamic color extraction service
// ABOUTME: Validates color extraction, caching, and fallback behavior

import XCTest
import SwiftUI
@testable import MusicAssistantPlayer

@MainActor
final class DynamicColorServiceTests: XCTestCase {
    var service: DynamicColorService!

    override func setUp() async throws {
        service = DynamicColorService()
    }

    func testFallbackColors() {
        let colors = service.currentColors

        // Should return fallback colors when no artwork
        XCTAssertNotNil(colors.dominant)
        XCTAssertNotNil(colors.vibrant)
        XCTAssertNotNil(colors.muted)
        XCTAssertNotNil(colors.lightAccent)
        XCTAssertNotNil(colors.darkAccent)
    }

    func testColorExtractionWithNilURL() async {
        await service.extractColors(from: nil)

        let colors = service.currentColors

        // Should use fallback colors
        XCTAssertEqual(colors.dominant, Color(white: 0.15))
    }

    func testCachingBehavior() async {
        let url = URL(string: "https://example.com/artwork.jpg")!

        // Extract colors twice
        await service.extractColors(from: url)
        let firstColors = service.currentColors

        await service.extractColors(from: url)
        let secondColors = service.currentColors

        // Colors should be identical (cached)
        XCTAssertEqual(firstColors.dominant, secondColors.dominant)
    }
}
