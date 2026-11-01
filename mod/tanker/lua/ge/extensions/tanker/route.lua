-- The run: where it starts and where it is going. Pure maths; no game globals.
local location = require('tanker/location')
local M = {}

-- One-line settings. Tune these after testing in game.
-- Yorkeys Crossing, outside Port Augusta, SA: Rowan's pick for where the run starts, at the head
-- of Spencer Gulf where the Stuart Highway heads north into the desert. config.json's start
-- moves it.
M.START = { latitude = -32.47125, longitude = 137.78370 }
M.START_NAME = 'Yorkeys Crossing, Port Augusta'
-- Pine Gap, outside Alice Springs. Everything about it in the game is fiction.
M.GOAL = { latitude = -23.7990, longitude = 133.7370 }
M.GOAL_NAME = 'Pine Gap'
-- Roads are longer than the straight line. 1.18 puts Yorkeys Crossing to Pine Gap at about 1,230 km,
-- close to the real drive up the Stuart Highway.
M.ROAD_FACTOR = 1.18
-- A new run starts once the truck is this close to the start, after the teleport there.
M.START_RADIUS_METRES = 5000
-- Within this distance of Pine Gap the run's first goal is reached.
M.GOAL_RADIUS_METRES = 2000

-- How far is left to Pine Gap from here: the straight line and the road estimate in km, which way
-- it is (degrees and letters), and whether it has been reached. nil for an invalid position.
function M.toGoal(here)
  local metres = location.distance(here, M.GOAL)
  if not metres then return nil end
  local bearing = location.bearing(here, M.GOAL)
  return {
    km = metres / 1000, roadKm = metres * M.ROAD_FACTOR / 1000, bearing = bearing,
    letters = location.compassLetters(bearing), reached = metres <= M.GOAL_RADIUS_METRES,
  }
end

-- How much of the trip is done, from 0 to 1, by road estimate from the start to here.
function M.progress(here, start)
  local total = location.distance(start or M.START, M.GOAL)
  local left = location.distance(here, M.GOAL)
  if not total or not left or total <= 0 then return nil end
  return math.max(0, math.min(1, 1 - left / total))
end

function M.atStart(here, start)
  local metres = location.distance(here, start or M.START)
  return metres ~= nil and metres <= M.START_RADIUS_METRES
end

return M
