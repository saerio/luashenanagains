local INSTALL_URL = "http://191.96.1.3:5000/management.lua"  -- Replace with actual raw URL

print("Downloading startup.lua...")
local success = shell.run("wget", INSTALL_URL, "startup.lua")

if success then
    print("Installation successful! Rebooting...")
    sleep(2)
    os.reboot()
else
    print("Download failed. Check your internet connection and URL.")
end
