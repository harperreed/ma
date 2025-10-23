// ABOUTME: Main entry point for Music Assistant Player macOS application
// ABOUTME: Manages client lifecycle and server configuration flow

import SwiftUI
import MusicAssistantKit
import AppIntents

@main
struct MusicAssistantPlayerApp: App {
    @State private var serverConfig: ServerConfig? = ServerConfig.load()
    @State private var client: MusicAssistantClient?
    @State private var streamingPlayer: StreamingPlayer?
    @State private var showSetup: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let config = serverConfig, let client = client, let streamingPlayer = streamingPlayer {
                    RoonStyleMainWindowView(client: client, serverConfig: config, streamingPlayer: streamingPlayer)
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

                // Create and register StreamingPlayer
                let player = StreamingPlayer(client: newClient, playerName: "Music Assistant Player")

                do {
                    try await player.register()
                    AppLogger.network.info("StreamingPlayer successfully registered")

                    // Only set state variables after both connection AND registration succeed
                    await MainActor.run {
                        self.streamingPlayer = player
                        self.client = newClient
                    }
                } catch {
                    AppLogger.errors.logError(error, context: "StreamingPlayer registration failed")
                    // Disconnect client and clear state on registration failure
                    await newClient.disconnect()
                    await MainActor.run {
                        self.client = nil
                        self.streamingPlayer = nil
                        self.serverConfig = nil
                    }
                }
            } catch {
                AppLogger.errors.logError(error, context: "Connection failed")
                // Clear client on failure so user can retry
                await MainActor.run {
                    self.client = nil
                    self.streamingPlayer = nil
                    self.serverConfig = nil
                }
            }
        }
    }
}

// App Shortcuts removed - intents no longer available in MusicAssistantKit 0.2.1
// TODO: Implement app shortcuts using direct client commands instead of intents
