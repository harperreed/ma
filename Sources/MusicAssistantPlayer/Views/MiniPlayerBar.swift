// ABOUTME: Persistent mini player bar at bottom with player selection, track info, and basic controls
// ABOUTME: Clicking artwork or track info expands to full now-playing view

import SwiftUI

struct MiniPlayerBar: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @Binding var selectedPlayer: Player?
    let availablePlayers: [Player]
    let imageCacheService: ImageCacheService
    let onExpand: () -> Void
    let onPlayerSelection: (Player) -> Void

    private let barHeight: CGFloat = 90

    var body: some View {
        HStack(spacing: 16) {
            // Left: Artwork + Track Info + Player Selector
            HStack(spacing: 12) {
                // Artwork (clickable to expand)
                Button(action: onExpand) {
                    if let artworkURL = nowPlayingViewModel.artworkURL {
                        AsyncImage(url: artworkURL) { phase in
                            switch phase {
                            case .empty:
                                Color.gray.opacity(0.3)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(4)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(4)
                            case .failure:
                                Color.gray.opacity(0.3)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(4)
                            @unknown default:
                                Color.gray.opacity(0.3)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(4)
                            }
                        }
                    } else {
                        Color.gray.opacity(0.3)
                            .frame(width: 60, height: 60)
                            .cornerRadius(4)
                    }
                }
                .buttonStyle(.plain)

                // Track info (clickable to expand)
                Button(action: onExpand) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nowPlayingViewModel.trackTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(nowPlayingViewModel.artistName)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .frame(width: 200, alignment: .leading)
                }
                .buttonStyle(.plain)

                // Player selector dropdown
                Menu {
                    ForEach(availablePlayers) { player in
                        Button(action: { onPlayerSelection(player) }) {
                            HStack {
                                Text(player.name)
                                if player.id == selectedPlayer?.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 12))
                        Text(selectedPlayer?.name ?? "No Player")
                            .font(.system(size: 12))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 400, alignment: .leading)

            Spacer()

            // Center: Transport controls with progress scrubber below (Spotify-style)
            VStack(spacing: 8) {
                // Transport controls
                HStack(spacing: 20) {
                    Button(action: { nowPlayingViewModel.skipPrevious() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPlayer == nil)

                    Button(action: {
                        if nowPlayingViewModel.isPlaying {
                            nowPlayingViewModel.pause()
                        } else {
                            nowPlayingViewModel.play()
                        }
                    }) {
                        Image(systemName: nowPlayingViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPlayer == nil)

                    Button(action: { nowPlayingViewModel.skipNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPlayer == nil)
                }

                // Progress scrubber (below transport controls)
                SeekableProgressBar(
                    progress: nowPlayingViewModel.progress,
                    duration: nowPlayingViewModel.duration,
                    onSeek: { time in
                        nowPlayingViewModel.seek(to: time)
                    }
                )
                .frame(width: 400)
            }

            Spacer()

            // Right: Volume control
            VolumeControl(
                volume: Binding(
                    get: { nowPlayingViewModel.volume },
                    set: { nowPlayingViewModel.volume = $0 }
                ),
                onVolumeChange: { volume in
                    nowPlayingViewModel.setVolume(volume)
                }
            )
            .frame(width: 200)
        }
        .padding(.horizontal, 20)
        .frame(height: barHeight)
        .background(Color.black.opacity(0.9))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedPlayer: Player? = Player(
            id: "test-player",
            name: "Test Player",
            isActive: true,
            type: .player,
            groupChildIds: [],
            syncedTo: nil,
            activeGroup: nil
        )

        var body: some View {
            MiniPlayerBar(
                nowPlayingViewModel: {
                    let playerService = PlayerService()
                    playerService.currentTrack = Track(
                        id: "1",
                        title: "Bohemian Rhapsody",
                        artist: "Queen",
                        album: "A Night at the Opera",
                        duration: 354.0,
                        artworkURL: nil
                    )
                    playerService.playbackState = .playing
                    playerService.progress = 120.0
                    return NowPlayingViewModel(playerService: playerService)
                }(),
                selectedPlayer: $selectedPlayer,
                availablePlayers: [
                    Player(
                        id: "test-player",
                        name: "Test Player",
                        isActive: true,
                        type: .player,
                        groupChildIds: [],
                        syncedTo: nil,
                        activeGroup: nil
                    ),
                    Player(
                        id: "kitchen",
                        name: "Kitchen",
                        isActive: false,
                        type: .player,
                        groupChildIds: [],
                        syncedTo: nil,
                        activeGroup: nil
                    )
                ],
                imageCacheService: ImageCacheService(),
                onExpand: {},
                onPlayerSelection: { _ in }
            )
            .frame(height: 90)
        }
    }

    return PreviewWrapper()
}
