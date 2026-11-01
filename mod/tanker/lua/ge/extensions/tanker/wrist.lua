-- The VR wrist HUD: a small panel on the left hand, like a watch. Drawn the same way as the
-- revolver, as flat-coloured triangles from the debug drawer, because textures and text drew too
-- slowly and lagged. So everything on it is a shape: two fuel bars, six ammo pips, the threat
-- square, a siphon pip that blinks while fuel flows, and the distance to Pine Gap as
-- seven-segment digits.
-- build() is pure maths: triangles in the panel's own flat space, in metres, x to the right and y
-- up, centred on the panel. place() turns them into world corners on the hand.
local M = {}

-- One-line settings. Tune these after testing in game.
M.WIDTH, M.HEIGHT = 0.080, 0.050
-- Where the panel sits from the left grip, in metres: back along the controller towards the
-- wrist, and up off the back of the hand.
M.BACK, M.LIFT = 0.07, 0.035
-- Most digits drawn for the distance: 9999 km covers every road on Earth.
M.DIGITS = 4

local COLOURS = {
  panel = { 18, 22, 20 }, empty = { 60, 64, 60 }, fuel = { 111, 207, 151 }, low = { 242, 201, 76 },
  out = { 235, 87, 87 }, cargo = { 196, 132, 72 }, ammo = { 242, 201, 76 }, digit = { 230, 230, 220 },
  clear = { 60, 64, 60 }, amber = { 242, 153, 74 }, red = { 235, 87, 87 },
}
M.COLOURS = COLOURS

-- Which of the seven segments (a top, b top right, c bottom right, d bottom, e bottom left,
-- f top left, g middle) each digit lights.
local SEGMENTS = {
  ['0'] = 'abcdef', ['1'] = 'bc', ['2'] = 'abged', ['3'] = 'abgcd', ['4'] = 'fgbc',
  ['5'] = 'afgcd', ['6'] = 'afgedc', ['7'] = 'abc', ['8'] = 'abcdefg', ['9'] = 'abcdfg', ['-'] = 'g',
}
M.SEGMENTS = SEGMENTS

local function finite(n) return type(n) == 'number' and n == n and n > -math.huge and n < math.huge end

