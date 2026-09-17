# The disassembly - how it is annotated, and what is still open

Chunks D1-D7 (David's decision: the disassembly is complete before any enhancement).
D1-D3 established 2026-09-16, D4-D7 2026-09-17. **The disassembly is complete.**

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

## D4 - the player

Three analysts (movement, items, combat with energy and lives) and two reviewers (196
items: 143 confirmed, 44 partly right, 4 refuted, 5 unverified); merge in
`build/d4/merge.py` with `build/d4/corrections.py`, 19 corrections to D1-D3 text. The
analysts measured with scripted runs of the original (`tools/scriptplay.py`) and
replays of the recording, and the reviewers re-ran at least three measurements each.

**Annotated:** the movement helpers (`$DD06`, `$DD12`, `$DD1E`, `$DD29`, `$DD9C`,
`$C400`, `$DAA7`) and the movement sections of the main loop; all 25 item handlers and
the routines around them (`$C141`, `$C178`, `$C1AA`, `$C1B2`, `$DDA2`, `$DDAE`); the
blow (`$D77A`), the flail (`$D923`, `$D986`), the feathered blade's blast (`$D991`,
`$DA9E`); and the self-modified operands they use. **`docs/difficulty.md`** has the POKE
sites as they really behave and the controls E6 can offer.

**Found the hard way (D4):**
- **The two reviewers disagreed** about whether the weapon strikes the map cells beside
  the player without fire; the disassembly settled it (`$D38B` is reached only by the
  jump at `$D2D9`, after the attack tests): only on the pass a blow starts.
- **Four published POKEs misbehave** in this version (`docs/difficulty.md`): the
  continues POKE of 0 ends the game at once, the "infinite continues" POKE only freezes
  the countdown, the time POKE speeds up the poison drain tenfold, and the energy POKE
  lets the bar overwrite the font and player graphics.

## Naming decisions (D4)

