-- setup.lua
-- Interactive setup and race control interface

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

modem.open(config.CHANNEL_GATE_TO_MAIN)

------------------------------------------------
-- RACE STATE (shared with main computer)
------------------------------------------------
local FALSE_START_SIDE = "back"
local START_LINE_SIDE = "left"

local raceState = {
  status = "IDLE",
  player = nil,
  startTime = nil,
  finishTime = nil,
  falseStart = false,
  gatesPassed = {},
  comparisonMode = config.COMPARISON_MODE.COURSE_RECORD,
  comparisonTime = nil,
  comparisonSplit = nil
}

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
  print(timeStr .. " - " .. message)
end

local function resetRace()
  raceState = {
    status = "IDLE",
    player = nil,
    startTime = nil,
    finishTime = nil,
    falseStart = false,
    gatesPassed = {},
    comparisonMode = raceState.comparisonMode,
    comparisonTime = nil,
    comparisonSplit = nil
  }
  modem.transmit(config.CHANNEL_MAIN_TO_GATES, 0, {type = "reset"})
  print("\nRace reset.\n")
end

local function armRace(playerName)
  if raceState.status ~= "IDLE" then
    print("Cannot arm - race in progress. Reset first.")
    return
  end
  
  raceState.status = "ARMED"
  raceState.player = playerName
  raceState.gatesPassed = {}
  raceState.falseStart = false
  
  raceState.comparisonTime = db.getComparisonTime(playerName, raceState.comparisonMode)
  raceState.comparisonSplit = db.getComparisonSplit(config.SPLIT_GATE_NUMBER, playerName, raceState.comparisonMode)
  
  print("\n=== RACE ARMED ===")
  print("Player: " .. playerName)
  print("Mode: " .. raceState.comparisonMode)
  if raceState.comparisonTime then
    print("Target: " .. utils.formatTime(raceState.comparisonTime))
  end
  print("Waiting for start...\n")
end

local function startRace()
  if raceState.status ~= "ARMED" then return end
  
  raceState.status = "RUNNING"
  raceState.startTime = nowMs()
  
  logEvent("RACE STARTED" .. (raceState.falseStart and " - FALSE START!" or ""))
  
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
  if raceState.status ~= "RUNNING" or playerName ~= raceState.player then
    return
  end
  
  for _, g in ipairs(raceState.gatesPassed) do
    if g == gateNumber then return end
  end
  
  table.insert(raceState.gatesPassed, gateNumber)
  local elapsed = timestamp - raceState.startTime
  logEvent("GATE " .. gateNumber .. " PASSED")
  
  if gateNumber == config.SPLIT_GATE_NUMBER then
    modem.transmit(config.CHANNEL_MAIN_TO_SPLIT, 0, {
      type = "split_time",
      time = elapsed
    })
    db.updateSplitTime(gateNumber, elapsed, playerName)
  end
end

