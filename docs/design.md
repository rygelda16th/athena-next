# The enhanced design - Checkpoint A

Written 2026-09-17 from David's answers and the measurements behind them, and
checked by an adversarial review against the research and the disassembly. The art
is specified separately in **`docs/art-bible.md`**. Where this disagrees with the
plan, this wins; where it disagrees with `docs/where-things-stand.md`, that wins.

## The rule everything else follows

**The game logic stays the 1987 original, byte for byte, and the oracle proves it.**
Every enhancement reads the game's state and presents it differently; nothing
presented feeds back. **Every gameplay option** (difficulty, bug fixes, invisible
enemies) **defaults to the original**, and the oracle runs with them off - in both
presentations. The **presentation** defaults to the new graphics and the arcade
sound; **classic mode** switches to the original graphics and the original sound.
**Nothing copyrighted is committed**: the Spectrum game, the arcade game's files and
anything converted from them are read from the builder's own copies at build time.

## David's decisions (2026-09-17)

| # | Question | Decision |
|---|---|---|
| 1, d | Art | **Characters from the arcade, scenery from the Spectrum** (option d, replacing the first answer's faithful remaster of Ivan Horn's art): the player, armour, weapons, items, effects, enemies and guardians are SNK's arcade art, converted at build time wherever the arcade has them; the scenery cells, and any enemy the arcade lacks, are Ivan Horn's shapes coloured to sit with it. **Every screen stays intact**: the title, the panel and its font, the text screens, the ending (credits) picture and the Combat School advert are the original's own, in both presentations |
| 2 | Motion | **Smooth scrolling, sprites glide** between the positions the logic computes |
| 7 | Extra animation frames | **About double the original counts**: from the arcade's own animation for converted characters, drawn for hand-made art (the art bible lists each) |
| 3, 8, 9 | Sound | **Classic**: the original beeper sound, played cleanly. **Arcade**: the arcade game's music and effects, captured at build time from the builder's own copy of the arcade game (David's: the Steam SNK 40th Anniversary Collection) and **converted onto the Next's three AY chips** |
| - | The arcade set | **Optional**: without it the build still makes the enhanced port, with classic sound and recoloured Spectrum art |
| 10 | Where the arcade sound plays | **The proposed mapping** (below); final choices made by ear at E5 |
| 4 | Options menu | **Presets that set the individual settings**, adjustable; one switch for the nine bug fixes; the invisible enemies as their own switch |
| 5 | Pad controls | **Up still jumps, a second button also jumps, Start pauses**; keyboard, Kempston, cursor and Sinclair stay |
| 6 | Classic mode | **Yes**: one switch between the new graphics and sound and the original ones |

## What a build needs, and what it makes

| The builder has | Characters | Scenery | Sound |
|---|---|---|---|
| **The Spectrum files** (`make fetch`) | Spectrum art, recoloured automatically | Spectrum cells, recoloured automatically | classic |
| **+ an arcade set** in `data/arcade/` | **converted arcade art** | Spectrum cells, recoloured automatically | **arcade**, converted to AY |
| **+ hand-made art** in `data/art/` (David's, local) | converted arcade art; hand-coloured art for enemies the arcade lacks | **hand-coloured and shaded cells** | arcade |

Every level has classic mode. The repository holds only rules and mappings: colour
rules for the recolouring, tile numbers, colour sets and offsets for the arcade art,
command numbers and conversion rules for the arcade sound.

**The arcade set:** the build uses 9 of its files - the sound program (`p5.6g`,
`p6.6k`), the sprite and background graphics (`p7.2p`, `p8.2s`, `p9.2t`, `p10.2b`) and
the three colour PROMs (`3.2c`, `2.1b`, `1.1c`) - under MAME's current names or the
older board-location names David's copy uses. They are identical in all three MAME
versions of the game (`athena`, `athenab`, `sathena`), so any of them works; the build
checks those 9 checksums. The main program files are not needed to build.

## Display

**Layers** (the Spectrum screen's 256x192 area; the border stays unused):

| Layer | What | Why |
|---|---|---|
| **Layer 2**, 256x192, 256 colours | the play area's scenery | any pixel any colour; hardware scroll |
| **Hardware sprites** | everything that moves: player, weapons, shots, enemies, guardians, explosions, hearts | no flicker; the original's copy wiped every sprite once a pass |
| **ULA** | the side and bottom panels, every text screen and message, the title, the ending and the Combat School advert - the original's own drawing, in both presentations; in classic mode also the play area | every screen stays intact (decision 1); it does not scroll with Layer 2 |

- **The play area** is the original's: 208x128 at the top of the screen (character
  columns 3-28, rows 0-15). Layer 2 and the sprites are clipped to it; the ULA shows
  the original panel everywhere else. Text screens and the play-area messages (LIFE
  LOST, OUT OF TIME, the world intro card, the hi-score table) are the original's
  drawing on the ULA, and Layer 2 is hidden while they show. The original's copy of
  the play area to the ULA (`$EBFA`) is hidden under Layer 2 in the new presentation;
  E2 decides whether to skip it (the oracle hashes `$5B00`-`$FFFF`, not the display
  file, but the panel's attributes must still be written).
- **Why Layer 2 and not the Tilemap for the scenery:** 16 colours per 8x8 tile, where the
  remaster wants any colour in any pixel. The tile limit is tight too: world 7's 131
  cells would be 524 tiles if every cell is kept and no quarter is shared.
- **Scrolling:** the logic scrolls 2 pixels on a pass the player walks (a pass
  without walking runs a matching delay instead). Layer 2's X offset is set from the
  scroll position after the previous pass plus that pass's 2 pixels times the
  fraction of the pass shown so far - about 1 pixel every other display frame, never
  drifting from the logic. Layer 2 is 256 pixels wide and the play area 208, so the
  incoming 16-pixel cell column is drawn in the 48 hidden pixels before it slides
  into view. Map cells the game changes (a broken block, a collected item, the
  growing plant) are redrawn in Layer 2; a change of map part redraws the whole area.
- **Colour:** every colour is one of the Next's 512 (3 bits each of red, green,
  blue). Layer 2 has a **256-colour palette per world**, loaded at the world change,
  so the two worlds that share a bank's cells can have different colours. The
  **sprite palette** holds the arcade's 16 colour sets in the first 8 entries of each
  16-entry block (where 4-bit images with a palette offset look), and the recoloured
  and hand-made Spectrum art in the other 128 entries: a shared part for the player,
  weapons and effects, and a part per world for enemies and guardians. The panel and screens
  keep the Spectrum's colours. Transparency costs one sprite index and one Layer 2
  colour value (NextReg `$14`).

## Motion and timing

- **Game speed is the original's measured pace:** a pass takes 4.12-4.19 display
  frames in ordinary play (a strict 4 would run 3-5% fast); that figure already
  includes the blocking beeper effects in play. E1 decides whether a fixed average
  or a per-pass model reproduces it best; the oracle is unaffected either way.
- **60 Hz displays:** the logic's frame interrupts come from a 50 Hz timer, not the
  display, so the pass and every frame-counted wait (the CONTINUE? countdown's 50
  frames a digit, the world-complete flash's 256 frames, tune lengths, the ending's
  waits) keep their speed. A pass is then about 5 display frames.
- **Rendering between passes:** at 28 MHz a pass's logic finishes early in its first
  display frame. Over the pass's display frames the renderer moves every object from
  its position after the previous pass to its position after this one, by fraction of
  the pass. A pass's result is therefore fully on screen by the end of that pass.
  The original too shows a pass's result only near its end (its frame wait at
  `$CEFA` comes before the copy at `$D137`), so gliding adds no delay compared with
  1987. Predicting the next pass instead buys nothing but mispredictions (walls,
  ledge step-backs, guardian path jumps).
- **Logic the original runs inside its drawing code** has to keep running once a
  pass, whatever draws the picture: the flail's length and ball position, the
  feathered blade's beam, the broad sword's shot moving a column a pass, the rising
  heart, the enemy position map, the guardian's path step, the map-blow row, **the
  POW flash's read of the HIT bar's colour** (`$CB32`: the panel stays the original's
  on the ULA, so the read works unchanged) and **the AttackState reset in the weapon setup**
  (`$CF73`). The oracle hashes all of them and catches any slip.
- **Converted arcade characters animate with the arcade's own frames**, chosen per
  logic state by the mapping (below); the Spectrum's timing still decides when each
  shows.
- **Extra animation frames are pure presentation:** the only logic that reads an
  animation frame number is the walkers' step timing (slot byte 9 bit 1, `$CC36`, also
  loaded at `$CBFE` and `$CC11`), and it stays inside the unchanged logic. Art is keyed
  to the logic's state plus the fraction of the pass shown, never to a free-running
  clock, so a long pass holds the last picture instead of drifting. The per-object
  rules (walker gait, the blow, the flail and blade) are in the art bible.
