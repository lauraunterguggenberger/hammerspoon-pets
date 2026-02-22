-- =============================================================================
-- ~/.hammerspoon/init.lua  —  Hammerspoon Power Config
-- =============================================================================
--
-- MODIFIER LAYERS:
--   nudge = Ctrl + Alt                (window snapping)
--   mash  = Cmd  + Ctrl + Alt         (fine movement, hints)
--   hyper = Cmd  + Ctrl + Alt + Shift (app launcher, system)
--
-- TIP: Map Caps Lock → Hyper in Karabiner-Elements for one-key access.
--   Simple Modifications: caps_lock → left_command+control+option+shift
--
-- QUICK REFERENCE  (hyper+q to show in-app)
-- =============================================================================

-- =============================================================================
-- CONFIG  (edit these to taste)
-- =============================================================================

local NUDGE_PX         = 20    -- pixels per keypress for fine move/resize
local CLIP_MAX         = 50    -- clipboard history size
local BATTERY_ALERTS   = {20, 15, 10, 5}  -- notify at these percentages

-- App launcher map: hyper + key → app name
-- Edit to match your installed apps.
local APPS = {
  a = "Arc",
  b = "Safari",
  c = "Calendar",
  e = "Visual Studio Code",
  f = "Finder",
  g = "Google Chrome",
  i = "iTerm2",
  m = "Mail",
  n = "Notes",
  o = "Obsidian",
  p = "1Password 7",
  r = "Reminders",
  s = "Slack",
  t = "Terminal",
  w = "WhatsApp",
  x = "Xcode",
  z = "Zoom",
}

-- Layout preset: edit app names and positions for hyper+l
-- unit rects: {x, y, w, h} as fractions of screen (0–1)
local LAYOUTS = {
  single = {
    { app = "Safari",            pos = {0,   0, 0.5, 1} },
    { app = "Terminal",          pos = {0.5, 0, 0.5, 1} },
  },
  dual = {
    { app = "Safari",            pos = {0, 0, 1, 1},   screen = 1 },
    { app = "Visual Studio Code",pos = {0, 0, 1, 1},   screen = 2 },
  },
}

-- WiFi actions: run a function when joining a specific network
local WIFI_RULES = {
  -- ["HomeNetwork"]   = function() hs.application.launchOrFocus("Dropbox") end,
  -- ["OfficeNetwork"] = function() hs.application.launchOrFocus("Slack")   end,
}

-- USB actions: run a function when a USB device is added/removed
local USB_RULES = {
  -- ["My USB Device"] = {
  --   added   = function() hs.alert.show("USB connected") end,
  --   removed = function() hs.alert.show("USB removed")   end,
  -- },
}

-- =============================================================================
-- MODIFIER ALIASES
-- =============================================================================

local hyper = {"cmd", "ctrl", "alt", "shift"}
local mash  = {"cmd", "ctrl", "alt"}
local nudge = {"ctrl", "alt"}

-- =============================================================================
-- GLOBAL SETTINGS
-- =============================================================================

hs.window.animationDuration = 0       -- instant window moves
hs.hints.showTitleThresh    = 4       -- show app name in hints
hs.hints.style              = "vimperator"
hs.hotkey.alertDuration     = 0       -- suppress built-in hotkey alerts
hs.logger.defaultLogLevel   = "warning"

-- =============================================================================
-- 1. AUTO-RELOAD
-- =============================================================================

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  if hs.fnutils.some(files, function(f) return f:sub(-4) == ".lua" end) then
    hs.reload()
  end
end):start()

-- Diagnostic: show status (helps debug "not working")
local function diagnostic()
  local ax = hs.axuielement.applicationElement(hs.application.frontmostApplication()):attributeValue("AXEnabled")
  local lines = {
    "Hammerspoon: running",
    "Config: loaded (you saw this)",
    "Accessibility: " .. (ax ~= false and "OK" or "MISSING – enable in System Settings → Privacy & Security → Accessibility"),
    "",
    "Quick test: Ctrl+Alt+Left (no Caps Lock) = snap left half",
    "If that works, nudge layer is OK.",
    "Hyper = Cmd+Ctrl+Alt+Shift (or Caps Lock if Karabiner is set up).",
  }
  hs.alert.show(table.concat(lines, "\n"), 6)
