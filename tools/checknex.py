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
import nexpatches                   # noqa: E402

ENGINE_RAM_PAGE = 94                # src/next/athena.asm

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
    check(mmu == [255, ENGINE_RAM_PAGE, 10, 11, 4, 5, 0, 1], "MMU: ROM, the engine's RAM, bank 5, bank 2, bank 0",
          str(mmu))
    check(nextreg(z, 0x8C) & 0xE0 == 0xA0, "alternative ROM on and write-protected", f"NextReg $8C = {nextreg(z, 0x8C):02X}")
    check(nextreg(z, 0x07) & 3 == 3, "CPU at 28 MHz", f"NextReg $07 = {nextreg(z, 0x07):02X}")
    check(nextreg(z, 0x22) & 6 == 6 and nextreg(z, 0x23) == 128, "one interrupt a frame, from line 128",
          f"NextReg $22 = {nextreg(z, 0x22):02X}, $23 = {nextreg(z, 0x23)}")
    keyscan = mem(z, 0x028E, 10)
    check(keyscan[-2:] == b"\xED\x78", "the ROM has KEY-SCAN's IN A,(C) at $0296", keyscan.hex())
    check(mem(z, 0x2000, 4) == b"ATHE", "the engine's RAM is at $2000")
    volatile = [(0xB8A0, 0xB8C0), (0x5800, 0x5B00), (0xF240, 0xF2B0)]
    patched = nexpatches.addresses() | {a + i for a, orig in nexpatches.PLAY_PATCHES for i in range(len(orig))}
    view = snap.view64()
    for name, lo in (("bank 5", 0x4000), ("bank 2", 0x8000), ("bank 0", 0xC000)):
        got = mem(z, lo, 0x4000)
        diff = [lo + i for i in range(0x4000) if got[i] != view[lo + i]]
        stray = [a for a in diff if not any(s <= a < e for s, e in volatile) and a not in patched]
        check(not stray, f"{name} equals the snapshot outside the title's moving bytes and the engine's patches",
              f"{len(diff)} differ" + (f"; UNEXPECTED at {', '.join(f'${a:04X}' for a in stray[:6])}"
                                       if stray else ""))
    unpatched = [a for a, orig in nexpatches.ENGINE_PATCHES + nexpatches.PLAY_PATCHES
                 if mem(z, a, len(orig)) == orig]
    check(not unpatched, "every engine patch is in place",
          ", ".join(f"${a:04X}" for a in unpatched))
    regs = z.cmd("get-registers")
    check("i=b7" in regs.lower() and "im2" in regs.lower().replace(" ", ""),
          "the resume stub finished: I = $B7, IM 2", " ".join(t for t in regs.split() if t.startswith(("PC=", "I=", "IM"))))
    seen = set()
    for _ in range(8):                  # the cycle holds its end colours, so sample it
        seen.add((mem(z, 0xF253, 1)[0], mem(z, 0x5807, 1)[0]))
        z.cmd("exit-cpu-step")
        time.sleep(0.3)
        z.cmd("enter-cpu-step")
    check(len(seen) > 1, "the title's interrupt is running (its colour counter moves)",
          f"{len(seen)} different ($F253, $5807) pairs in 8 samples")
    t = mem(z, 0x2004, 4)
    tick0, frames0 = t[0] | t[1] << 8, t[2] | t[3] << 8
    z.cmd("exit-cpu-step")
    time.sleep(2)
    z.cmd("enter-cpu-step")
    t = mem(z, 0x2004, 4)
    tick1, frames1 = t[0] | t[1] << 8, t[2] | t[3] << 8
    check(frames1 > frames0 and tick1 - tick0 == frames1 - frames0,
          "the engine counts every interrupt as a logic tick at 50 Hz",
          f"ticks +{tick1 - tick0}, interrupts +{frames1 - frames0}")
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
    check(mmu[:2] == [255, ENGINE_RAM_PAGE] and nextreg(z, 0x8C) & 0xE0 == 0xA0,
          "ROM paged with the engine's RAM at $2000, alternative ROM on and write-protected",
          f"MMU {mmu}, NextReg $8C {nextreg(z, 0x8C):02X}")
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
    if status == 1:
        dump_pace(z, nex)
    z.cmd("exit-emulator")


def dump_pace(z, nex):
    """The engine's pass-length histogram (src/next/engine.asm E_HIST) for check-pace."""
    import json
    base = 0x40000 + ENGINE_RAM_PAGE * 8192
    z.cmd("set-memory-zone 0")
    try:
        head = bytes.fromhex(z.cmd(f"read-memory {base} 32").replace("\n", "").strip())
        raw = bytes.fromhex(z.cmd(f"read-memory {base + 0x100} 1024").replace("\n", "").strip())
    finally:
        z.cmd("set-memory-zone -1")
    hist = {}
    for world in range(8):
        for kind in range(4):
            counts = [raw[2 * ((world * 4 + kind) * 16 + n)] | raw[2 * ((world * 4 + kind) * 16 + n) + 1] << 8
                      for n in range(16)]
            if any(counts):
                hist[f"{world},{kind}"] = counts
    out = {"nex": nex, "magic": head[:4].decode("latin-1"), "ticks": head[4] | head[5] << 8,
           "passes": head[0x19] | head[0x1A] << 8, "hist": hist}
    os.makedirs("build/e1", exist_ok=True)
    name = "build/e1/pace-" + os.path.basename(nex).replace("athena-oracle-", "").replace(".nex", "") + ".json"
    json.dump(out, open(name, "w"), indent=1)
    print(f"  pace histogram -> {name}")


def hz60(z):
    """The engine's 60 Hz path, under an emulator that only runs 50 Hz: tell the engine
    the display is 60 Hz and count logic ticks against interrupts."""
    import json
    load(z, "build/athena.nex")
    time.sleep(2)
    z.cmd("enter-cpu-step")
    for addr, value in ((0x2008, 60), (0x2009, 0), (0x2017, 262 & 255), (0x2018, 262 >> 8)):
        z.cmd(f"write-memory {addr} {value}")   # E_HZ = 60, E_ACC = 0, E_LPF = 262
    check(mem(z, 0x2008, 2) == bytes([60, 0]), "the engine told the display is 60 Hz")
    t = mem(z, 0x2004, 4)
    tick0, frames0 = t[0] | t[1] << 8, t[2] | t[3] << 8
    z.cmd("exit-cpu-step")
    time.sleep(4)
    z.cmd("enter-cpu-step")
    t = mem(z, 0x2004, 4)
    ticks, interrupts = (t[0] | t[1] << 8) - tick0, (t[2] | t[3] << 8) - frames0
    json.dump({"ticks": ticks, "interrupts": interrupts}, open("build/e1/hz60.json", "w"))
    check(interrupts > 100, "the play build ran", f"{interrupts} interrupts, {ticks} ticks")
    z.cmd("exit-emulator")


def main():
    mode = sys.argv[1]
    z = Zrcp(port=PORT, timeout=30)
    if mode == "play":
        play(z)
    elif mode == "hz60":
        os.makedirs("build/e1", exist_ok=True)
        hz60(z)
    else:
        oracle(z, sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 7200)
    if FAILS:
        sys.exit(f"\nG3 check-{mode} FAILED: {len(FAILS)} check(s)")
    print(f"\nG3 check-{mode} passed")


if __name__ == "__main__":
    main()
