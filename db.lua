local serialization = require("serialization")

local db = {}
local path = "./seeds.db"

-- 📥 โหลด database
function db.load()
  local file = io.open(path, "r")
  if file then
    local data = file:read("*a")
    file:close()
    db.data = serialization.unserialize(data) or {}
  else
    db.data = {}
  end
end

-- 💾 บันทึก database
function db.save()
  local file = io.open(path, "w")
  file:write(serialization.serialize(db.data))
  file:close()
end

-- 📊 อัปเดต highscore
function db.update(name, score)
  local current = db.data[name]

  if not current or score > current then
    db.data[name] = score
    return true  -- มีการอัปเดต
  end

  return false
end

-- 🔍 ดึงค่า
function db.get(name)
  return db.data[name]
end

return db