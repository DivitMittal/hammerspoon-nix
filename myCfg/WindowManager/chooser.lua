local Yabai = require "WindowManager.yabai"

local windowHistory = {}
local sameAppWindowHistory = {}
local spaceChooser
local renameSpaceChooser
local switcherTapInterval = 0.65
local switcherSession = {
  mode = nil,
  lastTap = 0,
  index = 0,
  windowIds = {},
}

local function isSelectableWindow(win)
  return win.id and win.role ~= "AXUnknown"
end

-- Single yabai query returning the selectable windows in `scope` plus the
-- focused window object (found via `has-focus`). Replaces two separate
-- queries — one subprocess per keystroke instead of two.
local function querySelectableWindows(scope)
  local windows = Yabai.queryJson(scope, "Could not read yabai windows")
  if not windows then
    return nil, nil
  end

  local selectableWindows = {}
  local focusedWindow
  for _, win in ipairs(windows) do
    if win["has-focus"] then
      focusedWindow = win
    end
    if isSelectableWindow(win) then
      table.insert(selectableWindows, win)
    end
  end

  return selectableWindows, focusedWindow
end

local function recordFocusedWindow(win)
  if not win then
    return
  end

  local app = win:application()
  local appName = app and app:name()
  local windowId = win:id()
  if not appName or not windowId then
    return
  end

  for index = #windowHistory, 1, -1 do
    if windowHistory[index] == windowId then
      table.remove(windowHistory, index)
    end
  end
  table.insert(windowHistory, 1, windowId)

  local history = sameAppWindowHistory[appName] or {}
  for index = #history, 1, -1 do
    if history[index] == windowId then
      table.remove(history, index)
    end
  end

  table.insert(history, 1, windowId)
  sameAppWindowHistory[appName] = history
end

hs.window.filter.default:rejectApp "iStat Menus"
hs.window.filter.default:subscribe(hs.window.filter.windowFocused, recordFocusedWindow)

local function getOrderedWindowIds(windows, currentWindowId, history)
  local validWindowIds = {}
  for _, win in ipairs(windows) do
    validWindowIds[win.id] = true
  end

  local orderedWindowIds = {}
  local includedWindowIds = {}
  for _, windowId in ipairs(history) do
    if windowId ~= currentWindowId and validWindowIds[windowId] then
      table.insert(orderedWindowIds, windowId)
      includedWindowIds[windowId] = true
    end
  end

  for _, win in ipairs(windows) do
    if win.id ~= currentWindowId and not includedWindowIds[win.id] then
      table.insert(orderedWindowIds, win.id)
    end
  end

  return orderedWindowIds
end

local function cycleWindows(mode, windows, currentWindowId, history, emptyMessage)
  local now = hs.timer.secondsSinceEpoch()
  local keepCycling = switcherSession.mode == mode
    and now - switcherSession.lastTap <= switcherTapInterval
    and #switcherSession.windowIds > 0

  if not keepCycling then
    switcherSession.mode = mode
    switcherSession.index = 0
    switcherSession.windowIds = getOrderedWindowIds(windows, currentWindowId, history)
  end

  switcherSession.lastTap = now

  if #switcherSession.windowIds == 0 then
    hs.alert.show(emptyMessage)
    return
  end

  switcherSession.index = switcherSession.index % #switcherSession.windowIds + 1
  Yabai.focusWindow(switcherSession.windowIds[switcherSession.index])
end

local function cycleCurrentSpaceWindows()
  local windows, focusedWindow = querySelectableWindows "windows --space"
  if not windows or not focusedWindow then
    return
  end

  cycleWindows("current-space", windows, focusedWindow.id, windowHistory, "No other windows on current space")
end

local function cycleSameAppWindows()
  local allWindows, focusedWindow = querySelectableWindows "windows"
  if not allWindows or not focusedWindow then
    return
  end

  local appName = focusedWindow.app
  if not appName or appName == "" then
    hs.alert.show "Focused window has no app name"
    return
  end

  local windows = {}
  for _, win in ipairs(allWindows) do
    if win.app == appName then
      table.insert(windows, win)
    end
  end

  cycleWindows(
    "same-app",
    windows,
    focusedWindow.id,
    sameAppWindowHistory[appName] or {},
    string.format("No other %s windows", appName)
  )
end

local function chooseCurrentDisplaySpace()
  local spaces = Yabai.queryJson("spaces --display", "Could not read yabai spaces")
  if not spaces then
    return
  end

  local choices = {}
  for _, space in ipairs(spaces) do
    if space.index then
      local label = space.label and space.label ~= "" and space.label or string.format("Space %s", space.index)
      local focusMark = space["has-focus"] and "● " or ""
      local windowCount = type(space.windows) == "table" and #space.windows or 0
      table.insert(choices, {
        text = string.format("%s%s", focusMark, label),
        subText = string.format("index %s · %s windows", space.index, windowCount),
        index = space.index,
        label = space.label or "",
      })
    end
  end

  if #choices == 0 then
    hs.alert.show "No spaces on current display"
    return
  end

  if not spaceChooser then
    spaceChooser = hs.chooser.new(function(choice)
      if choice then
        Yabai.focusSpace(choice.index)
      end
    end)

    spaceChooser:placeholderText "Choose space"
    spaceChooser:searchSubText(true)
    spaceChooser:rows(8)
  end

  spaceChooser:choices(choices)
  spaceChooser:show()
end

local function renameCurrentDisplaySpace()
  local spaces = Yabai.queryJson("spaces --display", "Could not read yabai spaces")
  if not spaces then
    return
  end

  local choices = {}
  for _, space in ipairs(spaces) do
    if space.index then
      local label = space.label and space.label ~= "" and space.label or string.format("Space %s", space.index)
      local focusMark = space["has-focus"] and "● " or ""
      table.insert(choices, {
        text = string.format("%s%s", focusMark, label),
        subText = string.format("rename index %s", space.index),
        index = space.index,
        label = space.label or "",
      })
    end
  end

  if #choices == 0 then
    hs.alert.show "No spaces on current display"
    return
  end

  if not renameSpaceChooser then
    renameSpaceChooser = hs.chooser.new(function(choice)
      if not choice then
        return
      end

      local button, newLabel = hs.dialog.textPrompt(
        "Rename Space",
        string.format("New name for space %s", choice.index),
        choice.label,
        "Rename",
        "Cancel"
      )

      if button == "Rename" and newLabel and newLabel ~= "" then
        Yabai.renameSpace(choice.index, newLabel)
      end
    end)

    renameSpaceChooser:placeholderText "Choose space to rename"
    renameSpaceChooser:searchSubText(true)
    renameSpaceChooser:rows(8)
  end

  renameSpaceChooser:choices(choices)
  renameSpaceChooser:show()
end

Bind(TLKeys.window, "w", nil, cycleCurrentSpaceWindows)
Bind(TLKeys.window, "a", nil, cycleSameAppWindows)
Bind(TLKeys.window, "s", nil, chooseCurrentDisplaySpace)
Bind(TLKeys.windowShift, "r", nil, renameCurrentDisplaySpace)
