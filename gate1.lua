-- bigtimer.lua
-- First pulse starts, second pulse stops. Displays big time on a monitor wall.

local SENSOR_SIDE = "bottom"   -- side where your ID pulse enters the computer

-- === monitor setup ===
local mon = peripheral.find("monitor")
if not mon then error("No monitor found. Place a monitor and try again.") end

mon.setTextScale(0.5) -- try 0.5, 1, or 2 depending on your monitor wall size
mon.setBackgroundColor(colors.black)
mon.setTextColor(colors.white)

-- === big digit font (3x5) ===
local FONT = {
  ["0"]={"\x7f\x7f\x7f","\x7f \x7f","\x7f \x7f","\x7f \x7f","\x7f\x7f\x7f"},
  ["1"]={" \x7f\x7f","  \x7f","  \x7f","  \x7f"," \x7f\x7f\x7f"},
  ["2"]={"\x7f\x7f\x7f","  \x7f","\x7f\x7f\x7f","\x7f  ","\x7f\x7f\x7f"},
  ["3"]={"\x7f\x7f\x7f","  \x7f","\x7f\x7f\x7f","  \x7f","\x7f\x7f\x7f"},
  ["4"]={"\x7f \x7f","\x7f \x7f","\x7f\x7f\x7f","  \x7f","  \x7f"},
  ["5"]={"\x7f\x7f\x7f","\x7f  ","\x7f\x7f\x7f","  \x7f","\x7f\x7f\x7f"},
  ["6"]={"\x7f\x7f\x7f","\x7f  ","\x7f\x7f\x7f","\x7f \x7f","\x7f\x7f\x7f"},
  ["7"]={"\x7f\x7f\x7f","  \x7f","  \x7f","  \x7f","  \x7f"},
  ["8"]={"\x7f\x7f\x7f","\x7f \x7f","\x7f\x7f\x7f","\x7f \x7f","\x7f\x7f\x7f"},
  ["9"]={"\x7f\x7f\x7f","\x7f \x7f","\x7f\x7f\x7f","  \x7f","\x7f\x7f\x7f"},
  ["."]={"   ","   ","   ","   ","  \x7f"},
  [":"]={"   "," \x7f ","   "," \x7f ","   "},
  [" "]={"   ","   ","   ","   ","   "},
}

local function fmtTime(ms)
  if ms < 0 then ms = 0 end
  local totalSeconds = ms / 1000
  local minutes = math.floor(totalSeconds / 60)
  local seconds = totalSeconds - (minutes * 60)
  return string.format("%02d:%06.3f", minutes, seconds) -- MM:SSS.sss (with leading)
end

local function clear()
  mon.clear()
  mon.setCursorPos(1,1)
end

local function drawCenteredBig(text, y)
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
      local ch = text:sub(i,i)
      local g = FONT[ch] or FONT[" "]
      mon.setCursorPos(x, startY + (r-1))
      mon.write(g[r])
      x = x + glyphW + gap
    end
  end
end

local function drawStatus(status, hint)
  local w, h = mon.getSize()
  mon.setCursorPos(2,2)
  mon.write(status)

  if hint then
    mon.setCursorPos(2, h-1)
    mon.write(hint)
  end
end

-- === timing state ===
local state = "ARMED"  -- ARMED -> RUNNING -> FINISHED
local startMs = nil
local finishMs = nil

local function nowMs() return os.epoch("utc") end

local function render()
  clear()
  local displayMs

  if state == "ARMED" then
    displayMs = 0
    drawStatus("ARMED", "Fly through gate to START")
  elseif state == "RUNNING" then
    displayMs = nowMs() - startMs
    drawStatus("RUNNING", "Fly through gate to STOP")
  else -- FINISHED
    displayMs = finishMs - startMs
    drawStatus("FINISHED", "Ctrl+T to stop (or reboot to reset)")
  end

  drawCenteredBig(fmtTime(displayMs), nil)
end

-- render loop
render()

while true do
  -- redraw regularly so the timer looks smooth
  local timerId = os.startTimer(0.05)

  local ev, p1 = os.pullEvent()
  if ev == "timer" and p1 == timerId then
    if state == "RUNNING" then render() end
  elseif ev == "redstone" then
    if redstone.getInput(SENSOR_SIDE) then
      if state == "ARMED" then
        startMs = nowMs()
        state = "RUNNING"
        render()
      elseif state == "RUNNING" then
        finishMs = nowMs()
        state = "FINISHED"
        render()
      end
    end
  end
end
