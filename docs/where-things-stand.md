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
| **G0** | provenance, repository, licence | **built, checks green - waiting at checkpoint G0a** |
| G1 | toolchain; the original under ZEsarUX; the recording played to the end | not started (image already built for G0) |
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

### Open item carried to G1

**Bank 7 +`$341B` is `40` in the snapshot and the recording, `00` in every tape.**
Three unencrypted dumps (Imagine 48K, Erbe, the 48K TAP) and the loaded 128K
tape all say `00`. G1 replays the recording and watches that byte: if the game
writes it, it is state; if not, the WoS dump carries a one-bit flaw and the
oracle has to start from it. Until then it is volatile for G2's comparison.

## Checkpoint G0a - for David

1. Read `docs/provenance.md` and `docs/licence.md`.
2. Confirm or amend the licence split (GPL-3.0-or-later for code and tools,
   CC BY-SA 4.0 for annotations).
3. Optionally rerun: `make fetch && make check-data && make provenance`.

**Checkpoint G0b - before acting:** create the public GitHub repository
(`rygelda16th/athena-next`, SSH) and push. Not done; waiting for a yes.

## Method notes that carried over

- Every check prints what it compared and exits non-zero on failure; nothing is
  judged by eye that a script can judge.
- Every claim about an instruction is from a disassembly, not from reading hex.
- Shared toolchain files are copies; `make toolchain-diff` reports drift from
  anotherworld-next.
