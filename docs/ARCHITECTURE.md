# Music Assistant Player - Architecture Documentation

This document provides an overview of the Music Assistant Player architecture, including the comprehensive architecture diagram.

## Architecture Diagram

The complete system architecture is visualized in `architecture.dot` (GraphViz format).

**View the diagram:**
- PNG: `architecture.png` (691KB, high resolution)
- SVG: `architecture.svg` (85KB, scalable vector)

**Regenerate diagram:**
```bash
cd docs
dot -Tpng architecture.dot -o architecture.png
dot -Tsvg architecture.dot -o architecture.svg
```

## Architecture Overview

### Design Pattern: MVVM (Model-View-ViewModel)

Music Assistant Player uses the MVVM pattern with SwiftUI:

- **Views (SwiftUI)**: Declarative UI components
- **ViewModels**: Observable objects managing UI state
- **Services**: Business logic and data management
- **Models**: Domain entities and data structures

### Key Architectural Layers

#### 1. Application Entry
- `MusicAssistantPlayerApp`: Main app entry point (@main)
- `ServerSetupView`: Initial server configuration flow

#### 2. macOS Integration Layer
**Now Playing Center:**
- `PlayerService+NowPlaying`: Extension providing media key support
- Integrates with `MPRemoteCommandCenter` for hardware media keys
- Updates `MPNowPlayingInfoCenter` for Control Center display

**App Intents (Siri/Shortcuts):**
- `PlayerIntents`: Five playback control intents (Play, Pause, Stop, Next, Previous)
- `IntentHelper`: Singleton bridge connecting intents to PlayerService
- `AppShortcutsProvider`: Registers Siri voice command phrases

#### 3. Services Layer (Business Logic)
- **PlayerService** (@MainActor): Core playback state management
  - Publishes: `currentTrack`, `playbackState`, `progress`, `volume`, `selectedPlayer`
  - Methods: `play()`, `pause()`, `stop()`, `skipNext()`, `skipPrevious()`, `seek()`, `setVolume()`
  - Uses Combine for reactive state updates

- **QueueService**: Queue management and operations

- **LibraryService**: Media library browsing (artists, albums, tracks, playlists, radio)
  - Caches metadata via `LibraryCache`

- **ImageCacheService**: Artwork caching with memory/disk persistence

- **EventParser**: Parses WebSocket events from Music Assistant server

#### 4. ViewModels (Presentation Logic)
- **NowPlayingViewModel**: Now Playing UI state (@ObservableObject)
- **QueueViewModel**: Queue UI state
- **LibraryViewModel**: Library browsing state

#### 5. Views (UI Components)

**Main Windows:**
- `MainWindowView`: Standard layout
- `RoonStyleMainWindowView`: Three-column Roon-inspired layout

**View Components:**
- `NowPlayingView`: Full playback display
- `QueueView`: Queue management UI
- `LibraryBrowseView`: Library browsing (artists, albums, tracks)
- `SidebarView`: Player selection sidebar
- `MiniPlayerBar`: Compact playback controls
- `PlayerControlsView`: Transport controls
- `AlbumArtView`: Artwork display
- `VolumeControl`: Volume slider
- `SeekableProgressBar`: Playback progress with seek
- `ErrorBanner`: Error display

#### 6. Models (Domain Entities)
- **Track**: `id`, `title`, `artist`, `album`, `duration`, `artworkURL`
- **Player**: `id`, `name`, `state`, `volume`
- **Album**, **Artist**, **Playlist**, **Radio**, **Genre**: Library entities
- **PlaybackState**: Enum (playing, paused, stopped)
- **ConnectionState**: Enum (connected, disconnected, error)
- **ServerConfig**: Server connection settings

#### 7. Error Handling
- **PlayerError**: Player-specific errors
- **QueueError**: Queue operation errors
- **LibraryError**: Library fetching errors

#### 8. Utilities
- **AppLogger**: Category-based logging (network, player, ui, cache, errors, intents)
- **ColorExtractor**: Extract dominant colors from artwork
- **NetworkValidator**: URL/server validation
- **BlurredArtworkBackground**: Visual effects

