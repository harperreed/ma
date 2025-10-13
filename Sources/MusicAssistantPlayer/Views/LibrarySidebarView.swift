// ABOUTME: Collapsible sidebar for library navigation with categories and providers
// ABOUTME: Displays library categories (Artists, Albums, etc.) and music providers (Spotify, Tidal, etc.)

import SwiftUI

struct LibrarySidebarView: View {
    @Binding var selectedCategory: LibraryCategory?
    let providers: [String] // Provider names from Music Assistant

    @State private var isLibraryExpanded = true
    @State private var isProvidersExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        providers: ["Spotify", "Tidal", "Local Files"]
    )
    .frame(width: 200, height: 600)
}
