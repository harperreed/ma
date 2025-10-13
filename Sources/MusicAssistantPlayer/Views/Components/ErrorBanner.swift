// ABOUTME: Error notification banner for user-facing error messages
// ABOUTME: Shows at top of view with dismiss action and auto-dismissal

import SwiftUI

struct ErrorBanner: View {
    let error: PlayerError
    let onDismiss: () -> Void

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.userMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(error.technicalDetails)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.red.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    dismiss()
                }
            }
        }
    }

    private func dismiss() {
        withAnimation {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}
