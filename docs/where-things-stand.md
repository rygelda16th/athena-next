# Where things stand

**This file is canonical.** Where it disagrees with anything else, believe this
one. Last updated 2026-09-17.

---

## The short version

An enhanced port of **Athena** (Imagine Software, 1987, 128K) to the ZX Spectrum
Next. There is no source code, so the 1987 binary is the reference: the game is
disassembled with SkoolKit, rebuilt byte for byte, run as a Next program, and
then enhanced one subsystem at a time, with Rafal's 40-minute playthrough
recording as the oracle that proves the game logic never changed.

| Gate | What | State |
|---|---|---|
| G0 | provenance, repository, licence | **passed** - approved by David 2026-09-16; repository public |
| G1 | the original under ZEsarUX; the recording played to the end | **passed** - David said go 2026-09-16 |
| G2 | code map; byte-identical reassembly; ctl round trip | **passed** - David said go 2026-09-16 |
| G3 | the original as `athena.nex`; the oracle | **passed** - David played it and said go 2026-09-16 |
| D1 | disassembly: boot, paging, memory map, main loop, interrupts, input, randomness | **passed** - David said go 2026-09-16 |
| D2 | disassembly: the renderer; every graphic exported (`make gfx`) | **passed** - David said go 2026-09-16 |
| D3 | disassembly: level data; every world's map drawn (`make worlds`) | **passed** - David said go 2026-09-16 |
| D4 | disassembly: the player; difficulty controls for E6 (`docs/difficulty.md`) | **passed** - David said go 2026-09-17 |
| D5 | disassembly: the enemies, collision, the stray writes | **passed** - David set the goal "finish the disassembly" 2026-09-17 |
| **D6** | disassembly: sound, the front end, every block titled | **annotated, checks green** |
| D7 | completeness gate (`make check-audit`), Bugs/Pokes/Facts pages, pass costs | in progress |
| A | enhancement design and art bible (David decides) | - |
| E1-E8 | enhancements; art track alongside | - |

The approved plan, with every decision and the reasons, is
`~/.claude/plans/i-am-thinking-of-resilient-panda.md`.

## Decisions (David, 2026-09-16)

1. **Disassembly complete first** - every routine and data block annotated,
   local HTML, before any enhancement work.
2. **Enhancements:** colour playfield with flicker-free hardware sprites; smooth
   hardware scrolling and a steady frame rate at the original game speed; better
   sound; switchable gameplay options (difficulty, continues, bug fixes,
   joystick/MD pad) defaulting to the original. Missing arcade worlds are not
   restored.
3. **Art:** new art on the original grid (same sizes and frame counts),
   generated then hand-cleaned. Tech gates run on recoloured original art as
   placeholders, so they never wait for it.
4. **Distribution:** public repository, bring your own game files; no Imagine
   bytes committed or released.
5. **Disassembly home:** public `.ctl` files; `.skool` and HTML regenerated
   locally from the player's snapshot, never hosted.

## G0 - what was built and what it proved

`make fetch` / `make check-data` / `make provenance` / `make doctor` /
`make toolchain-diff`, all green on 2026-09-16.

- **The three game files verify against digests published by the Internet
  Archive and ZXDB**, not against numbers this project chose. Spectrum
  Computing is blocked on the development Mac's network, so `local.mk`
  relays that one download (`FETCH_VIA`); the digest check makes that safe.
- **The snapshot is the original tape's game.** SkoolKit loads Imagine's 128K
  tape (SpeedLock 4, no accelerator misses), runs it five seconds to the same
  instruction, and 131,067 of 131,072 RAM bytes match. No code differs. See
  `docs/provenance.md`.
- **The recording plays our dump:** its embedded snapshot differs from ours in
  85 bytes, all counters, stack and title-screen attributes.
- **First named addresses**, from the POKE sites: lives `$C1EE`, time `$B94D`,
  energy `$BF1B`, megajump count `$B953`, immunity flag `$BA2A`, credits in the
  operand at `$CCB9` (the game modifies its own code there).
- **Toolchain:** `athena-next-tools` = anotherworld-next's image, byte-identical
  from FROM through ZEsarUX (so Docker reused its layers), plus SkoolKit 10.1 from
  its GitHub release tarball checked against GitHub's sha256, with the C simulator
  built. ZRCP will use port 10010 so it cannot collide with the other two projects.

