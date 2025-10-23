# Manual Integration Test Guide - StreamingPlayer

**Branch:** feature/local-playback-migration
**Date:** 2025-10-22
**Tester:** Doctor Biz

## Pre-Test Setup

### Requirements
- [ ] Music Assistant server running and accessible
- [ ] Server host and port known (e.g., localhost:8095)
- [ ] At least one track in the Music Assistant library

### Build Location
```
/Users/harper/Public/src/personal/ma-frontend/ma/.worktrees/local-playback/.build/debug/MusicAssistantPlayer.app
```

---

## Test 1: Application Launch

**Objective:** Verify the app launches successfully with new StreamingPlayer code.

**Steps:**
1. Open the app:
   ```bash
   open .build/debug/MusicAssistantPlayer.app
   ```
2. Observe the startup

**Expected Results:**
- ✅ App launches without crashes
- ✅ ServerSetupView appears (if not previously configured)
- ✅ No error dialogs appear

**Actual Results:**
- [ ] Pass / [ ] Fail
- Notes: ___________

---

## Test 2: Server Connection & StreamingPlayer Registration

**Objective:** Verify app connects to Music Assistant server AND StreamingPlayer registers successfully.

**Steps:**
1. Enter your Music Assistant server details:
   - Host: `____________`
   - Port: `____________`
2. Click connect/submit
3. Watch the console logs for:
   ```
   Successfully connected to Music Assistant server at [host]:[port]
   Successfully registered StreamingPlayer with server
   ```

**Expected Results:**
- ✅ Connection succeeds
- ✅ Log shows "Successfully registered StreamingPlayer with server"
- ✅ Main window appears
- ✅ Library loads

**Critical Check:** On the Music Assistant server side, verify "This Mac" appears in the players list.

**Actual Results:**
- [ ] Pass / [ ] Fail
- Connection time: ___________
- StreamingPlayer registered: [ ] Yes / [ ] No
- Notes: ___________

---

## Test 3: Player Selection & Verification

**Objective:** Verify the StreamingPlayer appears as a selectable player.

**Steps:**
1. In the app, find the player selection UI
2. Look for "This Mac" in the player list
3. Select "This Mac" as the active player

**Expected Results:**
- ✅ "This Mac" appears in player list
- ✅ Can select "This Mac" as active player
- ✅ Player shows as online/available

**Actual Results:**
- [ ] Pass / [ ] Fail
- Player name shown: ___________
- Notes: ___________

---

## Test 4: Audio Playback

**Objective:** Verify audio actually plays through the Mac's speakers via StreamingPlayer.

**Steps:**
1. Browse to a track in the library
2. Click Play
3. Listen for audio output from Mac speakers
4. Check volume is audible

**Expected Results:**
- ✅ Audio plays through Mac speakers
- ✅ Progress bar advances
- ✅ Current track displays correctly
- ✅ No audio glitches or stuttering

**Actual Results:**
- [ ] Pass / [ ] Fail
- Audio quality: ___________
- Latency (from click to audio): ___________
- Notes: ___________

---

## Test 5: Playback Controls

**Objective:** Verify all playback controls work with StreamingPlayer.

### 5a: Pause
**Steps:**
1. While playing, click Pause
2. Verify audio stops

**Results:** [ ] Pass / [ ] Fail

### 5b: Resume (Play after Pause)
**Steps:**
1. After pausing, click Play
2. Verify audio resumes from same position

**Results:** [ ] Pass / [ ] Fail

### 5c: Stop
**Steps:**
1. While playing, click Stop
2. Verify audio stops and progress resets

**Results:** [ ] Pass / [ ] Fail

### 5d: Seek
**Steps:**
1. While playing, drag progress slider to different position
2. Verify audio jumps to new position
3. Verify playback continues from new position

**Results:** [ ] Pass / [ ] Fail
- Seek accuracy: ___________

### 5e: Volume Control
**Steps:**
1. While playing, adjust volume slider
2. Verify audio volume changes
3. Test at multiple volume levels (0%, 50%, 100%)

**Results:** [ ] Pass / [ ] Fail
- Volume response: ___________

### 5f: Next Track
**Steps:**
1. Add multiple tracks to queue
2. Click Next
3. Verify next track plays

**Results:** [ ] Pass / [ ] Fail