- **Sprite images stream from RAM.** The Next holds 64 256-colour 16x16 images at
  once. Even the original frame counts need 80-98 per world, so the 64 slots are a
  cache: loaded on events (the weapon held, the armour level, flight, an enemy type
  when a slot fills, the guardian when it starts) and streamed as pictures change.
  The worst case is 38 images in one display frame, about 204,000 T-states, 36% of a
  28 MHz frame at 50 Hz.
- **Arcade tiles are Next sprite images as they stand.** An arcade sprite tile is
  16x16 with 8 colour values, and the arcade picks one of 16 colour sets per sprite;
  a Next 4-bit sprite image is 16x16 with 16 colour values and a 4-bit palette offset
  per sprite. So each arcade tile uploads once as a 4-bit image and its colour set
  becomes the sprite's palette offset: 128 slots instead of 64, at half the upload
  cost. Recoloured and hand-made Spectrum art stays 8-bit; E3 settles the mix.
- **When uploads happen:** only while the beam is below the play area. The play area
  is at the top of the screen, so that is one stretch of about 184 lines at 50 Hz
  (fewer at 60 Hz) - but the frame interrupt falls near its end, leaving about 63
  lines (115,000 T-states) before the display. So **each pass's logic and uploads
  start from a line interrupt at the play area's bottom line** (NextReg `$22`/`$23`),
  not from the frame interrupt.