### Open item carried to G1 (answered at G1, below)

**Bank 7 +`$341B` is `40` in the snapshot and the recording, `00` in every tape.**
Three unencrypted dumps (Imagine 48K, Erbe, the 48K TAP) and the loaded 128K
tape all say `00`. G1 replays the recording and watches that byte: if the game
writes it, it is state; if not, the WoS dump carries a one-bit flaw and the
oracle has to start from it. Until then it is volatile for G2's comparison.

## Checkpoint G0 - closed

David said go on 2026-09-16: the licence split stands (GPL-3.0-or-later code,
CC BY-SA 4.0 annotations) and the repository is public at
`github.com/rygelda16th/athena-next` (created as the personal account, pushed
over SSH). Before the first push the G0 commit was amended so that no run of the
game's own bytes is quoted anywhere in the history; `docs/licence.md` now says
precisely what the repository may hold (addresses, what an instruction does,
the value a check expects - what a published POKE list holds).

## G1 - what was built and what it proved

`make rzx-end` / `make check-orig`, both green on 2026-09-16. `make play-orig`
opens the original in the patched native ZEsarUX.

**The recording plays to the end, and the game has SEVEN worlds.** SkoolKit's
own RZX player, with a per-frame probe hooked in where it would draw
(`tools/rzxwalk.py`), plays all 119,655 frames in **13.4 seconds** - 180 times
real time - with no desynchronisation. Each world is loaded by paging another
128K bank in at `$C000` for five frames; nothing else in forty minutes pages:

| World | Loads at frame | Minutes | Bank at `$C000` |
|---|---|---|---|
| 1 | 207 | 0.1 | 3 |
| 2 | 12,983 | 4.3 | 3 |
| 3 | 27,476 | 9.2 | 4 |
| 4 | 41,546 | 13.8 | 4 |
| 5 | 56,078 | 18.7 | 6 |
| 6 | 70,145 | 23.4 | 6 |
| 7 | 85,975 | 28.7 | 7 |
| ending picture | 117,637 | 39.2 | 1 |
| Combat School advert | 119,119 | 39.7 | 1 |

So the level data lives two worlds to a bank (3, 4, 6) with world 7 alone in
bank 7 and the ending in bank 1. The manual and Crash say six worlds, Your
Sinclair said seven; the game's own congratulations text agrees with Your
Sinclair. The score climbs through every world (560 in world 1 to 224,860 in
world 7) and the recording finishes on the hi-score table with Rafal first on
433,790.

What `make rzx-end` leaves in `build/g1/`:
- `worlds-play.png` - each world thirty seconds in, the ending, the hi-scores
  (**the picture to look at**); `sheet.png` - every thirty seconds of the run;
- `world1.z80` ... `world7.z80`, `ending.z80`, `last-frame.z80` - snapshots in
  play, so later gates can start in any world; `worldN-card.png` - each world's
  title card;
- `map.txt` - the 5,566 addresses executed (28 in ROM, none in `$4000-$7FFF`,
  425 in `$8000-$BFFF`, 5,113 in `$C000-$FFFF`), the input to G2's first ctl;
- `variables.tsv`, `changes.tsv`, `paging.tsv`, `worlds.tsv`.

**The original runs in the project's headless ZEsarUX** (`make check-orig`):
loaded as a Spectrum 128K, all eight banks read back over ZRCP equal to the
snapshot outside the title's counters, stack and colour flash, and ZEsarUX's own
screenshot equal to our render in all 49,152 pixels.

**The bank 7 open item, answered as far as G1 can.** Bank 7 +`$341B` is `40`
at the start of the recording and **never changes in forty minutes of play**
(the probe sees values, not writes). So it is not state the game updates: the
dump carries one bit the tape does not. The oracle (G3) starts from the snapshot's `40` because the recording was
made on it; the Next build will use the tape's `00`. Whether the game ever
*reads* that byte - whether the bit shows up as a pixel or changes a decision -
is D2/D3's to find.

### Two things G1 found out the hard way

