-- gatenum.lua
-- Displays a large gate number on a 1x1 monitor

------------------------------------------------
-- CONFIG: change this per gate
------------------------------------------------
local GATE_NUMBER = 1   -- <-- CHANGE THIS ONLY
------------------------------------------------

local mon = peripheral.find("monitor")
if not mon then
  error("No monitor attached")
end

mon.setTextScale(2)
mon.setBackgroundColor(colors.black)
mon.setTextColor(colors.white)
mon.clear()

------------------------------------------------
-- Big digit font (3x5)
------------------------------------------------
local FONT = {
  ["0"] = {
    "###",
    "# #",
    "# #",
    "# #",
    "###"
  },
  ["1"] = {
    " ##",
    "  #",
    "  #",
    "  #",
    " ###"
  },
  ["2"] = {
    "###",
    "  #",
    "###",
    "#  ",
    "###"
  },
  ["3"] = {
    "###",
    "  #",
    "###",
    "  #",
    "###"
  },
  ["4"] = {
    "# #",
    "# #",
    "###",
    "  #",
    "  #"
  },
  ["5"] = {
    "###",
    "#  ",
    "###",
    "  #",
    "###"
  },
  ["6"] = {
    "###",
    "#  ",
    "###",
    "# #",
    "###"
  },
  ["7"] = {
    "###",
    "  #",
    "  #",
    "  #",
    "  #"
  },
  ["8"] = {
    "###",
    "# #",
    "###",
    "# #",
    "###"
  },
  ["9"] = {
    "###",
    "# #",
    "###",
    "  #",
    "###"
  }
}

------------------------------------------------
-- Draw function
------------------------------------------------
local function drawDigit(d)
  local digit = tostring(d)
  local glyph = FONT[digit]

  if not glyph then
    error("Invalid digit: "..digit)
  end

  local w, h = mon.getSize()

  local gw = 3
  local gh = 5

  local startX = math.floor((w - gw) / 2) + 1
  local startY = math.floor((h - gh) / 2) + 1

  for y = 1, gh do
    mon.setCursorPos(startX, startY + y - 1)
    mon.write(glyph[y])
  end
end

------------------------------------------------
-- Main
------------------------------------------------
drawDigit(GATE_NUMBER)
