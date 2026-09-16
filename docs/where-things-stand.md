# Where things stand

**This file is canonical.** Where it disagrees with anything else, believe this
one. Last updated 2026-09-16.

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
| **G3** | the original as `athena.nex`; the oracle | **built; see the G3 section for the checks' state** |
| D1-D7 | complete annotated disassembly | not started |
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
| hi-score table | 119,119 | 39.7 | 1 |

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

- **The menu only sees taps.** It waits at `$C2E6` until every key is up before it
  polls the 1-5 row at `$F1E9`, so a held key is never read and a single tap can
  miss the poll. The scripts press three frames, release twelve, and repeat.
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
bytes, with 893 state hashes along the way and the 22 tunes as records of what they
changed), and the check build patches those 23 instructions into calls to a handler
that feeds the values back and checks every hash on the machine.

| Build | Result |
|---|---|
| `athena-oracle-28.nex` (28 MHz) | **PASS** - all 914,021 events, all 893 checkpoints, 316 s at 20x emulator speed |
| `athena-oracle-35.nex` (3.5 MHz) | running at the time of writing; about an hour at 20x |

### Findings that change later work

- **The game's text printer draws into `$0000-$3FFF`** (off-screen text, harmless on
  a Spectrum's ROM). Anything the port ever puts at `$0000-$3FFF` must be
  write-protected - which is why the oracle handler lives in the Next's alternative
  ROM. The enhanced port inherits this constraint.
- **Tunes use their own interrupt routines to run the note timing** (`$DF90`,
  `$DFEF`), and abort loops by discarding return addresses. E1 (pacing) and E5
  (sound) have to treat the tune player as one unit, not patch into its middle.
- **The game overwrites its own menu code** (`$F1E9`-`$F486`) with data during play.
- **ZEsarUX differs from the Next's documentation on NextReg `$8E`** (it remaps
  `$C000-$FFFF` with bit 3 clear); the stub is written to work either way, and the
  KS3 will show which the hardware does.

## Checkpoint G3 - for David

1. **Play the original on the Next:** `make play` (CSpect). It should be
   indistinguishable from the original 128K game - that is the point of this gate.
2. Read `docs/oracle.md`.
3. Optionally rerun: `make g3` (the 3.5 MHz oracle takes about an hour).

**Next, if you say go - D1:** the complete disassembly begins - boot, 128K paging,
the memory map, the main loop and its HALT, both interrupt routines, input
(including the run-time-written control routines), and the R-based randomness,
each annotated in `src/athena.ctl` and checked with `make check-ctl` and
`make check-reasm`.

## Method notes that carried over

- Every check prints what it compared and exits non-zero on failure; nothing is
  judged by eye that a script can judge.
- Every claim about an instruction is from a disassembly, not from reading hex.
- Shared toolchain files are copies; `make toolchain-diff` reports drift from
  anotherworld-next.
