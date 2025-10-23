# Radio Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add radio station browsing, search, and playback to the library interface.

**Architecture:** Create RadiosListView following the established list view pattern (PlaylistsListView, TracksListView). Wire into existing LibraryViewModel and LibraryBrowseView. Add search support to LibraryService.

**Tech Stack:** SwiftUI, MusicAssistantKit, Combine

---

## Task 1: Create RadiosListView Component

**Files:**
- Create: `Sources/MusicAssistantPlayer/Views/RadiosListView.swift`
- Reference: `Sources/MusicAssistantPlayer/Views/PlaylistsListView.swift` (pattern to follow)

**Step 1: Create the RadiosListView file**

Create `Sources/MusicAssistantPlayer/Views/RadiosListView.swift`:

```swift
// ABOUTME: List view for displaying radio stations from Music Assistant
// ABOUTME: Provides play and queue actions for radio stations

import SwiftUI

struct RadiosListView: View {
    let radios: [Radio]
    let onPlayNow: (Radio) -> Void
    let onAddToQueue: (Radio) -> Void
    let onLoadMore: (() -> Void)?

    @State private var hoveredRadio: Radio.ID?

    var body: some View {
        ScrollView {
            if radios.isEmpty {
                Text("No radio stations found")
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(radios) { radio in
                        radioRow(radio)
                            .onHover { isHovered in
                                hoveredRadio = isHovered ? radio.id : nil
                            }
                    }

                    // Load more trigger
                    if let loadMore = onLoadMore {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                loadMore()
                            }
                    }
                }
            }
        }
    }

    private func radioRow(_ radio: Radio) -> some View {
        HStack(spacing: 12) {
            // Artwork
            if let artworkURL = radio.artworkURL {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 40, height: 40)
                .cornerRadius(4)
            } else {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(4)
            }

            // Station info
            VStack(alignment: .leading, spacing: 2) {
                Text(radio.name)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let provider = radio.provider {
                    Text(provider)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Action buttons (show on hover)
            if hoveredRadio == radio.id {
                HStack(spacing: 8) {
                    Button(action: { onPlayNow(radio) }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { onAddToQueue(radio) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.gray.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            hoveredRadio == radio.id ?
                Color.white.opacity(0.1) : Color.clear
        )
    }
}

// MARK: - Preview
#Preview {
    let sampleRadios = [
        Radio(id: "1", name: "KEXP 90.3 FM", artworkURL: nil, provider: "Radio Browser"),
        Radio(id: "2", name: "BBC Radio 6", artworkURL: nil, provider: "TuneIn"),
        Radio(id: "3", name: "NTS Radio", artworkURL: nil, provider: "Radio Browser")
    ]

    return RadiosListView(
        radios: sampleRadios,
        onPlayNow: { _ in },
        onAddToQueue: { _ in },
        onLoadMore: nil
    )
    .frame(width: 600, height: 400)
    .background(Color.black)
}
```

**Step 2: Add RadiosListView to Xcode project**

In Xcode:
1. Right-click on the `Views` folder in project navigator
2. Select "Add Files to MusicAssistantPlayer..."
3. Navigate to `Sources/MusicAssistantPlayer/Views/RadiosListView.swift`
4. Uncheck "Copy items if needed"
5. Check the MusicAssistantPlayer target
6. Click Add

**Step 3: Build to verify no compilation errors**

Run: `swift build` or build in Xcode (Cmd+B)
Expected: Build succeeds

**Step 4: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/RadiosListView.swift
git commit -m "feat: add RadiosListView component for radio stations

- Create list view following PlaylistsListView pattern
- Show station artwork, name, provider
- Hover reveals play/queue buttons
- Empty state for no results
- Pagination support via onLoadMore

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: Add Radio Support to LibraryViewModel

**Files:**
- Modify: `Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift`

**Step 1: Add radios computed property**

In `LibraryViewModel.swift`, after the `tracks` property (around line 74), add:

```swift
var radios: [Radio] {
    libraryService.radios
}
```

**Step 2: Add radio case to loadContent() method**

Find the `loadContent()` method and add the `.radio` case. After the `.playlists` case, add:

```swift
case .radio:
    try await libraryService.fetchRadios(
        limit: nil,
        offset: 0,
        sort: selectedSort,
        filter: selectedFilter,
        forceRefresh: false
    )
```

**Step 3: Add radio case to performSearch() method**

Find the `performSearch()` method and add the `.radio` case. After the `.playlists` case, add:

```swift
case .radio:
    try await libraryService.searchRadios(query: query)
```

**Step 4: Add radio case to loadMore() method**

Find the `loadMore()` method and add the `.radio` case. After the `.playlists` case, add:

```swift
case .radio:
    try await libraryService.fetchRadios(
        limit: nil,
        offset: nil,
        sort: selectedSort,
        filter: selectedFilter,
        forceRefresh: false
    )
```

**Step 5: Build to verify no compilation errors**

