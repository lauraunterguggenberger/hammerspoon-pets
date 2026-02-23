-- ~/.hammerspoon/bunny.lua
-- A desktop pet bunny that hops across the bottom of your screen.
--
-- Load in init.lua:
--   local bunny = require("bunny")
--   hs.hotkey.bind(hyper, "y", function() bunny.toggle() end)

local M = {}
math.randomseed(os.time())

-- ─── canvas dimensions ───────────────────────────────────────────────────────
local CW, CH = 110, 110  -- expanded for heart and layback

-- ─── colors ──────────────────────────────────────────────────────────────────
local WHITE    = {red=1,    green=1,    blue=1,    alpha=1   }
local DIMWHITE = {red=0.93, green=0.93, blue=0.93, alpha=1   }
local PINK     = {red=1,    green=0.70, blue=0.76, alpha=1   }
local PINKDIM  = {red=1,    green=0.80, blue=0.85, alpha=0.7 }
local DARK     = {red=0.12, green=0.08, blue=0.12, alpha=1   }
local SOFTGRAY = {red=0.72, green=0.72, blue=0.72, alpha=0.35}
local CLEAR    = {red=0,    green=0,    blue=0,    alpha=0   }
local HEARTRED = {red=1,    green=0.2,  blue=0.3,  alpha=1   }
local BLOODRED = {red=0.7,  green=0.05, blue=0.05, alpha=1   }  -- vampire fangs/blood
local BLACK    = {red=0.05, green=0.05, blue=0.08, alpha=1   }  -- hole interior

-- ─── element indices (same in both canvases) ─────────────────────────────────
local I = {
  tail=1, body=2, head=3,
  earFar=4, earNear=5, innerFar=6, innerNear=7,
  eye=8, nose=9, mouth=10, zzz=11,
  backArm=12, frontArm=13, heart=14, footL=15, footR=16,
  eye2=17,  -- second eye (layback only; face-on view)
  fangL=18, fangR=19, bloodDrop=20,  -- vampire: fangs (white) + mouth
  bubble=21, bubbleTail=22, bloodEmoji=23,  -- unused (thought bubble removed)
  mouthArc=24,  -- Pac-Man style open mouth (ellipticalArc)
  tooth1=25, tooth2=26, tooth3=27, tooth4=28, tooth5=29, tooth6=30,
}
local HIDDEN = {x=0, y=0, w=0, h=0}

-- ─── base frames for facing RIGHT ────────────────────────────────────────────
local BR = {
  tail      = {x=3,  y=74, w=18, h=13},
  body      = {x=6,  y=62, w=62, h=42},
  head      = {x=25, y=28, w=56, h=54},
  earFar    = {x=58, y=1,  w=13, h=44},  -- DIMWHITE, drawn behind
  earNear   = {x=40, y=0,  w=14, h=46},  -- WHITE, drawn in front
  innerFar  = {x=61, y=5,  w=7,  h=36},
  innerNear = {x=43, y=4,  w=8,  h=38},
  eye       = {x=64, y=46, w=12, h=12},
  nose      = {x=76, y=59, w=8,  h=7 },
  mouth     = {x=62, y=61, w=22, h=18},
  zzz       = {x=52, y=6,  w=38, h=16},  -- floats above head (face side)
  -- Heart pose: arm extended with paw, heart
  backArm   = {x=8,  y=68, w=12, h=8 },  -- rear arm (behind body)
  frontArm  = {x=68, y=70, w=14, h=10},  -- paw holding heart (facing right)
  heart     = {x=88, y=52, w=22, h=22},  -- ♥ next to paw (bigger)
  -- Lay-back pose: reclined body, prominent hind feet
  footL     = {x=12, y=88, w=22, h=18},
  footR     = {x=51, y=88, w=22, h=18},
  -- Vampire mode: red fangs + blood drop (replace nose)
  fangL     = {x=74, y=57, w=4,  h=14},
  fangR     = {x=82, y=57, w=4,  h=14},
  bloodDrop = {x=77, y=68, w=6,  h=8 },
}

-- Lay-back pose: body/head/tail/ears repositioned for reclined posture
local LAYBACK_R = {
  body    = {x=2,   y=72, w=86, h=28},  -- flatter, wider (horizontal)
  head    = {x=30,  y=38, w=40, h=42},  -- smaller, tilted back
  tail    = {x=10,  y=78, w=16, h=12},
  earFar  = {x=48,  y=8,  w=18, h=36},  -- splayed back/down
  earNear = {x=28,  y=6,  w=20, h=38},
  innerFar = {x=52, y=12, w=10, h=28},
  innerNear= {x=30, y=10, w=12, h=30},
  eye     = {x=54,  y=58, w=9,  h=9 },  -- right eye (face-on)
  eye2    = {x=37,  y=58, w=9,  h=9 },  -- left eye (face-on)
  nose    = {x=55,  y=68, w=6,  h=6 },
  mouth   = {x=38,  y=70, w=18, h=14},
  fangL   = {x=52,  y=66, w=3,  h=12},
  fangR   = {x=58,  y=66, w=3,  h=12},
  bloodDrop = {x=54, y=74, w=5, h=6 },
}

-- ─── base frames for facing LEFT (pre-computed, ears swapped for correct depth)
local function mir(f)  return {x = CW - f.x - f.w, y = f.y, w = f.w, h = f.h}  end

