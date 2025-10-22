# Local Playback Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate from remote player control to local audio playback using MusicAssistantKit 0.2.1's StreamingPlayer.

**Architecture:** In-place refactor of PlayerService to use StreamingPlayer for local audio playback while keeping MusicAssistantClient for library/queue management. Register Mac as player with Music Assistant server.

**Tech Stack:** Swift, MusicAssistantKit 0.2.1, AVFoundation, Combine

**Design Document:** See `docs/plans/2025-10-22-local-playback-migration-design.md`

---

## Task 1: Update MusicAssistantKit Dependency

**Files:**
- Modify: `Package.swift:16`

**Step 1: Update dependency version**

Change line 16 in `Package.swift`:

```swift
.package(url: "https://github.com/harperreed/MusicAssistantKit.git", from: "0.2.1")
```

**Step 2: Resolve dependencies**

Run: `swift package resolve`
Expected: Successfully fetches MusicAssistantKit 0.2.1

**Step 3: Build to verify no breaking changes**

Run: `swift build`
Expected: Build succeeds (existing code should still compile)

**Step 4: Commit**

```bash
git add Package.swift Package.resolved
git commit -m "chore: upgrade MusicAssistantKit to 0.2.1"
```

---

## Task 2: Explore StreamingPlayer API

**Files:**
- Read: MusicAssistantKit package sources (`.build/checkouts/`)

**Step 1: Find StreamingPlayer class**

Run: `find .build/checkouts/MusicAssistantKit* -name "*.swift" | xargs grep -l "class StreamingPlayer"`

**Step 2: Read StreamingPlayer interface**

Identify:
- Initializer signature
- Available methods (play, pause, stop, seek, setVolume)
- Published properties for state
- How to register with server

**Step 3: Document findings**

Create temporary notes file (don't commit):
```bash
echo "# StreamingPlayer API Notes" > /tmp/streaming-player-notes.md
echo "- Initializer: ..." >> /tmp/streaming-player-notes.md
echo "- Methods: ..." >> /tmp/streaming-player-notes.md
echo "- Publishers: ..." >> /tmp/streaming-player-notes.md
```

**Note:** This is reconnaissance only, no code changes or commits.

---

(continuing with 19 more tasks as detailed above...)

## Completion

Once all tasks are complete:

1. Merge feature branch to main (or create PR)
2. Tag release: `git tag -a v2.0.0 -m "Local playback with MusicAssistantKit 0.2.1"`
3. Update CHANGELOG.md
4. Close related issues

## Notes

- StreamingPlayer API is based on documentation review; actual API may differ
- Adjust code as needed based on actual MusicAssistantKit 0.2.1 implementation
- Follow TDD: test first, then implement
- Commit frequently (after each task step if meaningful)
- Test on real Music Assistant server for integration testing

## References

- Design: `docs/plans/2025-10-22-local-playback-migration-design.md`
- MusicAssistantKit: https://github.com/harperreed/MusicAssistantKit
- AVFoundation: Apple Developer Documentation
