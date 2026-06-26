local function resolveBin(bin)
  if resolvebin then
    return resolvebin(bin)
  end

  local output, _, _, _ = hs.execute(string.format("which %s", bin), true)
  return string.gsub(output, "%s+", "")
end

local yabaiBin = resolveBin "yabai"
local Yabai = {}

local function shellQuote(value)
  return string.format("'%s'", tostring(value):gsub("'", "'\\''"))
end

-- yabai's client resolves its socket from $USER, but Hammerspoon's GUI-agent
-- environment doesn't export it. Resolve it once and prefix every command, so
-- they keep running through a plain (fast) shell instead of a login shell.
local userName = os.getenv "USER"
if not userName or userName == "" then
  userName = string.gsub(hs.execute("id -un", true), "%s+", "")
end
local yabaiCmd = string.format("USER=%s %s", shellQuote(userName), yabaiBin)

function Yabai.action(args)
  local command = string.format("%s -m %s", yabaiCmd, args)
  print(string.format("yabai: %s", command))
  hs.execute(command)
end

function Yabai.query(args)
  local command = string.format("%s -m query --%s", yabaiCmd, args)
  print(string.format("yabai: %s", command))
  return hs.execute(command)
end

function Yabai.queryJson(args, errorMessage)
  -- Assign to a local first: hs.execute returns (output, status, type, rc),
  -- and passing Yabai.query directly as the last call argument would expand
  -- all four into hs.json.decode, whose extra `status` arg makes it throw.
  local output = Yabai.query(args)
  local ok, value = pcall(hs.json.decode, output)

  if not ok or type(value) ~= "table" then
    hs.alert.show(errorMessage)
    return nil
  end

  return value
end

function Yabai.focusWindow(windowId)
  Yabai.action(string.format("window --focus %s", windowId))
end

function Yabai.focusSpace(spaceIndex)
  Yabai.action(string.format("space --focus %s", spaceIndex))
end

function Yabai.renameSpace(spaceIndex, label)
  Yabai.action(string.format("space %s --label %s", spaceIndex, shellQuote(label)))
end

-- Visible, selectable windows on the current space, sorted into a stable
-- left-to-right, top-to-bottom order (x → y → id). Pure Lua: one yabai
-- query, no jq subprocess and no shell-quoting hazards.
local function sortedVisibleWindows()
  local windows = Yabai.queryJson("windows --space", "Could not read yabai windows")
  if not windows then
    return nil
  end

  local visible = {}
  for _, win in ipairs(windows) do
    if win["is-visible"] == true and win.role ~= "AXUnknown" then
      visible[#visible + 1] = win
    end
  end

  table.sort(visible, function(a, b)
    if a.frame.x ~= b.frame.x then
      return a.frame.x < b.frame.x
    end
    if a.frame.y ~= b.frame.y then
      return a.frame.y < b.frame.y
    end
    return a.id < b.id
  end)

  return visible
end

-- Focus windows linearly (BSP & floating) — up = prev, down = next, both wrap.
local focusOffset = { up = -1, down = 1 }
for key, offset in pairs(focusOffset) do
  Bind(TLKeys.window, key, nil, function()
    local windows = sortedVisibleWindows()
    if not windows or #windows == 0 then
      return
    end

    local focusedIndex
    for index, win in ipairs(windows) do
      if win["has-focus"] then
        focusedIndex = index
        break
      end
    end
    if not focusedIndex then
      return
    end

    -- 1-based modular neighbour; wraps at both ends like the old jq filter.
    local target = (focusedIndex - 1 + offset) % #windows + 1
    Yabai.focusWindow(windows[target].id)
  end)
end

-- Mission-control index of the space `offset` steps from the focused one,
-- restricted to (and wrapping within) the current display. nil if unknown.
local function adjacentSpaceOnDisplay(offset)
  local spaces = Yabai.queryJson("spaces --display", "Could not read yabai spaces")
  if not spaces or #spaces == 0 then
    return nil
  end

  table.sort(spaces, function(a, b)
    return a.index < b.index
  end)

  local focusedIndex
  for i, space in ipairs(spaces) do
    if space["has-focus"] then
      focusedIndex = i
      break
    end
  end
  if not focusedIndex then
    return nil
  end

  return spaces[(focusedIndex - 1 + offset) % #spaces + 1].index
end

-- Focus the next/previous space within the current display (wraps).
local spaceFocus = { right = 1, left = -1 }
for key, offset in pairs(spaceFocus) do
  Bind(TLKeys.window, key, nil, function()
    local index = adjacentSpaceOnDisplay(offset)
    if index then
      Yabai.focusSpace(index)
    end
  end)
end

-- Create or destroy spaces
local refreshSpaceman = function()
  hs.eventtap.keyStroke({ "ctrl" }, "escape", 0.2)
end
local exist = { c = "create", d = "destroy" }
for key, action in pairs(exist) do
  Bind(TLKeys.window, key, nil, function()
    Yabai.action(string.format("space --%s", action))
    refreshSpaceman()
  end)
end

-- Throw the focused window to the next/previous space within the current
-- display, staying on the current space (yabai does not follow by default).
local function throwWindowToAdjacentSpace(offset)
  local index = adjacentSpaceOnDisplay(offset)
  if index then
    Yabai.action(string.format("window --space %s", index))
  end
end

Bind(TLKeys.window, "tab", nil, function()
  throwWindowToAdjacentSpace(1)
end)

Bind(TLKeys.windowShift, "tab", nil, function()
  throwWindowToAdjacentSpace(-1)
end)

-- Move the focused window to the display in a given direction.
local moveDisplay = { m = "west", o = "east", u = "north", [","] = "south" }
for key, dir in pairs(moveDisplay) do
  Bind(TLKeys.window, key, nil, function()
    Yabai.action(string.format("window --display %s", dir))
  end)
end

-- PiP
Bind(TLKeys.window, "p", nil, function()
  Yabai.action "window --toggle sticky --toggle topmost --toggle pip"
end)

return Yabai
