-- Function to check and refuel if needed
function refuel_if_needed()
    if turtle.getFuelLevel() == 0 then  -- Check if out of fuel
        for i = 1, 16 do  -- Loop through inventory
            turtle.select(i)
            if turtle.refuel(1) then  -- Try to refuel with 1 unit
                print("Refueled using slot " .. i)
                break  -- Stop once refueled
            end
        end
    end
end

-- Refuel before moving
refuel_if_needed()

-- Try breaking the block in front
if turtle.detect() then
    turtle.dig()
    sleep(0.5) -- Small delay to allow item drops
end

-- Collect any dropped items
for i = 1, 16 do
    turtle.select(i)
    turtle.suck()
end

-- Refuel again in case it picked up fuel items
refuel_if_needed()

-- Move forward if possible
if turtle.forward() then
    print("Moved forward")
else
    print("Blocked from moving forward")
end
