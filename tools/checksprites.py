#!/usr/bin/env python3
"""Gate E3: every sprite the game draws is on the Next's hardware sprites, exactly.

    make check-sprites      (inside the container; runs an oracle build)

The oracle build replays Rafal's recording through the port. Every SAMPLE_EVERY
seconds this asks the engine to sample its next pass head (src/next/sprites.asm,
E_SPR_REQ): the engine builds that pass's objects, shows them at their final places
and holds the game there. The checker then rebuilds, from the game's own memory, what
the hardware sprites must be:

  - the player, first: composited from the pieces the engine recorded ($EDD5 calls)
    the way the game masks them into its buffer, one 16x32 object at the display
    address in $B94E less two bytes, mirrored when FacingLeft ($B952) is set;
  - every recorded draw ($EB1C, $EB72, $EBB0) in order, not shown when its display
    address is outside the screen: cut into 16x16 tiles, ink where the graphic bit is
    set, transparent where only the mask bit is, paper where neither;

and compares every sprite's five attributes (position, mirror, visible, pattern) and
every pattern's 256 bytes with the Next's, through ZEsarUX. Sprites past the count must
be invisible. It passes when every sample matches, every world was sampled
MIN_SAMPLES times, and the oracle still reaches the end of the recording.
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from zrcp import Zrcp               # noqa: E402
import checknex                     # noqa: E402

PORT = int(os.environ.get("ZRCP_PORT", "10010"))
NEX = os.environ.get("NEX", "build/g3/athena-oracle-28.nex")
TIMEOUT = int(os.environ.get("SPRITES_TIMEOUT", "7200"))
SAMPLE_EVERY = int(os.environ.get("SAMPLE_EVERY", "10"))
MIN_SAMPLES = int(os.environ.get("MIN_SAMPLES", "2"))
ENG = 0x40000 + checknex.ENGINE_RAM_PAGE * 8192
TRANSPARENT, PAPER, INK, PLAYER = 0xE3, 1, 2, 3
FAILS = []
SMOKE = int(os.environ.get("SMOKE", "0"))     # seconds: a short run for check-levels, which
                                               # asks only that what it saw matched


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""), flush=True)
    if not ok:
        FAILS.append(what)


class Machine:
    def __init__(self, z):
        self.z = z

    def phys(self, addr, n):
        self.z.cmd("set-memory-zone 0")
        try:
            return self._read(addr, n)
        finally:
            self.z.cmd("set-memory-zone -1")

    def mem(self, addr, n):
        return self._read(addr, n)

    def _read(self, addr, n):
        out = bytearray()
        while n:
            take = min(n, 4096)
            out += bytes.fromhex(self.z.cmd(f"read-memory {addr} {take}").replace("\n", "").strip())
            addr += take
            n -= take
        return bytes(out)

    def eng(self, off, n):
        return self.phys(ENG + off, n)

    def poke_eng(self, off, value):
        self.z.cmd("set-memory-zone 0")
        try:
            self.z.cmd(f"write-memory {ENG + off} {value}")
        finally:
            self.z.cmd("set-memory-zone -1")

    def sprites(self, index, count):
        out = []
        for line in self.z.cmd(f"tbblue-get-sprite {index} {count}").strip().split("\n"):
            out.append([int(v, 16) for v in line.split()])
        return out

    def pattern(self, slot):
        return bytes(int(v, 16) for v in self.z.cmd(f"tbblue-get-pattern {slot} 8").split())


def dfile_xy(d):
    h, l = d >> 8, d & 255
    return (l & 31) * 8, ((h >> 3) & 3) * 64 + (l >> 5) * 8 + (h & 7)


def tile(gfx, width, lines, tx, ty):
    wb = width // 8
    out = bytearray()
    for py in range(16):
        line = ty * 16 + py
        for px in range(16):
            x = tx * 16 + px
            b = x >> 3
            if line >= lines or b >= wb:
                out.append(TRANSPARENT)
                continue
            m, g = gfx[line * 2 * wb + 2 * b], gfx[line * 2 * wb + 2 * b + 1]
            bit = 0x80 >> (x & 7)
            out.append(INK if g & bit else TRANSPARENT if m & bit else PAPER)
    return bytes(out)


def player_tiles(m, pieces):
    buf = [0] * 512
    for lines, dest, gfx_addr in pieces:
        line0 = (dest & 255) >> 1
        gfx = m.mem(gfx_addr, 4 * lines)
        for n in range(lines):
            line = line0 + n
            if line >= 32:
                break
            for b in range(2):
                mask, g = gfx[4 * n + 2 * b], gfx[4 * n + 2 * b + 1]
                for bitn in range(8):
                    bit = 0x80 >> bitn
                    i = line * 16 + b * 8 + bitn
                    if g & bit:
                        buf[i] = 2
                    elif not mask & bit:
                        buf[i] = 1
    pats = []
    for t in range(2):
        pats.append(bytes(TRANSPARENT if v == 0 else PLAYER if v == 2 else PAPER for v in buf[256 * t:256 * t + 256]))
    return pats


def expected(m, arcade=None):
    """[(x, y, w, h, flip, [tile patterns])] in the engine's order; with an arcade model
    (tools/checkmapping.py), a mapped object is (x, y, "arcade", candidates, None, None):
    the (entry, pieces) it may show."""
    objs = []
    pl_last = m.eng(0xE09, 1)[0]
    arc_player = False
    if arcade and pl_last not in (0, 0xFF):
        a = m.mem(0xB94E, 2)
        d = (a[0] | a[1] << 8) - 2
        cands = arcade.player(m)
        if cands and 0x40 <= d >> 8 < 0x58:
            x, y = dfile_xy(d)
            objs.append((x, y, "arcade", cands, None, None))
            arc_player = True
            pl_last = 0
    if pl_last not in (0, 0xFF):
        raw = m.eng(0x781, 5 * pl_last)
        pieces = [(raw[5 * i], raw[5 * i + 1] | raw[5 * i + 2] << 8, raw[5 * i + 3] | raw[5 * i + 4] << 8)
                  for i in range(pl_last)]
        a = m.mem(0xB94E, 2)
        d = (a[0] | a[1] << 8) - 2
        if 0x40 <= d >> 8 < 0x58:
            x, y = dfile_xy(d)
            flip = 1 if m.mem(0xB952, 1)[0] else 0
            objs.append((x, y, 1, 2, flip, player_tiles(m, pieces)))
    dl_last = m.eng(0xE08, 1)[0]
    raw = m.eng(0x601, 8 * dl_last)
    for i in range(dl_last):
        e = raw[8 * i:8 * i + 8]
        width, lines, gfx_addr, d = e[0], e[1], e[2] | e[3] << 8, e[4] | e[5] << 8
        if not 0x40 <= d >> 8 < 0x58:
            continue
        x, y = dfile_xy(d)
        if arcade:
            cands = arcade.draw(m, gfx_addr, arc_player)
            if cands:
                objs.append((x, y, "arcade", cands, None, None))
                continue
        w, h = (width + 15) // 16, (lines + 15) // 16
        gfx = m.mem(gfx_addr, 2 * (width // 8) * lines)
        objs.append((x, y, w, h, 0, [tile(gfx, width, lines, tx, ty) for ty in range(h) for tx in range(w)]))
    return objs


def compare(m, arcade=None):
    objs = expected(m, arcade)
    count = m.eng(0x800, 1)[0]
    bad = []
    if count != len(objs):
        bad.append(f"{count} objects, expected {len(objs)}")
        return len(objs), 0, bad
    raw = m.eng(0x801, 16 * count)
    # an arcade object shows the candidate whose entry the engine chose
    chosen = []
    for i, o in enumerate(objs):
        if o[2] != "arcade":
            chosen.append(None)
            continue
        entry = raw[16 * i + 8] | raw[16 * i + 9] << 8
        pick = [pieces for e, pieces in o[3] if e == entry and raw[16 * i + 15] == 1]
        if not pick:
            bad.append(f"object {i}: entry ${entry:04X} kind {raw[16 * i + 15]}, "
                       f"expected one of {', '.join(f'${e:04X}' for e, _ in o[3])}")
            return len(objs), 0, bad
        chosen.append(pick[0])
    shown = m.eng(0xE02, 1)[0]
    ntiles = sum(len(c) if c is not None else o[2] * o[3] for o, c in zip(objs, chosen))
    if shown != ntiles:
        bad.append(f"{shown} sprites shown, expected {ntiles}")
    spr = m.sprites(0, max(shown, ntiles) + 4)
    n = 0
    for (x, y, w, h, flip, pats), pieces in zip(objs, chosen):
        if pieces is not None:
            for dx, dy, img, pal, pattern in pieces:
                s = spr[n]
                X, Y = x + dx + 32, y + dy + 32
                want = [X & 255, Y & 255, pal | (X >> 8 & 1), 0xC0 | img & 63, 0x80 | img & 0x40 | (Y >> 8 & 1)]
                if s[:5] != want:
                    bad.append(f"sprite {n}: {s} want {want}")
                else:
                    half = m.pattern(img >> 1)[128 * (img & 1):128 * (img & 1) + 128]
                    if half != pattern:
                        bad.append(f"sprite {n}: 4-bit image {img} differs in "
                                   f"{sum(1 for a, b in zip(half, pattern) if a != b)} bytes")
                n += 1
            continue
        for ty in range(h):
            for tx in range(w):
                s = spr[n]
                col = (w - 1 - tx) if flip else tx
                X, Y = x + 32 + 16 * col, y + 32 + 16 * ty
                want = [X & 255, Y & 255, (flip << 3) | (X >> 8 & 1), None, Y >> 8 & 1]
                if len(s) < 5 or s[0] != want[0] or s[1] != want[1] or s[2] != want[2] or s[4] != want[4] \
                        or s[3] & 0xC0 != 0xC0:
                    bad.append(f"sprite {n}: {s} want X {X} Y {Y} flip {flip}")
                else:
                    pat = m.pattern(s[3] & 63)
                    if pat != pats[ty * w + tx]:
                        diff = sum(1 for a, b in zip(pat, pats[ty * w + tx]) if a != b)
                        bad.append(f"sprite {n}: pattern slot {s[3] & 63} differs in {diff} pixels")
                n += 1
    for k in range(n, len(spr)):
        if spr[k][3] & 0x80:
            bad.append(f"sprite {k} is visible past the count")
    return len(objs), ntiles, bad


def main():
    run(NEX, None, "E3 check-sprites")


def run(nex, arcade, label):
    z = Zrcp(port=PORT, timeout=60)
    m = Machine(z)
    checknex.load(z, nex)
    time.sleep(1)
    started, last_req, per_world, samples = time.time(), 0, {}, 0
    last_done = m.eng(0xE06, 1)[0]
    while time.time() - started < (SMOKE or TIMEOUT):
        verdict = checknex.vars_block(z, 5)[4]
        if verdict:
            break
        done = m.eng(0xE06, 1)[0]
        if done != last_done:
            last_done = done
            world = m.mem(0xBA33, 1)[0]
            nobj, ntiles, bad = compare(m, arcade)
            samples += 1
            if 1 <= world <= 7:
                per_world[world] = per_world.get(world, 0) + 1
            print(f"    {time.time() - started:6.0f} s  world {world}  {nobj} objects, {ntiles} sprites  "
                  f"{'match' if not bad else '; '.join(bad[:3])}", flush=True)
            if bad:
                check(False, f"sample {samples} in world {world}", "; ".join(bad[:5]))
            m.poke_eng(0xE07, 0)                    # let the game go on
            if len(FAILS) > 5:
                break
        elif time.time() - last_req > SAMPLE_EVERY and m.eng(0xE05, 1)[0] == 0 and m.eng(0xE07, 1)[0] == 0:
            m.poke_eng(0xE05, 1)
            last_req = time.time()
        time.sleep(0.5)
    verdict = checknex.vars_block(z, 5)[4]
    c = m.eng(0xE27, 4)
    reused, full = c[0] | c[1] << 8, c[2] | c[3] << 8
    check(full == 0, "the image cache always had a free slot",
          f"a shown slot was reused {reused} times; no slot at all {full} times")
    if SMOKE:
        check(samples >= 3 and len(FAILS) == 0, f"{samples} samples matched in {SMOKE} seconds")
    else:
        check(verdict == 1, "the oracle reached the end of the recording with the sprites in", f"status {verdict}")
        for world in range(1, 8):
            check(per_world.get(world, 0) >= MIN_SAMPLES, f"world {world} sampled",
                  f"{per_world.get(world, 0)} samples")
    if arcade:
        arcade.report(check)
    z.cmd("exit-emulator")
    if FAILS:
        sys.exit(f"\n{label} FAILED: {len(FAILS)} check(s)")
    print(f"\n{label} passed")


if __name__ == "__main__":
    main()
