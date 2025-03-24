-- Turtle Monitor
-- Shows fuel levels and inventory for all turtles

local SERVER_URL = "http://191.96.1.3:5000"  -- Base server URL
local symbolChars = {"@", "#", "$", "%", "&", "!", "?", "+", "=", "*", "^", "~", "|", ":", ";", "<", ">", "/"} 
local itemSymbols = {}
local nextSymbol = 1

-- Function to get a symbol for an item
function getSymbolForItem(itemName)
    if not itemName then return " " end
    
    -- If we've seen this item before, use its symbol
    if itemSymbols[itemName] then
        return itemSymbols[itemName]
    end
    
    -- If not, assign a new symbol
    if nextSymbol <= #symbolChars then
        itemSymbols[itemName] = symbolChars[nextSymbol]
        nextSymbol = nextSymbol + 1
        return itemSymbols[itemName]
    else
        -- If we run out of symbols, use a generic one
        return "?"
    end
end

-- Function to request inventory data for a turtle
function getTurtleData(turtleID)
    local headers = {
        ["turtleid"] = turtleID
    }
    
    -- Get fuel level
    local fuelResponse = http.get(SERVER_URL .. "/get_fuel_level", headers)
    local fuelLevel = "Unknown"
    
    if fuelResponse then
        local responseText = fuelResponse.readAll()
        fuelResponse.close()
        
        local success, fuelData = pcall(textutils.unserializeJSON, responseText)
        if success and fuelData and fuelData.fuelLevel then
            fuelLevel = fuelData.fuelLevel
        end
    end
    
    -- Get inventory data
    local inventoryResponse = http.get(SERVER_URL .. "/get_inventory", headers)
    local inventory = {}
    
    if inventoryResponse then
        local responseText = inventoryResponse.readAll()
        inventoryResponse.close()
        
        local success, invData = pcall(textutils.unserializeJSON, responseText)
        if success and invData and invData.inventory then
            inventory = invData.inventory
        end
    end
    
    return {
        turtleID = turtleID,
        fuelLevel = fuelLevel,
        inventory = inventory
    }
end

-- Function to draw a turtle's inventory grid
function drawInventoryGrid(inventory)
    -- Create a blank grid first (16 slots, 4x4)
    local grid = {}
    for i = 1, 16 do
        grid[i] = " "  -- Initialize all slots with an empty space
    end
    
    -- Fill in the grid with items from the inventory
    for _, item in ipairs(inventory) do
        if item.slot >= 1 and item.slot <= 16 then
            grid[item.slot] = getSymbolForItem(item.item)
        end
    end
    
    -- Display as a 4x4 grid
    print("-----------------")
    print("| " .. grid[1] .. " | " .. grid[2] .. " | " .. grid[3] .. " | " .. grid[4] .. " |")
    print("-----------------")
    print("| " .. grid[5] .. " | " .. grid[6] .. " | " .. grid[7] .. " | " .. grid[8] .. " |")
    print("-----------------")
    print("| " .. grid[9] .. " | " .. grid[10] .. " | " .. grid[11] .. " | " .. grid[12] .. " |")
    print("-----------------")
    print("| " .. grid[13] .. " | " .. grid[14] .. " | " .. grid[15] .. " | " .. grid[16] .. " |")
    print("-----------------")
end

-- Function to draw the legend for item symbols
function drawLegend()
    print("\nLegend:")
    local sortedItems = {}
    for item, _ in pairs(itemSymbols) do
        table.insert(sortedItems, item)
    end
    table.sort(sortedItems)
    
    for _, item in ipairs(sortedItems) do
        local displayName = item:gsub("minecraft:", "")
        print(itemSymbols[item] .. " = " .. displayName)
    end
end

function monitorTurtle(turtleID)
    term.clear()
    term.setCursorPos(1, 1)
    print("=== Turtle #" .. turtleID .. " Monitor ===")

    -- Reset the itemSymbols table
    itemSymbols = {}
    nextSymbol = 1  -- Reset symbol index
    
    -- Get data for the specific turtle
    local data = getTurtleData(turtleID)
    print("Fuel = " .. data.fuelLevel)

    -- Check if inventory is not empty before attempting to draw the grid
    if next(data.inventory) then
        drawInventoryGrid(data.inventory)
    else
        print("No items in inventory.")
    end

    -- Display the legend showing symbol meanings
    drawLegend()
end


-- Call the monitor function for each turtle individually
monitorTurtle("11")
sleep(1)
monitorTurtle("18")
