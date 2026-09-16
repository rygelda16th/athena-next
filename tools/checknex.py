#!/usr/bin/env python3
"""Gate G3: the original running as a Next program, and the oracle.

    make check-play      athena.nex under headless ZEsarUX as a TBBlue (Next)
    make check-oracle    athena-oracle-35.nex and -28.nex against the recording

check-play: after loading, the game's banks must equal the snapshot outside the
bytes the running title changes, MMU slots must be where the resume stub put
them (ROM at $0000-$3FFF, bank 5 / bank 2 / bank 0 above), the ROM must hold
KEY-SCAN where the game calls it, and ZEsarUX's screenshot must be the title.

check-oracle: loads the oracle build, confirms the handler is in place (page 18
at $0000 with JP handler at $0028, page 19 at $2000), then polls the verdict
block at $3C00 until the handler reports PASS (the whole stream consumed, every
checkpoint matched) or a failure, printing progress as it goes.
"""

import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from specfile import Z80Snapshot    # noqa: E402
from zrcp import Zrcp               # noqa: E402

PORT = int(os.environ.get("ZRCP_PORT", "10010"))
FAILS = []


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""))
    if not ok:
        FAILS.append(what)


def mem(z, addr, n):
    text = z.cmd(f"read-memory {addr} {n}").replace("\n", "").strip()
    return bytes.fromhex(text)


def nextreg(z, r):
    return int(z.cmd(f"tbblue-get-register {r}").strip().split()[-1].rstrip("Hh"), 16)


def load(z, nex):
    z.cmd("enter-cpu-step")
    print("  " + (z.cmd(f"smartload /work/{nex}") or f"smartload {nex}"))
    z.cmd("exit-cpu-step")


def play(z):
    snap = Z80Snapshot(open("data/athena128.z80", "rb").read())
    load(z, "build/athena.nex")
    time.sleep(3)
    z.cmd("enter-cpu-step")
    mmu = [nextreg(z, 0x50 + i) for i in range(8)]
    check(mmu == [255, 255, 10, 11, 4, 5, 0, 1], "MMU: ROM, bank 5, bank 2, bank 0", str(mmu))
    check(nextreg(z, 0x07) & 3 == 0, "CPU at 3.5 MHz", f"NextReg $07 = {nextreg(z, 0x07):02X}")
    keyscan = mem(z, 0x028E, 10)
    check(keyscan[-2:] == b"\xED\x78", "the ROM has KEY-SCAN's IN A,(C) at $0296", keyscan.hex())
    volatile = [(0xB8A0, 0xB8C0), (0x5800, 0x5B00), (0xF240, 0xF2B0)]
    view = snap.view64()
    for name, lo in (("bank 5", 0x4000), ("bank 2", 0x8000), ("bank 0", 0xC000)):
        got = mem(z, lo, 0x4000)
        diff = [lo + i for i in range(0x4000) if got[i] != view[lo + i]]
        stray = [a for a in diff if not any(s <= a < e for s, e in volatile)]
        check(not stray, f"{name} equals the snapshot outside the title's moving bytes",
              f"{len(diff)} moved" + (f"; UNEXPECTED at {', '.join(f'${a:04X}' for a in stray[:6])}"
                                      if stray else ""))
    regs = z.cmd("get-registers")
    check("i=b7" in regs.lower() and "im2" in regs.lower().replace(" ", ""),
          "the resume stub finished: I = $B7, IM 2", " ".join(t for t in regs.split() if t.startswith(("PC=", "I=", "IM"))))
    before = mem(z, 0xF253, 1)[0], mem(z, 0x5807, 1)[0]
    z.cmd("exit-cpu-step")
    time.sleep(2)
    z.cmd("enter-cpu-step")
    after = mem(z, 0xF253, 1)[0], mem(z, 0x5807, 1)[0]
    check(before != after, "the title's interrupt is running (its colour counter moves)",
          f"$F253 {before[0]:02X}->{after[0]:02X}, $5807 {before[1]:02X}->{after[1]:02X}")
    z.cmd("save-screen /work/build/g3/play-title.pbm")
    shot = open("build/g3/play-title.pbm", "rb").read().split(b"\n", 2)[2]
    ours = open("build/g1/orig-title.pbm", "rb").read().split(b"\n", 2)[2] \
        if os.path.exists("build/g1/orig-title.pbm") else None
    if ours:
        differ = sum(bin(a ^ b).count("1") for a, b in zip(shot, ours))
        check(differ == 0, "the screen is the original's title (pixel for pixel, vs check-orig)",
              f"{differ} pixels differ")
    z.cmd("exit-emulator")


VARS = 0x40000 + 18 * 8192   # page 18; ZEsarUX zone 0 puts page n at 0x40000 + n * 8192


def vars_block(z, n=24):
    z.cmd("set-memory-zone 0")
    try:
        return bytes.fromhex(z.cmd(f"read-memory {VARS} {n}").replace("\n", "").strip())
    finally:
        z.cmd("set-memory-zone -1")


def oracle(z, nex, timeout):
    load(z, nex)
    time.sleep(1)
    z.cmd("enter-cpu-step")
    mmu = [nextreg(z, 0x50 + i) for i in range(8)]
    check(mmu[:2] == [255, 255] and nextreg(z, 0x8C) & 0xE0 == 0xA0,
          "ROM paged, alternative ROM on and write-protected", f"MMU {mmu}, NextReg $8C {nextreg(z, 0x8C):02X}")
    check(vars_block(z, 4) == b"ATHO", "verdict block present in page 18")
    check(mem(z, 0x0028, 1) == b"\xC3", "RST $28 jumps to the handler")
    z.cmd("exit-cpu-step")
    if FAILS:
        return
    started = time.time()
    last = -1
    while True:
        block = vars_block(z)
        status = block[4]
        events = block[5] | block[6] << 8 | block[7] << 16
        checks = block[8] | block[9] << 8
        if events != last and (time.time() - started) > 0:
            print(f"    {time.time() - started:6.0f} s  events {events:>9,}  checkpoints {checks:>5,}",
                  flush=True)
            last = events
        if status:
            break
        if time.time() - started > timeout:
            check(False, "oracle finished within the time allowed", f"{timeout} s, events {events:,}")
            return
        time.sleep(15)
    want, site = block[10], block[11]
    expected, got = block[12] | block[13] << 8, block[14] | block[15] << 8
    ret = block[17] | block[18] << 8
    detail = {1: f"all {events:,} events consumed, {checks:,} checkpoints matched",
              2: f"at event {events:,}: the game asked for site {want} (RST at ${ret - 1:04X}), "
                 f"the stream holds site {site}",
              3: f"at event {events:,}: checkpoint {checks + 1} hash {got:04X}, expected {expected:04X} "
                 f"(kind {block[16]}, RST at ${ret - 1:04X})"}.get(status, f"status {status}")
    check(status == 1, f"{nex}: the recording replayed through the port", detail)
    z.cmd("exit-emulator")


def main():
    mode = sys.argv[1]
    z = Zrcp(port=PORT, timeout=30)
    if mode == "play":
        play(z)
    else:
        oracle(z, sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 7200)
    if FAILS:
        sys.exit(f"\nG3 check-{mode} FAILED: {len(FAILS)} check(s)")
    print(f"\nG3 check-{mode} passed")


if __name__ == "__main__":
    main()
