// ABOUTME: Main entry point for Music Assistant Player macOS application
// ABOUTME: Manages client lifecycle and server configuration flow

import SwiftUI
import MusicAssistantKit

@main
struct MusicAssistantPlayerApp: App {
    @State private var serverConfig: ServerConfig? = ServerConfig.load()
    @State private var client: MusicAssistantClient?
    @State private var showSetup: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let config = serverConfig, let client = client {
                    MainWindowView(client: client, serverConfig: config)
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
        }
    }

    private func handleConnection(config: ServerConfig) {
        let newClient = MusicAssistantClient(host: config.host, port: config.port)

        Task {
            do {
                try await newClient.connect()
                print("Successfully connected to Music Assistant server at \(config.host):\(config.port)")

                // Only set client after successful connection
                await MainActor.run {
                    self.client = newClient
                }
            } catch {
                print("Connection failed: \(error)")
                // Clear client on failure so user can retry
                await MainActor.run {
                    self.client = nil
                    self.serverConfig = nil
                }
            }
        }
    }
}
