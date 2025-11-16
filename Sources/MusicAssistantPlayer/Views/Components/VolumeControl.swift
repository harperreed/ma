// ABOUTME: Volume control slider with speaker icons
// ABOUTME: Debounced volume updates to prevent API call spam

import SwiftUI

struct VolumeControl: View {
    @Binding var volume: Double
    let colors: ExtractedColors
    let onVolumeChange: (Double) -> Void

    @State private var isEditing = false
    @State private var pendingVolume: Double?
    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)

            Slider(value: $volume, in: 0...100, onEditingChanged: { editing in
                isEditing = editing
                if !editing, let finalVolume = pendingVolume {
                    // User finished dragging, send final value
                    onVolumeChange(finalVolume)
                    pendingVolume = nil
                    debounceTask?.cancel()
                }
            })
            .tint(colors.vibrant)
            .frame(width: 140)
            .onChange(of: volume) { oldValue, newValue in
                // Only track changes during user interaction
                guard isEditing else { return }

                pendingVolume = newValue

                // Debounce: cancel previous task and start new one
                debounceTask?.cancel()
                debounceTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    if !Task.isCancelled, let volume = pendingVolume {
                        onVolumeChange(volume)
                    }
                }
            }

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
        }
    }
}

#Preview {
    VStack {
        VolumeControl(volume: .constant(50), colors: ExtractedColors.fallback, onVolumeChange: { _ in })
        VolumeControl(volume: .constant(75), colors: ExtractedColors.fallback, onVolumeChange: { _ in })
    }
    .padding()
    .background(Color.black)
}