- **The Spectrum's display file is not 192 consecutive 32-byte lines.** Within
  each 2,048-byte third, character row r is 32 bytes on and pixel line p of it
  is 256 bytes on (`$4000 + 2048*third + 256*p + 32*r + column`) - the ROM's
  CL-ADDR at `$0E9B` builds exactly that address, and SkoolKit and ZEsarUX both
  draw that way. The first renderer assumed consecutive lines and drew every
  screen as shredded stripes, which looked plausible for a "two-colour"
  game until the title screen came out unreadable next to archive.org's
  screenshot. `make check-orig` now compares the renderer with ZEsarUX's own
  screenshot on every run.
- **The native ZEsarUX changes directory at start-up**, so a relative `--snap`
  path fails with "Error opening" while still exiting 0. `make play-orig`
  passes an absolute path.

### What the POKE-named variables turned out to be (first look)

Lives at `$C1EE` is an ASCII digit (`'5'` = 53), and the recording earns two
extra lives and loses three. Time at `$B94D` counts 9 to 0 as one digit of the
clock. The other four change far too often (megajumps 1,906 times, immunity
1,655) to be what the POKE file's names suggest; D4 names them properly.

## Checkpoint G1 - closed

David said go on 2026-09-16.

## G2 - what was built and what it proved

`make g2` - all green on 2026-09-16, 35 seconds end to end. The details, with every
number, are in **`docs/coverage.md`**.

**The disassembly exists, and rebuilds the game exactly.** `src/athena.ctl` (the 64K
view, bank 0 at `$C000`) and `src/bank1.ctl` ... `bank7.ctl` are SkoolKit control files:
addresses, block types and comments, no instructions and no data (`make check-ctl`
proves both that, and that ctl -> skool -> ctl loses nothing). From them and the
player's own snapshot, `make skool` writes the full skool files, and
`make check-reasm` assembles them with sjasmplus into a 128K image **twice** - as
written, and with every instruction labelled and every address SkoolKit can
resolve replaced by its label - and **both reproduce all 131,072 bytes of all eight
banks**. The labelled build's 952 "unreplaced address" warnings are the honest
measure of the disassembly work left.

**Code only ever runs from bank 0** (`make bank-exec`): every frame of the recording
in which another bank was paged was traced instruction by instruction - 129,252
instructions with bank 1, 3, 4, 6 or 7 in, none of them at `$C000` or above. So one
skool file holds all the code and the other banks are data, which is how the
control files are laid out. The replay engine this needed (`tools/rzxsim.py`) ends
the recording in exactly the state SkoolKit's own player does, and is what G3's
oracle will be built on.

**Coverage is the recording plus six scripted runs** (`make scripts`): the original
driven on SkoolKit's C simulator with keys pressed from a schedule - define keys (N
and Y), Kempston, cursor, Sinclair, and a game left alone to its game over. They add
206 addresses the recording never ran. Everything no run executed is accounted for
in `docs/coverage.md`: variables, the message table, the menu text, tables,
graphics-like constant data, the stack, and 2,870 bytes of workspace.

### Two findings that change later plans

- **There is no AY sound in the 128K version.** In forty minutes the recording
  writes the beeper port 368,992 times and the AY ports not once. The planning
  assumption of 128K AY music - and D6's "AY player at `$FB28`" - was wrong: that
  "instruction" is workspace. "Better sound" (E5) therefore has beeper music and
  effects to start from, not AY tunes; that is a Checkpoint A decision.
- **The input routine at `$BA8D` is written at run time** according to the control
  method chosen: its bytes in play differ from the title's, and the cursor and
  Sinclair runs execute parts of it the recording never did. The complete
  disassembly must describe each variant, not the title-time bytes (D1).

### Found the hard way

- **The first key press only closes the credits** (corrected at D1). The title
  waits at `$C2ED` for any key; the menu at `$F1C9` then waits until every key is
  up (`$C2F6`) and polls the 1-5 row at `$F1E9` with no further wait, so a key held
  from the first press is ignored until it is released. The scripts press three
  frames, release twelve, and repeat, which gets past both waits.
- **My own header was wrong by 512 bytes** (`$5B00`-`$765F` is 7,008 bytes, not
  6,496); `make ctl`'s canonical form caught it on the first round trip.

## Checkpoint G2 - closed

David said go on 2026-09-16.

## G3 - what was built and what it proved

`make g3`. The oracle's design, and the four things that went wrong while building
it, are in **`docs/oracle.md`**.

