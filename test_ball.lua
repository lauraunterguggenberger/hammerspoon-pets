-- ~/.hammerspoon/test_ball.lua
-- Unit tests for the bouncing ball.
--
-- Run from the Hammerspoon console:
--   require("test_ball")
--
-- Or run all tests:
--   require("tests")

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

local function ok(name, cond, reason)
  if cond then pass(name) else fail(name, reason or "condition was false") end
end

-- ─── load ball ────────────────────────────────────────────────────────────────

package.loaded["ball"] = nil
local ball = require("ball")

local overlaps = ball._overlaps
local BALL_R  = ball._BALL_R
local GRAVITY = ball._GRAVITY
local BOUNCE_DAMP = ball._BOUNCE_DAMP

-- ─── 1. overlaps — AABB collision ─────────────────────────────────────────────

do
  -- Non-overlapping: boxes side by side
  ok("overlaps: side-by-side false", not overlaps(0, 0, 10, 10, 20, 0, 10, 10))
  ok("overlaps: left of false", not overlaps(0, 0, 10, 10, 15, 0, 10, 10))
  ok("overlaps: right of false", not overlaps(20, 0, 10, 10, 0, 0, 10, 10))
  -- Vertical separation
  ok("overlaps: above false", not overlaps(0, 0, 10, 10, 0, 20, 10, 10))
  ok("overlaps: below false", not overlaps(0, 20, 10, 10, 0, 0, 10, 10))

  -- Overlapping
  ok("overlaps: same rect true", overlaps(10, 10, 20, 20, 10, 10, 20, 20))
  ok("overlaps: partial right true", overlaps(0, 0, 20, 20, 15, 0, 20, 20))
  ok("overlaps: partial left true", overlaps(15, 0, 20, 20, 0, 0, 20, 20))
  ok("overlaps: contained true", overlaps(5, 5, 10, 10, 0, 0, 30, 30))
  ok("overlaps: touching edge true", overlaps(0, 0, 10, 10, 10, 0, 10, 10))
end

-- ─── 2. registerPet ──────────────────────────────────────────────────────────

do
  -- registerPet accepts pet with getBounds and bounce
  local mockPet = { getBounds = function() return {} end, bounce = function() end }
  local okReg, errReg = pcall(function() ball.registerPet(mockPet) end)
  ok("registerPet: accepts valid pet", okReg, tostring(errReg))

  -- registerPet ignores nil
  ball.registerPet(nil)
  ok("registerPet: nil no error", true)

  -- registerPet ignores object without getBounds
  ball.registerPet({ bounce = function() end })
  ok("registerPet: missing getBounds no error", true)

  -- registerPet ignores object without bounce
  ball.registerPet({ getBounds = function() return {} end })
  ok("registerPet: missing bounce no error", true)
end

-- ─── 3. throw — no error when called ──────────────────────────────────────────

do
  local okThrow, errThrow = pcall(function() ball.throw() end)
  ok("throw: no error", okThrow, tostring(errThrow))

  -- throw again: clears previous, no error
  local okThrow2, errThrow2 = pcall(function() ball.throw() end)
  ok("throw again: no error", okThrow2, tostring(errThrow2))
end

-- ─── 4. constants ─────────────────────────────────────────────────────────────

do
  ok("BALL_R > 0", BALL_R > 0)
  ok("GRAVITY > 0", GRAVITY > 0)
  ok("BOUNCE_DAMP in 0..1", BOUNCE_DAMP > 0 and BOUNCE_DAMP < 1)
end

-- ─── report ───────────────────────────────────────────────────────────────────

local summary = string.format(
  "Ball tests: %d passed, %d failed", passed, failed)

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
