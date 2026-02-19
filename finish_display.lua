-- finish_display.lua
-- Large monitor display for finish line

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
modem.open(config.CHANNEL_MAIN_TO_FINISH)

------------------------------------------------
-- STATE
------------------------------------------------
local state = {
  status = "WAITING",  -- WAITING, RUNNING, FINISHED
  currentTime = 0,
  comparisonTime = nil,  -- Target finish time
  finalTime = nil,  -- Actual finish time
  player = nil
}

------------------------------------------------
-- DISPLAY FUNCTIONS
------------------------------------------------

local function clearDisplay()
  utils.clearMonitor(monitor, colors.black)
end

local function drawFinishDisplay()
  clearDisplay()
  
  local w, h = monitor.getSize()
  monitor.setTextScale(config.TIMER_TEXT_SCALE)
  
  if state.status == "WAITING" then
    -- Display waiting message
    local msg = "FINISH LINE"
    local x = math.floor((w - #msg) / 2) + 1
    monitor.setCursorPos(x, math.floor(h / 2))
    monitor.write(msg)
    
  elseif state.status == "RUNNING" or state.status == "FINISHED" then
    -- Display current time (big)
    local displayTime = state.finalTime or state.currentTime
    local timeStr = utils.formatTime(displayTime)
    
    -- Draw big time in center
    utils.drawCenteredBig(monitor, timeStr, math.floor(h / 2) - 3, colors.white)
    
    -- Draw delta below if we have a comparison time
    if state.comparisonTime then
      local delta = displayTime - state.comparisonTime
      local deltaStr = utils.formatDelta(delta)
      
      -- Determine color (green if ahead/faster, red if behind/slower)
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
    
    -- Draw status at bottom
    if state.status == "FINISHED" then
      monitor.setCursorPos(2, h - 1)
      monitor.setTextColor(colors.lime)
      monitor.write("FINISHED!")
    elseif state.status == "RUNNING" then
      monitor.setCursorPos(2, h - 1)
      monitor.setTextColor(colors.yellow)
      monitor.write("RUNNING...")
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
  state.finalTime = nil
  state.player = message.player
  
  drawFinishDisplay()
end

local function onUpdateTime(message)
  if state.status == "RUNNING" then
    state.currentTime = message.time
    drawFinishDisplay()
  end
end

local function onRaceFinish(message)
  state.status = "FINISHED"
  state.finalTime = message.time
  
  drawFinishDisplay()
  
  -- After 10 seconds, reset to waiting
  os.startTimer(10)
end

------------------------------------------------
-- MAIN LOOP
------------------------------------------------

print("Finish Line Display")
print("Waiting for race data...")

clearDisplay()
drawFinishDisplay()

local renderTimer = os.startTimer(0.05)

while true do
  local event, p1, p2, p3, p4, p5 = os.pullEvent()
  
  if event == "timer" then
    if p1 == renderTimer then
      -- Smooth rendering for running timer
      if state.status == "RUNNING" then
        drawFinishDisplay()
      end
      renderTimer = os.startTimer(0.05)
    else
      -- Reset timer (after showing finish)
      if state.status == "FINISHED" then
        state.status = "WAITING"
        state.currentTime = 0
        state.finalTime = nil
        state.comparisonTime = nil
        state.player = nil
        drawFinishDisplay()
      end
    end
    
  elseif event == "modem_message" then
    local side, channel, replyChannel, message, distance = p1, p2, p3, p4, p5
    
    if channel == config.CHANNEL_MAIN_TO_FINISH and type(message) == "table" then
      if message.type == "race_start" then
        onRaceStart(message)
      elseif message.type == "update_time" then
        onUpdateTime(message)
      elseif message.type == "race_finish" then
        onRaceFinish(message)
      end
    end
  end
end
