-- an atm for computercraft tweaked that stores an ID on the card but any actual data on the server side
local http = require("http")

local function displayMenu()
    term.clear()
    term.setCursorPos(1, 1)
    print("Welcome to the ATM")
    print("1. Check Balance")
    print("2. Deposit")
    print("3. Withdraw")
    print("4. Exit")
    write("Select an option: ")
end

local function sendRequest(action, cardID, amount)
    local url = "http://your-server-address/api/atm"
    local body = textutils.serializeJSON({action = action, cardID = cardID, amount = amount})
    local response = http.post(url, body, {["Content-Type"] = "application/json"})
    if response then
        local responseBody = response.readAll()
        response.close()
        return textutils.unserializeJSON(responseBody)
    else
        error("Failed to communicate with the server.")
    end
end

local function handleCard()
    print("Please insert your card.")
    while true do
        local event, side, x, y = os.pullEvent("disk")
        local cardID = disk.getID(side)
        if cardID then
            return cardID
        end
    end
end

local function main()
    local cardID = handleCard()
    while true