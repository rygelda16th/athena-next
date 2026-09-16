#!/usr/bin/env python3
"""Gate G2: the control files lose nothing, and carry none of the game.

    make check-ctl      (inside the container)

For src/athena.ctl and src/bankN.ctl:
1. Round trip: sna2skool.py turns the ctl and the snapshot into a skool file,
   skool2ctl.py turns that back into a ctl, and the result must equal the
   committed ctl exactly. So everything in the ctl reaches the skool file, and
   the committed file is in the canonical form `make ctl` writes.
2. No game bytes: no line may hold an instruction or a DEFB/DEFM/DEFS/DEFW
   statement. A ctl names addresses, lengths, block types and comments.
3. If work/NAME.skool exists and differs from what the ctl produces, say so:
   annotations made there have not been saved with `make ctl` yet.
"""

import filecmp
import os
import re
import subprocess
import sys

NAMES = ["athena"] + [f"bank{n}" for n in (1, 3, 4, 6, 7)]
DATA = re.compile(r"\b(DEFB|DEFM|DEFS|DEFW)\b\s+[$%0-9\"]", re.I)
INSTRUCTION_LINE = re.compile(r"^[ *]\$[0-9A-F]{4} ")
OUT = "build/g2/ctlcheck"


def main():
    os.makedirs(OUT, exist_ok=True)
    fails = []
    for name in NAMES:
        ctl = f"src/{name}.ctl"
        page = [] if name == "athena" else ["-p", name[4:]]
        skool = f"{OUT}/{name}.skool"
        with open(skool, "w") as f:
            subprocess.run(["sna2skool.py", "-H", *page, "-c", ctl, "data/athena128.z80"],
                           stdout=f, stderr=subprocess.DEVNULL, check=True)
        again = subprocess.run(["skool2ctl.py", "-h", skool], capture_output=True, text=True,
                               check=True).stdout
        same = again == open(ctl).read()
        leaks = [i + 1 for i, line in enumerate(open(ctl))
                 if DATA.search(line) or INSTRUCTION_LINE.match(line)]
        lines = sum(1 for _ in open(ctl))
        print(f"  {'ok  ' if same else 'FAIL'}  {ctl}: {lines} lines, round trip "
              f"{'identical' if same else 'DIFFERS (run make skool && make ctl)'}")
        print(f"  {'ok  ' if not leaks else 'FAIL'}  {ctl}: "
              f"{'no instructions or data statements' if not leaks else f'game bytes at lines {leaks[:5]}'}")
        if not same:
            fails.append(f"{ctl} round trip")
        if leaks:
            fails.append(f"{ctl} holds game bytes")
        work = f"work/{name}.skool"
        if os.path.exists(work) and not filecmp.cmp(work, skool, shallow=False):
            print(f"  note  {work} differs from what {ctl} produces - unsaved annotations?")
    if fails:
        sys.exit(f"G2 check-ctl FAILED: {', '.join(fails)}")
    print("G2 check-ctl passed")


if __name__ == "__main__":
    main()
