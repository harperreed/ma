// ABOUTME: Connection status indicator showing server connection state with color-coded status
// ABOUTME: Displays hostname, provides click action for server management, reactive to connection state

import SwiftUI

extension ConnectionState {
    var color: Color {
        switch self {
        case .connected: return .green
        case .connecting, .reconnecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    var icon: String {
        switch self {
        case .connected: return "checkmark.circle.fill"
        case .connecting, .reconnecting: return "arrow.triangle.2.circlepath"
        case .disconnected: return "xmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

struct ConnectionStatusIndicator: View {
    let serverHost: String
    let serverPort: Int
    let connectionState: ConnectionState
    let onDisconnect: () -> Void
    let onChangeServer: () -> Void

    @State private var showMenu = false

    var body: some View {
        Button(action: {
            showMenu = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: connectionState.icon)
                    .font(.system(size: 10))
                    .foregroundColor(connectionState.color)

                Text("Connected to \(serverHost):\(serverPort)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showMenu) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Server Connection")
                    .font(.headline)
                    .padding(.bottom, 4)

                HStack {
                    Image(systemName: connectionState.icon)
                        .foregroundColor(connectionState.color)
                    Text(connectionStateText)
                        .font(.subheadline)
                }

                Divider()

                VStack(spacing: 8) {
                    Button(action: {
                        showMenu = false
                        onChangeServer()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Change Server...")
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)

                    Button(action: {
                        showMenu = false
                        onDisconnect()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Disconnect")
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)
                }
            }
            .padding()
            .frame(width: 220)
        }
    }

    private var connectionStateText: String {
        "\(connectionState.displayText): \(serverHost):\(serverPort)"
    }
}

#Preview {
    VStack(spacing: 20) {
        ConnectionStatusIndicator(
            serverHost: "localhost",
            serverPort: 8095,
            connectionState: .connected,
            onDisconnect: {},
            onChangeServer: {}
        )

        ConnectionStatusIndicator(
            serverHost: "localhost",
            serverPort: 8095,
            connectionState: .error("Network timeout"),
            onDisconnect: {},
            onChangeServer: {}
        )

        ConnectionStatusIndicator(
            serverHost: "localhost",
            serverPort: 8095,
            connectionState: .disconnected,
            onDisconnect: {},
            onChangeServer: {}
        )
    }
    .padding()
    .frame(width: 400, height: 300)
    .background(Color.black)
}
