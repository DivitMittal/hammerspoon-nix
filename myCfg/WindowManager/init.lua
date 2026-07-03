local pseudoModifier = require "pseudoModifier"
local spaces = require "hs.spaces"

-- F16 acts as a pseudo-modifier for window actions. Hold it to run multiple
-- action keys, or tap it to enter one-shot mode for the next action key.
WindowModifier = pseudoModifier.new("f16", "Window")

-- Register a window-mode binding: `key` (with optional real mods) runs fn.
function windowBind(key, mods, fn)
  pseudoModifier.bind(WindowModifier, mods, key, fn)
end

windowBind("space", nil, function()
  spaces.toggleMissionControl()
end)

------
-- Spaces
------
-- require("WindowManager.spaces")
require "WindowManager.yabai"
require "WindowManager.chooser"

------
-- Windows
------
require "WindowManager.window"
