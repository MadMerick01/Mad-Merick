-- Small fakes for the game: positions, a file store, and the adapter, fuel and pistol the core uses.
local F = {}
function F.position(lat, lon) return { latitude = lat or 0, longitude = lon or 0 } end

-- An in-memory file store with the same calls as the game's.
function F.io()
  local files, io = {}, { writes = 0 }
  io.files = files
  function io.exists(path) return files[path] ~= nil end
  function io.read(path) return files[path] end
  function io.mkdir() return true end
  function io.write(path, data)
    io.writes = io.writes + 1
    -- A copy, as a JSON round trip would make.
    local function copy(v) if type(v) ~= 'table' then return v end local o = {} for k, x in pairs(v) do o[k] = copy(x) end return o end
    files[path] = copy(data)
    return true
  end
  return io
end

-- An Earth that reports wherever the test puts the truck, and teleports it when asked.
function F.adapter(lat, lon)
  local a = { here = { valid = true, latitude = lat, longitude = lon, heading = 0, vehicle = { model = 'us_semi' } }, teleports = {} }
  if lat == nil then a.here = { valid = false, reason = 'earth_missing' } end
  function a:sample() return self.here end
  function a:put(lat2, lon2) self.here = { valid = true, latitude = lat2, longitude = lon2, heading = 0, vehicle = { model = 'us_semi' } } end
  function a:teleport(point, name) self.teleports[#self.teleports + 1] = { point = point, name = name }; return self.refuse == nil, self.refuse end
  return a
end

function F.fuel()
  local f = { reads = 0, sets = {} }
  function f:read() self.reads = self.reads + 1; return true end
  function f:set(litres, serial) self.sets[#self.sets + 1] = { litres = litres, serial = serial }; return true end
  return f
end

function F.pistol(state)
  local p = { state = state or { installed = false } }
  function p:read() return self.state end
  function p:leftHand() return self.hand end
  return p
end

-- A controller with fakes, and what it sent to the HUD.
function F.controller(adapter, extra)
  local core = require('tanker/core')
  local sent = {}
  local env = { io = F.io(), adapter = adapter or F.adapter(-34.19, 138.14), fuel = F.fuel(), pistol = F.pistol(),
    trigger = function(event, view) sent[#sent + 1] = { event = event, view = view } end }
  for k, v in pairs(extra or {}) do env[k] = v end
  local c = core.new(env)
  return c, env, sent
end
return F
