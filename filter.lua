local component = require("component")

local transposer = component.transposer
local db = require("db")
local event = require("event")

-- 🔧 CONFIG
local config = require("config")
local inputSide = config.inputSide
local outputSide = config.outputSide
local trashSide = config.trashSide

local OFFSET = 1 -- 🔧 ปรับได้ (ยิ่งน้อยยิ่งโหด)
local running = true

-- 📊 อ่าน seed
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

-- 🚀 เริ่มทำงาน

event.listen("interrupted", function()
    print("Stopping safely...")
    running = false
end)

db.load()

local size = transposer.getInventorySize(inputSide)
local round = 0
while running do
    round = round + 1
    for slot = 1, size do
        local stack = transposer.getStackInSlot(inputSide, slot)

        if stack then
            local seed = getSeedData(stack)

            if seed then
                local updated = db.update(seed.name, seed.score)
                local high = db.get(seed.name)
                if high then
                    if seed.score >= high - OFFSET then
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
                if seed.name == "Weed" then
                    transposer.transferItem(inputSide, trashSide, 64, slot)
                    print("TRASH:", seed.name)
                else
                    print("SKIP:", stack.label)
                    transposer.transferItem(inputSide, outputSide, 64, slot)
                end
            end
        end
    end
    if round >= 10 then
        db.save()
        round = 0
    end
end

db.save()


print("Filter complete.")
