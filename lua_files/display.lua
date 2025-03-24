local index = "http://191.96.1.3:5000/vcc/index.json"
local location = "default"

function fetchJSON()
  print("🔄 Fetching JSON from: " .. index)
  local req = http.get(index)

  if req == nil then
    print("❌ Failed to fetch JSON!")
    return nil
  end

  local response = req.readAll()
  req.close()

  print("✅ JSON Response Received")

  local success, json = pcall(textutils.unserializeJSON, response)
  if not success then
    print("❌ Error parsing JSON!")
    return nil
  end

  return json
end

function findFiles()
  sleep(1)
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

  if #files == 0 then
    print("⚠️ No images found in JSON!")
  else
    print("✅ Found " .. #files .. " images:")
    for i, file in ipairs(files) do
      print("📂 " .. i .. ": " .. file)
    end
  end

  return files
end

function drawImage(baseURL, monitor)
  sleep(1)
  if not baseURL then
    print("Skipping: No valid URL provided.")
    return "skipped"
  end

  local width, height = monitor.getSize()
  local fullURL = baseURL .. "-" .. width .. "x" .. height .. ".vcc"

  print("🔗 Fetching Image: " .. fullURL)
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

  print("✅ Rendering image: " .. fullURL)
  monitor.clear()
  monitor.setCursorPos(1, 1)

  local y = 1
  local escapeMode = "none"
  local paletteSlot, paletteR, paletteG, paletteB = nil, nil, nil, nil

  for i = 1, #img do
    local char = img:sub(i, i)

    if escapeMode == "none" then
      if char == "\0" then
        escapeMode = "unknown"
      elseif char == "\n" then
        y = y + 1
        monitor.setCursorPos(1, y)
      else
        monitor.write(char)
      end
    elseif escapeMode == "unknown" then
      if char == "f" then escapeMode = "foreground"
      elseif char == "b" then escapeMode = "background"
      elseif char == "p" then escapeMode = "palette"
      else
        print("⚠️ Malformed escape sequence: " .. char)
        escapeMode = "none"
      end
    elseif escapeMode == "foreground" then
      monitor.setTextColor(colors.fromBlit(char))
      escapeMode = "none"
    elseif escapeMode == "background" then
      monitor.setBackgroundColor(colors.fromBlit(char))
      escapeMode = "none"
    elseif escapeMode == "palette" then
      if paletteSlot == nil then
        paletteSlot = char
      elseif paletteR == nil then
        paletteR = string.byte(char)
      elseif paletteG == nil then
        paletteG = string.byte(char)
      elseif paletteB == nil then
        paletteB = string.byte(char)

        monitor.setPaletteColour(
          colors.fromBlit(paletteSlot),
          paletteR / 255,
          paletteG / 255,
          paletteB / 255
        )
        escapeMode = "none"
      end
    end
  end

  return "drawn"
end

local monitor = peripheral.find("monitor")
local files = findFiles()
local currentFile = 1

while true do
  sleep(1)
  if #files == 0 then
    print("⚠️ No images available! Retrying in 10 seconds...")
    sleep(10)
    files = findFiles()
  else
    print("🖼 Displaying image " .. currentFile .. "/" .. #files)
    local res = drawImage(files[currentFile], monitor)

    currentFile = currentFile + 1
    if currentFile > #files then
      files = findFiles()
      currentFile = 1
    end

    if res ~= "skipped" then
      sleep(6)
    end
  end
end