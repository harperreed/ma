# Local Playback Migration Design
**Date:** 2025-10-22
**Status:** Approved
**Author:** code_crusader & Doctor Biz

## Overview

Migrate Music Assistant Player from remote player control to local audio playback using MusicAssistantKit 0.2.1's new StreamingPlayer capabilities.

## Goals

- Replace remote player control with local audio playback on this Mac
- Continue using Music Assistant server for library browsing and queue management
- Register this Mac as a player in the Music Assistant ecosystem
- Maintain existing UI/UX - users shouldn't need to relearn the app

## Non-Goals

- Supporting remote player control (removing this capability entirely)
- Building standalone player without server connection
- Creating new UI for player management

## Requirements

### Functional Requirements
- App must stream audio directly from Music Assistant server to Mac speakers via AVFoundation
- Local player must appear in server's player list alongside other players
- All playback controls (play/pause/stop/seek/volume) must work with local playback
- Queue management continues to work through server
- Metadata and library browsing continue to work through server

### Technical Requirements
- Upgrade MusicAssistantKit from 0.0.4 to 0.2.1
- Integrate StreamingPlayer with existing PlayerService architecture
- Maintain test coverage throughout migration
- Follow TDD approach per project standards

## Architecture

### Selected Approach: In-Place Refactor

Refactor existing PlayerService to use StreamingPlayer internally instead of sending remote commands. This maintains current architecture while changing implementation.

**Why this approach:**
- Medium complexity - not trivial but manageable
- Preserves existing public API - UI code unchanged
- Clear migration path
- Lower risk than full rewrite

**Alternatives considered:**
1. New LocalPlayerService + abstract interface - Too much complexity for requirements
2. Minimal wrapper - Creates technical debt

### Component Changes

#### Package.swift
- Update dependency: `MusicAssistantKit` from `0.0.4` to `0.2.1`
- No additional dependencies needed (AVFoundation is macOS SDK)

#### MusicAssistantPlayerApp
**Current state:** Creates `MusicAssistantClient`, connects to server

**New responsibilities:**
1. Create `StreamingPlayer` instance
2. Register local player with Music Assistant server after connection
3. Pass both client and streaming player to PlayerService

**Connection flow:**
```
Connect to server → Create StreamingPlayer → Register as player → Initialize PlayerService
```

#### PlayerService
**Current architecture:**
- Holds `MusicAssistantClient`
- Sends remote commands via client
- Subscribes to server events for player state
- Maintains atomic `PlayerState` struct
- Publishes state via `@Published` properties

**Refactored architecture:**
- Add `StreamingPlayer` property
- Keep `MusicAssistantClient` for library/queue/metadata operations
- Route playback commands (`play`, `pause`, `stop`, `seek`, `setVolume`) to `StreamingPlayer`
- Subscribe to `StreamingPlayer` publishers for local state updates
- Remove remote player event subscription
- Keep atomic `PlayerState` and `@Published` properties unchanged
- Maintain `selectedPlayer` - when it's "this Mac", use local StreamingPlayer

**Event subscription changes:**
- **Before:** Subscribe to server events for remote player state
- **After:** Subscribe to StreamingPlayer publishers for local playback state
- Keep same state update logic - different source

**Progress tracking changes:**
- **Before:** Custom `startLocalProgressTracking()` task estimates progress
- **After:** Subscribe to StreamingPlayer's AVFoundation progress updates
- Remove custom progress estimation task

#### QueueService
**No changes needed** - continues using `MusicAssistantClient` for queue operations

## Data Flow

### Playback Command Flow
```
User clicks play button
  ↓
UI calls PlayerService.play()
  ↓
PlayerService.streamingPlayer.play()
  ↓
AVFoundation streams from http://host:port/builtin_player/flow/{player_id}.mp3
  ↓
StreamingPlayer publishes state update
  ↓
PlayerService updates state
  ↓
UI reflects changes via @Published
```

### State Updates - Two Sources

**1. Local Playback State** (from StreamingPlayer - authoritative)
- Playback state (playing/paused/stopped)
- Current progress
- Volume level

**2. Server Metadata** (from MusicAssistantClient - authoritative)
- Current track information
- Queue changes
- Favorite status
- Shuffle/repeat modes

These merge in PlayerService's atomic `PlayerState` struct.

## Error Handling