local function finishRace()
  if raceState.status ~= "RUNNING" then return end
  
  raceState.status = "FINISHED"
  raceState.finishTime = nowMs()
  
  local rawTime = raceState.finishTime - raceState.startTime
  logEvent("FINISHED!")
  
  local penalties = {
    false_start = raceState.falseStart,
    missed_gates = {}
  }
  
  local penaltyTime = 0
  
  if raceState.falseStart then
    penaltyTime = penaltyTime + config.FALSE_START_PENALTY
    logEvent("False start: +" .. (config.FALSE_START_PENALTY / 1000) .. "s")
  end
  
  for g = 1, config.TOTAL_GATES do
    local found = false
    for _, passed in ipairs(raceState.gatesPassed) do
      if passed == g then found = true; break end
    end
    if not found then
      table.insert(penalties.missed_gates, g)
    end
  end
  
  if #penalties.missed_gates > 0 then
    local gatePenalty = #penalties.missed_gates * config.MISSED_GATE_PENALTY
    penaltyTime = penaltyTime + gatePenalty
    logEvent("Missed " .. #penalties.missed_gates .. " gates: +" .. (gatePenalty / 1000) .. "s")
    logEvent("Missed: " .. table.concat(penalties.missed_gates, ", "))
  end
  
  local finalTime = rawTime + penaltyTime
  
  print("\n=== FINAL RESULTS ===")
  print("Raw Time:   " .. utils.formatTime(rawTime))
  print("Penalties:  +" .. utils.formatTime(penaltyTime))
  print("Final Time: " .. utils.formatTime(finalTime))
  
  db.addRun(raceState.player, finalTime, penalties)
  print("Saved to database.\n")
  
  modem.transmit(config.CHANNEL_MAIN_TO_FINISH, 0, {
    type = "race_finish",
    time = finalTime
  })
  
  modem.transmit(config.CHANNEL_MAIN_TO_LEADERBOARD, 0, {type = "update"})
end

------------------------------------------------
-- MENU SYSTEM
------------------------------------------------

local function drawMenu()
  term.clear()
  term.setCursorPos(1, 1)
  print("=== ELYTRA RACE CONTROL ===")
  print("")
  print("Status: " .. raceState.status)
  if raceState.player then
    print("Player: " .. raceState.player)
  end
  print("Comparison Mode: " .. raceState.comparisonMode)
  print("")
  print("Commands:")
  print("  1 - Arm Race")
  print("  2 - Set Comparison Mode")
  print("  3 - Reset Race")
  print("  4 - View Top 10")
  print("  5 - View Player Stats")
  print("  Q - Quit to monitoring mode")
  print("")
  write("> ")
end

local function showTop10()
  term.clear()
  term.setCursorPos(1, 1)
  print("=== TOP 10 TIMES ===\n")
  
  local top = db.getTopTimes(10)
  if #top == 0 then
    print("No times recorded yet.\n")
  else
    for i, entry in ipairs(top) do
      print(string.format("%2d. %-16s %s", i, entry.player, utils.formatTime(entry.time)))
    end
  end
  
  print("\nPress any key to continue...")
  os.pullEvent("key")
end

local function showPlayerStats()
  term.clear()
  term.setCursorPos(1, 1)
  write("Enter player name: ")
  local playerName = read()
  
  if playerName == "" then return end
  
  local runs = db.getPlayerRuns(playerName)
  
  term.clear()
  term.setCursorPos(1, 1)
  print("=== " .. playerName .. " ===\n")
  
  if #runs == 0 then
    print("No runs recorded.\n")
  else
    print("Best: " .. utils.formatTime(runs[1].time))
    print("\nAll runs:")
    for i, run in ipairs(runs) do
      print(string.format("%2d. %s - %s", i, utils.formatTime(run.time), run.date))
    end
  end
  
  print("\nPress any key to continue...")
  os.pullEvent("key")
end

local function setComparisonMode()
  term.clear()
  term.setCursorPos(1, 1)
  print("=== SET COMPARISON MODE ===\n")
  print("1 - Personal Best")
  print("2 - Course Record")
  print("3 - Daily Best")
  print("")
  write("> ")
  
  local choice = read()
  
  if choice == "1" then
    raceState.comparisonMode = config.COMPARISON_MODE.PERSONAL_BEST
  elseif choice == "2" then
    raceState.comparisonMode = config.COMPARISON_MODE.COURSE_RECORD
  elseif choice == "3" then
    raceState.comparisonMode = config.COMPARISON_MODE.DAILY_BEST
  end
end

------------------------------------------------
-- INITIALIZATION
------------------------------------------------

print("Loading database...")
db.load()
print("Database loaded.\n")

local monitoringMode = false

------------------------------------------------
-- MAIN LOOP
------------------------------------------------

local updateTimer = os.startTimer(0.1)

while true do
  if not monitoringMode then
    drawMenu()
    local choice = read()
    
    if choice == "1" then
      term.clear()
      term.setCursorPos(1, 1)
      write("Enter player name: ")
      local playerName = read()
      if playerName ~= "" then
        armRace(playerName)
        monitoringMode = true
      end
    elseif choice == "2" then
      setComparisonMode()
    elseif choice == "3" then
      resetRace()
    elseif choice == "4" then
      showTop10()
    elseif choice == "5" then
      showPlayerStats()
    elseif choice:lower() == "q" then
      monitoringMode = true
      term.clear()
      term.setCursorPos(1, 1)
      print("=== MONITORING MODE ===")
      print("Press M for menu\n")
    end
  else
    local event, p1, p2, p3, p4, p5 = os.pullEvent()
    
    if event == "timer" and p1 == updateTimer then
      if raceState.status == "RUNNING" then
        local elapsed = nowMs() - raceState.startTime
        modem.transmit(config.CHANNEL_MAIN_TO_SPLIT, 0, {type = "update_time", time = elapsed})
        modem.transmit(config.CHANNEL_MAIN_TO_FINISH, 0, {type = "update_time", time = elapsed})
      end
      updateTimer = os.startTimer(0.1)
      
    elseif event == "redstone" then
      if redstone.getInput(START_LINE_SIDE) then
        if raceState.status == "ARMED" then
          startRace()
        elseif raceState.status == "RUNNING" then
          finishRace()
        end
      end
      
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
      
    elseif event == "char" then
      if p1:lower() == "m" then
        monitoringMode = false
      end
    end
  end
end
