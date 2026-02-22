-- ~/.hammerspoon/pig.lua
-- A desktop pet pig that trots across the bottom of your screen.
--
-- Load in init.lua:
--   local pig = require("pig")
--   hs.hotkey.bind(hyper, "p", function() pig.toggle() end)

local M = {}
math.randomseed(os.time())

-- ─── canvas dimensions ───────────────────────────────────────────────────────
local CW, CH = 110, 110

-- ─── colors ──────────────────────────────────────────────────────────────────
local WHITE     = {red=1,    green=1,    blue=1,    alpha=1   }
local PINK      = {red=1,    green=0.75, blue=0.80, alpha=1   }
local PINKDARK  = {red=0.95, green=0.65, blue=0.72, alpha=1   }
local DARK      = {red=0.12, green=0.08, blue=0.12, alpha=1   }
local SOFTGRAY  = {red=0.72, green=0.72, blue=0.72, alpha=0.35}
local CLEAR     = {red=0,    green=0,    blue=0,    alpha=0   }
local HEARTRED  = {red=1,    green=0.2,  blue=0.3,  alpha=1   }
local MUD       = {red=0.35, green=0.22, blue=0.15, alpha=1   }   -- mud puddle
local MUD_STROKE= {red=0.28, green=0.18, blue=0.12, alpha=1   }

-- ─── element indices (same in both canvases) ─────────────────────────────────
local I = {
  tail=1, body=2, head=3, snout=4, nostrilL=5, nostrilR=6,
  earFar=7, earNear=8,
  eye=9, mouth=10, zzz=11,
  backArm=12, frontArm=13, heart=14,
  bubble=15, bubbleTail=16, waveEmoji=17,
  footL=18, footR=19,
  eye2=20,  -- roll pose (face-on)
}
local HIDDEN = {x=0, y=0, w=0, h=0}

-- ─── base frames for facing RIGHT ────────────────────────────────────────────
local BR = {
  tail      = {x=4,  y=72, w=16, h=12},   -- curly tail (oval for now)
  body      = {x=8,  y=58, w=58, h=44},   -- round body
  head      = {x=28, y=24, w=48, h=50},   -- head
  snout     = {x=68, y=48, w=20, h=18},   -- protruding snout
  nostrilL   = {x=72, y=58, w=4,  h=4 },  -- left nostril
  nostrilR   = {x=80, y=58, w=4,  h=4 },  -- right nostril
  earFar    = {x=52, y=4,  w=16, h=24},   -- floppy ear (wider than tall)
  earNear   = {x=36, y=2,  w=18, h=26},
  eye       = {x=58, y=42, w=10, h=10},
  mouth     = {x=62, y=58, w=20, h=14},
  zzz       = {x=44, y=2,  w=36, h=14},
  -- Heart pose
  backArm   = {x=10, y=72, w=12, h=10},
  frontArm  = {x=72, y=68, w=14, h=12},
  heart     = {x=90, y=46, w=20, h=20},
  -- Wave pose (thought bubble)
  bubble    = {x=18, y=0,  w=52, h=32},   -- slightly bigger, moved up for full rounded bottom
  bubbleTail= {x=52, y=30, w=8,  h=8 },
  waveEmoji = {x=28, y=6,  w=32, h=22},   -- 👋 in bubble
  -- Roll pose feet
  footL     = {x=14, y=86, w=20, h=16},
  footR     = {x=54, y=86, w=20, h=16},
}

-- Roll pose: pig lying down (like layback)
local ROLL_R = {
  body    = {x=4,   y=72, w=88, h=26},
  head    = {x=32,  y=36, w=38, h=40},
  tail    = {x=12,  y=76, w=14, h=10},
  earFar  = {x=52,  y=10, w=16, h=22},
  earNear = {x=28,  y=8,  w=18, h=24},
  eye     = {x=54,  y=54, w=8,  h=8 },
  eye2    = {x=38,  y=54, w=8,  h=8 },
  snout   = {x=56,  y=64, w=14, h=12},
  mouth   = {x=40,  y=68, w=16, h=10},
}

-- Mud puddle: pig hiding (scared)
local MUD_PUDDLE = {
  hole    = {x=14,  y=76,  w=82,  h=34},
  earFar  = {x=52,  y=38,  w=14,  h=36},
  earNear = {x=38,  y=35,  w=16,  h=40},
  head    = {x=30,  y=56,  w=48,  h=34},
  eye     = {x=42,  y=66,  w=8,   h=8 },
  eye2    = {x=58,  y=66,  w=8,   h=8 },
  snout   = {x=48,  y=76,  w=12,  h=10},
  mouth   = {x=38,  y=78,  w=30,  h=10},
}

