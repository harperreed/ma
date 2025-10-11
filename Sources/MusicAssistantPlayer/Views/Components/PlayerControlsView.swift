// ABOUTME: Playback control buttons (play/pause, skip, progress bar)
// ABOUTME: Provides transport controls and progress scrubbing interface

import SwiftUI

struct PlayerControlsView: View {
    let isPlaying: Bool
    let progress: TimeInterval
    let duration: TimeInterval
    let onPlay: () -> Void
    let onPause: () -> Void
    let onSkipPrevious: () -> Void
    let onSkipNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: progressWidth(geometry: geometry), height: 4)
                    }
                }
                .frame(height: 4)

                // Time labels
                HStack {
                    Text(formatTime(progress))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(formatTime(duration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Transport controls
            HStack(spacing: 32) {
                Button(action: onSkipPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: isPlaying ? onPause : onPlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: onSkipNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        guard duration > 0 else { return 0 }
        return geometry.size.width * CGFloat(progress / duration)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 40) {
        PlayerControlsView(
            isPlaying: false,
            progress: 45,
            duration: 180,
            onPlay: {},
            onPause: {},
            onSkipPrevious: {},
            onSkipNext: {}
        )

        PlayerControlsView(
            isPlaying: true,
            progress: 120,
            duration: 240,
            onPlay: {},
            onPause: {},
            onSkipPrevious: {},
            onSkipNext: {}
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
