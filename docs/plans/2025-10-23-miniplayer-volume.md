# MiniPlayerBar Volume Control Design

**Date:** 2025-10-23
**Status:** Approved for Implementation
**Approach:** Add VolumeControl to MiniPlayerBar (Option 1)

## Overview

Add volume control to the MiniPlayerBar (bottom persistent bar in RoonStyleMainWindowView) to allow users to adjust volume without expanding to full now-playing view. All infrastructure already exists - this is purely a UI integration task.

## Requirements

- Display volume control in MiniPlayerBar
- Reuse existing VolumeControl component with debouncing
- Maintain responsive layout (hide volume on narrow windows)
- Wire to existing PlayerService.setVolume() method
- Consistent with existing volume control in PlayerControlsView

## Architecture

### Data Flow

```
User drags volume slider in MiniPlayerBar
    ↓
VolumeControl debounces (300ms) during drag
    ↓
onVolumeChange callback → NowPlayingViewModel.setVolume()
    ↓
PlayerService.setVolume() - optimistic update + API call
    ↓
Volume binding updates both MiniPlayerBar and NowPlayingView controls
```

### Existing Infrastructure (Already Implemented)

**VolumeControl component** (`Sources/MusicAssistantPlayer/Views/Components/VolumeControl.swift`):
- Accepts `@Binding var volume: Double` and `onVolumeChange: (Double) -> Void`
- Built-in 300ms debouncing during drag
- Speaker icons (muted and full volume)
- 64 lines, fully implemented

**PlayerService.setVolume()** (`Sources/MusicAssistantPlayer/Services/PlayerService.swift:480-503`):
- Optimistic UI updates for immediate feedback
- API call via `client.setVolume(playerId:volume:)`
- Error handling and logging

**NowPlayingViewModel** already exposes:
- `@Published var volume: Double` property
- `func setVolume(_ volume: Double)` method

## Components

### 1. MiniPlayerBar (Modify)

**File:** `Sources/MusicAssistantPlayer/Views/MiniPlayerBar.swift`

**Changes:**
1. Add VolumeControl to right section (after progress bar)
2. Add responsive width management for volume control
3. Hide volume control on narrow windows (< 900px width)

**Before** (current layout):
```
[Artwork + Track + Player Selector] [Spacer] [Transport Controls] [Spacer] [Progress Bar]
```

**After** (new layout):
```
[Artwork + Track + Player Selector] [Spacer] [Transport Controls] [Spacer] [Progress Bar] [Volume]
```

**Implementation details:**
- Add VolumeControl after SeekableProgressBar
- Constrain VolumeControl to 200px width
- Use GeometryReader to hide volume when window width < 900px
- Pass `volume: $nowPlayingViewModel.volume` binding
- Pass `onVolumeChange: { nowPlayingViewModel.setVolume($0) }` callback

### 2. RoonStyleMainWindowView (No changes needed)

MiniPlayerBar already receives `nowPlayingViewModel` with volume bindings (line 154).

## Responsive Layout Strategy

| Window Width | MiniPlayerBar Layout                          |
| ------------ | --------------------------------------------- |
| < 900px      | Hide volume control (prioritize track info)   |
| 900-1200px   | Show volume at 150px width                    |
| > 1200px     | Show volume at 200px width (full)             |

**Why hide on narrow windows?**
- MiniPlayerBar is already dense with controls
- Volume is still accessible in expanded NowPlayingView
- Prioritize track info and playback controls

## Implementation Checklist

- [ ] Wrap MiniPlayerBar body in GeometryReader for responsive width detection
- [ ] Add VolumeControl component after SeekableProgressBar
- [ ] Wire volume binding: `$nowPlayingViewModel.volume`
- [ ] Wire onVolumeChange callback: `{ nowPlayingViewModel.setVolume($0) }`
- [ ] Add responsive width constraints (150-200px based on window size)
- [ ] Add conditional display logic (hide when width < 900px)
- [ ] Manual testing: verify volume changes in both MiniPlayerBar and NowPlayingView
- [ ] Manual testing: verify responsive behavior at different window sizes
- [ ] Manual testing: verify debouncing works (no API spam during drag)
- [ ] Write unit tests for MiniPlayerBar volume integration

## Estimated Effort

**Complexity:** Low - reusing existing component, simple integration

**Lines of Code:**
- Modified: ~30 lines (MiniPlayerBar layout changes)
- New: 0 lines (all components exist)

**Time Estimate:** 1-2 hours including tests

## Trade-offs

**Why MiniPlayerBar (Not Duplicate in NowPlayingView):**
- MiniPlayerBar is the primary interaction point for quick controls
- NowPlayingView already has volume via PlayerControlsView
- Adding a second volume control in NowPlayingView would be redundant and confusing
- Matches UX patterns from Spotify, Apple Music, etc.

**Why Responsive Hiding:**
- MiniPlayerBar has limited space budget
- Volume is still accessible in expanded NowPlayingView
- Better to hide gracefully than squish controls

## Testing Strategy

### Manual Tests
- Launch app, play track from MiniPlayerBar
- Adjust volume slider in MiniPlayerBar → verify audio changes
- Expand to NowPlayingView → verify volume slider matches MiniPlayerBar position
- Adjust volume in NowPlayingView → verify MiniPlayerBar slider syncs
- Resize window below 900px → verify volume control hides
- Resize window above 900px → verify volume control appears
- Drag volume slider continuously → verify no API spam (debouncing works)

### Unit Tests
- MiniPlayerBar displays VolumeControl when width >= 900px
- MiniPlayerBar hides VolumeControl when width < 900px
- VolumeControl binding syncs with NowPlayingViewModel.volume
- onVolumeChange callback invokes NowPlayingViewModel.setVolume()

## Notes

- VolumeControl component already handles all edge cases (drag state, debouncing, icons)
- PlayerService.setVolume() already handles optimistic updates and errors
- No changes needed to data layer - purely UI integration
- Volume binding ensures both MiniPlayerBar and NowPlayingView stay in sync
