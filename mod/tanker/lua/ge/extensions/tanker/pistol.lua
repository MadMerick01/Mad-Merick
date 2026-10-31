-- Rowan's VR revolver (BeamngVRcontrollerPoses), a separate mod Tanker needs installed. This
-- only reads it: whether it is there, whether it is drawn, and its ammo once the pistol has ammo.
-- Every call is guarded, so a missing pistol or a changed function means nothing is shown, never an error.
local M = {}

local function defaults()
  return {
    pistol = function() return rawget(_G, 'vrPistol') or (extensions and extensions.vrPistol) end,
    hands = function() return rawget(_G, 'vrHands') or (extensions and extensions.vrHands) end,
  }
end

local function count(n, most)
  return type(n) == 'number' and n == n and n >= 0 and n <= most and n == math.floor(n)
end

function M.new(environment)
  local env = environment or defaults()
  local p = {}

  local function get(name)
    local ok, value = pcall(env[name])
    if ok and type(value) == 'table' then return value end
  end

  -- What the HUD shows: installed, drawn, and loaded and spare rounds when the pistol reports
  -- them (getAmmo returning { loaded, spare }). loaded and spare are nil while it has no ammo.
  function p:read()
    local pistol = get('pistol')
    if not pistol then return { installed = false } end
    local out = { installed = true }
    if type(pistol.isEquipped) == 'function' then
      local ok, on = pcall(pistol.isEquipped)
      out.drawn = ok and on == true
    end
    if type(pistol.getAmmo) == 'function' then
      local ok, ammo = pcall(pistol.getAmmo)
      if ok and type(ammo) == 'table' and count(ammo.loaded, 6) and count(ammo.spare, 9999) then
        out.loaded, out.spare = ammo.loaded, ammo.spare
      end
    end
    return out
  end

  -- The left controller's grip pose in the world, for the wrist HUD: { pos, dir, up, right } with
  -- vec3s, or nil when VR or the pistol's hand tracking is not running.
  function p:leftHand()
    local hands = get('hands')
    if not hands or type(hands.getPose) ~= 'function' then return nil end
    local ok, pose = pcall(hands.getPose, 'left', 'grip')
    if ok and type(pose) == 'table' and pose.valid and pose.pos and pose.dir and pose.up and pose.right then return pose end
  end

  return p
end

return M
