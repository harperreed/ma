// ABOUTME: Main entry point for Music Assistant Player macOS application
// ABOUTME: Initializes SwiftUI app lifecycle and main window

import SwiftUI

@main
struct MusicAssistantPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Music Assistant Player")
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
