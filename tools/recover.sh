#!/bin/bash
# PCSX-Redux recovery script
# Kills any existing instance, restarts, and waits for watcher to be ready

set -e

PCSX_EXE="/mnt/c/Users/acurr/Documents/pcsx-redux-nightly-23057.20251115.5-x64/pcsx-redux.exe"
BRIDGE_DIR="/mnt/c/Users/acurr/AppData/Roaming/pcsx-effect-editor/lua_cli"
INCOMING="$BRIDGE_DIR/incoming.lua"
RESPONSE="$BRIDGE_DIR/response.txt"
MAX_WAIT=30  # seconds to wait for watcher to come online

echo "[recover] Killing any existing PCSX-Redux process..."
taskkill.exe /IM pcsx-redux.exe /F 2>/dev/null || true

sleep 1

echo "[recover] Starting PCSX-Redux..."
# Start in background, detached from terminal
cd "/mnt/c/Users/acurr/Documents/pcsx-redux-nightly-23057.20251115.5-x64"
cmd.exe /c start "" "pcsx-redux.exe" &

echo "[recover] Waiting for watcher to come online..."

# Clear any old response
rm -f "$RESPONSE"

# Poll until watcher responds
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
            echo "[recover] Watcher is online! Response: $CONTENT"
            rm -f "$RESPONSE"
            exit 0
        fi
    fi

    echo "[recover] Waiting... ($i/$MAX_WAIT)"
done

echo "[recover] ERROR: Watcher did not respond within $MAX_WAIT seconds"
exit 1
