-- Initialize the monitor
local monitor = peripheral.find("monitor")
if not monitor then return end  -- Exit if no monitor is found

term.clear()
monitor.setTextScale(0.5)
monitor.clear()
monitor.setBackgroundColor(colors.white)
monitor.clear()

-- Function to handle the screen display depending on lockdown status
local function displayLockStatus(isLockdown)
    if isLockdown then
        monitor.setBackgroundColor(colors.red)
    else
        monitor.setBackgroundColor(colors.white)
    end
    monitor.clear()
end

-- Function to check lockdown status from the server
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

-- Function to authenticate user via the server
local function authenticateUser(username, password)
    local url = "http://191.96.1.3:5000/authenticate"
    local body = "username=" .. username .. "&password=" .. password .. "&leads_to=submain"
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
    monitor.clear()

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
local lockdown = checkLockdownStatus()
displayLockStatus(lockdown)

-- Run authentication and redstone monitoring in parallel
parallel.waitForAny(
    function()
        if not lockdown then
            requestUsernamePasswordAndAuthenticate()
        end
    end,
    redstoneListener  -- Run redstone monitoring in parallel
)
