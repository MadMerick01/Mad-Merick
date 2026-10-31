local T = dofile((arg[0]:match('^(.*)[/\\]') or '.') .. '/testlib.lua')
local F = require('fixtures')
local R = require('madMerick/route')
local P = require('madMerick/persistence')

-- Runs the controller for a while, half a second at a time.
local function run(c, seconds) for _ = 1, math.floor(seconds * 2) do c:tick(0.5) end end

-- A new player: Start the run teleports to the start, and arriving starts and saves the run.
local adapter = F.adapter(-31.0, 140.0)
local c, env, sent = F.controller(adapter)
c:mount(true)
run(c, 1)
T.eq(c.state, 'NEW', 'no save means a new run')
local v = c:view()
T.eq(v.startAllowed, true, 'Start the run offered'); T.eq(v.saveAllowed, false, 'no saving before the run')
T.eq(v.threat, 'clear', 'no Hoons yet'); T.check(v.goal.roadKm > 1000, 'distance to Pine Gap shown')
T.check(#sent > 0 and sent[1].event == 'MadMerickState', 'state sent to the HUD')
T.eq(c:goToSave(), false, 'no save to go to')
T.eq(c:startRun(), true, 'start the run')
T.eq(adapter.teleports[1].name, R.START_NAME, 'teleports to the start')
T.eq(c.state, 'TO_START', 'heading to the start')
T.eq(c:startRun(), false, 'cannot start twice')
adapter:put(R.START.latitude, R.START.longitude)
run(c, 1)
T.eq(c.state, 'RUNNING', 'arriving starts the run')
T.eq(env.io.writes, 1, 'the run is saved at the start')
T.eq(c:view().saveAllowed, true, 'saving allowed on the road')

-- Driving north adds km; a teleport-sized jump does not.
adapter:put(R.START.latitude + 0.002, R.START.longitude)
run(c, 0.5)
T.near(c.profile.run.drivenKm, 0.222, 0.01, 'km driven counted')
adapter:put(R.START.latitude + 0.5, R.START.longitude)
run(c, 0.5)
T.near(c.profile.run.drivenKm, 0.222, 0.01, 'a jump is not driving')

-- Fuel readings measure the range.
c:fuelReading(1, 300, 400)
c.profile.run.drivenKm = c.profile.run.drivenKm + 5
c:fuelReading(1, 298, 400)
local f = c:view().fuel
T.eq(f.litres, 298, 'fuel shown'); T.check(f.rangeKm and f.rangeKm > 500, 'range from what was used')

-- Hoons near: no saving.
env.hoonDistances = function() return { 100 } end
run(c, 0.5)
T.eq(c:view().threat, 'red', 'a Hoon on you shows red')
T.eq(c:view().saveAllowed, false, 'no saving with Hoons near')
T.eq(c:manualSave(), false, 'save refused'); T.eq(c.feedback, 'You can\'t save with Hoons nearby.', 'and says why')
env.hoonDistances = nil
run(c, 0.5)
T.eq(c:manualSave(), true, 'save once they are gone')
T.eq(env.io.files[P.DIRECTORY .. 'save-b.json'].vehicle.fuelLitres, 298, 'the save keeps the fuel')

-- A new session away from the save: Go to your save, and the tank is put back as saved.
local adapter2 = F.adapter(-20.0, 130.0)
local c2, env2 = F.controller(adapter2, { io = env.io })
run(c2, 1)
T.eq(c2.state, 'AWAY', 'away from the save')
T.eq(c2:view().startAllowed, false, 'no new run while a save exists')
T.eq(c2:view().goToSaveAllowed, true, 'Go to your save offered')
T.eq(c2:goToSave(), true, 'go to the save')
adapter2:put(c.profile.resume.latitude, c.profile.resume.longitude)
run(c2, 1)
T.eq(c2.state, 'RUNNING', 'back on the road')
T.eq(env2.fuel.sets[1] and env2.fuel.sets[1].litres, 298, 'tank put back as saved')

-- A refused teleport says so and stays put.
local adapter3 = F.adapter(-31.0, 140.0)
adapter3.refuse = 'teleport_refused'
local c3 = F.controller(adapter3)
run(c3, 1)
T.eq(c3:startRun(), false, 'refused teleport'); T.eq(c3.state, 'NEW', 'still ready to start')
T.check(c3.feedback and c3.feedback:find('companion'), 'explains the refusal')

-- A teleport that never lands times out.
local adapter4 = F.adapter(-31.0, 140.0)
local c4 = F.controller(adapter4)
run(c4, 1)
c4:startRun()
run(c4, 61)
T.eq(c4.state, 'NEW', 'a lost teleport goes back to ready')

-- No Earth: nothing breaks.
local c5 = F.controller(F.adapter())
run(c5, 1)
T.eq(c5:view().goal, nil, 'no distance without Earth')
T.eq(c5:view().saveAllowed, false, 'no saving without Earth')

-- Ammo and the wrist HUD come from the pistol when it is there.
local drawn = 0
local c6, env6 = F.controller(F.adapter(-31.0, 140.0), { drawTri = function() drawn = drawn + 1 end,
  pistol = F.pistol({ installed = true, drawn = true, loaded = 5, spare = 30 }) })
run(c6, 1)
T.eq(c6:view().ammo.loaded, 5, 'ammo from the pistol'); T.eq(c6:view().pistol.drawn, true, 'drawn shown')
T.eq(drawn, 0, 'no wrist HUD without hand tracking')
local v3 = function(x, y, z) return { x = x, y = y, z = z } end
env6.pistol.hand = { pos = v3(0, 0, 0), dir = v3(0, 1, 0), up = v3(0, 0, 1), right = v3(1, 0, 0) }
c6:tick(0.01)
T.check(drawn > 0, 'wrist HUD drawn with hand tracking')
T.eq(F.controller(F.adapter(-31.0, 140.0)):view().ammo, nil, 'no ammo shown without the pistol')

-- A broken config is never ignored.
local io7 = F.io()
io7.files['/settings/madMerick/config.json'] = { wrist = 'maybe' }
local c7 = F.controller(F.adapter(-31.0, 140.0), { io = io7 })
run(c7, 1)
T.eq(c7.state, 'ERROR', 'invalid config stops the run')
T.done('core')
