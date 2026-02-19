-- split_display.lua
-- Large monitor display for split time at halfway point

local config = require("config")
local utils = require("utils")

------------------------------------------------
-- PERIPHERALS
------------------------------------------------
local modem = peripheral.find("ender_modem")
if not modem then
  error("No ender modem found! Please attach an ender modem.")
end

local monitor = peripheral.find("monitor")
if not monitor then
  error("No monitor found! Please attach a monitor.")
end

-- Open modem channel
modem.open(config.CHANNEL_MAIN_TO_SPLIT)

------------------------------------------------
-- STATE
------------------------------------------------
local state = {
  status = "WAITING",  -- WAITING, RUNNING, SPLIT_SHOWN
  currentTime = 0,
  comparisonTime = nil,  -- Target split time
  splitTime = nil,  -- Actual split time when gate is passed
  player = nil
}

------------------------------------------------
-- DISPLAY FUNCTIONS
------------------------------------------------

local function clearDisplay()
  utils.clearMonitor(monitor, colors.black)
end

local function drawSplitDisplay()
  clearDisplay()
  
  local w, h = monitor.getSize()
  monitor.setTextScale(config.TIMER_TEXT_SCALE)
  
  if state.status == "WAITING" then
    -- Display waiting message
    monitor.setCursorPos(1, math.floor(h / 2))
    local msg = "SPLIT TIMER - GATE " .. config.SPLIT_GATE_NUMBER
    local x = math.floor((w - #msg) / 2) + 1
    monitor.setCursorPos(x, math.floor(h / 2))
    monitor.write(msg)
    
  elseif state.status == "RUNNING" or state.status == "SPLIT_SHOWN" then
    -- Display current time (big)
    local displayTime = state.splitTime or state.currentTime
    local timeStr = utils.formatTime(displayTime)
    
    -- Draw big time in center
    utils.drawCenteredBig(monitor, timeStr, math.floor(h / 2) - 3, colors.white)
    
    -- Draw delta below if we have a comparison time
    if state.comparisonTime then
      local delta = displayTime - state.comparisonTime
      local deltaStr = utils.formatDelta(delta)
      
      -- Determine color (green if ahead, red if behind)
      local deltaColor = delta < 0 and config.COLOR_AHEAD or config.COLOR_BEHIND
      
      -- Draw delta text
      local deltaY = math.floor(h / 2) + 3
      utils.drawCenteredBig(monitor, deltaStr, deltaY, deltaColor)
    end
    
    -- Draw player name at top
    if state.player then
      monitor.setCursorPos(2, 2)
      monitor.setTextColor(colors.white)
      monitor.write("Player: " .. state.player)
    end
    
    -- Draw label at bottom
    if state.status == "SPLIT_SHOWN" then
      monitor.setCursorPos(2, h - 1)
      monitor.setTextColor(colors.yellow)
      monitor.write("SPLIT!")
    end
  end
end

------------------------------------------------
-- MESSAGE HANDLERS
------------------------------------------------

local function onRaceStart(message)
  state.status = "RUNNING"
  state.currentTime = 0
  state.comparisonTime = message.comparison
  state.splitTime = nil
  state.player = message.player
  
  drawSplitDisplay()
end

local function onUpdateTime(message)
  if state.status == "RUNNING" then
    state.currentTime = message.time
    drawSplitDisplay()
  end
end

local function onSplitTime(message)
  state.status = "SPLIT_SHOWN"
  state.splitTime = message.time
  
  drawSplitDisplay()
  
  -- After 5 seconds, reset to waiting
  os.startTimer(5)
end

------------------------------------------------
-- MAIN LOOP
------------------------------------------------

print("Split Timer Display - Gate " .. config.SPLIT_GATE_NUMBER)
print("Waiting for race data...")

clearDisplay()
drawSplitDisplay()

local renderTimer = os.startTimer(0.05)

while true do
  local event, p1, p2, p3, p4, p5 = os.pullEvent()
  
  if event == "timer" then
    if p1 == renderTimer then
      -- Smooth rendering for running timer
      if state.status == "RUNNING" then
        drawSplitDisplay()
      end
      renderTimer = os.startTimer(0.05)
    else
      -- Reset timer (after showing split)
      if state.status == "SPLIT_SHOWN" then
        state.status = "WAITING"
        state.currentTime = 0
        state.splitTime = nil
        state.comparisonTime = nil
        state.player = nil
        drawSplitDisplay()
      end
    end
    
  elseif event == "modem_message" then
    local side, channel, replyChannel, message, distance = p1, p2, p3, p4, p5
    
    if channel == config.CHANNEL_MAIN_TO_SPLIT and type(message) == "table" then
      if message.type == "race_start" then
        onRaceStart(message)
      elseif message.type == "update_time" then
        onUpdateTime(message)
      elseif message.type == "split_time" then
        onSplitTime(message)
      end
    end
  end
end
