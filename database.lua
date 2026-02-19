-- database.lua
-- Database management for race times

local config = require("config")
local utils = require("utils")

local db = {}

-- Database structure:
-- {
--   players = {
--     ["PlayerName"] = {
--       {time = 12345, date = "Day 1 12:34:56", timestamp = 123456789, penalties = {false_start = true, missed_gates = {3}}},
--       ...up to 20 entries
--     }
--   },
--   global_best = {time = 12345, player = "PlayerName", date = "..."},
--   daily_bests = {
--     [day_number] = {time = 12345, player = "PlayerName", date = "..."}
--   }
-- }

local data = {
  players = {},
  global_best = nil,
  daily_bests = {}
}

-- === INITIALIZATION ===

function db.load()
  local content = utils.readFile(config.DATABASE_FILE)
  if content then
    local success, loaded = pcall(textutils.unserialize, content)
    if success and loaded then
      data = loaded
      return true
    end
  end
  -- Initialize empty database
  data = {
    players = {},
    global_best = nil,
    daily_bests = {}
  }
  return false
end

function db.save()
  local serialized = textutils.serialize(data)
  utils.writeFile(config.DATABASE_FILE, serialized)
end

-- === ADD RACE RESULT ===

function db.addRun(playerName, timeMs, penalties)
  -- penalties is a table: {false_start = bool, missed_gates = {gate_nums...}}
  
  local entry = {
    time = timeMs,
    date = utils.getDateTimeString(),
    timestamp = os.epoch("utc"),
    penalties = penalties or {}
  }
  
  -- Initialize player if not exists
  if not data.players[playerName] then
    data.players[playerName] = {}
  end
  
  -- Add the run
  table.insert(data.players[playerName], entry)
  
  -- Sort by time (ascending)
  utils.sortByField(data.players[playerName], "time", false)
  
  -- Keep only top 20
  while #data.players[playerName] > config.MAX_RUNS_PER_PLAYER do
    table.remove(data.players[playerName])
  end
  
  -- Update global best
  if not data.global_best or timeMs < data.global_best.time then
    data.global_best = {
      time = timeMs,
      player = playerName,
      date = entry.date
    }
  end
  
  -- Update daily best
  local day = utils.getDateStamp()
  if not data.daily_bests[day] or timeMs < data.daily_bests[day].time then
    data.daily_bests[day] = {
      time = timeMs,
      player = playerName,
      date = entry.date
    }
  end
  
  db.save()
end

-- === QUERY FUNCTIONS ===

function db.getPlayerBest(playerName)
  if data.players[playerName] and #data.players[playerName] > 0 then
    return data.players[playerName][1].time
  end
  return nil
end

function db.getGlobalBest()
  if data.global_best then
    return data.global_best.time
  end
  return nil
end

function db.getDailyBest()
  local day = utils.getDateStamp()
  if data.daily_bests[day] then
    return data.daily_bests[day].time
  end
  return nil
end

-- Get comparison time based on mode
function db.getComparisonTime(playerName, mode)
  if mode == config.COMPARISON_MODE.PERSONAL_BEST then
    return db.getPlayerBest(playerName)
  elseif mode == config.COMPARISON_MODE.COURSE_RECORD then
    return db.getGlobalBest()
  elseif mode == config.COMPARISON_MODE.DAILY_BEST then
    return db.getDailyBest()
  end
  return nil
end

-- Get top 10 times across all players
function db.getTopTimes(limit)
  limit = limit or 10
  local allTimes = {}
  
  -- Collect all best times
  for playerName, runs in pairs(data.players) do
    if #runs > 0 then
      local best = runs[1]
      table.insert(allTimes, {
        player = playerName,
        time = best.time,
        date = best.date
      })
    end
  end
  
  -- Sort by time
  utils.sortByField(allTimes, "time", false)
  
  -- Return top N
  local result = {}
  for i = 1, math.min(limit, #allTimes) do
    table.insert(result, allTimes[i])
  end
  
  return result
end

-- Get all runs for a player
function db.getPlayerRuns(playerName)
  return data.players[playerName] or {}
end

-- === SPLIT TIME TRACKING ===
-- Store best split times for specific gates
data.split_times = data.split_times or {}

function db.updateSplitTime(gateNumber, timeMs, playerName)
  if not data.split_times[gateNumber] or timeMs < data.split_times[gateNumber].time then
    data.split_times[gateNumber] = {
      time = timeMs,
      player = playerName,
      date = utils.getDateTimeString()
    }
    db.save()
  end
end

function db.getSplitTime(gateNumber)
  if data.split_times[gateNumber] then
    return data.split_times[gateNumber].time
  end
  return nil
end

-- Get best split time based on comparison mode
function db.getComparisonSplit(gateNumber, playerName, mode)
  if mode == config.COMPARISON_MODE.PERSONAL_BEST then
    -- For personal best split, we'd need to track individual gate times per player
    -- For now, return course record split
    return db.getSplitTime(gateNumber)
  elseif mode == config.COMPARISON_MODE.COURSE_RECORD then
    return db.getSplitTime(gateNumber)
  elseif mode == config.COMPARISON_MODE.DAILY_BEST then
    -- Similar to personal best, use course record for now
    return db.getSplitTime(gateNumber)
  end
  return nil
end

-- === DEBUG/ADMIN ===

function db.clearAll()
  data = {
    players = {},
    global_best = nil,
    daily_bests = {},
    split_times = {}
  }
  db.save()
end

function db.getData()
  return data
end

return db
