-- number.lua (simple, 1x1 monitor)
local GATE_NUMBER = 1  -- <-- change this per gate

local mon = peripheral.find("monitor")
if not mon then error("No monitor found") end

mon.setBackgroundColor(colors.black)
mon.setTextColor(colors.white)

local function draw()
  local text = tostring(GATE_NUMBER)

  -- Try largest to smallest. (Not all scales exist in all versions, but these usually do.)
  local scales = {5, 4, 3, 2, 1, 0.5}
  for _, s in ipairs(scales) do
    pcall(function() mon.setTextScale(s) end)
    local w, h = mon.getSize()
    if #text <= w and 1 <= h then
      mon.clear()
      local x = math.floor((w - #text) / 2) + 1
      local y = math.floor(h / 2)
      if y < 1 then y = 1 end
      mon.setCursorPos(x, y)
      mon.write(text)
      return
    end
  end

  -- Fallback
  mon.setTextScale(1)
  mon.clear()
  mon.setCursorPos(1, 1)
  mon.write(text)
end

draw()
