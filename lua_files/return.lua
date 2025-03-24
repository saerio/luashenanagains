turtle.back()
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

refuel_if_needed()