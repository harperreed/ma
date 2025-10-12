// ABOUTME: Navigation sidebar with section navigation and player selection
// ABOUTME: Shows available Music Assistant players and navigation options

import SwiftUI

struct SidebarView: View {
    @Binding var selectedPlayer: Player?
    let availablePlayers: [Player]
    let connectionState: ConnectionState
    let serverHost: String
    let onRetry: () -> Void

    // Only show groups and non-synced players (hide synced players since they're represented by their group)
    var visiblePlayers: [Player] {
        availablePlayers.filter { player in
            // Show groups
            if player.isGroup {
                return true
            }
            // Show individual players that aren't synced
            return !player.isSynced
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation
            VStack(alignment: .leading, spacing: 8) {
                Text("MUSIC ASSISTANT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal)
                    .padding(.top)

                SidebarItem(icon: "play.circle.fill", title: "Now Playing", isSelected: true)
                SidebarItem(icon: "music.note.list", title: "Library", isSelected: false)
                SidebarItem(icon: "magnifyingglass", title: "Search", isSelected: false)
            }
            .padding(.bottom, 24)

            Divider()
                .background(Color.white.opacity(0.1))

            // Players
            VStack(alignment: .leading, spacing: 8) {
                Text("PLAYERS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal)
                    .padding(.top)

                if visiblePlayers.isEmpty {
                    Text("No players found")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                } else {
                    ForEach(visiblePlayers) { player in
                        Button(action: {
                            selectedPlayer = player
                        }) {
                            HStack(spacing: 8) {
                                // Icon based on player type and state
                                Image(systemName: playerIcon(for: player))
                                    .font(.system(size: player.isGroup ? 10 : 8))
                                    .foregroundColor(playerIconColor(for: player))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.name)
                                        .font(.system(size: 13))
                                        .foregroundColor(selectedPlayer?.id == player.id ? .white : .white.opacity(0.7))

                                    // Show grouping info
                                    if player.isGroup && !player.groupChildIds.isEmpty {
                                        Text("Group • \(player.groupChildIds.count) \(player.groupChildIds.count == 1 ? "player" : "players")")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(
                                selectedPlayer?.id == player.id ?
                                    Color.white.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                    }
                }
            }

            Spacer()

            // Connection status at bottom
            ConnectionStatusView(
                connectionState: connectionState,
                serverHost: serverHost,
                onRetry: onRetry
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.06, green: 0.06, blue: 0.1))
    }

    private func playerIcon(for player: Player) -> String {
        if player.isGroup {
            return player.isActive ? "speaker.wave.3.fill" : "speaker.wave.3"
        } else if player.isSynced {
            return player.isActive ? "circle.fill" : "circle"
        } else {
            return player.isActive ? "circle.fill" : "circle"
        }
    }

    private func playerIconColor(for player: Player) -> Color {
        if player.isActive {
            return .green
        } else if player.isGroup {
            return .white.opacity(0.4)
        } else {
            return .white.opacity(0.3)
        }
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .padding(.horizontal, 8)
    }
}

#Preview {
    SidebarView(
        selectedPlayer: .constant(
            Player(id: "1", name: "Kitchen", isActive: true, type: .player, groupChildIds: [], syncedTo: nil, activeGroup: nil)
        ),
        availablePlayers: [
            Player(id: "1", name: "Kitchen", isActive: true, type: .player, groupChildIds: [], syncedTo: nil, activeGroup: nil),
            Player(id: "2", name: "Bedroom", isActive: false, type: .player, groupChildIds: [], syncedTo: nil, activeGroup: nil),
            Player(id: "3", name: "First Floor", isActive: true, type: .group, groupChildIds: ["1", "4"], syncedTo: nil, activeGroup: nil),
            Player(id: "4", name: "Living Room", isActive: true, type: .player, groupChildIds: [], syncedTo: "3", activeGroup: nil)
        ],
        connectionState: .connected,
        serverHost: "192.168.200.113",
        onRetry: {}
    )
    .frame(width: 220, height: 600)
}
