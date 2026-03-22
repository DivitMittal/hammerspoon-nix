local yabaiOutput, _, _, _ = hs.execute("which yabai", true)
local yabaiBin = string.gsub(yabaiOutput, "%s+", "")
local function yabai(args)
  local command = string.format("%s -m %s", yabaiBin, args)
  print(string.format("yabai: %s", command))
  os.execute(command)
end

-- Focus windows linearly (BSP & floating) — up=prev, down=next in sorted order
local focusWindowJq = {
  up   = [[sort_by(.display, .space, .frame.x, .frame.y, .id) | map(select(."is-visible" == true and .role != "AXUnknown")) | nth(index(map(select(."has-focus" == true))) - 1).id]],
  down = [[sort_by(.display, .space, .frame.x, .frame.y, .id) | map(select(."is-visible" == true and .role != "AXUnknown")) | reverse | nth(index(map(select(."has-focus" == true))) - 1).id]],
}
for key, jqExpr in pairs(focusWindowJq) do
  Bind(TLKeys.window, key, nil, function()
    local cmd = string.format("%s -m query --windows | jq -re '%s'", yabaiBin, jqExpr)
    print(string.format("yabai: %s", cmd))
    local windowId = string.gsub(hs.execute(cmd, true), "%s+", "")
    if windowId ~= "" then
      yabai(string.format("window --focus %s", windowId))
    end
  end)
end

-- Focus spaces
local focus = { right = "next", left = "prev" }
for key, direction in pairs(focus) do
  Bind(TLKeys.window, key, nil, function()
    yabai(string.format("space --focus %s", direction))
  end)
end

-- Create or destroy spaces
local refreshSpaceman = function()
  hs.eventtap.keyStroke({ "ctrl" }, "escape", 0.2)
end
local exist = { c = "create", d = "destroy" }
for key, action in pairs(exist) do
  Bind(TLKeys.window, key, nil, function()
    yabai(string.format("space --%s", action))
    refreshSpaceman()
  end)
end

-- Carry windows to next/previous space
Bind(TLKeys.window, "tab", nil, function()
  yabai "window --space next"
end)

Bind(TLKeys.hyper, "tab", nil, function()
  yabai "window --space prev"
end)

-- PiP
Bind(TLKeys.window, "p", nil, function()
  yabai "window --toggle sticky --toggle topmost --toggle pip"
end)
