local T = dofile((arg[0]:match('^(.*)[/\\]') or '.') .. '/testlib.lua')
local W = require('tanker/wrist')

local function lit(ch)
  local out = {}
  W.digit(out, ch, 0, 0, 1, 2, 0.1, { 1, 1, 1 })
  return #out / 2
end
T.eq(lit('8'), 7, 'eight lights every segment'); T.eq(lit('1'), 2, 'one lights two')
T.eq(lit('0'), 6, 'zero lights six'); T.eq(lit('-'), 1, 'dash lights the middle'); T.eq(lit('x'), 0, 'unknown lights none')

T.eq(W.digitsFor(1490.4), '1490', 'whole km'); T.eq(W.digitsFor(1490.6), '1491', 'rounded')
T.eq(W.digitsFor(nil), '----', 'unknown shows dashes'); T.eq(W.digitsFor(123456), '9999', 'too big is capped')

local function count(tris, colour)
  local n = 0
  for _, t in ipairs(tris) do if t[7] == colour then n = n + 1 end end
  return n
end
local full = W.build({ threat = 'red', goal = { roadKm = 1490 }, fuel = { litres = 300, capacity = 400 },
  cargo = { litres = 100, capacity = 1000 }, ammo = { loaded = 4, spare = 12 } })
T.eq(count(full, W.COLOURS.ammo), 8, 'four rounds light four pips')
T.eq(count(full, W.COLOURS.red), 2, 'red threat square')
T.eq(count(full, W.COLOURS.fuel), 2, 'a three-quarter tank is green')
T.eq(count(full, W.COLOURS.cargo), 2, 'cargo bar drawn')
T.eq(count(full, W.COLOURS.digit), 2 * (lit('1') + lit('4') + lit('9') + lit('0')), 'distance digits drawn')
local inside = true
for _, t in ipairs(full) do
  for i = 1, 5, 2 do
    if math.abs(t[i]) > W.WIDTH / 2 + 1e-9 or math.abs(t[i + 1]) > W.HEIGHT / 2 + 1e-9 then inside = false end
  end
end
T.check(inside, 'every triangle stays on the panel')
local low = W.build({ fuel = { litres = 30, capacity = 400 } })
T.eq(count(low, W.COLOURS.out), 2, 'a nearly dry tank is red')
T.eq(count(low, W.COLOURS.ammo), 0, 'no ammo lights no pips')
T.check(#W.build(nil) > 0, 'an empty view still draws the panel')

local v = function(x, y, z) return { x = x, y = y, z = z } end
local pose = { pos = v(10, 20, 30), dir = v(0, 1, 0), up = v(0, 0, 1), right = v(1, 0, 0) }
local corners = {}
local n = W.place({ { 0, 0, 0.01, 0, 0, 0.01, { 1, 2, 3 } } }, pose, function(ax, ay, az, bx, by, bz, cx, cy, cz, colour)
  corners[#corners + 1] = { ax, ay, az, bx, by, bz, cx, cy, cz, colour }
end)
T.eq(n, 2, 'each triangle is drawn both ways round')
T.near(corners[1][1], 10, 1e-9, 'panel centre on the hand (x)')
T.near(corners[1][2], 20 - W.BACK, 1e-9, 'panel back towards the wrist')
T.near(corners[1][3], 30 + W.LIFT, 1e-9, 'panel lifted off the hand')
T.near(corners[1][4], 10.01, 1e-9, 'panel x runs along the controller right')
T.near(corners[1][8], 20 - W.BACK + 0.01, 1e-9, 'panel y runs along the controller forward')
T.eq(corners[2][4], corners[1][7], 'second copy is wound the other way')
T.eq(W.place({}, nil, function() end), 0, 'no pose draws nothing')
T.done('wrist HUD')
