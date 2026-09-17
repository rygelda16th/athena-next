# The plan from Checkpoint A to the finished port

**Progress is in `docs/where-things-stand.md`, which is canonical.** This file is the plan as it
was written; where the work deviated from it - the classic sound's form, MAME as the sound
harness, which mappings and bug fixes are done - that file says so.

Written 2026-09-17, the day David approved Checkpoint A. It lines up everything left:
the order of the steps, what each builds, the command that proves it, and what David
checks or does at each checkpoint. The design is `docs/design.md`, the art
`docs/art-bible.md`; the canonical status stays `docs/where-things-stand.md`.

## How the work is organised

Three tracks, worked in one order:

- **E - the engine:** the enhancements, E1-E8, each proven by the oracle (the game
  logic unchanged) plus its own check.
- **C - the arcade conversion:** capture the arcade game once in MAME, then map its
  characters (C1-C3). The capture also feeds the arcade sound in E5.
- **H - David's hand-made art:** scenery cells and any enemy the arcade lacks, done
  whenever David likes once its tools exist; it never blocks anything.

Every step ends the same way as G0-D7: a gate command that passes, a git tag, an entry
in `docs/where-things-stand.md`, and a stop for David. **Every gate also runs on a
build with no arcade set**, so the port always works from the Spectrum files alone.

## The order

| # | Step | Needs | Gate | David's checkpoint | Tag |
|---|---|---|---|---|---|
| 1 | **E1** Pace at 28 MHz | - | `make check-pace`, `make check-oracle` | play in CSpect: original speed? | `e1` |
| 2 | **C1** Arcade capture tooling | the arcade set (in) | `make check-capture` | play the arcade game through in MAME on the Deck | `c1` |
| 3 | **E2** Play area on Layer 2 | E1 | `make check-render`, oracle | look in CSpect | `e2` |
| 4 | **E3** Hardware sprites | E2 | `make check-sprites`, oracle | no flicker, gliding, in CSpect | `e3` |
| 5 | **C2** Contact sheets; first mapping (player, weapons, effects) | C1 play-through, E3 | `make check-mapping` | approve the first mapping, seen in the game | `c2` |
| 6 | **E4** Hardware scrolling | E3 | `make check-scroll`, oracle | smooth scroll in CSpect | `e4` |
| 7 | **E5** Sound: classic, then arcade | E1; C1 play-through for the effects | `make check-classic-sound`, `make check-arcade-capture`, `make check-arcade-sound` | name the arcade tunes; tune the AY instruments by ear; sign off placement | `e5` |
| 8 | **C3** Remaining mappings: items, then each bank's enemies and guardian | C2 | `make check-mapping` | approve each group | `c3` |
| 9 | **E6** Controls and options | E1 | `make check-options`, oracle | play-test the presets; set their values | `e6` |
| 10 | **E7** Integration: all mappings and hand-made art; the three build levels | C3, E6, H so far | `make check-levels` | sign off each world in CSpect | `e7` |
| 11 | **E8** The KS3 | the machine; E7 | the hardware checklist | play it on the KS3 | `e8` |
| any | **H** Hand-made art (scenery cells bank by bank; Spectrum-only enemies) | E2 (palettes), `tools/artimport.py` | `make check-art` | draw, and approve each bank's sheet | - |
| any | **KS3 smoke test**, the week it arrives (due end of September) | the machine | the early checklist | run the builds on the hardware | - |

C1 comes second because it needs David's time: while he plays the arcade game
through, E2 and E3 go ahead, and the log is ready when C2 and E5 need it.

## The steps

### 1. E1 - Pace at 28 MHz

- **Build:** `athena.nex` at 28 MHz, pacing the original's passes to their measured
  length (4.12-4.19 display frames in ordinary play). E1 settles whether a fixed
  average or a per-pass model does it best.
  - Each pass starts from a line interrupt below the play area.
  - The logic's frame interrupt comes from a 50 Hz timer, so 60 Hz displays keep the
    speed.
- **Interim sound:** until E5 the beeper tunes and effects play at 3.5 MHz (the CPU
  drops around `$C408` and `$DEC6`), so they are not 8x too high.
- **Gate:**
  - `make check-pace`: pass lengths over a replay, at 50 and 60 Hz, inside the
    measured range.
  - `make check-oracle`: the whole recording still matches at 3.5 and 28 MHz.
