local Yabai = require "WindowManager.yabai"

local function isSelectableWindow(win)
  return win.id and win.role ~= "AXUnknown"
end

-- Stable left-to-right, top-to-bottom order (x → y → id) so the same window
-- lands in the same chooser row every time — unlike MRU, which reshuffles.
local function spatialLess(a, b)
  if a.frame.x ~= b.frame.x then
    return a.frame.x < b.frame.x
  end
  if a.frame.y ~= b.frame.y then
    return a.frame.y < b.frame.y
  end
  return a.id < b.id
end

local function windowTitle(win)
  return win.title and win.title ~= "" and win.title or "(untitled)"
end

-- One reusable chooser for both window pickers; choices/placeholder are
-- replaced on each show, and the completion callback focuses the pick.
local windowChooser

local function windowChooserFor(placeholder)
  if not windowChooser then
    windowChooser = hs.chooser.new(function(choice)
      if choice and choice.windowId then
        Yabai.focusWindow(choice.windowId)
      end
    end)
    windowChooser:searchSubText(true)
    windowChooser:rows(10)
  end

  windowChooser:placeholderText(placeholder)
  return windowChooser
end

-- window+w: every selectable window on the current space, in spatial order.
local function chooseCurrentSpaceWindows()
  local windows = Yabai.queryJson("windows --space", "Could not read yabai windows")
  if not windows then
    return
  end

  local selectable = {}
  for _, win in ipairs(windows) do
    if isSelectableWindow(win) then
      selectable[#selectable + 1] = win
    end
  end
  table.sort(selectable, spatialLess)

  local choices = {}
  for _, win in ipairs(selectable) do
    local focusMark = win["has-focus"] and "● " or ""
    choices[#choices + 1] = {
      text = string.format("%s%s", focusMark, win.app or "?"),
      subText = windowTitle(win),
      windowId = win.id,
    }
  end

  if #choices == 0 then
    hs.alert.show "No windows on current space"
    return
  end

  local chooser = windowChooserFor "Choose window on this space"
  chooser:choices(choices)
  chooser:show()
end

-- window+a: every window of the focused app across all spaces and displays,
-- grouped by space then spatial within each space.
local function chooseSameAppWindows()
  local windows = Yabai.queryJson("windows", "Could not read yabai windows")
  if not windows then
    return
  end

  local focusedApp
  for _, win in ipairs(windows) do
    if win["has-focus"] then
      focusedApp = win.app
      break
    end
  end
  if not focusedApp or focusedApp == "" then
    hs.alert.show "Focused window has no app"
    return
  end

  local appWindows = {}
  for _, win in ipairs(windows) do
    if isSelectableWindow(win) and win.app == focusedApp then
      appWindows[#appWindows + 1] = win
    end
  end

  table.sort(appWindows, function(a, b)
    if a.space ~= b.space then
      return (a.space or 0) < (b.space or 0)
    end
    return spatialLess(a, b)
  end)

  local choices = {}
  for _, win in ipairs(appWindows) do
    local focusMark = win["has-focus"] and "● " or ""
    choices[#choices + 1] = {
      text = string.format("%s%s", focusMark, windowTitle(win)),
      subText = string.format("space %s · display %s", win.space or "?", win.display or "?"),
      windowId = win.id,
    }
  end

  if #choices == 0 then
    hs.alert.show(string.format("No %s windows", focusedApp))
    return
  end

  local chooser = windowChooserFor(string.format("Choose %s window", focusedApp))
  chooser:choices(choices)
  chooser:show()
end

-- window+s: every space, ordered by display. Displays are shown in the
-- space row metadata, not as separate chooser rows.
local spaceChooser
local renameHotkey

local function buildSpaceChoices()
  local spaces = Yabai.queryJson("spaces", "Could not read yabai spaces")
  if not spaces then
    return nil
  end

  local byDisplay = {}
  local displayOrder = {}
  for _, space in ipairs(spaces) do
    local display = space.display or 0
    if not byDisplay[display] then
      byDisplay[display] = {}
      displayOrder[#displayOrder + 1] = display
    end
    local group = byDisplay[display]
    group[#group + 1] = space
  end
  table.sort(displayOrder)

  local choices = {}
  for _, display in ipairs(displayOrder) do
    local group = byDisplay[display]
    table.sort(group, function(a, b)
      return a.index < b.index
    end)

    for _, space in ipairs(group) do
      local label = space.label and space.label ~= "" and space.label or string.format("Space %s", space.index)
      local focusMark = space["has-focus"] and "● " or ""
      local windowCount = type(space.windows) == "table" and #space.windows or 0
      choices[#choices + 1] = {
        text = string.format("%s%s", focusMark, label),
        subText = string.format("display %s · index %s · %s windows", display, space.index, windowCount),
        spaceIndex = space.index,
        label = space.label or "",
      }
    end
  end

  return choices
end

local function showSpaceChooser()
  local choices = buildSpaceChoices()
  if not choices or #choices == 0 then
    hs.alert.show "No spaces"
    return
  end

  if not spaceChooser then
    spaceChooser = hs.chooser.new(function(choice)
      if renameHotkey then
        renameHotkey:disable()
      end
      if choice and choice.spaceIndex then
        Yabai.focusSpace(choice.spaceIndex)
      end
    end)

    spaceChooser:placeholderText "Choose space (⌘R to rename)"
    spaceChooser:searchSubText(true)
    spaceChooser:rows(10)
  end

  spaceChooser:choices(choices)
  spaceChooser:show()

  -- ⌘R renames the highlighted space, leaving plain `r` free for searching.
  -- The hotkey is global, so we only keep it live while the chooser is open.
  if not renameHotkey then
    renameHotkey = hs.hotkey.new({ "cmd" }, "r", function()
      local choice = spaceChooser:selectedRowContents()
      if not choice or not choice.spaceIndex then
        return
      end

      spaceChooser:hide()
      renameHotkey:disable()

      local button, newLabel = hs.dialog.textPrompt(
        "Rename Space",
        string.format("New name for space %s", choice.spaceIndex),
        choice.label,
        "Rename",
        "Cancel"
      )
      if button == "Rename" and newLabel and newLabel ~= "" then
        Yabai.renameSpace(choice.spaceIndex, newLabel)
      end

      showSpaceChooser()
    end)
  end
  renameHotkey:enable()
end

windowBind("w", nil, chooseCurrentSpaceWindows)
windowBind("a", nil, chooseSameAppWindows)
windowBind("s", nil, showSpaceChooser)
