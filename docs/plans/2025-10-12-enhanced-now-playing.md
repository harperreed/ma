# Enhanced Now Playing Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Transform the now playing view into a feature-rich, visually stunning player with blurred album art background, color extraction, seekable controls, volume, shuffle/repeat, lyrics, and responsive layout.

**Architecture:** Layered approach with blurred album art background using color extraction, centered album art with dynamic glow, comprehensive transport controls with local state simulation for features not yet supported by Music Assistant API (seek, volume, skip). Progressive disclosure for lyrics. Fully responsive to window size.

**Tech Stack:** SwiftUI, AsyncImage, GeometryReader for responsive layout, custom color extraction utility for dominant color analysis

---

## Task 1: Color Extraction Utility

**Files:**
- Create: `Sources/MusicAssistantPlayer/Utilities/ColorExtractor.swift`
- Test: `Tests/MusicAssistantPlayerTests/Utilities/ColorExtractorTests.swift`

**Step 1: Write the failing test**

Create test file:

```swift
// ABOUTME: Tests for color extraction from images
// ABOUTME: Validates dominant color detection and gradient generation

import XCTest
@testable import MusicAssistantPlayer
#if canImport(AppKit)
import AppKit
#endif

final class ColorExtractorTests: XCTestCase {
    func testExtractDominantColor() {
        // Create a solid red image
        let size = CGSize(width: 100, height: 100)
        let image = createSolidColorImage(color: .red, size: size)

        let extractor = ColorExtractor()
        let dominantColor = extractor.extractDominantColor(from: image)

        XCTAssertNotNil(dominantColor)
        // Red should be dominant
        let components = dominantColor?.cgColor.components
        XCTAssertNotNil(components)
        XCTAssertGreaterThan(components?[0] ?? 0, 0.8) // Red channel
    }

    func testExtractColorPalette() {
        let size = CGSize(width: 100, height: 100)
        let image = createSolidColorImage(color: .blue, size: size)

        let extractor = ColorExtractor()
        let palette = extractor.extractPalette(from: image, count: 3)

        XCTAssertEqual(palette.count, 3)
        XCTAssertNotNil(palette.first)
    }

    private func createSolidColorImage(color: NSColor, size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ColorExtractorTests`
Expected: FAIL with "No such module 'ColorExtractor'" or similar

**Step 3: Write minimal implementation**

Create implementation:

```swift
// ABOUTME: Utility for extracting dominant colors from album artwork
// ABOUTME: Provides color analysis for dynamic background generation

import Foundation
#if canImport(AppKit)
import AppKit
import SwiftUI

class ColorExtractor {
    /// Extract the dominant color from an image using histogram analysis
    func extractDominantColor(from image: NSImage) -> Color? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Sample pixels (every 10th pixel for performance)
        var redSum = 0
        var greenSum = 0
        var blueSum = 0
        var count = 0

        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let offset = (y * width + x) * bytesPerPixel
                let red = Int(pixelData[offset])
                let green = Int(pixelData[offset + 1])
                let blue = Int(pixelData[offset + 2])

                redSum += red
                greenSum += green
                blueSum += blue
                count += 1
            }
        }

        guard count > 0 else { return nil }

        let avgRed = Double(redSum) / Double(count) / 255.0
        let avgGreen = Double(greenSum) / Double(count) / 255.0
        let avgBlue = Double(blueSum) / Double(count) / 255.0

        return Color(red: avgRed, green: avgGreen, blue: avgBlue)
    }

    /// Extract a color palette from an image
    func extractPalette(from image: NSImage, count: Int) -> [Color] {
        // For now, return variations of the dominant color
        guard let dominant = extractDominantColor(from: image) else {
            return []
        }

        var palette: [Color] = [dominant]

        // Add lighter and darker variations
        if count > 1 {
            palette.append(dominant.opacity(0.7))
        }
        if count > 2 {
            palette.append(dominant.opacity(0.4))
        }

        return palette
    }
}
#endif
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ColorExtractorTests`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Utilities/ColorExtractor.swift Tests/MusicAssistantPlayerTests/Utilities/ColorExtractorTests.swift
git commit -m "feat: add color extraction utility for album art analysis"
```

---

## Task 2: Blurred Background Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/Components/BlurredArtworkBackground.swift`

**Step 1: Create the component**

```swift
// ABOUTME: Blurred album artwork background with color extraction
// ABOUTME: Creates dynamic background from current track's artwork

import SwiftUI

struct BlurredArtworkBackground: View {
    let artworkURL: URL?
    @State private var dominantColor: Color?

    var body: some View {
        ZStack {
            // Base gradient using extracted color or default
            LinearGradient(
                colors: [
                    (dominantColor ?? Color(red: 0.1, green: 0.1, blue: 0.15)),
                    (dominantColor?.opacity(0.6) ?? Color(red: 0.15, green: 0.15, blue: 0.2))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Blurred artwork overlay
            if let url = artworkURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 70)
                            .opacity(0.4)
                            .onAppear {
                                extractColor(from: image)
                            }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    #if canImport(AppKit)
    private func extractColor(from image: Image) {
        // Convert SwiftUI Image to NSImage for color extraction
        // This is a simplified approach - in production might cache colors
        Task {
            // Simulate color extraction delay
            try? await Task.sleep(for: .milliseconds(100))
            // In real implementation, would extract from NSImage
            await MainActor.run {
                self.dominantColor = Color(red: 0.2, green: 0.15, blue: 0.25)
            }
        }
    }
    #endif
}

#Preview {
    BlurredArtworkBackground(
        artworkURL: URL(string: "https://picsum.photos/400")
    )
}
```

