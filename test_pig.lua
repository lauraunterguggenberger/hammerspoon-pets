-- ~/.hammerspoon/test_pig.lua
-- Unit tests for the desktop pig.
--
-- Run from the Hammerspoon console:
--   require("test_pig")
--
-- Or bind a hotkey in init.lua:
--   hs.hotkey.bind(mash, "`", function() package.loaded["test_pig"] = nil; require("test_pig") end)

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

-- ─── load a fresh pig instance ────────────────────────────────────────────────

package.loaded["pig"] = nil
local pig = require("pig")

local mir  = pig._mir
local B    = pig._B
local BL   = pig._BL
local ROLL_R = pig._ROLL_R
local ROLL_L = pig._ROLL_L
local MUD_PUDDLE = pig._MUD_PUDDLE
local CW   = pig._CW
local CH   = pig._CH
local TROT = pig._TROT
local SWAY = pig._SWAY

-- ─── 1. mir() — frame mirroring ───────────────────────────────────────────────

do
  local f = {x=10, y=20, w=15, h=30}
  local m = mir(f)

  eq  ("mir: x becomes CW - x - w",    CW - 10 - 15,  m.x)
  eq  ("mir: y is preserved",           20,             m.y)
  eq  ("mir: w is preserved",           15,             m.w)
  eq  ("mir: h is preserved",           30,             m.h)

  local mm = mir(m)
  eq  ("mir: double-mirror restores x", f.x,            mm.x)

  local full = {x=0, y=0, w=CW, h=10}
  eq  ("mir: full-width frame stays at x=0", 0, mir(full).x)

  local edge = {x=CW-1, y=0, w=1, h=1}
  eq  ("mir: far-right 1px lands at x=0", 0, mir(edge).x)

  for key, frame in pairs(B) do
    ok("mir: " .. key .. " x >= 0 after mirror", mir(frame).x >= 0,
       "x=" .. mir(frame).x)
  end
end

-- ─── 2. BL — pre-computed left-facing frames ─────────────────────────────────

