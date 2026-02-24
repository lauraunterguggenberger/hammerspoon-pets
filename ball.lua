-- ~/.hammerspoon/ball.lua
-- A bouncing ball that bounces off the ground and makes pets jump when it hits them.
-- Throw with: ball.throw()
-- Bind to nudge+t: hs.hotkey.bind(nudge, "t", function() ball.throw() end)

local M = {}

local BALL_R = 8
local GRAVITY = 1.2
local BOUNCE_DAMP = 0.72
local PET_BOUNCE_DAMP = 0.85
local MIN_VY = 0.3
local GROUND_OFFSET = 22

local canvas
local timer
local x, y
local vx, vy
local screen
local groundY
local pets = {}

-- Register pets (bunny, pig) for collision
function M.registerPet(pet)
  if pet and pet.getBounds and pet.bounce then
    table.insert(pets, pet)
  end
end

local function overlaps(ax, ay, aw, ah, bx, by, bw, bh)
  if not (ax and ay and aw and ah and bx and by and bw and bh) then return false end
  return ax < bx + bw and ax + aw >= bx and ay < by + bh and ay + ah >= by
end

-- test exports
M._overlaps = overlaps
M._BALL_R = BALL_R
M._GRAVITY = GRAVITY
M._BOUNCE_DAMP = BOUNCE_DAMP

local function animate()
  if not canvas then return end

  vy = vy + GRAVITY
  x = x + vx
  y = y + vy

  -- Bounce on ground
  if y + BALL_R * 2 >= groundY then
    y = groundY - BALL_R * 2
    vy = -vy * BOUNCE_DAMP
    vx = vx * 0.98
  end

  -- Collision with pets
  local ballBox = {x=x, y=y, w=BALL_R*2, h=BALL_R*2}
  for _, pet in ipairs(pets) do
    local bounds = pet.getBounds()
    if bounds and bounds.x and bounds.y and bounds.w and bounds.h and overlaps(ballBox.x, ballBox.y, ballBox.w, ballBox.h, bounds.x, bounds.y, bounds.w, bounds.h) then
      pet.bounce()
      vx = -vx * PET_BOUNCE_DAMP
      vy = -math.abs(vy) * PET_BOUNCE_DAMP
      -- nudge ball out so it doesn't get stuck
      x = x + (vx > 0 and 6 or -6)
      break  -- one pet per frame
    end
  end

  canvas:topLeft({x=math.floor(x), y=math.floor(y)})

  -- Stop when off screen or barely moving
  local offLeft = x + BALL_R * 2 < screen.x - 20
  local offRight = x > screen.x + screen.w + 20
  local stopped = math.abs(vy) < MIN_VY and y + BALL_R * 2 >= groundY - 2

  if offLeft or offRight or (stopped and math.abs(vx) < 0.5) then
    timer:stop()
    timer = nil
    canvas:hide()
    canvas:delete()
    canvas = nil
  end
end

function M.throw()
  -- Clear any existing ball so you can throw again
  if timer then timer:stop(); timer = nil end
  if canvas then canvas:hide(); canvas:delete(); canvas = nil end

  screen = hs.screen.mainScreen():frame()
  groundY = screen.y + screen.h - BALL_R * 2 - GROUND_OFFSET

  -- Throw from random point, random direction
  local margin = 60
  local span = screen.w - margin * 2
  x = screen.x + margin + math.random() * span
  y = groundY - 40 - math.random() * 30
  local dir = math.random() > 0.5 and 1 or -1
  vx = dir * (8 + math.random() * 5)
  vy = -6 - math.random() * 6

  canvas = hs.canvas.new({x=x, y=y, w=BALL_R*2, h=BALL_R*2})
  canvas:appendElements({
    type = "oval",
    frame = {x=0, y=0, w=BALL_R*2, h=BALL_R*2},
    fillColor = {red=0.95, green=0.6, blue=0.2, alpha=1},
    strokeColor = {red=0.85, green=0.5, blue=0.1, alpha=1},
    strokeWidth = 1,
  })
  canvas:level(hs.canvas.windowLevels.floating)
  pcall(function() canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces) end)
  canvas:topLeft({x=math.floor(x), y=math.floor(y)})
  canvas:show()

  timer = hs.timer.new(1/30, animate)
  timer:start()
end

return M
