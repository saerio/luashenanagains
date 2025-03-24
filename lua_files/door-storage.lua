-- Initialize the monitor
local monitor = peripheral.find("monitor")  
if not monitor then
    return  -- Exit if no monitor is found
end

monitor.setTextScale(2)  
monitor.clear()
monitor.setBackgroundColor(colors.white)
monitor.setTextColor(colors.black)
monitor.clear()

-- Function to display centered text
local function displayCenteredText(text)
    local width, height = monitor.getSize()
    local textLength = #text
    local x = math.floor((width - textLength) / 2)
    local y = math.floor(height / 2)
    monitor.setCursorPos(x, y)
    monitor.write(text)
end

-- Function to handle the screen display depending on lockdown status
local function displayLockStatus(isLockdown)
    if isLockdown then
        monitor.setBackgroundColor(colors.red)
        monitor.setTextColor(colors.white)
    else
        monitor.setBackgroundColor(colors.white)
        monitor.setTextColor(colors.black)
    end
    monitor.clear()
    displayCenteredText(" ")
end

-- Function to check lockdown status
local function checkLockdownStatus()
    local response = http.get("http://191.96.1.3:5000/lockdown")  
    if not response then return false end

    local body = response.readAll()
    response.close()
    local jsonResponse = textutils.unserializeJSON(body)
    
    if jsonResponse and jsonResponse.lockdown ~= nil then
        return jsonResponse.lockdown  
    else
        return false
    end
end

-- Function to authenticate user
local function authenticateUser(username, password)
    local url = "http://191.96.1.3:5000/authenticate"
    local body = "username=" .. username .. "&password=" .. password .. "&leads_to=storage"
    local headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }
    
    local response = http.post(url, body, headers)
    if not response then return false end
    
    local authStatus = response.readAll()
    response.close()
    return authStatus == "true"
end

-- Function to log redstone exit event
local function logExitEvent()
    local url = "http://191.96.1.3:5000/log-exit"
    local headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }
    
    local response = http.post(url, "event=redstone_exit", headers)
    if response then response.close() end
end

-- Function to open the door
local function openDoor()
    monitor.setBackgroundColor(colors.green)
    monitor.setTextColor(colors.black)
    monitor.clear()
    displayCenteredText(" ")

    redstone.setOutput("top", true)  
    os.sleep(5)  
    displayLockStatus(lockdown)  
    redstone.setOutput("top", false)  
end

-- Function to check redstone input at the back
local function checkRedstoneInput()
    return redstone.getInput("back")  
end

-- Function to continuously monitor redstone input
local function redstoneListener()
    while true do
        if checkRedstoneInput() then
            logExitEvent()  -- Log event when redstone input is detected
            openDoor()
        end
        os.sleep(0.1)  -- Check every 0.1 seconds for near-instant response
    end
end

-- Function to request authentication
local function requestUsernamePasswordAndAuthenticate()
    term.clear()
    term.setCursorPos(1, 1)
    write("Enter username: ")
    local username = read()
    
    write("Enter password: ")
    local password = read("*")  
    
    if authenticateUser(username, password) then
        openDoor()  
    end
end

-- Lockdown status
local lockdown = false

-- Run the redstone listener in a separate thread
parallel.waitForAny(
    function()  -- Main loop to check lockdown status and authentication
        while true do
            lockdown = checkLockdownStatus()
            displayLockStatus(lockdown)
            
            if not lockdown then
                requestUsernamePasswordAndAuthenticate()
            end
            
            os.sleep(5)
        end
    end,
    redstoneListener  -- Run redstone monitoring in parallel
)
