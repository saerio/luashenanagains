-- Modified helper function to handle multiple displays and set color
local function fillVerticalBar(startX, y, h, thickness, color)
    -- Default to grey if no color is provided
    color = color or colors.lightGray
    
    for _, disp in ipairs(displays) do
        -- Calculate if this bar segment belongs on this monitor
        local localStartX = startX - disp.x
        local localEndX = localStartX + thickness - 1
        
        -- Always draw on each monitor when it's the green bar
        if color == colors.green then
            local drawStartX = disp.width - thickness + 1
            local drawEndX = disp.width
            
            -- Set the background color for the bar
            disp.monitor.setBackgroundColor(color)
            
            for col = drawStartX, drawEndX do
                for row = y, math.min(y + h - 1, disp.height) do
                    disp.monitor.setCursorPos(col, row)
                    disp.monitor.write(" ")
                end
            end
        else
            -- Original behavior for non-green bars
            if localEndX >= 0 and localStartX < disp.width then
                local drawStartX = math.max(1, localStartX)
                local drawEndX = math.min(disp.width, localEndX)
                
                disp.monitor.setBackgroundColor(colors.black) -- Reset color first
                disp.monitor.setBackgroundColor(color)
                
                for col = drawStartX, drawEndX do
                    for row = y, math.min(y + h - 1, disp.height) do
                        disp.monitor.setCursorPos(col, row)
                        disp.monitor.write(" ")
                    end
                end
            end
        end
    end
end
