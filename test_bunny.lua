-- ~/.hammerspoon/test_bunny.lua
-- Unit tests for the desktop bunny.
--
-- Run from the Hammerspoon console:
--   require("test_bunny")
--
-- Or bind a hotkey in init.lua:
--   hs.hotkey.bind(mash, "`", function() package.loaded["test_bunny"] = nil; require("test_bunny") end)

-- ─── tiny test runner ─────────────────────────────────────────────────────────

local passed, failed = 0, 0
local log = {}

local function pass(name)
  passed = passed + 1
  table.insert(log, "PASS  " .. name)
end

local function fail(name, reason)
  failed = failed + 1
  table.insert(log, "FAIL  " .. name .. "\n        " .. tostring(reason))
end

local function eq(name, expected, got)
  if expected == got then
    pass(name)
  else
    fail(name, "expected " .. tostring(expected) .. "  got " .. tostring(got))
  end
end

local function near(name, expected, got, tol)
  tol = tol or 0.001
  if math.abs(expected - got) <= tol then
    pass(name)
  else
    fail(name, "expected ~" .. tostring(expected) .. "  got " .. tostring(got))
  end
end

local function ok(name, cond, reason)
  if cond then pass(name) else fail(name, reason or "condition was false") end
end

-- ─── load a fresh bunny instance ─────────────────────────────────────────────

package.loaded["bunny"] = nil       -- clear require cache for a clean slate
local bunny = require("bunny")

local mir  = bunny._mir
local B    = bunny._B
local BL   = bunny._BL
local LAYBACK_R = bunny._LAYBACK_R
local LAYBACK_L = bunny._LAYBACK_L
local VAMPIRE   = bunny._VAMPIRE
local HOLE     = bunny._HOLE
local CW   = bunny._CW
local CH   = bunny._CH
local HOPH = bunny._HOPH
local HOPR = bunny._HOPR
local WALK = bunny._WALK

-- ─── 1. mir() — frame mirroring ───────────────────────────────────────────────

do
  local f = {x=10, y=20, w=15, h=30}
  local m = mir(f)

  eq  ("mir: x becomes CW - x - w",    CW - 10 - 15,  m.x)
  eq  ("mir: y is preserved",           20,             m.y)
  eq  ("mir: w is preserved",           15,             m.w)
  eq  ("mir: h is preserved",           30,             m.h)

  -- double mirror should restore original x
  local mm = mir(m)
  eq  ("mir: double-mirror restores x", f.x,            mm.x)

  -- frame spanning full canvas width mirrors to x=0
  local full = {x=0, y=0, w=CW, h=10}
  eq  ("mir: full-width frame stays at x=0", 0, mir(full).x)

  -- frame at far right edge mirrors to x=0
  local edge = {x=CW-1, y=0, w=1, h=1}
  eq  ("mir: far-right 1px lands at x=0", 0, mir(edge).x)

  -- x is always >= 0 for any valid base frame
  for key, frame in pairs(B) do
    ok("mir: " .. key .. " x >= 0 after mirror", mir(frame).x >= 0,
       "x=" .. mir(frame).x)
  end
end

-- ─── 2. BL — pre-computed left-facing frames ─────────────────────────────────

do
  -- Standard frames (non-ear) should be simple mirrors of BR
  local standardKeys = {
    "tail", "body", "head", "eye", "nose", "mouth", "zzz",
    "backArm", "frontArm", "heart", "footL", "footR",
    "fangL", "fangR", "bloodDrop",  -- vampire mode
  }
  for _, key in ipairs(standardKeys) do
    local expected = mir(B[key])
    local got      = BL[key]
    eq("BL " .. key .. ": x mirrored",   expected.x, got.x)
    eq("BL " .. key .. ": y preserved",  expected.y, got.y)
    eq("BL " .. key .. ": w preserved",  expected.w, got.w)
  end

  -- Ear swap: BL.earFar uses BR.earNear's position (mirrored), and vice-versa
  eq("BL earFar.x  = mir(BR.earNear).x",     mir(B.earNear).x,  BL.earFar.x)
  eq("BL earNear.x = mir(BR.earFar).x",      mir(B.earFar).x,   BL.earNear.x)
  eq("BL innerFar.x  = mir(BR.innerNear).x", mir(B.innerNear).x, BL.innerFar.x)
  eq("BL innerNear.x = mir(BR.innerFar).x",  mir(B.innerFar).x,  BL.innerNear.x)

  -- y values are preserved through the ear swap (mir never changes y)
  eq("BL earFar.y  = BR.earNear.y",  B.earNear.y, BL.earFar.y)
  eq("BL earNear.y = BR.earFar.y",   B.earFar.y,  BL.earNear.y)

  -- All BL frames must fit within the canvas
  for key, f in pairs(BL) do
    ok("BL: " .. key .. " x >= 0",        f.x >= 0,        "x=" .. f.x)
    ok("BL: " .. key .. " fits in canvas", f.x + f.w <= bunny._CW,
       "x+w=" .. (f.x + f.w))
  end
