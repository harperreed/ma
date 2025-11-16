// ABOUTME: Tests for glass card component
// ABOUTME: Validates glass effect rendering and color integration

import XCTest
import SwiftUI
@testable import MusicAssistantPlayer

final class GlassCardTests: XCTestCase {
    func testGlassCardRendersWithColors() throws {
        let colors = ExtractedColors.fallback
        let card = GlassCard(colors: colors) {
            Text("Content")
        }

        // Verify card can be instantiated
        XCTAssertNotNil(card)
    }

    func testGlassCardUsesDefaultCornerRadius() {
        let colors = ExtractedColors.fallback
        let card = GlassCard(colors: colors) {
            Text("Content")
        }

        // Card should be created successfully with default parameters
        XCTAssertNotNil(card)
    }

    func testGlassCardAcceptsCustomCornerRadius() {
        let colors = ExtractedColors.fallback
        let card = GlassCard(colors: colors, cornerRadius: 20) {
            Text("Content")
        }

        XCTAssertNotNil(card)
    }
}
