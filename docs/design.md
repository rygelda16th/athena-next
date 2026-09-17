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

## David's decisions (2026-09-17)

| # | Question | Decision |
|---|---|---|
| 1 | Art style | **Faithful remaster**: Ivan Horn's poses and outlines, coloured and shaded. (Not answered, so the recommendation stands until David says otherwise: new title, panel, font and ending; the Combat School advert dropped from the new graphics, kept in classic mode.) |
| 2 | Motion | **Smooth scrolling, sprites glide** between the positions the logic computes |
| 7 | Extra animation frames | **About double the original counts** (the art bible lists each) |
| 3, 8, 9 | Sound | **Classic**: the original beeper sound, played cleanly. **Arcade**: the arcade game's music and effects, captured at build time from David's own copy of the arcade game (the Steam SNK 40th Anniversary Collection) and **converted onto the Next's three AY chips** |
| 10 | Where the arcade sound plays | **The proposed mapping** (below); final choices made by ear at E5 |
| 4 | Options menu | **Presets that set the individual settings**, adjustable; one switch for the nine bug fixes; the invisible enemies as their own switch |
| 5 | Pad controls | **Up still jumps, a second button also jumps, Start pauses**; keyboard, Kempston, cursor and Sinclair stay |
| 6 | Classic mode | **Yes**: one switch between the new graphics and sound and the original ones |

## Display

**Layers** (the Spectrum screen's 256x192 area; the border stays unused):

| Layer | What | Why |
|---|---|---|
| **Layer 2**, 256x192, 256 colours | the play area's scenery, the title, the ending picture | any pixel any colour; hardware scroll |
| **Hardware sprites** | everything that moves: player, weapons, shots, enemies, guardians, explosions, hearts | no flicker; the original's copy wiped every sprite once a pass |
| **Tilemap**, 40x32 cells of 8x8 tiles, 15 colours and transparent per tile | the side and bottom panels, the font and the large font, every text screen and message | does not scroll with Layer 2; its 512 tiles hold the panel, both fonts and the item icons |
| ULA | classic mode | the original's own screen |

- **The play area** is the original's: 208x128 at the top of the screen (character
  columns 3-28, rows 0-15). Layer 2 and the sprites are clipped to it; the tilemap
  shows through everywhere else. Text screens and the play-area messages (LIFE
  LOST, OUT OF TIME, the world intro card, the hi-score table) hide Layer 2 while
  they show.
- **Why not the Tilemap for the scenery:** 16 colours per 8x8 tile, where the
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
  **sprite palette** has a shared part (player, armour, weapons, effects, hearts, the
  flame and bomb) and a part per world (enemies, guardian). The tilemap has 16
  sub-palettes of 16. Transparency costs one sprite index, one Layer 2 colour value
  (NextReg `$14`) and one index in each tilemap sub-palette (NextReg `$4C`).

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
  POW flash's read of the HIT bar's colour** (`$CB32`: the ULA attributes must still
  be written, or the read answered) and **the AttackState reset in the weapon setup**
  (`$CF73`). The oracle hashes all of them and catches any slip.
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

### Arcade: captured from David's arcade copy, converted to AY

**The arcade hardware** (MAME `snk.cpp`, checked by a verifier): a 4 MHz sound Z80
with 48 KB of program (`p5.6g`, `p6.6k`), two YM3526 FM chips at 4 MHz, no samples.
The sound CPU's only interrupts are the two chips' timers and a command waiting, so
the chip timers most likely set the tempo (to be confirmed from the sound program).
The arcade's main CPU writes one byte per command to its own `$C400`; whether any
cue takes more than one command is for the survey to find. On a real board one chip
plays the music and the other the effects.

**Where the files come from:** David's own copy - the Steam SNK 40th Anniversary
Collection, which holds the same program files as MAME's `athena` set, extracted
with community scripts (lawfulness depends on the country; David has accepted the
step). The whole set is needed: the sound files for the capture, and the main
program files for the MAME play-through that identifies the effects. The files go
in `data/arcade/`, checked against MAME's published checksums, and are **never
committed** (`docs/licence.md`). SNK Corporation owns the arcade music.

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
4. **Play-through log:** MAME taps the arcade main CPU's writes to its `$C400` while
   the arcade game is played through once. This is **the only way to tie the
   unnamed effect commands to events** (jump, swing, hit, pickup), and it shows
   where each cue starts, stops and loops.
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
about 64 KB; sprite art about 300-380 KB for every world at the extra frame counts;
scenery cells about 125 KB; title and ending screens 96 KB; panel, fonts and item
tiles about 16 KB; arcade AY music about 100 KB; classic sound 0-1 MB depending on
E5's choice - about 1.0-1.9 MB. **If recorded edges come out large, E5 takes the
re-implemented tone generator.** A 1 MB Next (768 KB) would need each world loaded
from the SD card at the world change; that is not planned.

## The phases from here

| Phase | What | Gate |
|---|---|---|
| Art track | briefs from `docs/art-bible.md`; David generates; `tools/artimport.py` fits, quantises and checks; hand-cleaning | David approves each world's sheet |
| E1 | pacing at 28 MHz: the original's measured pace, the 50 Hz logic timer on 60 Hz displays, the line-interrupt start of each pass | oracle green; pass length within the measured range |
| E2 | Layer 2 play area, tilemap panel and text, palettes, the draw-path logic kept | pixel-exact against a Python reference render (placeholder art: the originals recoloured); oracle green |
| E3 | hardware sprites, the image cache, player compositing, gliding, extra frames | pixel-exact against the reference; no flicker |
| E4 | hardware scrolling | pixel-exact against the reference |
| E5 | classic sound; arcade capture harness, proof against MAME, command survey, play-through log, AY conversion, loops, placement | capture matches MAME; David signs off by ear |
| E6 | controls and options | oracle green with options off; a check per option |
| E7 | approved art, world by world | David's per-world sign-off |
| E8 | the KS3: timing, sound, colour, the upload window | on the hardware |

**What David does along the way:** buy the Steam SNK 40th Anniversary Collection and
extract the arcade set before E5; play the arcade game through once in MAME for the
play-through log; name the arcade tunes and tune the AY instruments by ear; generate
and approve the art; play-test the presets.

## Still open

- Whether generated art of SNK's and Imagine's characters and logos goes in the
  public repository, and under what terms (at the first art delivery).
- A playable release: out of scope without the rights holders.
- Decision 1's extra screens (the recommendation stands until David answers).
- For the stages named: the arcade's command numbers, tempo source, loop behaviour
  and chip split (E5); the classic sound's storage form (E5); how the pace model
  handles passes with effects (E1); the KS3's sprite, DAC and copper timing (E8).
