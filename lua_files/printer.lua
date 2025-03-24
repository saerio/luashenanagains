-- Locate the printer peripheral
local printer = peripheral.find("printer")

if not printer then
    print("No printer found! Make sure it's connected.")
    return
end

-- Ask for user input
print("Enter text to print 128 times:")
local input = read()

-- Check if there's paper and ink
if not printer.hasPaper() then
    print("Error: No paper in the printer!")
    return
end

if printer.getInkLevel() == 0 then
    print("Error: No ink in the printer!")
    return
end

-- Start the first page
printer.newPage()

-- Print 128 times
for i = 1, 128 do
    printer.write(input)
    printer.newLine()

    -- After every 21 lines (full page), eject and start a new page
    if i % 21 == 0 then
        printer.endPage()

        -- Check if there's still paper before continuing
        if not printer.hasPaper() then
            print("Out of paper! Printing stopped at line " .. i)
            return
        end

        -- Start a new page
        printer.newPage()
    end
end

-- Finalize last page if needed
printer.endPage()
print("Printing complete!")
