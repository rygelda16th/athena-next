#!/usr/bin/env python3
"""Gate G2: write the FIRST control files. Run once; after that src/*.ctl are the
disassembly and are edited (through `make skool` / `make ctl`), never regenerated.

    make ctl-bootstrap        (refuses to overwrite existing src/*.ctl)

src/athena.ctl covers the 64K the game runs in, bank 0 at $C000:
- $4000-$B6B4 is laid out from what G1 established (nothing executes there in
  the whole recording): display file, attributes, system variables, the world
  area the loader at $B8C3 fills from a world bank, and the world settings it
  copies from bank 1;
- $B6B5-$FFFF is SkoolKit's own reading (sna2ctl.py) of the merged code
  map, build/g2/map-all.txt: every address executed by the recording or by the
  scripted runs in tools/scripts/ is code.

src/bank1.ctl, bank3.ctl, bank4.ctl, bank6.ctl, bank7.ctl describe the other
banks as data at $C000, where they are paged when the loader copies them.
"""

import os
import subprocess
import sys

SPLIT = 0xB6B5

HEAD = """\
; Athena (Imagine Software, 1987), ZX Spectrum 128K - the 64K the game runs in,
; with bank 0 paged at $C000. Control file for SkoolKit 10.1.
; Annotations CC BY-SA 4.0; see docs/licence.md. Build with `make skool`.
@ $4000 start
@ $4000 org
b $4000 Display file
D $4000 The screen at the moment the snapshot was saved: the title's credits page.
B $4000,6144,32
b $5800 Attribute file
B $5800,768,32
b $5B00 System variables and workspace
D $5B00 Not examined yet. Nothing in this range executes during the recording.
B $5B00,6496,16
b $7660 World area
D $7660 The loader at #R$B8C3 copies the whole of the current world's bank here (16,384 bytes, #R$7660 to #R$B65F). In the snapshot, taken at the title screen before any world was loaded, it still holds what the tape loader left behind.
B $7660,16384,16
b $B660 World settings
D $B660 85 bytes the loader at #R$B8C3 copies from bank 1 for the current world.
B $B660,85,16
"""

BANK = """\
; Athena (Imagine Software, 1987), ZX Spectrum 128K - RAM bank {n}, as paged at
; $C000. Control file for SkoolKit 10.1. Annotations CC BY-SA 4.0.
@ $C000 start
@ $C000 org
b $C000 {title}
D $C000 {desc}
B $C000,16384,16
"""

BANKS = {
    1: ("Bank 1: the ending, the hi-score screen and the world settings",
        "Paged by #R$B8C3 for every world load (85 bytes of world settings), by #R$B908 for the ending picture and by #R$B929 for the hi-score screen."),
    3: ("Bank 3: worlds 1 and 2",
        "Copied whole to the world area at $7660 by #R$B8C3 when world 1 or 2 starts."),
    4: ("Bank 4: worlds 3 and 4",
        "Copied whole to the world area at $7660 by #R$B8C3 when world 3 or 4 starts."),
    6: ("Bank 6: worlds 5 and 6",
        "Copied whole to the world area at $7660 by #R$B8C3 when world 5 or 6 starts."),
    7: ("Bank 7: world 7",
        "Copied whole to the world area at $7660 by #R$B8C3 when world 7 starts. Holds the one bit (at +$341B) in which the snapshot differs from the original tape; see docs/provenance.md."),
}


def main():
    targets = ["src/athena.ctl"] + [f"src/bank{n}.ctl" for n in BANKS]
    existing = [t for t in targets if os.path.exists(t)]
    if existing and "--force" not in sys.argv:
        sys.exit(f"refusing to overwrite {', '.join(existing)}: the control files are the "
                 "disassembly now (use --force only to start again)")
    auto = subprocess.run(["sna2ctl.py", "-h", "-m", "build/g2/map-all.txt", "-s", f"0x{SPLIT:04X}",
                           "data/athena128.z80"], capture_output=True, text=True, check=True).stdout
    lines = [ln for ln in auto.splitlines() if ln and not ln.startswith("@")]
    first = int(lines[0].split()[1][1:], 16)
    if first != SPLIT:
        sys.exit(f"sna2ctl started at ${first:04X}, not ${SPLIT:04X}")
    os.makedirs("src", exist_ok=True)
    with open("src/athena.ctl", "w") as f:
        f.write(HEAD)
        f.write("\n".join(lines) + "\n")
    for n, (title, desc) in BANKS.items():
        with open(f"src/bank{n}.ctl", "w") as f:
            f.write(BANK.format(n=n, title=title, desc=desc))
    kinds = {}
    for ln in lines:
        kinds[ln[0]] = kinds.get(ln[0], 0) + 1
    print(f"src/athena.ctl: header regions $4000-${SPLIT - 1:04X}, then {len(lines)} lines from sna2ctl "
          f"({', '.join(f'{k} {v}' for k, v in sorted(kinds.items()))})")
    print("src/bank{1,3,4,6,7}.ctl written")


if __name__ == "__main__":
    main()
