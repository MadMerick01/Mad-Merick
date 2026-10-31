local T = dofile((arg[0]:match('^(.*)[/\\]') or '.') .. '/testlib.lua')
local P = require('tanker/persistence')
local F = require('fixtures')

local io = F.io()
local store = P.new(io)
local save, why = store:load()
T.eq(save, nil, 'no save at first'); T.eq(why, 'missing', 'missing')
local profile = P.newProfile(F.position(-34.19, 138.14), F.position(-34.0, 138.1), { model = 'us_semi' })
profile.vehicle.fuelLitres = 250
local saved = store:save(profile)
T.check(saved ~= nil, 'first save'); T.eq(saved.generation, 1, 'generation 1')
T.eq(io.writes, 1, 'one write'); T.eq(profile.generation, 0, 'the profile passed in is not changed')
profile.run.drivenKm = 12.5
local second = store:save(profile)
T.eq(second.generation, 2, 'generation 2')
T.check(io.files[P.DIRECTORY .. 'save-a.json'] and io.files[P.DIRECTORY .. 'save-b.json'], 'saves alternate slots')
local again = P.new(io):load()
T.eq(again.generation, 2, 'newest save loads'); T.near(again.run.drivenKm, 12.5, 1e-9, 'distance kept')
T.eq(again.vehicle.fuelLitres, 250, 'fuel kept'); T.eq(again.vehicle.model, 'us_semi', 'truck kept')

io.files[P.DIRECTORY .. 'save-b.json'].run = 'bad'
T.eq(P.new(io):load().generation, 1, 'an unreadable newest save falls back to the other slot')
io.files[P.DIRECTORY .. 'save-a.json'].schemaVersion = 99
local s, w = P.new(io):load()
T.eq(s, nil, 'a newer save is not loaded'); T.eq(w, 'newer_version', 'and says why')

local bad = P.newProfile(F.position(-34.19, 138.14), F.position(-34.0, 138.1))
bad.vehicle.fuelLitres = -1
T.eq(P.new(F.io()):save(bad), nil, 'negative fuel is refused')
T.eq(P.validate({}), nil, 'an empty document is refused')
T.check(P.plainConfig({ model = 'us_semi', parts = { a = 'b' } }) ~= nil, 'plain vehicle config kept')
T.eq(P.plainConfig({ model = 'us_semi', f = function() end }), nil, 'functions refused')
T.done('persistence')
