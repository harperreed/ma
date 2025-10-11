// ABOUTME: Main entry point for Music Assistant Player macOS application
// ABOUTME: Initializes SwiftUI app lifecycle and main window

import SwiftUI

@main
struct MusicAssistantPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
