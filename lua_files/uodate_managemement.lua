-- Configuration
local MANAGEMENT_LUA_URL = "http://191.96.1.3:5000/management.lua"  -- URL to fetch the latest management.lua

-- Path where the updated management.lua will be saved as the startup script
local STARTUP_LUA_PATH = "startup.lua"

-- Function to fetch and save the latest management.lua as the startup script
local function update_startup_lua()
    -- Make HTTP request to fetch the latest management.lua
    local response = http.get(MANAGEMENT_LUA_URL)

    if response then
        local luaCode = response.readAll()
        response.close()

        -- Save the fetched code as startup.lua
        local file = fs.open(STARTUP_LUA_PATH, "w")
        file.write(luaCode)
        file.close()

        print("Successfully updated startup.lua (management.lua).")
    else
        print("Failed to download management.lua. Please check the server.")
        return false
    end

    return true
end

-- Update the startup.lua
if update_startup_lua() then
    -- Reboot the turtle after updating
    print("Rebooting the turtle to apply the update...")
    os.reboot()
else
    print("Update failed. Turtle will not reboot.")
end