### Connection Lifecycle
Two connection points requiring coordination:
1. **Server connection**: `MusicAssistantClient.connect()` (existing)
2. **Player registration**: Register `StreamingPlayer` with server (new)

### Error Scenarios

| Scenario | Handling |
|----------|----------|
| Server unreachable | Show ServerSetupView (existing behavior) |
| Player registration fails | Update `connectionState` to `.error("Failed to register player")`, show in UI |
| Audio stream unreachable | Update `lastError`, display error state in UI |
| AVFoundation playback error | Subscribe to StreamingPlayer error events, update `lastError` |
| Network interruption during playback | StreamingPlayer handles reconnection, we surface status via `connectionState` |

### Connection State
Extend existing `connectionState` enum:
- `.connecting` - connecting to server
- `.connected` - server connected AND player registered successfully
- `.error(String)` - server connection or player registration failed

Enhance `connectionMonitorTask` to verify both connections.

### Cleanup
Update `deinit`:
- Cancel existing tasks (already done)
- **Add:** Unregister player from server
- **Add:** Stop active audio playback

## Testing Strategy

### Unit Tests to Update

**PlayerServiceTests.swift:**
- Mock StreamingPlayer in addition to/instead of MusicAssistantClient
- Test playback command routing to StreamingPlayer
- Verify state updates from StreamingPlayer publishers
- Keep existing state management tests (should pass unchanged)

**EventParserTests.swift:**
- Minimal changes - still parsing server events for metadata
- Add tests if StreamingPlayer state format differs

### New Test Coverage

- Player registration flow (connect → register → ready)
- StreamingPlayer initialization failure handling
- State synchronization between StreamingPlayer and PlayerService
- Audio streaming failure mid-playback
- Fallback behavior for various error conditions

### Integration Testing

Manual test checklist:
- [ ] Connect to Music Assistant server
- [ ] Verify "this Mac" appears in player list
- [ ] Select local player from list
- [ ] Start playback - verify audio plays through speakers
- [ ] Test play/pause/stop controls
- [ ] Test seek functionality
- [ ] Test volume control
- [ ] Verify queue advancement (auto-play next track)
- [ ] Test shuffle/repeat modes
- [ ] Disconnect network, verify reconnection behavior

### TDD Approach
Per project requirements, write failing tests before implementing each change.

## Migration Steps

### Stage 1: Infrastructure
1. Write tests for StreamingPlayer initialization
2. Update Package.swift to MusicAssistantKit 0.2.1
3. Resolve package dependencies
4. Add StreamingPlayer to app initialization
5. Implement player registration with server
6. Verify tests pass

### Stage 2: PlayerService Refactor
1. Write tests for playback command routing
2. Add StreamingPlayer property to PlayerService
3. Update `play()`, `pause()`, `stop()`, `seek()`, `setVolume()` to use StreamingPlayer
4. Verify tests pass

### Stage 3: Event Subscription
1. Write tests for local state updates
2. Replace remote player event subscription with StreamingPlayer publishers
3. Remove custom progress tracking task
4. Verify tests pass

### Stage 4: Cleanup
1. Remove unused remote player control code
2. Update error handling for new failure modes
3. Remove dead code paths
4. Run full test suite
5. Manual integration testing

## Verification Criteria

Before claiming completion (per verification-before-completion requirements):
- [ ] All unit tests pass
- [ ] All integration tests pass (manual checklist above)
- [ ] No compilation warnings
- [ ] Pre-commit hooks pass
- [ ] Audio actually plays through Mac speakers
- [ ] All playback controls functional

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| StreamingPlayer API differs from docs | High | Review actual SDK code early, adjust design if needed |
| Breaking changes in 0.2.1 | Medium | Thorough testing at each stage, rollback possible |
| AVFoundation audio session conflicts | Medium | Proper audio session configuration, test with other audio apps |
| Performance issues with streaming | Low | Monitor performance, optimize if needed |

## Future Considerations

Not in scope for this migration, but noting for future:
- Could add option to switch between local and remote playback modes
- Could support multiple local players (if useful)
- Could add audio effects/EQ via AVFoundation
- Could support offline playback caching

## References

- MusicAssistantKit 0.2.1 documentation
- Current PlayerService implementation: `Sources/MusicAssistantPlayer/Services/PlayerService.swift`
- Current app initialization: `Sources/MusicAssistantPlayer/MusicAssistantPlayerApp.swift`
