// ABOUTME: Main now playing display with album art and metadata
// ABOUTME: Central hero section showing current track and playback controls

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var viewModel: NowPlayingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Album art
            AlbumArtView(
                artworkURL: viewModel.artworkURL,
                size: 320
            )

            // Track metadata
            VStack(spacing: 8) {
                Text(viewModel.trackTitle)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(viewModel.artistName)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))

                    if !viewModel.albumName.isEmpty {
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        Text(viewModel.albumName)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .lineLimit(1)
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
            .frame(maxWidth: 500)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.15, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
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

    return NowPlayingView(
        viewModel: NowPlayingViewModel(playerService: playerService)
    )
}
