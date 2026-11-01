-- Other cars near the player's, for siphoning: the closest one, how far it is, and how fast the
-- player is going. Any car counts, parked, crashed or traffic. Every game call is guarded: a
-- missing or changed one means no car found, never an error.
local M = {}

local function defaults()
  return {
    player = function() return getPlayerVehicle(0) end,
    all = function()
      if type(getAllVehicles) == 'function' then return getAllVehicles() end
      local list = {}
      if be and be.getObjectCount then
        for i = 0, be:getObjectCount() - 1 do list[#list + 1] = be:getObject(i) end
      end
      return list
    end,
  }
end

local function finite(n) return type(n) == 'number' and n == n and n > -math.huge and n < math.huge end
local function point(p) return p and finite(p.x) and finite(p.y) and finite(p.z) and p or nil end

function M.new(environment)
  local env = environment or defaults()
  local n = {}

  -- The player's car: its id, position and speed in metres a second.
  function n:player()
    local ok, car = pcall(env.player)
    if not ok or not car then return nil end
    local okId, id = pcall(function() return car:getID() end)
    local okPos, pos = pcall(function() return car:getPosition() end)
    if not (okId and type(id) == 'number' and okPos and point(pos)) then return nil end
    local okVel, vel = pcall(function() return car:getVelocity() end)
    local speed = okVel and point(vel) and math.sqrt(vel.x * vel.x + vel.y * vel.y + vel.z * vel.z) or 0
    return { id = id, pos = pos, speed = speed }
  end

  -- How far the car with this id is from the player, in metres, or nil if it is gone.
  -- With no id, the closest other car: { id, metres }. Also returns the player.
  function n:closest(id)
    local me = self:player()
    if not me then return nil end
    local ok, all = pcall(env.all)
    if not ok or type(all) ~= 'table' then return nil, me end
    local best
    for _, car in ipairs(all) do
      local okId, carId = pcall(function() return car:getID() end)
      if okId and type(carId) == 'number' and carId ~= me.id and (id == nil or carId == id) then
        local okPos, pos = pcall(function() return car:getPosition() end)
        if okPos and point(pos) then
          local dx, dy, dz = pos.x - me.pos.x, pos.y - me.pos.y, pos.z - me.pos.z
          local metres = math.sqrt(dx * dx + dy * dy + dz * dz)
          if not best or metres < best.metres then best = { id = carId, metres = metres } end
        end
      end
    end
    return best, me
  end

  return n
end

return M
