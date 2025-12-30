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

## Setup

1. Copy `config.sh.example` to `config.sh` and update paths for your system
2. Run `./tools/setup-hook.sh` to install the auto-start hook into PCSX-Redux
3. Restart PCSX-Redux - watcher should auto-load

**Configuration (`config.sh`):**
- `PCSX_EXE` - Path to pcsx-redux.exe
- `BRIDGE_DIR` - Path to the lua_cli bridge directory
- `WSL_DISTRO` - Your WSL distribution name
- `REPO_DIR` - Path to this repo
- `GAME_ISO` - Path to game ISO/BIN (Windows path with forward slashes)
- `SAVE_STATE` - Path to save state file to restore after recovery
- `ISO_BOOT_WAIT` - Seconds to wait for game to boot before loading save state

## Development

**Auto-start:** The watcher automatically loads when PCSX-Redux starts via a hook in `%APPDATA%\pcsx-redux\output.lua`.

**Bridge paths (configured in config.sh):**
- Default Windows: `%APPDATA%\pcsx-effect-editor\lua_cli\`
- Default WSL: `/mnt/c/Users/<user>/AppData/Roaming/pcsx-effect-editor/lua_cli/`

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
2. Starts PCSX-Redux with the configured ISO (`-iso` flag) and runs it (`-run`)
3. Polls until watcher responds to a test command
4. Waits for game to boot (`ISO_BOOT_WAIT` seconds)
5. Loads the configured save state via Lua

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
