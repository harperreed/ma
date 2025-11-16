// ABOUTME: Tests for design system constants and utilities
// ABOUTME: Validates spacing, typography, and layout values

import XCTest
@testable import MusicAssistantPlayer

final class DesignSystemTests: XCTestCase {
    func testSpacingScale() {
        XCTAssertEqual(DesignSystem.Spacing.xxs, 4)
        XCTAssertEqual(DesignSystem.Spacing.xs, 8)
        XCTAssertEqual(DesignSystem.Spacing.sm, 12)
        XCTAssertEqual(DesignSystem.Spacing.md, 16)
        XCTAssertEqual(DesignSystem.Spacing.lg, 24)
        XCTAssertEqual(DesignSystem.Spacing.xl, 32)
        XCTAssertEqual(DesignSystem.Spacing.xxl, 48)
    }

    func testCornerRadiusScale() {
        XCTAssertEqual(DesignSystem.CornerRadius.tight, 4)
        XCTAssertEqual(DesignSystem.CornerRadius.standard, 8)
        XCTAssertEqual(DesignSystem.CornerRadius.relaxed, 12)
        XCTAssertEqual(DesignSystem.CornerRadius.round, 16)
    }

    func testLayoutBreakpoints() {
        XCTAssertEqual(DesignSystem.Layout.compactBreakpoint, 800)
        XCTAssertEqual(DesignSystem.Layout.mediumBreakpoint, 1100)
        XCTAssertEqual(DesignSystem.Layout.expandedBreakpoint, 1400)
    }
}
