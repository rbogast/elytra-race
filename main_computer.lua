-- main_computer.lua
-- Main race computer - manages the entire race system

local config = require("config")
local utils = require("utils")
local db = require("database")

------------------------------------------------
-- PERIPHERALS
------------------------------------------------
local FALSE_START_SIDE = "back"  -- Redstone side for Integrated Dynamics false start detection
local START_LINE_SIDE = "left"   -- Redstone side for start line trigger
local modem = peripheral.find("ender_modem")

if not modem then
  error("No ender modem found! Please attach an ender modem.")
end

-- Open all channels
modem.open(config.CHANNEL_GATE_TO_MAIN)

------------------------------------------------
-- RACE STATE
------------------------------------------------
local raceState = {
  status = "IDLE",  -- IDLE, ARMED, RUNNING, FINISHED
  player = nil,
  startTime = nil,
  finishTime = nil,
  falseStart = false,
  gatesPassed = {},  -- table of gate numbers passed
  comparisonMode = config.COMPARISON_MODE.COURSE_RECORD,
  comparisonTime = nil,
  comparisonSplit = nil
}

------------------------------------------------
-- INITIALIZATION
------------------------------------------------
print("=== ELYTRA RACE - MAIN COMPUTER ===")
print("Loading database...")
db.load()
print("Database loaded.")
print("")
print("Commands:")
print("  arm <player> - Arm the course for a player")
print("  mode <personal|course|daily> - Set comparison mode")
print("  reset - Reset current race")
print("  top10 - Show top 10 times")
print("  clear - Clear all data (admin)")
print("")

------------------------------------------------
-- HELPER FUNCTIONS
------------------------------------------------

local function nowMs()
  return os.epoch("utc")
end

local function logEvent(message)
  local timeStr = "00:00.000"
  if raceState.status == "RUNNING" and raceState.startTime then
    local elapsed = nowMs() - raceState.startTime
    timeStr = utils.formatTime(elapsed)
  end
  
  local fullMessage = timeStr .. " - " .. message
  print(fullMessage)
end

local function resetRace()
  raceState = {
    status = "IDLE",
    player = nil,
    startTime = nil,
    finishTime = nil,
    falseStart = false,
    gatesPassed = {},
    comparisonMode = raceState.comparisonMode,  -- Keep comparison mode
    comparisonTime = nil,
    comparisonSplit = nil
  }
  
  -- Notify all gates to reset
  modem.transmit(config.CHANNEL_MAIN_TO_GATES, 0, {type = "reset"})
  
  print("Race reset.")
end

local function armRace(playerName)
  if raceState.status ~= "IDLE" then
    print("Cannot arm - race already in progress. Use 'reset' first.")
    return
  end
  
  raceState.status = "ARMED"
  raceState.player = playerName
  raceState.gatesPassed = {}
  raceState.falseStart = false
  
  -- Get comparison times based on mode
  raceState.comparisonTime = db.getComparisonTime(playerName, raceState.comparisonMode)
  raceState.comparisonSplit = db.getComparisonSplit(config.SPLIT_GATE_NUMBER, playerName, raceState.comparisonMode)
  
  print("=== RACE ARMED ===")
  print("Player: " .. playerName)
  print("Comparison Mode: " .. raceState.comparisonMode)
  if raceState.comparisonTime then
    print("Target Time: " .. utils.formatTime(raceState.comparisonTime))
  else
    print("No comparison time available")
  end
  print("")
  print("Waiting for start...")
end

local function startRace()
  if raceState.status ~= "ARMED" then
    return
  end
  
  raceState.status = "RUNNING"
  raceState.startTime = nowMs()
  
  logEvent("RACE STARTED" .. (raceState.falseStart and " - FALSE START!" or ""))
  
  -- Send start signal to split and finish displays
  modem.transmit(config.CHANNEL_MAIN_TO_SPLIT, 0, {
    type = "race_start",
    player = raceState.player,
    comparison = raceState.comparisonSplit
  })
  
  modem.transmit(config.CHANNEL_MAIN_TO_FINISH, 0, {
    type = "race_start",
    player = raceState.player,
    comparison = raceState.comparisonTime
  })
end

local function onGatePassed(gateNumber, playerName, timestamp)
  -- Only process if race is running and for the current player
  if raceState.status ~= "RUNNING" or playerName ~= raceState.player then
    return
  end
  
  -- Check if gate already passed
  for _, g in ipairs(raceState.gatesPassed) do
    if g == gateNumber then
      return  -- Already passed this gate
    end
  end
  
  -- Record gate passage
  table.insert(raceState.gatesPassed, gateNumber)
  
  local elapsed = timestamp - raceState.startTime
  logEvent("GATE " .. gateNumber .. " PASSED")
  
  -- If this is the split gate, send update
  if gateNumber == config.SPLIT_GATE_NUMBER then
    modem.transmit(config.CHANNEL_MAIN_TO_SPLIT, 0, {
      type = "split_time",
      time = elapsed
    })
    
    -- Update split time in database
    db.updateSplitTime(gateNumber, elapsed, playerName)
  end