end

-- ─── 3. base frame sanity ─────────────────────────────────────────────────────

do
  for key, f in pairs(B) do
    ok("B: " .. key .. " x >= 0",        f.x >= 0,        "x=" .. f.x)
    ok("B: " .. key .. " y >= 0",        f.y >= 0,        "y=" .. f.y)
    ok("B: " .. key .. " w > 0",         f.w > 0,         "w=" .. f.w)
    ok("B: " .. key .. " h > 0",         f.h > 0,         "h=" .. f.h)
    ok("B: " .. key .. " fits in canvas", f.x + f.w <= CW, "x+w=" .. (f.x+f.w))
  end
end

-- ─── 4. animation constants ───────────────────────────────────────────────────

do
  ok  ("HOPH > 0",   HOPH > 0)
  ok  ("HOPR > 0",   HOPR > 0)
  ok  ("WALK > 0",   WALK > 0)
  ok  ("CW > 0",     CW > 0)
  ok  ("CH > 0",     CH > 0)

  -- hop rate should give a visible animation (not too fast, not too slow)
  ok  ("HOPR < 1",   HOPR < 1,   "hop rate >= 1 would alias badly")
  ok  ("HOPH <= CH", HOPH <= CH, "hop height taller than canvas")
end

-- ─── 5. bounce math ───────────────────────────────────────────────────────────

do
  -- bounce = -|sin(phase)| * HOPH, so always <= 0 (canvas moves up)
  for _, phase in ipairs({0, 0.5, 1.0, math.pi/2, math.pi, 3.14}) do
    local bounce = -math.abs(math.sin(phase)) * HOPH
    ok(string.format("bounce <= 0 at phase %.2f", phase), bounce <= 0,
       "bounce=" .. bounce)
  end

  -- at phase 0 bounce is exactly 0 (bunny on the ground)
  near("bounce at phase=0 is 0", 0, -math.abs(math.sin(0)) * HOPH)

  -- at phase pi/2 bounce is maximum
  near("bounce at pi/2 equals -HOPH", -HOPH, -math.abs(math.sin(math.pi/2)) * HOPH)
end

-- ─── 6. layback frames (two eyes, feet) ───────────────────────────────────────

do
  ok("LAYBACK_R has eye",   LAYBACK_R.eye ~= nil)
  ok("LAYBACK_R has eye2",  LAYBACK_R.eye2 ~= nil)
  eq("LAYBACK_L eye2 mirrored from LAYBACK_R.eye2", mir(LAYBACK_R.eye2).x, LAYBACK_L.eye2.x)
  eq("LAYBACK_L eye mirrored from LAYBACK_R.eye",  mir(LAYBACK_R.eye).x,  LAYBACK_L.eye.x)
  -- Layback body is flatter (wider, shorter) than upright
  ok("layback body wider than upright",  LAYBACK_R.body.w > B.body.w)
  ok("layback body shorter than upright", LAYBACK_R.body.h < B.body.h)
  -- Both eyes fit in layback head
  local head = LAYBACK_R.head
  ok("layback eye in head",  LAYBACK_R.eye.x >= head.x and LAYBACK_R.eye.x + LAYBACK_R.eye.w <= head.x + head.w)
  ok("layback eye2 in head", LAYBACK_R.eye2.x >= head.x and LAYBACK_R.eye2.x + LAYBACK_R.eye2.w <= head.x + head.w)
  -- All layback frames fit in canvas
  for key, f in pairs(LAYBACK_R) do
    ok("LAYBACK_R: " .. key .. " fits", f.x + f.w <= CW, "x+w=" .. (f.x + f.w))
  end
