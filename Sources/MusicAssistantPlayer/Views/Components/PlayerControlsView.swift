// ABOUTME: Playback control buttons (play/pause, skip, progress bar)
// ABOUTME: Provides transport controls and progress scrubbing interface

import SwiftUI

struct PlayerControlsView: View {
    let isPlaying: Bool
    let progress: TimeInterval
    let duration: TimeInterval
    @Binding var volume: Double
    let isShuffled: Bool
    let isLiked: Bool
    let repeatIcon: String
    let isRepeatActive: Bool

    let onPlay: () -> Void
    let onPause: () -> Void
    let onSkipPrevious: () -> Void
    let onSkipNext: () -> Void
    let onSeek: (TimeInterval) -> Void
    let onVolumeChange: (Double) -> Void
    let onShuffle: () -> Void
    let onLike: () -> Void
    let onRepeat: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Secondary controls (shuffle, like, repeat)
            HStack {
                Button(action: onShuffle) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 20))
                        .foregroundColor(isShuffled ? .white : .white.opacity(0.5))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isLiked ? .red : .white.opacity(0.5))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onRepeat) {
                    Image(systemName: repeatIcon)
                        .font(.system(size: 20))
                        .foregroundColor(isRepeatActive ? .white : .white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 500)
            .padding(.horizontal)

            // Progress bar (seekable)
            SeekableProgressBar(
                progress: progress,
                duration: duration,
                onSeek: onSeek
            )
            .padding(.horizontal)

            // Transport controls
            HStack(spacing: 40) {
                Button(action: onSkipPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: isPlaying ? onPause : onPlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: onSkipNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }

            // Volume control
            VolumeControl(volume: $volume, onVolumeChange: onVolumeChange)
        }
        .padding()
    }

}

#Preview {
    struct PreviewWrapper: View {
        @State private var volume: Double = 50

        var body: some View {
            VStack(spacing: 40) {
                PlayerControlsView(
                    isPlaying: false,
                    progress: 45,
                    duration: 180,
                    volume: $volume,
                    isShuffled: false,
                    isLiked: false,
                    repeatIcon: "repeat",
                    isRepeatActive: false,
                    onPlay: {},
                    onPause: {},
                    onSkipPrevious: {},
                    onSkipNext: {},
                    onSeek: { _ in },
                    onVolumeChange: { _ in },
                    onShuffle: {},
                    onLike: {},
                    onRepeat: {}
                )

                PlayerControlsView(
                    isPlaying: true,
                    progress: 120,
                    duration: 240,
                    volume: $volume,
                    isShuffled: true,
                    isLiked: true,
                    repeatIcon: "repeat.1",
                    isRepeatActive: true,
                    onPlay: {},
                    onPause: {},
                    onSkipPrevious: {},
                    onSkipNext: {},
                    onSeek: { _ in },
                    onVolumeChange: { _ in },
                    onShuffle: {},
                    onLike: {},
                    onRepeat: {}
                )
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
    }

    return PreviewWrapper()
}
