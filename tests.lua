-- ~/.hammerspoon/tests.lua
-- Run all desktop pet tests (bunny, pig, ball).
--
-- Run from the Hammerspoon console:
--   require("tests")

local results = {}

-- Run bunny tests
package.loaded["test_bunny"] = nil
package.loaded["bunny"] = nil
local bunnyResult = require("test_bunny")
table.insert(results, {name="bunny", passed=bunnyResult.passed, failed=bunnyResult.failed})

-- Run pig tests
package.loaded["test_pig"] = nil
package.loaded["pig"] = nil
local pigResult = require("test_pig")
table.insert(results, {name="pig", passed=pigResult.passed, failed=pigResult.failed})

-- Run ball tests
package.loaded["test_ball"] = nil
package.loaded["ball"] = nil
local ballResult = require("test_ball")
table.insert(results, {name="ball", passed=ballResult.passed, failed=ballResult.failed})

-- Summary
local totalPassed = 0
local totalFailed = 0
local lines = {"\n" .. string.rep("=", 50), "ALL TESTS SUMMARY", string.rep("=", 50)}
for _, r in ipairs(results) do
  totalPassed = totalPassed + r.passed
  totalFailed = totalFailed + r.failed
  table.insert(lines, string.format("  %s: %d passed, %d failed", r.name, r.passed, r.failed))
end
table.insert(lines, string.rep("-", 50))
table.insert(lines, string.format("  TOTAL: %d passed, %d failed", totalPassed, totalFailed))
table.insert(lines, string.rep("=", 50))
print(table.concat(lines, "\n"))

local alertStyle = {
  textFont  = "Menlo",
  textSize  = 13,
  radius    = 6,
  fillColor = totalFailed == 0
    and {red=0.05, green=0.35, blue=0.05, alpha=0.92}
    or  {red=0.40, green=0.05, blue=0.05, alpha=0.92},
  textColor = {white=1},
}

hs.alert.show(
  string.format("All tests: %d passed, %d failed", totalPassed, totalFailed) ..
  (totalFailed > 0 and "\n(see Hammerspoon console for details)" or ""),
  alertStyle, hs.screen.mainScreen(), 5)

return {results=results, passed=totalPassed, failed=totalFailed}
