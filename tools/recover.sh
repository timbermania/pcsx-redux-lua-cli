#!/bin/bash
# PCSX-Redux recovery script
# Kills any existing instance, restarts with ISO, and loads save state

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[recover] ERROR: config.sh not found. Copy config.sh.example to config.sh and update paths." >&2
    exit 1
fi

source "$CONFIG_FILE"

INCOMING="$BRIDGE_DIR/incoming.lua"
RESPONSE="$BRIDGE_DIR/response.txt"
MAX_WAIT=30  # seconds to wait for watcher to come online

echo "[recover] Killing any existing PCSX-Redux process..."
taskkill.exe /IM pcsx-redux.exe /F 2>/dev/null || true

sleep 1

# Convert Windows path to proper format for command line
# GAME_ISO is like "C:/Users/..." - convert to "C:\Users\..." for Windows
GAME_ISO_WIN=$(echo "$GAME_ISO" | sed 's|/|\\|g')

echo "[recover] Starting PCSX-Redux with ISO: $GAME_ISO_WIN"
PCSX_DIR="$(dirname "$PCSX_EXE")"
cd "$PCSX_DIR"
cmd.exe /c start "" "$(basename "$PCSX_EXE")" -iso "$GAME_ISO_WIN" -run &

echo "[recover] Waiting for watcher to come online..."

# Clear any old response
rm -f "$RESPONSE"

# Poll until watcher responds
WATCHER_READY=false
for i in $(seq 1 $MAX_WAIT); do
    sleep 1

    # Send a simple test command
    echo 'print("ping")
-- run' > "$INCOMING"

    sleep 1

    # Check for response
    if [ -f "$RESPONSE" ]; then
        CONTENT=$(cat "$RESPONSE")
        if [[ "$CONTENT" == *"ping"* ]]; then
            echo "[recover] Watcher is online!"
            rm -f "$RESPONSE"
            WATCHER_READY=true
            break
        fi
    fi

    echo "[recover] Waiting for watcher... ($i/$MAX_WAIT)"
done

if [ "$WATCHER_READY" = false ]; then
    echo "[recover] ERROR: Watcher did not respond within $MAX_WAIT seconds"
    exit 1
fi

# Wait for game to boot before loading save state
echo "[recover] Waiting ${ISO_BOOT_WAIT}s for game to boot..."
sleep "$ISO_BOOT_WAIT"

# Load save state via Lua
echo "[recover] Loading save state: $SAVE_STATE"
rm -f "$RESPONSE"

cat > "$INCOMING" << EOF
local f = Support.File.open("$SAVE_STATE", "READ")
if f then
    PCSX.loadSaveState(f)
    f:close()
    print("Save state loaded successfully")
else
    print("ERROR: Could not open save state file")
end
-- run
EOF

# Wait for save state load confirmation
for i in $(seq 1 10); do
    sleep 1
    if [ -f "$RESPONSE" ]; then
        CONTENT=$(cat "$RESPONSE")
        echo "[recover] $CONTENT"
        rm -f "$RESPONSE"
        break
    fi
done

echo "[recover] Recovery complete!"
exit 0
