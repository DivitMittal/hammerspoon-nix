local canvas = require "hs.canvas"
local eventtap = require "hs.eventtap"
local geometry = require "hs.geometry"
local hotkey = require "hs.hotkey"
local keycodes = require "hs.keycodes"
local screen = require "hs.screen"
local timer = require "hs.timer"

local pseudoModifier = {}

local function hideHud(modal)
  if modal._hud then
    modal._hud:delete()
    modal._hud = nil
  end
end

local function showHud(modal)
  hideHud(modal)

  local currentScreen = screen.mainScreen()
  local frame = currentScreen and currentScreen:frame()
  if not frame then
    return
  end

  local label = modal._label
  local width = math.max(110, (#label * 11) + 32)
  local height = 44
  local margin = 20
  local rect = geometry.rect(frame.x + frame.w - width - margin, frame.y + frame.h - height - margin, width, height)

  modal._hud = canvas.new(rect):appendElements({
    type = "rectangle",
    action = "fill",
    roundedRectRadii = { xRadius = 10, yRadius = 10 },
    fillColor = { white = 0, alpha = 0.82 },
  }, {
    type = "text",
    text = label,
    textAlignment = "center",
    textColor = { white = 1, alpha = 1 },
    textFont = Font and Font.default or ".AppleSystemUIFont",
    textSize = 16,
    frame = { x = 10, y = 10, w = width - 20, h = height - 20 },
  })

  modal._hud:level(canvas.windowLevels.floating)
  modal._hud:behavior(canvas.windowBehaviors.canJoinAllSpaces)
  modal._hud:show()
end

local function stopKeyWatcher(modal)
  if modal._keyWatcher then
    modal._keyWatcher:stop()
    modal._keyWatcher = nil
  end
end

local function stopTimeout(modal)
  if modal._timeout then
    modal._timeout:stop()
    modal._timeout = nil
  end
end

local function resetTimeout(modal)
  stopTimeout(modal)
  modal._timeout = timer.doAfter(3, function()
    modal:exit()
  end)
end

local function normalizeMods(mods)
  local normalized = { alt = false, ctrl = false, cmd = false, shift = false }

  for _, mod in ipairs(mods or {}) do
    if mod == "alt" or mod == "option" then
      normalized.alt = true
    elseif mod == "ctrl" or mod == "control" then
      normalized.ctrl = true
    elseif mod == "cmd" or mod == "command" then
      normalized.cmd = true
    elseif mod == "shift" then
      normalized.shift = true
    end
  end

  return normalized
end

local function modsMatch(required, event)
  local flags = event:getFlags()
  local actual = {
    alt = not not flags.alt,
    ctrl = not not flags.ctrl,
    cmd = not not flags.cmd,
    shift = not not flags.shift,
  }

  return actual.alt == required.alt
    and actual.ctrl == required.ctrl
    and actual.cmd == required.cmd
    and actual.shift == required.shift
end

local function findBinding(modal, event)
  local keyCode = event:getKeyCode()
  for _, binding in ipairs(modal._bindings) do
    if binding.keyCode == keyCode and modsMatch(binding.mods, event) then
      return binding
    end
  end
  return nil
end

local function startWatcher(modal)
  stopKeyWatcher(modal)
  modal._keyWatcher = eventtap
    .new({ eventtap.event.types.keyDown, eventtap.event.types.keyUp }, function(event)
      if not modal._state then
        return false
      end

      local keyCode = event:getKeyCode()
      if keyCode == keycodes.map.escape then
        modal:exit()
        return true
      end

      local binding = findBinding(modal, event)
      if not binding then
        return false
      end

      if event:getType() == eventtap.event.types.keyDown then
        binding.fn()
        modal._actionRan = true

        if modal._state == "oneshot" then
          modal:exit()
        end
      end

      return true
    end)
    :start()
end

function pseudoModifier.new(key, label)
  local modal = { _bindings = {} }
  modal._label = label

  function modal:enterHeld()
    self._state = "held"
    self._actionRan = false
    showHud(self)
    stopTimeout(self)
    startWatcher(self)
  end

  function modal:enterOneshot()
    self._state = "oneshot"
    self._actionRan = false
    showHud(self)
    resetTimeout(self)
    startWatcher(self)
  end

  function modal:exit()
    if not self._state then
      return
    end

    stopTimeout(self)
    stopKeyWatcher(self)
    hideHud(self)
    self._state = nil
    self._actionRan = false
  end

  modal._hotkey = hotkey.bind({}, key, function()
    modal:enterHeld()
  end, function()
    if modal._state ~= "held" then
      return
    end

    if modal._actionRan then
      modal:exit()
    else
      modal:enterOneshot()
    end
  end)

  return modal
end

function pseudoModifier.bind(modal, mods, key, fn)
  modal._bindings[#modal._bindings + 1] = {
    fn = fn,
    keyCode = keycodes.map[key],
    mods = normalizeMods(mods),
  }
end

return pseudoModifier