- **The player is composited in software**, as the original builds it in a buffer:
  body, helmet, body armour, hand piece, winged legs and leg piece go into its two
  16x32 images. **The crescent wing (16x16) and the crouch peak (16x8) sit 8 pixels
  behind the body**, outside that box (`$CEE5`-`$CEF7`, `$D1B3`, `$D1C0`-`$D1D4`), so
  each is a sprite image of its own. The composite is rebuilt and uploaded whenever
  the player's picture changes, at most once a display frame: about 11,000 T-states
  for two images, 16,000 with the wing or peak (2-3% of a frame).

## The arcade art (option d)

**What the arcade set holds** (MAME `snk.cpp` and `snk_v.cpp`, decoded from David's
set into local preview sheets in `build/arcade-gfx/`):

- **Sprites:** 1,024 16x16 tiles, 3 bits a pixel. Values 0-5 are colours, 6 is a
  shadow (it darkens what is behind) and 7 is transparent. Up to 50 sprites at once,
  each with one of 16 colour sets. Athena's hardware has no mirror flag (those
  attribute bits are tile banks), so left- and right-facing art are stored separately.
- **Background:** 1,024 8x8 tiles, 4 bits a pixel, 16 palettes, in a scrolling map of
  64x64 tiles.
- **Colours:** three PROMs give 4 weighted bits per channel; the conversion quantises
  them to the Next's 3 bits.
- The arcade Athena is a 16x16 head over a 16x16 body - the Spectrum player's 16x32.

