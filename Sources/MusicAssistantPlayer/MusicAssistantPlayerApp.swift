// ABOUTME: Main entry point for Music Assistant Player macOS application
// ABOUTME: Manages client lifecycle and server configuration flow

import SwiftUI
import MusicAssistantKit
import AppIntents

@main
struct MusicAssistantPlayerApp: App {
    @State private var serverConfig: ServerConfig? = ServerConfig.load()
    @State private var client: MusicAssistantClient?
    @State private var showSetup: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let config = serverConfig, let client = client {
                    RoonStyleMainWindowView(client: client, serverConfig: config)
                } else {
                    ServerSetupView { config in
                        self.serverConfig = config
                        handleConnection(config: config)
                    }
                }
            }
            .onAppear {
                if let config = serverConfig {
                    handleConnection(config: config)
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandMenu("Players") {
                // Populated dynamically by ContentView state
                Text("Player selection available in window")
                    .disabled(true)
            }

            CommandMenu("Queue") {
                Button("Show Queue") {
                    // TODO: Implement queue window/popover
                    AppLogger.ui.info("Show queue from menubar")
                }
                .keyboardShortcut("q", modifiers: [.command, .shift])
            }
        }
    }

    private func handleConnection(config: ServerConfig) {
        let newClient = MusicAssistantClient(host: config.host, port: config.port)

        Task {
            do {
                try await newClient.connect()
                AppLogger.network.info("Successfully connected to Music Assistant server at \(config.host):\(config.port)")

                // Only set client after successful connection
                await MainActor.run {
                    self.client = newClient
                }
            } catch {
                AppLogger.errors.logError(error, context: "Connection failed")
                // Clear client on failure so user can retry
                await MainActor.run {
                    self.client = nil
                    self.serverConfig = nil
                }
            }
        }
    }
}

struct MusicAssistantAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayIntent(),
            phrases: [
                "Play music in \(.applicationName)",
                "Resume music in \(.applicationName)"
            ],
            shortTitle: "Play",
            systemImageName: "play.fill"
        )

        AppShortcut(
            intent: PauseIntent(),
            phrases: [
                "Pause music in \(.applicationName)",
                "Pause \(.applicationName)"
            ],
            shortTitle: "Pause",
            systemImageName: "pause.fill"
        )

        AppShortcut(
            intent: StopIntent(),
            phrases: [
                "Stop music in \(.applicationName)",
                "Stop \(.applicationName)"
            ],
            shortTitle: "Stop",
            systemImageName: "stop.fill"
        )

        AppShortcut(
            intent: NextTrackIntent(),
            phrases: [
                "Next track in \(.applicationName)",
                "Skip song in \(.applicationName)"
            ],
            shortTitle: "Next",
            systemImageName: "forward.fill"
        )

        AppShortcut(
            intent: PreviousTrackIntent(),
            phrases: [
                "Previous track in \(.applicationName)",
                "Go back in \(.applicationName)"
            ],
            shortTitle: "Previous",
            systemImageName: "backward.fill"
        )
    }
}
