# The disassembly - how it is annotated, and what is still open

Chunks D1-D7 (David's decision: the disassembly is complete before any enhancement).
D1 established 2026-09-16.

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

## Carried from D1 to later chunks

Questions D1's analysts could not settle, with the chunk they belong to:

- **D2 (renderer):** whether interrupts lost inside the long DI drawing routine
  `$EBFA` behave the same on hardware as in the replay model; why `$ED4E` runs
  with interrupts off; the four 64-byte sprites at `$6BA0` drawn over a damaged
  guardian; the message printer `$C292` and its control codes, `$C28C`, `$C284`,
  `$C3A5`, `$C1BF`; how the energy bar is drawn, and its colour operand `$BF16`.
- **D3 (level data):** the 23-byte world header; the two 32-byte copies at
  `$BE27`-`$BE40`; the substitute block codes at `$CECA` and `$DE09`; what the
  stale RES 7 walk by `$C169` at a world change does to the new world's data;
  the map transform at `$BCE6` before a new game (no lasting effect found); map
  cell codes for walls, ladders and items (`$79`, `$7A`, `$7F`, `$80`, `$98`,
  `$B2`); the MapChanges record bytes 6-8.
- **D4 (player):** ClimbState values 2 and 4; what up, down and fire do in play;
  which armour piece each of `$BA24`-`$BA26` is; the weapon behind each weapon
  level; `$D8D6`, `$D64F`, `$D660` (run while `$D38C` is set); `$C091`; the
  per-world resets at `$BD8D`-`$BDAA`.
- **D5 (enemies):** the order `$C51F` returns enemy slots in; what writes `$FF`
  and `$FE` into the enemy position map; the sprites of enemy types 4, 6 and 7;
  whether the unguarded end of the `$D08C` PUSH clear ever corrupts
  `$EF7E`-`$EF7F`; the type 4 spawn position's apparent off-by-one.
- **D6 (sound and front end):** the 800 bytes copied to `$FCE0`-`$FFFF` at
  start-up (corrupting them changed nothing in the recording); whether tune 11
  can be cut short by a key; `IN A,($9F)` at `$F240`; why `$C3C0` writes `$FF` to
  `$BDB3` (no effect found); the hi-score table at `$BBDB` and the message texts
  at `$BB18`-`$BC90`; define keys at `$F355`.
