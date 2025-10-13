# Miniplayer Responsive Layout Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Make the player fully responsive with miniplayer mode at small window sizes, removing album art minimum size and providing menu access when sidebar/queue are hidden.

**Architecture:** Extend existing GeometryReader-based responsive pattern with additional breakpoints. At < 700px, hide sidebar and queue to create miniplayer mode. Add menu button overlay in NowPlayingView and menubar commands for accessing hidden features.

**Tech Stack:** SwiftUI, GeometryReader, macOS MenuBar commands, SF Symbols

---

## Task 1: Remove Album Art Minimum Size

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/NowPlayingView.swift:82-85`

**Step 1: No test needed for this change**

This is a visual/layout change that doesn't require unit testing. We'll verify visually by resizing the window.

**Step 2: Remove the minimum size constraint**

In `NowPlayingView.swift`, modify the `albumArtSize(for:)` function:

```swift
private func albumArtSize(for size: CGSize) -> CGFloat {
    let baseSize = min(size.width, size.height) * 0.55
    return min(baseSize, 800)  // Remove the max(..., 350) to allow full shrinking
}
```

**Step 3: Verify layout adapts**

Run: `swift run`
Expected: Album art should shrink proportionally with window size, no hard stop at 350px

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/NowPlayingView.swift
git commit -m "feat: remove album art minimum size for better responsive scaling"
```

---

## Task 2: Add Sidebar Hiding at < 700px

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift:31-62`
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift:104-107`

**Step 1: No test needed for layout logic**

This is responsive layout behavior that will be verified visually.

**Step 2: Add shouldShowSidebar function**

In `MainWindowView.swift`, add a new function after `queueWidth(for:)`:

```swift
private func shouldShowSidebar(for size: CGSize) -> Bool {
    // Hide sidebar on very small windows for miniplayer mode
    size.width >= 700
}
```

**Step 3: Update body to conditionally show sidebar**

In `MainWindowView.swift`, wrap the SidebarView in a conditional:

```swift
var body: some View {
    GeometryReader { geometry in
        HStack(spacing: 0) {
            // Sidebar (responsive width, hides in miniplayer mode)
            if shouldShowSidebar(for: geometry.size) {
                SidebarView(
                    selectedPlayer: $selectedPlayer,
                    availablePlayers: availablePlayers,
                    connectionState: playerService.connectionState,
                    serverHost: serverConfig.host,
                    onRetry: handleRetry
                )
                .frame(width: sidebarWidth(for: geometry.size))
                .onChange(of: selectedPlayer) { oldValue, newValue in
                    if let player = newValue {
                        handlePlayerSelection(player)
                    }
                }
            }

            // Now Playing (center hero)
            NowPlayingView(
                viewModel: NowPlayingViewModel(playerService: playerService)
            )
            .frame(maxWidth: .infinity)

            // Queue (right panel, responsive width)
            if shouldShowQueue(for: geometry.size) {
                QueueView(
                    viewModel: QueueViewModel(queueService: queueService)
                )
                .frame(width: queueWidth(for: geometry.size))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    .task {
        await fetchInitialData()
        subscribeToPlayerUpdates()
    }
    .onDisappear {
        playerUpdateTask?.cancel()
    }
}
```

**Step 4: Verify sidebar hides**

Run: `swift run`
Expected: Resize window to < 700px width, sidebar should disappear

**Step 5: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git commit -m "feat: hide sidebar at < 700px for miniplayer mode"
```

---

## Task 3: Create Miniplayer Menu Button Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/Components/MiniPlayerMenuButton.swift`
- Modify: `Sources/MusicAssistantPlayer/Views/NowPlayingView.swift:10-78`

**Step 1: No unit test for UI component**

This is a visual component that will be verified by running the app.

**Step 2: Create MiniPlayerMenuButton component**

Create `Sources/MusicAssistantPlayer/Views/Components/MiniPlayerMenuButton.swift`:

```swift
// ABOUTME: Menu button for accessing sidebar/queue when in miniplayer mode
// ABOUTME: Shows hamburger icon in top-left corner with semi-transparent background

import SwiftUI

struct MiniPlayerMenuButton: View {
    @Binding var selectedPlayer: Player?
    let availablePlayers: [Player]
    let onPlayerSelect: (Player) -> Void
    let onShowQueue: () -> Void

    @State private var showMenu = false

    var body: some View {
        VStack {
            HStack {
                Menu {
                    Section("Players") {
                        ForEach(availablePlayers) { player in
                            Button(action: {
                                onPlayerSelect(player)
                            }) {
                                HStack {
                                    Text(player.name)
                                    if selectedPlayer?.id == player.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    Button("Show Queue") {
                        onShowQueue()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .padding(16)

                Spacer()
            }
            Spacer()
        }
    }
}
```

