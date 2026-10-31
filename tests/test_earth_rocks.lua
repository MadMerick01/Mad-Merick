local T = dofile((arg[0]:match('^(.*)[/\\]') or '.') .. '/testlib.lua')
local adapterModule = require('tanker/earthAdapter')

-- A fake of Earth's trees module: the switch its settings page uses.
local function earth()
  local trees = { groupOff = { lampglow = true }, calls = {} }
  function trees.setGroupEnabled(groups, on)
    trees.calls[#trees.calls + 1] = on
    for _, g in ipairs(groups) do trees.groupOff[g] = (not on) or nil end
    return true
  end
  local env = { core = function() return {} end, module = function(name) if name == 'trees' then return trees end end,
    vehicle = function() return nil end }
  return adapterModule.new(env), trees
end

local a, trees = earth()
T.eq(a:rocks(true), 'shown', 'rocks shown and left alone')
T.eq(#trees.calls, 0, 'nothing switched while they are wanted')
T.eq(a:rocks(false), 'hidden', 'rocks hidden')
T.eq(trees.groupOff.rock and trees.groupOff.desert_rock, true, 'both rock groups off')
T.eq(a:rocks(false), 'hidden', 'still hidden'); T.eq(#trees.calls, 1, 'switched only once')
trees.groupOff.desert_rock = nil -- Earth turned them back on
a:rocks(false)
T.eq(trees.groupOff.desert_rock, true, 'hidden again'); T.eq(#trees.calls, 2, 'one more switch')
T.eq(a:rocks(true), 'shown', 'shown again'); T.eq(trees.groupOff.rock, nil, 'rock group back on')
T.eq(trees.groupOff.lampglow, true, 'other groups untouched')

-- Rocks the player turned off in Earth stay off.
local b, trees2 = earth()
trees2.groupOff.rock, trees2.groupOff.desert_rock = true, true
T.eq(b:rocks(false), 'hidden', 'already hidden')
T.eq(b:rocks(true), 'hidden_by_earth', 'Earth\'s choice kept')
T.eq(#trees2.calls, 0, 'never switched')
b:restoreRocks()
T.eq(#trees2.calls, 0, 'nothing to restore')

-- Restore after Tanker hid them.
local c, trees3 = earth()
c:rocks(false); c:restoreRocks()
T.eq(trees3.groupOff.rock, nil, 'restored on shutdown')

-- No Earth, or no trees module: unavailable, no errors.
local none = adapterModule.new({ core = function() return nil end, module = function() end, vehicle = function() end })
T.eq(none:rocks(false), 'unavailable', 'no Earth')
local bare = adapterModule.new({ core = function() return {} end, module = function() return {} end, vehicle = function() end })
T.eq(bare:rocks(false), 'unavailable', 'no switch')
T.done('earth_rocks')
