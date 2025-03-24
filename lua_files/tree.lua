-- This script will make the turtle farm trees by mining logs and going up.
-- After finishing the tree, it will return to the ground and search for a new tree.
-- It will also automatically refuel when needed.

-- SETTINGS
local MAX_SEARCH_MOVES = 500  -- Maximum steps to search for a new tree
local DIG_DURING_SEARCH = false  -- Set to false to prevent digging during search
local FUEL_THRESHOLD = 10  -- Minimum fuel level to maintain

-- Function to check and refuel the turtle if needed
function checkFuel(threshold)
    threshold = threshold or FUEL_THRESHOLD  -- Use default threshold
    
    local currentFuel = turtle.getFuelLevel()
    
    -- If we have "unlimited" fuel, no need to refuel
    if currentFuel == "unlimited" then
        return true
    end
    
    -- If fuel is below threshold, try to refuel
    if currentFuel < threshold then
        print("Fuel low (" .. currentFuel .. "). Attempting to refuel...")
        
        -- Try each slot to find fuel items
        local originalSlot = turtle.getSelectedSlot()
        local refueled = false
        
        for slot = 1, 16 do
            turtle.select(slot)
            -- Try to refuel from this slot
            if turtle.refuel(1) then
                refueled = true
                print("Refueled from slot " .. slot .. ". New fuel level: " .. turtle.getFuelLevel())
                if turtle.getFuelLevel() >= threshold then
                    break  -- Stop if we have enough fuel now
                end
            end
        end
        
        -- Return to original slot
        turtle.select(originalSlot)
        
        if refueled then
            return true
        else
            print("WARNING: Could not refuel! Fuel level critical: " .. currentFuel)
            return false
        end
    end
    
    return true  -- Fuel level is fine
end

-- Function to mine the log in front of the turtle.
function mineLog()
    -- Check if the block in front is a log.
    local success, data = turtle.inspect()
    if success and (data.name:find("log") or data.name:find("wood")) then
        -- If it's a log, mine it.
        turtle.dig()
        return true
    end
    return false
end

-- Function to mine the block above the turtle.
function mineAbove()
    local success, data = turtle.inspectUp()
    if success and (data.name:find("log") or data.name:find("wood")) then
        -- If there's a log above, mine it.
        turtle.digUp()
        return true
    end
    return false
end

-- Function to move up one block.
function moveUp()
    checkFuel()  -- Check fuel before moving
    if not turtle.up() then
        -- If the turtle can't move up, try digging up the block first.
        turtle.digUp()
        turtle.up()
    end
end

-- Function to move down one block.
function moveDown()
    checkFuel()  -- Check fuel before moving
    if not turtle.down() then
        -- If the turtle can't move down, try digging down the block first.
        turtle.digDown()
        turtle.down()
    end
end

-- Function to go back down to the ground.
function goDownToGround()
    -- Keep moving down until the turtle detects a non-log block below.
    while true do
        local success, data = turtle.inspectDown()
        if success and not (data.name:find("log") or data.name:find("wood")) then
            -- If the block below is not a log, stop.
            break
        end
        moveDown()
    end
end

-- Function to turn randomly (left or right)
function turnRandomly()
    if math.random(2) == 1 then
        turtle.turnLeft()
    else
        turtle.turnRight()
    end
end

-- Function to move forward, handling obstacles
function tryMove()
    checkFuel()  -- Check fuel before moving
    
    if turtle.forward() then
        return true
    elseif DIG_DURING_SEARCH then
        -- Only dig if the setting allows it
        if not turtle.detect() or turtle.dig() then
            return turtle.forward()
        end
    end
    return false
end

-- Function to search for a new tree safely
function searchForTree(maxMoves)
    print("Searching for a new tree...")
    
    -- Remember our starting position
    local moves = 0
    local turnsLeft = 0
    local turnsRight = 0
    
    while moves < maxMoves do
        -- Check if there's a log in front
        local success, data = turtle.inspect()
        if success and (data.name:find("log") or data.name:find("wood")) then
            print("Found a new tree!")
            return true
        end
        
        -- Make sure we have enough fuel
        if not checkFuel() then
            print("Insufficient fuel to continue searching. Stopping.")
            return false
        end
        turtle.suck()
        -- No tree found, make a random move
        if math.random(5) == 1 then
            -- Occasionally turn randomly
            if math.random(2) == 1 then
                turtle.turnLeft()
                turnsLeft = turnsLeft + 1
            else
                turtle.turnRight()
                turnsRight = turnsRight + 1
            end
        else
            -- Try to move forward
            if not tryMove() then
                -- If we can't move forward, turn randomly
                if math.random(2) == 1 then
                    turtle.turnLeft()
                    turnsLeft = turnsLeft + 1
                else
                    turtle.turnRight()
                    turnsRight = turnsRight + 1
                end
            end
        end
        
        moves = moves + 1
        
        -- Every 10 moves, report progress
        if moves % 10 == 0 then
            print("Searched " .. moves .. " moves. Continuing...")
        end
    end
    
    print("No tree found after " .. maxMoves .. " moves.")
    return false
end

-- Function to farm the tree.
function farmTree()
    -- Start by checking if there's a log in front of the turtle.
    print("Checking if there's a log in front...")
    local success = mineLog()
    
    -- If there's a log in front, start the tree farming process.
    if success then
        print("Log found. Starting tree farming.")
        
        -- Make sure we have enough fuel
        if not checkFuel() then
            print("Insufficient fuel to farm the tree. Stopping.")
            return false
        end
        
        turtle.forward()  -- Move into the tree's position
        
        -- Now mine upward through the tree trunk
        local miningUp = true
        while miningUp do
            -- Make sure we have enough fuel
            if not checkFuel() then
                print("Insufficient fuel to continue mining upward. Returning to ground.")
                break
            end
            
            -- Mine the log above
            miningUp = mineAbove()
            
            -- If we found a log above, move up and continue
            if miningUp then
                moveUp()
            end
        end
        
        -- Once the tree is done, return to the ground.
        print("Tree mining complete. Returning to the ground.")
        goDownToGround()
        print("Finished and back on the ground.")
        return true
    else
        print("No log found in front of the turtle.")
        return false
    end
end

-- Initialize random number generator
math.randomseed(os.time())

-- Main function to farm trees and search for more
function main()
    print("Starting tree farming with autorefueling")
    print("Current fuel level: " .. turtle.getFuelLevel())
    print("Safe exploration mode: " .. (DIG_DURING_SEARCH and "OFF" or "ON"))
    
    -- First check if we have enough fuel to begin
    if not checkFuel(FUEL_THRESHOLD) then
        print("Not enough fuel to begin operation. Please add fuel items to inventory.")
        return
    end
    
    -- First try to farm a tree if we're already at one
    farmTree()
    
    -- Then search for a new tree
    local foundTree = searchForTree(MAX_SEARCH_MOVES)
    
    -- If we found a tree, farm it
    if foundTree then
        farmTree()
    end
    
    print("Tree farming complete.")
    print("Remaining fuel level: " .. turtle.getFuelLevel())
end

-- Start the tree farming process.
main()