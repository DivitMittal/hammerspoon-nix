local window = require "hs.window"
window.animationDuration = 0

------
-- Window Paning
------
-- whole
local function maximizeCurrentWindow()
  local win = window.focusedWindow()
  if not win then
    return
  end
  win:maximize()
end

local function centerCurrentWindow()
  local win = window.focusedWindow()
  if not win then
    return
  end
  win:centerOnScreen()
end

-- halves
local function moveCurrentWindowToLeftHalf()
  local win = window.focusedWindow()
  if not win then
    return
  end
  local screenFrame = win:screen():frame()
  local newFrame = hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w / 2, screenFrame.h)
  win:setFrame(newFrame)
end

local function moveCurrentWindowToRightHalf()
  local win = window.focusedWindow()
  if not win then
    return
  end
  local screenFrame = win:screen():frame()
  local newFrame = hs.geometry.rect(screenFrame.x + screenFrame.w / 2, screenFrame.y, screenFrame.w / 2, screenFrame.h)
  win:setFrame(newFrame)
end

local function moveCurrentWindowToTopHalf()
  local win = window.focusedWindow()
  if not win then
    return
  end
  local screenFrame = win:screen():frame()
  local newFrame = hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w, screenFrame.h / 2)
  win:setFrame(newFrame)
end

local function moveCurrentWindowToBottomHalf()
  local win = window.focusedWindow()
  if not win then
    return
  end
  local screenFrame = win:screen():frame()
  local newFrame = hs.geometry.rect(screenFrame.x, screenFrame.y + screenFrame.h / 2, screenFrame.w, screenFrame.h / 2)
  win:setFrame(newFrame)
end

-- quarters
local function moveCurrentWindowToTopLeft()
  local win = window.focusedWindow()
  if not win then
    return
  end
  local screenFrame = win:screen():frame()
  local newFrame = hs.geometry.rect(screenFrame.x, screenFrame.y, screenFrame.w / 2, screenFrame.h / 2)
  win:setFrame(newFrame)
end

local function moveCurrentWindowToTopRight()
  local win = window.focusedWindow()
  if not win then
    return
  end
  local screenFrame = win:screen():frame()
  local newFrame =
    hs.geometry.rect(screenFrame.x + screenFrame.w / 2, screenFrame.y, screenFrame.w / 2, screenFrame.h / 2)
  win:setFrame(newFrame)
end

local function moveCurrentWindowToBottomLeft()
  local win = window.focusedWindow()
  if not win then
    return
  end
  local screenFrame = win:screen():frame()
  local newFrame =
    hs.geometry.rect(screenFrame.x, screenFrame.y + screenFrame.h / 2, screenFrame.w / 2, screenFrame.h / 2)
  win:setFrame(newFrame)
end

local function moveCurrentWindowToBottomRight()
  local win = window.focusedWindow()
  if not win then
    return
  end
  local screenFrame = win:screen():frame()
  local newFrame = hs.geometry.rect(
    screenFrame.x + screenFrame.w / 2,
    screenFrame.y + screenFrame.h / 2,
    screenFrame.w / 2,
    screenFrame.h / 2
  )
  win:setFrame(newFrame)
end

-- Binds
windowBind("0", nil, centerCurrentWindow)
windowBind("1", nil, moveCurrentWindowToBottomLeft)
windowBind("2", nil, moveCurrentWindowToBottomHalf)
windowBind("3", nil, moveCurrentWindowToBottomRight)
windowBind("4", nil, moveCurrentWindowToLeftHalf)
windowBind("5", nil, maximizeCurrentWindow)
windowBind("6", nil, moveCurrentWindowToRightHalf)
windowBind("7", nil, moveCurrentWindowToTopLeft)
windowBind("8", nil, moveCurrentWindowToTopHalf)
windowBind("9", nil, moveCurrentWindowToTopRight)
