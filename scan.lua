local component = require("component")
local sides = require("sides")
local serialization = require("serialization")

local transposer = component.transposer
local db = require("db")
local event = require("event")

-- 🔧 CONFIG
local config = require("config")
local inputSide = config.inputSide
local outputSide = config.outputSide

local running = true
-- 📊 ดึงข้อมูล seed

local function isCrop(stack)
    return stack.name == "IC2:itemCropSeed"
end

local function getSeedData(stack)
    if not stack or not isCrop(stack) then
        return nil
    end
    if stack.crop then
      local crop = stack.crop

      local name = stack.label or "unknown"

      local gr = crop.growth or crop.gr or 0
      local ga = crop.gain or crop.ga or 0
      if gr > 23 then gr = 23 end
      return {
          name = name,
          score = gr + ga
      }
    else 
      local name = stack.label or "unknown"
      return {
          name = name,
          score = 0
      }
    end
end

local function checkEmty()
    local size = transposer.getInventorySize(inputSide)
    for slot = 1, size do
        local stack = transposer.getStackInSlot(inputSide, slot)
        if stack then
            return false
        end
    end
    return true
end

event.listen("interrupted", function()
    print("Stopping safely...")
    running = false
end)

-- 🚀 เริ่ม scan
db.load()

local size = transposer.getInventorySize(inputSide)
local round = 0
while not checkEmty() and running do
    round = round + 1
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
    if round >= 10 then
        db.save()
        round = 0
    end
    os.sleep(0)
end

db.save()

print("Scan complete.")