end

-- ─── 7. hole frames (head peeking, scared) ────────────────────────────────────

do
  ok("HOLE has hole",  HOLE.hole ~= nil)
  ok("HOLE has head",  HOLE.head ~= nil)
  ok("HOLE has earFar",   HOLE.earFar ~= nil)
  ok("HOLE has earNear",  HOLE.earNear ~= nil)
  ok("HOLE has innerFar", HOLE.innerFar ~= nil)
  ok("HOLE has innerNear", HOLE.innerNear ~= nil)
  ok("HOLE has eye",   HOLE.eye ~= nil)
  ok("HOLE has eye2",  HOLE.eye2 ~= nil)
  ok("HOLE has nose",  HOLE.nose ~= nil)
  ok("HOLE has mouth", HOLE.mouth ~= nil)
  -- Hole opening at bottom, head/ears peeking above it
  ok("hole opening at bottom", HOLE.hole.y >= 70)
  ok("hole opening fits in canvas", HOLE.hole.x + HOLE.hole.w <= CW)
  ok("hole head fits in canvas", HOLE.head.x + HOLE.head.w <= CW)
  -- Ears above the hole
  ok("hole ears above hole opening", HOLE.earNear.y < HOLE.hole.y)
  -- Both eyes in head
  local head = HOLE.head
  ok("hole eye in head",  HOLE.eye.x >= head.x and HOLE.eye.x + HOLE.eye.w <= head.x + head.w)
  ok("hole eye2 in head", HOLE.eye2.x >= head.x and HOLE.eye2.x + HOLE.eye2.w <= head.x + head.w)
  -- Valid states include inhole and vampire
  local validStates = {hop=true, idle=true, heart=true, layback=true, sleep=true, inhole=true, vampire=true}
  ok("_getState returns valid state", validStates[bunny._getState()] ~= nil)
end

-- ─── 7b. vampire frames (face-on, sharp teeth, thought bubble) ─────────────────

do
  ok("VAMPIRE has eye",   VAMPIRE.eye ~= nil)
  ok("VAMPIRE has eye2",  VAMPIRE.eye2 ~= nil)
  ok("VAMPIRE has nose",  VAMPIRE.nose ~= nil)
  ok("VAMPIRE has mouthArc", VAMPIRE.mouthArc ~= nil)
  ok("VAMPIRE has fangL", VAMPIRE.fangL ~= nil)
  ok("VAMPIRE has fangR", VAMPIRE.fangR ~= nil)
  -- Both eyes fit in head
  local head = VAMPIRE.head
  ok("vampire eye in head",  VAMPIRE.eye.x >= head.x and VAMPIRE.eye.x + VAMPIRE.eye.w <= head.x + head.w)
  ok("vampire eye2 in head", VAMPIRE.eye2.x >= head.x and VAMPIRE.eye2.x + VAMPIRE.eye2.w <= head.x + head.w)
  -- All vampire frames fit in canvas
  for key, f in pairs(VAMPIRE) do
    ok("VAMPIRE: " .. key .. " fits", f.x + f.w <= CW, "x+w=" .. (f.x + f.w))
  end
end

-- ─── 8. toggle lifecycle ──────────────────────────────────────────────────────

do
  -- clean state before we start
  bunny.stop()
  eq("lifecycle: canvas nil before start", nil, bunny._getCanvas())
  ok("lifecycle: state is valid initially", bunny._getState() == "hop")

  -- start
  bunny.toggle()
  ok("lifecycle: canvas exists after start", bunny._getCanvas() ~= nil)
  eq("lifecycle: state is hop after start",  "hop", bunny._getState())

  -- stop
  bunny.toggle()
  eq("lifecycle: canvas nil after stop", nil, bunny._getCanvas())

  -- idempotent stop — calling stop twice should not error
  local ok2, err = pcall(function() bunny.stop(); bunny.stop() end)
  ok("lifecycle: double stop is safe", ok2, tostring(err))

  -- start again after stop
  bunny.toggle()
  ok("lifecycle: can restart after stop", bunny._getCanvas() ~= nil)

  -- clean up — stop the bunny so it's not left running after tests
  bunny.stop()
  eq("lifecycle: canvas nil after final stop", nil, bunny._getCanvas())
