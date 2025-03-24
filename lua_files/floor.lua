-- Find all connected monitors
local monitors = {}
for _, p in pairs(peripheral.getNames()) do
    if peripheral.getType(p) == "monitor" then
        table.insert(monitors, peripheral.wrap(p))
    end
end

if #monitors == 0 then
    print("No monitors found!")
    return
end

-- Configure all monitors
for _, monitor in ipairs(monitors) do
    monitor.setTextScale(5)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
end

-- Function to generate a random color
local function randomColor()
    local colorList = {
        colors.red, colors.orange, colors.yellow, colors.lime, colors.green,
        colors.cyan, colors.lightBlue, colors.blue, colors.purple, colors.magenta,
        colors.pink, colors.white, colors.lightGray
    }
    return colorList[math.random(#colorList)]
end

-- Function to draw the disco floor on a monitor
local function drawDiscoFloor(monitor)
    local width, height = monitor.getSize()
    for y = 1, height do
        for x = 1, width do
            monitor.setCursorPos(x, y)
            monitor.setBackgroundColor(randomColor())
            monitor.write(" ")  -- Draw a colored block
        end
    end
end

-- Disco loop across all monitors
while true do
    for _, monitor in ipairs(monitors) do
        drawDiscoFloor(monitor)
    end
    sleep(0.2)  -- Change speed of the effect
end
