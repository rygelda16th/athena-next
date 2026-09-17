# athena-next

An enhanced port of **Athena** (Imagine Software, 1987, ZX Spectrum 128K) to the
ZX Spectrum Next - built from a complete disassembly of the original, verified
against a full playthrough recording, and enhanced one subsystem at a time.

**This repository contains no copy of the original game's code or data.** You supply your own
copy; see `data/README.md` and `docs/licence.md`.

Status: **E7** - the enhanced port plays: the scenery on Layer 2, everything that moves on
hardware sprites with smooth scrolling, the original's beeper sound (or the arcade's music and
effects on the AY chips, from your own arcade set), a pad, an options screen and settings saved
to the SD card, all with the original's game logic proved unchanged against a 40-minute
recording. See `docs/where-things-stand.md`, which is canonical.

## Requirements

- Docker (the whole toolchain runs in a container: SkoolKit 10.1, sjasmplus,
  hdfmonkey, headless ZEsarUX - all pinned)
- python3 on the host (standard library only), curl

## Quick start

```sh
make image        # build the toolchain container
make doctor       # versions, and a Z80N assembly smoke test
make fetch        # download YOUR game files into data/ and verify them
make check-data   # the files are the dump and recording this project measured
make provenance   # the snapshot is the original tape's game
make rzx-end      # play the whole recording: pictures, snapshots, code map
make check-orig   # the original runs in headless ZEsarUX as a 128K
make play-orig    # play it yourself (native ZEsarUX)
make g2           # code map, skool files, ctl round trip, byte-identical rebuild
make g3           # athena.nex, and the recording replayed through it on a Next
make play         # play build/athena.nex in CSpect
make html         # the annotated disassembly as HTML, from YOUR snapshot (never publish it)
make gfx          # PNG sheets of every graphic (build/gfx)
make worlds       # every world's whole map (build/worlds)
make check-gfx check-worlds check-audit   # the play area, the maps, and completeness
```

## The enhanced port

```sh
make nex          # build/athena.nex: the enhanced port from the Spectrum files alone
make e1 e2 e3 e4  # pace, the play area, the sprites, the scroll - each proved against the recording
make e5           # sound: the original's beeper, and (with an arcade set) the arcade's music
make e6           # the pad, the options screen, the levers, the switches, the SD card
make check-levels # all three build levels build and play
```

With your own copy of the arcade game in `data/arcade/athena.zip` (optional, never
committed - see `docs/licence.md`):

```sh
make arcade-assets   # the arcade art and sound, made from YOUR set into build/assets
make nex-arcade      # build/athena-arcade.nex (needs a 2MB Next)
make c2 c3           # the mapping covers the art bible and shows in the game, exactly
make check-arcade-sound
```

Your own hand-made scenery goes in `data/art/` (never committed): `make check-art` checks it
against `docs/art-bible.md` and the next build uses it.

## Layout

| Path | What |
|---|---|
| `docs/where-things-stand.md` | canonical status |
| `docs/provenance.md` | which Athena, and how we know |
| `docs/licence.md` | what is and is never in this repository |
| `docs/coverage.md` | where code runs, and every byte no run executed |
| `docs/oracle.md` | how the port is proved to still be the original game |
| `docs/disassembly.md` | how the disassembly was made, and what is still open |
| `docs/difficulty.md` | why it is hard; the POKEs as they really behave; the levers for the options |
| `docs/design.md` | the enhanced design (Checkpoint A) |
| `docs/art-bible.md` | where every play-area graphic comes from, and what it must cover |
| `docs/plan.md` | every step from Checkpoint A to the finished port |
| `src/next/engine.asm` | the engine: pacing, the interrupt, the services |
| `src/next/render.asm`, `sprites.asm` | the play area on Layer 2; the hardware sprites |
| `src/next/sound.asm`, `options.asm` | classic and arcade sound; the controls and the options |
| `tools/arcade/` | the arcade capture, the art mapping and the sound conversion (your own set) |
| `src/next/` | the Next side: resume stub, oracle handler, top-level source |
| `tools/` | fetch, checks, format readers (standard library Python) |
| `src/` | SkoolKit control files - the disassembly - and (later) new Z80 code |
| `data/` | your game files - never committed |
| `build/` | everything generated - never committed |

Code and tools: GPL-3.0-or-later (`LICENSE`). Annotations and docs:
CC BY-SA 4.0 (`LICENSE-annotations`). Athena is (c) 1987 Imagine Software; the
arcade original is (c) 1986 SNK.
