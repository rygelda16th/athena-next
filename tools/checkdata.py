#!/usr/bin/env python3
"""Gate G0: the game files are the ones every later number is measured against.

    python3 tools/checkdata.py [data-dir]

Checks, each against a fact established before this project wrote any code:

1. athena128.z80 is a 128K snapshot, stopped where the recording also starts.
2. athena.rzx is Rafal's single-block 128K recording, 119,654 frames long.
3. The recording's embedded snapshot and the .z80 differ in EXACTLY 85 bytes:
   three counters at $F253/$F254/$F2A6, the two stack bytes below SP, and 80
   attribute bytes of the title screen's colour flash. Everything else - every
   byte of code and level data - is identical, so the recording plays our dump.
4. The eight places the published 128K POKEs patch hold the instructions those
   POKEs replace (DEC (HL), DEC A, JR Z, JP NZ, an operand), which ties the
   snapshot to the build the POKE file was written for.
5. athena128.tzx is a TZX tape image.
Digests themselves are tools/fetch.py's job.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from specfile import Rzx, Z80Snapshot  # noqa: E402

FAILS = []


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""))
    if not ok:
        FAILS.append(what)


def main():
    data = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "data")

    print("athena128.z80")
    z = Z80Snapshot(open(os.path.join(data, "athena128.z80"), "rb").read())
    check(z.is_128k, "128K hardware", f"v{z.version} mode {z.hw_mode}")
    check(sorted(z.pages) == list(range(3, 11)), "all eight RAM banks present")
    check((z.pc, z.sp, z.i, z.im, z.iff1) == (0xB8B8, 0xB8B1, 0xB7, 2, 0),
          "stopped at the IM 2 handler entry",
          f"PC {z.pc:04X} SP {z.sp:04X} I {z.i:02X} IM {z.im} IFF1 {z.iff1}")
    check(z.port_7ffd == 0x10, "bank 0 at $C000 with the 48K ROM paged", f"$7FFD={z.port_7ffd:02X}")

    print("athena.rzx")
    r = Rzx(open(os.path.join(data, "athena.rzx"), "rb").read())
    check(r.creator and r.creator[0] == "Spectaculator", "recorded in Spectaculator", str(r.creator))
    check(len(r.snapshots) == 1 and r.snapshots[0][0] == "z80", "one embedded .z80 snapshot")
    check(len(r.input_blocks) == 1, "one input-recording block",
          "ZEsarUX only plays the first block; SkoolKit's rzxplay plays all")
    check(r.frames == 119654, "119,654 frames (39.9 minutes at 50 Hz)", f"{r.frames:,}")
    e = Z80Snapshot(r.snapshots[0][1])
    check(e.is_128k, "embedded snapshot is 128K", f"v{e.version} mode {e.hw_mode}")
    check((e.pc, e.sp, e.i, e.im, e.port_7ffd) == (z.pc, z.sp, z.i, z.im, z.port_7ffd),
          "embedded snapshot stopped at the same place")

    diff = {b: [i for i in range(16384) if z.bank(b)[i] != e.bank(b)[i]] for b in range(8)}
    expected = {
        0: [0x3253, 0x3254, 0x32A6],        # $F253, $F254, $F2A6: counters
        2: [0x38B0, 0x38B1],                # $B8B0-$B8B1: just below SP
    }
    attr = diff[5]
    check(all(diff[b] == expected.get(b, []) for b in (0, 1, 2, 3, 4, 6, 7)),
          "banks 0-4, 6, 7 differ only at the three counters and the stack",
          ", ".join(f"bank {b}: {len(v)}" for b, v in diff.items() if v))
    check(len(attr) == 80 and all(0x1800 <= i < 0x1B00 for i in attr),
          "bank 5 differs only in 80 attribute bytes ($5800-$5AFF)",
          f"{len(attr)} bytes, ${0x4000 + attr[0]:04X}-${0x4000 + attr[-1]:04X}" if attr else "none")
    total = sum(len(v) for v in diff.values())
    check(total == 85, "85 differing bytes in all", str(total))

    print("128K POKE sites (Spectrum Computing's Athena (1987)(Imagine Software).pok)")
    view = z.view64()
    sites = [
        ("infinite lives",       0xCCAD, 0x35, "DEC (HL) after LD HL,$C1EE"),
        ("infinite credits",     0xCCBA, 0x3D, "DEC A"),
        ("infinite continues",   0xCCED, 0x3D, "DEC A"),
        ("megajumps",            0xC76C, 0x3D, "DEC A before LD ($B953),A"),
        ("infinite time",        0xDAF4, 0xB9, "high byte of LD HL,$B94D; DEC (HL)"),
        ("infinite energy",      0xBF10, 0x35, "DEC (HL) after LD HL,$BF1B"),
        ("immunity",             0xD4F2, 0xC2, "JP NZ"),
        ("keep objects (1 of 2)", 0xCD13, 0x28, "JR Z"),
    ]
    for name, addr, byte, what in sites:
        check(view[addr] == byte, f"{name}: ${addr:04X} = {byte:02X}", f"{view[addr]:02X}; {what}")

    print("athena128.tzx")
    t = open(os.path.join(data, "athena128.tzx"), "rb").read()
    check(t[:8] == b"ZXTape!\x1a", "TZX signature", f"v{t[8]}.{t[9]}, {len(t):,} bytes")

    if FAILS:
        print(f"\nG0 data check FAILED: {len(FAILS)} of the checks above")
        sys.exit(1)
    print("\nG0 data check passed")


if __name__ == "__main__":
    main()
