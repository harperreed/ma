// ABOUTME: Main now playing display with album art and metadata
// ABOUTME: Central hero section with blurred background and responsive layout

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    @Binding var selectedPlayer: Player?
    let availablePlayers: [Player]
    @ObservedObject var imageCacheService: ImageCacheService

    // MARK: - Responsive Layout Constants

    private enum LayoutBreakpoint {
        static let miniplayerWidth: CGFloat = 700
        static let smallWindow: CGFloat = 800
        static let largeWindow: CGFloat = 1200
    }

    private enum AlbumArtSize {
        static let sizeMultiplier: CGFloat = 0.55
        static let maximum: CGFloat = 800
    }

    private enum FontSize {
        static let titleSmall: CGFloat = 24
        static let titleLarge: CGFloat = 28
        static let metadataSmall: CGFloat = 14
        static let metadataLarge: CGFloat = 18
    }

    private enum Spacing {
        static let small: CGFloat = 16
        static let large: CGFloat = 24
    }

    private enum ControlsWidth {
        static let standard: CGFloat = 600
        static let large: CGFloat = 700
    }

    var body: some View {
        GeometryReader { geometry in
            // Content
            VStack(spacing: responsiveSpacing(for: geometry.size)) {
                    // Error banner at top
                    if let error = viewModel.lastError {
                        ErrorBanner(error: error) {
                            viewModel.clearError()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    Spacer()

                    // Album art
                    AlbumArtView(
                        artworkURL: viewModel.artworkURL,
                        size: albumArtSize(for: geometry.size)
                    )

                    // Track metadata
                    VStack(spacing: 8) {
                        Text(viewModel.trackTitle)
                            .font(.system(size: titleFontSize(for: geometry.size), weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                        HStack(spacing: 8) {
                            Text(viewModel.artistName)
                                .font(.system(size: metadataFontSize(for: geometry.size)))
                                .foregroundColor(.white.opacity(0.85))

                            if !viewModel.albumName.isEmpty {
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                Text(viewModel.albumName)
                                    .font(.system(size: metadataFontSize(for: geometry.size)))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .frame(maxWidth: controlsMaxWidth(for: geometry.size))
                    .padding(.horizontal)

                    // Player controls
                    PlayerControlsView(
                        isPlaying: viewModel.isPlaying,
                        progress: viewModel.progress,
                        duration: viewModel.duration,
                        volume: $viewModel.volume,
                        isShuffled: viewModel.isShuffled,
                        isLiked: viewModel.isLiked,
                        repeatIcon: viewModel.repeatMode.icon,
                        isRepeatActive: viewModel.repeatMode.isActive,
                        onPlay: viewModel.play,
                        onPause: viewModel.pause,
                        onSkipPrevious: viewModel.skipPrevious,
                        onSkipNext: viewModel.skipNext,
                        onSeek: viewModel.seek,
                        onVolumeChange: viewModel.setVolume,
                        onShuffle: viewModel.toggleShuffle,
                        onLike: viewModel.toggleLike,
                        onRepeat: viewModel.cycleRepeatMode
                    )
                    .frame(maxWidth: controlsMaxWidth(for: geometry.size))

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                // TODO: Fix BlurredArtworkBackground - it interferes with layout calculations
                // causing text to be cut off. Need to find a way to render background
                // without affecting GeometryReader sizing.
                // .background(
                //     BlurredArtworkBackground(artworkURL: viewModel.artworkURL, cacheService: imageCacheService)
                // )
                .overlay(
                    // Show menu button in miniplayer mode
                    Group {
                        if geometry.size.width < LayoutBreakpoint.miniplayerWidth {
                            MiniPlayerMenuButton(
                                selectedPlayer: selectedPlayer,
                                availablePlayers: availablePlayers,
                                onPlayerSelect: { player in
                                    viewModel.handlePlayerSelection(player)
                                },
                                onShowQueue: {
                                    // TODO: Implement queue popover in next task
                                    AppLogger.ui.info("Show queue requested")
                                }
                            )
                        }
                    }
                )
        }
    }

    // MARK: - Responsive Sizing

    private func albumArtSize(for size: CGSize) -> CGFloat {
        let baseSize = min(size.width, size.height) * AlbumArtSize.sizeMultiplier
        return min(baseSize, AlbumArtSize.maximum)
    }

    private func titleFontSize(for size: CGSize) -> CGFloat {
        size.width < LayoutBreakpoint.smallWindow ? FontSize.titleSmall : FontSize.titleLarge
    }

    private func metadataFontSize(for size: CGSize) -> CGFloat {
        size.width < LayoutBreakpoint.smallWindow ? FontSize.metadataSmall : FontSize.metadataLarge
    }

    private func responsiveSpacing(for size: CGSize) -> CGFloat {
        size.width < LayoutBreakpoint.smallWindow ? Spacing.small : Spacing.large
    }

    private func controlsMaxWidth(for size: CGSize) -> CGFloat {
        size.width > LayoutBreakpoint.largeWindow ? ControlsWidth.large : ControlsWidth.standard
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
            NowPlayingView(
                viewModel: {
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
                    )
                ],
                imageCacheService: ImageCacheService()
            )
        }
    }

    return PreviewWrapper()
}