**The original runs as a Next program.** `build/athena.nex` is the game exactly as
check-reasm rebuilt it, plus a resume stub in 16K bank 8 (`src/next/resume.asm`)
that starts it where the snapshot was saved: 48K ROM selected, registers, I and
IM 2 restored, and a last `NEXTREG $8E` that pages bank 0 over the stub itself so
the next fetch lands on the game's own `RET` at `$E985`. `make check-play` runs it
under headless ZEsarUX as a Next (all three banks equal the snapshot outside the
title's moving bytes, interrupts running, the title pixel for pixel), and
`make check-cspect` runs it in CSpect under a probe plugin
(`tools/cspect/athprobe.cs`) with the same result - its screen equals ZEsarUX's
in all 49,152 pixels. **`make play` opens it in CSpect.**

**The oracle replays Rafal's forty minutes through the port.** Replaying key presses
could never have worked: the game reads the R register for randomness, its tunes
are driven by interrupts, and its key-wait loops read the port as fast as the CPU
allows - all of which depend on CPU speed. So `make oracle-stream` records every
value the game took from outside (914,021 port and R reads, compressed to 348,106
bytes, with 893 state hashes along the way and the 22 tunes that finish as records of what they
changed), and the check build patches those 23 instructions into calls to a handler
that feeds the values back and checks every hash on the machine.

| Build | Result |
|---|---|
| `athena-oracle-28.nex` (28 MHz) | **PASS** - all 914,021 events, all 893 checkpoints, 316 s at 20x emulator speed |
| `athena-oracle-35.nex` (3.5 MHz) | **PASS** - all 914,021 events, all 893 checkpoints, 782 s at 20x emulator speed |

### Findings that change later work

- **The game writes into `$0000-$3FFF`** (harmless on a Spectrum's ROM): D5 found
  the two writers - the list-flag walk `$C169` at the first game after loading, and the
  feathered blade's blast drawn above the screen in world 7. Anything the port ever puts at `$0000-$3FFF` must be
  write-protected - which is why the oracle handler lives in the Next's alternative
  ROM. The enhanced port inherits this constraint.
- **Tunes use their own interrupt routines to run the note timing** (`$DF90`,
  `$DFEF`), and abort loops by discarding return addresses. E1 (pacing) and E5
  (sound) have to treat the tune player as one unit, not patch into its middle.
- **The game overwrites its own menu code** (all of `$F001`-`$F4FE`) with data during play.
- **ZEsarUX differs from the Next's documentation on NextReg `$8E`** (it remaps
  `$C000-$FFFF` with bit 3 clear); the stub is written to work either way, and the
  KS3 will show which the hardware does.

## Checkpoint G3 - closed

David ran `make play` (CSpect) on 2026-09-16: "pretty accurate", and "hard as
nails" - which is the original's difficulty, and why the gameplay options (E6)
matter. He said go for D1.

## D1 - what was built and what it proved

`make html`, then open `build/html/athena/index.html`. How the annotation is done,
the naming decisions and the questions carried to later chunks are in
**`docs/disassembly.md`**.

**What is annotated.** 61 of the 399 blocks now have real titles, and between them
129 labels and 507 instruction comments, all in `src/athena.ctl`:

- **Start-up and game flow:** the entry point `$F0C0` (the tape loader's
  `JP $F0C0`), the control menu `$F1C9` and its two code templates, new game
  `$BCE6`/`$BD01`, next world `$BD85`, the world loader `$B8C3`, world set-up
  `$BDC0` with the life start `$BE47`, game over `$C3C0`, the hi-score table
  `$BF6A`, the ending `$B908`.
- **Memory map:** the world area `$7660` and its overflow `$B660`, the IM 2 table
  `$B700`, the stack `$B801`, the variables block `$B949` (every byte named or shown
  to be unused), four constant tables `$BA37`-`$BA8C`, the run-time control routine
  and key table `$BA8D`/`$BAA6`, the control flags `$BAB2`.
- **The main loop** `$C553`, with the pieces it jumps through (`$DAC9`, `$DAD7`,
  `$DAF2`, `$D08C`, `$D333`, `$D38B`), its exits, the pause, abort, time bonus and
  clock.
- **Interrupts:** the vector `$B8B8` and everything that rewrites it, the title
  routine and its colour cycling, the in-game `EI; RETI`, and how the tune player's
  interrupt routines drive note timing.
- **Input and randomness:** every control method, and all eight `LD A,R` sites with
  what each value decides.

Every description and variable meaning was checked by an adversarial reviewer
(292 items, of which 91 needed correcting) before it went in. `make check-ctl` and
`make check-reasm` pass: annotations cannot change the game.

**Structure corrected** (bytes unchanged): the start-up code `$F0C0`-`$F1C8` was
read as text and data (only `$F0C0`-`$F10A` actually became code at D1 - a tool bug
that D2 found and fixed); the item handlers `$DC25`, `$DC31`, `$DC68`, `$DCAA` and the
unused fill routine `$F4AC` were read as data; `$BA43` and `$BA54` were read as
text; and the byte after each of the nine `CALL $C408` is not an instruction but
the sound effect number `$C408` reads (at `$D4F8` the misreading had swallowed the
next three instructions).

### Findings that change later work

- **The game's speed is its main loop's.** One pass is one step of play; a pass
  never takes less than 4 frames and averages 4.32-4.49 per world. The drawing
  routine `$EBFA` runs 53,592 T-states with interrupts off, so about one interrupt
  a pass is lost. The clock ticks every 13 passes (about 54 frames, 1.085 s). E1's
  "original game speed" is this pass rate.
- **Collisions with enemies are read from a map, not from the screen.** Each pass
  writes enemy numbers into a 128-byte map at `$EF80` and checks the player's
  cells there (`$D38B`). D5 still has to confirm there is no screen read, but
  the plan's hidden-buffer fallback looks unlikely to be needed.
- **Scroll geometry:** one scroll step is two pixels; map cells are 16 pixels,
  8 cells a column, with the play area drawn in a 128-line buffer at `$F000` and
  copied to the screen. That fixes the step for E4's hardware scroll.
- **The byte after `CALL $C408` is data.** Any patch that moves or rewrites those
  calls must keep it.
- **Difficulty levers for E6 are simple values:** lives (`$C1EE`, an ASCII digit,
  5), credits (`$CCB9`, three continues, none in world 7), the clock (5:00 per
  world, not reset by a lost life), immunity (200 passes).
- **Tune numbers:** 0-3 world intros (a counter that is never reset), 4-10 start of
  play in worlds 1-7 (again after every lost life), 11 after the hi-score table,
  12 world 7 completed, 13 life lost and game over, 0 again for the ending.

### Found the hard way

- **Three analysts failed 37 times** before the cause was found: each died when
  writing its whole annotation set as one final answer took more than three
  minutes. They now write annotations to files as they go
  (`docs/disassembly.md`).
- **Five of my own earlier statements were wrong, and are corrected:** the
  start-up code, not the tape loader, sets IM 2 and the title vector; frame
  119,119 is a Combat School advert, not the hi-score table; there are 23 tune
  calls, of which 22 finish; play overwrites the whole of `$F001`-`$F4FE`; and
  the menu's tap trap is two waits (the first key only closes the credits), not a
  release wait before every poll.

## Checkpoint D1 - closed

David said go for D2 on 2026-09-16.

## D2 - what was built and what it proved

`make html` (the disassembly), **`make gfx`** (PNG sheets of every graphic, from your
own files, in `build/gfx/index.html`) and **`make check-gfx`** (the gate). The method,
what went wrong and the open questions are in **`docs/disassembly.md`**.

**What is annotated.** 146 of the 358 blocks now have real titles (the count of
blocks fell because dozens of SkoolKit's guessed text and data fragments became whole
routines, tables and messages), with 230 labels and 809 instruction comments:

- **The play area:** the redraw from the map (`$DE96`, `$DDC4`, `$DDFD`), the
  two-pixel scrolls (`$E989`, `$EA4D`), the copy to the screen (`$EBFA`), the cell
  redraw, the back buffer at `$F000`.
- **Sprites:** the player built in its own buffer (`$EDB4`, `$EDD5`, `$ECCB`,
  `$ECE9`), the masked sprite drawers (`$EB11`, `$EB71`, `$EBAF`), the drawing parts of
  the main loop and the guardian.
- **Text and the panel:** the character and message printers with their control
  codes, the large characters, every message as its own text entry, the hi-score
  table, the energy bar, weapon colours and carried items, the screen utilities.
- **Graphics:** `$5B00`-`$765F` split into the bit-reversal table, the player's
  sprite buffer, the font and 29 blocks of graphics (28 sets and one unused), each described and drawn; bank 1 split
  into the world overflow, the ending picture and the Combat School advert.

`make check-ctl` and `make check-reasm` pass. **`make check-gfx`** rebuilds the play
area from each world's map and cell table and matches every buffer byte in all seven
world snapshots.

### Findings that change later work

- **The flicker, explained and measured.** Every pass the play-area copy wipes all
  sprites off the screen; only the player is built off screen and put back at once.
  Everything else (enemies, guardian, explosions, hit effects) is redrawn later in
  the pass, so a TV frame whose beam passes those lines in between shows the sprite
  missing: 1.2-3.2% of TV frames per world, the player never, guardian explosions
  nearly always. Hardware sprites (E3) remove the cause entirely.
- **The copy is timed to the beam.** The game balances the work before the copy
  (matching delays for empty enemy slots and guardian passes) so it starts about
  14,000 T-states after the interrupt, just as the beam reaches the screen (inferred
  from the measured start times). The enhanced port does not need to keep this.
- **Play area geometry for E2/E4:** a 128-line buffer of 32 bytes a line; 15 map
  columns of 8 cells drawn into bytes 1-30, 13 shown (columns 3-28 of the screen);
  one attribute for the whole play area, from the world header; 16x16 cells, 116 per
  world bank (131 in world 7).
- **Every graphic is one of two formats:** plain 1 bit a pixel, or a mask byte before
  each graphic byte; left-facing sprites are mirrored copies (the player's made at start-up
  through the bit-reversal table at `$5B00`; each world's enemies have their
  right-facing frames at a fixed offset, the operand at `$CC7E`, half-way through the
  bank's frame area - only about half of them exact mirrors, D3). This is the grid the new art must fit (art bible).
- **The title graphics exist only in the tape-loaded machine:** the start-up code
  overwrites the ATHENA logo and part of the figure after drawing them, so
  `make gfx` reads them from `make provenance`'s snapshot.

### Found the hard way

- **D1's start-up block was only partly code** (`tools/annotate.py` bug, now fixed;
  re-running all of D1 changed only `$F10B`-`$F1C8`).
- **The G3 claim that the text printer writes into `$0000-$3FFF` was wrong**; the
  constraint stands, the writer is unknown (a D5 question). Corrected in
  `docs/oracle.md` and `src/next/oracle.asm`.
- **Screens taken at the frame interrupt show far more flicker than a TV** - every
  sprite missing once a pass; the measurement had to model the beam.

## Checkpoint D2 - closed

David said go for D3 on 2026-09-16.

## D3 - what was built and what it proved

**`make worlds`** (a picture of every world's whole map, from your own files, in
`build/worlds/`) and **`make check-worlds`** (the gate). Method, open questions and what
went wrong: **`docs/disassembly.md`**.

**What is annotated.** The four world banks are laid out block by block - headers with
every field commented, enemy frames, guardian graphics, maps, cell tables, guardian paths
and records, world names, enemy start lists, templates, world 7's message - and bank 1's
overflow pieces; plus the routines that read the map and the lists (`$C2D9`, `$DB90`,
`$DB56`, `$DB9F`, `$DBAB`, `$DD58`, `$D65E`, `$D603`, `$C190`, `$C0F1`, `$C169`, `$D5D1`,
`$D5E3`, `$D909` and helpers). Across all six ctl files: 237 of 429 blocks titled, 320
labels, 948 instruction comments. `make check-ctl`, `make check-reasm`, `make check-gfx`
and `make check-worlds` pass.

**The map format is proven two ways.** `make check-worlds` rebuilds each world snapshot's
play area from the pristine world data and matches every byte once play's own changes are
put in; and every world's whole map matches a published pixel map of all seven worlds at
93.0-99.8% of pixels per part (99.2-99.9% outside the areas that map blanks out).

### Findings that change later work

- **Two faults in the original, candidates for E6's bug-fix options:**
  - **World 7's enemy list is damaged before it is played.** At every world change the
    game clears the previous world's list flags before installing the new list, so it
    walks world 6's positions over world 7's freshly loaded list: six enemies start 64
    map columns early and three on the wrong side. The same walk damages two of world
    3's cell pictures.
  - **World 7's guardian column is `$FF`**, apparently meant as "never", but the map
    column wraps, so the check still matches, at view columns 255 and 511.
- **Map geometry for E2/E4:** a world's map is columns of 8 cells (334-403 columns in
  worlds 1-6, 598 in world 7); the first 208 columns are the upper part and the rest the
  lower part, one screen height below, with the lower column directly under the upper;
  world 7 is one part. Nothing but walls in the map bounds the player.
