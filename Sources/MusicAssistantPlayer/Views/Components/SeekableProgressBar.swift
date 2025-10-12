// ABOUTME: Seekable progress bar with drag gesture support
// ABOUTME: Provides visual feedback and time scrubbing for playback

import SwiftUI

struct SeekableProgressBar: View {
    let progress: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void

    @State private var isDragging = false
    @State private var dragProgress: TimeInterval?

    private var displayProgress: TimeInterval {
        dragProgress ?? progress
    }

    var body: some View {
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

                    // Scrubber handle (only visible when dragging or hovering)
                    if isDragging {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .offset(x: progressWidth(geometry: geometry) - 6)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let percent = value.location.x / geometry.size.width
                            let newProgress = duration * Double(max(0, min(1, percent)))
                            dragProgress = newProgress
                        }
                        .onEnded { value in
                            isDragging = false
                            if let finalProgress = dragProgress {
                                onSeek(finalProgress)
                            }
                            dragProgress = nil
                        }
                )
            }
            .frame(height: 12)

            // Time labels
            HStack {
                Text(formatTime(displayProgress))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()
                Spacer()
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()
            }
        }
    }

    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        guard duration > 0 else { return 0 }
        let percent = min(max(displayProgress / duration, 0), 1.0)
        return geometry.size.width * CGFloat(percent)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 40) {
        SeekableProgressBar(
            progress: 120,
            duration: 240,
            onSeek: { _ in }
        )
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