-- ─── mirror function ────────────────────────────────────────────────────────
local function mir(f)
  return {x = CW - f.x - f.w, y = f.y, w = f.w, h = f.h}
end

-- ─── base frames for facing LEFT ─────────────────────────────────────────────
local BL = {
  tail      = mir(BR.tail),
  body      = mir(BR.body),
  head      = mir(BR.head),
  snout     = mir(BR.snout),
  nostrilL   = mir(BR.nostrilL),
  nostrilR   = mir(BR.nostrilR),
  earFar    = mir(BR.earNear),   -- depth swap
  earNear   = mir(BR.earFar),
  eye       = mir(BR.eye),
  mouth     = mir(BR.mouth),
  zzz       = mir(BR.zzz),
  backArm   = mir(BR.backArm),
  frontArm  = mir(BR.frontArm),
  heart     = mir(BR.heart),
  bubble    = mir(BR.bubble),
  bubbleTail= mir(BR.bubbleTail),
  waveEmoji = mir(BR.waveEmoji),
  footL     = mir(BR.footL),
  footR     = mir(BR.footR),
}

local ROLL_L = {
  body    = mir(ROLL_R.body),
  head    = mir(ROLL_R.head),
  tail    = mir(ROLL_R.tail),
  earFar  = mir(ROLL_R.earNear),
  earNear = mir(ROLL_R.earFar),
  eye     = mir(ROLL_R.eye),
  eye2    = mir(ROLL_R.eye2),
  snout   = mir(ROLL_R.snout),
  mouth   = mir(ROLL_R.mouth),
}

-- ─── state ───────────────────────────────────────────────────────────────────
M._dir = 1

local canvasR, canvasL
local canvas
local base

local timer, keyTap, noiseListener
local posX
local state      = "trot"
local stateAge   = 0
local trotPhase   = 0
local earWiggle  = 0
local blinkIn    = 120 + math.random(80)
local zOff       = 0
local zAge       = 0
local tailWiggle = 0

-- ─── animation parameters ────────────────────────────────────────────────────
local TROT  = 1.4
local SWAY  = 3
local TROTR = 0.08
local EARB  = 3

local rollFrames
local mudActive

-- ─── canvas construction ─────────────────────────────────────────────────────
local function buildCanvas(f)
  local c = hs.canvas.new({x=0, y=0, w=CW, h=CH})
  c:appendElements(
    { type="oval",      frame=f.tail,      fillColor=PINK,     strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",     frame=f.body,      fillColor=PINK,     strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",     frame=f.head,      fillColor=PINK,     strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",     frame=f.snout,     fillColor=PINKDARK,  strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",     frame=f.nostrilL,  fillColor=DARK,      strokeColor=CLEAR,    strokeWidth=0 },
    { type="oval",     frame=f.nostrilR,  fillColor=DARK,      strokeColor=CLEAR,    strokeWidth=0 },
    { type="rectangle", frame=f.earFar,   fillColor=PINK,      strokeColor=SOFTGRAY, strokeWidth=1, roundedRectRadii={xRadius=8,yRadius=4} },
    { type="rectangle", frame=f.earNear,  fillColor=PINK,      strokeColor=SOFTGRAY, strokeWidth=1, roundedRectRadii={xRadius=9,yRadius=5} },
    { type="oval",     frame=f.eye,      fillColor=DARK,      strokeColor=CLEAR,    strokeWidth=0 },
    { type="text",     frame=f.mouth,    textAlignment="center",
      text=hs.styledtext.new("ω", {font={name="Helvetica", size=12}, color=DARK}) },
    { type="text",     frame=f.zzz,      textAlignment="left",
      text=hs.styledtext.new("z z z", {font={name="Helvetica", size=10}, color=CLEAR}) },
    { type="oval",     frame=HIDDEN,     fillColor=PINK,      strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",     frame=HIDDEN,     fillColor=PINK,      strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="text",     frame=HIDDEN,     textAlignment="center",
      text=hs.styledtext.new("♥", {font={name="Helvetica", size=20}, color=HEARTRED}) },
    { type="rectangle", frame=HIDDEN,    fillColor=WHITE,     strokeColor=SOFTGRAY, strokeWidth=1, roundedRectRadii={xRadius=12,yRadius=12} },
    { type="oval",     frame=HIDDEN,     fillColor=WHITE,     strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="text",     frame=HIDDEN,     textAlignment="center",
      text=hs.styledtext.new("👋", {font={name="Apple Color Emoji", size=20}}) },
    { type="oval",     frame=HIDDEN,     fillColor=PINK,     strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",     frame=HIDDEN,     fillColor=PINK,     strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",     frame=HIDDEN,     fillColor=DARK,     strokeColor=CLEAR,    strokeWidth=0 }
  )
  return c
