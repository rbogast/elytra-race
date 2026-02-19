-- utils.lua
-- Utility functions for the elytra race system

local utils = {}

-- === TIME FORMATTING ===

-- Format milliseconds to MM:SS.sss
function utils.formatTime(ms)
  if ms < 0 then ms = 0 end
  local totalSeconds = ms / 1000
  local minutes = math.floor(totalSeconds / 60)
  local seconds = totalSeconds - (minutes * 60)
  return string.format("%02d:%06.3f", minutes, seconds)
end

-- Format milliseconds to a delta string with sign
function utils.formatDelta(ms)
  local sign = ""
  if ms > 0 then
    sign = "+"
  elseif ms < 0 then
    sign = "-"
    ms = -ms
  end
  
  local seconds = ms / 1000
  return string.format("%s%.3f", sign, seconds)
end

-- === BIG DIGIT FONT (3x5) for monitors ===

utils.FONT = {
  ["0"] = {"\x7f\x7f\x7f", "\x7f \x7f", "\x7f \x7f", "\x7f \x7f", "\x7f\x7f\x7f"},
  ["1"] = {" \x7f\x7f", "  \x7f", "  \x7f", "  \x7f", " \x7f\x7f\x7f"},
  ["2"] = {"\x7f\x7f\x7f", "  \x7f", "\x7f\x7f\x7f", "\x7f  ", "\x7f\x7f\x7f"},
  ["3"] = {"\x7f\x7f\x7f", "  \x7f", "\x7f\x7f\x7f", "  \x7f", "\x7f\x7f\x7f"},
  ["4"] = {"\x7f \x7f", "\x7f \x7f", "\x7f\x7f\x7f", "  \x7f", "  \x7f"},
  ["5"] = {"\x7f\x7f\x7f", "\x7f  ", "\x7f\x7f\x7f", "  \x7f", "\x7f\x7f\x7f"},
  ["6"] = {"\x7f\x7f\x7f", "\x7f  ", "\x7f\x7f\x7f", "\x7f \x7f", "\x7f\x7f\x7f"},
  ["7"] = {"\x7f\x7f\x7f", "  \x7f", "  \x7f", "  \x7f", "  \x7f"},
  ["8"] = {"\x7f\x7f\x7f", "\x7f \x7f", "\x7f\x7f\x7f", "\x7f \x7f", "\x7f\x7f\x7f"},
  ["9"] = {"\x7f\x7f\x7f", "\x7f \x7f", "\x7f\x7f\x7f", "  \x7f", "\x7f\x7f\x7f"},
  ["."] = {"   ", "   ", "   ", "   ", "  \x7f"},
  [":"] = {"   ", " \x7f ", "   ", " \x7f ", "   "},
  [" "] = {"   ", "   ", "   ", "   ", "   "},
  ["-"] = {"   ", "   ", "\x7f\x7f\x7f", "   ", "   "},
  ["+"] = {"   ", " \x7f ", "\x7f\x7f\x7f", " \x7f ", "   "},
}

-- Draw big text centered on a monitor
function utils.drawCenteredBig(mon, text, y, textColor)
  if textColor then
    mon.setTextColor(textColor)
  end
  
  local w, h = mon.getSize()
  local rows = 5
  local glyphW = 3
  local gap = 1

  local textW = (#text * glyphW) + ((#text - 1) * gap)
  local startX = math.max(1, math.floor((w - textW) / 2) + 1)
  local startY = y or math.floor((h - rows) / 2)

  for r = 1, rows do
    local x = startX
    for i = 1, #text do
      local ch = text:sub(i, i)
      local g = utils.FONT[ch] or utils.FONT[" "]
      mon.setCursorPos(x, startY + (r - 1))
      mon.write(g[r])
      x = x + glyphW + gap
    end
  end
  
  if textColor then
    mon.setTextColor(colors.white)
  end
end

-- === MONITOR HELPERS ===

function utils.clearMonitor(mon, bgColor)
  mon.setBackgroundColor(bgColor or colors.black)
  mon.setTextColor(colors.white)
  mon.clear()
  mon.setCursorPos(1, 1)
end

-- === DATE/TIME ===

function utils.getDateTimeString()
  -- Returns formatted date/time string
  local time = os.epoch("utc")
  local days = math.floor(time / 86400000)
  local hours = math.floor((time % 86400000) / 3600000)
  local minutes = math.floor((time % 3600000) / 60000)
  local seconds = math.floor((time % 60000) / 1000)
  
  return string.format("Day %d %02d:%02d:%02d", days, hours, minutes, seconds)
end

function utils.getDateStamp()
  -- Returns just the day number
  local time = os.epoch("utc")
  return math.floor(time / 86400000)
end

-- === TABLE UTILITIES ===

-- Deep copy a table
function utils.deepCopy(orig)
  local copy
  if type(orig) == 'table' then
    copy = {}
    for k, v in pairs(orig) do
      copy[k] = utils.deepCopy(v)
    end
  else
    copy = orig
  end
  return copy
end

-- Sort table by a field
function utils.sortByField(tbl, field, descending)
  table.sort(tbl, function(a, b)
    if descending then
      return a[field] > b[field]
    else
      return a[field] < b[field]
    end
  end)
end

-- === FILE I/O ===

function utils.fileExists(filename)
  local file = fs.exists(filename)
  return file
end

function utils.readFile(filename)
  if not fs.exists(filename) then
    return nil
  end
  
  local file = fs.open(filename, "r")
  local content = file.readAll()
  file.close()
  return content
end

function utils.writeFile(filename, content)
  local file = fs.open(filename, "w")
  file.write(content)
  file.close()
end

return utils
