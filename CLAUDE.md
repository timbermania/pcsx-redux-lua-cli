# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Lua bridge that enables remote Lua script execution in Windows PCSX-Redux emulator from WSL/Gemini environments. It uses file-based IPC (Inter-Process Communication) through a shared directory.

## Architecture

```
WSL/Gemini                          Windows PCSX-Redux
    |                                     |
    |-- writes Lua to incoming.lua -->    |
    |                                     |-- watcher.lua polls for file
    |                                     |-- executes code if "-- run" marker present
    |<-- reads response.txt --------------|-- writes captured output
```

**Core Component:** `tools/watcher.lua` - The main bridge script that:
- Hooks into PCSX-Redux's `DrawImguiFrame()` callback
- Polls for `incoming.lua` every ~30 frames (~0.5s)
- Requires `-- run` marker at end of file to execute (prevents partial file execution)
- Deletes input file immediately to prevent double execution
- Captures all `print()` output and writes to `response.txt`
- Uses `load()` + `pcall()` for safe execution with syntax/runtime error handling

## Development

**Auto-start:** The watcher automatically loads when PCSX-Redux starts via a hook in `%APPDATA%\pcsx-redux\output.lua`.

**Manual start (if needed):**
```lua
dofile('C:/Users/acurr/Documents/pcsx-redux-nightly-23057.20251115.5-x64/tools/watcher.lua')
```

**Bridge paths:**
- Windows: `%APPDATA%\pcsx-effect-editor\lua_cli\`
- WSL: `/mnt/c/Users/acurr/AppData/Roaming/pcsx-effect-editor/lua_cli/`

**Protocol:**
1. Write Lua code to `incoming.lua` with `-- run` appended at the end
2. Poll for `response.txt` to appear/update
3. Read response (file is overwritten on each execution)

## Crash Recovery

If PCSX-Redux crashes or becomes unresponsive:

```bash
./tools/recover.sh
```

This script:
1. Kills any existing `pcsx-redux.exe` process
2. Starts PCSX-Redux fresh (watcher auto-loads)
3. Polls until watcher responds to a test command
4. Exits with success when ready

**Wrapper with auto-recovery:**
```bash
./tools/bridge.sh "print('hello')"
```
Sends a command and auto-recovers on timeout.

## Important Implementation Details

- The `-- run` marker regex: `%-%-%s*run%s*$` (Lua pattern matching)
- If file deletion fails, execution is skipped to prevent infinite loops
- Output capture overrides `print()` temporarily, preserving original behavior
- The watcher is protected by `pcall()` to never crash the emulator UI loop
- Watcher copy lives at: `C:\Users\acurr\Documents\pcsx-redux-nightly-23057.20251115.5-x64\tools\watcher.lua`
