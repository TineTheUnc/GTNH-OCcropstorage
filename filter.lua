local component = require("component")

local transposer = component.transposer
local db = require("db")

-- 🔧 CONFIG
local config = require("config")
local inputSide = config.inputSide
local outputSide = config.outputSide
local trashSide = config.trashSide

local OFFSET = 1  -- 🔧 ปรับได้ (ยิ่งน้อยยิ่งโหด)

-- 📊 อ่าน seed
local function getSeedData(stack)
  if not stack or not stack.crop then return nil end

  local crop = stack.crop

  local name = stack.label or "unknown"
  local gr = crop.growth or crop.gr or 0
  local ga = crop.gain or crop.ga or 0

  return {
    name = name,
    score = gr + ga
  }
end

-- 🚀 เริ่มทำงาน
db.load()

local size = transposer.getInventorySize(inputSide)

for slot = 1, size do
  local stack = transposer.getStackInSlot(inputSide, slot)

  if stack then
    local seed = getSeedData(stack)

    if seed then
      local high = db.get(seed.name)
      if high then
        if seed.score >= high - OFFSET then
          local updated = db.update(seed.name, seed.score)
          transposer.transferItem(inputSide, outputSide, 64, slot)
          print("KEEP:", seed.name, seed.score, "/", high)
        else
          transposer.transferItem(inputSide, trashSide, 64, slot)
          print("TRASH:", seed.name, seed.score, "/", high)
        end
      else
        -- ยังไม่มีใน DB
        print("UNKNOWN:", seed.name)
        transposer.transferItem(inputSide, trashSide, 64, slot)
      end
    else
      print("SKIP:", stack.label)
      transposer.transferItem(inputSide, outputSide, 64, slot)
    end
  end
end

db.save()

print("Filter complete.")