**What the graphics files do not hold:** which tiles make up each character, which
colour set each uses, and which frames animate together. The arcade's code decides
that while it runs. So **the arcade capture comes first**: David plays the arcade game
through once in MAME (on the Steam Deck; the managed Mac takes no personal installs),
and a Lua script logs, every frame, the sprite table, the background tiles and their
colours, and the sound commands. From that log `tools/` build contact sheets of every
arcade character and animation, and the **mapping** is authored: for each Spectrum
logic state (the art bible's asset tables), the arcade frames that show it - tiles,
colour sets, offsets and timing. David approves each group against the original.
Only the mapping is committed; the builder's own graphics files supply the pixels.

**Rules for converted art:**
- No redrawing: choose frames, place them, and crop only where a piece must go.
- Place each character at the Spectrum object's position (feet on the same line,
  centred on its box). It may be wider or taller than the Spectrum's box; the game's
  hits come from map cells, not pictures, so play is unchanged.
- The shadow value becomes a fixed dark colour or is dropped (the Next's sprites
  have no translucency); decided per character at mapping.
- Items and boxes are map cells on the Spectrum: their arcade pictures are drawn
  into the cell over its background at build time.
- Where the arcade has no counterpart, the Spectrum art is used: recoloured, or hand-
  coloured by David.

## Sound

**One switch** (decision 6): the new presentation plays the **arcade** sound, classic
mode the **original** sound. The original's tunes block the game (the world intro
card, the start-of-play jingles, a lost life); those waits stay, because they are
part of the logic's pace. In both modes the new sound replaces the calls into the
original's players (`$C408` effects, `$DEC6` tunes).

### Classic: the original beeper sound, played cleanly

The beeper routines are timing loops, so at 28 MHz they would play about 8x too high.
And recording the beeper at 1 bit a sample would not be clean: the tunes' character
is a pulse that narrows in 48-T-state steps (about 13.5 microseconds), far finer than
a 64-microsecond sample. So the speaker's edges are kept at T-state resolution and
turned into multi-bit samples by measuring how long the speaker was on in each
sample period - a band-limited result on the Next's DACs. E5 chooses between:

- **recorded edges:** the build runs the original's players on SkoolKit's simulator
  against the player's snapshot and stores the edge times (roughly 300 KB to 1 MB,
  measured at E5), or
- **a re-implemented tone generator** that reads the game's own tune data and effect
  table and produces the same edges at play time (no extra memory; some CPU).

What must be covered: all 14 tunes (tunes 0-3 loop until a key; tunes 4-13 are
one-shot jingles of 1.9-10.4 seconds) and the 8 effects - effect 12, the rising
heart, in each of its 16 variants (its mask byte `$BCCF` is rewritten at `$D222` as
the heart rises). E5 also settles the output route: the copper (as anotherworld-next
does, whose rate follows the display's line rate, so 60 Hz needs care, and which
uses 936 of the copper's 1,024 instructions) or the DMA.

### Arcade: captured from the builder's arcade copy, converted to AY

**The arcade hardware** (MAME `snk.cpp`, checked by a verifier): a 4 MHz sound Z80
with 48 KB of program (`p5.6g`, `p6.6k`), two YM3526 FM chips at 4 MHz, no samples.
The sound CPU's only interrupts are the two chips' timers and a command waiting, so
the chip timers most likely set the tempo (to be confirmed from the sound program).
The arcade's main CPU writes one byte per command to its own `$C400`; whether any
cue takes more than one command is for the survey to find. On a real board one chip
plays the music and the other the effects.

**Where the files come from:** the builder's own copy (David's is the Steam SNK 40th
Anniversary Collection, extracted with community scripts; lawfulness depends on the
country, and David has accepted the step). They go in `data/arcade/`, are checked
against MAME's published checksums, and are **never committed** (`docs/licence.md`).
Without them the build plays classic sound. SNK Corporation owns the arcade music.

**The build-time pipeline (E5):**

