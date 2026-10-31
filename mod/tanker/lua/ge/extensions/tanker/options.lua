-- Choices the player makes in the HUD, kept in /settings/tanker/options.json. Unlike config.json,
-- which testers edit by hand, Tanker writes this file itself, so a missing or broken one just
-- means the defaults.
local M = { FILE = '/settings/tanker/options.json', DIRECTORY = '/settings/tanker/' }

function M.defaults()
  -- desertRocks: whether BeamNG.Earth's scattered rocks are shown (and solid). Off makes the open
  -- desert a clear, fast surface for chases.
  return { desertRocks = true }
end

function M.validate(data)
  local o = M.defaults()
  if type(data) == 'table' and type(data.desertRocks) == 'boolean' then o.desertRocks = data.desertRocks end
  return o
end

function M.load(io)
  local okExists, exists = pcall(io.exists, M.FILE)
  if not okExists or exists ~= true then return M.defaults() end
  local ok, data = pcall(io.read, M.FILE)
  return M.validate(ok and data or nil)
end

function M.save(io, options)
  local o = M.validate(options)
  local okDir, made = pcall(io.mkdir, M.DIRECTORY)
  if not okDir or made == false then return false end
  local ok, written = pcall(io.write, M.FILE, o)
  return ok and written ~= false
end

return M
