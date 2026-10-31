-- The threat light: off, amber when a Hoon is near, red when one is on you. Pure maths; no game
-- globals. Takes the distances in metres to every Hoon that is hunting the player; with no Hoons
-- yet it is always clear.
local M = {}

-- One-line settings. Tune these after testing in game.
M.NEAR_METRES = 600
M.ON_YOU_METRES = 120

function M.level(distances)
  local nearest
  for _, d in ipairs(type(distances) == 'table' and distances or {}) do
    if type(d) == 'number' and d == d and d >= 0 and (not nearest or d < nearest) then nearest = d end
  end
  if nearest and nearest <= M.ON_YOU_METRES then return 'red' end
  if nearest and nearest <= M.NEAR_METRES then return 'amber' end
  return 'clear'
end

return M
