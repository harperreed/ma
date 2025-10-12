# Music Assistant Player

A native macOS client for Music Assistant with a Roon-inspired interface.

## Features

- Native SwiftUI interface
- Three-column layout (Sidebar, Queue, Now Playing)
- Player discovery and management
- Queue management
- Transport controls
- Real-time playback information

## Installation

### From DMG

1. Download `MusicAssistantPlayer-0.1.0.dmg`
2. Open the DMG file
3. Drag Music Assistant Player to Applications folder
4. Launch from Applications
5. On first run, right-click the app and select "Open" (unsigned app warning)

### From Source

```bash
git clone [repo-url]
cd ma
swift run
```

## Building

See [BUILDING.md](BUILDING.md) for detailed build instructions.

## Usage

1. Launch Music Assistant Player
2. Enter your Music Assistant server URL
3. Select a player from the sidebar
4. Browse and control playback

## Requirements

- macOS 14.0 or later
- Music Assistant server (running locally or remotely)

## Development

This project uses Swift Package Manager for dependency management and Xcode for building the macOS app bundle.

## License

Copyright © 2025 Harper Reed. All rights reserved.
