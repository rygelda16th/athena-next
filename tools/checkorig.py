#!/usr/bin/env python3
"""Gate G1: the original game runs in the project's headless ZEsarUX as a 128K.

    make check-orig      (starts the emulator in the container, then runs this)

1. ZEsarUX took data/athena128.z80 as a Spectrum 128K, stopped where the snapshot
   was saved.
2. All eight RAM banks read back over ZRCP equal the snapshot's, except for the
   bytes the running title changes (counters, stack, colour flash); zone 0 lays
   the banks out as bank n at n * 16384.
3. ZEsarUX's own screenshot equals tools/zxscreen.py's render of the same bytes
   in all 49,152 pixels - the check that keeps the renderer honest about the
   display file's layout (see the note at the top of zxscreen.py).
4. Released for three seconds, the game runs: the title's counters move and
   the program counter is still inside the game.
"""

import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from specfile import Z80Snapshot    # noqa: E402
from zrcp import Zrcp               # noqa: E402
from zxscreen import PALETTE, screen_rgb  # noqa: E402

PORT = int(os.environ.get("ZRCP_PORT", "10010"))
FAILS = []


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""))
    if not ok:
        FAILS.append(what)


def read_bank(z, n):
    z.cmd("set-memory-zone 0")
    try:
        text = z.cmd(f"read-memory {n * 16384} 16384").replace("\n", "").strip()
    finally:
        z.cmd("set-memory-zone -1")
    return bytes.fromhex(text)


def pbm_pixels(path):
    data = open(path, "rb").read()
    magic, dims, rest = data.split(b"\n", 2)
    width, height = map(int, dims.split())
    assert magic == b"P4" and (width, height) == (256, 192), (magic, width, height)
    return lambda x, y: rest[y * 32 + x // 8] >> (7 - x % 8) & 1


def main():
    snap = Z80Snapshot(open("data/athena128.z80", "rb").read())
    z = Zrcp(port=PORT, timeout=30)
    z.cmd("enter-cpu-step")

    print("loaded")
    machine = z.cmd("get-current-machine")
    check("128k" in machine, "machine is a Spectrum 128K", machine)
    regs = z.registers()
    check((regs.get("PC"), regs.get("SP"), regs.get("I")) == (0xB8B8, 0xB8B1, 0xB7),
          "stopped at the IM 2 handler entry, as the snapshot was",
          f"PC {regs.get('PC', 0):04X} SP {regs.get('SP', 0):04X} I {regs.get('I', 0):02X}")
    check("SCR5" in z.cmd("get-paging-state"), "screen from bank 5")

    # The emulator runs from the moment it loads, so by the time the checker has
    # connected the title has moved on a few frames. What may differ is exactly
    # what differs between the snapshot and the recording's own start
    # (docs/provenance.md): the title's counters, the stack below SP and the
    # colour flash in the attributes. Anything else is a failure.
    volatile = {0: set(range(0x3240, 0x32B0)),          # $F240-$F2AF counters
                2: set(range(0x38A0, 0x38C0)),          # $B8A0-$B8BF stack
                5: set(range(0x1800, 0x1B00))}          # $5800-$5AFF attributes
    for n in range(8):
        got = read_bank(z, n)
        diff = [i for i, (a, b) in enumerate(zip(got, snap.bank(n))) if a != b]
        stray = [i for i in diff if i not in volatile.get(n, ())]
        check(len(got) == 16384 and not stray, f"bank {n} equals the snapshot",
              f"{len(diff)} volatile byte(s) moved" + (
                  f"; UNEXPECTED at +{', +'.join(f'{i:04X}' for i in stray[:8])}" if stray else ""))

    print("screen")
    shot = "/work/build/g1/orig-title.pbm"
    os.makedirs(os.path.dirname(shot.replace("/work/", "")), exist_ok=True)
    z.cmd(f"save-screen {shot}")
    lit = pbm_pixels(shot)
    scr = snap.bank(5)[:6912]
    rgb = screen_rgb(scr)
    wrong = 0
    for y in range(192):
        for x in range(256):
            attr = scr[6144 + (y // 8) * 32 + x // 8]
            paper = ((attr >> 3) & 7) + (8 if attr & 0x40 else 0)
            ours = rgb[y][x] != PALETTE[paper]
            if ours != bool(lit(x, y)):
                wrong += 1
    check(wrong == 0, "ZEsarUX's screenshot equals our render, every pixel", f"{wrong} of 49,152 differ")

    print("running")
    before = read_bank(z, 0)
    z.cmd("exit-cpu-step")
    time.sleep(3)
    z.cmd("enter-cpu-step")
    after = read_bank(z, 0)
    moved = [i for i in (0x3253, 0x3254, 0x32A6) if before[i] != after[i]]
    check(bool(moved), "the title's counters moved in 3 s",
          ", ".join(f"${0xC000 + i:04X} {before[i]:02X}->{after[i]:02X}" for i in moved) or "none")
    pc = z.registers().get("PC", 0)
    check(pc >= 0x5B00, "program counter is in the game, not the ROM", f"PC {pc:04X}")
    z.cmd("exit-emulator")

    if FAILS:
        sys.exit(f"\nG1 check-orig FAILED: {len(FAILS)} check(s)")
    print("\nG1 check-orig passed: the original runs in headless ZEsarUX as a 128K")


if __name__ == "__main__":
    main()
