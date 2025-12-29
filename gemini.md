# PCSX-Redux Lua CLI (WSL + Windows)

Bridge to execute Lua in Windows PCSX-Redux from WSL/Gemini using `%APPDATA%`.

## Setup
1.  **Directory**: Ensure `C:\Users\acurr\AppData\Roaming\pcsx-effect-editor\lua_cli` exists.
2.  **Emulator**: In PCSX-Redux, run `dofile('tools/watcher.lua')`.
    *   The script uses `os.getenv("APPDATA")` to find the bridge folder.

## Protocol
- **Bridge Path (Windows)**: `%APPDATA%\pcsx-effect-editor\lua_cli\`
- **Bridge Path (WSL)**: `/mnt/c/Users/acurr/AppData/Roaming/pcsx-effect-editor/lua_cli/`
- **Input**: `incoming.lua` (MUST end with `-- run` to execute)
- **Output**: `response.txt`

## Gemini Workflow
1. Write Lua to `/mnt/c/Users/acurr/AppData/Roaming/pcsx-effect-editor/lua_cli/incoming.lua`.
   *   **Crucial:** Append `-- run` to the end of the file.
2. Poll for `/mnt/c/Users/acurr/AppData/Roaming/pcsx-effect-editor/lua_cli/response.txt`.
3. Read result. (Note: The watcher overwrites this file on each run).
