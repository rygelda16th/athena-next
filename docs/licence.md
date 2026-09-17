# Licence, and what is never in this repository

**Status: confirmed by David at checkpoint G0 (2026-09-16).**

## The rule this project lives by

Athena is Imagine Software's 1987 conversion of SNK's 1986 arcade game. Its
code is Andrew Deakin's, its graphics Ivan Horn's, its music Martin Galway's,
and the rights passed from Imagine to Ocean to Infogrames/Atari; the licence to
make it was SNK's. ZXDB lists the original as "Availability: Available", which
covers archiving and downloading the original file. **It does not cover a
modified version**, so:

**No copy of Imagine's game - its code or its data, in any form - is committed
to, or released from, this project.**
The player supplies their own copy (`make fetch` downloads it and checks it
against published digests). Everything derived from it - snapshots, generated
`.skool` and `.asm`, the HTML disassembly, the rebuilt `.nex`, traces, page
dumps, extracted graphics - is a build product under `build/` or `work/` and is
gitignored.

What the repository does contain is what a published POKE list contains:
addresses, what the instruction at an address does, the value a check expects to
find there. The annotations (`src/*.ctl`), the checks under `tools/` and the
enhanced port's own code (`src/next/`) are made of that - they name and describe the
game, and are useless without it. The port's hooks list the bytes each patched site
holds before it is patched (`tools/nexpatches.py`, and the bug fixes' three-byte
sites in `src/next/options.asm`), exactly as a POKE list does, so a check can prove
the running game differs from the player's own file at those addresses and nowhere
else. The arcade mapping and the sound cues (`tools/arcade/*.json`) are numbers in
the same sense: tile numbers, colour sets, offsets and the sound program's command
numbers, with no picture or sound of SNK's.

This is the same discipline wolf3d-next and anotherworld-next follow: those
repositories contain no id Software or Delphine data, and the player's own game
files are read at build time.

## What IS in the repository, and under which licence

| What | Licence | Why |
|---|---|---|
| New code: Z80 sources written for the port, `tools/`, Makefile, Dockerfile | **GPL-3.0-or-later** (`LICENSE`) | SkoolKit is GPL-3.0-or-later, and any SkoolKit extension module this project writes (for custom skool macros) imports it, so it has to be compatible; one licence for all new code keeps that simple. |
| Annotations: `src/*.ctl` (labels, comments, block descriptions) and `docs/` | **CC BY-SA 4.0** (`LICENSE-annotations`) | The same choice Richard Dymond made for his SkoolKit disassemblies (CC BY-SA 3.0 for the annotation text), updated to 4.0. |

Both texts were fetched from gnu.org and creativecommons.org, not typed.

### Why control files and not skool files

A `.skool` file contains every instruction of the game, so it is Imagine's code
with comments added. A SkoolKit **control file** (`.ctl`) holds only addresses,
block types, labels and comments - no instructions and no data bytes.
`sna2skool.py -c athena.ctl athena128.z80` regenerates the full `.skool` from
the player's own snapshot, and `make check-ctl` (G2) proves the round trip
loses nothing. That is how "complete disassembly, published" and "no Imagine
bytes" are both true at once.

The HTML disassembly is built locally and **never hosted**, because it shows
every instruction.

## The arcade game's sound and graphics (decided at Checkpoint A, 2026-09-17)

The enhanced port converts SNK's 1986 arcade music and sound effects onto the Next's
AY chips, and uses the arcade's own character art (player, weapons, items, effects,
enemies, guardians). SNK Corporation owns all of it. The same rule applies:

- **The player supplies their own copy of the arcade game, and it is optional.** The
  build uses 9 files (the sound program, the sprite and background graphics, the
  colour PROMs), identical in MAME's `athena`, `athenab` and `sathena` sets; David's
  came from the Steam SNK 40th Anniversary Collection, extracted with community
  scripts. Whether that extraction is lawful depends on the country; the choice is the
  player's. Without the files the build still works, with classic sound and recoloured
  Spectrum art.
- The files go in `data/arcade/` and are checked against MAME's published checksums.
  **They, the logs captured from them, and every picture and tune converted from them
  are build products, never committed or released.**
- The repository holds only what a POKE list would: tile numbers, colour set numbers,
  offsets and frame timings for the art; command numbers and conversion rules for the
  sound, including an instrument table keyed by a hash of each FM patch, as
  wolf3d-next's MIDI table is. None of it contains SNK's pixels or notes.
- **Hand-made art** (David's coloured versions of Ivan Horn's shapes, for the scenery
  and any enemy the arcade lacks) lives in `data/art/`, which git ignores, until David
  decides at its first delivery whether it may be published.

## Decided later, not here

- **Hand-made art.** David's coloured versions of Ivan Horn's shapes are derived from
  Imagine's art. Whether they go in this repository, and under what terms, is decided
  at their first delivery.
- **A playable release.** A public `.nex` would contain Imagine's code. That
  needs the rights holders' permission and is out of scope unless David decides
  otherwise.

## Third-party tools

Used, not vendored: SkoolKit 10.1 (GPL-3.0-or-later, pinned by sha256),
sjasmplus, hdfmonkey and ZEsarUX (pinned commits, three local ZEsarUX patches
from wolf3d-next), all fetched and built inside the container.
