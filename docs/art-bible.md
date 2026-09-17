# The art bible

Written 2026-09-17 for Checkpoint A and checked by an adversarial review against the
graphics, the snapshot and the disassembly. It says what every new graphic must be:
its size, how many frames, which colours it may use, what drives its animation, and
in what order the art is made. The design it serves is **`docs/design.md`**.

The originals are the reference: `make gfx` writes a sheet of every graphic set to
`build/gfx/` (open `build/gfx/index.html`). They are your own game's pictures, so
they stay local. The art track adds a brief sheet per asset (the original enlarged
on a pixel grid, labelled, both directions shown, with empty slots for the new
frames) and `tools/artimport.py`, which fits, quantises and checks a drawing against
this document.

## Style: a faithful remaster

- **Keep** Ivan Horn's silhouettes, poses and proportions. Every picture must still
  read at its real size on a TV.
- **Add** colour and shading. Light comes from the top left, for everything.
- **Sprites** get a one-pixel dark outline, so they read against coloured scenery;
  the original had black paper behind everything and needed none.
- **Scenery** is darker and less saturated than the sprites, for the same reason.
- **Hard edges only:** no anti-aliasing against transparency and no partial
  transparency.
- **World colours** follow the world, not the Spectrum's single ink colour (the
  original's world 1 is bright cyan). A starting point, decided world by world:

| World | Name | Original ink | Suggested mood |
|---|---|---|---|
| 1 | Forest | bright cyan | greens and bark browns |
| 2 | Cavern | yellow | earth, ochre, dim stone |
| 3 | Sky | white | blues, cloud white, gold |
| 4 | Labyrinth | cyan | cold grey-green stone |
| 5 | Sea | green | blue-greens, coral, sand |
| 6 | Hell | magenta | reds, black rock, lava orange |
| 7 | The Last World | white | pale ice blue and grey (the arcade's Ice music plays here) |

## Hard limits

| What | Limit |
|---|---|
| Every colour | one of the Next's 512: 3 bits each of red, green and blue |
| **Size** | inside the original's width and height (below), so what the player sees matches 1987. (The logic's hits do not come from the picture: an enemy's hit cells come from its top-left cell and its height, and the guardian's from a fixed 4x4 block of cells.) A 24-pixel-wide graphic sits in a 32-pixel sprite box; the spare 8 pixels stay transparent |
| Scenery cells, title, ending | Layer 2, from a **256-colour palette**, opaque - and never the transparency colour (the 8-bit value in NextReg `$14`, default `$E3`: two of the 512 colours) |
| Sprites | built from 16x16 images; one index of the sprite palette is transparent. The palette is shared: about half for the player, armour, weapons and effects (every world), about half for the world's enemies and guardian |
| Panel, fonts, item icons, text | 8x8 tiles on the tilemap: 16 colours per tile from one of 16 sub-palettes, of which index 15 (NextReg `$4C`) is transparent - **15 drawable colours per tile** |

Two worlds that share a bank (1 and 2, 3 and 4, 5 and 6) **share the same cell and
enemy pictures**. Each world has its own palette, so the same drawing can be coloured
twice: the picture is drawn once with palette indices, and each world gets its colours.

## How animation is keyed

A pass of the game's logic lasts a little over 4 display frames at 50 Hz: usually 4,
sometimes 5 (the feathered blade's passes, some passes in world 7), and about 5 on a
60 Hz display. New pictures are placed by **fraction of the pass**, from the logic's
state - never from a clock of their own - and a long pass holds its last picture.
The ceiling is one picture per display frame. The counts below are about double the
original's (David's decision 7).

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

"Mirror" means the other direction comes from the hardware's mirror flag, so it is
not drawn. "Both" means the original has separately drawn art for each direction,
and so does the new art.

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
- The item pictures double as the panel's item icons (G).
- Cells must tile seamlessly with their neighbours: the map places them edge to edge.

### G. Panel, fonts and text (tilemap: 8x8 tiles, 15 colours per tile)

| Asset | Original sheet | Size | Notes |
|---|---|---|---|
| Font | `5c40-font` | 8x8, 44 characters (digits, punctuation, capitals) | every message, the score, the clock, the hi-score table |
| **Large font** | (the same font doubled) | 16x16, the same 44 characters (2x2 tiles each) | PRESS ANY KEY / TO PLAY, the intro card's world name, the CONTINUE? countdown digit; drawn as its own font |
| Panel labels LIFE, STR, POW, HIT | `f000-panel-labels` | 16x32, 16x24, 16x16, 16x24 | POW and LIFE flash: palette effects, not frames |
| Energy bar unit and end | `bab8-panel-pieces` | 16x8 each | |
| Fallen figure | `bab8-panel-pieces` | 32x16 | shown under LIFE LOST, OUT OF TIME, OUT OF LIFE and ABORT PRESSED |
| Item icons | the world's item cells (F) | 16x16 with a one-pixel frame | 15-colour versions for the panel |
| Panel frame and backgrounds | (attribute colours in the original) | 8x8 tiles | the layout stays the original's: the logic prints to fixed rows and columns |

### H. Screens (Layer 2, 256x192, own palette)

| Asset | Original | New |
|---|---|---|
| Title | `f5d8-title`: SNK logo 104x32, Imagine logo 104x40, Athena 64x128, ATHENA logo 128x40 | one composed 256x192 title; the logo's colour cycling becomes palette cycling |
| Ending (credits) picture | `bank1-ending`: Athena with the programming, music and graphics credits | 256x192, **keeping the 1987 credits** (and adding the port's) |
| Combat School advert | `bank1-combat-school` | **not redrawn**: the new graphics drop it; classic mode keeps it |

## Totals

| Set | Original pictures | New (about) |
|---|---|---|
| Player body poses | 6 | 24 |
| Armour, flight, wing and peak layers | 26 | 70, more where new poses move the head or hand |
| Weapons, shots, chain, blast | 29 | 48 |
| Effects | 9 | 20 |
| Enemies (directions drawn) | 83 | 168, plus 5 fall poses |
| Guardians | 9 | 18 |
| Scenery cells | 479 | 479, plus plant pictures |
| Fonts, panel pieces | 51 | 95, plus item icons |
| Screens | 2 | 2 |

## Order of work

1. **The player, weapons and effects**, which every world uses and E3 needs first.
2. **Bank 3** (worlds 1 and 2): cells, enemies, guardian.
3. **Bank 4**, then **bank 6**, then **bank 7**.
4. **Panel, fonts and item icons.**
5. **Title and ending.**

For each: a brief sheet goes out; you generate drafts; `tools/artimport.py` scales
them to the grid, quantises them to the palette and checks the limits above; the
result is hand-cleaned; you approve the sheet, shown beside the original. The
technical phases never wait: until a set is approved they use the original,
recoloured automatically.

## Decided at the first delivery

Whether generated art of SNK's and Imagine's characters, and of the two companies'
logos on the title, goes in the public repository, and under what terms. Until then
new art stays local.
