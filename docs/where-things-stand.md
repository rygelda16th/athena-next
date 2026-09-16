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
| **G1** | the original under ZEsarUX; the recording played to the end | **built, checks green - waiting at checkpoint G1** |
| G2 | code map; byte-identical reassembly; ctl round trip | not started |
| G3 | the original as `athena.nex`; the oracle | not started |
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

## Checkpoint G1 - for David

1. Look at `build/g1/worlds-play.png` (and `sheet.png` if curious): seven worlds,
   the ending, the hi-score table.
2. Play the original: `make play-orig`.
3. Optionally rerun: `make rzx-end && make check-orig`.

**Next, if you say go - G2:** the killing experiment first (does code ever run at
`$C000` from a bank other than 0? The paging log says only five frames per world
load, which is promising), then the code map from `map.txt`, then a byte-identical
reassembly of all eight banks with sjasmplus and a lossless ctl round trip.

## Method notes that carried over

- Every check prints what it compared and exits non-zero on failure; nothing is
  judged by eye that a script can judge.
- Every claim about an instruction is from a disassembly, not from reading hex.
- Shared toolchain files are copies; `make toolchain-diff` reports drift from
  anotherworld-next.
