# Radio Feature Design

**Date:** 2025-10-23
**Status:** Approved for Implementation
**Approach:** List view pattern (Option 1)

## Overview

Add radio station browsing and playback to the Music Assistant Player app. Radio is the penultimate library category (before genres). The backend infrastructure already exists - this design focuses on UI integration.

## Requirements

- Browse available radio stations from Music Assistant
- Search radio stations by name
- Play radio stations through the player
- Add radio stations to queue
- Consistent UI with existing library categories (artists, albums, tracks, playlists)

## Architecture

### Data Flow

```
User selects Radio → LibraryViewModel.selectedCategory = .radio
    ↓
LibraryViewModel.loadContent() calls LibraryService.fetchRadios()
    ↓
LibraryService fetches from API: music/radios/library_items
    ↓
Service parses results → @Published var radios: [Radio]
    ↓
RadiosListView displays the list
    ↓
User clicks play → onPlayNow(radioId, .radio) → PlayerService plays station
```

### Existing Infrastructure (Already Implemented)

LibraryService already provides:
- `@Published var radios: [Radio]` - published property for UI binding
- `fetchRadios()` - fetches with pagination, sorting, filtering, caching
- `parseRadios()` - parses Music Assistant API responses

Radio model already exists:
```swift
struct Radio: Identifiable, Hashable {
    let id: String
    let name: String
    let artworkURL: URL?
    let provider: String?
}
```

## Components

### 1. RadiosListView (New)

**File:** `Sources/MusicAssistantPlayer/Views/RadiosListView.swift`

**Pattern:** Follow PlaylistsListView and TracksListView pattern

**Interface:**
```swift
struct RadiosListView: View {
    let radios: [Radio]
    let onPlayNow: (Radio) -> Void
    let onAddToQueue: (Radio) -> Void
    let onLoadMore: (() -> Void)?
}
```

**Display Format:**
- Vertical scrollable list
- Each row: artwork thumbnail (40x40), station name, provider name
- Hover reveals play/queue action buttons
- Empty state: "No radio stations found"
- Pagination support via onLoadMore callback

### 2. LibraryViewModel (Modify)

**File:** `Sources/MusicAssistantPlayer/ViewModels/LibraryViewModel.swift`

**Changes:**
- Add computed property: `var radios: [Radio] { libraryService.radios }`
- Add `.radio` case to `loadContent()` method → calls `libraryService.fetchRadios()`
- Add `.radio` case to `performSearch()` method → calls `libraryService.searchRadios()`
- Add `.radio` case to `loadMore()` method → pagination support

### 3. LibraryBrowseView (Modify)

**File:** `Sources/MusicAssistantPlayer/Views/LibraryBrowseView.swift`

**Changes:**
- Replace `case .radio, .genres:` with separate cases
- Add `.radio` case:
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
```

### 4. LibraryService (Modify)

**File:** `Sources/MusicAssistantPlayer/Services/LibraryService.swift`

**Changes:**
- Add `searchRadios(query: String)` method
- API call: `music/radios/search` with search term
- Parse results using existing `parseRadios()` method
- Update `radios` published property

## Search Implementation

Music Assistant API provides radio search via `music/radios/search` command.

**Method signature:**
```swift
func searchRadios(query: String) async throws {
    // Call music/radios/search API
    // Parse results
    // Update self.radios
}
```

## Error Handling

- Reuse existing `LibraryError` types (already covers network/API errors)
- Display errors via `LibraryViewModel.errorMessage` property
- Show empty state in RadiosListView when no results
- Failed API calls logged via AppLogger.errors

## Testing Strategy

### Unit Tests
- LibraryService.searchRadios() with mock client
- Radio search result parsing
- Error handling for failed searches

### UI Tests
- RadiosListView displays stations correctly
- Empty state shown when no stations
- Play/queue buttons trigger correct callbacks
- Pagination loads more items

### Integration Tests
- Full flow: select radio category → load → display → play
- Search flow: enter query → results update → select station

## Implementation Checklist

- [ ] Create RadiosListView.swift (~100 lines)
- [ ] Add radio cases to LibraryViewModel (loadContent, performSearch, loadMore, radios property)
- [ ] Wire RadiosListView into LibraryBrowseView
- [ ] Add searchRadios() method to LibraryService
- [ ] Write unit tests for radio search
- [ ] Write UI tests for RadiosListView
- [ ] Manual testing: browse, search, play radio stations

## Estimated Effort

**Complexity:** Low - following established patterns, backend already complete

**Lines of Code:**
- New: ~100 lines (RadiosListView)
- Modified: ~50 lines (ViewModel, BrowseView, Service)

**Time Estimate:** 2-3 hours including tests

## Trade-offs

**Why List View (Not Grid):**
- Consistent with playlists and tracks categories
- Radio stations often lack rich artwork
- Simpler implementation
- Easier to scan station names

**Alternative Considered:**
- Grid view like albums - rejected because many stations don't have artwork, would look sparse

## Notes

- Genres category remains "Coming Soon" (next to implement after radio)
- Radio model already includes provider field (e.g., "TuneIn", "Radio Browser")
- LibraryService already supports sort/filter for radios (inherited from base implementation)