- **Every cell code is accounted for** - background, items and their boxes, scenery,
  climbable, breakable blocks with one or two blows, stepping cells - with the table in
  `build/d3/notes.json`; codes `$10`-`$2D` never reach the renderer.
- **Both worlds of a bank share one cell table, guardian and template table**; each world
  has its own map, enemy list, play-area colour, name and header values (spawn code,
  guardian and end columns).

### Found the hard way

- **My D2 wording had the enemy frame halves backwards** (the first half faces left), and
  `make gfx` labelled them wrongly; fixed.
- **The merge dropped all but the first line length of a text sub-block**, and **bank text
  linking to game code lost its links**; both fixed before applying.

## Checkpoint D3 - closed

David said go for D4 on 2026-09-17.

## D4 - what was built and what it proved

Method, naming decisions and open questions: **`docs/disassembly.md`**. What makes the
game hard, the POKE sites as they really behave, and the controls E6 can offer:
**`docs/difficulty.md`**.

**What is annotated.** How the player moves (the movement helpers and the movement
sections of the main loop), all 25 item handlers and the routines around them, the blow,
the flail and the feathered blade, and the self-modified operands they use. Across all
six ctl files: 282 of 429 blocks titled, 371 labels, 1,242 instruction comments. Every
gate passes (`check-ctl`, `check-reasm`, `check-gfx`, `check-worlds`).