end

local function setupCanvas(c, x, y)
  c:level(hs.canvas.windowLevels.floating)
  pcall(function() c:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces) end)
  c:topLeft({x=math.floor(x), y=math.floor(y)})
end

-- ─── state helpers ───────────────────────────────────────────────────────────
local function closeEyes()
  if state == "roll" and rollFrames then
    local e1, e2 = rollFrames.eye, rollFrames.eye2
    canvas[I.eye].frame  = {x=e1.x, y=e1.y + 3, w=e1.w, h=2}
    canvas[I.eye2].frame = {x=e2.x, y=e2.y + 3, w=e2.w, h=2}
  elseif state == "inmud" and mudActive then
    local e1, e2 = MUD_PUDDLE.eye, MUD_PUDDLE.eye2
    canvas[I.eye].frame  = {x=e1.x, y=e1.y + 3, w=e1.w, h=2}
    canvas[I.eye2].frame = {x=e2.x, y=e2.y + 3, w=e2.w, h=2}
  else
    local ef = base.eye
    canvas[I.eye].frame = {x=ef.x, y=ef.y + 4, w=ef.w, h=2}
  end
end

local function openEyes()
  if state == "roll" and rollFrames then
    canvas[I.eye].frame  = rollFrames.eye
    canvas[I.eye2].frame = rollFrames.eye2
  elseif state == "inmud" and mudActive then
    canvas[I.eye].frame  = MUD_PUDDLE.eye
    canvas[I.eye2].frame = MUD_PUDDLE.eye2
  else
    canvas[I.eye].frame = base.eye
  end
end

local function hideHeartPose()
  canvas[I.backArm].frame = HIDDEN
  canvas[I.frontArm].frame = HIDDEN
  canvas[I.heart].frame = HIDDEN
end

local function hideWavePose()
  canvas[I.bubble].frame = HIDDEN
  canvas[I.bubbleTail].frame = HIDDEN
  canvas[I.waveEmoji].frame = HIDDEN
end

local function setState(s)
  state = s
  stateAge = 0
  zOff = 0
  zAge = 0
  hideHeartPose()
  hideWavePose()
  if s == "oink" then
    canvas[I.mouth].frame = {x=base.mouth.x - 4, y=base.mouth.y, w=base.mouth.w + 8, h=base.mouth.h}
    canvas[I.mouth].text = hs.styledtext.new("oink", {font={name="Helvetica", size=10}, color=DARK})
  elseif s ~= "roll" and s ~= "inmud" then
    canvas[I.mouth].frame = base.mouth
    canvas[I.mouth].text = hs.styledtext.new("ω", {font={name="Helvetica", size=12}, color=DARK})
  end
  if s ~= "roll" and s ~= "inmud" and (rollFrames or mudActive) then
    canvas[I.body].frame = base.body
    canvas[I.body].fillColor = PINK
    canvas[I.body].strokeColor = SOFTGRAY
    canvas[I.body].strokeWidth = 1
    canvas[I.head].frame = base.head
    canvas[I.tail].frame = base.tail
    canvas[I.snout].frame = base.snout
    canvas[I.nostrilL].frame = base.nostrilL
    canvas[I.nostrilR].frame = base.nostrilR
    canvas[I.earFar].frame = base.earFar
    canvas[I.earNear].frame = base.earNear
    canvas[I.eye].frame = base.eye
    canvas[I.eye2].frame = HIDDEN
    canvas[I.mouth].frame = base.mouth
    canvas[I.footL].frame = HIDDEN
    canvas[I.footR].frame = HIDDEN
    rollFrames = nil
    mudActive = false
  end
end

