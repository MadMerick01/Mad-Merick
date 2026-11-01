local T = dofile((arg[0]:match('^(.*)[/\\]') or '.') .. '/testlib.lua')
local F = require('fixtures')
local S = require('tanker/siphon')
local R = require('tanker/route')

-- The logic alone: a litre a second from their tank into yours, exactly what came out.
local asked = {}
local s = S.new(function(litres, serial, id) asked[#asked + 1] = { litres = litres, serial = serial, id = id }; return true end)
T.eq(s:start(42, 0), true, 'starts on a car')
T.eq(s:start(43, 0), false, 'one siphon at a time')
s:step(0, 3, 0, { litres = 10, capacity = 100 })
T.eq(asked[1].litres, -1, 'takes a litre'); T.eq(asked[1].id, 42, 'from their car')
s:step(0.5, 3, 0, { litres = 10, capacity = 100 })
T.eq(#asked, 1, 'waits for their answer')
T.eq(s:answer(99, 1, 0, 50, 0.5), false, 'an answer to something else is ignored')
s:answer(asked[1].serial, 20, 19, 50, 0.5)
T.eq(asked[2].litres, 1, 'puts what came out into yours'); T.eq(asked[2].id, nil, 'your car')
s:answer(asked[2].serial, 10, 11, 100, 0.5)
T.near(s:view(0.5).litres, 1, 1e-9, 'one litre taken'); T.eq(s:view(0.5).theirs, 19, 'their tank shown')
s:step(0.9, 3, 0, { litres = 11, capacity = 100 })
T.eq(#asked, 2, 'no more than a litre a second')
s:step(1.0, 3, 0, { litres = 11, capacity = 100 })
T.eq(#asked, 3, 'the next litre after a second')
-- Their last half litre: only what was there moves, then it stops dry.
s:answer(asked[3].serial, 0.4, 0, 50, 1.1)
s:answer(asked[4].serial, 11, 11.4, 100, 1.1)
T.eq(s:active(), false, 'stops when their tank is dry')
T.near(s.result.taken, 1.4, 1e-9, 'kept what was taken')
T.check(s:view(2).result:find('dry'), 'says their tank is dry')
T.eq(s:view(1.1 + S.RESULT_SECONDS + 1), nil, 'the result goes after a few seconds')

-- Your tank nearly full: takes only the room left, then stops full.
local asked2 = {}
local s2 = S.new(function(litres, serial) asked2[#asked2 + 1] = { litres = litres, serial = serial }; return true end)
s2:start(5, 0)
s2:step(0, 3, 0, { litres = 99.7, capacity = 100 })
T.near(asked2[1].litres, -0.3, 1e-9, 'takes only the room you have')
s2:answer(asked2[1].serial, 30, 29.7, 50, 0)
s2:answer(asked2[2].serial, 99.7, 100, 100, 0)
T.eq(s2:active(), false, 'stops when your tank is full'); T.check(s2.result.text:find('full'), 'and says so')

-- Driving off, the car going, a silent car and Stop all end it, keeping what was taken.
local function fresh() local x = S.new(function() return true end); x:start(5, 0); return x end
local s3 = fresh(); s3:step(0, 3, 4, nil); T.eq(s3.result.reason, 'moved', 'driving off stops it')
local s4 = fresh(); s4:step(0, 30, 0, nil); T.eq(s4.result.reason, 'moved', 'too far away stops it')
local s5 = fresh(); s5:step(0, nil, 0, nil); T.eq(s5.result.reason, 'lost', 'the car gone stops it')
local s6 = fresh(); s6:step(0, 3, 0, nil); s6:step(S.WAIT_SECONDS + 1, 3, 0, nil); T.eq(s6.result.reason, 'lost', 'no answer stops it')
local s7 = fresh(); T.check(s7:finish('stopped', 0):find('stopped'), 'Stop stops it')
local s8 = S.new(function() return true end); s8:start(5, 0)
local sent8 = {}
s8 = S.new(function(l, serial) sent8[#sent8 + 1] = serial; return true end); s8:start(5, 0); s8:step(0, 3, 0, nil)
s8:answer(sent8[1], 0, 0, 0, 0)
T.check(s8.result.text:find('no fuel'), 'a car with no fuel says so')

-- In the game: a car beside you offers Siphon fuel, and the fuel shows in your tank.
local adapter = F.adapter(-31.0, 140.0)
local near = F.nearby({ [42] = 4 })
local c, env = F.controller(adapter, { nearby = near })
local function run(seconds) for _ = 1, math.floor(seconds * 2) do c:tick(0.5) end end
run(1)
T.eq(c:view().siphonNear, nil, 'nothing offered before the run')
T.eq(c:startSiphon(), false, 'no siphon before the run')
c:startRun(); adapter:put(R.START.latitude, R.START.longitude); run(1)
T.eq(c.state, 'RUNNING', 'on the road')
c:fuelReading(7, 50, 300)
local v = c:view()
T.eq(v.siphonAllowed, true, 'Siphon fuel offered beside a car'); T.near(v.siphonNear.metres, 4, 1e-9, 'with how far it is')
near.speed = 5; run(0.5)
T.eq(c:view().siphonAllowed, false, 'not while driving'); T.eq(c:view().siphonNear.moving, true, 'says to stop')
near.speed = 0; run(0.5)
T.eq(c:startSiphon(), true, 'siphon started')
T.eq(c:view().siphonStopAllowed, true, 'Stop offered'); T.eq(c:view().siphon.active, true, 'the box shows')
run(0.5)
local take = env.fuel.changes[1]
T.eq(take.id, 42, 'takes from the car beside you'); T.eq(take.litres, -1, 'a litre')
c:fuelChanged(42, take.serial, 80, 79, 100)
local give = env.fuel.changes[2]
T.eq(give.id, nil, 'into your truck'); T.eq(give.litres, 1, 'the same litre')
c:fuelChanged(7, give.serial, 50, 51, 300)
T.eq(c:view().fuel.litres, 51, 'your tank shows it at once')
T.eq(c:view().siphon.theirs, 79, 'their tank in the box')
env.hoonDistances = function() return { 300 } end; run(0.5)
T.eq(c:view().siphon.hoons, true, 'the box warns of Hoons')
env.hoonDistances = nil
T.eq(c:stopSiphon(), true, 'Stop'); T.check(c.feedback:find('You took 1 L'), 'says what you took')
T.eq(c:view().siphon.active, false, 'the box shows the result'); T.eq(c:view().siphonStopAllowed, false, 'Stop gone')

-- The command sent into a car is valid Lua, and goes to the car with that id.
local fuel = require('tanker/fuel')
local commands, ids = {}, {}
local function car(id) return { getID = function() return id end, queueLuaCommand = function(_, cmd) commands[#commands + 1] = cmd; ids[#ids + 1] = id end } end
local f = fuel.new({ player = function() return car(7) end, byId = function(id) return car(id) end })
T.eq(f:change(-1, 3, 42), true, 'asks their car'); T.eq(ids[1], 42, 'the car with that id')
T.eq(f:change(1, 4), true, 'asks your car'); T.eq(ids[2], 7, 'your car')
T.check((loadstring or load)(commands[1]) ~= nil, 'the command is valid Lua')
T.check(commands[1]:find('fuelChanged(%d, %d', 1, true) and commands[1]:find(', 42, 3, before', 1, true), 'answers with its id and serial')
T.eq(f:change(0 / 0, 5, 42), false, 'nonsense litres refused')

-- The wrist shows a blinking pip while siphoning.
local W = require('tanker/wrist')
local plain, on, off = #W.build({}), #W.build({ siphon = { active = true, blink = true } }), W.build({ siphon = { active = true, blink = false } })
T.eq(on, plain + 2, 'a pip while siphoning')
T.eq(off[5][7], W.COLOURS.empty, 'it blinks off')
T.eq(#W.build({ siphon = { active = false } }), plain, 'no pip once it stops')
T.done('siphon')