**Measured, in scripted runs of the original and replays of the recording** (each
re-checked by a reviewer):

| | |
|---|---|
| Walking | one 2-pixel scroll step a pass (about 0.44 pixels a frame); keys are read only every fourth step, with the player on a cell or on a cell boundary |
| Normal jump | rises 32 lines in 4 passes, no hang |
| High jump (every second jump after item `$60`) | rises 56 lines in 7 passes, hangs 5, 20 passes in the air |
| Falling / gliding / flying up | 8 / 2 / 4 lines a pass |
| Climbing | 4 lines a pass |
| A life with no armour, standing still in world 1 | about 8-14 seconds of enemy contact |
| Blows with fire held | every second pass (kinds 1-5); a flail throw every 35 frames |
| Guardians | destroyed at 80 damage; each pass a blow reaches one adds the weapon level, so the kick never harms it |

### Findings that change later work

- **Four published POKEs misbehave in this version** - the continues POKE of 0 ends the
  game at once (OR A is the working value), "infinite continues" only freezes the
  countdown, the time POKE makes a poison drain ten times faster, and the energy POKE
  lets the bar overwrite the font and the player graphics. E6 must use the controls in
  `docs/difficulty.md`, not the POKE list.
- **The item table is complete**: 25 items, what each does, which are carried, and every
  item-box rule (all 73 boxes opened in the recording matched). The weapons by level:
  kick, club, war hammer, flail, dagger, broad sword, feathered blade; a weapon item sets
  its own level, so picking up a weaker weapon lowers it.
