// ABOUTME: Navigation sidebar with section navigation and player selection
// ABOUTME: Shows available Music Assistant players and navigation options

import SwiftUI

struct SidebarView: View {
    @Binding var selectedPlayer: Player?
    let availablePlayers: [Player]
    let connectionState: ConnectionState
    let serverHost: String
    let onRetry: () -> Void

    @State private var expandedGroups: Set<String> = []
    @State private var isGroupsSectionExpanded: Bool = true
    @State private var isPlayersSectionExpanded: Bool = true

    // Helper function to sort players: active/playing first, then alphabetically
    func sortPlayers(_ players: [Player]) -> [Player] {
        players.sorted { player1, player2 in
            // Playing/active players first
            if player1.isActive != player2.isActive {
                return player1.isActive
            }
            // Then alphabetically by name
            return player1.name.localizedCaseInsensitiveCompare(player2.name) == .orderedAscending
        }
    }

    // Groups only - sorted by playing first, then name
    var groups: [Player] {
        let groupPlayers = availablePlayers.filter { $0.isGroup }
        return sortPlayers(groupPlayers)
    }

    // Individual players (non-groups, non-synced) - sorted by playing first, then name
    var individualPlayers: [Player] {
        let nonGroupPlayers = availablePlayers.filter { !$0.isGroup && !$0.isSynced }
        return sortPlayers(nonGroupPlayers)
    }

    // All top level players (for initialization logic)
    var topLevelPlayers: [Player] {
        groups + individualPlayers
    }