do
  local standardKeys = {
    "tail", "body", "head", "snout", "nostrilL", "nostrilR", "eye", "mouth", "zzz",
    "backArm", "frontArm", "heart", "bubble", "bubbleTail", "waveEmoji", "footL", "footR",
  }
  for _, key in ipairs(standardKeys) do
    local expected = mir(B[key])
    local got      = BL[key]
    eq("BL " .. key .. ": x mirrored",   expected.x, got.x)
    eq("BL " .. key .. ": y preserved",  expected.y, got.y)
    eq("BL " .. key .. ": w preserved",  expected.w, got.w)
  end

  eq("BL earFar.x  = mir(BR.earNear).x", mir(B.earNear).x, BL.earFar.x)
  eq("BL earNear.x = mir(BR.earFar).x",  mir(B.earFar).x,  BL.earNear.x)

  for key, f in pairs(BL) do
    ok("BL: " .. key .. " x >= 0",        f.x >= 0,        "x=" .. f.x)
    ok("BL: " .. key .. " fits in canvas", f.x + f.w <= pig._CW,
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
  ok  ("TROT > 0",   TROT > 0)
  ok  ("SWAY >= 0",  SWAY >= 0)
  ok  ("CW > 0",     CW > 0)
  ok  ("CH > 0",     CH > 0)
  ok  ("SWAY <= CH", SWAY <= CH, "sway taller than canvas")
end

-- ─── 5. sway math (trot) ──────────────────────────────────────────────────────

do
  for _, phase in ipairs({0, 0.5, 1.0, math.pi/2, math.pi, 3.14}) do
    local sway = math.sin(phase) * SWAY
    ok(string.format("sway in [-SWAY, SWAY] at phase %.2f", phase), sway >= -SWAY and sway <= SWAY,
       "sway=" .. sway)
  end
end

-- ─── 6. roll frames ───────────────────────────────────────────────────────────

do
  ok("ROLL_R has eye",   ROLL_R.eye ~= nil)
  ok("ROLL_R has eye2",  ROLL_R.eye2 ~= nil)
  eq("ROLL_L eye2 mirrored from ROLL_R.eye2", mir(ROLL_R.eye2).x, ROLL_L.eye2.x)
  eq("ROLL_L eye mirrored from ROLL_R.eye",  mir(ROLL_R.eye).x,  ROLL_L.eye.x)
  ok("roll body wider than upright",  ROLL_R.body.w > B.body.w)
  ok("roll body shorter than upright", ROLL_R.body.h < B.body.h)
  local head = ROLL_R.head
  ok("roll eye in head",  ROLL_R.eye.x >= head.x and ROLL_R.eye.x + ROLL_R.eye.w <= head.x + head.w)
  ok("roll eye2 in head", ROLL_R.eye2.x >= head.x and ROLL_R.eye2.x + ROLL_R.eye2.w <= head.x + head.w)
  for key, f in pairs(ROLL_R) do
    ok("ROLL_R: " .. key .. " fits", f.x + f.w <= CW, "x+w=" .. (f.x + f.w))
  end
end

-- ─── 7. mud puddle frames ──────────────────────────────────────────────────────

do
  ok("MUD_PUDDLE has hole",  MUD_PUDDLE.hole ~= nil)
  ok("MUD_PUDDLE has head",  MUD_PUDDLE.head ~= nil)
  ok("MUD_PUDDLE has earFar",   MUD_PUDDLE.earFar ~= nil)
  ok("MUD_PUDDLE has earNear",  MUD_PUDDLE.earNear ~= nil)
  ok("MUD_PUDDLE has eye",   MUD_PUDDLE.eye ~= nil)
  ok("MUD_PUDDLE has eye2",  MUD_PUDDLE.eye2 ~= nil)
  ok("MUD_PUDDLE has snout", MUD_PUDDLE.snout ~= nil)
  ok("MUD_PUDDLE has mouth", MUD_PUDDLE.mouth ~= nil)
  ok("mud hole at bottom", MUD_PUDDLE.hole.y >= 70)
  ok("mud hole fits in canvas", MUD_PUDDLE.hole.x + MUD_PUDDLE.hole.w <= CW)
  ok("mud head fits in canvas", MUD_PUDDLE.head.x + MUD_PUDDLE.head.w <= CW)
  ok("mud ears above hole opening", MUD_PUDDLE.earNear.y < MUD_PUDDLE.hole.y)
  local head = MUD_PUDDLE.head
  ok("mud eye in head",  MUD_PUDDLE.eye.x >= head.x and MUD_PUDDLE.eye.x + MUD_PUDDLE.eye.w <= head.x + head.w)
  ok("mud eye2 in head", MUD_PUDDLE.eye2.x >= head.x and MUD_PUDDLE.eye2.x + MUD_PUDDLE.eye2.w <= head.x + head.w)
  local validStates = {trot=true, idle=true, heart=true, wave=true, oink=true, roll=true, sleep=true, inmud=true}
  ok("_getState returns valid state", validStates[pig._getState()] ~= nil)
end

-- ─── 8. toggle lifecycle ───────────────────────────────────────────────────────

do
  pig.stop()
  eq("lifecycle: canvas nil before start", nil, pig._getCanvas())
  ok("lifecycle: state is valid initially", pig._getState() == "trot")

  pig.toggle()
  ok("lifecycle: canvas exists after start", pig._getCanvas() ~= nil)
  eq("lifecycle: state is trot after start",  "trot", pig._getState())

  pig.toggle()
  eq("lifecycle: canvas nil after stop", nil, pig._getCanvas())

  local ok2, err = pcall(function() pig.stop(); pig.stop() end)
  ok("lifecycle: double stop is safe", ok2, tostring(err))

  pig.toggle()
  ok("lifecycle: can restart after stop", pig._getCanvas() ~= nil)

  pig.stop()
  eq("lifecycle: canvas nil after final stop", nil, pig._getCanvas())
end

-- ─── 9. scare() API ────────────────────────────────────────────────────────────

do
  pig.stop()
  local okScare, errScare = pcall(function() pig.scare() end)
  ok("scare when stopped: no error", okScare, tostring(errScare))
  eq("scare when stopped: canvas still nil", nil, pig._getCanvas())

  pig.toggle()
  eq("scare prep: state is trot", "trot", pig._getState())
  pig.scare()
  eq("scare from trot: state becomes inmud", "inmud", pig._getState())
  ok("scare from trot: canvas still exists", pig._getCanvas() ~= nil)

  pig.scare()
  eq("scare when inmud: stays inmud", "inmud", pig._getState())

  pig.stop()
  pig.toggle()
  pig.scare()
  eq("scare after restart: inmud", "inmud", pig._getState())

  pig.stop()
end

-- ─── report ───────────────────────────────────────────────────────────────────

local summary = string.format(
  "Pig tests: %d passed, %d failed", passed, failed)

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
