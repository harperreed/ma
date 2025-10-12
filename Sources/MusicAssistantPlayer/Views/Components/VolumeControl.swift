// ABOUTME: Volume control slider with speaker icons
// ABOUTME: Manages local volume state (API integration pending)

import SwiftUI

struct VolumeControl: View {
    @Binding var volume: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)

            Slider(value: $volume, in: 0...100)
                .tint(.white)
                .frame(width: 200)

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
        }
    }
}

#Preview {
    VStack {
        VolumeControl(volume: .constant(50))
        VolumeControl(volume: .constant(75))
    }
    .padding()
    .background(Color.black)
}