**Step 3: Add menu button to NowPlayingView**

In `NowPlayingView.swift`, update the body to overlay the menu button when in miniplayer mode:

```swift
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

            // Show menu button in miniplayer mode
            if geometry.size.width < 700 {
                MiniPlayerMenuButton(
                    selectedPlayer: $viewModel.selectedPlayer,
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
```

**Step 4: Update NowPlayingViewModel to expose needed properties**

In `Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift`, add:

```swift
@Published var selectedPlayer: Player?
@Published var availablePlayers: [Player] = []

func handlePlayerSelection(_ player: Player) {
    selectedPlayer = player
    playerService.selectedPlayer = player

    Task {
        await playerService.fetchPlayerState(for: player.id)
    }
}
```

**Step 5: Verify menu button appears**

Run: `swift run`
Expected: At < 700px window width, menu button appears in top-left

**Step 6: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/Components/MiniPlayerMenuButton.swift
git add Sources/MusicAssistantPlayer/Views/NowPlayingView.swift
git add Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift
git commit -m "feat: add miniplayer menu button for player/queue access"
```

---

## Task 4: Add MenuBar Commands

**Files:**
- Modify: `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift`

**Step 1: No test needed for menubar commands**

Menubar integration is verified by running the app and checking the menus.

**Step 2: Add menubar commands**

In `MusicAssistantPlayerApp.swift`, add `.commands()` modifier:

```swift
import SwiftUI

@main
struct MusicAssistantPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Players") {
                // Populated dynamically by ContentView state
                Text("Player selection available in window")
                    .disabled(true)
            }

            CommandMenu("Queue") {
                Button("Show Queue") {
                    // TODO: Implement queue window/popover
                    print("Show queue from menubar")
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
        }
    }
}
```

**Note:** Full menubar integration with dynamic player list requires more architecture (app-level state). For now, this provides the menu structure. Future enhancement can connect it to actual player selection.

**Step 3: Verify menus appear**

Run: `swift run`
Expected: "Players" and "Queue" menus appear in macOS menubar

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift
git commit -m "feat: add menubar commands for Players and Queue"
```

---

## Task 5: Final Integration and Testing

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/MainWindowView.swift` (pass players to NowPlayingViewModel)

**Step 1: Connect availablePlayers to NowPlayingViewModel**

In `MainWindowView.swift`, update NowPlayingView initialization to pass players:

```swift
// Now Playing (center hero)
NowPlayingView(
    viewModel: NowPlayingViewModel(
        playerService: playerService,
        selectedPlayer: $selectedPlayer,
        availablePlayers: availablePlayers
    )
)
.frame(maxWidth: .infinity)
```

**Step 2: Update NowPlayingViewModel initializer**

In `Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift`:

```swift
init(playerService: PlayerService, selectedPlayer: Binding<Player?>? = nil, availablePlayers: [Player] = []) {
    self.playerService = playerService
    self._selectedPlayer = selectedPlayer != nil ? selectedPlayer! : .constant(nil)
    self.availablePlayers = availablePlayers
    // ... existing subscription setup
}
```

**Step 3: Run all tests**

Run: `swift test`
Expected: All 23 tests passing

**Step 4: Visual verification checklist**

Run: `swift run`

Verify:
- [ ] Window ≥ 1000px: Sidebar + NowPlaying + Queue all visible
- [ ] Window 700-999px: Sidebar + NowPlaying visible, Queue hidden
- [ ] Window < 700px: Only NowPlaying visible (miniplayer mode)
- [ ] Miniplayer mode shows menu button in top-left
- [ ] Menu button shows player list and queue option
- [ ] Album art shrinks smoothly with no hard minimum
- [ ] MenuBar has "Players" and "Queue" menus

**Step 5: Final commit**

```bash
git add Sources/MusicAssistantPlayer/Views/MainWindowView.swift
git add Sources/MusicAssistantPlayer/ViewModels/NowPlayingViewModel.swift
swift test  # Verify all tests pass
git commit -m "feat: complete miniplayer responsive layout with menu access"
```

---

## Success Criteria

✅ Album art scales proportionally without minimum size constraint
✅ Sidebar hides at < 700px for miniplayer mode
✅ Queue hides at < 1000px
✅ Menu button appears in miniplayer mode (< 700px)
✅ MenuBar commands for Players and Queue
✅ All 23 tests passing
✅ Smooth responsive transitions at all window sizes
