local GET_LUA_URL = "http://191.96.1.3:5000/get_lua"  -- Endpoint to get Lua code
local RETRY_DELAY = 5  -- Seconds to wait before retrying if there's an error

-- Get turtle ID
local turtleID = tostring(os.getComputerID())

-- Function to request and execute Lua code (runs on any device, turtle or not)
local function fetch_and_run()
    while true do
        print("Fetching Lua code for Turtle ID: " .. turtleID)

        -- Set up headers with turtleID
        local headers = {
            ["turtleID"] = turtleID
        }

        -- Make HTTP request to get Lua code
        local response = http.get(GET_LUA_URL, headers)

        if response then
            local luaCode = response.readAll()
            response.close()

            if luaCode and luaCode ~= "" then
                print("Executing received code...")
                local func, err = load(luaCode, "received_code", "t", _ENV)

                if func then
                    local success, execErr = pcall(func)
                    if not success then
                        print("Error executing code: " .. execErr)
                    end
                else
                    print("Error loading code: " .. err)
                end
            else
                print("Error: Empty response received.")
            end
        else
            print("Failed to fetch code. Retrying in " .. RETRY_DELAY .. " seconds...")
        end
        -- Wait before retrying
        sleep(RETRY_DELAY)
    end
end

-- Run the function
fetch_and_run()
