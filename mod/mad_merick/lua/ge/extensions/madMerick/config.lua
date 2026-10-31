-- Settings a player or tester can change in /settings/madMerick/config.json. A missing file means
-- the defaults; a file that is present but invalid is never ignored or replaced.
local location = require('madMerick/location')
local M = { FILE = '/settings/madMerick/config.json' }

function M.defaults()
  -- Each caller receives a fresh table. start, when set, moves where a new run begins (handy for
  -- testing); wrist turns the VR wrist HUD on or off.
  return { resumeRadiusMetres = 50, wrist = true }
end

function M.validate(data)
  if type(data) ~= 'table' or (data.start ~= nil and not location.valid(data.start)) then return nil, 'start_coordinates' end
  local radius = data.resumeRadiusMetres == nil and 50 or data.resumeRadiusMetres
  if not location.finite(radius) or radius < 1 or radius > 1000 then return nil, 'verification_radius' end
  if data.wrist ~= nil and type(data.wrist) ~= 'boolean' then return nil, 'wrist' end
  return { start = data.start and location.copy(data.start), resumeRadiusMetres = radius, wrist = data.wrist ~= false }
end

function M.load(io)
  local existsOK, exists = pcall(io.exists, M.FILE)
  if not existsOK or type(exists) ~= 'boolean' then return nil, 'configuration_unreadable' end
  if not exists then return M.defaults() end
  local ok, data = pcall(io.read, M.FILE)
  if not ok or data == nil then return nil, 'configuration_unreadable' end
  return M.validate(data)
end

return M