1. **Capture harness:** the sound Z80 plus two ymfm YM3526 cores (BSD, the cores
   MAME uses) with their timers, and the board's memory-mapped latch (`$E000`),
   chips (`$E800`-`$F400`) and status register (`$F800`, whose bits are cleared only
   by its acknowledge write). The harness plays a command and logs every chip write
   with its time. Its Z80 must allow memory-mapped I/O: SkoolKit's C simulator
   (which this project uses) keeps memory in a raw buffer and cannot, so it is
   SkoolKit's pure-Python simulator with a memory object (which must test IFF itself
   and step past HALT - its interrupt model is the Spectrum's), or the `z80` package
   built from source for arm64. The timers are 72 microseconds a step (timer 1) and
   288 (timer 2) at 4 MHz, not the datasheet's 3.58 MHz figures.
2. **Proof:** the harness's ymfm render of a command matches MAME's own render of the
   same command. The log also shows which chip carries music and which effects.
3. **Command survey:** every command value tried, plus the sound program's command
   handler read; David names the music by ear against SNK's album titles.
4. **Play-through log:** the arcade capture (above) also logs the arcade main CPU's
   writes to its `$C400`. This is **the only way to tie the unnamed effect commands
   to events** (jump, swing, hit, pickup), and it shows where each cue starts, stops
   and loops. It is David's one-off run; builders need only the resulting mapping.
