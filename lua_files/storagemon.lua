-- The endpoint to which the data will be sent
local endpoint = "http://191.96.1.3:5000/submit_inventory"

-- Function to get the inventory content
local function getInventory()
    local inventory = {}
    local side = "left"  -- Change this to match the actual adjacent inventory

    -- Check if there's an inventory on the specified side
    if peripheral.hasType(side, "inventory") then
        local inv = peripheral.wrap(side)
        local size = inv.size()

        for slot = 1, size do
            local item = inv.getItemDetail(slot)
            if item then
                table.insert(inventory, {
                    name = item.name,
                    count = item.count
                })
            end
        end
    else
        print("No inventory found on " .. side)
    end

    return inventory
end

-- Function to send data to the endpoint
local function sendInventoryData()
    local turtleID = os.getComputerID()  -- Get the computer's unique ID
    local fuelLevel = 1  -- Set fuel level to 0 since it's a computer

    -- Prepare the data
    local data = {
        turtleID = "53",
        inventory = getInventory(),
        fuelLevel = fuelLevel
    }

    -- Convert the data table to JSON
    local jsonData = textutils.serializeJSON(data)
    print("Sending data: " .. jsonData)

    -- Make the HTTP POST request
    local response = http.post(endpoint, jsonData, { ["Content-Type"] = "application/json" })

    -- Read the response (for debugging or error handling)
    if response then
        local body = response.readAll()
        response.close()
        print("Server response: " .. body)
    else
        print("Failed to connect to server.")
    end
end

-- Ensure HTTP API is enabled
if http then
    sendInventoryData()
else
    print("HTTP API is disabled. Enable it in ComputerCraft settings.")
end