### 5g: Previous Track
**Steps:**
1. After playing for a few seconds, click Previous
2. Verify track restarts or previous track plays

**Results:** [ ] Pass / [ ] Fail

---

## Test 6: Queue Management

**Objective:** Verify queue operations work with StreamingPlayer.

**Steps:**
1. Add multiple tracks to queue
2. Verify queue displays correctly
3. Let current track finish
4. Verify next track auto-plays

**Expected Results:**
- ✅ Queue displays all tracks
- ✅ Current track indicator updates
- ✅ Auto-advance to next track works
- ✅ Queue order respected

**Actual Results:**
- [ ] Pass / [ ] Fail
- Notes: ___________

---

## Test 7: Shuffle & Repeat

**Objective:** Verify shuffle and repeat modes work.

### 7a: Shuffle
**Steps:**
1. Enable shuffle mode
2. Play through multiple tracks
3. Verify tracks play in random order

**Results:** [ ] Pass / [ ] Fail

### 7b: Repeat All
**Steps:**
1. Enable repeat all mode
2. Let queue play to end
3. Verify playback restarts from beginning

**Results:** [ ] Pass / [ ] Fail

### 7c: Repeat One
**Steps:**
1. Enable repeat one mode
2. Let track finish
3. Verify same track replays

**Results:** [ ] Pass / [ ] Fail

---

## Test 8: Error Handling

**Objective:** Verify graceful error handling.

### 8a: Network Interruption
**Steps:**
1. Start playback
2. Disconnect network (turn off WiFi)
3. Observe behavior
4. Reconnect network
5. Observe recovery

**Expected Results:**
- ✅ App shows connection error
- ✅ Audio stops gracefully (no crash)
- ✅ Reconnects automatically when network returns
- ✅ Playback can resume

**Results:** [ ] Pass / [ ] Fail

### 8b: Server Restart
**Steps:**
1. Start playback
2. Restart Music Assistant server
3. Observe behavior
4. Verify reconnection

**Results:** [ ] Pass / [ ] Fail

---

## Test 9: State Persistence

**Objective:** Verify app remembers state across restarts.

**Steps:**
1. Connect to server and start playback
2. Quit app (Cmd+Q)
3. Relaunch app
4. Verify server config remembered
5. Verify reconnects automatically

**Expected Results:**
- ✅ Server config persisted
- ✅ Auto-reconnects on launch
- ✅ StreamingPlayer re-registers
- ✅ Previous player selection restored

**Results:** [ ] Pass / [ ] Fail

---

## Test 10: Console Log Analysis

**Objective:** Verify no errors or warnings in console logs.

**Steps:**
1. Open Console.app
2. Filter for "MusicAssistantPlayer"
3. Review logs during testing session

**Look for:**
- ❌ Error messages
- ⚠️ Warning messages
- ✅ Successful registration messages
- ✅ Clean event handling

**Actual Results:**
- Errors found: ___________
- Warnings found: ___________
- Notes: ___________

---

## Summary

### Overall Test Results

| Test | Status | Notes |
|------|--------|-------|
| 1. App Launch | [ ] Pass / [ ] Fail | |
| 2. Connection & Registration | [ ] Pass / [ ] Fail | |
| 3. Player Selection | [ ] Pass / [ ] Fail | |
| 4. Audio Playback | [ ] Pass / [ ] Fail | |
| 5. Playback Controls | [ ] Pass / [ ] Fail | |
| 6. Queue Management | [ ] Pass / [ ] Fail | |
| 7. Shuffle & Repeat | [ ] Pass / [ ] Fail | |
| 8. Error Handling | [ ] Pass / [ ] Fail | |
| 9. State Persistence | [ ] Pass / [ ] Fail | |
| 10. Console Logs | [ ] Pass / [ ] Fail | |

### Critical Issues Found
_List any blocking issues:_

1. ___________
2. ___________

### Non-Critical Issues Found
_List any minor issues:_

1. ___________
2. ___________

### Recommendations

**Ready for merge?** [ ] Yes / [ ] No

**Additional work needed:**
- ___________
- ___________

### Sign-off

**Tester:** Doctor Biz
**Date:** 2025-10-22
**Status:** [ ] Approved / [ ] Needs Work
**Signature:** ___________
