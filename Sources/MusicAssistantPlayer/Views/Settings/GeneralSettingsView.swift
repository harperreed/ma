// ABOUTME: General settings tab for server configuration and connection management
// ABOUTME: Allows changing Music Assistant server host and port

import SwiftUI
import MusicAssistantKit

struct GeneralSettingsView: View {
    @State private var host: String = ""
    @State private var port: String = "8095"
    @State private var isTestingConnection: Bool = false
    @State private var connectionStatus: String = ""
    @State private var connectionSuccess: Bool = false
    @State private var hasChanges: Bool = false

    @State private var resonateKitEnabled: Bool = false
    @State private var appSettings: AppSettings = AppSettings.load()

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server Connection")
                            .font(.headline)
                        Text("Configure your Music Assistant server connection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    // Server Host
                    HStack {
                        Text("Host:")
                            .frame(width: 80, alignment: .trailing)
                        TextField("192.168.1.100", text: $host)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: host) { _, _ in
                                hasChanges = true
                                connectionStatus = ""
                            }
                    }

                    // Server Port
                    HStack {
                        Text("Port:")
                            .frame(width: 80, alignment: .trailing)
                        TextField("8095", text: $port)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: port) { _, _ in
                                hasChanges = true
                                connectionStatus = ""
                            }
                        Spacer()
                    }

                    // Connection Status
                    if !connectionStatus.isEmpty {
                        HStack {
                            Image(systemName: connectionSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(connectionSuccess ? .green : .red)
                            Text(connectionStatus)
                                .font(.caption)
                                .foregroundColor(connectionSuccess ? .green : .red)
                        }
                        .padding(.leading, 80)
                    }

                    // Action Buttons
                    HStack(spacing: 12) {
                        Spacer()

                        Button("Test Connection") {
                            testConnection()
                        }
                        .disabled(isTestingConnection || host.isEmpty)

                        Button("Save") {
                            saveConfiguration()
                        }
                        .disabled(!hasChanges || host.isEmpty)
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding(.leading, 80)
                    .padding(.top, 8)
                }
                .padding(.vertical, 8)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Connection")
                        .font(.headline)

                    if let config = ServerConfig.load() {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 8))
                            Text("\(config.host):\(config.port)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 8))
                            Text("Not connected")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ResonateKit Playback")
                        .font(.headline)

                    Text("Enable synchronized multi-room audio playback using the Resonate Protocol")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle("Enable ResonateKit", isOn: $resonateKitEnabled)
                        .onChange(of: resonateKitEnabled) { _, newValue in
                            hasChanges = true
                            appSettings.resonateKitEnabled = newValue
                        }

                    if resonateKitEnabled {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("ResonateKit will automatically discover and connect to available servers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                    Text("Music Assistant Player")
                        .font(.caption)
                    Text("A native macOS client for Music Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 400)
        .onAppear {
            loadCurrentConfiguration()
        }
    }

    private func loadCurrentConfiguration() {
        if let config = ServerConfig.load() {
            host = config.host
            port = String(config.port)
        }

        appSettings = AppSettings.load()
        resonateKitEnabled = appSettings.resonateKitEnabled

        hasChanges = false
        connectionStatus = ""
    }

    private func testConnection() {
        guard let portInt = Int(port) else {
            connectionStatus = "Invalid port number"
            connectionSuccess = false
            return
        }

        // Validate configuration
        if let error = NetworkValidator.validateServerConfig(host: host, port: portInt) {
            connectionStatus = error
            connectionSuccess = false
            return
        }

        isTestingConnection = true
        connectionStatus = "Testing connection..."
        connectionSuccess = false

        Task {
            do {
                let testClient = MusicAssistantClient(host: host, port: portInt)
                try await testClient.connect()

                await MainActor.run {
                    connectionStatus = "Connection successful!"
                    connectionSuccess = true
                    isTestingConnection = false
                }

                // Disconnect test client
                await testClient.disconnect()
            } catch {
                await MainActor.run {
                    connectionStatus = "Connection failed: \(error.localizedDescription)"
                    connectionSuccess = false
                    isTestingConnection = false
                }
            }
        }
    }

    private func saveConfiguration() {
        guard let portInt = Int(port) else {
            connectionStatus = "Invalid port number"
            connectionSuccess = false
            return
        }

        let config = ServerConfig(host: host, port: portInt)
        config.save()

        appSettings.save()

        hasChanges = false
        connectionStatus = "Configuration saved. Please restart the app to apply changes."
        connectionSuccess = true
    }
}