end
hs.hotkey.bind(hyper, "`", diagnostic)  -- hyper+backtick = diagnostic

require("hs.ipc")   -- enables the `hs` CLI for console debugging

hs.alert.show("Hammerspoon loaded", 1)

-- =============================================================================
-- 2. WINDOW MANAGEMENT
-- =============================================================================

local windowHistory = {}

local function saveFrame(win)
  local id = win:id()
  if not windowHistory[id] then windowHistory[id] = {} end
  local h = windowHistory[id]
  table.insert(h, win:frame():copy())
  if #h > 8 then table.remove(h, 1) end
end

local function snap(x, y, w, h)
  local win = hs.window.focusedWindow()
  if not win then return end
  saveFrame(win)
  win:moveToUnit(hs.geometry(x, y, w, h))
end

local function nudgeWin(dx, dy)
  local win = hs.window.focusedWindow()
  if not win then return end
  local f = win:frame()
  f.x, f.y = f.x + dx, f.y + dy
  win:setFrame(f, 0)
end

local function resizeWin(dw, dh)
  local win = hs.window.focusedWindow()
  if not win then return end
  local f = win:frame()
  f.w = math.max(200, f.w + dw)
  f.h = math.max(200, f.h + dh)
  win:setFrame(f, 0)
end

-- Halves  (nudge + arrows)
hs.hotkey.bind(nudge, "left",  function() snap(0,   0,   0.5, 1  ) end)
hs.hotkey.bind(nudge, "right", function() snap(0.5, 0,   0.5, 1  ) end)
hs.hotkey.bind(nudge, "up",    function() snap(0,   0,   1,   0.5) end)
hs.hotkey.bind(nudge, "down",  function() snap(0,   0.5, 1,   0.5) end)

-- Quarters  (nudge + u/i/j/k = top-left / top-right / bottom-left / bottom-right)
hs.hotkey.bind(nudge, "u", function() snap(0,   0,   0.5, 0.5) end)
hs.hotkey.bind(nudge, "i", function() snap(0.5, 0,   0.5, 0.5) end)
hs.hotkey.bind(nudge, "j", function() snap(0,   0.5, 0.5, 0.5) end)
hs.hotkey.bind(nudge, "k", function() snap(0.5, 0.5, 0.5, 0.5) end)

-- Thirds  (nudge + 1/2/3)
hs.hotkey.bind(nudge, "1", function() snap(0,    0, 1/3, 1) end)
hs.hotkey.bind(nudge, "2", function() snap(1/3,  0, 1/3, 1) end)
hs.hotkey.bind(nudge, "3", function() snap(2/3,  0, 1/3, 1) end)

-- Two-thirds  (nudge + 4/5)
hs.hotkey.bind(nudge, "4", function() snap(0,    0, 2/3, 1) end)
hs.hotkey.bind(nudge, "5", function() snap(1/3,  0, 2/3, 1) end)

-- Centered positions  (nudge + f/c/m/s)
hs.hotkey.bind(nudge, "f", function()
  local win = hs.window.focusedWindow()
  if win then saveFrame(win); win:maximize() end
end)
hs.hotkey.bind(nudge, "c", function() snap(0.1,  0.05, 0.8, 0.9) end)  -- large center
hs.hotkey.bind(nudge, "m", function() snap(0.2,  0.1,  0.6, 0.8) end)  -- medium center
hs.hotkey.bind(nudge, "s", function() snap(0.25, 0.15, 0.5, 0.7) end)  -- small center

-- Undo last window position  (nudge + z)
hs.hotkey.bind(nudge, "z", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local h = windowHistory[win:id()]
  if h and #h > 0 then
    win:setFrame(table.remove(h))
  else
    hs.alert.show("No window history", 1)
  end
end)

