# The disassembly - how it is annotated, and what is still open

Chunks D1-D7 (David's decision: the disassembly is complete before any enhancement).
D1 and D2 established 2026-09-16.

## Where it lives

- **`src/athena.ctl`** (the 64K the game runs in, bank 0 at `$C000`) and
  **`src/bank1.ctl`, `bank3.ctl`, `bank4.ctl`, `bank6.ctl`, `bank7.ctl`** (data banks)
  hold every annotation: block types and boundaries, titles, descriptions,
  register tables, comments and labels. They contain addresses and words, never
  the game's bytes (`make check-ctl` refuses a ctl that holds any).
- **`src/athena.ref`** sets up the HTML: game name, credits, the five data banks
  as "Other code", hex page names.
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

## Open questions carried forward

Answered by D2 (from D1's list): the explosion frames at `$6BA0`; the message printer,
its control codes and the panel routines; the energy bar and its colour operand
(`EnergyColour`, `$BF16`); the lost interrupt inside `$EBFA` (53,575 T-states with
interrupts off, plus an estimated 3,300-4,000 T-states of contention on a 128K: one
interrupt a pass is lost, as in the recording).

- **D3 (level data):** the 23-byte world headers in full; the two 32-byte copies at
  `$BE27`-`$BE40` (they replace the cell pictures for block codes `$79` and `$7A`);
  the substitute block codes at `$CECA` and `$DE09`; the stale RES 7 walk by `$C169`
  at a world change; the map transform at `$BCE6` before a new game; map cell codes
  for walls, ladders and items; whether map codes `$10`-`$2D` can reach the renderer;
  what writes block graphics during play (world 3's live table differs from its bank
  in entries 90 and 92); enemy frame boundaries in stretches never drawn, and whether
  the second half of each bank's enemy graphics mirrors the first; the MapChanges
  record bytes 6-8; which picture each item code gives.
- **D4 (player):** ClimbState values 2 and 4; what up, down and fire do in play;
  which armour piece each of `$BA24`-`$BA26` is; the weapon behind each weapon level
  and the strike set ``$D991`` draws; the pieces at `$6F20`-`$6F9F`; `$D8D6`, `$D64F`,
  `$D660`; `$C091`; the per-world resets at `$BD8D`-`$BDAA`.
- **D5 (enemies):** the order `$C51F` returns enemy slots in; what writes `$FF` and
  `$FE` into the enemy position map; the guardian's cell in that map ignoring the row
  within a third (`$D53F`) - a bug in play or not; the type 4 spawn position's
  apparent off-by-one; **which instruction writes into `$0000`-`$3FFF`** (a write
  trap over passes where a display address steps above the screen, `$C312`, is the
  suggested test).
- **D6 (sound and front end):** why `$ED4E` runs with interrupts off; the 800 bytes
  copied to `$FCE0`-`$FFFF` at start-up; whether tune 11 can be cut short by a key;
  `IN A,($9F)` at `$F240`; why `$C3C0` writes `$FF` to `$BDB3`; define keys at
  `$F355`; the 192 unused bytes at `$6CA0`.
- **E8 (hardware):** the flicker rates and the lost interrupt were measured in a
  replay model with estimated contention; the KS3 is the check.