- **Risk:** passes that contain effects, and the interrupt the original loses each
  pass.

### 2. C1 - Arcade capture tooling

- **Build:**
  - MAME on the Steam Deck (the managed Mac takes no personal installs). If MAME will
    not run there, the fallback is MAME in the tools container, replaying an input
    recording.
  - A Lua script that logs, every frame: the sprite table, the background tiles, their
    colours and scroll, and the arcade main CPU's sound commands. It appends across
    sessions and save states.
  - `tools/` code that reads the logs.
- **Gate:** `make check-capture`. A frame drawn from the log plus the arcade files
  matches MAME's own snapshot of that frame, pixel for pixel, on a test run of the
  attract mode.
- **David:** plays all eight arcade worlds through, in as many sessions as he likes
  (cheats allowed). Every enemy, guardian, weapon, item and sound should appear at
  least once.

### 3. E2 - Play area on Layer 2

- **Build:**
  - Layer 2 scenery clipped to the play area, with a 256-colour palette per world.
  - The original panel and every screen shown unchanged on the ULA.
  - The **recolouring rules** for the scenery cells: the art every build has.
  - A Python reference renderer.
  - The logic the original runs inside its drawing code kept running: the POW flash's
    attribute read, the flail, the blade, the shot, the heart, the position map, the
    guardian path, the map-blow row, the AttackState reset.
  - Whether to skip the original's copy to the screen, now hidden.
- **Gate:** `make check-render`: the play area matches the reference pixel for pixel at
  checkpoints across all seven worlds; the oracle stays green.
- **Also built at the end of E2, so H can start:** `tools/artimport.py` (fit, quantise,
  check) and brief sheets for the cells.

### 4. E3 - Hardware sprites

- **Build:**
  - Every moving object on hardware sprites, with the recolouring rules for sprites.
  - The image cache, uploading from the line interrupt.
  - The player composited in software, with the crescent wing and crouch peak as
    separate sprites.
  - Gliding by fraction of the pass.
  - The state-to-frames table that mappings will fill; until then, the original frames.
  - Arcade tiles as 4-bit images beside 8-bit ones: this mix is untested and gets
    proven here.
- **Gate:** `make check-sprites`. Pixel-exact against the reference, and every sprite
  present in every display frame (no flicker). The cache's worst case is measured.
  Oracle green.

### 5. C2 - Contact sheets and the first mapping

- **Build:**
  - From the play-through log, a contact sheet of every arcade character: its
    animations, colour sets and the tiles that make it up.
  - The mapping format and tool.
  - The first group: the player (each combination of pose, armour and flight), the
    weapons and the effects.
- **Gate:** `make check-mapping`. Every state in the art bible's tables A-C is covered;
  every tile and colour set it names exists; the sheet is built. The mapped art shows
  in the game.
- **David:** approves the sheet (the Spectrum original beside the arcade version) and
  looks at it in CSpect.

### 6. E4 - Hardware scrolling

- **Build:**
  - Layer 2's offset set from the scroll position plus the fraction of the pass.
  - The incoming cell column drawn in the 48 hidden pixels.
  - A full redraw on a change of map part.
- **Gate:** `make check-scroll`: pixel-exact against the reference in mid-pass frames
  too; oracle green.

### 7. E5 - Sound

**E5a, classic.**
- **Build:**
  - Measure the recorded-edges form against a re-implemented tone generator, and pick
    one (memory decides).
  - The output route: copper or DMA, including 60 Hz.
- **Gate:** `make check-classic-sound`. The edges the port plays match the original's,
  simulated, for all 14 tunes, the 8 effects and effect 12's 16 variants.

**E5b, arcade capture.**
- **Build:**
  - A sound-board harness: a Z80 that can see memory-mapped writes (SkoolKit's
    pure-Python simulator with a memory object, or the `z80` package built for arm64),
    plus two ymfm YM3526 cores with their timers.
  - The command survey.
- **Gate:** `make check-arcade-capture`. The harness's render of each command matches
  MAME's own recording of it.

**E5c, conversion.**
- **Build:**
  - The AY player, from wolf3d-next's `music.inc`.
  - The instrument table keyed by FM patch hash.
  - Exact loops.
  - Placement per decision 10, using the play-through log to name the effects.