-- Fine-move  (mash + arrows  →  move by NUDGE_PX)
hs.hotkey.bind(mash, "left",  function() nudgeWin(-NUDGE_PX, 0)         end)
hs.hotkey.bind(mash, "right", function() nudgeWin( NUDGE_PX, 0)         end)
hs.hotkey.bind(mash, "up",    function() nudgeWin(0,         -NUDGE_PX) end)
hs.hotkey.bind(mash, "down",  function() nudgeWin(0,          NUDGE_PX) end)

-- Resize  (hyper + arrows  →  resize by NUDGE_PX)
hs.hotkey.bind(hyper, "left",  function() resizeWin(-NUDGE_PX, 0)         end)
hs.hotkey.bind(hyper, "right", function() resizeWin( NUDGE_PX, 0)         end)
hs.hotkey.bind(hyper, "up",    function() resizeWin(0,         -NUDGE_PX) end)
hs.hotkey.bind(hyper, "down",  function() resizeWin(0,          NUDGE_PX) end)

-- =============================================================================
-- 3. MULTI-MONITOR
-- =============================================================================

local function throwToScreen(dir)
  local win = hs.window.focusedWindow()
  if not win then return end
  local scr = (dir == "next") and win:screen():next() or win:screen():previous()
  win:moveToScreen(scr, true, true)
end

hs.hotkey.bind(nudge, "[", function() throwToScreen("prev") end)
hs.hotkey.bind(nudge, "]", function() throwToScreen("next") end)

-- =============================================================================
-- 4. WINDOW HINTS  (mash+space = all windows, mash+tab = current app)
-- =============================================================================

hs.hotkey.bind(mash, "space", hs.hints.windowHints)

hs.hotkey.bind(mash, "tab", function()
  local app = hs.application.frontmostApplication()
  hs.hints.windowHints(app and app:allWindows() or nil)
end)

-- =============================================================================
-- 5. APP LAUNCHER  (hyper + key)
-- =============================================================================

for key, app in pairs(APPS) do
  hs.hotkey.bind(hyper, key, function()
    hs.application.launchOrFocus(app)
  end)
end

-- =============================================================================
-- 6. CLIPBOARD HISTORY  (hyper+v = picker)
-- =============================================================================

local clipHistory = {}

hs.pasteboard.watcher.new(function(content)
  if type(content) == "string" and #content > 0 then
    if clipHistory[1] ~= content then
      table.insert(clipHistory, 1, content)
      if #clipHistory > CLIP_MAX then table.remove(clipHistory) end
    end
  end
end):start()

