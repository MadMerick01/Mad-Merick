/* global angular, bngApi */
angular.module('beamng.apps').directive('madMerickHud', [function () {
  // What the player was looking at. BeamNG rebuilds the app each time a menu closes, so this is
  // kept out here and the new app carries on where the old one was.
  var kept = { tab: 'road', open: true }
  // The commands the HUD may send, each only while Lua says it is allowed.
  var COMMANDS = { startRun: 'startAllowed', goToSave: 'goToSaveAllowed', save: 'saveAllowed' }
  return {
    templateUrl: '/ui/modules/apps/MadMerick/app.html',
    replace: true,
    link: function (scope) {
      'use strict'
      var disposed = false
      var lastMessage = Date.now()
      var waiting = { state: 'STARTING', stateLabel: 'WAITING FOR MAD MERICK', threat: 'clear' }
      scope.data = waiting
      var core = function (body) {
        if (typeof bngApi !== 'undefined' && bngApi.engineLua) bngApi.engineLua('if madMerick_core then madMerick_core.' + body + ' end')
      }
      var mount = function (on) { core('uiMounted(' + (on ? 'true' : 'false') + ')') }

      scope.tabs = [{ id: 'road', label: 'Road' }, { id: 'rig', label: 'Rig' }]
      scope.tab = kept.tab
      scope.open = kept.open
      scope.setTab = function (id) { scope.tab = kept.tab = id }
      scope.toggle = function () { scope.open = kept.open = !scope.open }
      scope.send = function (name) {
        var allowed = COMMANDS[name]
        if (allowed && scope.data[allowed] === true) core(name + '()')
      }

      // Whole numbers with thousands commas, or a dash when unknown.
      scope.whole = function (n) {
        return typeof n === 'number' && isFinite(n) ? Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',') : '–'
      }
      // The own tank's share as a percentage, for the bar, and its colour.
      scope.fuelShare = function (f) {
        if (!f || !(f.capacity > 0)) return 0
        return Math.max(0, Math.min(100, f.litres / f.capacity * 100))
      }
      scope.fuelColour = function (f) {
        var s = scope.fuelShare(f)
        return s <= 10 ? '#eb5757' : s <= 25 ? '#f2c94c' : '#6fcf97'
      }
      // Six pips for the cylinder: true for each round loaded.
      scope.pips = function (ammo) {
        var loaded = ammo && typeof ammo.loaded === 'number' ? ammo.loaded : 0
        return [1, 2, 3, 4, 5, 6].map(function (i) { return i <= loaded })
      }
      scope.threatColour = function (t) { return t === 'red' ? '#eb5757' : t === 'amber' ? '#f2994a' : '#3c403c' }

      scope.$on('MadMerickState', function (event, data) {
        if (disposed || !data || typeof data.state !== 'string') return
        lastMessage = Date.now()
        scope.$evalAsync(function () { if (!disposed) scope.data = data })
      })
      mount(true)
      var heartbeat = setInterval(function () {
        if (disposed) return
        mount(true)
        if (Date.now() - lastMessage > 6000) {
          scope.$evalAsync(function () {
            if (disposed) return
            scope.data = { state: 'STARTING', stateLabel: 'WAITING FOR MAD MERICK', threat: 'clear',
              feedback: 'Mad Merick is not responding. Check that the mod is enabled, then reload it.' }
          })
        }
      }, 3000)
      scope.$on('$destroy', function () {
        disposed = true
        clearInterval(heartbeat)
        mount(false)
      })
    }
  }
}])
