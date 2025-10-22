# StreamingPlayer API Analysis

**Date:** 2025-10-22
**Task:** Task 2 - Reconnaissance of StreamingPlayer class in MusicAssistantKit
**Source:** `/Users/harper/Public/src/personal/ma-frontend/ma/.worktrees/local-playback/.build/checkouts/MusicAssistantKit/Sources/MusicAssistantKit/Player/StreamingPlayer.swift`

## Overview

StreamingPlayer is an actor-based class that provides AVFoundation-based audio playback integrated with Music Assistant server. It registers as a "built-in player" and receives playback commands via events.

## Availability

```swift
@available(macOS 12.0, iOS 15.0, *)
public actor StreamingPlayer
```

## Initializer Signature

```swift
public init(client: MusicAssistantClient, playerName: String)
```

**Parameters:**
- `client: MusicAssistantClient` - The Music Assistant client instance for server communication
- `playerName: String` - Human-readable name for this player (shows in MA UI)

## Registration & Lifecycle

### Register with Server

```swift
public func register() async throws
```

**What it does:**
1. Calls `client.registerBuiltinPlayer(playerName:playerId:)` to register with server
2. Extracts and stores `player_id` from the response
3. Subscribes to built-in player events via `client.events.builtinPlayerEvents`
4. Sends initial state update immediately
5. Starts periodic state updates (every 30 seconds)

**Throws:** `MusicAssistantError.invalidResponse` if server doesn't return a valid player_id

### Unregister from Server

```swift
public func unregister() async throws
```

**What it does:**
1. Stops periodic state updates
2. Stops any active playback
3. Unregisters from server via `client.unregisterBuiltinPlayer(playerId:)`
4. Clears player ID

## Available Methods

### Public Methods

#### Get Current Player ID
```swift
public nonisolated var currentPlayerId: String? { get async }
```

Returns the player ID assigned by the server after registration (nil if not registered).

### Private Methods (Internal Implementation)

The following methods are **private** and called automatically via event handling:

- `playMedia(urlPath: String)` - Loads and plays audio from server URL
- `play()` - Resumes playback
- `pause()` - Pauses playback
- `stop()` - Stops and clears playback
- `setVolume(_ volume: Double)` - Sets volume (0-100)
- `setMuted(_ muted: Bool)` - Mutes/unmutes audio
- `setPower(_ powered: Bool)` - Powers player on/off

**Important:** These methods are NOT directly callable. They are triggered by server events.

## Event-Driven Control

StreamingPlayer operates on an **event-driven model**:

1. Server sends events via WebSocket to `client.events.builtinPlayerEvents`
2. StreamingPlayer subscribes to this Combine publisher
3. Events arrive as tuples: `(playerId: String, event: BuiltinPlayerEvent)`
4. StreamingPlayer filters for its own player ID and handles events

### Supported Events

From `BuiltinPlayerEventType`:

| Event Type | Payload | Action |
|------------|---------|--------|
| `PLAY_MEDIA` | `mediaUrl: String` | Load and play audio from URL |
| `PLAY` | - | Resume playback |
| `PAUSE` | - | Pause playback |
| `STOP` | - | Stop and clear |
| `SET_VOLUME` | `volume: Double` | Set volume (0-100) |
| `MUTE` | - | Mute audio |
| `UNMUTE` | - | Unmute audio |
| `POWER_ON` | - | Power on player |
| `POWER_OFF` | - | Power off and stop |
| `TIMEOUT` | - | Server detected timeout (re-register if needed) |

## State Management

### State Properties (Private)

```swift
private var powered: Bool = false
private var volume: Double = 50.0
private var muted: Bool = false
private var currentPosition: Double = 0.0
```

### State Updates to Server

StreamingPlayer sends state updates via `BuiltinPlayerState`:

```swift
public struct BuiltinPlayerState: Codable, Sendable {
    public let powered: Bool
    public let playing: Bool
    public let paused: Bool
    public let position: Double    // Position in seconds
    public let volume: Double      // Volume level 0-100
    public let muted: Bool
}
```

**When state is sent:**
- Immediately after registration
- After any state change (play, pause, volume change, etc.)
- Periodically every 30 seconds while registered

**How it's sent:**
```swift
client.updateBuiltinPlayerState(playerId: playerId, state: state)
```

## Audio Implementation Details

### AVFoundation Usage

- Uses `AVPlayer` for audio playback
- Uses `AVPlayerItem` for loading media
- Uses `CMTime` for position tracking
- Observes `AVPlayerItem.status` for debugging playback issues

### Audio Session Configuration

**macOS:** No audio session configuration needed (AVPlayer uses default output)

