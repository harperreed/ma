// ABOUTME: Collapsible sidebar for library navigation with categories and providers
// ABOUTME: Displays library categories (Artists, Albums, etc.) and music providers (Spotify, Tidal, etc.)

import SwiftUI

struct LibrarySidebarView: View {
    @Binding var selectedCategory: LibraryCategory?
    let providers: [String] // Provider names from Music Assistant
    let currentTrackTitle: String?
    let currentArtist: String?
    let currentColors: ExtractedColors
    let onNowPlayingTap: () -> Void

    @State private var isLibraryExpanded = true
    @State private var isProvidersExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Now Playing Card
            nowPlayingCard
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.top, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.xs)

            Divider()
                .background(currentColors.vibrant.opacity(0.2))
                .padding(.vertical, DesignSystem.Spacing.xs)

            // Library Section
            DisclosureGroup(
                isExpanded: $isLibraryExpanded,
                content: {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        ForEach(LibraryCategory.allCases) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                colors: currentColors,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.leading, DesignSystem.Spacing.xs)
                    .padding(.top, DesignSystem.Spacing.xs)
                },
                label: {
                    Text("LIBRARY")
                        .font(DesignSystem.Typography.label)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, DesignSystem.Spacing.xs)
                }
            )
            .padding(.horizontal, DesignSystem.Spacing.sm)

            Divider()
                .background(currentColors.vibrant.opacity(0.2))
                .padding(.vertical, DesignSystem.Spacing.xs)

            // Providers Section
            DisclosureGroup(
                isExpanded: $isProvidersExpanded,
                content: {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        ForEach(providers, id: \.self) { provider in
                            ProviderButton(
                                name: provider,
                                colors: currentColors,
                                action: {
                                    // TODO: Implement provider filtering
                                }
                            )
                        }
                    }
                    .padding(.leading, DesignSystem.Spacing.xs)
                    .padding(.top, DesignSystem.Spacing.xs)
                },
                label: {
                    Text("PROVIDERS")
                        .font(DesignSystem.Typography.label)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, DesignSystem.Spacing.xs)
                }
            )
            .padding(.horizontal, DesignSystem.Spacing.sm)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }

    // MARK: - Now Playing Card

    private var nowPlayingCard: some View {
        Button(action: onNowPlayingTap) {
            GlassCard(colors: currentColors) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    HStack {
                        Image(systemName: "music.note")
                            .font(DesignSystem.Typography.body)
                        Text("NOW PLAYING")
                            .font(DesignSystem.Typography.label)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundColor(.white.opacity(0.5))

                    if let title = currentTrackTitle {
                        Text(title)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if let artist = currentArtist {
                            Text(artist)
                                .font(DesignSystem.Typography.label)
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    } else {
                        Text("No track playing")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(DesignSystem.Spacing.sm)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CategoryButton: View {
    let category: LibraryCategory
    let isSelected: Bool
    let colors: ExtractedColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: category.iconName)
                    .font(DesignSystem.Typography.body)
                    .frame(width: 16)

                Text(category.displayName)
                    .font(DesignSystem.Typography.body)

                Spacer()
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.vertical, 6)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .background(
                isSelected ? colors.vibrant.opacity(0.2) : Color.clear
            )
            .cornerRadius(6)
            .overlay(
                isSelected ?
                    Rectangle()
                        .fill(colors.vibrant)
                        .frame(width: 2)
                        .cornerRadius(1)
                    : nil,
                alignment: .leading
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: DesignSystem.Animation.quick), value: isSelected)
    }
}

struct ProviderButton: View {
    let name: String
    let colors: ExtractedColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "music.note.house")
                    .font(DesignSystem.Typography.body)
                    .frame(width: 16)

                Text(name)
                    .font(DesignSystem.Typography.body)

                Spacer()
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.vertical, 6)
            .padding(.horizontal, DesignSystem.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// #Preview {
//     LibrarySidebarView(
//         selectedCategory: .constant(.artists),
//         providers: ["Spotify", "Tidal", "Local Files"],
//         currentTrackTitle: "Song Title",
//         currentArtist: "Artist Name",
//         currentColors: .fallback,
//         onNowPlayingTap: {}
//     )
//     .frame(height: 600)
// }
