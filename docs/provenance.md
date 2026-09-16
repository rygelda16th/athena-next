# Provenance - which Athena this project is built on, and how we know

Gate G0. Reproduce with `make fetch`, `make check-data`, `make provenance`.
Established 2026-09-16.

## The short version

Everything in this project is measured against **one 128K snapshot and one
recording made from it**, and both are now tied to Imagine's original tape:

- `data/athena128.z80` is the World of Spectrum dump `ATHEN128.Z80`. Loading
  **Imagine's original 128K tape** (SpeedLock 4) in SkoolKit's simulator and
  letting the game run to the same instruction reproduces it in **131,067 of
  131,072 RAM bytes**. The five that differ are two counters, a stack byte, a
  ROM keyboard variable and one bit in bank 7 (below). **No code differs: the
  snapshot is not a crack.**
- `data/athena.rzx` is Rafal's playthrough, recorded in Spectaculator, **one
  input block of 119,654 frames (39.9 minutes)**. Its embedded snapshot differs
  from `athena128.z80` in **85 bytes**: the same two counters, two stack bytes
  and 80 attribute bytes of the title screen's colour flash. The recording plays
  our dump.

## The files, and who vouches for them

Nothing here is committed; `tools/fetch.py` downloads each file and checks it
against digests published by someone other than this project.

| data/ | Source | Size | Verified against |
|---|---|---|---|
| `athena128.z80` | archive.org `zx_Athena_1987_Imagine_Software_a_128K` | 108,395 | md5 `93d7ca3c...4e4e` (archive.org item metadata; ZXDB for `Athena128.z80.zip/ATHEN128.Z80`), sha512 (ZXDB) |
| `athena.rzx` | archive.org `rzxarchive/athena.rzx` (RZX Archive) | 240,835 | md5 `6b85f1d4...9664`, sha1 (archive.org item metadata) |
| `athena128.tzx` | Spectrum Computing `Athena.tzx.zip`, member `Athena - 128k.tzx` | 124,186 | md5 `a82fe06b...b425`, sha512 (ZXDB; origin "Original release", SpeedLock 4) |

ZXDB marks Athena **"Availability: Available"**. The archive.org item's `[a]`
tag is an old TOSEC name; TOSEC 2023 calls the same file
`Athena (1987)(Imagine)(128K).z80`.

## What the snapshot is

`make check-data` asserts all of this:

- .z80 version 3, hardware mode 4 (128K), all eight RAM banks present.
- Saved on the first instruction of the IM 2 handler: PC `$B8B8`, SP `$B8B1`,
  I `$B7`, IM 2, interrupts off. `$7FFD` = `$10`: bank 0 at `$C000`, 48K ROM.
- The eight places the published 128K POKEs patch hold the instructions they
  replace. Disassembled with SkoolKit:

  | POKE | Address | Instruction there |
  |---|---|---|
  | infinite lives | `$CCAD` | `DEC (HL)` after `LD HL,$C1EE` |
  | infinite credits | `$CCBA` | `DEC A` after `LD A,$00` - the count is that operand, `$CCB9` (self-modifying) |
  | infinite continues | `$CCED` | `DEC A` after `LD A,B` |
  | megajumps | `$C76C` | `DEC A` before `LD ($B953),A` |
  | infinite time | `$DAF4` | high byte of `LD HL,$B94D` before `DEC (HL)` |
  | infinite energy | `$BF10` | `DEC (HL)` after `LD HL,$BF1B` |
  | immunity | `$D4F2` | `JP NZ,$C553` after `LD A,($BA2A) / OR A` |
  | keep objects | `$CD13` | `JR Z,$CD23` |

  These are the first named addresses of the disassembly: lives `$C1EE`, time
  `$B94D`, energy `$BF1B`, megajump count `$B953`, immunity flag `$BA2A`.

## The tape comparison (`make provenance`)

1. `tap2sna.py -c machine=128` loads `athena128.tzx`. The SpeedLock accelerator
   handles the whole tape with no misses; the simulation stops at the end of
   the tape with the loader at `$8913`.
2. `trace.py` runs the loaded machine for five seconds of emulated time
   (17,727,000 T-states, 250 frames), then on to the next `$B8B8`.
3. All 131,072 RAM bytes are compared with `athena128.z80`:

| Where | Snapshot | Tape | What |
|---|---|---|---|
| bank 0 +`$3253` = `$F253` | `47` | `44` | counter (the RZX differs here too) |
| bank 0 +`$32A6` = `$F2A6` | `A9` | `A7` | counter (the RZX differs here too) |
| bank 2 +`$38B1` = `$B8B1` | `E5` | `EA` | stack, just below SP |
| bank 5 +`$1C06` = `$5C06` | `21` | `23` | KSTATE, the ROM's keyboard state |
| bank 7 +`$341B` | `40` | `00` | **one bit** inside what looks like 1-bit graphics |

Run for 20 or 60 seconds instead and the set changes only by the title's colour
flash, the stack and counters (`$F244` joins at 60 s); the bank 7 bit differs
at all three.

## The one open item: bit 6 of bank 7 +`$341B`

The 11 bytes before it and the 12 after it appear as plain bytes in three other
dumps (the search is a one-off and not repeated here, so the bytes themselves
are not quoted), and all three have **`00`** in its place:

| Dump | Offset in file | Byte |
|---|---|---|
| Imagine `Athena - 48k.tzx` | 105,412 | `00` |
| Erbe re-release `Athena - Side 1 (Erbe).tzx` | 102,981 | `00` |
| `ATHENA.TAP` (48K) | 99,717 | `00` |

Neither 128K tape holds the sequence as plain bytes (their blocks load through
SpeedLock's loader), so the raw search finds nothing there, but loading the
Imagine 128K tape also gives `00`. So **`00` is what shipped**, and
the snapshot plus the recording made from it carry one extra bit. Two
explanations, and G1 can tell them apart when it replays the recording:

- **The game writes it at run time** (the snapshot was taken after some play,
  and that block is state - a map or collected-item bitmap rather than
  graphics). Then it is ordinary state and the rebuild uses the tape's `00`.
- **The dump is corrupt by one bit.** Then the recording was made on a machine
  with a one-pixel flaw and the oracle must start from the snapshot's `40`.

Until G1 settles it, the byte is treated as volatile: the byte-identical
reassembly at G2 excludes it, and the value we build with is decided then.

## Why this matters for the rest of the plan

- The RZX is a valid reference for the **original game**, not a modified one.
- Byte-identical reassembly (G2) compares against the snapshot, and the snapshot
  is the tape's game.
- The 48K build is a separate, shifted assembly (every POKE address is +784 to
  +941 bytes away in 128K) and is out of scope.
