// ABOUTME: Main now playing display with album art and metadata
// ABOUTME: Central hero section with blurred background and responsive layout

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var viewModel: NowPlayingViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Blurred background
                BlurredArtworkBackground(artworkURL: viewModel.artworkURL)

                // Content
                VStack(spacing: responsiveSpacing(for: geometry.size)) {
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
                        onShuffle: viewModel.toggleShuffle,
                        onLike: viewModel.toggleLike,
                        onRepeat: viewModel.cycleRepeatMode
                    )
                    .frame(maxWidth: controlsMaxWidth(for: geometry.size))

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Show menu button in miniplayer mode (< 700px width)
                if geometry.size.width < 700 {
                    MiniPlayerMenuButton(
                        selectedPlayer: viewModel.selectedPlayer,
                        availablePlayers: viewModel.availablePlayers,
                        onPlayerSelect: { player in
                            viewModel.handlePlayerSelection(player)
                        },
                        onShowQueue: {
                            // TODO: Implement queue popover in next task
                            print("Show queue requested")
                        }
                    )
                }
            }
        }
    }

    // MARK: - Responsive Sizing

    private func albumArtSize(for size: CGSize) -> CGFloat {
        let baseSize = min(size.width, size.height) * 0.55
        return min(baseSize, 800)
    }

    private func titleFontSize(for size: CGSize) -> CGFloat {
        size.width < 800 ? 24 : 28
    }

    private func metadataFontSize(for size: CGSize) -> CGFloat {
        size.width < 800 ? 14 : 18
    }

    private func responsiveSpacing(for size: CGSize) -> CGFloat {
        size.width < 800 ? 16 : 24
    }

    private func controlsMaxWidth(for size: CGSize) -> CGFloat {
        size.width > 1200 ? 700 : 600
    }
}

#Preview {
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
        }()
    )
}