local BL = {
  tail      = mir(BR.tail),
  body      = mir(BR.body),
  head      = mir(BR.head),
  -- Ears swap so the WHITE (near) ear is always on the face side
  earFar    = mir(BR.earNear),   -- DIMWHITE behind element → right position
  earNear   = mir(BR.earFar),    -- WHITE front element     → left position
  innerFar  = mir(BR.innerNear),
  innerNear = mir(BR.innerFar),
  eye       = mir(BR.eye),
  nose      = mir(BR.nose),
  mouth     = mir(BR.mouth),
  zzz       = mir(BR.zzz),
  backArm   = mir(BR.backArm),
  frontArm  = mir(BR.frontArm),
  heart     = mir(BR.heart),
  footL     = mir(BR.footL),
  footR     = mir(BR.footR),
  fangL     = mir(BR.fangL),
  fangR     = mir(BR.fangR),
  bloodDrop = mir(BR.bloodDrop),
}

local LAYBACK_L = {
  body    = mir(LAYBACK_R.body),
  head    = mir(LAYBACK_R.head),
  tail    = mir(LAYBACK_R.tail),
  earFar  = mir(LAYBACK_R.earNear),  -- depth swap like BL
  earNear = mir(LAYBACK_R.earFar),
  innerFar = mir(LAYBACK_R.innerNear),
  innerNear= mir(LAYBACK_R.innerFar),
  eye     = mir(LAYBACK_R.eye),
  eye2     = mir(LAYBACK_R.eye2),
  nose     = mir(LAYBACK_R.nose),
  mouth    = mir(LAYBACK_R.mouth),
  fangL    = mir(LAYBACK_R.fangL),
  fangR    = mir(LAYBACK_R.fangR),
  bloodDrop= mir(LAYBACK_R.bloodDrop),
}

-- Vampire pose: face-on, Pac-Man mouth with teeth
-- Head is enlarged so the big mouth fits proportionally inside the face
local VAMPIRE = {
  body      = {x=2,   y=72, w=86, h=28},  -- same as LAYBACK
  head      = {x=16,  y=22, w=78, h=74},  -- bigger face so mouth fits (was 40×42)
  tail      = {x=10,  y=78, w=16, h=12},
  earFar    = {x=50,  y=2,  w=20, h=40},
  earNear   = {x=26,  y=0,  w=24, h=44},
  innerFar  = {x=54, y=6,  w=12, h=32},
  innerNear = {x=28, y=4,  w=14, h=36},
  eye       = {x=58, y=44, w=11, h=11},  -- scaled up for bigger head
  eye2      = {x=41, y=44, w=11, h=11},
  nose      = {x=52, y=56, w=7,  h=7 },
  -- Pac-Man style mouth: ellipticalArc (C-shape)
  mouthArc  = {x=24, y=60, w=62, h=28},  -- raised a few px
  fangL     = {x=34, y=52, w=5,  h=20},  -- left fang (WHITE, prominent)
  fangR     = {x=71, y=52, w=5,  h=20},  -- right fang (WHITE)
  -- teeth along mouth edge (slightly longer for visibility)
  tooth1    = {x=26, y=64, w=5,  h=10},  tooth2 = {x=40, y=66, w=5, h=10},
  tooth3    = {x=54, y=68, w=5,  h=10},  tooth4 = {x=68, y=66, w=5, h=10},
  tooth5    = {x=80, y=64, w=5,  h=10},  tooth6 = {x=52, y=82, w=7, h=8 },  -- bottom
  -- arms and legs: jumping at you!
  backArm   = {x=0,  y=64, w=18, h=14},   -- left arm reaching out
  frontArm  = {x=92, y=64, w=18, h=14},  -- right arm reaching out
  footL     = {x=10, y=92, w=24, h=16},   -- left foot
  footR     = {x=76, y=92, w=24, h=16},   -- right foot
}

-- Rabbit hole: black opening, head + ears peeking up (scared by pop)
local HOLE = {
  hole   = {x=12,  y=78,  w=86,  h=32},  -- black oval opening
  earFar = {x=50,  y=38,  w=14,  h=38},  -- ears peeking up
  earNear= {x=36,  y=35,  w=16,  h=42},
  innerFar = {x=53, y=43, w=8,   h=30},
  innerNear= {x=38, y=40, w=10,  h=34},
  head   = {x=30,  y=58,  w=50,  h=36},  -- head between ears
  eye    = {x=42,  y=68,  w=8,   h=8 },  -- left eye (face-on)
  eye2   = {x=60,  y=68,  w=8,   h=8 },  -- right eye
  nose   = {x=51,  y=78,  w=6,   h=6 },
  mouth  = {x=40,  y=80,  w=30,  h=12},
}

-- ─── state ───────────────────────────────────────────────────────────────────
M._dir = 1   -- 1 = right, -1 = left

local canvasR, canvasL     -- one canvas per direction, both built at start
local canvas               -- alias: whichever is currently visible
local base                 -- alias: BR or BL, matches the visible canvas

