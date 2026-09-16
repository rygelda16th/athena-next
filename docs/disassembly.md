# The disassembly - how it is annotated, and what is still open

Chunks D1-D7 (David's decision: the disassembly is complete before any enhancement).
D1-D3 established 2026-09-16.

## Where it lives

- **`src/athena.ctl`** (the 64K the game runs in, bank 0 at `$C000`) and
  **`src/bank1.ctl`, `bank3.ctl`, `bank4.ctl`, `bank6.ctl`, `bank7.ctl`** (data banks)
  hold every annotation: block types and boundaries, titles, descriptions,
  register tables, comments and labels. They contain addresses and words, never
  the game's bytes (`make check-ctl` refuses a ctl that holds any).
- **`src/athena.ref`** sets up the HTML: game name, credits, the five data banks
  as "Other code", hex page names.
- `tools/annotate.py ... --bank N` applies annotations to `src/bankN.ctl`; in bank text,
  an address that is not a statement in the bank is linked to the game's code (`@main`).
- `make skool` regenerates `work/*.skool` from the ctl files and your snapshot;
  **`make html`** builds `build/html/athena/index.html` from them. The HTML holds
  the game's bytes, so it stays on your machine.

## How a chunk is annotated

1. **Analysis.** One analyst per subsystem, each with a narrow remit, working from
   `work/athena.skool`, the recording (`tools/rzxsim.py`) and snapshots, and
   required to give evidence for every claim - an address and what the
   instructions do, or a trace or snapshot result. Anything not established goes
   in an "unresolved" list instead of the disassembly.
2. **Adversarial review.** A reviewer tries to refute every title, description,
   register table and variable meaning and a third of the comments, and gives
   replacement text for anything wrong. D1's four reviews checked 292 items:
   196 confirmed, 77 partly right, 14 refuted, 5 unverified. Every correction to
   text that reaches the disassembly was applied; corrections that only fixed an
   analyst's reader and writer lists (working notes, not published) were not.
3. **Merge** (`build/d1/merge.py`, local). Every correction is applied as a
   replacement that must find the text it replaces, so none can be dropped
   silently. Where two analysts described the same thing, the merge prefers the
   one whose remit it was, and resolves overlaps and label clashes explicitly.
4. **Apply** (`tools/annotate.py`): step `ctl` changes block boundaries and lays
   out variables as sub-blocks; `make skool`; step `skool` writes titles,
   descriptions, registers, comments and labels (and turns variables that are
   really instruction operands into comments on those instructions); `make ctl`
   writes the canonical ctl back.
5. **Gates:** `make check-ctl` (lossless round trip) and `make check-reasm` (all
   131,072 bytes reproduced in both builds) - annotations can never change the
   game.

**Found the hard way (D1):** analysts that returned their whole annotation set as
one final answer died, 37 times, the moment composing that answer took more than
three minutes - after 9-19 minutes of good research each time. The fix was to
write annotations to files as they are established and return only a file list;
all five agents then finished first time. D2-D7 work the same way.

## D1 naming decisions

Where analysts disagreed, the reviewer's evidence decided:

| Address | Label | Why |
|---|---|---|
| `$B95C` | `MapColumn` | scroll position / 8: the map column (8 cells a column) - not "MapColumnHalf" |
| `$B95A` | `ScrollQuarter` | scroll position / 4 - not "MapColumn" |
| `$BA17` | `MapWindow` | moves as the view scrolls; "WorldDataPtr" described only its first value |
| `$BA35` | `PlayerBufferPos` | where in the sprite buffer at `$5C00` the player is drawn - not a graphic address |
| `$CCB9` | `Credits` | one more than the CONTINUE? offers left; the POKE list's name, kept |
| `$D5D2`, `$D5DB` | `WorldListAddr`, `WorldListCount` | the world's list of enemy starts |

## D2 - the renderer

Same method as D1: four analysts (playfield, sprites, text and panel, graphics
catalogue) writing to files as they go, two adversarial reviewers (193 items: 155
confirmed, 31 partly right, 3 refuted, 4 unverified), a merge whose corrections must
find their text (`build/d2/merge.py`, `build/d2/corrections.py`), and nine corrections
to D1 text applied in `src/athena.ctl` (each must match exactly once).

**Graphics:** `make gfx` writes a PNG sheet of every graphic set - player, armour,
weapons, effects, font, panel pieces, title logos, the two bank 1 screens, and for
each world bank the map cells, enemy frames and guardians - to `build/gfx/` with an
`index.html`, from your own files. The formats are in `tools/extract_gfx.py`'s
header and in the data block descriptions. **`make check-gfx`** proves the play-area
formats: it rebuilds the back buffer at `$F000` from each world snapshot's map, map
window, facing, scroll step and cell table, and all 3,810-3,840 bytes match in all
seven worlds; the screen differs only where sprites are drawn.

**Found the hard way (D2):**
- **`tools/annotate.py` had put a new block's start line after the old block's
  sub-blocks,** so D1's start-up block at `$F0C0` kept the old text and data layout
  from `$F10B` on: that part was still disassembled as `DEFM`/`DEFB`, and ten of its
  comments had nowhere to go. No gate could see it (data statements reproduce the
  bytes too). The tool now inserts in address order; re-running all of D1 with it
  changed only `$F10B`-`$F1C8`, which is now code with its comments.
- **Bank addresses leak.** Two bank 1 blocks keyed only by address labelled `$C154`
  and retitled the code block at `$DC54` in the main disassembly; the merge now leaves
  bank blocks to `src/bankN.ctl`.
- **Frame-end screens exaggerate flicker.** A screen taken at the frame interrupt
  shows every sprite missing once a pass; only a model that samples each line when
  the beam reaches it gives what a TV shows (1-3% of frames).
- **`docs/oracle.md` blamed the text printer** for the stray writes into
  `$0000-$3FFF`; `$C237` cannot address below `$4000`. Corrected; the writer is open
  (D5 below).

## D3 - level data

Three analysts (world headers and bank layout, the map, enemy and guardian lists) and
two reviewers (181 items: 126 confirmed, 50 partly right, 5 refuted); merge in
`build/d3/merge.py` with `build/d3/corrections.py`, 18 corrections to D1/D2 text.

**The world banks are fully laid out** (`src/bank3.ctl`, `bank4.ctl`, `bank6.ctl`,
`bank7.ctl`, and bank 1's overflow pieces): two 23-byte headers (every field commented),
the template words, the enemy frames (left-facing first half, right-facing second half),
guardian graphics, the maps, the cell table, the guardian path and record, the world
names, the enemy start lists, the templates and world 7's congratulations message - each
bank packed with no gaps, in the same order.

**`make worlds`** draws every world's whole map from your snapshot into `build/worlds/`;
**`make check-worlds`** proves the map format: each world snapshot's play-area buffer is
rebuilt from the pristine bank data and matches every byte once the map cells and cell
pictures that play changed are copied in. Against a published pixel map of all seven
worlds (Spectrum Computing's `Athena_4.png`, used only for comparison) 93.0-99.8% of
pixels match per part, and 99.2-99.9% outside the cells that map blanks out; the rest is
that map hiding unseen areas and showing sprites.

**Found the hard way (D3):**
- **D2 had the enemy frame halves backwards** (first half faces left), and only 29 of the
  56 second-half frames are exact mirrors; corrected in text and in `tools/extract_gfx.py`.
- **Bank text refers to game code** (`#R$C169`) without `@main`; the tool now links those
  instead of flattening them.
- **A text sub-block has a list of lengths** (`T $FF73,141,17:n2,19:n1,...`); the merge's
  first pattern kept only the first.

## Naming decisions (D3)

| Where | Label | Why |
|---|---|---|
| header bytes 16-17 | RightFramesOffset | the offset leads to the right-facing half |
| bank lists | `W1EnemyList`... `W7EnemyList`, `W12EnemyTemplates`... | the lists analyst's names, whose remit it was |
| `$C169` | `ClearListMarks` | one of two analysts' names |

## Open questions carried forward

Answered by D3 (from the list below it replaced): the world headers; the copies at
`$BE27`-`$BE40` (they give codes `$79`/`$7A` the background picture); the substitute
codes at `$CECA`/`$DE09` (background and item-box blocks); the stale walk by `$C169`
(it damages world 3's cells 90 and 92 and nine bytes of world 7's enemy list); the map
transform at `$BCE6` (it undoes most of play's changes, wasted work); every cell code;
codes `$10`-`$2D` never reach the renderer; the enemy frame halves; which picture each
item code gives (from the pictures - what each item does is D4).

- **D4 (player):** ClimbState values 2 and 4; what up, down and fire do in play; which
  armour piece each of `$BA24`-`$BA26` is; what each item does (and the box rules at
  `$D689`-`$D71E`); the weapon behind each weapon level and the strike set `$D991`
  draws; the pieces at `$6F20`-`$6F9F`; `$D8D6`, `$C091`; the per-world resets at
  `$BD8D`-`$BDAA`; the open left end of world 1's upper part (where would the player
  fall?).
- **D5 (enemies):** enemy types 1-9 and slot bytes 1 and 12 (the movers at `$CB62`-`$CC1A`);
  the order `$C51F` returns slots in; what writes `$FF` and `$FE` into the enemy position
  map; the guardian's cell in that map ignoring the row within a third (`$D53F`); whether
  world 7's type 4 spawn code `$FF` can ever match a cell (a template at `$0000` would
  start); whether world 7's own three-byte list walk can happen in play; **which
  instruction writes into `$0000`-`$3FFF`**.
- **D6 (sound and front end):** why `$ED4E` runs with interrupts off; the 800 bytes
  copied to `$FCE0`-`$FFFF` at start-up; whether tune 11 can be cut short by a key;
  `IN A,($9F)` at `$F240`; why `$C3C0` writes `$FF` to `$BDB3`; define keys at `$F355`;
  the 192 unused bytes at `$6CA0`.
- **Not decidable from the code:** why bank 7's unused second header holds bank 3's
  values; whether the differing second-half enemy frames are retouched art or errors;
  why the box pictures `$C7`/`$C8` are equal in banks 3 and 6 but not 4 and 7; what
  `$C0F1`'s handling of `$00` and `$D4` was for.
- **E8 (hardware):** the flicker rates and the lost interrupt were measured in a replay
  model with estimated contention; the KS3 is the check.
