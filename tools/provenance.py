#!/usr/bin/env python3
"""Gate G0: is our snapshot a clean dump of the original tape?

Runs inside the container (it needs SkoolKit):

    make provenance

1. Load Imagine's original 128K tape (SpeedLock 4) with SkoolKit's simulated LOAD.
2. Let the loaded game run for five seconds of emulated time, then on to the next
   entry to its IM 2 handler at $B8B8 - the instruction data/athena128.z80 was
   saved on.
3. Compare all eight RAM banks with the snapshot.

The answer recorded in docs/provenance.md is exactly five bytes, none of them
code. This script fails if that ever stops being true.
"""

import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from specfile import Z80Snapshot  # noqa: E402

OUT = "build/provenance"
FRAME_128K = 70908                  # T-states in one 128K frame
RUN_FOR = 5 * 50 * FRAME_128K       # five seconds of the title screen

# bank, offset -> (what it is, value in data/athena128.z80, value from the tape)
EXPECTED = {
    (0, 0x3253): ("$F253 counter", 71, 68),
    (0, 0x32A6): ("$F2A6 counter", 169, 167),
    (2, 0x38B1): ("$B8B1 stack, below SP", None, None),
    (5, 0x1C06): ("$5C06 KSTATE (ROM keyboard state)", 33, 35),
    (7, 0x341B): ("bank 7 +$341B, inside graphics-like data", 0x40, 0x00),
}


def run(*cmd):
    print("  $ " + " ".join(cmd))
    r = subprocess.run(cmd, capture_output=True, text=True)
    tail = [ln for ln in (r.stdout + r.stderr).replace("\r", "\n").splitlines()
            if ln.strip() and not ln.startswith("[")]
    for ln in tail[-3:]:
        print("    " + ln)
    if r.returncode:
        sys.exit(f"command failed ({r.returncode})")


def main():
    os.makedirs(OUT, exist_ok=True)
    loaded = f"{OUT}/tape128.z80"
    later = f"{OUT}/tape128-5s.z80"
    at_isr = f"{OUT}/tape128-isr.z80"
    for f in (loaded, later, at_isr):
        if os.path.exists(f):
            os.remove(f)
    run("tap2sna.py", "-c", "machine=128", "-c", "accelerator=list",
        "data/athena128.tzx", loaded)
    run("trace.py", "-M", str(RUN_FOR), loaded, later)
    run("trace.py", "-S", "0xB8B8", "-M", "1000000", later, at_isr)

    ours = Z80Snapshot(open("data/athena128.z80", "rb").read())
    tape = Z80Snapshot(open(at_isr, "rb").read())
    print(f"\ntape-loaded machine: PC {tape.pc:04X} SP {tape.sp:04X}, "
          f"$7FFD {tape.port_7ffd:02X}; snapshot: PC {ours.pc:04X} SP {ours.sp:04X}")
    found = {}
    for b in range(8):
        for i in range(16384):
            if ours.bank(b)[i] != tape.bank(b)[i]:
                found[(b, i)] = (ours.bank(b)[i], tape.bank(b)[i])
    ok = True
    for (b, i), (x, y) in sorted(found.items()):
        known = EXPECTED.get((b, i))
        label = known[0] if known else "UNEXPECTED"
        print(f"  bank {b} +{i:04X}: snapshot {x:02X}, tape {y:02X}   {label}")
        if not known:
            ok = False
    missing = set(EXPECTED) - set(found)
    for key in sorted(missing):
        print(f"  bank {key[0]} +{key[1]:04X}: now identical ({EXPECTED[key][0]})")
    identical = 8 * 16384 - len(found)
    print(f"\n{identical:,} of {8 * 16384:,} RAM bytes identical; {len(found)} differ")
    if not ok:
        sys.exit("G0 provenance FAILED: a difference outside the five recorded bytes")
    print("G0 provenance passed: the snapshot is the original tape's game, plus five known bytes")


if __name__ == "__main__":
    main()