local function showHeartPose()
  canvas[I.backArm].frame = base.backArm
  canvas[I.frontArm].frame = base.frontArm
  canvas[I.heart].frame = base.heart
  hideWavePose()
  canvas[I.footL].frame = HIDDEN
  canvas[I.footR].frame = HIDDEN
end

local function showWavePose()
  canvas[I.bubble].frame = base.bubble
  canvas[I.bubbleTail].frame = base.bubbleTail
  canvas[I.waveEmoji].frame = base.waveEmoji
  hideHeartPose()
  canvas[I.footL].frame = HIDDEN
  canvas[I.footR].frame = HIDDEN
end

local function showRollPose()
  rollFrames = (M._dir == 1) and ROLL_R or ROLL_L
  canvas[I.body].frame = rollFrames.body
  canvas[I.head].frame = rollFrames.head
  canvas[I.tail].frame = rollFrames.tail
  canvas[I.earFar].frame = rollFrames.earFar
  canvas[I.earNear].frame = rollFrames.earNear
  canvas[I.eye].frame = rollFrames.eye
  canvas[I.eye2].frame = rollFrames.eye2
  canvas[I.snout].frame = rollFrames.snout
  canvas[I.mouth].frame = rollFrames.mouth
  hideHeartPose()
  hideWavePose()
  canvas[I.footL].frame = base.footL
  canvas[I.footR].frame = base.footR
end

local function showMudPose()
  mudActive = true
  canvas[I.tail].frame = HIDDEN
  canvas[I.body].frame = MUD_PUDDLE.hole
  canvas[I.body].fillColor = MUD
  canvas[I.body].strokeColor = MUD_STROKE
  canvas[I.body].strokeWidth = 2
  canvas[I.earFar].frame = MUD_PUDDLE.earFar
  canvas[I.earNear].frame = MUD_PUDDLE.earNear
  canvas[I.head].frame = MUD_PUDDLE.head
  canvas[I.eye].frame = MUD_PUDDLE.eye
  canvas[I.eye2].frame = MUD_PUDDLE.eye2
  canvas[I.snout].frame = MUD_PUDDLE.snout
  canvas[I.mouth].frame = MUD_PUDDLE.mouth
  canvas[I.nostrilL].frame = HIDDEN
  canvas[I.nostrilR].frame = HIDDEN
  hideHeartPose()
  hideWavePose()
  canvas[I.footL].frame = HIDDEN
  canvas[I.footR].frame = HIDDEN
end

-- Flip direction
local function flip(gY)
  canvas:hide()
  M._dir = M._dir * -1
  if M._dir == 1 then
    canvas = canvasR
    base = BR
  else
    canvas = canvasL
    base = BL
  end
  canvas:topLeft({x=math.floor(posX), y=math.floor(gY)})
  canvas:show()
end