hs.hotkey.bind(hyper, "v", function()
  if #clipHistory == 0 then
    hs.alert.show("Clipboard history empty", 1.5)
    return
  end

  local choices = {}
  for i, clip in ipairs(clipHistory) do
    table.insert(choices, {
      text    = clip:gsub("%s+", " "):sub(1, 100),
      subText = string.format("[%d]  %d chars", i, #clip),
      idx     = i,
    })
  end

  local c = hs.chooser.new(function(choice)
    if choice then
      hs.pasteboard.setContents(clipHistory[choice.idx])
      hs.eventtap.keyStroke({"cmd"}, "v")
    end
  end)
  c:choices(choices)
  c:bgDark(true)
  c:width(65)
  c:rows(12)
  c:show()
end)

-- =============================================================================
-- 7. CAFFEINATE  (menubar icon — click or hyper+0 to toggle)
-- =============================================================================

local cafBar = hs.menubar.new()

local function refreshCafBar()
  if not cafBar then return end
  local on = hs.caffeinate.get("displayIdle")
  cafBar:setTitle(on and "[AWAKE]" or "[sleep]")
  cafBar:setTooltip(on and "Sleep: disabled  (click to re-enable)"
                       or  "Sleep: enabled   (click to disable)")
end

if cafBar then
  cafBar:setClickCallback(function()
    hs.caffeinate.toggle("displayIdle")
    refreshCafBar()
  end)
  refreshCafBar()
end

hs.hotkey.bind(hyper, "0", function()
  hs.caffeinate.toggle("displayIdle")
  refreshCafBar()
  hs.alert.show(hs.caffeinate.get("displayIdle") and "Caffeinate ON" or "Caffeinate OFF", 1.5)
end)

-- =============================================================================
-- 8. WINDOW MODE  (nudge+w to enter — vim-style modal control)
-- =============================================================================
--   hjkl        move window
--   HJKL        resize window
--   arrows      snap to half
--   u/i/b/n     snap to quarter (TL/TR/BL/BR)
--   f           maximize,  c = large center
--   [/]         throw to prev/next screen
--   q / Escape  exit window mode

local wm = hs.hotkey.modal.new(nudge, "w")
local wmAlertId

local wmStyle = {
  textColor  = {white = 1},
  fillColor  = {red = 0.08, green = 0.08, blue = 0.45, alpha = 0.92},
  textFont   = "Menlo",
  textSize   = 13,
  radius     = 6,
  atScreenEdge = 2,
}

function wm:entered()
  wmAlertId = hs.alert.show(
    "WINDOW MODE  |  hjkl=move  HJKL=resize  arrows=snap  [/]=screen  esc=exit",
    wmStyle, 9999)
end

function wm:exited()
  if wmAlertId then hs.alert.closeSpecific(wmAlertId) end
end

local WM = 30  -- pixels per step in window mode

local function wmBind(mods, key, fn)
  wm:bind(mods, key, fn, nil, fn)  -- fires on press AND repeat
end

wmBind("",      "h", function() nudgeWin(-WM, 0)   end)
wmBind("",      "l", function() nudgeWin( WM, 0)   end)
wmBind("",      "k", function() nudgeWin(0,  -WM)  end)
wmBind("",      "j", function() nudgeWin(0,   WM)  end)

wmBind("shift", "h", function() resizeWin(-WM, 0)  end)
wmBind("shift", "l", function() resizeWin( WM, 0)  end)
wmBind("shift", "k", function() resizeWin(0,  -WM) end)
wmBind("shift", "j", function() resizeWin(0,   WM) end)

wm:bind("", "left",  function() snap(0,   0,   0.5, 1  ) end)
wm:bind("", "right", function() snap(0.5, 0,   0.5, 1  ) end)
wm:bind("", "up",    function() snap(0,   0,   1,   0.5) end)
wm:bind("", "down",  function() snap(0,   0.5, 1,   0.5) end)

wm:bind("", "u", function() snap(0,   0,   0.5, 0.5) end)
wm:bind("", "i", function() snap(0.5, 0,   0.5, 0.5) end)
wm:bind("", "b", function() snap(0,   0.5, 0.5, 0.5) end)
wm:bind("", "n", function() snap(0.5, 0.5, 0.5, 0.5) end)

wm:bind("", "f", function()
  local win = hs.window.focusedWindow()
  if win then saveFrame(win); win:maximize() end
end)
wm:bind("", "c", function() snap(0.1, 0.05, 0.8, 0.9) end)
wm:bind("", "[", function() throwToScreen("prev") end)
wm:bind("", "]", function() throwToScreen("next") end)

wm:bind("", "escape", function() wm:exit() end)
wm:bind("", "q",      function() wm:exit() end)

-- =============================================================================
-- 9. SYSTEM WATCHERS
-- =============================================================================

-- Battery alerts
local lastBatt = hs.battery.percentage() or 100
hs.battery.watcher.new(function()
  local pct = hs.battery.percentage() or 100
  if not hs.battery.isCharging() then
    for _, threshold in ipairs(BATTERY_ALERTS) do
      if lastBatt > threshold and pct <= threshold then
        hs.notify.new({
          title           = "Low Battery",
          informativeText = string.format("Battery at %d%% — please charge", math.floor(pct)),
          autoWithdraw    = false,
        }):send()
        break
      end
    end
  end
  lastBatt = pct
end):start()

-- WiFi watcher
local lastSSID = hs.wifi.currentNetwork()
hs.wifi.watcher.new(function()
  local ssid = hs.wifi.currentNetwork()
  if ssid ~= lastSSID then
    hs.alert.show("Network: " .. (ssid or "(disconnected)"), 2)
    if ssid and WIFI_RULES[ssid] then WIFI_RULES[ssid]() end
    lastSSID = ssid
  end
end):start()

-- Screen watcher
hs.screen.watcher.new(function()
  hs.timer.doAfter(1, function()
    local n = #hs.screen.allScreens()
    hs.alert.show(string.format("%d display%s connected", n, n == 1 and "" or "s"), 2)
  end)
end):start()

-- USB watcher
hs.usb.watcher.new(function(data)
  local rule = USB_RULES[data.productName]
  if rule then
    local action = rule[data.eventType]
    if action then action() end
  end
end):start()

-- =============================================================================
-- 10. AUDIO CONTROLS
-- =============================================================================

local function setVolume(delta)
  local dev = hs.audiodevice.defaultOutputDevice()
  if not dev then return end
  local vol = math.min(100, math.max(0, (dev:volume() or 0) + delta))
  dev:setVolume(vol)
  hs.alert.show(string.format("Vol: %d%%", math.floor(vol)), 0.8)
end

hs.hotkey.bind(hyper, "=", function() setVolume( 5) end)
hs.hotkey.bind(hyper, "-", function() setVolume(-5) end)

hs.hotkey.bind(hyper, "9", function()
  local dev = hs.audiodevice.defaultOutputDevice()
  if not dev then return end
  dev:setMuted(not dev:muted())
  hs.alert.show(dev:muted() and "Muted" or "Unmuted", 1)
end)

-- Cycle audio output devices
hs.hotkey.bind(hyper, "8", function()
  local current = hs.audiodevice.defaultOutputDevice()
  local all = hs.audiodevice.allOutputDevices()
  for i, dev in ipairs(all) do
    if dev:uid() == current:uid() then
      local nxt = all[(i % #all) + 1]
      nxt:setDefaultOutputDevice()
      hs.alert.show("Audio out: " .. nxt:name(), 1.5)
      return
    end
  end
end)

-- =============================================================================
-- 11. DATE / TIME STAMPS
-- =============================================================================

-- hyper+d  →  2026-02-21
hs.hotkey.bind(hyper, "d", function()
  hs.eventtap.keyStrokes(os.date("%Y-%m-%d"))
end)

-- mash+d  →  2026-02-21T14:30:00
hs.hotkey.bind(mash, "d", function()
  hs.eventtap.keyStrokes(os.date("%Y-%m-%dT%H:%M:%S"))
end)

-- =============================================================================
-- 12. LAYOUT PRESETS  (hyper+l)
-- =============================================================================

hs.hotkey.bind(hyper, "l", function()
  local screens = hs.screen.allScreens()

  if #screens >= 2 then
    local layout = {}
    for _, entry in ipairs(LAYOUTS.dual) do
      local scr = screens[entry.screen] or screens[1]
      table.insert(layout, {entry.app, nil, scr, hs.geometry(entry.pos), nil, nil})
    end
    hs.layout.apply(layout)
    hs.alert.show("Dual-monitor layout applied", 1.5)
  else
    local layout = {}
    for _, entry in ipairs(LAYOUTS.single) do
      table.insert(layout, {entry.app, nil, screens[1], hs.geometry(entry.pos), nil, nil})
    end
    hs.layout.apply(layout)
    hs.alert.show("Single-monitor layout applied", 1.5)
  end
end)

-- =============================================================================
-- 13. SYSTEM HUD  (hyper+h)
-- =============================================================================

hs.hotkey.bind(hyper, "h", function()
  local dev   = hs.audiodevice.defaultOutputDevice()
  local batt  = hs.battery.percentage()
  local parts = {
    batt and string.format("Batt: %d%%%s", math.floor(batt),
      hs.battery.isCharging() and "+" or "") or "No battery",
    "WiFi: " .. (hs.wifi.currentNetwork() or "none"),
    string.format("Vol: %d%%", math.floor(dev and dev:volume() or 0)),
    string.format("Screens: %d", #hs.screen.allScreens()),
  }
  hs.alert.show(table.concat(parts, "   |   "), 3)
end)

-- =============================================================================
-- 14. LOCK SCREEN  (hyper+backspace)
-- =============================================================================

hs.hotkey.bind(hyper, "delete", function()
  hs.caffeinate.lockScreen()
end)

-- =============================================================================
-- 15. HELP OVERLAY  (hyper+q)
-- =============================================================================

local HELP = [[
WINDOW SNAPPING  (nudge = Ctrl+Alt)
  nudge + arrows       snap to half screen
  nudge + u/i/j/k      snap to quarter  (TL / TR / BL / BR)
  nudge + 1/2/3        snap to third
  nudge + 4/5          snap to two-thirds
  nudge + f            maximize
  nudge + c/m/s        center  (large / medium / small)
  nudge + z            undo last move
  nudge + [/]          throw to prev/next screen
  nudge + w            enter WINDOW MODE (hjkl/HJKL, esc to exit)

FINE CONTROL
  mash  + arrows       move window by pixel
  hyper + arrows       resize window by pixel
  mash  + space        window hints  (all windows)
  mash  + tab          window hints  (current app)

APP LAUNCHER  (hyper = Cmd+Ctrl+Alt+Shift)
  hyper + a/b/c/e/f/g/i/m/n/o/p/r/s/t/w/x/z

SYSTEM
  hyper + v            clipboard history picker
  hyper + 0            toggle caffeinate
  hyper + -/=          volume down / up
  hyper + 9            mute toggle
  hyper + 8            cycle audio output device
  hyper + d            insert date  (YYYY-MM-DD)
  mash  + d            insert ISO timestamp
  hyper + l            apply layout preset
  hyper + h            system HUD
  hyper + delete       lock screen
  hyper + q            this help
]]

local helpStyle = {
  textColor  = {white = 1},
  fillColor  = {red = 0, green = 0, blue = 0, alpha = 0.93},
  textFont   = "Menlo",
  textSize   = 12,
  radius     = 8,
}

hs.hotkey.bind(hyper, "q", function()
  hs.alert.show(HELP, helpStyle, hs.screen.mainScreen(), 10)
end)

-- =============================================================================
-- 16. BUNNY  (hyper+y, nudge+y, or nudge+b to toggle)
-- =============================================================================
-- NOTE: Ctrl+Option+y is sometimes captured by input methods / keyboard layout.
-- If nudge+y doesn't work, try nudge+b (B for bunny) or hyper+y.

local bunny = require("bunny")
hs.hotkey.bind(hyper, "y", function() bunny.toggle() end)
hs.hotkey.bind(nudge, "y", function() bunny.toggle() end)
hs.hotkey.bind(nudge, "b", function() bunny.toggle() end)  -- fallback if Ctrl+Opt+y is captured
hs.hotkey.bind(nudge, "h", function() bunny.scare() end)  -- nudge+h = scare into rabbit hole

-- =============================================================================
-- 17. PIG  (hyper+p, nudge+p to toggle, nudge+m to scare into mud)
-- =============================================================================

local pig = require("pig")
hs.hotkey.bind(hyper, "p", function() pig.toggle() end)
hs.hotkey.bind(nudge, "p", function() pig.toggle() end)
hs.hotkey.bind(nudge, "m", function() pig.scare() end)  -- nudge+m = scare into mud puddle

-- =============================================================================
-- 18. BALL  (nudge+t to throw — bounces, pets jump when hit)
-- =============================================================================

local ball = require("ball")
ball.registerPet(bunny)
ball.registerPet(pig)
hs.hotkey.bind(nudge, "t", function() ball.throw() end)

-- Run all tests: mash+` (backtick)
hs.hotkey.bind(mash, "`", function()
  package.loaded["tests"] = nil
  require("tests")
end)
