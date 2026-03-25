local yabaiOutput, _, _, _ = hs.execute("which yabai", true)
local yabaiBin = string.gsub(yabaiOutput, "%s+", "")
local jqOutput, _, _, _ = hs.execute("which jq", true)
local jqBin = string.gsub(jqOutput, "%s+", "")
local function yabai(args)
  local command = string.format("%s -m %s", yabaiBin, args)
  print(string.format("yabai: %s", command))
  os.execute(command)
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
  yabai("window --space next")
end)

Bind(TLKeys.hyper, "tab", nil, function()
  yabai("window --space prev")
end)

-- PiP
Bind(TLKeys.window, "p", nil, function()
  yabai("window --toggle sticky --toggle topmost --toggle pip")
end)