local timer, keyTap, noiseListener
local posX
local state      = "hop"
local stateAge   = 0
local hopPhase   = 0
local earWiggle  = 0
local blinkIn    = 120 + math.random(80)
local zOff       = 0
local zAge       = 0
local ballBounce = 0   -- extra jump when hit by ball
local vampireMode = false
local vampireUntil = 0   -- timestamp when to exit vampire mode
local vampireKiss = false  -- true during kiss-goodbye phase
local vampireKissAge = 0
local vampireLurch = 0   -- 0=pre, 1-20=animating jump/scale, 21+=done (1 sec in, then lurch)

-- ─── animation parameters ────────────────────────────────────────────────────
local WALK = 1.6
local HOPH = 22
local HOPR = 0.13
local EARB = 5
local LURCH_SCALE = 1.2   -- smaller so vampire fits in canvas when he gets big
local LURCH_SIZE = math.floor(CW * LURCH_SCALE)   -- 154
local LURCH_OFFSET = math.floor((LURCH_SIZE - CW) / 2)  -- 22

-- ─── canvas construction ─────────────────────────────────────────────────────
-- Builds a canvas whose elements are laid out according to frame table f.
local function buildCanvas(f)
  local c = hs.canvas.new({x=0, y=0, w=CW, h=CH})
  c:appendElements(
    { type="oval",      frame=f.tail,      fillColor=WHITE,    strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",      frame=f.body,      fillColor=WHITE,    strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",      frame=f.head,      fillColor=WHITE,    strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="rectangle", frame=f.earFar,    fillColor=DIMWHITE, strokeColor=SOFTGRAY, strokeWidth=1, roundedRectRadii={xRadius=6,yRadius=6} },
    { type="rectangle", frame=f.earNear,   fillColor=WHITE,    strokeColor=SOFTGRAY, strokeWidth=1, roundedRectRadii={xRadius=7,yRadius=7} },
    { type="rectangle", frame=f.innerFar,  fillColor=PINKDIM,  strokeColor=CLEAR,    strokeWidth=0, roundedRectRadii={xRadius=3,yRadius=3} },
    { type="rectangle", frame=f.innerNear, fillColor=PINK,     strokeColor=CLEAR,    strokeWidth=0, roundedRectRadii={xRadius=4,yRadius=4} },
    { type="oval",      frame=f.eye,       fillColor=DARK,     strokeColor=CLEAR,    strokeWidth=0 },
    { type="oval",      frame=f.nose,      fillColor=PINK,     strokeColor=CLEAR,    strokeWidth=0 },
    { type="text",      frame=f.mouth,     textAlignment="center",
      text=hs.styledtext.new("ω", {font={name="Helvetica", size=13}, color=DARK}) },
    { type="text",      frame=f.zzz,       textAlignment="left",
      text=hs.styledtext.new("z z z", {font={name="Helvetica", size=10}, color=CLEAR}) },
    { type="oval",      frame=HIDDEN,      fillColor=DIMWHITE, strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",      frame=HIDDEN,      fillColor=WHITE,    strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="text",      frame=HIDDEN,      textAlignment="center",
      text=hs.styledtext.new("♥", {font={name="Helvetica", size=22}, color=HEARTRED}) },
    { type="oval",      frame=HIDDEN,      fillColor=WHITE,    strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",      frame=HIDDEN,      fillColor=WHITE,    strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="oval",      frame=HIDDEN,      fillColor=DARK,     strokeColor=CLEAR,    strokeWidth=0 },
    { type="rectangle", frame=HIDDEN,      fillColor=BLOODRED, strokeColor=CLEAR,    strokeWidth=0, roundedRectRadii={xRadius=1,yRadius=1} },
    { type="rectangle", frame=HIDDEN,      fillColor=BLOODRED, strokeColor=CLEAR,    strokeWidth=0, roundedRectRadii={xRadius=1,yRadius=1} },
    { type="oval",      frame=HIDDEN,      fillColor=BLOODRED, strokeColor=CLEAR,    strokeWidth=0 },
    { type="rectangle", frame=HIDDEN,     fillColor=WHITE,     strokeColor=SOFTGRAY, strokeWidth=1, roundedRectRadii={xRadius=12,yRadius=12} },
    { type="oval",      frame=HIDDEN,     fillColor=WHITE,     strokeColor=SOFTGRAY, strokeWidth=1 },
    { type="text",      frame=HIDDEN,     textAlignment="center",
      text=hs.styledtext.new("🩸", {font={name="Apple Color Emoji", size=22}}) },
    { type="ellipticalArc", frame=HIDDEN, fillColor=BLOODRED, strokeColor=CLEAR, strokeWidth=0 },
    { type="rectangle", frame=HIDDEN, fillColor=WHITE, strokeColor=CLEAR, strokeWidth=0 },
    { type="rectangle", frame=HIDDEN, fillColor=WHITE, strokeColor=CLEAR, strokeWidth=0 },
    { type="rectangle", frame=HIDDEN, fillColor=WHITE, strokeColor=CLEAR, strokeWidth=0 },
    { type="rectangle", frame=HIDDEN, fillColor=WHITE, strokeColor=CLEAR, strokeWidth=0 },
    { type="rectangle", frame=HIDDEN, fillColor=WHITE, strokeColor=CLEAR, strokeWidth=0 },
    { type="rectangle", frame=HIDDEN, fillColor=WHITE, strokeColor=CLEAR, strokeWidth=0 }
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
  if state == "vampire" then
    local e1, e2 = VAMPIRE.eye, VAMPIRE.eye2
    canvas[I.eye].frame  = {x=e1.x, y=e1.y + 4, w=e1.w, h=2}
    canvas[I.eye2].frame = {x=e2.x, y=e2.y + 4, w=e2.w, h=2}
  elseif state == "layback" and laybackFrames then
    local e1, e2 = laybackFrames.eye, laybackFrames.eye2
    canvas[I.eye].frame  = {x=e1.x, y=e1.y + 4, w=e1.w, h=2}
    canvas[I.eye2].frame = {x=e2.x, y=e2.y + 4, w=e2.w, h=2}
  elseif state == "inhole" and holeActive then
    local e1, e2 = HOLE.eye, HOLE.eye2
    canvas[I.eye].frame  = {x=e1.x, y=e1.y + 3, w=e1.w, h=2}
    canvas[I.eye2].frame = {x=e2.x, y=e2.y + 3, w=e2.w, h=2}
  else
    local ef = base.eye
    canvas[I.eye].frame = {x=ef.x, y=ef.y + 4, w=ef.w, h=2}
  end
end

local function openEyes()
  if state == "vampire" then
    canvas[I.eye].frame  = VAMPIRE.eye
    canvas[I.eye2].frame = VAMPIRE.eye2
  elseif state == "layback" and laybackFrames then
    canvas[I.eye].frame  = laybackFrames.eye
    canvas[I.eye2].frame = laybackFrames.eye2
  elseif state == "inhole" and holeActive then
    canvas[I.eye].frame  = HOLE.eye
    canvas[I.eye2].frame = HOLE.eye2
  else
    canvas[I.eye].frame = base.eye
  end
end

local laybackFrames  -- LAYBACK_R or LAYBACK_L, used to restore when exiting
local holeActive     -- true when in rabbit hole pose
local vampireActive  -- true when in vampire pose

local function hideVampirePose()
  canvas[I.bubble].frame = HIDDEN
  canvas[I.bubbleTail].frame = HIDDEN
  canvas[I.bloodEmoji].frame = HIDDEN
  canvas[I.fangL].frame = HIDDEN
  canvas[I.fangR].frame = HIDDEN
  canvas[I.bloodDrop].frame = HIDDEN
  canvas[I.mouthArc].frame = HIDDEN
  for i = I.tooth1, I.tooth6 do canvas[i].frame = HIDDEN end
  vampireLurch = 0
  -- reset transformation and restore canvas size
  for _, c in ipairs({canvasR, canvasL}) do
    if c then
      c:transformation(nil)
      c:size({w=CW, h=CH})
    end
  end
  vampireActive = false
end

local function setState(s)
  state = s;  stateAge = 0;  zOff = 0;  zAge = 0
  -- hide optional elements when leaving heart
  if s ~= "heart" then
    canvas[I.backArm].frame = HIDDEN
    canvas[I.frontArm].frame = HIDDEN
    canvas[I.heart].frame = HIDDEN
  end
  -- restore body/head/tail/ears when leaving layback, inhole, or vampire
  if s ~= "layback" and s ~= "inhole" and s ~= "vampire" and (laybackFrames or holeActive or vampireActive) then
    if vampireActive then hideVampirePose() end
    canvas[I.body].frame = base.body
    canvas[I.body].fillColor = WHITE
    canvas[I.body].strokeColor = SOFTGRAY
    canvas[I.body].strokeWidth = 1
    canvas[I.head].frame = base.head
    canvas[I.tail].frame = base.tail
    canvas[I.earFar].frame = base.earFar
    canvas[I.earNear].frame = base.earNear
    canvas[I.innerFar].frame = base.innerFar
    canvas[I.innerNear].frame = base.innerNear
    canvas[I.eye].frame = base.eye
    canvas[I.eye2].frame = HIDDEN
    canvas[I.nose].frame = base.nose
    canvas[I.mouth].frame = base.mouth
    canvas[I.mouth].text = hs.styledtext.new("ω", {font={name="Helvetica", size=13}, color=DARK})
    canvas[I.footL].frame = HIDDEN
    canvas[I.footR].frame = HIDDEN
    laybackFrames = nil
    holeActive = false
  end
end

local function showHeartPose()
  canvas[I.backArm].frame = base.backArm
  canvas[I.frontArm].frame = base.frontArm
  canvas[I.heart].frame = base.heart
  canvas[I.footL].frame = HIDDEN
  canvas[I.footR].frame = HIDDEN
end

local function showVampirePose()
  vampireActive = true
  vampireLurch = 0
  canvas[I.zzz].frame = HIDDEN  -- hide sleep "z z z" if coming from sleep
  canvas[I.mouth].frame = HIDDEN
  canvas[I.bloodDrop].frame = HIDDEN
  canvas[I.bubble].frame = HIDDEN
  canvas[I.bubbleTail].frame = HIDDEN
  canvas[I.bloodEmoji].frame = HIDDEN
  -- vampire body/head/ears/eyes
  canvas[I.body].frame = VAMPIRE.body
  canvas[I.head].frame = VAMPIRE.head
  canvas[I.tail].frame = VAMPIRE.tail
  canvas[I.earFar].frame = VAMPIRE.earFar
  canvas[I.earNear].frame = VAMPIRE.earNear
  canvas[I.innerFar].frame = VAMPIRE.innerFar
  canvas[I.innerNear].frame = VAMPIRE.innerNear
  canvas[I.eye].frame = VAMPIRE.eye
  canvas[I.eye2].frame = VAMPIRE.eye2
  canvas[I.nose].frame = VAMPIRE.nose
  -- Pac-Man mouth: ellipticalArc (C-shape, bite on right)
  canvas[I.mouthArc].frame = VAMPIRE.mouthArc
  canvas[I.mouthArc].fillColor = BLOODRED
  canvas[I.mouthArc].startAngle = 70
  canvas[I.mouthArc].endAngle = 290
  -- white fangs and teeth
  canvas[I.fangL].fillColor = WHITE
  canvas[I.fangR].fillColor = WHITE
  canvas[I.fangL].frame = VAMPIRE.fangL
  canvas[I.fangR].frame = VAMPIRE.fangR
  canvas[I.tooth1].frame = VAMPIRE.tooth1
  canvas[I.tooth2].frame = VAMPIRE.tooth2
  canvas[I.tooth3].frame = VAMPIRE.tooth3
  canvas[I.tooth4].frame = VAMPIRE.tooth4
  canvas[I.tooth5].frame = VAMPIRE.tooth5
  canvas[I.tooth6].frame = VAMPIRE.tooth6
  -- arms and legs: jumping at you!
  canvas[I.heart].frame = HIDDEN
  canvas[I.backArm].frame = VAMPIRE.backArm
  canvas[I.frontArm].frame = VAMPIRE.frontArm
  canvas[I.footL].frame = VAMPIRE.footL
  canvas[I.footR].frame = VAMPIRE.footR
end

local function showLaybackPose()
  laybackFrames = (M._dir == 1) and LAYBACK_R or LAYBACK_L
  canvas[I.body].frame = laybackFrames.body
  canvas[I.head].frame = laybackFrames.head
  canvas[I.tail].frame = laybackFrames.tail
  canvas[I.earFar].frame = laybackFrames.earFar
  canvas[I.earNear].frame = laybackFrames.earNear
  canvas[I.innerFar].frame = laybackFrames.innerFar
  canvas[I.innerNear].frame = laybackFrames.innerNear
  canvas[I.eye].frame = laybackFrames.eye
  canvas[I.eye2].frame = laybackFrames.eye2
  canvas[I.nose].frame = laybackFrames.nose
  canvas[I.mouth].frame = laybackFrames.mouth
  canvas[I.backArm].frame = HIDDEN
  canvas[I.frontArm].frame = HIDDEN
  canvas[I.heart].frame = HIDDEN
  canvas[I.footL].frame = base.footL
  canvas[I.footR].frame = base.footR
  canvas[I.fangL].frame = HIDDEN
  canvas[I.fangR].frame = HIDDEN
  canvas[I.bloodDrop].frame = HIDDEN
  canvas[I.mouthArc].frame = HIDDEN
  for i = I.tooth1, I.tooth6 do canvas[i].frame = HIDDEN end
  canvas[I.bubble].frame = HIDDEN
  canvas[I.bubbleTail].frame = HIDDEN
  canvas[I.bloodEmoji].frame = HIDDEN
end

local HOLE_STROKE = {red=0.15, green=0.15, blue=0.2, alpha=1}  -- dark edge for hole

local function offsetY(f, dy)
  return {x=f.x, y=f.y + dy, w=f.w, h=f.h}
end

local function showHolePose()
  holeActive = true
  canvas[I.tail].frame = HIDDEN
  canvas[I.body].frame = HOLE.hole
  canvas[I.body].fillColor = BLACK
  canvas[I.body].strokeColor = HOLE_STROKE
  canvas[I.body].strokeWidth = 2
  canvas[I.earFar].frame = HOLE.earFar
  canvas[I.earNear].frame = HOLE.earNear
  canvas[I.innerFar].frame = HOLE.innerFar
  canvas[I.innerNear].frame = HOLE.innerNear
  canvas[I.backArm].frame = HIDDEN
  canvas[I.frontArm].frame = HIDDEN
  canvas[I.heart].frame = HIDDEN
  canvas[I.footL].frame = HIDDEN
  canvas[I.footR].frame = HIDDEN
  canvas[I.head].frame = HOLE.head
  canvas[I.eye].frame = HOLE.eye
  canvas[I.eye2].frame = HOLE.eye2
  canvas[I.nose].frame = HOLE.nose
  canvas[I.mouth].frame = HOLE.mouth
  canvas[I.fangL].frame = HIDDEN
  canvas[I.fangR].frame = HIDDEN
  canvas[I.bloodDrop].frame = HIDDEN
  canvas[I.mouthArc].frame = HIDDEN
  for i = I.tooth1, I.tooth6 do canvas[i].frame = HIDDEN end
end

-- Flip: hide the current canvas, show the other one at the same position.
local function flip(gY)
  canvas:hide()
  M._dir = M._dir * -1
  if M._dir == 1 then
    canvas = canvasR;  base = BR
  else
    canvas = canvasL;  base = BL
  end
  canvas:topLeft({x=math.floor(posX), y=math.floor(gY)})
  canvas:show()
end

-- ─── animation loop (~30 fps) ─────────────────────────────────────────────────
local function animate()
  if not canvas then return end

  stateAge = stateAge + 1
  blinkIn  = blinkIn  - 1
  if ballBounce > 0 then ballBounce = ballBounce - 1 end

  local screen = hs.screen.mainScreen():frame()
  local gY     = screen.y + screen.h - CH - 22

  -- VAMPIRE: time's up → kiss goodbye then return to normal
  if vampireMode and hs.timer.secondsSinceEpoch() >= vampireUntil then
    vampireMode = false
    setState("heart")
    showHeartPose()
    vampireKiss = true
    vampireKissAge = 0
  end
  if vampireKiss then
    vampireKissAge = vampireKissAge + 1
    if vampireKissAge > 90 then  -- ~3 sec kiss
      vampireKiss = false
      setState("idle")
    end
  end

  -- BLINK
  if blinkIn <= 0 then
    blinkIn = 120 + math.random(120)
    closeEyes()
    hs.timer.doAfter(0.12, function()
      if canvas and state ~= "sleep" then openEyes() end
    end)
  end

  -- EAR WIGGLE (on keypress; skip when in hole - no ears visible)
  if earWiggle > 0 and state ~= "inhole" and state ~= "vampire" then
    earWiggle = earWiggle - 1
    local wobble = ((earWiggle % 2 == 0) and 4 or -4) * M._dir
    local nf, nif = base.earNear, base.innerNear
    canvas[I.earNear].frame   = {x=nf.x  + wobble, y=nf.y,  w=nf.w,  h=nf.h }
    canvas[I.innerNear].frame = {x=nif.x + wobble, y=nif.y, w=nif.w, h=nif.h}
    if earWiggle == 0 then
      canvas[I.earNear].frame   = base.earNear
      canvas[I.innerNear].frame = base.innerNear
    end
  end

  -- ── HOP ───────────────────────────────────────────────────────────────────
  if state == "hop" then
    hopPhase = hopPhase + HOPR
    local bounce = -math.abs(math.sin(hopPhase)) * HOPH

    -- ear bob (only when not wiggling)
    if earWiggle == 0 then
      local bob = math.abs(math.sin(hopPhase)) * EARB
      local nf, ff   = base.earNear,   base.earFar
      local nif, fif = base.innerNear, base.innerFar
      canvas[I.earNear].frame   = {x=nf.x,  y=nf.y  + bob, w=nf.w,  h=nf.h }
      canvas[I.earFar].frame    = {x=ff.x,  y=ff.y  + bob, w=ff.w,  h=ff.h }
      canvas[I.innerNear].frame = {x=nif.x, y=nif.y + bob, w=nif.w, h=nif.h}
      canvas[I.innerFar].frame  = {x=fif.x, y=fif.y + bob, w=fif.w, h=fif.h}
    end

    posX = posX + M._dir * WALK

    local minX = screen.x + 14
    local maxX = screen.x + screen.w - CW - 14
    if posX >= maxX then
      posX = maxX;  flip(gY)
    elseif posX <= minX then
      posX = minX;  flip(gY)
    end

    canvas:topLeft({x=math.floor(posX), y=math.floor(gY + bounce + (ballBounce > 0 and -math.abs(math.sin(ballBounce * 0.2)) * 24 or 0))})

    -- hop too long → lay back and rest
    if stateAge > 360 and math.random() < 0.005 then
      setState("layback"); showLaybackPose()
    elseif stateAge > 220 and math.random() < 0.004 then
      setState("idle")
    end

  -- ── IDLE ──────────────────────────────────────────────────────────────────
  elseif state == "idle" then
    local jump = (ballBounce > 0 and -math.abs(math.sin(ballBounce * 0.2)) * 24 or 0)
    canvas:topLeft({x=math.floor(posX), y=math.floor(gY + jump)})
    if math.random() < 0.008 then earWiggle = 14 end
    if stateAge > 200 then
      local r = math.random()
      if     r < 0.005 then setState("sleep"); closeEyes()
      elseif r < 0.010 then setState("hop")
      end
    end

  -- ── HEART ───────────────────────────────────────────────────────────────────
  elseif state == "heart" then
    local jump = (ballBounce > 0 and -math.abs(math.sin(ballBounce * 0.2)) * 24 or 0)
    canvas:topLeft({x=math.floor(posX), y=math.floor(gY + jump)})
    if stateAge > 75 then setState("idle") end

  -- ── LAYBACK ────────────────────────────────────────────────────────────────
  elseif state == "layback" then
    local jump = (ballBounce > 0 and -math.abs(math.sin(ballBounce * 0.2)) * 24 or 0)
    canvas:topLeft({x=math.floor(posX), y=math.floor(gY + jump)})
    if stateAge > 140 and math.random() < 0.012 then
      setState("hop")
    end

  -- ── VAMPIRE (face-on, Pac-Man mouth; lurch at 1 sec) ───────────────────────
  elseif state == "vampire" then
    -- at 1 sec (~30 frames) in: jump up into screen and get bigger
    if stateAge >= 30 and vampireLurch == 0 then vampireLurch = 1 end
    if vampireLurch >= 1 and vampireLurch <= 20 then
      vampireLurch = vampireLurch + 1
      local t = (vampireLurch - 1) / 20  -- 0..1 over 20 frames
      local ease = t * t  -- ease-in (quicker start)
      local jumpUp = ease * 100  -- move up 100px
      local scale = 1 + ease * 0.4  -- grow to 1.4x
      -- Resize both canvases so scaled content fits (no clipping)
      for _, c in ipairs({canvasR, canvasL}) do
        if c then c:size({w=LURCH_SIZE, h=LURCH_SIZE}) end
      end
      canvas:topLeft({x=math.floor(posX - LURCH_OFFSET), y=math.floor(gY - jumpUp - LURCH_OFFSET)})
      local m = hs.canvas.matrix.translate(LURCH_OFFSET, LURCH_OFFSET)
        :append(hs.canvas.matrix.translate(CW/2, CH/2):scale(scale):translate(-CW/2, -CH/2))
      canvas:transformation(m)
      if vampireLurch > 20 then vampireLurch = 21 end
    elseif vampireLurch == 0 then
      for _, c in ipairs({canvasR, canvasL}) do
        if c then c:size({w=CW, h=CH}) end
      end
      canvas:topLeft({x=math.floor(posX), y=math.floor(gY)})
      canvas:transformation(nil)
    else
      -- vampireLurch >= 21: stay at lurched position (set once, then static)
      if vampireLurch == 21 then
        vampireLurch = 22
        for _, c in ipairs({canvasR, canvasL}) do
          if c then c:size({w=LURCH_SIZE, h=LURCH_SIZE}) end
        end
        canvas:topLeft({x=math.floor(posX - LURCH_OFFSET), y=math.floor(gY - 100 - LURCH_OFFSET)})
        local m = hs.canvas.matrix.translate(LURCH_OFFSET, LURCH_OFFSET)
          :append(hs.canvas.matrix.translate(CW/2, CH/2):scale(LURCH_SCALE):translate(-CW/2, -CH/2))
        canvas:transformation(m)
      end
    end

  -- ── INHOLE (scared, peeking to see if safe) ─────────────────────────────────
  elseif state == "inhole" then
    local peek = math.sin(stateAge * 0.06) * 4  -- head/ears peek left/right
    canvas[I.earFar].frame   = {x=HOLE.earFar.x + peek,  y=HOLE.earFar.y,  w=HOLE.earFar.w,  h=HOLE.earFar.h }
    canvas[I.earNear].frame   = {x=HOLE.earNear.x + peek, y=HOLE.earNear.y, w=HOLE.earNear.w, h=HOLE.earNear.h}
    canvas[I.innerFar].frame = {x=HOLE.innerFar.x + peek, y=HOLE.innerFar.y, w=HOLE.innerFar.w, h=HOLE.innerFar.h}
    canvas[I.innerNear].frame= {x=HOLE.innerNear.x+peek, y=HOLE.innerNear.y, w=HOLE.innerNear.w,h=HOLE.innerNear.h}
    canvas[I.head].frame     = {x=HOLE.head.x + peek, y=HOLE.head.y, w=HOLE.head.w, h=HOLE.head.h}
    canvas[I.eye].frame      = {x=HOLE.eye.x + peek,  y=HOLE.eye.y,  w=HOLE.eye.w,  h=HOLE.eye.h }
    canvas[I.eye2].frame     = {x=HOLE.eye2.x + peek, y=HOLE.eye2.y, w=HOLE.eye2.w, h=HOLE.eye2.h}
    canvas[I.nose].frame     = {x=HOLE.nose.x + peek, y=HOLE.nose.y, w=HOLE.nose.w, h=HOLE.nose.h}
    canvas[I.fangL].frame    = HIDDEN
    canvas[I.fangR].frame    = HIDDEN
    canvas[I.bloodDrop].frame= HIDDEN
    canvas[I.mouth].frame    = {x=HOLE.mouth.x + peek, y=HOLE.mouth.y, w=HOLE.mouth.w, h=HOLE.mouth.h}
    local jump = (ballBounce > 0 and -math.abs(math.sin(ballBounce * 0.2)) * 24 or 0)
    canvas:topLeft({x=math.floor(posX), y=math.floor(gY + jump)})
    -- peek long enough, decide it's safe
    if stateAge > 90 and math.random() < 0.008 then
      setState("hop")
    end

  -- ── SLEEP ─────────────────────────────────────────────────────────────────
  elseif state == "sleep" then
    local jump = (ballBounce > 0 and -math.abs(math.sin(ballBounce * 0.2)) * 24 or 0)
    canvas:topLeft({x=math.floor(posX), y=math.floor(gY + jump)})

    zAge = zAge + 1
    if zAge % 90 == 0 then zOff = 0 end
    zOff = zOff + 0.5

    local alpha = math.max(0, 1 - zOff / 32)
    local zf = base.zzz
    canvas[I.zzz].frame = {x=zf.x, y=zf.y - zOff, w=zf.w, h=zf.h}
    canvas[I.zzz].text  = hs.styledtext.new("z z z",
      {font={name="Helvetica", size=10},
       color={red=0.55, green=0.78, blue=1, alpha=alpha}})

    if stateAge > 420 and math.random() < 0.004 then
      openEyes()
      canvas[I.zzz].text = hs.styledtext.new("z z z",
        {font={name="Helvetica", size=10}, color=CLEAR})
      setState("hop")
    end
  end
end

-- ─── public API ──────────────────────────────────────────────────────────────

function M.start()
  if canvas then return end

  local ok, err = pcall(function()
    local screen = hs.screen.mainScreen():frame()
    posX   = screen.x + math.floor(screen.w * 0.45)
    M._dir = 1

    local gY = math.floor(screen.y + screen.h - CH - 22)

    -- Build both canvases up front — flip() just swaps which is visible
    canvasR = buildCanvas(BR)
    canvasL = buildCanvas(BL)
    setupCanvas(canvasR, posX, gY)
    setupCanvas(canvasL, posX, gY)

    canvas = canvasR
    base   = BR
    canvas:show()

    timer = hs.timer.new(1/30, animate)
    timer:start()

    -- React to sounds (tongue clicks, pops) — requires microphone permission
    local okNoise, errNoise = pcall(function()
      if hs.noises then
        noiseListener = hs.noises.new(function(evType)
          if evType == 3 then  -- pop = scary noise, jump in hole
            if state == "sleep" then
              openEyes()
              canvas[I.zzz].text = hs.styledtext.new("z z z",
                {font={name="Helvetica", size=10}, color=CLEAR})
              setState("inhole"); showHolePose()
            elseif state == "hop" or state == "idle" or state == "heart" or state == "layback" or state == "vampire" then
              setState("inhole"); showHolePose()
            elseif state == "inhole" then
              -- another pop while hiding = stay longer (reset timer)
              stateAge = 0
            end
          else  -- tss (1,2) = gentle, ear wiggle
            earWiggle = 14
            if state == "sleep" then
              openEyes()
              canvas[I.zzz].text = hs.styledtext.new("z z z",
                {font={name="Helvetica", size=10}, color=CLEAR})
              setState("idle")
            elseif (state == "hop" or state == "idle") and stateAge > 20 then
              if math.random() < 0.15 then setState("heart"); showHeartPose() end
            end
          end
        end)
        noiseListener:start()
      end
    end)
    if not okNoise then hs.logger.new("bunny"):w("Sound reactivity unavailable: " .. tostring(errNoise)) end

    keyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function()
      if state == "inhole" then
        setState("hop")  -- keypress = safe, emerge from hole
        return false
      end
      if state == "layback" or state == "vampire" then
        setState("hop")
        return false
      end
      if state == "sleep" then
        openEyes()
        canvas[I.zzz].text = hs.styledtext.new("z z z",
          {font={name="Helvetica", size=10}, color=CLEAR})
        setState("idle")
        return false
      end
      -- action triggers: heart or layback (when in hop/idle)
      if (state == "hop" or state == "idle") and stateAge > 30 then
        local r = math.random()
        if r < 0.12 then
          setState("heart"); showHeartPose(); return false
        elseif r < 0.22 then
          setState("layback"); showLaybackPose(); return false
        end
      end
      earWiggle = 12
      return false
    end)
    keyTap:start()
  end)

  if not ok then
    hs.alert.show("Bunny error:\n" .. tostring(err), 6)
    if canvasR then canvasR:delete(); canvasR = nil end
    if canvasL then canvasL:delete(); canvasL = nil end
    canvas = nil
    if timer  then timer:stop();  timer  = nil end
    if keyTap then keyTap:stop(); keyTap = nil end
  end
end

function M.stop()
  if timer   then timer:stop();                      timer   = nil end
  if keyTap  then keyTap:stop();                     keyTap  = nil end
  if noiseListener then pcall(function() noiseListener:stop() end); noiseListener = nil end
  if canvasR then canvasR:hide(); canvasR:delete();  canvasR = nil end
  if canvasL then canvasL:hide(); canvasL:delete();  canvasL = nil end
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
  if state == "hop" or state == "idle" or state == "heart" or state == "layback" or state == "vampire" or state == "sleep" then
    setState("inhole")
    showHolePose()
  end
end

-- ─── test exports ─────────────────────────────────────────────────────────────
M._mir       = mir
M._B         = BR
M._BL        = BL
M._LAYBACK_R = LAYBACK_R
M._LAYBACK_L = LAYBACK_L
M._VAMPIRE   = VAMPIRE
M._HOLE      = HOLE
M._CW        = CW
M._CH        = CH
M._HOPH      = HOPH
M._HOPR      = HOPR
M._WALK      = WALK
M._EARB      = EARB
M._getState   = function() return state end
M._getCanvas  = function() return canvas end
M._isVampire  = function() return vampireMode end

function M.getBounds()
  if not canvas then return nil end
  local screen = hs.screen.mainScreen():frame()
  local gY = screen.y + screen.h - CH - 22
  return {x=posX, y=gY, w=CW, h=CH}
end

function M.bounce()
  if not canvas then return end
  ballBounce = 18
end

function M.vampire()
  if not canvas then return end
  vampireMode = true
  vampireUntil = hs.timer.secondsSinceEpoch() + 10
  vampireKiss = false
  if state == "sleep" then
    openEyes()
    canvas[I.zzz].text = hs.styledtext.new("z z z", {font={name="Helvetica", size=10}, color=CLEAR})
  end
  setState("vampire")
  showVampirePose()
end

return M
