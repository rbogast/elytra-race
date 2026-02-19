-- leaderboard.lua
-- Leaderboard display for top 10 times

local config = require("config")
local utils = require("utils")
local db = require("database")

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
modem.open(config.CHANNEL_MAIN_TO_LEADERBOARD)

------------------------------------------------
-- DISPLAY FUNCTIONS
------------------------------------------------

local function drawLeaderboard()
  utils.clearMonitor(monitor, colors.black)
  
  monitor.setTextScale(config.LEADERBOARD_TEXT_SCALE)
  local w, h = monitor.getSize()
  
  -- Title
  monitor.setCursorPos(1, 1)
  monitor.setTextColor(colors.yellow)
  local title = "=== TOP 10 TIMES ==="
  local titleX = math.floor((w - #title) / 2) + 1
  monitor.setCursorPos(titleX, 1)
  monitor.write(title)
  
  -- Get top 10 times
  local topTimes = db.getTopTimes(10)
  
  if #topTimes == 0 then
    monitor.setTextColor(colors.gray)
    monitor.setCursorPos(1, 3)
    monitor.write("No times recorded yet")
    return
  end
  
  -- Header
  monitor.setCursorPos(1, 3)
  monitor.setTextColor(colors.lightGray)
  monitor.write("#  Player           Time")
  
  -- Times
  for i, entry in ipairs(topTimes) do
    local y = 4 + i
    if y > h then break end
    
    monitor.setCursorPos(1, y)
    
    -- Rank color
    if i == 1 then
      monitor.setTextColor(colors.gold or colors.yellow)
    elseif i == 2 then
      monitor.setTextColor(colors.lightGray)
    elseif i == 3 then
      monitor.setTextColor(colors.orange)
    else
      monitor.setTextColor(colors.white)
    end
    
    -- Format: "1  PlayerName      01:23.456"
    local rank = string.format("%2d", i)
    local player = entry.player
    if #player > 16 then
      player = player:sub(1, 13) .. "..."
    end
    player = player .. string.rep(" ", 16 - #player)
    
    local timeStr = utils.formatTime(entry.time)
    
    monitor.write(rank .. " " .. player .. " " .. timeStr)
  end
  
  -- Footer with last update time
  monitor.setCursorPos(1, h)
  monitor.setTextColor(colors.gray)
  monitor.write("Updated: " .. os.date("%H:%M:%S"))
end

------------------------------------------------
-- INITIALIZATION
------------------------------------------------

print("Leaderboard Display")
print("Loading database...")
db.load()
print("Database loaded.")

drawLeaderboard()

-- Auto-refresh timer
local refreshTimer = os.startTimer(30)  -- Refresh every 30 seconds

------------------------------------------------
-- MAIN LOOP
------------------------------------------------

while true do
  local event, p1, p2, p3, p4, p5 = os.pullEvent()
  
  if event == "timer" and p1 == refreshTimer then
    -- Auto-refresh
    db.load()  -- Reload database
    drawLeaderboard()
    refreshTimer = os.startTimer(30)
    
  elseif event == "modem_message" then
    local side, channel, replyChannel, message, distance = p1, p2, p3, p4, p5
    
    if channel == config.CHANNEL_MAIN_TO_LEADERBOARD and type(message) == "table" then
      if message.type == "update" then
        -- Reload database and redraw
        db.load()
        drawLeaderboard()
      end
    end
    
  elseif event == "monitor_touch" then
    -- Manual refresh on touch
    db.load()
    drawLeaderboard()
  end
end
