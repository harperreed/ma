// ABOUTME: First-run server configuration view for Music Assistant connection
// ABOUTME: Allows user to enter server host/port and test connection

import SwiftUI
import MusicAssistantKit

struct ServerSetupView: View {
    @State private var host: String = "192.168.200.113"
    @State private var port: String = "8095"
    @State private var isConnecting: Bool = false
    @State private var connectionStatus: String = ""
    @State private var connectionSuccess: Bool = false

    let onConnect: (ServerConfig) -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.8))

                Text("Music Assistant Player")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)

                Text("Connect to your Music Assistant server")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 40)

            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server Address")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    TextField("192.168.1.100", text: $host)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .disabled(isConnecting)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Port")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    TextField("8095", text: $port)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .disabled(isConnecting)
                }

                Button(action: handleConnect) {
                    HStack {
                        if isConnecting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text(isConnecting ? "Connecting..." : "Connect")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(isConnecting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isConnecting || host.isEmpty)
                .padding(.top, 8)

                if !connectionStatus.isEmpty {
                    Text(connectionStatus)
                        .font(.system(size: 12))
                        .foregroundColor(connectionSuccess ? .green : .red)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: 400)
            .padding(32)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.15, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func handleConnect() {
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

        isConnecting = true
        connectionStatus = ""

        let config = ServerConfig(host: host, port: portInt)

        // Test connection
        Task {
            do {
                // Actually test the connection
                let testClient = MusicAssistantClient(host: host, port: portInt)
                try await testClient.connect()

                // Connection successful!
                await MainActor.run {
                    connectionStatus = "Connected successfully!"
                    connectionSuccess = true

                    // Save config
                    config.save()

                    // Disconnect test client
                    Task {
                        await testClient.disconnect()
                    }

                    // Notify parent after brief delay for user feedback
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onConnect(config)
                    }
                }
            } catch {
                await MainActor.run {
                    connectionStatus = "Connection failed: \(error.localizedDescription)"
                    connectionSuccess = false
                    isConnecting = false
                }
            }
        }
    }
}

#Preview {
    ServerSetupView { _ in
        print("Connected")
    }
}
