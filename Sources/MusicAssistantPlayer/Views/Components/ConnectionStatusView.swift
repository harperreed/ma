// ABOUTME: Connection status indicator component for Music Assistant server
// ABOUTME: Displays connection state with colored badge and status text

import SwiftUI

struct ConnectionStatusView: View {
    let connectionState: ConnectionState
    let serverHost: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(connectionState.displayText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                if connectionState.isConnected {
                    Text(serverHost)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            if case .error = connectionState {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private var statusColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .yellow
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ConnectionStatusView(
            connectionState: .connected,
            serverHost: "192.168.200.113",
            onRetry: {}
        )

        ConnectionStatusView(
            connectionState: .connecting,
            serverHost: "192.168.200.113",
            onRetry: {}
        )

        ConnectionStatusView(
            connectionState: .error("Connection refused"),
            serverHost: "192.168.200.113",
            onRetry: {}
        )
    }
    .padding()
    .frame(width: 220)
    .background(Color(red: 0.06, green: 0.06, blue: 0.1))
}
