-- Configuration
local SERVER_URL = "http://191.96.1.3:5000/submit_inventory"  -- Endpoint to submit inventory and fuel data
local GET_LUA_URL = "http://191.96.1.3:5000/get_lua"  -- Endpoint to get Lua code
local RETRY_DELAY = 5  -- Seconds to wait before retrying if there's an error

-- Get turtle ID
local turtleID = tostring(os.getComputerID())

-- Check if running on a turtle by attempting to call turtle-specific functions
local isTurtle = pcall(function() return turtle.getItemDetail(1) end)

-- Function to submit inventory and fuel level data to the server (only on turtles)
local function submit_inventory_data()
    if not isTurtle then
        print("Not running on a turtle, skipping inventory and fuel submission.")
        return
    end

    -- Get inventory and fuel level
    local inventory = {}
    for slot = 1, 16 do  -- Assuming there are 16 inventory slots
        local item = turtle.getItemDetail(slot)
        if item then
            table.insert(inventory, {slot = slot, item = item.name, count = item.count})
        end
    end
    local fuelLevel = turtle.getFuelLevel()

    -- Create the POST request body
    local data = {
        turtleID = turtleID,
        inventory = inventory,
        fuelLevel = fuelLevel
    }

    -- Convert the data to JSON format
    local jsonData = textutils.serializeJSON(data)

    -- Set up headers with Content-Type and turtleID
    local headers = {
        ["Content-Type"] = "application/json",
        ["turtleID"] = turtleID
    }

    -- Make HTTP POST request to submit inventory and fuel data
    local response = http.post(SERVER_URL, jsonData, headers)

    if response then
        print("Successfully submitted inventory and fuel data.")
        response.close()
    else
        print("Failed to submit inventory and fuel data.")
    end
end

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

        -- Submit inventory and fuel level data (only on turtles)
        submit_inventory_data()

        -- Wait before retrying
        sleep(RETRY_DELAY)
    end
end

-- Run the function
fetch_and_run()
