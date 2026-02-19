-- config.lua
-- Central configuration for the elytra race system

local config = {}

-- === SYSTEM IDENTIFIERS ===
config.MAIN_COMPUTER_ID = 0  -- Set this to the main computer's ID
config.SPLIT_GATE_NUMBER = 8  -- Which gate has the split timer (halfway point)
config.TOTAL_GATES = 15

-- === MODEM CHANNELS ===
config.CHANNEL_GATE_TO_MAIN = 100  -- Gates send to main on this channel
config.CHANNEL_MAIN_TO_GATES = 101  -- Main broadcasts to gates on this channel
config.CHANNEL_MAIN_TO_SPLIT = 102  -- Main sends split data to split timer
config.CHANNEL_MAIN_TO_FINISH = 103  -- Main sends finish data to finish line
config.CHANNEL_MAIN_TO_LEADERBOARD = 104  -- Main sends leaderboard updates

-- === PENALTIES (in milliseconds) ===
config.FALSE_START_PENALTY = 3000  -- 3 seconds
config.MISSED_GATE_PENALTY = 5000  -- 5 seconds

-- === DATABASE SETTINGS ===
config.MAX_RUNS_PER_PLAYER = 20  -- Keep top 20 times per player
config.DATABASE_FILE = "race_database.txt"

-- === COMPARISON MODES ===
config.COMPARISON_MODE = {
  PERSONAL_BEST = "personal_best",
  COURSE_RECORD = "course_record",
  DAILY_BEST = "daily_best"
}

-- === MONITOR SETTINGS ===
config.TIMER_TEXT_SCALE = 0.5  -- For large timer displays
config.LEADERBOARD_TEXT_SCALE = 1.0

-- === COLORS ===
config.COLOR_AHEAD = colors.green
config.COLOR_BEHIND = colors.red
config.COLOR_NEUTRAL = colors.white

return config
