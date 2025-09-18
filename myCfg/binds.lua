Bind = require("hs.hotkey").bind

TLKeys = {}
TLKeys.hyper = { "alt", "ctrl", "shift", "cmd" }

local app = require "hs.application"
local bundleID = {
  launchpad = "com.apple.launchpad.launcher",
}
Bind(TLKeys.hyper, "l", nil, function()
  app.launchOrFocusByBundleID(bundleID.launchpad)
end)

-- Wezterm
local weztermOutput, _, _, _ = hs.execute("which wezterm", true)
local weztermBin = string.gsub(weztermOutput, "%s+", "")
local function wezterm(args)
  local command = string.format("%s %s", weztermBin, args)
  print(string.format("wezterm: %s", command))
  os.execute(command)
end
Bind(TLKeys.hyper, "return", nil, function()
  wezterm "start"
end)

-- Wifi
local wifi = require "hs.wifi"
Bind(TLKeys.hyper, "i", nil, function()
  local status = wifi.interfaceDetails().power
  wifi.setPower(not status)
end)

-- Bluetooth
local blueutilOutput, _, _, _ = hs.execute("which blueutil", true)
local blueutilBin = string.gsub(blueutilOutput, "%s+", "")
local function blueutil(args)
  local command = string.format("%s %s", blueutilBin, args)
  print(string.format("blueutil: %s", command))
  os.execute(command)
end
local function getStatusBluetooth()
  local status_cmd = string.format("%s -p", blueutilBin)
  local status, _, _, _ = hs.execute(status_cmd, false)
  return tonumber(status)
end
Bind(TLKeys.hyper, "b", nil, function()
  local new_status = getStatusBluetooth() == 0 and 1 or 0
  local set_cmd = string.format("-p %s", new_status)
  blueutil(set_cmd)
end)

-- Low Power Mode
local rgOutput, _, _, _ = hs.execute("which rg", true)
local rgBin = string.gsub(rgOutput, "%s+", "")
local awkOutput, _, _, _ = hs.execute("which awk", true)
local awkBin = string.gsub(awkOutput, "%s+", "")
local function pmset(args)
  local command = string.format("/usr/bin/sudo /usr/bin/pmset %s", args)
  print(string.format("pmset: %s", command))
  os.execute(command)
end
local function getStatusLowPowerMode()
  local status_cmd = string.format("/usr/bin/pmset -g | %s lowpowermode | %s '{print $2}'", rgBin, awkBin)
  local status, _, _, _ = hs.execute(status_cmd, false)
  return tonumber(status)
end
Bind(TLKeys.hyper, "e", nil, function()
  local new_status = getStatusLowPowerMode() == 0 and 1 or 0
  local set_cmd = string.format("-a lowpowermode %s", new_status)
  pmset(set_cmd)
end)
