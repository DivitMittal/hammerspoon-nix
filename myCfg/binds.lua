Bind = require("hs.hotkey").bind

TLKeys = {}
TLKeys.hyper = { "alt", "ctrl", "shift", "cmd" }

-- App Launcher (add Hammerspoon to App Management in System Settings > Security & Privacy)
local bundleID = {
  launchpad = "com.apple.launchpad.launcher",
  firefox = "org.mozilla.firefox",
  wezterm = "com.github.wez.wezterm",
}
local app = require "hs.application"
Bind(TLKeys.hyper, "l", nil, function()
  app.launchOrFocusByBundleID(bundleID.launchpad)
end)
Bind(TLKeys.hyper, "f", nil, function()
  app.launchOrFocusByBundleID(bundleID.firefox)
end)
Bind(TLKeys.hyper, "return", nil, function()
  app.launchOrFocusByBundleID(bundleID.wezterm)
end)

-- Wifi Toggle
Bind(TLKeys.hyper, "i", nil, function()
  local wifi = require "hs.wifi"
  local status = wifi.interfaceDetails().power
  wifi.setPower(not status)
end)

-- Bluetooth Toggle
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

-- Low Power Mode Toggle
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

-- GPU Switching (Integrated/Dedicated)
local function getStatusGPU()
  local status_cmd = "/usr/bin/pmset -g | " .. rgBin .. " 'gpuswitch' | " .. awkBin .. " '{print $2}'"
  local status, _, _, _ = hs.execute(status_cmd, false)
  return tonumber(status)
end

Bind(TLKeys.hyper, "g", nil, function()
  local current_status = getStatusGPU()
  local new_status = current_status == 0 and 1 or 0
  local gpu_type = new_status == 0 and "Integrated" or "Dedicated"

  local set_cmd = string.format("gpuswitch %s", new_status)
  pmset(set_cmd)

  -- Visual alert
  local message = string.format("GPU: %s", gpu_type)
  hs.alert.show(message, 2)
end)