Run: `swift build`
Expected: Build succeeds

**Step 6: Commit**

```bash
git add Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift
git commit -m "feat: add radio support to LibraryViewModel

- Add radios computed property
- Add radio cases to loadContent, performSearch, loadMore
- Enable radio browsing and search in library

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3: Add Radio Search to LibraryService

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Services/LibraryService.swift`

**Step 1: Add searchRadios method**

In `LibraryService.swift`, after the `fetchRadios()` method (around line 970), add:

```swift
func searchRadios(query: String) async throws {
    guard let client = client else {
        let error = LibraryError.noClientAvailable
        lastError = error
        throw error
    }

    guard !query.isEmpty else {
        // Empty query - clear results
        self.radios = []
        return
    }

    do {
        AppLogger.network.info("Searching radios: query='\(query)'")

        // Music Assistant API: music/radios/search
        let result = try await client.sendCommand(
            command: "music/radios/search",
            args: [
                "search": query,
                "limit": 50
            ]
        )

        if let result = result {
            let parsedRadios = parseRadios(from: result)
            self.radios = parsedRadios
            self.hasMoreItems = false // Search results don't paginate
            lastError = nil
        } else {
            self.radios = []
            self.hasMoreItems = false
            lastError = nil
        }
    } catch let error as LibraryError {
        AppLogger.errors.logError(error, context: "searchRadios")
        lastError = error
        throw error
    } catch {
        let libError = LibraryError.networkError(error.localizedDescription)
        AppLogger.errors.logError(error, context: "searchRadios")
        lastError = libError
        throw libError
    }
}
```

**Step 2: Build to verify no compilation errors**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Services/LibraryService.swift
git commit -m "feat: add radio search to LibraryService

- Implement searchRadios method
- Call music/radios/search API
- Parse results using existing parseRadios
- Handle empty queries and errors

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: Wire RadiosListView into LibraryBrowseView

**Files:**
- Modify: `Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift`

**Step 1: Replace "Coming Soon" with RadiosListView**

Find the switch statement with `case .radio, .genres:` (around line 198) and replace it with separate cases:

```swift
case .radio:
    RadiosListView(
        radios: viewModel.radios,
        onPlayNow: { onPlayNow($0.id, .radio) },
        onAddToQueue: { onAddToQueue($0.id, .radio) },
        onLoadMore: {
            Task {
                await viewModel.loadMore()
            }
        }
    )
case .genres:
    Text("Coming Soon")
        .foregroundColor(.white.opacity(0.5))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
```

**Step 2: Build to verify no compilation errors**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift
git commit -m "feat: wire RadiosListView into library browse interface

- Replace 'Coming Soon' with RadiosListView for radio category
- Connect play and queue callbacks
- Enable pagination for radio stations
- Keep genres as 'Coming Soon' (next to implement)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 5: Manual Testing

**Step 1: Build and run the app**

Run in Xcode (Cmd+R) or: `swift run`

**Step 2: Test radio browsing**

1. Click "Radio" in the library sidebar
2. Verify radio stations load and display
3. Verify station artwork or placeholder icon shows
4. Verify station name and provider display
5. Hover over a station
6. Verify play and queue buttons appear on hover

**Step 3: Test radio playback**

1. Click the play button on a radio station
2. Verify the station starts playing
3. Verify now playing UI updates with station info

**Step 4: Test radio search**

1. Type a search query in the search bar (e.g., "BBC")
2. Wait for debounce (500ms)
3. Verify search results appear
4. Clear search
5. Verify full list returns

**Step 5: Test pagination**

1. Browse radio stations
2. Scroll to bottom of list
3. Verify more stations load automatically
4. Verify "Load More" button appears if pagination available

**Step 6: Test error handling**

1. Disconnect from network or stop Music Assistant server
2. Try to browse radio
3. Verify error message displays appropriately
4. Reconnect and verify recovery

---

## Task 6: Write Tests

**Files:**
- Create: `Tests/MusicAssistantPlayerTests/Views/RadiosListViewTests.swift`
- Create: `Tests/MusicAssistantPlayerTests/ViewModels/LibraryViewModelRadioTests.swift`

**Step 1: Create RadiosListView tests**

Create `Tests/MusicAssistantPlayerTests/Views/RadiosListViewTests.swift`:

```swift
// ABOUTME: Tests for RadiosListView component
// ABOUTME: Verifies radio station display, empty states, and interactions

import Testing
@testable import MusicAssistantPlayer

@Suite("RadiosListView Tests")
struct RadiosListViewTests {

    @Test("RadiosListView displays radio stations")
    func displaysRadioStations() {
        let radios = [
            Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser"),
            Radio(id: "2", name: "BBC Radio 6", artworkURL: nil, provider: "TuneIn")
        ]

        let view = RadiosListView(
            radios: radios,
            onPlayNow: { _ in },
            onAddToQueue: { _ in },
            onLoadMore: nil
        )

        #expect(view.radios.count == 2)
        #expect(view.radios[0].name == "KEXP")
        #expect(view.radios[1].name == "BBC Radio 6")
    }

    @Test("RadiosListView shows empty state when no radios")
    func showsEmptyState() {
        let view = RadiosListView(
            radios: [],
            onPlayNow: { _ in },
            onAddToQueue: { _ in },
            onLoadMore: nil
        )

        #expect(view.radios.isEmpty)
    }

    @Test("RadiosListView calls onPlayNow callback")
    func callsPlayNowCallback() {
        let radio = Radio(id: "1", name: "Test", artworkURL: nil, provider: nil)
        var playedRadio: Radio?

        let view = RadiosListView(
            radios: [radio],
            onPlayNow: { playedRadio = $0 },
            onAddToQueue: { _ in },
            onLoadMore: nil
        )

        view.onPlayNow(radio)
        #expect(playedRadio?.id == "1")
    }

    @Test("RadiosListView calls onAddToQueue callback")
    func callsAddToQueueCallback() {
        let radio = Radio(id: "1", name: "Test", artworkURL: nil, provider: nil)
        var queuedRadio: Radio?

        let view = RadiosListView(
            radios: [radio],
            onPlayNow: { _ in },
            onAddToQueue: { queuedRadio = $0 },
            onLoadMore: nil
        )

        view.onAddToQueue(radio)
        #expect(queuedRadio?.id == "1")
    }
}
```

**Step 2: Add file to Xcode project**

Add `RadiosListViewTests.swift` to the Tests target in Xcode.

**Step 3: Run tests**

Run: `swift test` or Cmd+U in Xcode
Expected: All tests pass

**Step 4: Create LibraryViewModel radio tests**

Create `Tests/MusicAssistantPlayerTests/ViewModels/LibraryViewModelRadioTests.swift`:

```swift
// ABOUTME: Tests for LibraryViewModel radio functionality
// ABOUTME: Verifies radio loading, search, and pagination

import Testing
@testable import MusicAssistantPlayer
import MusicAssistantKit

@Suite("LibraryViewModel Radio Tests")
struct LibraryViewModelRadioTests {

    @Test("LibraryViewModel exposes radios from service")
    @MainActor
    func exposesRadiosFromService() async {
        let mockClient = MockMusicAssistantClient()
        let service = LibraryService(client: mockClient)
        let viewModel = LibraryViewModel(libraryService: service)

        // Simulate service having radios
        await service.radios = [
            Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser")
        ]

        #expect(viewModel.radios.count == 1)
        #expect(viewModel.radios[0].name == "KEXP")
    }

    @Test("LibraryViewModel loads radios when category selected")
    @MainActor
    func loadsRadiosWhenCategorySelected() async throws {
        let mockClient = MockMusicAssistantClient()
        mockClient.mockRadios = [
            Radio(id: "1", name: "Test Radio", artworkURL: nil, provider: nil)
        ]

        let service = LibraryService(client: mockClient)
        let viewModel = LibraryViewModel(libraryService: service)

        viewModel.selectedCategory = .radio
        try await viewModel.loadContent()

        #expect(viewModel.radios.count == 1)
        #expect(viewModel.radios[0].name == "Test Radio")
    }
}
```

**Step 5: Add file to Xcode project**

Add `LibraryViewModelRadioTests.swift` to the Tests target in Xcode.

**Step 6: Run all tests**

Run: `swift test`
Expected: All tests pass

**Step 7: Commit**

```bash
git add Tests/MusicAssistantPlayerTests/Views/RadiosListViewTests.swift Tests/MusicAssistantPlayerTests/ViewModels/LibraryViewModelRadioTests.swift
git commit -m "test: add tests for radio feature

- Add RadiosListView component tests
- Add LibraryViewModel radio functionality tests
- Verify display, callbacks, loading, search

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 7: Final Verification

**Step 1: Run full test suite**

Run: `swift test`
Expected: All 240+ tests pass

**Step 2: Build for release**

Run: `swift build -c release`
Expected: Build succeeds

**Step 3: Manual smoke test**

1. Launch app
2. Navigate to Radio category
3. Browse stations
4. Search for a station
5. Play a station
6. Add station to queue
7. Verify everything works as expected

**Step 4: Push changes**

```bash
git push
```

---

## Completion Checklist

- [ ] Task 1: RadiosListView component created
- [ ] Task 2: LibraryViewModel updated with radio support
- [ ] Task 3: Radio search added to LibraryService
- [ ] Task 4: RadiosListView wired into LibraryBrowseView
- [ ] Task 5: Manual testing completed successfully
- [ ] Task 6: Unit tests written and passing
- [ ] Task 7: Final verification and push

## Notes

- The backend (LibraryService.fetchRadios) was already implemented, so no changes needed there
- Radio model already exists with all necessary fields
- Following the established pattern makes this feature consistent with other library categories
- Next category to implement would be Genres (currently still "Coming Soon")
