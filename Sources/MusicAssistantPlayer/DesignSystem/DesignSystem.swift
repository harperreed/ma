// ABOUTME: Centralized design system constants for spacing, typography, colors, and layout
// ABOUTME: Provides consistent design tokens across the application

import SwiftUI

enum DesignSystem {

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let tight: CGFloat = 4
        static let standard: CGFloat = 8
        static let relaxed: CGFloat = 12
        static let round: CGFloat = 16
    }

    // MARK: - Typography

    enum Typography {
        static let display = Font.system(size: 32, weight: .bold)
        static let titleLarge = Font.system(size: 24, weight: .semibold)
        static let title = Font.system(size: 18, weight: .semibold)
        static let bodyLarge = Font.system(size: 16, weight: .medium)
        static let body = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
        static let label = Font.system(size: 11, weight: .semibold)
    }

    // MARK: - Animation

    enum Animation {
        static let instant: Double = 0.1
        static let quick: Double = 0.15
        static let standard: Double = 0.2
        static let deliberate: Double = 0.25
    }

    // MARK: - Layout

    enum Layout {
        static let compactBreakpoint: CGFloat = 800
        static let mediumBreakpoint: CGFloat = 1100
        static let expandedBreakpoint: CGFloat = 1400

        static let sidebarWidth: CGFloat = 240
        static let queueWidth: CGFloat = 360
        static let miniPlayerHeight: CGFloat = 96
    }

    // MARK: - Shadows

    enum Shadow {
        static let light = (color: Color.black.opacity(0.2), radius: CGFloat(4), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.3), radius: CGFloat(8), y: CGFloat(4))
        static let heavy = (color: Color.black.opacity(0.5), radius: CGFloat(16), y: CGFloat(8))
    }

    enum ShadowLevel {
        case light
        case medium
        case heavy
    }
}

// MARK: - View Extensions

extension View {
    func designSystemShadow(_ level: DesignSystem.ShadowLevel) -> some View {
        let shadow = switch level {
            case .light: DesignSystem.Shadow.light
            case .medium: DesignSystem.Shadow.medium
            case .heavy: DesignSystem.Shadow.heavy
        }
        return self.shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
    }
}
