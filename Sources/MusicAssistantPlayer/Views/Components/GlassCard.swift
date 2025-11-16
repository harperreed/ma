// ABOUTME: Reusable glass card component with dynamic color integration
// ABOUTME: Provides consistent glass material effect across the app using system materials

import SwiftUI

struct GlassCard<Content: View>: View {
    let colors: ExtractedColors
    let cornerRadius: CGFloat
    let borderOpacity: Double
    let content: Content

    init(
        colors: ExtractedColors,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.relaxed,
        borderOpacity: Double = 0.15,
        @ViewBuilder content: () -> Content
    ) {
        self.colors = colors
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.content = content()
    }

    var body: some View {
        content
            .background(
                ZStack {
                    // Glass blur effect using system material
                    Color.clear
                        .background(.ultraThinMaterial)

                    // Tinted overlay
                    colors.muted
                        .opacity(0.2)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(colors.vibrant.opacity(borderOpacity), lineWidth: 1)
                    .shadow(color: colors.vibrant.opacity(0.05), radius: 8)
            )
    }
}

#Preview {
    ZStack {
        Color.black

        GlassCard(colors: .fallback) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Glass Card")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(.white)

                Text("This is a glass card with dynamic colors")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(DesignSystem.Spacing.md)
        }
        .frame(width: 300, height: 150)
        .padding()
    }
}
