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

    @Environment(\.dynamicColorService) var colorService
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var glassMaterial: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)

            colorService.currentColors.muted
                .opacity(0.25)
        }
    }

    private var topBorder: some View {
        Rectangle()
            .fill(colorService.currentColors.vibrant.opacity(0.15))
            .frame(height: 1)
            .shadow(color: colorService.currentColors.vibrant.opacity(0.05), radius: 8, y: -2)
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Left Zone: Artwork + Track Info + Player Selector (420px)
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Artwork (clickable to expand)
                Button(action: onExpand) {
                    if let artworkURL = nowPlayingViewModel.artworkURL {
                        AsyncImage(url: artworkURL) { phase in
                            switch phase {
                            case .empty:
                                Color.gray.opacity(0.3)
                                    .frame(width: 64, height: 64)
                                    .cornerRadius(DesignSystem.CornerRadius.tight)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 64, height: 64)
                                    .cornerRadius(DesignSystem.CornerRadius.tight)
                            case .failure:
                                Color.gray.opacity(0.3)
                                    .frame(width: 64, height: 64)
                                    .cornerRadius(DesignSystem.CornerRadius.tight)
                            @unknown default:
                                Color.gray.opacity(0.3)
                                    .frame(width: 64, height: 64)
                                    .cornerRadius(DesignSystem.CornerRadius.tight)
                            }
                        }
                    } else {
                        Color.gray.opacity(0.3)
                            .frame(width: 64, height: 64)
                            .cornerRadius(DesignSystem.CornerRadius.tight)
                    }
                }
                .buttonStyle(.plain)

                // Track info (clickable to expand)
                Button(action: onExpand) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text(nowPlayingViewModel.trackTitle)
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(nowPlayingViewModel.artistName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .frame(width: 240, alignment: .leading)
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
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "speaker.wave.2")
                            .font(DesignSystem.Typography.caption)
                        Text(selectedPlayer?.name ?? "No Player")
                            .font(DesignSystem.Typography.caption)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 420, alignment: .leading)

            Spacer()

            // Center Zone: Transport controls with progress scrubber below (min 480px)
            VStack(spacing: DesignSystem.Spacing.xs) {
                // Transport controls
                HStack(spacing: DesignSystem.Spacing.lg) {
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
                    colors: colorService.currentColors,
                    onSeek: { time in
                        nowPlayingViewModel.seek(to: time)
                    }
                )
                .frame(minWidth: 480)
            }

            Spacer()

            // Right Zone: Secondary controls + Volume (240px)
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Secondary controls
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Button(action: { nowPlayingViewModel.toggleShuffle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 14))
                            .foregroundColor(nowPlayingViewModel.isShuffled ? colorService.currentColors.vibrant : .white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPlayer == nil)

                    Button(action: { nowPlayingViewModel.toggleLike() }) {
                        Image(systemName: nowPlayingViewModel.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(nowPlayingViewModel.isLiked ? colorService.currentColors.vibrant : .white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPlayer == nil)

                    Button(action: { nowPlayingViewModel.cycleRepeatMode() }) {
                        Image(systemName: nowPlayingViewModel.repeatMode == .one ? "repeat.1" : "repeat")
                            .font(.system(size: 14))
                            .foregroundColor(nowPlayingViewModel.repeatMode != .off ? colorService.currentColors.vibrant : .white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPlayer == nil)
                }

                // Volume control
                VolumeControl(
                    volume: Binding(
                        get: { nowPlayingViewModel.volume },
                        set: { nowPlayingViewModel.volume = $0 }
                    ),
                    colors: colorService.currentColors,
                    onVolumeChange: { volume in
                        nowPlayingViewModel.setVolume(volume)
                    }
                )
            }
            .frame(width: 240, alignment: .trailing)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .frame(height: DesignSystem.Layout.miniPlayerHeight)
        .background {
            ZStack(alignment: .top) {
                glassMaterial
                topBorder
            }
        }
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
