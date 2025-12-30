#!/bin/bash
# Send a Lua command through the bridge with timeout and auto-recovery
# Usage: ./bridge.sh "print('hello')"
# Usage: ./bridge.sh path/to/script.lua

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_DIR="/mnt/c/Users/acurr/AppData/Roaming/pcsx-effect-editor/lua_cli"
INCOMING="$BRIDGE_DIR/incoming.lua"
RESPONSE="$BRIDGE_DIR/response.txt"
TIMEOUT=10  # seconds to wait for response
AUTO_RECOVER=true

# Parse arguments
CODE="$1"
if [ -z "$CODE" ]; then
    echo "Usage: $0 <lua-code-or-file>" >&2
    exit 1
fi

# If argument is a file, read it
if [ -f "$CODE" ]; then
    CODE=$(cat "$CODE")
fi

# Clear old response
rm -f "$RESPONSE"

# Write command with run marker
echo "$CODE
-- run" > "$INCOMING"

# Wait for response
for i in $(seq 1 $TIMEOUT); do
    sleep 1
    if [ -f "$RESPONSE" ]; then
        cat "$RESPONSE"
        rm -f "$RESPONSE"
        exit 0
    fi
done

# Timeout - check if we should recover
if [ "$AUTO_RECOVER" = true ]; then
    echo "[bridge] Timeout waiting for response. Attempting recovery..." >&2
    if "$SCRIPT_DIR/recover.sh"; then
        echo "[bridge] Recovery successful. Retrying command..." >&2
        rm -f "$RESPONSE"
        echo "$CODE
-- run" > "$INCOMING"

        for i in $(seq 1 $TIMEOUT); do
            sleep 1
            if [ -f "$RESPONSE" ]; then
                cat "$RESPONSE"
                rm -f "$RESPONSE"
                exit 0
            fi
        done
    fi
fi

echo "[bridge] ERROR: No response after timeout and recovery" >&2
exit 1
