-- gate.lua
-- Program for gate computers with player detectors
-- Each gate listens for players and reports to the main computer

local config = require("config")

------------------------------------------------
-- GATE CONFIGURATION
------------------------------------------------
local GATE_NUMBER = 1  -- CHANGE THIS FOR EACH GATE (1-15)
------------------------------------------------

-- Find peripherals
local modem = peripheral.find("ender_modem")
if not modem then
  error("No ender modem found! Please attach an ender modem.")
end

local detector = peripheral.find("playerDetector")
if not detector then
  error("No player detector found! Please attach a player detector from Advanced Peripherals.")
end

-- Optional: Find monitor for gate number display
local monitor = peripheral.find("monitor")

-- Open modem channels
modem.open(config.CHANNEL_MAIN_TO_GATES)

print("Gate " .. GATE_NUMBER .. " initialized")
print("Listening for players...")

-- Display gate number on monitor if available
if monitor then
  monitor.setTextScale(2)
  monitor.setBackgroundColor(colors.black)
  monitor.setTextColor(colors.white)
  monitor.clear()
  
  local w, h = monitor.getSize()
  local text = tostring(GATE_NUMBER)
  local x = math.floor((w - #text) / 2) + 1
  local y = math.floor(h / 2)
  monitor.setCursorPos(x, y)
  monitor.write(text)
end

-- Track recently detected players to avoid duplicate detections
local recentPlayers = {}
local COOLDOWN_TIME = 2  -- seconds before same player can trigger again

local function cleanupRecentPlayers()
  local now = os.epoch("utc")
  for player, timestamp in pairs(recentPlayers) do
    if (now - timestamp) > (COOLDOWN_TIME * 1000) then
      recentPlayers[player] = nil
    end
  end
end

local function onPlayerDetected(playerName)
  local now = os.epoch("utc")
  
  -- Check cooldown
  if recentPlayers[playerName] then
    return  -- Player detected too recently
  end
  
  -- Mark player as recently detected
  recentPlayers[playerName] = now
  
  -- Send message to main computer
  modem.transmit(config.CHANNEL_GATE_TO_MAIN, GATE_NUMBER, {
    type = "gate_passed",
    gate = GATE_NUMBER,
    player = playerName,
    timestamp = now
  })
  
  print("[" .. os.date("%H:%M:%S") .. "] Player detected: " .. playerName)
  
  -- Visual feedback on monitor if available
  if monitor then
    monitor.setTextColor(colors.lime)
    monitor.setCursorPos(1, h)
    monitor.clearLine()
    monitor.write(playerName:sub(1, w))
    
    -- Reset color after a moment
    os.startTimer(1)
  end
end

-- Main event loop
while true do
  local event, p1, p2, p3, p4, p5 = os.pullEvent()
  
  if event == "timer" then
    -- Reset monitor color
    if monitor then
      monitor.setTextColor(colors.white)
    end
    -- Cleanup old entries
    cleanupRecentPlayers()
    
  elseif event == "modem_message" then
    -- Messages from main computer (control commands)
    local side, channel, replyChannel, message, distance = p1, p2, p3, p4, p5
    
    if channel == config.CHANNEL_MAIN_TO_GATES and type(message) == "table" then
      if message.type == "reset" then
        -- Clear recent players on race reset
        recentPlayers = {}
        print("Race reset - cleared recent detections")
      end
    end
    
  else
    -- Check for players in range using Advanced Peripherals
    local players = detector.getPlayersInRange(16)  -- 16 block range
    
    if players and #players > 0 then
      for _, playerName in ipairs(players) do
        onPlayerDetected(playerName)
      end
    end
  end
end
