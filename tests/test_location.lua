local T = dofile((arg[0]:match('^(.*)[/\\]') or '.') .. '/testlib.lua')
local L = require('madMerick/location')
local F = require('fixtures')
local C = require('madMerick/config')
T.check(L.valid(F.position(-33.86, 151.21)), 'valid coordinate')
T.check(not L.valid(F.position(91, 0)), 'invalid latitude rejected')
T.check(not L.valid({ latitude = '0', longitude = 0 }), 'string latitude rejected')
T.near(L.distance(F.position(), F.position(1, 0)), 111195.0802, 0.01, 'one degree north')
T.near(L.bearing(F.position(), F.position(0, 1)), 90, 1e-9, 'bearing east')
T.eq(L.compassLetters(0), 'N', 'letters north'); T.eq(L.compassLetters(315), 'NW', 'letters north-west')

local io = F.io()
local d = C.load(io)
T.eq(d.resumeRadiusMetres, 50, 'default resume radius'); T.eq(d.wrist, true, 'wrist HUD on by default')
T.eq(d.start, nil, 'no start override by default'); T.eq(io.writes, 0, 'loading defaults writes nothing')
io.files[C.FILE] = { start = F.position(-31, 137), wrist = false }
local c = C.load(io)
T.eq(c.start.latitude, -31, 'start override read'); T.eq(c.wrist, false, 'wrist HUD can be turned off')
io.files[C.FILE] = { start = F.position(100, 0) }
T.eq(C.load(io), nil, 'invalid start is never ignored')
io.files[C.FILE] = { wrist = 'yes' }
T.eq(C.load(io), nil, 'invalid wrist setting rejected')
T.done('location and config')
