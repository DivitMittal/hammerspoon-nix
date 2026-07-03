-- Warpd: keyboard-driven mouse/pointer control, via the F17 pseudo-modifier.
-- Hold F17 to run multiple pointer actions, or tap it for one-shot mode.
local pseudoModifier = require "pseudoModifier"
local warpdBin = resolvebin "warpd"

local pointerModifier = pseudoModifier.new("f17", "Pointer")

-- Run a Warpd mode once, then leave pointer mode.
local function pointerBind(key, fn)
  pseudoModifier.bind(pointerModifier, {}, key, fn)
end

pointerBind("q", function()
  os.execute(string.format("%s --normal &", warpdBin))
end)
pointerBind("s", function()
  os.execute(string.format("%s --smart-hint --oneshot &", warpdBin))
end)
pointerBind("g", function()
  os.execute(string.format("%s --grid --oneshot &", warpdBin))
end)
pointerBind("f", function()
  os.execute(string.format("%s --hint --oneshot &", warpdBin))
end)
pointerBind("p", function()
  os.execute(string.format("%s --hint2 --oneshot &", warpdBin))
end)