- **Why the start feels unfair**: a standing blow reaches only the upper of the player's
  two map rows, while world 1's first enemies walk in the lower row, and the starting
  kick cannot strike from a crouch.
- **World 7's first guardian came back** in the recording: destroyed three times before
  the final guardian led to the ending.
- **The player's screen address does leave the screen** (628 times in the recording,
  mostly flying at the top) but is only read until `$CD36` puts it back - so it is not
  the stray writer into `$0000-$3FFF` (still a D5 question).

### Found the hard way

- **The two reviewers contradicted each other** on whether the held weapon strikes the
  cells beside the player without fire; the disassembly settled it (only on the pass a
  blow starts).
- **Two analysts named the same weapons differently** (sword / broad sword, spiked /
  war hammer); the names taken are the ones that match the item pictures D3 read.

## Checkpoint D4 - closed

David said go for D5 on 2026-09-17.

## D5 - what was built and what it proved

Method and open questions: **`docs/disassembly.md`**; the new faults for E6's options:
**`docs/difficulty.md`**.

**What is annotated.** The enemy mover, the slot-list picker `$C51F`, the complete enemy
slot, the cell animation, the contact and heart tests, the heart release, the enemy
position map build, and the sprite drawers' behaviour above the screen. Across all six ctl
files: 283 of 429 blocks titled, 372 labels, 1,378 instruction comments. Every gate
passes.

