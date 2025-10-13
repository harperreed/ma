// ABOUTME: Collapsible sidebar for library navigation with categories and providers
// ABOUTME: Displays library categories (Artists, Albums, etc.) and music providers (Spotify, Tidal, etc.)

import SwiftUI

struct LibrarySidebarView: View {
    @Binding var selectedCategory: LibraryCategory?
    let providers: [String] // Provider names from Music Assistant
    let currentTrackTitle: String?
    let currentArtist: String?
    let onNowPlayingTap: () -> Void

    @State private var isLibraryExpanded = true
    @State private var isProvidersExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Now Playing Button
            Button(action: onNowPlayingTap) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.system(size: 16))
                        Text("NOW PLAYING")
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.5))

                    if let title = currentTrackTitle {
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if let artist = currentArtist {
                            Text(artist)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    } else {
                        Text("No track playing")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)

            // Library Section
            DisclosureGroup(
                isExpanded: $isLibraryExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(LibraryCategory.allCases) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.top, 8)
                },
                label: {
                    Text("LIBRARY")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 8)
                }
            )
            .padding(.horizontal, 12)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)

            // Providers Section
            DisclosureGroup(
                isExpanded: $isProvidersExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(providers, id: \.self) { provider in
                            ProviderButton(
                                name: provider,
                                action: {
                                    // TODO: Implement provider filtering
                                }
                            )
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.top, 8)
                },
                label: {
                    Text("PROVIDERS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 8)
                }
            )
            .padding(.horizontal, 12)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct CategoryButton: View {
    let category: LibraryCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.system(size: 14))
                    .frame(width: 16)

                Text(category.displayName)
                    .font(.system(size: 13))

                Spacer()
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct ProviderButton: View {
    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "music.note.house")
                    .font(.system(size: 14))
                    .frame(width: 16)

                Text(name)
                    .font(.system(size: 13))

                Spacer()
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LibrarySidebarView(
        selectedCategory: .constant(.artists),
        providers: ["Spotify", "Tidal", "Local Files"],
        currentTrackTitle: "Song Title",
        currentArtist: "Artist Name",
        onNowPlayingTap: {}
    )
    .frame(width: 200, height: 600)
}
