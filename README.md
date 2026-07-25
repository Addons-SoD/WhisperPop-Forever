# WhisperPop (Standalone)

A standalone whisper message manager addon extracted from the **BigFoot** addon pack. All dependencies on the BigFoot core have been removed so it can run independently.

Originally authored by **Abin**, with BigFoot integration by **Ever@178.com**.

## Features

- **Whisper History:** Records all incoming and outgoing whisper messages in a scrollable list, organized by player.
- **New Message Alert:** A flashing horn button appears next to the chat frame when unread whispers arrive, with an optional sound notification.
- **Player List:** Displays whisper contacts with class icons (including GM and Battle.net friend icons). Left-click to whisper, Shift-click to query player info, Alt-click to invite, Right-click for the player menu.
- **Message Viewer:** Pop-up message frame with scrollable chat history per player, with auto-hide behavior.
- **Options:** Toggle receive-only mode, sound notification, timestamps, help tips, and persistent message history (kept up to 9 days across characters on the same account).
- **Slash Command:** `/whisperpop` to toggle the main frame.

## Dependency Handling (How Standalone Works)

| Original Dependency | Solution |
| --- | --- |
| `## Dependencies: BigFoot` / `## LoadOnDemand: 1` | Removed from TOC; addon loads normally at startup |
| `WhisperPop_Toggle(switch)` (called by BigFoot to activate) | `enable.lua` calls `WhisperPop_Toggle(1)` at `PLAYER_LOGIN` when BigFoot is absent |
| `GetAddOnMetadata` (removed in Classic Era 1.15.x) | Replaced with `C_AddOns.GetAddOnMetadata` fallback |
| `FCF_UpdateButtonSide` (may not exist in Classic Era) | `hooksecurefunc` call guarded with nil check |
| `ChatFrame1ButtonFrameBottomButton` / `FriendsMicroButton` (may not exist in Classic Era) | Button positioning guarded with nil checks |
| `table.getn()` / `getn()` (deprecated Lua API) | Replaced with `#` length operator |

> All guards use `if not X then ... end` or nil checks: when BigFoot is still present, the original BigFoot behavior is preserved.

## Directory Structure

```
WhisperPop/
├─ WhisperPop.toc          # Removed Dependencies: BigFoot / LoadOnDemand
├─ enable.lua              # Standalone auto-enable at PLAYER_LOGIN (new)
├─ WhisperPop.lua          # Core addon table and utility functions
├─ MainFrame.lua           # Main frame, player list, event handling, button logic
├─ MessageFrame.lua        # Per-player message viewer frame
├─ OptionFrame.lua         # Option buttons, saved variables, slash command
├─ Localization.lua        # enUS / zhCN / zhTW locale strings
├─ VirtualScrollList-1.0.lua  # Virtual scroll list library (by Abin)
├─ WhisperPop.xml          # Horn button UI definition
├─ Notify.mp3              # New message sound alert
└─ Texture/                # Button and icon textures
```

## Installation

1. Close the game.
2. If you have the BigFoot version of WhisperPop, rename its folder (e.g. `WhisperPop_bigfoot`) to avoid conflicts.
3. Copy this entire `WhisperPop` directory into `Interface\AddOns\`.
4. Launch the game and confirm **WhisperPop** is checked in the addon list.
5. A horn button will appear near the chat frame. Incoming whispers are recorded automatically.

## Compatibility

- **Interface:** 11508, 11509 (Classic Era 1.15.x / Season of Discovery)
- Battle.net whisper events (`CHAT_MSG_BN_WHISPER`) are registered but gracefully ignored if unavailable.
- If porting to Retail (10.2.6+ / 11.x), further API adaptation may be required.