- **Gate:** `make check-arcade-sound`. The AY register stream per tick matches the
  conversion model, and loops are exact.
- **David:** names the tunes, tunes the instruments by ear, and signs off where each
  cue plays.

### 8. C3 - The remaining mappings

- **Groups, in order:**
  1. Items and boxes (drawn into their cells).
  2. Bank 3's enemies and guardian.
  3. Bank 4.
  4. Bank 6.
  5. Bank 7.
- **Settled per group:** the shadow value, how the larger arcade guardians sit, and
  which Spectrum enemies have no arcade counterpart. That list goes to H.
- **Gate:** `make check-mapping`, per group.
- **David:** approves each group.

### 9. E6 - Controls and options

- **Controls:**
  - Kempston, cursor, Sinclair and the keyboard as before.
  - Mega Drive pad: up jumps, a second button also jumps, Start pauses.
  - The pad answers the original's keyboard-only waits: PRESS ANY KEY, CONTINUE? and
    the release from pause.
- **The options screen:** a new text screen in the original's style (the existing
  screens stay untouched). It holds:
  - presets that set the individual difficulty levers;
  - the nine-bug-fix switch;
  - the invisible-enemies switch;
  - the classic mode switch;
  - settings saved to the SD card (the esxDOS lessons from anotherworld-next apply).
- **Gate:** `make check-options`:
  - the oracle green with every option off;
  - a scripted run per option, showing the effect `docs/difficulty.md` measured;
  - the pad answering every wait.
- **David:** play-tests the presets and sets their values.

### 10. E7 - Integration

- **Build:** every approved mapping, and David's approved hand-made art, in the build,
  world by world.
- **Gate:** `make check-levels`. Three builds pass every gate:
  - Spectrum files only;
  - with the arcade set;
  - with the hand-made art.
- **David:** signs off each world in CSpect.

### 11. E8 - The KS3

- **What gets checked on the machine:**
  - pace;
  - the sprite upload window, and 4-bit and 8-bit images together;
  - the copper or DMA sound route;
  - the AY chips;
  - colour;
  - 60 Hz over HDMI;
  - saving settings to the card.
- **Gate:** the hardware checklist, each item passing.
- **David:** plays it on the KS3.

**The KS3 smoke test** runs the week the machine arrives, whatever step we are on:
- the G3 `athena.nex` and the newest build run;
- the numbers only hardware can answer are measured early: sprites per line, the
  copper's DAC rate, the card's read speed with interrupts off.

### H - David's hand-made art

- **Starts:** after E2, with `tools/artimport.py` and brief sheets.
- **Order:** scenery cells bank by bank (3, 4, 6, 7), then any enemy C3 found the arcade
  lacks.
- **Gate:** `make check-art`: size, palette, transparency and seamless tiling.
- **Storage:** everything stays in `data/art/`.
- **David:** approves each bank's sheet.
- **Still to decide, at the first delivery:** whether any of it may be published.

## David's jobs, in order

1. **After E1:** play `athena.nex` in CSpect at 28 MHz and say whether the speed feels right.
2. **After C1:** play the arcade game through in MAME on the Deck, all eight worlds.
3. **After E2:** look at the play area; start hand-made cells whenever you like (H).
4. **After E3:** check the sprites in CSpect.
5. **After C2:** approve the first mapping (player, weapons, effects).
6. **After E4:** check the scroll.
7. **During E5:** name the arcade tunes, tune the AY instruments by ear, sign off placement.
8. **During C3:** approve items, then each bank's enemies and guardian.
9. **After E6:** play-test and set the presets.
10. **After E7:** sign off each world.
11. **When the KS3 arrives:** run the smoke test builds; at E8, play it on the machine.

## What finished means

- **The logic:** the oracle is green at 3.5 and 28 MHz, on 50 and 60 Hz timing, with
  every option off.
- **The builds:** Spectrum files only, with the arcade set, and with hand-made art all
  build and pass every gate.
- **Classic mode:** plays the original graphics and sound.
- **Hardware:** the KS3 checklist passes.
- **The record:** `docs/where-things-stand.md` records every gate.
- **What is published:** the repository holds only code, tools, rules, mappings and
  annotations - nothing of Imagine's or SNK's.