| Where | Label or name | Why |
|---|---|---|
| weapon kinds 1-7 | broad sword, dagger, club, war hammer, kick, feathered blade, flail | from the graphics and the items that give them (the combat analyst; the items analyst's "sword", "light blade", "spiked hammer" dropped) |
| `$C91F` | `JumpCountSwitch` | an opcode switched from NOP to INC (HL) by item `$60` |
| `$D38C`, `$D504`, `$C95B` | `WeaponCellBlows`, `ContactCount`, `AttackFlag` | one analyst's entry each, with the reviews' corrections |
| `$BA24`-`$BA26` | ArmourA (a piece at the body's right edge, item `$74`), ArmourB (body, `$75`), ArmourC (helmet, `$76`) | from the pictures and the handlers |

## D5 - the enemies

Three analysts (movers and slots, spawns and guardians, collision and the stray writer)
and two reviewers (98 items: 61 confirmed, 34 partly right, 1 refuted, 2 unverified);
merge in `build/d5/merge.py` with `build/d5/corrections.py`, 10 corrections to D1-D4
text. The collision analyst instrumented a copy of SkoolKit's C simulator to log every
memory read and write, and replayed all 119,655 frames of the recording on it.

**Annotated:** the enemy mover in the main loop (`$CB02`-`$CC45`), the slot-list picker
`$C51F` (topmost enemy first), the cell animation (`$C606`-`$C63B`), the contact and
heart tests in `$D38B`, the heart release `$D8D6`, the enemy position map build in
`$D08C`, the sprite drawers' pushes above the screen, and the complete 13-byte enemy slot
in the EnemySlots description.

**Found the hard way (D5):**
- **The review found what both analysts missed:** most list starts are freed in the pass
  they start (721 of 851), which also explained the high list-start counts in worlds 3
  and 5 that the analysts had put down to the player's route.
- **Slot byte 0 is not always a template high byte** - for a type 4 start it is the
  start column until the first mover pass.

## D6 - sound, the front end, and everything left

Three analysts (tunes, sound effects and front end, workspace) and two reviewers (152
items: 112 confirmed, 32 partly right, 6 refuted, 2 unverified); merge in
`build/d6/merge.py` with `build/d6/corrections.py`, 23 corrections to earlier text.
**After D6 every one of the 355 blocks in the six ctl files has a real title.**

**Annotated:** the tone generator `$DF5A`, the tune and effect-list commands, the pitch,
tune and dispatch tables and the player's workspace, and every tune and effect list
laid out in `$E16A`-`$E976`; the sound effect player `$C408` and its table; the hi-score
code `$C015`/`$C074` and table; define keys `$F355` and its texts; the panel graphics; and
the workspace areas (`$EE03`-`$EFFF`: the weapon graphics copy and the enemy position map;
`$F4C6`-`$FFFF`: the loaded copies start-up moves, the title graphics, and the copy of the
tape loader's stack that start-up puts over them).

**Proof:** a tune decoder (`build/d6/tunes`, and the reviewer's independent one) turns
all 14 tunes into notes - pitch 3,546,900 / (48 x BC + 92) Hz, lengths in interrupts -
and matches all 23 tune calls in the recording frame by frame.

**Found the hard way (D6):**
- **`tools/annotate.py` threw away published sub-block comments and labels** when it laid
  out new variables in a block that already had some (D1's three tune effect variables).
  The tool now keeps them; re-applied from the saved ctl, nothing was lost.
- **The tunes analyst's model counted looping tunes twice**; the reviewer's decoder fixed
  the intro tune lengths (tune 0: 1,792 interrupts a pass, not about 3,500).
- **D2's weapon graphics were named from the pictures alone** (club, sword, mace, axe);
  they are now named from the items that give them (broad sword, dagger, club, war
  hammer, kick, feathered blade, flail), which D4 established and the weapon table and
  pictures agree with.

## D7 - the completeness gate

**`make check-audit`** (`tools/disasm_audit.py`) checks the main program and every bank:
every block has a real title and a description; every unused block says why; every
instruction that code outside its block jumps to or calls is marked; every address the
code reads or writes by absolute address is explained (a label, a commented statement, or
named in its block's text); and every instruction whose operand the code rewrites carries
a comment. It passes: 355 blocks, 388 labels in the main program and 67 in the banks,
1,633 instruction comments.

D7 also added the **Bugs, Pokes and Trivia pages** to the HTML (`src/athena.ref`, from the
reviewed findings of D3-D6), and measured **what a pass of the main loop costs**
(`build/d7/costs.py`, from the recording):

| Stage (world 2, 59 passes) | T-states | |
|---|---|---|
| move the player, including the two-pixel buffer scroll or the delay that matches it | 151,723 | 53% |
| copy the play area to the screen (interrupts off) | 53,592 | 19% |
| wait for the frame (HALT) | 32,386 | 11% |
| build the player's sprite | 15,289 | 5% |
| enemy position map, immunity | 11,021 | 4% |
| draw weapons, enemies, effects | 9,287 | 3% |
| read controls, start enemies | 4,112 | 1% |
| everything else (enemy moves, clock, end checks, loop tail, player to screen) | about 9,000 | 3% |
| **a pass** | **286,327 (4.04 frames)** | |

World 7 is the same shape (300,561 T-states, 4.24 frames). **The game logic is a small
part of a pass; the scroll and the copy dominate** - which hardware scrolling (E4) removes.

**Found the hard way (D7):** replacing a block's header dropped its existing label when
the new annotation gave none (`WorldArea`); the tool now keeps it, and a check of every
tag shows no label was ever lost in D1-D6.

## Open questions carried forward

Answered by D6: tune 11 can be cut short by a key; `IN A,($9F)` is the Multiface One's
page-in port (and answered by partially decoded Kempston interfaces), unused by the game;
the `$FF` written to `$BDB3` at a game ending in world 3 or later is a mark that worlds 1
and 2 are gone, never read; the 800 bytes at `$FCE0` are a copy of the tape loader's stack
area that nothing reads; `$6CA0` is never read.

- **Checkpoint A / E6:** whether a fall through an open bottom cell of a lower part, or a
  part change in world 7, can happen; whether the wrong-cell wall test after a rise off
  the top ever mattered; the high jump's hang and the fall lookahead - design or accident;
  walking back over a destroyed world 7 guardian's start position.
- **Not decidable from the code:** why the game reads the Multiface port; why bank 7's
  unused second header holds bank 3's values; whether the differing enemy frames are
  retouched art or errors; why the box pictures `$C7`/`$C8` differ between banks; what
  `$C0F1`'s handling of `$00` and `$D4` was for; what ArmourA's piece and item `$77`'s
  picture show; the creatures' names; why pitch table entry 40 is off the scale; why
  `$ED4E` runs with interrupts off.
- **E8 (hardware):** the flicker rates and the lost interrupt were measured in a replay
  model with estimated contention; the KS3 is the check.
