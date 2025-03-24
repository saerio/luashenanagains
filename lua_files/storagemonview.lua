-- ComputerCraft Script to fetch and display inventory items in the required format with scrolling and search

-- URL to fetch inventory data
local url = "http://191.96.1.3:5000/get_inventory"
local headers = {["turtleid"] = "53"}

-- Function to fetch inventory data
local function fetchInventory()
    local response, err = http.get(url, headers)
    if not response then
        print("Error fetching inventory: " .. (err or "Unknown error"))
        return nil
    end
    local data = response.readAll()
    response.close()
    return data
end

-- Function to parse JSON data (rudimentary, but works for this case)
local function parseJSON(jsonStr)
    local success, inventory = pcall(textutils.unserializeJSON, jsonStr)
    if success and inventory then
        return inventory
    else
        return nil
    end
end

-- Function to display inventory data with scrolling and search
local function displayInventory(inventoryData)
    local inventory = parseJSON(inventoryData)
    if not inventory or not inventory.inventory then
        print("Invalid inventory data.")
        return
    end
    
    local pageSize = 11  -- Number of items to display per screen page
    local currentPage = 1
    local searchTerm = ""
    
    -- Filter function to get items containing the search term
    local function filterItems()
        local filteredItems = {}
        for _, item in ipairs(inventory.inventory) do
            if string.find(item.name:lower(), searchTerm:lower()) then
                table.insert(filteredItems, item)
            end
        end
        return filteredItems
    end

    -- Function to display a page of items
    local function displayPage(page)
        term.clear()
        term.setCursorPos(1, 1)
        
        local filteredItems = filterItems()
        local itemCountFiltered = #filteredItems
        local startIndex = (page - 1) * pageSize + 1
        local endIndex = math.min(page * pageSize, itemCountFiltered)
        
        -- Print the items for the current page with the format: X(amount (itemname))
        for i = startIndex, endIndex do
            local item = filteredItems[i]
            print("X" .. item.count .. " (" .. item.name .. ")")
        end
        
        -- Display navigation instructions
        print("\nPage " .. page .. "/" .. math.ceil(itemCountFiltered / pageSize))
        print("Search: " .. searchTerm)
        print("Use ↑ (Up) / ↓ (Down) to scroll.")
        print("Type to search, Backspace to erase...")
    end

    -- Initial display of the first page
    displayPage(currentPage)

    -- Wait for user input to scroll through the pages or search
    while true do
        local event, key = os.pullEvent("key")
        
        if key == keys.down then  -- Next page
            local filteredItems = filterItems()
            if currentPage < math.ceil(#filteredItems / pageSize) then
                currentPage = currentPage + 1
                displayPage(currentPage)
            end
        elseif key == keys.up then  -- Previous page
            if currentPage > 1 then
                currentPage = currentPage - 1
                displayPage(currentPage)
            end
        elseif key == keys.backspace then  -- Remove last character in search term
            searchTerm = searchTerm:sub(1, -2)
            currentPage = 1  -- Reset to first page when search term changes
            displayPage(currentPage)
        elseif key >= 32 and key <= 126 then  -- Only printable characters
            searchTerm = searchTerm .. string.char(key)
            currentPage = 1  -- Reset to first page when search term changes
            displayPage(currentPage)
        end
    end
end

-- Main function
local function main()
    print("Fetching inventory data...")
    local inventoryData = fetchInventory()
    if inventoryData then
        print("Displaying inventory data:")
        displayInventory(inventoryData)
    else
        print("Failed to fetch inventory.")
    end
end

-- Run the script
main()
