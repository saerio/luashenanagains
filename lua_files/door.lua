-- Initialize the monitor
local monitor = peripheral.find("monitor")  -- Find the connected monitor
if not monitor then
    print("No monitor found!")
    return
end
term.clear()
monitor.setTextScale(0.5)  -- Set text scale for better visibility
monitor.clear()  -- Clear the screen

-- Set the background color to white (no text)
monitor.setBackgroundColor(colors.white)
monitor.clear()

-- Function to handle the screen display depending on lockdown status
local function displayLockStatus(isLockdown)
    -- Lockdown mode: red background
    if isLockdown then
        monitor.setBackgroundColor(colors.red)
        monitor.clear()
    else
        -- Normal mode: white background
        monitor.setBackgroundColor(colors.white)
        monitor.clear()
    end
end

-- Function to make an HTTP request to check if lockdown is enabled
local function checkLockdownStatus()
    local response = http.get("http://191.96.1.3:5000/lockdown")  -- Replace with your server URL
    if not response then
        print("Error: Unable to connect to the server.")
        return false
    end

    -- Read the response body
    local body = response.readAll()
    response.close()

    -- Parse the JSON response (using a JSON library like "json" in CC:Tweaked)
    local jsonResponse = textutils.unserializeJSON(body)

    -- Check the "lockdown" field in the JSON response
    if jsonResponse and jsonResponse.lockdown ~= nil then
        return jsonResponse.lockdown  -- Return true or false based on the lockdown status
    else
        print("Error: Invalid JSON response or missing lockdown field.")
        return false
    end
end

-- Function to authenticate username and password via the webserver
local function authenticateUser(username, password)
    local url = "http://191.96.1.3:5000/authenticate"  -- Replace with your server URL
    local body = "username=" .. username .. "&password=" .. password .. "&leads_to=main_door"
    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }
    
    local response = http.post(url, body, headers)
    if not response then
        print("Error: Unable to connect to the server.")
        return false
    end
    local authStatus = response.readAll()
    response.close()
    return authStatus == "true"  -- Assuming the server returns 'true' or 'false'
end

-- Lockdown status (this will be checked from the server)
local lockdown = false

-- Function to request username and password and check authentication
local function requestUsernamePasswordAndAuthenticate()
    term.clear()
    term.setCursorPos(1, 1)
    write("Enter username: ")
    local username = read()
    
    write("Enter password: ")
    local password = read("*")  -- Hide the password input
    
    if authenticateUser(username, password) then
        -- Authentication successful, but do not display any text
        monitor.clear()
        monitor.setBackgroundColor(colors.green)
        monitor.clear()

        -- Output redstone signal of strength 15 on the top
        redstone.setOutput("top", true)  -- Set redstone output to 15 (on)
        
        -- Wait for a few seconds before locking again
        os.sleep(5)  -- Sleep for 5 seconds
        
        -- Lock the system again
        displayLockStatus(lockdown)  -- Return to normal locked state
        
        -- Turn off the redstone signal
        redstone.setOutput("top", false)  -- Turn off redstone output
    else
        -- Incorrect credentials, show message, but don't display text on monitor
        print("Authentication failed. Try again.")
    end
end

-- Main loop to keep checking the lockdown status

-- First, check the lockdown status before anything else
lockdown = checkLockdownStatus()

-- Display the updated lockdown status on the screen
displayLockStatus(lockdown)

-- If the system is not in lockdown, request username and password for authentication
if not lockdown then
    requestUsernamePasswordAndAuthenticate()
else
    print("System is in lockdown. No authentication allowed.")
end

os.sleep(5)  -- Check every 5 seconds (this interval can be adjusted)
