#!/bin/bash
# Installs the watcher auto-start hook into PCSX-Redux's output.lua
# Run this once after setting up config.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[setup] ERROR: config.sh not found. Copy config.sh.example to config.sh and update paths." >&2
    exit 1
fi

source "$CONFIG_FILE"

# Determine the Windows UNC path to watcher.lua
WATCHER_WSL_PATH="$REPO_DIR/tools/watcher.lua"
WATCHER_WIN_PATH="//wsl.localhost/$WSL_DISTRO$WATCHER_WSL_PATH"

# Find PCSX-Redux AppData folder (derive from PCSX_EXE path)
# Extract Windows username from the path
WIN_USER=$(echo "$PCSX_EXE" | sed -n 's|/mnt/c/Users/\([^/]*\)/.*|\1|p')
OUTPUT_LUA="/mnt/c/Users/$WIN_USER/AppData/Roaming/pcsx-redux/output.lua"

if [ ! -f "$OUTPUT_LUA" ]; then
    echo "[setup] ERROR: Could not find $OUTPUT_LUA" >&2
    echo "[setup] Make sure PCSX-Redux has been run at least once." >&2
    exit 1
fi

# Check if hook already exists
if grep -q "BridgeWatcherLoaded" "$OUTPUT_LUA"; then
    echo "[setup] Hook already exists in output.lua. Updating path..."
    # Update the existing dofile path
    sed -i "s|dofile('//wsl.localhost/[^']*')|dofile('$WATCHER_WIN_PATH')|" "$OUTPUT_LUA"
else
    echo "[setup] Installing hook into output.lua..."
    # Insert hook after the initial comments
    sed -i '/^-- recompiled one way or another.$/a\
\
-- Auto-start the Lua bridge watcher (only once)\
if not _G.BridgeWatcherLoaded then\
    _G.BridgeWatcherLoaded = true\
    pcall(function()\
        dofile('"'"''"$WATCHER_WIN_PATH"''"'"')\
    end)\
end' "$OUTPUT_LUA"
fi

echo "[setup] Done! Watcher will auto-load from:"
echo "        $WATCHER_WIN_PATH"
echo ""
echo "[setup] Restart PCSX-Redux to activate."
