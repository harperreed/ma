// ABOUTME: Card component displaying available Music Assistant players
// ABOUTME: Sonos-style card layout with player selection and status

import SwiftUI

struct PlayersCard: View {
    let players: [Player]
    @Binding var selectedPlayer: Player?
    let onPlayerSelection: (Player) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("PLAYERS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Text("\(players.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(Color.white.opacity(0.1))

            // Players list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(players) { player in
                        PlayerRow(
                            player: player,
                            isSelected: selectedPlayer?.id == player.id,
                            onSelect: { onPlayerSelection(player) }
                        )
                    }
                }
                .padding(12)
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PlayerRow: View {
    let player: Player
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Player icon/status indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green : Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: player.isActive ? "speaker.wave.2.fill" : "speaker.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                }

                // Player info
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        // Status indicator
                        Circle()
                            .fill(player.isActive ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)

                        Text(player.isActive ? "Active" : "Inactive")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Checkmark for selected player
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(isSelected ? Color.white.opacity(0.08) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlayersCard(
        players: [
            Player(id: "1", name: "Living Room", isActive: true, type: .player, groupChildIds: [], syncedTo: nil, activeGroup: nil),
            Player(id: "2", name: "Bedroom", isActive: false, type: .player, groupChildIds: [], syncedTo: nil, activeGroup: nil),
            Player(id: "3", name: "Kitchen", isActive: true, type: .player, groupChildIds: [], syncedTo: nil, activeGroup: nil)
        ],
        selectedPlayer: .constant(Player(id: "1", name: "Living Room", isActive: true, type: .player, groupChildIds: [], syncedTo: nil, activeGroup: nil)),
        onPlayerSelection: { _ in }
    )
    .frame(width: 320, height: 400)
    .padding()
    .background(Color.black)
}
