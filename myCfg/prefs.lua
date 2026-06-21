local ipcOk, ipc = pcall(function()
  return hs.ipc
end)

if ipcOk then
  ipc.cliInstall() -- installs `hs` binary @ /usr/local/bin with ownership div:admin
  ipc.cliSaveHistory(false)
else
  print(string.format("hs.ipc unavailable: %s", ipc))
  hs.alert.show "hs.ipc unavailable; another Hammerspoon may be running"
end

-- enabled
hs.autoLaunch(true)
hs.menuIcon(true)
hs.preferencesDarkMode(true)
hs.allowAppleScript(true)
hs.accessibilityState(true)

-- disabled
hs.dockIcon(false)
hs.automaticallyCheckForUpdates(false)
hs.uploadCrashData(false)
