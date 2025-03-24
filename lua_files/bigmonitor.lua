-- Turtle Monitor with Authentication and Exit Logs
-- Displays multiple turtles in a 2x2 grid with an inventory legend, authentication, and exit logs

local SERVER_URL = "http://191.96.1.3:5000"  -- Base server URL
local location = "default"

function fetchJSON()
  print("Fetching JSON from: " .. index)
  local req = http.get(index)

  if req == nil then
    print("Failed to fetch JSON!")
    return nil
  end

  local response = req.readAll()
  req.close()

  local success, json = pcall(textutils.unserializeJSON, response)
  if not success then
    print("Error parsing JSON!")
    return nil
  end

  print("JSON fetched successfully!")
  return json
end

function findFiles()
  local json = fetchJSON()
  if json == nil then return {} end

  local files = {}
  if json["default"] and json["default"]["files"] then
    for _, item in ipairs(json["default"]["files"]) do
      table.insert(files, item)
    end
  end
  if json[location] and json[location]["files"] then
    for _, item in ipairs(json[location]["files"]) do
      table.insert(files, item)
    end
  end

  print("Fetched " .. #files .. " image(s):")
  for i, file in ipairs(files) do
    print(i .. ": " .. file)
  end

  return files
end

function drawImage(baseURL, monitor)
    if not baseURL then
      print("Skipping: No valid URL provided.")
      return "skipped"
    end
  
    local width, height = monitor.getSize()
    local fullURL = baseURL .. "-" .. width .. "x" .. height .. ".vcc"
  
    print("🔍 Base URL: " .. baseURL)
    print("🔗 Generated Full URL: " .. fullURL)
  
    local req = http.get(fullURL)
    if req == nil then
      print("❌ Image fetch failed: " .. fullURL)
      return "skipped"
    end
  
    local img = req.readAll()
    req.close()
  
    if not img or #img == 0 then
      print("❌ Image data is empty: " .. fullURL)
      return "skipped"
    end
  
    -- ✅ Print first 100 bytes of the file for debugging
    print("📄 First 100 bytes of VCC file:")
    print(img:sub(1, 100))
  
    print("✅ Rendering image: " .. fullURL)
    monitor.clear()
    monitor.setCursorPos(1, 1)
  
    local y = 1
    local x = 1
    local escapeMode = "none"
  
    for i = 1, #img do
      local char = img:sub(i, i)
  
      if escapeMode == "none" then
        if char == "\0" then
          escapeMode = "unknown"
        elseif char == "\n" then
          y = y + 1
          x = 1
          monitor.setCursorPos(x, y)
        else
          monitor.write(char)
          x = x + 1
        end
      elseif escapeMode == "unknown" then
        if char == "f" then escapeMode = "foreground"
        elseif char == "b" then escapeMode = "background"
        elseif char == "p" then escapeMode = "palette"
        else
          print("⚠️ Unknown escape sequence: " .. char)
          escapeMode = "none"
        end
      elseif escapeMode == "foreground" then
        monitor.setTextColor(colors.fromBlit(char))
        escapeMode = "none"
      elseif escapeMode == "background" then
        monitor.setBackgroundColor(colors.fromBlit(char))
        escapeMode = "none"
      elseif escapeMode == "palette" then
        print("⚠️ Palette change detected, skipping for now")
        escapeMode = "none"
      end
    end
  
    print("✅ Image drawn successfully!")
    return "drawn"
  end

local monitor = peripheral.find("monitor")
if not monitor then error("Monitor not found") end

local files = findFiles()
if #files == 0 then
  print("No images found, retrying...")
  sleep(10)
  files = findFiles()
end

local currentFile = 1

parallel.waitForAll(
  function()
    while true do
      if #files == 0 then
        print("⚠️ No images available, retrying in 10 seconds...")
        sleep(10)
        files = findFiles()
      else
        print("📺 Displaying image " .. currentFile .. "/" .. #files)
        local res = drawImage(files[currentFile], monitor)

        if res == "drawn" then
          currentFile = currentFile % #files + 1
        else
          print("⚠️ Skipping broken image.")
        end
        
        sleep(6)
      end
    end
  end
)