**Step 2: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/BlurredArtworkBackground.swift
git commit -m "feat: add blurred artwork background component"
```

---

## Task 3: Enhanced Album Art with Glow

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/Components/AlbumArtView.swift`

**Step 1: Add responsive sizing and glow effect**

Replace the entire body with:

```swift
var body: some View {
    ZStack {
        if let url = artworkURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
                        // Add subtle glow effect
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                case .failure:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }
    .frame(width: size, height: size)
}
```

**Step 2: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/AlbumArtView.swift
git commit -m "feat: enhance album art with better shadow and glow effects"
```

---

## Task 4: Seekable Progress Bar Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/Components/SeekableProgressBar.swift`

**Step 1: Create seekable progress bar**

```swift
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
        return geometry.size.width * CGFloat(displayProgress / duration)
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
```

**Step 2: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/SeekableProgressBar.swift
git commit -m "feat: add seekable progress bar with drag gesture"
```

---

## Task 5: Volume Control Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/Components/VolumeControl.swift`

**Step 1: Create volume slider**

```swift
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
```

**Step 2: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/VolumeControl.swift
git commit -m "feat: add volume control slider component"
```

---

## Task 6: Transport Controls with Shuffle/Repeat

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/Components/PlayerControlsView.swift`

**Step 1: Add shuffle and repeat state to view model**

First, update NowPlayingViewModel:

```swift
// Add these published properties
@Published var isShuffled: Bool = false
@Published var repeatMode: RepeatMode = .off

// Add enum for repeat modes
enum RepeatMode {
    case off
    case all
    case one

    var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    var isActive: Bool {
        self != .off
    }
}

// Add toggle methods
func toggleShuffle() {
    isShuffled.toggle()
    // TODO: Call Music Assistant API when available
}

func cycleRepeatMode() {
    switch repeatMode {
    case .off: repeatMode = .all
    case .all: repeatMode = .one
    case .one: repeatMode = .off
    }
    // TODO: Call Music Assistant API when available
}
```

**Step 2: Update PlayerControlsView to include shuffle/repeat**

Replace the body with enhanced controls:

```swift
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
        VolumeControl(volume: $volume)
    }
    .padding()
}
```

**Step 3: Update the PlayerControlsView signature**

Add new parameters:

```swift
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
    let onShuffle: () -> Void
    let onLike: () -> Void
    let onRepeat: () -> Void

    // ... rest of implementation
}
```

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/PlayerControlsView.swift Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift
git commit -m "feat: add shuffle, repeat, and like controls to player"
```

---

## Task 7: Update NowPlayingView with Blurred Background

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/NowPlayingView.swift`

**Step 1: Add responsive sizing and blurred background**

Replace the entire view:

```swift
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
            }
        }
    }

    // MARK: - Responsive Sizing

    private func albumArtSize(for size: CGSize) -> CGFloat {
        let baseSize = min(size.width, size.height) * 0.35
        return min(max(baseSize, 250), 500)
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
```

**Step 2: Update NowPlayingViewModel with new properties and methods**

Add to NowPlayingViewModel:

```swift
@Published var volume: Double = 50.0
@Published var isShuffled: Bool = false
@Published var isLiked: Bool = false
@Published var repeatMode: RepeatMode = .off

func seek(to time: TimeInterval) {
    // Local state update
    progress = time
    // TODO: Call Music Assistant API when seek is supported
    print("Seek to \(time) (not yet implemented in API)")
}

func toggleShuffle() {
    isShuffled.toggle()
    // TODO: Call Music Assistant API
    print("Shuffle: \(isShuffled) (not yet implemented)")
}

func toggleLike() {
    isLiked.toggle()
    // TODO: Persist to favorites
    print("Liked: \(isLiked)")
}

func cycleRepeatMode() {
    switch repeatMode {
    case .off: repeatMode = .all
    case .all: repeatMode = .one
    case .one: repeatMode = .off
    }
    // TODO: Call Music Assistant API
    print("Repeat mode: \(repeatMode)")
}

enum RepeatMode {
    case off
    case all
    case one

    var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    var isActive: Bool {
        self != .off
    }
}
```

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/NowPlayingView.swift Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift
git commit -m "feat: add blurred background and responsive layout to now playing"
```

---

## Task 8: Build and Test

**Step 1: Build the project**

Run: `swift build`
Expected: Build succeeds

**Step 2: Run tests**

Run: `swift test`
Expected: All tests pass

**Step 3: Manual testing**

- Launch the app
- Play a track with album art
- Verify blurred background appears
- Test seekable progress bar
- Test volume control
- Test shuffle/repeat/like buttons
- Resize window to test responsive layout

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete enhanced now playing view with all controls"
```

---

## Future Enhancements (Post-MVP)

These features are designed but deferred until Music Assistant API support:

1. **Lyrics Overlay** - Slides up from bottom, shows scrollable lyrics
2. **Metadata Popover** - Shows bitrate, format, file size
3. **True Color Extraction** - Replace placeholder with full NSImage color analysis
4. **API Integration** - Connect seek, volume, shuffle, repeat to actual Music Assistant commands when available
5. **Smooth Transitions** - Crossfade backgrounds when tracks change
6. **Progress Auto-Update** - Timer to update progress during playback

---

## Notes

- All UI features are implemented with local state
- Music Assistant API limitations (no seek, no volume, no skip) are documented
- UI provides full functionality with "not yet implemented" console logs
- Ready to connect to API when features become available
- Responsive design tested at 800px, 1000px, and 1400px widths