**Two of the plan's named risks are closed, by logging every memory read and write over
the whole recording** (an instrumented copy of SkoolKit's C simulator, all 119,655
frames):

- **Collision never reads the screen.** Every collision - player and enemies, weapon and
  enemies, player and scenery, items, hearts - is a lookup in the enemy position map or
  the world map, in cells two character columns by two rows. The only non-drawing screen
  read checks the HIT bar's colour before flashing the POW label. **The plan's
  hidden-buffer fallback is not needed: E2-E4 can replace the renderer outright.**
- **The writers into `$0000-$3FFF` are known** (1,768 writes): the list-flag walk
  `$C169` at the first game after loading (list address and count still 0, so it clears
  bit 7 of every third byte of `$0001-$02FE` - the change that broke the first oracle
  handler), and the feathered blade's blast drawn above the top of the screen in world 7
  (`$384C-$3FF5`). A broad sword shot striking a rising heart could also write there (shown
  in a controlled run, never in the recording). **The port must keep `$0000-$3FFF`
  write-protected** unless all three are fixed.

### Findings that change later work

- **Enemies:** types 6 and 7 fly one column a pass through everything; types 1-5, 8 and 9
  walk one column every second pass, turning at walls and ledges; type 4 walks off ledges
  and falls. An enemy's column is a screen column - scrolling never moves it. Five slots,
  topmost enemy drawn first.
- **Most list enemies never appear**: 721 of 851 list starts were started at a screen
  edge over a ledge, stepped back out of bounds and freed in the same pass - and started
  again, invisibly, every pass.
- **Two more faults for E6's bug-fix options**: the guardian's hit area ignores its row
  in worlds 3-7 (blows and contact land where no guardian is drawn), and guardian damage
  carries into the next guardian.

### Found the hard way

- **The first answers to "who writes below `$4000`" were guesses** (the text printer at
  G3, a struck heart at D5's start); only logging every write over the whole recording
  settled it.
- **The review caught what both analysts missed** (the invisible list starts), which
  changed several of their counts.

## Checkpoint D5 - closed

David set the goal "finish the disassembly" on 2026-09-17, so D6 and D7 run on without
stopping at their checkpoints; D7 ends with one checkpoint for the finished disassembly.

## D6 - what was built and what it proved

Method and what went wrong: **`docs/disassembly.md`**.

**Every block is titled.** The tone generator, the tune and effect-list commands and
tables, all 14 tunes and their effect lists, the sound effects, the hi-score code, define
keys, the panel graphics and the workspace areas. Across all six ctl files: 355 of 355
blocks titled, 455 labels, 1,624 instruction comments. Every gate passes.

**The tunes are decoded and proven**: all 14 decode into notes (pitch 3,546,900 /
(48 x BC + 92) Hz, lengths in interrupts), and an independent decoder matches all 23 tune
calls in the recording frame by frame. The sound is two out-of-step square-wave
oscillators on the beeper, which narrows each note's pulse as it sounds - the basis for
E5's "better sound".

### Findings that change later work

- **E5 (sound):** the tunes are Martin Galway's (credits picture), one voice of two
  detuned oscillators with effect lists (sweeps) laid over; tune data is compact and
  fully decodable, so re-voicing them for the Next's AY chips can work from the decoded
  notes. Sound effects are 13 table entries, 8 of them used.
- **The game reads the Multiface One's page-in port** in the title colour cycler; nothing
  uses the value.

## Method notes that carried over

- Every check prints what it compared and exits non-zero on failure; nothing is
  judged by eye that a script can judge.
- Every claim about an instruction is from a disassembly, not from reading hex.
- Shared toolchain files are copies; `make toolchain-diff` reports drift from
  anotherworld-next.
