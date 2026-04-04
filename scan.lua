local component = require("component")
local sides = require("sides")
local serialization = require("serialization")

local transposer = component.transposer
local db = require("db")

-- 🔧 CONFIG
local config = require("config")
local inputSide = config.inputSide
local outputSide = config.outputSide

-- 📊 ดึงข้อมูล seed
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

local function checkEmty()
  local size = transposer.getInventorySize(inputSide)
  for slot = 1, size do
    local stack = transposer.getStackInSlot(inputSide, slot)
    if stack then return false end
  end
  return true
end

-- 🚀 เริ่ม scan
db.load()

local size = transposer.getInventorySize(inputSide)
while not checkEmty() do
  for slot = 1, size do
    local stack = transposer.getStackInSlot(inputSide, slot)

    if stack then
      local seed = getSeedData(stack)

      if seed then
        local updated = db.update(seed.name, seed.score)
        if updated then
          print("NEW HIGH:", seed.name, seed.score)
        else
          print("SCAN:", seed.name, seed.score)
        end
      else
        print("SKIP (no tag):", stack.label)
      end
      transposer.transferItem(inputSide, outputSide, 64, slot)
    end
  end
end

db.save()

print("Scan complete.")