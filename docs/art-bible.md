# The art bible

Written 2026-09-17 for Checkpoint A, checked by an adversarial review against the
graphics, the snapshot and the disassembly, and revised the same day for David's
option d. It says where every graphic in the play area comes from, what it must
cover, and in what order the work is done. The design it serves is
**`docs/design.md`**.

**Decisions it follows (David, 2026-09-17):** characters from the arcade, scenery
from the Spectrum (option d); every screen stays intact (section G); the arcade set
is optional; extra frames about double.

The Spectrum originals are the reference for what must be covered: `make gfx` writes a
sheet of every graphic set to `build/gfx/` (open `build/gfx/index.html`). The arcade
graphics decode into `build/arcade-gfx/`. Both come from your own files, so they stay
local.

## Where each graphic comes from

| Graphic | With an arcade set | Without one | David's hand-made override (local, `data/art/`) |
|---|---|---|---|
| Player: body, armour, flight | **arcade Athena**, mapped per state | Spectrum art, recoloured | - |
| Weapons, shots, chain, blast | **arcade** | recoloured | - |
| Effects: explosion, heart, flame and bomb | **arcade** | recoloured | - |
| Items and boxes (map cells) | **arcade item pictures**, drawn into the cell | recoloured cells | - |
| Enemies the arcade has | **arcade** | recoloured | - |
| Enemies the arcade lacks | recoloured | recoloured | hand-coloured |
| Guardians | **arcade boss** | recoloured | - |
| Scenery cells | recoloured | recoloured | **hand-coloured and shaded** |
| Title, panel, fonts, text screens, ending, advert | the original, untouched | the original | - |

The repository holds rules and mappings only. Pictures are made at build time from
the builder's files; hand-made art stays in `data/art/`, which git ignores, until David
decides otherwise.

## Converted arcade art

**What the arcade set holds** (MAME `snk.cpp`, `snk_v.cpp`):
- **1,024 sprite tiles**, 16x16, 3 bits a pixel: values 0-5 are colours, 6 is a
  shadow that darkens what is behind, 7 is transparent. Each sprite uses one of 16
  colour sets. Left- and right-facing art are separate tiles (the hardware cannot
  mirror).
- **1,024 background tiles**, 8x8, 4 bits a pixel, 16 palettes.
- **Colours** from three PROMs, 4 weighted bits per channel, quantised to the Next's 3.
- The arcade Athena is a 16x16 head over a 16x16 body, the Spectrum player's 16x32.

**How a mapping is made:**
1. **The capture:** David plays the arcade game through once in MAME on the Steam
   Deck, with cheats if that helps reach every world. A Lua script logs every frame's
   sprite table, background tiles and colours, and the sound commands.
2. **Contact sheets:** every arcade character assembled from the log, with its
   animations and colour sets, beside the Spectrum graphic it could replace.
3. **The mapping:** for each Spectrum logic state in the asset tables below, the arcade
   frames that show it - tile numbers, colour set, offsets, and which display frames
   of the pass each shows. Where the arcade has more frames than the Spectrum, they
   are the extra frames; where it has fewer, frames repeat.
4. **Approval:** David approves each group - player, weapons and effects, items, then
   each bank's enemies and guardian - on a sheet of the Spectrum original beside the
   converted result.

**Rules:**
- **No redrawing.** Choose frames, place them, and crop only where a piece must go.
- **Placement:** feet on the Spectrum object's line, centred on its box. A converted
  character may be wider or taller than the Spectrum's box: the game's hits come from
  map cells (an enemy's from its top-left cell and height, the guardian's from a fixed
  4x4 block), so play is unchanged.
- **The shadow value** becomes a fixed dark colour or is dropped (the Next's sprites
  have no translucency), per character.
- **Layered player:** the Spectrum builds the player from body, helmet, body armour,
  hand piece, winged legs and leg piece, with the crescent wing and crouch peak beside
  it. The arcade draws its own armour and wings; the mapping follows each combination
  of pose, armour and flight that the capture shows.