**iOS:** Configures `AVAudioSession` with:
- Category: `.playback`
- Mode: `.default`
- Activates session

### Time Observation

Adds periodic time observer (every 1 second) to track playback position:
```swift
player.addPeriodicTimeObserver(
    forInterval: CMTime(seconds: 1.0, preferredTimescale: 1),
    queue: .main
)
```

### URL Construction

Media URLs are relative paths from the server. StreamingPlayer constructs full URLs:

```swift
let baseURL = URL(string: "http://\(client.host):\(client.port)")
let streamURL = baseURL.appendingPathComponent(urlPath)
```

Example: If server is `localhost:8095` and event sends `mediaUrl: "/stream/abc123.mp3"`, final URL is `http://localhost:8095/stream/abc123.mp3`

## Threading Model

StreamingPlayer is an **actor** which provides:
- Thread-safe state management
- Sequential access to mutable properties
- Safe async/await patterns

### Nonisolated Methods

Two methods are marked `nonisolated` to allow calling from any context:
1. `configureAudioSession()` - Accesses only `AVAudioSession.sharedInstance()`
2. `getBaseURL()` - Accesses only client properties asynchronously
3. `currentPlayerId` getter - Uses async getter to access actor state

## Example Usage Pattern

From `MAPlayer/main.swift`:

```swift
// Create client
let client = MusicAssistantClient(host: "localhost", port: 8095)
try await client.connect()

// Create player
let player = StreamingPlayer(client: client, playerName: "My Player")

// Register (this makes it available in MA UI)
try await player.register()

// Get assigned ID
if let playerId = await player.currentPlayerId {
    print("Registered as: \(playerId)")
}

// Keep running to receive events...
// (Control happens via MA UI, not directly)

// Cleanup when done
try? await player.unregister()
await client.disconnect()
```

## Integration Requirements

To integrate StreamingPlayer into an application:

1. **Create MusicAssistantClient** with server host/port
2. **Connect client** via `client.connect()`
3. **Create StreamingPlayer** with client and player name
4. **Register player** via `player.register()`
5. **Keep application running** to receive and handle events
6. **Unregister on shutdown** via `player.unregister()`

## Important Considerations

### No Direct Playback Control

**You cannot directly call play/pause/stop methods.** All control happens via:
1. Music Assistant server UI sends commands
2. Server emits events
3. StreamingPlayer receives and handles events

This is by design - it's a "remote-controlled" player model.

### Periodic State Updates

Every 30 seconds, StreamingPlayer sends its current state to the server. If too many updates are missed, the server may mark the player as offline and send a `TIMEOUT` event.

### Error Handling

State update errors are silently ignored to avoid console spam. The server handles player health tracking based on successful state updates.

### Player Item Status Observation

The implementation includes a Task-based observer for `AVPlayerItem.status` that logs:
- ✓ Ready to play
- ❌ Failed (with error)
- ⏳ Unknown status

This helps debug streaming issues during development.

## Surprises & Important Details

1. **Actor Isolation:** StreamingPlayer is an actor, so all state access is async and sequential. This prevents race conditions but requires careful async/await usage.

2. **Event Filtering:** Events arrive for ALL registered built-in players, so StreamingPlayer filters by `playerId` before handling.

3. **No Seek Method:** There's no public or private seek method in StreamingPlayer. Seeking might be controlled via queue commands to the server.

4. **Volume Range:** Volume is 0-100 (percentage), not 0.0-1.0. StreamingPlayer converts to AVPlayer's 0.0-1.0 range internally.

5. **Player ID Persistence:** The `playerId` parameter in `register()` is optional, allowing re-registration with the same ID. Current implementation doesn't persist IDs across app restarts.

6. **Combine Publisher:** Events use Combine's `PassthroughSubject`, stored in `Set<AnyCancellable>`. All Combine operations are dispatched to MainActor to avoid actor isolation crashes.

7. **Timeout Task Management:** Each state update has a 30-second timeout tracked via stored Tasks that are cancelled on success/failure.

8. **AVPlayer Lifecycle:** AVPlayer instance is created on first `playMedia` call and reused. It's only destroyed on `stopPlayback()` or `unregister()`.

## Questions for Implementation

1. **Persistence:** Should we persist player ID between app launches?
2. **Multiple Players:** Can one app register multiple StreamingPlayers with different names?
3. **Background Playback:** Does iOS require additional capabilities for background audio?
4. **Error Recovery:** How should we handle repeated registration failures?
5. **State Synchronization:** What if local state diverges from server state?

## Next Steps

Task 3 will involve creating an IntentService class that wraps StreamingPlayer and coordinates between:
- User intents (AppIntent actions)
- StreamingPlayer lifecycle
- PlayerService state management
- Error handling and user feedback
