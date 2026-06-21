local function resolveBin(bin)
  if resolvebin then
    return resolvebin(bin)
  end

  local output, _, _, _ = hs.execute(string.format("which %s", bin), true)
  return string.gsub(output, "%s+", "")
end

local yabaiBin = resolveBin("yabai")
local jqBin = resolveBin("jq")
local Yabai = {}

local function shellQuote(value)
  return string.format("'%s'", tostring(value):gsub("'", "'\\''"))
end

function Yabai.action(args)
  local command = string.format("%s -m %s", yabaiBin, args)
  print(string.format("yabai: %s", command))
  os.execute(command)
end

function Yabai.query(args)
  local command = string.format("%s -m query --%s", yabaiBin, args)
  print(string.format("yabai: %s", command))
  return hs.execute(command, false)
end

function Yabai.queryJson(args, errorMessage)
  local ok, value = pcall(hs.json.decode, Yabai.query(args))

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

-- Focus windows linearly (BSP & floating) — up=prev, down=next in sorted order
local focusWindowJq = {
  up = [[sort_by(.display, .space, .frame.x, .frame.y, .id) | map(select(."is-visible" == true and .role != "AXUnknown")) | . as $w | ($w | map(."has-focus") | index(true)) as $i | if $i != null then $w[$i - 1].id else empty end]],
  down = [[sort_by(.display, .space, .frame.x, .frame.y, .id) | map(select(."is-visible" == true and .role != "AXUnknown")) | . as $w | ($w | map(."has-focus") | index(true)) as $i | if $i != null then $w[($i + 1) % ($w | length)].id else empty end]],
}
for key, jqExpr in pairs(focusWindowJq) do
  Bind(TLKeys.window, key, nil, function()
    local cmd = string.format("%s -m query --windows | %s -re '%s' 2>&1", yabaiBin, jqBin, jqExpr)
    print(string.format("yabai: %s", cmd))
    local windowId = string.gsub(hs.execute(cmd, false), "%s+", "")
    if windowId ~= "" then
      Yabai.focusWindow(windowId)
    end
  end)
end

-- Focus spaces
local focus = { right = "next", left = "prev" }
for key, direction in pairs(focus) do
  Bind(TLKeys.window, key, nil, function()
    Yabai.focusSpace(direction)
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

-- Carry windows to next/previous space
Bind(TLKeys.window, "tab", nil, function()
  Yabai.action("window --space next")
end)

Bind(TLKeys.hyper, "tab", nil, function()
  Yabai.action("window --space prev")
end)

-- PiP
Bind(TLKeys.window, "p", nil, function()
  Yabai.action("window --toggle sticky --toggle topmost --toggle pip")
end)

return Yabai