-- Adds a rectangle as two triangles: corners x1,y1 (bottom left) to x2,y2 (top right).
local function rect(out, x1, y1, x2, y2, colour)
  out[#out + 1] = { x1, y1, x2, y1, x2, y2, colour }
  out[#out + 1] = { x1, y1, x2, y2, x1, y2, colour }
end

-- One digit with its bottom left corner at x, y, w wide and h tall; t is the segment thickness.
local function digit(out, ch, x, y, w, h, t, colour)
  local lit = SEGMENTS[ch]
  if not lit then return end
  local mid = y + h / 2
  local boxes = {
    a = { x, y + h - t, x + w, y + h }, d = { x, y, x + w, y + t }, g = { x, mid - t / 2, x + w, mid + t / 2 },
    f = { x, mid, x + t, y + h }, b = { x + w - t, mid, x + w, y + h },
    e = { x, y, x + t, mid }, c = { x + w - t, y, x + w, mid },
  }
  for s in lit:gmatch('.') do
    local r = boxes[s]
    rect(out, r[1], r[2], r[3], r[4], colour)
  end
end
M.digit = digit

-- The number as at most M.DIGITS characters: whole km, or dashes when unknown or too big.
function M.digitsFor(km)
  if not finite(km) or km < 0 then return string.rep('-', M.DIGITS) end
  local s = tostring(math.floor(km + 0.5))
  if #s > M.DIGITS then return string.rep('9', M.DIGITS) end
  return s
end

local function share(part, whole)
  if not finite(part) or not finite(whole) or whole <= 0 then return nil end
  return math.max(0, math.min(1, part / whole))
end

-- A bar across the panel at height y: empty grey, then filled to the share in its colour.
local function bar(out, y, h, fraction, colour)
  local x1, x2 = -M.WIDTH / 2 + 0.006, M.WIDTH / 2 - 0.006
  rect(out, x1, y, x2, y + h, COLOURS.empty)
  if fraction and fraction > 0 then rect(out, x1, y, x1 + (x2 - x1) * fraction, y + h, colour) end
end

-- The triangles for this HUD state (the same view the on-screen HUD gets). Each is
-- { x1, y1, x2, y2, x3, y3, { r, g, b } }, in metres on the panel.
function M.build(view)
  view = type(view) == 'table' and view or {}
  local out = {}
  local w, h = M.WIDTH, M.HEIGHT
  rect(out, -w / 2, -h / 2, w / 2, h / 2, COLOURS.panel)

  -- Top row: the threat square on the left, the km to Pine Gap on the right.
  local top = h / 2 - 0.004
  local size = 0.012
  rect(out, -w / 2 + 0.005, top - size, -w / 2 + 0.005 + size, top, COLOURS[view.threat] or COLOURS.clear)
  -- While siphoning, a pip beside it blinks green once a second as the fuel flows.
  local sip = view.siphon
  if type(sip) == 'table' and sip.active then
    local x0 = -w / 2 + 0.005 + size + 0.003
    rect(out, x0, top - size + 0.003, x0 + 0.006, top - 0.003, sip.blink and COLOURS.fuel or COLOURS.empty)
  end
  local text = M.digitsFor(view.goal and view.goal.roadKm)
  local dw, dh, dt, gap = 0.007, 0.012, 0.0015, 0.0025
  local x = w / 2 - 0.005 - #text * dw - (#text - 1) * gap
  for i = 1, #text do
    digit(out, text:sub(i, i), x + (i - 1) * (dw + gap), top - dh, dw, dh, dt, COLOURS.digit)
  end

  -- Middle: your own tank, then the cargo tank.
  local fuel = view.fuel or {}
  local own = share(fuel.litres, fuel.capacity)
  local ownColour = own == nil and COLOURS.empty or own <= 0.1 and COLOURS.out or own <= 0.25 and COLOURS.low or COLOURS.fuel
  bar(out, -0.002, 0.005, own, ownColour)
  local cargo = view.cargo or {}
  bar(out, -0.010, 0.005, share(cargo.litres, cargo.capacity), COLOURS.cargo)

  -- Bottom: six pips in a ring like the cylinder, lit for each round loaded.
  local ammo = view.ammo or {}
  local loaded = finite(ammo.loaded) and ammo.loaded or 0
  local cx, cy, radius, pip = 0, -h / 2 + 0.0095, 0.0062, 0.0016
  for i = 1, 6 do
    local angle = math.pi / 2 - (i - 1) * math.pi / 3
    local px, py = cx + radius * math.cos(angle), cy + radius * math.sin(angle)
    rect(out, px - pip, py - pip, px + pip, py + pip, i <= loaded and COLOURS.ammo or COLOURS.empty)
  end
  return out
end

-- Turns panel triangles into world corners on the left hand. pose is the grip pose
-- ({ pos, dir, up, right }, each with x, y, z). The panel lies on the back of the wrist: its x
-- along the controller's right, its y along the controller's forward, facing up off the hand.
-- emit(ax, ay, az, bx, by, bz, cx, cy, cz, colour) is called for each triangle, both ways round
-- so it shows from either side. Returns how many triangles were emitted.
function M.place(tris, pose, emit)
  if type(tris) ~= 'table' or type(pose) ~= 'table' or type(emit) ~= 'function' then return 0 end
  local p, f, u, r = pose.pos, pose.dir, pose.up, pose.right
  if not (p and f and u and r) then return 0 end
  local ox, oy, oz = p.x - f.x * M.BACK + u.x * M.LIFT, p.y - f.y * M.BACK + u.y * M.LIFT, p.z - f.z * M.BACK + u.z * M.LIFT
  local function corner(x, y) return ox + r.x * x + f.x * y, oy + r.y * x + f.y * y, oz + r.z * x + f.z * y end
  local n = 0
  for _, t in ipairs(tris) do
    local ax, ay, az = corner(t[1], t[2])
    local bx, by, bz = corner(t[3], t[4])
    local cx, cy, cz = corner(t[5], t[6])
    emit(ax, ay, az, bx, by, bz, cx, cy, cz, t[7])
    emit(ax, ay, az, cx, cy, cz, bx, by, bz, t[7])
    n = n + 2
  end
  return n
end

return M
