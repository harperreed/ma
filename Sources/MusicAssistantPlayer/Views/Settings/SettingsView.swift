// ABOUTME: Main settings window using macOS native TabView style
// ABOUTME: Provides tabbed interface for app preferences and configuration

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(0)

            // Future tabs can be added here:
            // - Audio settings
            // - Appearance
            // - Advanced
        }
        .frame(width: 500)
    }
}