    // Get child players for a specific player (group members or synced players)
    func childPlayers(for parent: Player) -> [Player] {
        return availablePlayers
            .filter { player in
                // Players synced to this parent
                player.syncedTo == parent.id ||
                // Or group members (if parent is a group)
                (parent.isGroup && parent.groupChildIds.contains(player.id))
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func isGroupExpanded(_ groupId: String) -> Bool {
        expandedGroups.contains(groupId)
    }

    private func toggleGroup(_ groupId: String) {
        if expandedGroups.contains(groupId) {
            expandedGroups.remove(groupId)
        } else {
            expandedGroups.insert(groupId)
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
            VStack(alignment: .leading, spacing: 4) {
                ScrollView {
                    VStack(spacing: 0) {
                        if topLevelPlayers.isEmpty {
                            Text("No players found")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                        } else {
                            // Groups section
                            if !groups.isEmpty {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isGroupsSectionExpanded.toggle()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.5))
                                            .rotationEffect(.degrees(isGroupsSectionExpanded ? 90 : 0))

                                        Text("GROUPS")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.top, 6)
                                    .padding(.bottom, 2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                if isGroupsSectionExpanded {
                                    ForEach(groups) { player in
                        let children = childPlayers(for: player)
                        VStack(spacing: 0) {
                            // Parent player/group
                            HStack(spacing: 0) {
                                // Chevron for groups with children
                                if !children.isEmpty {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            toggleGroup(player.id)
                                        }
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.5))
                                            .rotationEffect(.degrees(isGroupExpanded(player.id) ? 90 : 0))
                                            .frame(width: 20, height: 20)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.leading, 4)
                                } else {
                                    Spacer()
                                        .frame(width: 20)
                                }

                                // Main player button
                                Button(action: {
                                    selectedPlayer = player
                                }) {
                                    HStack(spacing: 8) {
                                        // Icon based on player type and state
                                        if let icon = playerIcon(for: player) {
                                            Image(systemName: icon)
                                                .font(.system(size: 10))
                                                .foregroundColor(playerIconColor(for: player))
                                                .frame(width: 16)
                                        } else {
                                            Spacer()
                                                .frame(width: 16)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(player.name)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(selectedPlayer?.id == player.id ? .white : .white.opacity(0.7))

                                                // Show "+ N" badge for players with children
                                                if !children.isEmpty {
                                                    Text("+\(children.count)")
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.6))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.white.opacity(0.1))
                                                        .cornerRadius(4)
                                                }
                                            }

                                            // Show grouping info subtitle
                                            if player.isGroup && !player.groupChildIds.isEmpty {
                                                Text("Group • \(player.groupChildIds.count) \(player.groupChildIds.count == 1 ? "player" : "players")")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.4))
                                            } else if !player.isGroup && !children.isEmpty {
                                                Text("Synced • \(children.count) \(children.count == 1 ? "player" : "players")")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.4))
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 3)
                                    .background(
                                        selectedPlayer?.id == player.id ?
                                            Color.white.opacity(0.1) : Color.clear
                                    )
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 4)

                            // Child players (group members or synced players) - only show if expanded
                            if !children.isEmpty && isGroupExpanded(player.id) {
                                ForEach(children) { child in
                                    Button(action: {
                                        selectedPlayer = child
                                    }) {
                                        HStack(spacing: 8) {
                                            // Indentation
                                            Spacer()
                                                .frame(width: 12)

                                            // Child icon
                                            if let icon = playerIcon(for: child) {
                                                Image(systemName: icon)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(playerIconColor(for: child))
                                                    .frame(width: 16)
                                            } else {
                                                Spacer()
                                                    .frame(width: 16)
                                            }

                                            Text(child.name)
                                                .font(.system(size: 12))
                                                .foregroundColor(selectedPlayer?.id == child.id ? .white : .white.opacity(0.6))

                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 2)
                                        .background(
                                            selectedPlayer?.id == child.id ?
                                                Color.white.opacity(0.08) : Color.clear
                                        )
                                        .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 4)
                                    .padding(.leading, 4)
                                }
                            }
                        }
                                    }
                                }
                            }

                            // Separator between groups and individual players
                            if !groups.isEmpty && !individualPlayers.isEmpty {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.vertical, 4)
                            }

                            // Individual players section
                            if !individualPlayers.isEmpty {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isPlayersSectionExpanded.toggle()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.5))
                                            .rotationEffect(.degrees(isPlayersSectionExpanded ? 90 : 0))

                                        Text("PLAYERS")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.top, 6)
                                    .padding(.bottom, 2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                if isPlayersSectionExpanded {
                                    ForEach(individualPlayers) { player in
                        let children = childPlayers(for: player)
                        VStack(spacing: 0) {
                            // Parent player/group
                            HStack(spacing: 0) {
                                // Chevron for groups with children
                                if !children.isEmpty {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            toggleGroup(player.id)
                                        }
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.5))
                                            .rotationEffect(.degrees(isGroupExpanded(player.id) ? 90 : 0))
                                            .frame(width: 20, height: 20)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.leading, 4)
                                } else {
                                    Spacer()
                                        .frame(width: 20)
                                }

                                // Main player button
                                Button(action: {
                                    selectedPlayer = player
                                }) {
                                    HStack(spacing: 8) {
                                        // Icon based on player type and state
                                        if let icon = playerIcon(for: player) {
                                            Image(systemName: icon)
                                                .font(.system(size: 10))
                                                .foregroundColor(playerIconColor(for: player))
                                                .frame(width: 16)
                                        } else {
                                            Spacer()
                                                .frame(width: 16)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(player.name)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(selectedPlayer?.id == player.id ? .white : .white.opacity(0.7))

                                                // Show "+ N" badge for players with children
                                                if !children.isEmpty {
                                                    Text("+\(children.count)")
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.6))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.white.opacity(0.1))
                                                        .cornerRadius(4)
                                                }
                                            }

                                            // Show grouping info subtitle
                                            if player.isGroup && !player.groupChildIds.isEmpty {
                                                Text("Group • \(player.groupChildIds.count) \(player.groupChildIds.count == 1 ? "player" : "players")")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.4))
                                            } else if !player.isGroup && !children.isEmpty {
                                                Text("Synced • \(children.count) \(children.count == 1 ? "player" : "players")")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.4))
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 3)
                                    .background(
                                        selectedPlayer?.id == player.id ?
                                            Color.white.opacity(0.1) : Color.clear
                                    )
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 4)

                            // Child players (group members or synced players) - only show if expanded
                            if !children.isEmpty && isGroupExpanded(player.id) {
                                ForEach(children) { child in
                                    Button(action: {
                                        selectedPlayer = child
                                    }) {
                                        HStack(spacing: 8) {
                                            // Indentation
                                            Spacer()
                                                .frame(width: 12)

                                            // Child icon
                                            if let icon = playerIcon(for: child) {
                                                Image(systemName: icon)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(playerIconColor(for: child))
                                                    .frame(width: 16)
                                            } else {
                                                Spacer()
                                                    .frame(width: 16)
                                            }

                                            Text(child.name)
                                                .font(.system(size: 12))
                                                .foregroundColor(selectedPlayer?.id == child.id ? .white : .white.opacity(0.6))

                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 2)
                                        .background(
                                            selectedPlayer?.id == child.id ?
                                                Color.white.opacity(0.08) : Color.clear
                                        )
                                        .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 4)
                                    .padding(.leading, 4)
                                }
                            }
                        }
                                    }
                                }
                            }
                        }
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
        .onAppear {
            // Initialize all groups with children as expanded
            for player in topLevelPlayers {
                if !childPlayers(for: player).isEmpty && !expandedGroups.contains(player.id) {
                    expandedGroups.insert(player.id)
                }
            }
        }
    }

    private func playerIcon(for player: Player) -> String? {
        // Only show speaker icon when actively playing
        if player.isActive {
            return "speaker.wave.2.fill"
        }
        return nil
    }

    private func playerIconColor(for player: Player) -> Color {
        return .white.opacity(0.6)
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
