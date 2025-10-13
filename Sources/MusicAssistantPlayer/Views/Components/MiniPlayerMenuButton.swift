// ABOUTME: Menu button for accessing sidebar/queue when in miniplayer mode
// ABOUTME: Shows hamburger icon at top-center with semi-transparent background, maintaining centered aesthetic

import SwiftUI

struct MiniPlayerMenuButton: View {
    let selectedPlayer: Player?
    let availablePlayers: [Player]
    let onPlayerSelect: (Player) -> Void
    let onShowQueue: () -> Void

    @State private var showMenu = false

    var body: some View {
        VStack {
            // Top-center menu button
            HStack {
                Spacer()
                Menu {
                    Section("Players") {
                        ForEach(availablePlayers) { player in
                            Button(action: {
                                onPlayerSelect(player)
                            }) {
                                HStack {
                                    Text(player.name)
                                    if selectedPlayer?.id == player.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    Button("Show Queue") {
                        onShowQueue()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(10)
                        .background(Color.black.opacity(0.2))
                        .clipShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .padding(.top, 12)
                Spacer()
            }
            Spacer()
        }
    }
}
