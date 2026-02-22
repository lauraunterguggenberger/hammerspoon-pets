# Desktop Bunny — Hammerspoon Pet

A desktop pet bunny that hops across the bottom of your screen, reacts to keypresses and sounds, and has multiple poses and states.

## Quick start


| Action                                                                  | Shortcut                                 |
| ----------------------------------------------------------------------- | ---------------------------------------- |
| Toggle bunny on/off                                                     | **Hyper+y**, **Nudge+y**, or **Nudge+b** |
| Scare into rabbit hole                                                  | **Nudge+h**                              |
| *(Nudge = Ctrl+Alt; Hyper = Cmd+Ctrl+Alt+Shift or Caps Lock if mapped)* |                                          |


If Nudge+y doesn't work (Ctrl+Option+y is sometimes captured by input methods), use **Nudge+b** (B for bunny) instead.

## States and behavior

### Hop

Default state. The bunny hops left and right along the bottom of the screen.

- Ears bob with each hop
- Flips horizontally when reaching screen edges
- Eventually goes idle or lays back after extended hopping

### Idle

Pauses briefly between hops. Random ear twitches. May transition to sleep or back to hop.

### Sleep

Falls asleep with closed eyes and floating "z z z". Wakes on keypress or sound (tongue click).

### Heart

Stops and gives you a heart, with both arms extended. Triggered by:

- **Keypress** (~12% chance when hopping/idle)
- **Tongue click** (tss) (~15% chance)

### Lay back

Reclines with feet visible. Triggered by:

- **Hopping too long** (~12 seconds)
- **Keypress** (~10% chance)
- Wakes back to hop on keypress

### Rabbit hole (scared)

Jumps into a hole with only his head peeking out. Triggered by:

- **Pop sound** (sharp mouth pop near microphone)
- Another pop while hiding keeps him in longer
- **Keypress** = he decides it's safe and emerges
- After ~3 seconds he may emerge on his own

## Sound reactivity

Uses `hs.noises` (microphone) to react to mouth sounds:


| Sound                  | Reaction                                                 |
| ---------------------- | -------------------------------------------------------- |
| **Pop**                | Scared → jumps in rabbit hole                            |
| **Tongue click (tss)** | Ears wiggle; ~15% chance to give heart; wakes from sleep |


**Requirements:** Microphone permission for Hammerspoon (System Settings → Privacy & Security → Microphone). If denied, the bunny works normally but won't react to sounds.

## Keypress reactions

- **Ears wiggle** on every keypress (when not in hole)
- **~12%** heart pose (hop/idle)
- **~10%** lay back pose (hop/idle)
- **Wake from sleep** → idle
- **Emerge from hole** → hop
- **Exit lay back** → hop

## Visual design

### Base bunny

- White body, head, tail, ears
- Pink inner ears, nose
- Single visible eye in profile (hop/idle/heart)
- ω mouth

### Heart pose

- Arms (back + front paw) extended
- Red heart ♥ (22×22 px)

### Lay back pose

- Flatter, wider body (horizontal)
- Ears splayed back
- **Two eyes** (face-on view)
- Prominent hind feet (22×18 px each)

### Rabbit hole

- **Black oval opening** at the bottom (the burrow)
- Head and **ears** peeking up from the hole
- Two eyes (face-on, cautious)
- Head and ears peek left and right while hidden

## Technical details

### Files

- `**bunny.lua`** — Main module (~550 lines)
- `**test_bunny.lua`** — Unit tests (~265 lines)

### Canvas

- Size: 110×110 px
- Two canvases: `canvasR` (facing right) and `canvasL` (facing left)
- Flipped at screen edges so bunny always faces movement direction
- Uses `hs.canvas` with ovals and rectangles

### Frame tables

- **BR/BL** — Base frames for right/left
- **LAYBACK_R/LAYBACK_L** — Reclined pose with two eyes and feet
- **HOLE** — Head-only peek (single face-on frame)

### Test exports (for `test_bunny.lua`)

- `_mir`, `_B`, `_BL`, `_LAYBACK_R`, `_LAYBACK_L`, `_HOLE`
- `_CW`, `_CH`, `_HOPH`, `_HOPR`, `_WALK`, `_EARB`
- `_getState()`, `_getCanvas()`

## Running tests

With Hammerspoon running:

1. Open **Hammerspoon** menu bar → **Console**
2. Run: `require("test_bunny")`

Results appear in the console and as an on-screen alert.



/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs -c 'require("test_bunny")' 2>&1

## Change history

1. **Horizontal flip** — Bunny correctly faces left when hopping left (dual canvas, flip at edges)
2. **Heart action** — Stop and give heart with arms; triggered by keypress
3. **Lay back** — Reclined pose with feet; triggered by long hop or keypress
4. **Lay back improvement** — Flatter body, bigger feet, more horizontal
5. **Bigger heart** — 22×22 px, larger font
6. **Two eyes when laying back** — Face-on view with both eyes
7. **Sound reactivity** — `hs.noises` for tongue clicks and pops
8. **Rabbit hole** — Pop scares bunny; hides with only head peeking; peeks left/right
9. **Fallback keybinding** — Nudge+b when Nudge+y is captured

