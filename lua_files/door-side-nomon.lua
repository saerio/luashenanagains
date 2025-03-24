-- Function to handle the screen display depending on lockdown status
local function displayLockStatus(isLockdown)
    -- Lockdown mode: red background
    if isLockdown then
        term.setBackgroundColor(colors.red)
        term.clear()
        term.setTextColor(colors.white)
        print("System is in lockdown!")
    else
        -- Normal mode: white background
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setTextColor(colors.black)
        print("System is not in lockdown.")
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
local function authenticateUser(username, password, leads_to)
    local url = "http://191.96.1.3:5000/authenticate"  -- Replace with your server URL
    local body = "username=" .. username .. "&password=" .. password .. "&leads_to=storage"
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
    
    if authenticateUser(username, password, leads_to) then
        -- Authentication successful, do not display text on the screen
        term.setBackgroundColor(colors.green)
        term.clear()
        term.setTextColor(colors.white)
        print("Authentication successful!")
        
        -- Output redstone signal on the left
        redstone.setOutput("left", true)  -- Activate redstone
        
        -- Wait for a few seconds before locking again
        os.sleep(5)  -- Sleep for 5 seconds
        
        -- Lock the system again
        displayLockStatus(lockdown)  -- Return to normal locked state
        
        -- Turn off the redstone signal
        redstone.setOutput("left", false)  -- Deactivate redstone
    else
        -- Incorrect credentials, show message in terminal
        term.setTextColor(colors.red)
        print("Authentication failed. Try again.")
        term.setTextColor(colors.white)
    end
end

-- Main loop to keep checking the lockdown status
lockdown = checkLockdownStatus()
    
-- Display the updated lockdown status in the terminal
displayLockStatus(lockdown)
    
-- If the system is not in lockdown, request username and password for authentication
if not lockdown then
    requestUsernamePasswordAndAuthenticate()
else
    print("System is in lockdown. No authentication allowed.")
end
    
os.sleep(5)  -- Check every 5 seconds (this interval can be adjusted)
