-- tools/watcher.lua
-- Watches for lua_bridge/incoming.lua and executes it.

local APPDATA = os.getenv("APPDATA")
local BRIDGE_DIR = APPDATA .. "/pcsx-effect-editor/lua_cli/"
local INCOMING_FILE = BRIDGE_DIR .. "incoming.lua"
local RESPONSE_FILE = BRIDGE_DIR .. "response.txt"

-- Simple timer to avoid checking disk every single frame
local tick_counter = 0
local CHECK_INTERVAL = 30 -- Check every 30 frames (approx 0.5s)

function CheckBridge()
    local f = io.open(INCOMING_FILE, "r")
    if f then
        local code = f:read("*a")
        f:close()
        
        -- Check for execution marker "-- run" at the end of the file
        if not code:match("%-%-%s*run%s*$") then
            -- File exists but is not ready to run yet
            return
        end

        print("[Bridge] Found incoming command with '-- run' marker.")
        
        -- Delete the incoming file immediately to prevent double execution
        -- Note: If permissions fail, this might loop.
        local ok, err = os.remove(INCOMING_FILE)
        if not ok then
            print("[Bridge] Error removing file: " .. tostring(err))
            -- If we can't delete it, we shouldn't run it, or we'll loop forever.
            return
        end
        
        -- Prepare output capture
        local output_buffer = {}
        local old_print = print
        
        -- Override print to capture output
        print = function(...)
            local args = {...}
            local line = ""
            for i, v in ipairs(args) do
                if i > 1 then line = line .. "\t" end
                line = line .. tostring(v)
            end
            table.insert(output_buffer, line)
            old_print(...)
        end
        
        -- Execute
        local chunk, compile_err = load(code)
        if chunk then
            local status, run_err = pcall(chunk)
            if not status then
                table.insert(output_buffer, "RUNTIME ERROR: " .. tostring(run_err))
                old_print("[Bridge] Runtime Error: " .. tostring(run_err))
            else
                old_print("[Bridge] Execution successful.")
            end
        else
            table.insert(output_buffer, "SYNTAX ERROR: " .. tostring(compile_err))
            old_print("[Bridge] Syntax Error: " .. tostring(compile_err))
        end
        
        -- Restore print
        print = old_print
        
        -- Write response
        local out = io.open(RESPONSE_FILE, "w")
        if out then
            out:write(table.concat(output_buffer, "\n"))
            out:close()
        else
            old_print("[Bridge] Error: Could not write response file.")
        end
    end
end

-- Hook into existing DrawImguiFrame or create one
local old_DrawImguiFrame = DrawImguiFrame

function DrawImguiFrame()
    if old_DrawImguiFrame then old_DrawImguiFrame() end
    
    tick_counter = tick_counter + 1
    if tick_counter >= CHECK_INTERVAL then
        tick_counter = 0
        -- Use pcall to ensure we don't crash the UI loop if IO fails
        pcall(CheckBridge)
    end
end

print("[Bridge] Watcher started. Polling " .. INCOMING_FILE)