5. **AY conversion** (wolf3d-next's `music.inc` method): each FM channel's frequency
   number and block become an AY note (the 4 MHz clock changes the pitch constant),
   the carrier's level becomes AY volume, decay and sustain shape the notes, and the
   FM drum mode, if used, goes to the AY noise channel. The converter keeps the
   capture's timestamps, and the Next's player runs at a fixed tick rate of its own
   (wolf3d-next's runs at 200 Hz), independent of 50 or 60 Hz video. Voices are
   allocated from the capture's measured counts; the starting split is wolf3d-next's,
   two AYs for music (6 voices) and one for effects (3). An instrument table keyed by
   a hash of each FM patch (so the repository holds nothing of SNK's) is **tuned by
   ear with David**.
6. **Loops:** the harness finds each tune's loop point from the sound program's
   state, so the converted tune loops exactly.

**Where it plays** (decision 10; moments from the 128K disassembly, cue titles as on
SNK's album CLRC-10031; all checked by ear at E5):

| Moment | Arcade cue |
|---|---|
| World intro card | world 1: "Setting Off"; later worlds: the coming world's theme |
| Play in world 1 Forest / 2 Cavern / 3 Sky / 4 Labyrinth / 5 Sea / 6 Hell | that world's theme, looping through play, restarting after a lost life |
| Play in world 7, The Last World | "World of Ice" (the arcade world the Spectrum lacks) |
| Guardian appears, worlds 1, 2, 5 | "Theme of Hamadrias, Godem, Neptune" |
| Guardian appears, worlds 3, 6 | "Theme of Glyphs (Gryphon), Chimera, Mado" |
| Guardian appears, world 4 | "Theme of Titan" |
| World 7 first guardian / final guardian | "Theme of Glyphs (Gryphon), Chimera, Mado" (or Titan) / "Theme of Dante" |
| Guardian destroyed, worlds 1-6 | the theme stops; silence or a short cue, by ear |
| World 7 completed, ending picture | "The End of Athena's Journey" |
| Life lost | the music stops; the arcade's unused death cue if the capture finds one |
| CONTINUE? taken | "Credit" |
| Game over | "Game Over" |
| Hi-score name entry | "Let's Meet Again Someday" |
| After the hi-score table (tune 11, cut short by a key) | "Let's Meet Again Someday" runs on, or silence, by ear |
| Title and menu | silent, or the attract cue if the arcade has one |

**Effects** go on the original's eight effect moments - effect 0 is both an enemy
destroyed and a guardian hit that does not destroy it (told apart by GuardianActive,
`$B955`), effect 2 both a block broken and a box opened, then player hurt, name
letter, item collected, heart released, heart collected, heart rising - and on
moments the original has none for, where the arcade has one: weapon swing, jump,
guardian destroyed, falling. New moments are detected from the logic's state, never
by changing it.

## Input and options (E6)

- **Controls:** keyboard (the original's define keys), Kempston, cursor, Sinclair,
  and a Mega Drive pad: up jumps, one button attacks, a second button also jumps,
  Start pauses. **The original's waits read only the keyboard** (`$C2E5`/`$C2ED`,
  even with Kempston chosen: PRESS ANY KEY, the credits, CONTINUE?, the release from
  pause), so the pad's buttons and Start answer those too. Name entry stays on the
  keyboard.
- **Options menu:** presets Original (default), Easier, Easy, each setting the
  individual levers of `docs/difficulty.md` - lives, continues, time to answer
  CONTINUE?, energy, contact damage, immunity length, clock, guardian strength,
  keeping items after a lost life, poison drain, the feathered blade's cost - which
  can then be changed one by one. One switch fixes all nine bugs on the Bugs page.
  **Invisible enemies** is its own switch (721 of 851 list starts never appear;
  showing them makes the game harder). Preset values are tuned by play at E6.
- **Settings are saved to the SD card.**

## Memory

The target is the Next's **2 MB profile** (1,792 KB usable; the KS3 and expanded
Nexts). Rough budget: the original game 144 KB; Layer 2's picture 48 KB; new code
about 64 KB; sprite art under about 380 KB for every world (the arcade's 1,024 tiles
are 131 KB as 4-bit images, plus the Spectrum art the arcade lacks);
scenery cells about 125 KB; arcade AY music about 100 KB; classic sound 0-1 MB
depending on E5's choice - about 0.8-1.8 MB (the screens are the original's, so
they cost nothing). **If recorded edges come out large, E5 takes the
re-implemented tone generator.** A 1 MB Next (768 KB) would need each world loaded
from the SD card at the world change; that is not planned.

## The phases from here

| Phase | What | Gate |
|---|---|---|
| Art track | the arcade capture (MAME play-through on the Deck); contact sheets and the mapping, group by group; the recolouring rules; David's hand-made cells and Spectrum-only enemies, checked by `tools/artimport.py` | David approves each group's mapping and each world's sheet |
| E1 | pacing at 28 MHz: the original's measured pace, the 50 Hz logic timer on 60 Hz displays, the line-interrupt start of each pass | oracle green; pass length within the measured range |
| E2 | Layer 2 play area, palettes, the original panel and screens on the ULA, the draw-path logic kept | pixel-exact against a Python reference render (placeholder art: the originals recoloured); oracle green |
| E3 | hardware sprites, the image cache, player compositing, gliding, extra frames | pixel-exact against the reference; no flicker |
| E4 | hardware scrolling | pixel-exact against the reference |
| E5 | classic sound; arcade sound harness, proof against MAME, command survey, AY conversion, loops, placement (from the capture's log) | capture matches MAME; David signs off by ear |
| E6 | controls and options | oracle green with options off; a check per option |
| E7 | approved mappings and hand-made art, world by world; the build's three levels checked | David's per-world sign-off; a build with no arcade set still passes every gate |
| E8 | the KS3: timing, sound, colour, the upload window | on the hardware |

**What David does along the way:** play the arcade game through once in MAME on the
Deck for the capture (early, before the art mapping); approve the arcade mappings;
colour and shade the scenery cells and any Spectrum-only enemies; name the arcade tunes
and tune the AY instruments by ear; play-test the presets. (The arcade set is already
in `data/arcade/`.)

## Still open

- Whether David's hand-made art (coloured Spectrum shapes) goes in the public
  repository, and under what terms (at its first delivery). Converted arcade art is
  never committed.
- From the capture: how many Spectrum enemies and cells have arcade counterparts;
  how the larger arcade guardians fit the Spectrum's guardian positions; the shadow
  value per character.
- A playable release: out of scope without the rights holders.
- For the stages named: the arcade's command numbers, tempo source, loop behaviour
  and chip split (E5); the classic sound's storage form (E5); how the pace model
  handles passes with effects (E1); the KS3's sprite, DAC and copper timing (E8).