-- ─── animation loop (~30 fps) ─────────────────────────────────────────────────
local function animate()
  if not canvas then return end

  stateAge = stateAge + 1
  blinkIn = blinkIn - 1

  local screen = hs.screen.mainScreen():frame()
  local gY = screen.y + screen.h - CH - 22

  -- BLINK
  if blinkIn <= 0 then
    blinkIn = 120 + math.random(120)
    closeEyes()
    hs.timer.doAfter(0.12, function()
      if canvas and state ~= "sleep" then openEyes() end
    end)
  end

  -- EAR WIGGLE
  if earWiggle > 0 and state ~= "inmud" then
    earWiggle = earWiggle - 1
    local wobble = ((earWiggle % 2 == 0) and 3 or -3) * M._dir
    local nf, ff = base.earNear, base.earFar
    canvas[I.earNear].frame = {x=nf.x + wobble, y=nf.y, w=nf.w, h=nf.h}
    canvas[I.earFar].frame  = {x=ff.x + wobble, y=ff.y, w=ff.w, h=ff.h}
    if earWiggle == 0 then
      canvas[I.earNear].frame = base.earNear
      canvas[I.earFar].frame  = base.earFar
    end
  end

  -- TROT
  if state == "trot" then
    trotPhase = trotPhase + TROTR
    local sway = math.sin(trotPhase) * SWAY

    if earWiggle == 0 then
      local bob = math.abs(math.sin(trotPhase)) * EARB
      local nf, ff = base.earNear, base.earFar
      canvas[I.earNear].frame = {x=nf.x, y=nf.y + bob, w=nf.w, h=nf.h}
      canvas[I.earFar].frame  = {x=ff.x, y=ff.y + bob, w=ff.w, h=ff.h}
    end

    posX = posX + M._dir * TROT

    local minX = screen.x + 14
    local maxX = screen.x + screen.w - CW - 14
    if posX >= maxX then posX = maxX; flip(gY)
    elseif posX <= minX then posX = minX; flip(gY)
    end

    canvas:topLeft({x=math.floor(posX), y=math.floor(gY + sway)})

    if stateAge > 360 and math.random() < 0.005 then
      setState("roll"); showRollPose()
    elseif stateAge > 220 and math.random() < 0.004 then
      setState("idle")
    end

  elseif state == "idle" then
    canvas:topLeft({x=math.floor(posX), y=gY})
    if math.random() < 0.008 then earWiggle = 12 end
    if stateAge > 200 then
      local r = math.random()
      if r < 0.005 then setState("sleep"); closeEyes()
      elseif r < 0.010 then setState("trot") end
    end

  elseif state == "heart" then
    canvas:topLeft({x=math.floor(posX), y=gY})
    if stateAge > 75 then setState("idle") end

  elseif state == "wave" then
    canvas:topLeft({x=math.floor(posX), y=gY})
    if stateAge > 75 then setState("idle") end

  elseif state == "oink" then
    canvas:topLeft({x=math.floor(posX), y=gY})
    if stateAge > 45 then setState("idle") end

  elseif state == "roll" then
    canvas:topLeft({x=math.floor(posX), y=gY})
    if stateAge > 140 and math.random() < 0.012 then setState("trot") end

  elseif state == "inmud" then
    local peek = math.sin(stateAge * 0.06) * 4
    canvas[I.earFar].frame   = {x=MUD_PUDDLE.earFar.x + peek,   y=MUD_PUDDLE.earFar.y,   w=MUD_PUDDLE.earFar.w,   h=MUD_PUDDLE.earFar.h}
    canvas[I.earNear].frame  = {x=MUD_PUDDLE.earNear.x + peek, y=MUD_PUDDLE.earNear.y, w=MUD_PUDDLE.earNear.w, h=MUD_PUDDLE.earNear.h}
    canvas[I.head].frame     = {x=MUD_PUDDLE.head.x + peek,    y=MUD_PUDDLE.head.y,    w=MUD_PUDDLE.head.w,    h=MUD_PUDDLE.head.h}
    canvas[I.eye].frame     = {x=MUD_PUDDLE.eye.x + peek,     y=MUD_PUDDLE.eye.y,     w=MUD_PUDDLE.eye.w,     h=MUD_PUDDLE.eye.h}
    canvas[I.eye2].frame    = {x=MUD_PUDDLE.eye2.x + peek,    y=MUD_PUDDLE.eye2.y,    w=MUD_PUDDLE.eye2.w,    h=MUD_PUDDLE.eye2.h}
    canvas[I.snout].frame   = {x=MUD_PUDDLE.snout.x + peek,    y=MUD_PUDDLE.snout.y,   w=MUD_PUDDLE.snout.w,   h=MUD_PUDDLE.snout.h}
    canvas[I.mouth].frame   = {x=MUD_PUDDLE.mouth.x + peek,   y=MUD_PUDDLE.mouth.y,  w=MUD_PUDDLE.mouth.w,  h=MUD_PUDDLE.mouth.h}
    canvas:topLeft({x=math.floor(posX), y=gY})
    if stateAge > 90 and math.random() < 0.008 then setState("trot") end

  elseif state == "sleep" then
    canvas:topLeft({x=math.floor(posX), y=gY})
    zAge = zAge + 1
    if zAge % 90 == 0 then zOff = 0 end
    zOff = zOff + 0.5
    local alpha = math.max(0, 1 - zOff / 32)
    local zf = base.zzz
    canvas[I.zzz].frame = {x=zf.x, y=zf.y - zOff, w=zf.w, h=zf.h}
    canvas[I.zzz].text = hs.styledtext.new("z z z", {font={name="Helvetica", size=10}, color={red=0.55, green=0.78, blue=1, alpha=alpha}})
    if stateAge > 420 and math.random() < 0.004 then
      openEyes()
      canvas[I.zzz].text = hs.styledtext.new("z z z", {font={name="Helvetica", size=10}, color=CLEAR})
      setState("trot")
    end
  end
end

-- ─── public API ──────────────────────────────────────────────────────────────

