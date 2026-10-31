import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import vm from 'node:vm'
import test from 'node:test'

const APP = '../mod/mad_merick/ui/modules/apps/MadMerick/'
const source = readFileSync(new URL(APP + 'app.js', import.meta.url), 'utf8')
const html = readFileSync(new URL(APP + 'app.html', import.meta.url), 'utf8')
const fixed = body => 'if madMerick_core then madMerick_core.' + body + ' end'

function app() {
  const commands = [], handlers = {}, timers = new Map()
  let definition, clock = 0
  const scope = { $on: (name, fn) => { handlers[name] = fn }, $evalAsync: fn => fn() }
  vm.runInNewContext(source, {
    angular: { module(name) {
      assert.equal(name, 'beamng.apps')
      return { directive(id, factory) { assert.equal(id, 'madMerickHud'); definition = factory.at(-1)() } }
    } },
    bngApi: { engineLua: command => commands.push(command) },
    setInterval: fn => { timers.set(1, fn); return 1 }, clearInterval: id => timers.delete(id), Date: { now: () => clock }
  })
  definition.link(scope)
  const a = { scope, commands, handlers, state: data => handlers.MadMerickState({}, data),
    advance: ms => { clock += ms; for (const tick of timers.values()) tick() } }
  // BeamNG rebuilds the app when a menu closes: the old one is destroyed and a new one linked.
  a.remount = () => {
    handlers.$destroy()
    a.scope = { $on: (name, fn) => { handlers[name] = fn }, $evalAsync: fn => fn() }
    definition.link(a.scope)
    return a
  }
  return a
}

test('app mounts, resyncs and says when Lua is silent', () => {
  const a = app()
  assert.equal(a.commands[0], fixed('uiMounted(true)'))
  a.advance(3000)
  assert.equal(a.commands[1], fixed('uiMounted(true)'))
  a.advance(4000)
  assert.match(a.scope.data.feedback, /not responding/)
  a.handlers.$destroy()
  assert.equal(a.commands.at(-1), fixed('uiMounted(false)'))
})

test('buttons only send fixed commands when Lua allows them', () => {
  const a = app()
  const before = a.commands.length
  a.scope.send('startRun'); a.scope.send('save'); a.scope.send('goToSave'); a.scope.send('os.exit')
  assert.equal(a.commands.length, before)
  a.state({ state: 'NEW', startAllowed: true })
  a.scope.send('startRun')
  assert.equal(a.commands.at(-1), fixed('startRun()'))
  a.state({ state: 'RUNNING', saveAllowed: true })
  a.scope.send('save')
  assert.equal(a.commands.at(-1), fixed('save()'))
  a.state({ state: 'AWAY', goToSaveAllowed: true })
  a.scope.send('goToSave')
  assert.equal(a.commands.at(-1), fixed('goToSave()'))
})

test('strip helpers show fuel, ammo and the threat light', () => {
  const a = app()
  assert.equal(a.scope.whole(1453.6), '1,454')
  assert.equal(a.scope.whole(null), '–')
  assert.equal(a.scope.fuelShare({ litres: 100, capacity: 400 }), 25)
  assert.equal(a.scope.fuelColour({ litres: 100, capacity: 400 }), '#f2c94c')
  assert.equal(a.scope.fuelColour({ litres: 20, capacity: 400 }), '#eb5757')
  assert.equal(a.scope.fuelShare(undefined), 0)
  assert.deepEqual(Array.from(a.scope.pips({ loaded: 2 })), [true, true, false, false, false, false])
  assert.deepEqual(Array.from(a.scope.pips(undefined)), [false, false, false, false, false, false])
  assert.equal(a.scope.threatColour('red'), '#eb5757')
  assert.equal(a.scope.threatColour('clear'), '#3c403c')
})

test('ignores malformed state and keeps the tab across rebuilds', () => {
  const a = app()
  a.state(null); a.state({ state: 7 })
  assert.equal(a.scope.data.state, 'STARTING')
  a.scope.setTab('rig')
  a.scope.toggle()
  a.remount()
  assert.equal(a.scope.tab, 'rig')
  assert.equal(a.scope.open, false)
})

test('template uses only the helpers the app defines', () => {
  for (const name of ['toggle', 'send', 'whole', 'fuelShare', 'fuelColour', 'pips', 'threatColour', 'setTab']) {
    assert.ok(html.includes(name + '('), name)
  }
  assert.ok(!/bngApi|engineLua/.test(html), 'no direct Lua from the template')
})