- **No counterpart:** where the arcade has nothing matching, the Spectrum art is used
  (recoloured, or David's hand-made version).

## Recoloured Spectrum art (automatic)

The fallback for every graphic, and the scenery until David's cells exist. Ivan Horn's
art is 1 bit a pixel plus, for sprites, a mask, so each picture has three kinds of
pixel: ink, paper inside the mask, and outside. A committed rule per asset and world
turns them into colours: an outline and fill from the ink, a lighter fill from the
paper inside the mask, and for scenery a two-tone ramp in the world's palette (table
below). The rules hold colour choices only, never pixels.

## Hand-made art (David, local)

For the scenery cells and any enemy the arcade lacks.

**Style:** Ivan Horn's shapes, coloured and shaded to sit with the arcade art:
- **Palette:** the arcade's tones.
- **Enemies:** about 7 colours per 16x16, like the arcade sprites.
- **Light:** from the top left.
- **Edges:** hard only, with no anti-aliasing and no partial transparency.
- **Scenery:** darker and less saturated than the characters, so they read against it.

**World colours** follow the world, not the Spectrum's single ink colour. A starting
point, decided world by world:

| World | Name | Original ink | Suggested mood |
|---|---|---|---|
| 1 | Forest | bright cyan | greens and bark browns |
| 2 | Cavern | yellow | earth, ochre, dim stone |
| 3 | Sky | white | blues, cloud white, gold |
| 4 | Labyrinth | cyan | cold grey-green stone |
| 5 | Sea | green | blue-greens, coral, sand |
| 6 | Hell | magenta | reds, black rock, lava orange |
| 7 | The Last World | white | pale ice blue and grey (the arcade's Ice music plays here) |

**Hard limits:**

| What | Limit |
|---|---|
| Every colour | one of the Next's 512: 3 bits each of red, green and blue |
| Size | inside the original's width and height (the asset tables), so it lines up with the Spectrum's scenery and positions |
| Scenery cells | Layer 2, from the world's 256-colour palette, opaque, never the transparency colour (the 8-bit value in NextReg `$14`, default `$E3`: two of the 512 colours); cells tile seamlessly edge to edge |
| Hand-made sprites | 16x16 images with one transparent index, using the sprite palette's entries not taken by the arcade's colour sets |

Two worlds that share a bank (1 and 2, 3 and 4, 5 and 6) **share the same cell and
enemy pictures**: draw once with palette indices; each world gets its colours.
`tools/artimport.py` fits, quantises and checks hand-made art against these limits.

## How animation is keyed

A pass of the game's logic lasts a little over 4 display frames at 50 Hz: usually 4,
sometimes 5 (the feathered blade's passes, some passes in world 7), and about 5 on a
60 Hz display. New pictures are placed by **fraction of the pass**, from the logic's
state - never from a clock of their own - and a long pass holds its last picture.
The ceiling is one picture per display frame. For hand-made art the counts below are
about double the original's (decision 7); converted arcade art uses the arcade's own
frames, repeated where it has fewer, to at least the same counts. The rules below say
when each picture shows, whatever its source.

- **Walkers** (every enemy type but 6 and 7) step 8 pixels every second pass and glide
  about 1 pixel a display frame. A gait cycle of 4 frames covers those 8 pixels: the
  original's two frames stay, and each gets one in-between.
- **Fliers** (type 6) and the flame and bomb (type 7) move 8 pixels a pass: 4 frames
  per direction for type 6, 8 for type 7.
- **The player's walk** changes picture every second pass in the original: 8 frames,
  one per pass, over the 8-pass cycle that scrolls one map cell.
- **A blow with the broad sword, dagger, club, war hammer or kick** spans the fire
  pass and the next, about 8 display frames at 50 Hz:

  | Share of the two passes | Weapon | Player |
  |---|---|---|
  | first eighth | swing | attack pose 1 |
  | to five eighths | contact (the original's strike picture); the explosion starts at the second display frame | attack pose 2 |
  | to seven eighths | recover | walk frame 0 |
  | last eighth | held | walk frame 0 |

  Holding fire loops it every 2 passes, exactly as the logic strikes.
- **The feathered blade and the flail** work differently: firing hides the held weapon
  for 7 passes, and what shows is the blast or the thrown flail, keyed to the shot's
  7-pass timer. Their held pictures only need the walk bob.
- **Explosion:** the original shows each of 4 pictures for 2 passes; the new 8 show one
  a pass.

## The assets

These tables are **what every source must cover**: each row is a state the logic can
be in, with the Spectrum's size and frame counts. For converted arcade art, the "New
frames" column is the minimum the mapping provides. "Mirror" and "Both" apply to
recoloured and hand-made art: "mirror" means the other direction comes from the
hardware's mirror flag; "both" means the original drew each direction, and so does the
new art. Converted arcade art always uses the arcade's own left- and right-facing tiles.

### A. The player (every world; drawn facing right, left is mirrored)

The player is composited from layers each time its picture changes, as the original
builds it. The body and its layers share the **16x32 grid**. The **crescent wing and
the crouch peak are not on it**: they are drawn 8 pixels behind the body, overlapping
its back half, so each is its own 16-pixel-wide sprite beside the player.

| Asset | Original sheet | Size | Original frames | New frames | Driven by |
|---|---|---|---|---|---|
| Walk | `5da0-player-walk` | 16x32 | 4 | **8** | walk phase (PlayerFrame and its half-step counter) |
| Climb | `6d60-player-climb` | 16x32 | 2 | **4** | climb phase |
| Jump | (walk frame 1) | 16x32 | 0 | **3** take-off, rise, fall **+ 1** landing | JumpCounter |
| Crouch | (walk frame 0, lowered 8 lines) | 16x32 box, figure in the lower 24 lines | 0 | **2** going down, crouched | Crouching flag |
| Glide | (walk frame 3 + leg piece) | 16x32 | 0 | **2** float loop | glide flag |
| Attack poses | (walk frames 3 / 0) | 16x32 | 0 | **2**, plus **2** kick poses | the blow |
| Helmet (2 armour levels) | `5fa0-armour-head` | 16x16 | 2 | **2 per level for the walk**, plus one per level for each new pose that moves the head | armour level, pose |
| Body armour (lines 16-23, 2 levels) | `6020-armour-waist` | 16x8 | 8 (4 walk frames x 2) | **16** for the walk **+ 24** for the 12 new poses (one per pose per level) | pose, level |
| Hand piece (2 levels) | `6120-armour-hand` | 16x8 | 2 | **2**, plus one per level for each new pose that moves the hand | level, pose |
| Climb helmet (2 levels, from behind) | `6d60-player-climb` | 16x16 | 2 | **2** | armour level |
| Climb body armour | `6d60-player-climb` | 16x8 | 2 | **4** | climb phase |
| Winged legs (the winged boot) | `70a0-flight` | 16x8, lines 24-31 | 4 | **8** | the four-step flight counter |
| Leg piece (gliding) | `6f20-pieces` | 16x8, lines 24-31 | 1 | **1** | glide |
| **Crescent wing** (flight without the boot) | `70a0-flight` | 16x16, 8 pixels behind the body, lines 8-23 | 4 | **8** | the flight counter |
| **Crouch peak** | `6f20-pieces` | 16x8, 8 pixels behind the body, lines 24-31 | 1 | **2**, one per crouch pose | crouch |

Armour must line up with every pose it is drawn over: the original drew all its
poses from the 4 walk frames, so 4 armour pieces a level fitted everything. The new
poses need their own pieces.

### B. Weapons (every world; drawn facing right, left is mirrored)

| Asset | Original sheet | Size | Original pictures | New pictures |
|---|---|---|---|---|
| Broad sword, dagger, club, war hammer, held | `6160-weapons-1-4` | 24x16 | 3 each: two level, one raised | **5 each**: the three + swing + recover |
| Kick | `65e0-weapons-5-7` | 24x16 | 2 | **4**: chamber, extend, hold, retract |
| Feathered blade, flail, held | `65e0-weapons-5-7` | 24x24 | 2 each | **2 each** (hidden while they strike) |
| Broad sword's shot | `6f20-pieces` (bar, dithered bar) | 16x8 | 2 | **4** shimmer |
| Flail chain | `68e0-chain` | end 16x8, link 16x8, ball 16x16 | 1 each | end 1, link 1, **ball 4** spin |
| Feathered blade's blast | `6960-strikes` | 6 pictures: rise = beam 24x24 (drawn twice) + end 16x16; turn = wisp 16x8 + streak 24x24 (drawn twice); ground = shaft 32x16 (drawn twice) + tip 16x16 | 6 | the 6 **+ 2 in-betweens per phase change + a 2-frame shimmer per phase** (about 10 poses) |

### C. Effects (every world)

| Asset | Original sheet | Size | Original frames | New frames | Notes |
|---|---|---|---|---|---|
| Explosion | `6ba0-explosion` | 16x16 | 4 | **8** | also the hit effect and the damaged guardian's sparks |
| Flame and bomb (enemy type 7) | `6fa0-flame-bomb` | 16x16 | 4 (2 flame, 2 bomb) | **8** (4 each) | the same both ways |
| Heart | `7620-heart` | 16x16 | 1 | **4** pulse | rises 2 lines a pass |

### D. Enemies (per bank; each moves as its type)

Types 1-5, 8 and 9 walk, and type 4 also walks off ledges and falls (add **1 fall
pose** per direction drawn); type 6 flies. New frames: **4 per direction drawn**.

The `bankN-enemies` sheets show the left-facing frames **in the order the frames
are stored, not by type**: bank 3 types 1, 2, 3, 4, 5, 6; bank 4 types 4, 1, 3, 2,
5, 8, 9, 6; bank 6 types 4, 1, 2, 3, 5, 8, 6; bank 7 types 1, 2, 6, 3, 5, 8, 9. The
brief sheets will label each enemy and show both directions.

| Bank (worlds) | Type | Size | Moves | Directions |
|---|---|---|---|---|
| 3 (1 Forest, 2 Cavern) | 1 | 32x32 | walks | both |
| | 2 | 24x16 | walks | mirror |
| | 3 | 24x32 | walks | both |
| | 4 | 16x16 | walks, falls | both |
| | 5 | 24x32 | walks | both |
| | 6 | 24x32 | flies | mirror |
| 4 (3 Sky, 4 Labyrinth) | 1 | 24x16 | walks | mirror |
| | 2 | 24x32 | walks | both |
| | 3 | 32x24 | walks | mirror |
| | 4 | 16x16 | walks, falls | both (one of its two frames differs) |
| | 5 | 24x32 | walks | mirror |
| | 6 | 24x32 | flies | mirror |
| | 8 | 24x32 | walks | both |
| | 9 | 32x32 | walks | both |
| 6 (5 Sea, 6 Hell) | 1 | 24x32 | walks | mirror |
| | 2 | 24x16 | walks | mirror |
| | 3 | 24x32 | walks | mirror |
| | 4 | 16x16 | walks, falls | mirror |
| | 5 | 24x32 | walks | both |
| | 6 | 24x32 | flies | mirror |
| | 8 | 32x32 | walks | both |
| 7 (7 The Last World) | 1 | 24x32 | walks | mirror |
| | 2 | 24x32 | walks | both |
| | 3 | 32x32 | walks | both |
| | 5 | 24x32 | walks | mirror |
| | 6 | 24x32 | flies | mirror |
| | 8 | 24x32 | walks | both |
| | 9 | 24x32 | walks | both |

World 7 has no type 4. 29 of the original's 56 right-facing frames are exact mirrors;
where it drew both directions, the new art does too.

### E. Guardians (per bank; they do not turn)

| Bank (worlds) | Size | Original frames | New frames |
|---|---|---|---|
| 3 (1, 2) | 48x48 | 2 | **4** (two transitions between the path's two pictures) |
| 4 (3, 4) | 48x48 | 2 | **4** |
| 6 (5, 6) | 48x40 | 2 | **4** |
| 7, first guardian | 32x48 | 2 | **4** |
| 7, final guardian | 48x32 | 1 | **2** |

### F. Scenery cells (per bank, Layer 2)

| Bank (worlds) | Cells (16x16) | Used by the two maps | Sheet |
|---|---|---|---|
| 3 (1, 2) | 116 | 79 | `bank3-cells` |
| 4 (3, 4) | 116 | 81 | `bank4-cells` |
| 6 (5, 6) | 116 | 76 | `bank6-cells` |
| 7 (7) | 131 | 92 | `bank7-cells` |

- Cells the maps don't use are still drawn by play: item pictures, box contents and
  the pictures a blow uncovers. **Draw the maps' cells first.**
- **The growing plant** is cells `$7C`, `$7D` and `$7E`, shown one after another over
  a cell the player has stepped on: make it **6-8** pictures.
- **Cells `$79` and `$7A` are not drawn:** they are hidden triggers, filled at world
  set-up with a copy of that world's background cell (`$81` in the bank's first
  world, `$82` in the second), and must stay identical to it in each world's palette.
- The panel's item icons stay the original pictures (G); the new item pictures show in play.
- Cells must tile seamlessly with their neighbours: the map places them edge to edge.

### G. Kept exactly as the original (David, 2026-09-17: "keep all the screens intact")

These are not redrawn. The original draws them on the Spectrum screen (the ULA), and
the new presentation shows that drawing unchanged:

- the title, with its logos and colour cycling;
- the side and bottom panels: the LIFE, STR, POW and HIT labels, the energy bars, the
  score, the clock, the lives and the carried items. The item icons are drawn from the
  original item pictures, so an item shows in its new art in play and its original
  picture in the panel;
- the font and the large font, and every text screen and message: PRESS ANY KEY, the
  world intro card, LIFE LOST, OUT OF TIME, CONTINUE?, the hi-score table, the control
  menu, with the fallen figure under the messages;
- the ending (credits) picture;
- the Combat School advert.

## What must be covered

| Set | Spectrum pictures | Source with an arcade set |
|---|---|---|
| Player body poses | 6 (24 with extra frames) | arcade |
| Armour, flight, wing and peak layers | 26 (about 70) | arcade, per combination the capture shows |
| Weapons, shots, chain, blast | 29 (about 48) | arcade |
| Effects | 9 (20) | arcade |
| Enemies (directions drawn) | 83 (168, plus 5 fall poses) | arcade where it has them; the rest recoloured or hand-made |
| Guardians | 9 (18) | arcade |
| Scenery cells | 479, plus plant pictures | recoloured; hand-made by David |

How many enemies and cells have arcade counterparts is known only after the capture.

## Order of work

1. **The arcade capture:** set up MAME on the Deck with the logging script; David plays
   through.
2. **Contact sheets and mappings:** player, weapons and effects first (E3 needs them),
   then items, then each bank's enemies and guardian. David approves each group.
3. **The recolouring rules** for every graphic, so a build without an arcade set, or
   before a mapping exists, always has art.
4. **David's hand-made art:** scenery cells bank by bank (3, 4, 6, 7), then any enemy
   the arcade lacks.

The technical phases never wait: until a mapping or hand-made set is approved they use
the recoloured Spectrum art.

## Decided later

Whether David's hand-made art goes in the public repository, and under what terms, is
decided at its first delivery. Converted arcade art is never committed.