function M.start()
  if canvas then return end

  local ok, err = pcall(function()
    local screen = hs.screen.mainScreen():frame()
    posX = screen.x + math.floor(screen.w * 0.45)
    M._dir = 1

    local gY = math.floor(screen.y + screen.h - CH - 22)

    canvasR = buildCanvas(BR)
    canvasL = buildCanvas(BL)
    setupCanvas(canvasR, posX, gY)
    setupCanvas(canvasL, posX, gY)

    canvas = canvasR
    base = BR
    canvas:show()

    timer = hs.timer.new(1/30, animate)
    timer:start()

    -- React to sounds (pops → inmud, tongue click → wake / heart / wave)
    local okNoise, errNoise = pcall(function()
      if hs.noises then
        noiseListener = hs.noises.new(function(evType)
          if evType == 3 then  -- pop = scary, jump in mud
            if state == "sleep" then
              openEyes()
              canvas[I.zzz].text = hs.styledtext.new("z z z", {font={name="Helvetica", size=10}, color=CLEAR})
              setState("inmud"); showMudPose()
            elseif state == "trot" or state == "idle" or state == "heart" or state == "wave" or state == "oink" or state == "roll" then
              setState("inmud"); showMudPose()
            elseif state == "inmud" then
              stateAge = 0
            end
          else  -- tongue click
            earWiggle = 12
            if state == "sleep" then
              openEyes()
              canvas[I.zzz].text = hs.styledtext.new("z z z", {font={name="Helvetica", size=10}, color=CLEAR})
              setState("idle")
            elseif (state == "trot" or state == "idle") and stateAge > 20 then
              local r = math.random()
              if r < 0.12 then setState("heart"); showHeartPose()
              elseif r < 0.24 then setState("wave"); showWavePose()
              elseif r < 0.30 then setState("oink") end
            end
          end
        end)
        noiseListener:start()
      end
    end)
    if not okNoise then hs.logger.new("pig"):w("Sound reactivity unavailable: " .. tostring(errNoise)) end

    keyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function()
      if state == "inmud" then
        setState("trot")
        return false
      end
      if state == "roll" then
        setState("trot")
        return false
      end
      if state == "sleep" then
        openEyes()
        canvas[I.zzz].text = hs.styledtext.new("z z z", {font={name="Helvetica", size=10}, color=CLEAR})
        setState("idle")
        return false
      end
      if (state == "trot" or state == "idle") and stateAge > 30 then
        local r = math.random()
        if r < 0.10 then setState("heart"); showHeartPose(); return false
        elseif r < 0.20 then setState("wave"); showWavePose(); return false
        elseif r < 0.28 then setState("oink"); return false
        elseif r < 0.35 then setState("roll"); showRollPose(); return false
        end
      end
      earWiggle = 10
      return false
    end)
    keyTap:start()
  end)

  if not ok then
    hs.alert.show("Pig error:\n" .. tostring(err), 6)
    if canvasR then canvasR:delete(); canvasR = nil end
    if canvasL then canvasL:delete(); canvasL = nil end
    canvas = nil
    if timer then timer:stop(); timer = nil end
    if keyTap then keyTap:stop(); keyTap = nil end
  end
end

function M.stop()
  if timer then timer:stop(); timer = nil end
  if keyTap then keyTap:stop(); keyTap = nil end
  if noiseListener then pcall(function() noiseListener:stop() end); noiseListener = nil end
  if canvasR then canvasR:hide(); canvasR:delete(); canvasR = nil end
  if canvasL then canvasL:hide(); canvasL:delete(); canvasL = nil end
  canvas = nil
end

function M.toggle()
  if canvas then M.stop() else M.start() end
end

function M.scare()
  if not canvas then return end
  if state == "sleep" then
    openEyes()
    canvas[I.zzz].text = hs.styledtext.new("z z z", {font={name="Helvetica", size=10}, color=CLEAR})
  end
  if state == "trot" or state == "idle" or state == "heart" or state == "wave" or state == "oink" or state == "roll" or state == "sleep" then
    setState("inmud")
    showMudPose()
  end
end

-- ─── test exports ─────────────────────────────────────────────────────────────
M._mir = mir
M._B = BR
M._BL = BL
M._ROLL_R = ROLL_R
M._ROLL_L = ROLL_L
M._MUD_PUDDLE = MUD_PUDDLE
M._CW = CW
M._CH = CH
M._TROT = TROT
M._SWAY = SWAY
M._getState = function() return state end
M._getCanvas = function() return canvas end

return M