end

local function finishRace()
  if raceState.status ~= "RUNNING" then
    return
  end
  
  raceState.status = "FINISHED"
  raceState.finishTime = nowMs()
  
  local rawTime = raceState.finishTime - raceState.startTime
  logEvent("FINISHED!")
  
  -- Calculate penalties
  local penalties = {
    false_start = raceState.falseStart,
    missed_gates = {}
  }
  
  local penaltyTime = 0
  
  if raceState.falseStart then
    penaltyTime = penaltyTime + config.FALSE_START_PENALTY
    logEvent("False start penalty: +" .. (config.FALSE_START_PENALTY / 1000) .. " seconds")
  end
  
  -- Check for missed gates
  local missedCount = 0
  for g = 1, config.TOTAL_GATES do
    local found = false
    for _, passed in ipairs(raceState.gatesPassed) do
      if passed == g then
        found = true
        break
      end
    end
    if not found then
      table.insert(penalties.missed_gates, g)
      missedCount = missedCount + 1
    end
  end
  
  if missedCount > 0 then
    local gatePenalty = missedCount * config.MISSED_GATE_PENALTY
    penaltyTime = penaltyTime + gatePenalty
    logEvent("Missed " .. missedCount .. " gate(s): +" .. (gatePenalty / 1000) .. " seconds")
    logEvent("Missed gates: " .. table.concat(penalties.missed_gates, ", "))
  end
  
  local finalTime = rawTime + penaltyTime
  
  print("")
  print("=== FINAL RESULTS ===")
  print("Raw Time:   " .. utils.formatTime(rawTime))
  print("Penalties:  +" .. utils.formatTime(penaltyTime))
  print("Final Time: " .. utils.formatTime(finalTime))
  print("")
  
  -- Save to database
  db.addRun(raceState.player, finalTime, penalties)
  print("Result saved to database.")
  
  -- Send finish data to displays
  modem.transmit(config.CHANNEL_MAIN_TO_FINISH, 0, {
    type = "race_finish",
    time = finalTime
  })
  
  -- Update leaderboard
  modem.transmit(config.CHANNEL_MAIN_TO_LEADERBOARD, 0, {
    type = "update"
  })
  
  print("")
  print("Type 'reset' to prepare for next race.")
end

local function showTop10()
  local top = db.getTopTimes(10)
  print("")
  print("=== TOP 10 TIMES ===")
  for i, entry in ipairs(top) do
    print(string.format("%2d. %-16s %s", i, entry.player, utils.formatTime(entry.time)))
  end
  print("")
end

local function setComparisonMode(mode)
  if mode == "personal" then
    raceState.comparisonMode = config.COMPARISON_MODE.PERSONAL_BEST
    print("Comparison mode: Personal Best")
  elseif mode == "course" then
    raceState.comparisonMode = config.COMPARISON_MODE.COURSE_RECORD
    print("Comparison mode: Course Record")
  elseif mode == "daily" then
    raceState.comparisonMode = config.COMPARISON_MODE.DAILY_BEST
    print("Comparison mode: Daily Best")
  else
    print("Invalid mode. Use: personal, course, or daily")
  end
end

------------------------------------------------
-- MAIN LOOP
------------------------------------------------

-- Update timer for live display
local updateTimer = os.startTimer(0.1)

while true do
  local event, p1, p2, p3, p4, p5 = os.pullEvent()
  
  if event == "timer" and p1 == updateTimer then
    -- Update split and finish displays with current time
    if raceState.status == "RUNNING" then
      local elapsed = nowMs() - raceState.startTime
      
      modem.transmit(config.CHANNEL_MAIN_TO_SPLIT, 0, {
        type = "update_time",
        time = elapsed
      })
      
      modem.transmit(config.CHANNEL_MAIN_TO_FINISH, 0, {
        type = "update_time",
        time = elapsed
      })
    end
    
    updateTimer = os.startTimer(0.1)
    
  elseif event == "redstone" then
    -- Check for start line trigger
    if redstone.getInput(START_LINE_SIDE) then
      if raceState.status == "ARMED" then
        startRace()
      elseif raceState.status == "RUNNING" then
        finishRace()
      end
    end
    
    -- Check for false start detection (Integrated Dynamics)
    if redstone.getInput(FALSE_START_SIDE) and raceState.status == "ARMED" then
      raceState.falseStart = true
      print("FALSE START DETECTED!")
    end
    
  elseif event == "modem_message" then
    local side, channel, replyChannel, message, distance = p1, p2, p3, p4, p5
    
    if channel == config.CHANNEL_GATE_TO_MAIN and type(message) == "table" then
      if message.type == "gate_passed" then
        onGatePassed(message.gate, message.player, message.timestamp)
      end
    end
    
  elseif event == "char" or event == "paste" then
    -- Handle single-line commands
    
  elseif event == "key" then
    if p1 == keys.enter then
      -- Process command from input
    end
  end
  
  -- Handle terminal input differently using read()
  if event == "term_resize" or event == "monitor_touch" then
    -- Handle terminal events
  end
end