#### 9. External Dependencies
- **MusicAssistantKit**: WebSocket client for Music Assistant server
- **MediaPlayer.framework**: MPRemoteCommandCenter, MPNowPlayingInfoCenter
- **AppIntents.framework**: Siri and Shortcuts integration

## Data Flow

### Primary Data Flow
```
Music Assistant Server (WebSocket)
  ↓
MusicAssistantClient
  ↓
EventParser
  ↓
Services (PlayerService, QueueService, LibraryService)
  ↓ (Combine Publishers)
ViewModels (Observe & Transform)
  ↓ (@ObservedObject binding)
Views (SwiftUI)
```

### macOS Integration Flow

**Now Playing:**
```
PlayerService state changes
  → PlayerService+NowPlaying observes via Combine
  → Updates MPNowPlayingInfoCenter
  → Displays in Control Center

Hardware media keys
  → MPRemoteCommandCenter
  → PlayerService+NowPlaying handlers
  → PlayerService methods (play/pause/next/previous)
```

**App Intents:**
```
User: "Hey Siri, play music"
  → AppIntents invoked
  → IntentHelper.shared.playerService
  → PlayerService.play()
  → Updates propagate to UI
```

## Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Reactive Framework**: Combine
- **Dependency Management**: Swift Package Manager
- **Networking**: WebSocket (via MusicAssistantKit)
- **Platform**: macOS 14.0+
- **Architecture Pattern**: MVVM
- **Testing**: XCTest

## Key Design Decisions

### 1. MVVM with Combine
- Clean separation between UI and business logic
- Reactive data flow using Combine publishers
- ViewModels observe Services, Views observe ViewModels

### 2. Service Layer Pattern
- Services encapsulate business logic and external communication
- @MainActor ensures thread safety for UI-related state
- Services are shared across ViewModels via dependency injection

### 3. Extension-Based Integration
- macOS integrations (Now Playing, App Intents) added via extensions
- Keeps core PlayerService focused on playback logic
- Easy to add/remove platform features

### 4. Bridge Pattern for App Intents
- IntentHelper singleton bridges App Intents (different process) to PlayerService
- Weak reference prevents retain cycles
- Graceful degradation when PlayerService unavailable

### 5. Caching Strategy
- Image cache for artwork (memory + disk)
- Library metadata cache to reduce server requests
- Cache invalidation on reconnect

### 6. Error Handling
- Domain-specific error types (PlayerError, QueueError, LibraryError)
- Errors propagate through ViewModels to ErrorBanner
- Logging via AppLogger for debugging

## Testing

The project includes comprehensive tests:

- **Model Tests**: Track, Player, Album, Artist, Playlist, etc.
- **Service Tests**: PlayerService, QueueService, LibraryService, ImageCacheService
- **ViewModel Tests**: NowPlayingViewModel, QueueViewModel, LibraryViewModel
- **Utility Tests**: ColorExtractor, NetworkValidator

## Future Architecture Considerations

1. **Desktop Widgets**: Requires Widget Extension target + App Groups
2. **User Notifications**: Track change notifications with user preferences
3. **Album Artwork in Now Playing**: Requires image fetching from server
4. **Seek Position Control**: Additional Now Playing integration
5. **Multi-window Support**: Separate windows for queue, library
6. **Keyboard Shortcuts**: System-wide hotkeys beyond media keys

## Diagram Legend

**Colors:**
- Blue: Application/Windows layer
- Purple: macOS Integration
- Green: Services layer
- Orange: ViewModels layer
- Light Blue: Views/UI layer
- Pink: Models/Domain entities
- Red: Error types
- Gray: Utilities
- Dark Gray: External dependencies

**Edge Styles:**
- Solid: Direct dependency
- Dashed: Weak/indirect dependency
- Dotted: Reactive observation (Combine)

**Node Shapes:**
- Box (rounded): Standard components
- Ellipse: State/enum types
- Component: External frameworks
- Double octagon: External systems (Siri)

---

*For implementation details, see source code in `Sources/MusicAssistantPlayer/`*
*For build instructions, see `BUILDING.md`*
*For code signing details, see `docs/CODE_SIGNING.md`*