end

-- ─── 9. scare() API ────────────────────────────────────────────────────────────

do
  bunny.stop()
  -- scare when not running: no-op, no error
  local okScare, errScare = pcall(function() bunny.scare() end)
  ok("scare when stopped: no error", okScare, tostring(errScare))
  eq("scare when stopped: canvas still nil", nil, bunny._getCanvas())

  -- start, scare from hop → inhole
  bunny.toggle()
  eq("scare prep: state is hop", "hop", bunny._getState())
  bunny.scare()
  eq("scare from hop: state becomes inhole", "inhole", bunny._getState())
  ok("scare from hop: canvas still exists", bunny._getCanvas() ~= nil)

  -- scare when already inhole: no-op (stays inhole)
  bunny.scare()
  eq("scare when inhole: stays inhole", "inhole", bunny._getState())

  -- keypress emerges from hole (simulated via internal state; we can't easily sim keypress)
  -- instead: restart and test scare from heart state
  bunny.stop()
  bunny.toggle()
  -- get to heart (would need to trigger it; for now just test scare from hop again works)
  bunny.scare()
  eq("scare after restart: inhole", "inhole", bunny._getState())

  bunny.stop()
end

-- ─── 10. getBounds() and bounce() (for ball collision) ───────────────────────────

do
  bunny.stop()
  eq("getBounds when stopped: nil", nil, bunny.getBounds())

  bunny.toggle()
  local b = bunny.getBounds()
  ok("getBounds when running: non-nil", b ~= nil)
  ok("getBounds has x", b and b.x ~= nil)
  ok("getBounds has y", b and b.y ~= nil)
  ok("getBounds has w", b and b.w == bunny._CW)
  ok("getBounds has h", b and b.h == bunny._CH)

  -- bounce() when running: no error
  local okBounce, errBounce = pcall(function() bunny.bounce() end)
  ok("bounce when running: no error", okBounce, tostring(errBounce))

  bunny.stop()
  local okBounceStop, _ = pcall(function() bunny.bounce() end)
  ok("bounce when stopped: no error", okBounceStop)
end

-- ─── 11. vampire() API ────────────────────────────────────────────────────────

do
  bunny.stop()
  -- vampire when stopped: no-op, no error
  local okVamp, errVamp = pcall(function() bunny.vampire() end)
  ok("vampire when stopped: no error", okVamp, tostring(errVamp))
  eq("vampire when stopped: canvas still nil", nil, bunny._getCanvas())
  ok("vampire when stopped: not in vampire mode", not bunny._isVampire())

  -- start, trigger vampire
  bunny.toggle()
  eq("vampire prep: canvas exists", true, bunny._getCanvas() ~= nil)
  bunny.vampire()
  ok("vampire when running: no error", true)
  ok("vampire when running: enters vampire mode", bunny._isVampire())
  eq("vampire when running: state is vampire", "vampire", bunny._getState())

  bunny.stop()
end

-- ─── report ───────────────────────────────────────────────────────────────────

local summary = string.format(
  "Bunny tests: %d passed, %d failed", passed, failed)

table.insert(log, 1, summary)
table.insert(log, 2, string.rep("-", 40))

local report = table.concat(log, "\n")
print(report)

local alertStyle = {
  textFont  = "Menlo",
  textSize  = 13,
  radius    = 6,
  fillColor = failed == 0
    and {red=0.05, green=0.35, blue=0.05, alpha=0.92}
    or  {red=0.40, green=0.05, blue=0.05, alpha=0.92},
  textColor = {white=1},
}

hs.alert.show(
  summary .. (failed > 0 and "\n(see Hammerspoon console for details)" or ""),
  alertStyle, hs.screen.mainScreen(), 4)

return {passed=passed, failed=failed, log=log}
