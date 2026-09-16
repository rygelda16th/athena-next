# athena-next

An enhanced port of **Athena** (Imagine Software, 1987, ZX Spectrum 128K) to the
ZX Spectrum Next - built from a complete disassembly of the original, verified
against a full playthrough recording, and enhanced one subsystem at a time.

**This repository contains no copy of the original game's code or data.** You supply your own
copy; see `data/README.md` and `docs/licence.md`.

Status: **G0** (provenance) - see `docs/where-things-stand.md`, which is canonical.

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
```

## Layout

| Path | What |
|---|---|
| `docs/where-things-stand.md` | canonical status |
| `docs/provenance.md` | which Athena, and how we know |
| `docs/licence.md` | what is and is never in this repository |
| `tools/` | fetch, checks, format readers (standard library Python) |
| `src/` | SkoolKit control files (from G2) and new Z80 code |
| `data/` | your game files - never committed |
| `build/` | everything generated - never committed |

Code and tools: GPL-3.0-or-later (`LICENSE`). Annotations and docs:
CC BY-SA 4.0 (`LICENSE-annotations`). Athena is (c) 1987 Imagine Software; the
arcade original is (c) 1986 SNK.
