#!/usr/bin/env python3
"""D2 gate: the play-area formats are right.

For each world snapshot from `make rzx-end` (build/g1/world1.z80 ... world7.z80) this
rebuilds the back buffer at $F000 from the map, the map window, the facing, the scroll
step count and the world's table of 16x16 map cells, exactly as the game's redraw
($DE99, $DDEE, $DDFD, $DE29) and scroll ($E989, $DD66) do, and compares it byte for
byte with the buffer in the snapshot. If a scroll step is under way in the snapshot,
the one line it has reached is left out. The play area on screen is also compared:
it may differ only where sprites are drawn over it (they never go into the buffer).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from specfile import Z80Snapshot  # noqa: E402

WORLDS = [f"build/g1/world{n}.z80" for n in range(1, 8)]


def word(m, a):
    return m[a] | m[a + 1] << 8


def block_index(m, code):
    """#R$DDFD: which entry of the cell table a map cell code draws."""
    if code >= 0x79:
        a = code
    elif code >= 0x60:
        a = m[0xDE09]                     # the world's item block
    elif code >= 0x46 or code < 0x10:
        a = m[0xCECA]                     # the world's background block
    elif code >= 0x2E:
        a = code + 0x32                   # item pictures
    else:
        a = code
    return (a - 0x60) & 0xFF


def redraw(m, window):
    """$DE99: 15 map columns of 8 cells, from the column before the window, into bytes 1-30."""
    buf = bytearray(4096)
    table, hl = word(m, 0xDE2F), window - 8
    for col in range(15):
        for row in range(8):
            src = table + 32 * block_index(m, m[hl])
            dest = 1 + 2 * col + 512 * row
            for line in range(16):
                buf[dest + 32 * line] = m[(src + 2 * line) & 0xFFFF]
                buf[dest + 32 * line + 1] = m[(src + 2 * line + 1) & 0xFFFF]
            hl += 1
    return buf


def shift_left(buf):
    """$E989: two one-bit shifts of bytes 30..1 of every line."""
    for n in range(128):
        carry = 0
        for _ in range(2):
            for x in range(30, 0, -1):
                v = buf[n * 32 + x] << 1 | carry
                buf[n * 32 + x], carry = v & 0xFF, v >> 8


def picture(m, window, facing, count):
    """How #R$DD66 rebuilds the buffer: the window it was drawn from, then the shifts since."""
    if count > 8:
        count -= 8
        window = window + 8 if facing else window - 8
    if facing and count == 8:
        window, shifts = window + 8, 0
    elif facing:
        shifts = count
    else:
        shifts = 8 - count
    buf = redraw(m, window)
    for _ in range(shifts):
        shift_left(buf)
    return buf


def dfile(n, x):
    return 2048 * (n // 64) + 256 * (n % 8) + 32 * ((n // 8) % 8) + x


def check(path):
    snap = Z80Snapshot(open(path, "rb").read())
    m = snap.view64()
    window, facing, count, pc = word(m, 0xBA17), m[0xB952], m[0xD4A2], snap.pc
    now = picture(m, window, facing, count)
    before = picture(m, window, facing, count + 1)
    pending = None
    if 0xE989 <= pc < 0xEBB0:             # a two-pixel shift is under way; HL is its line
        pending = (snap.hl - 0xF000) // 32
        buf = now[:32 * (pending + 1)] + before[32 * (pending + 1):]
        shown = before
    elif pc == 0xCEFB:                    # scrolled, waiting for the frame before the copy
        buf, shown = now, before
    else:
        buf, shown = now, now
    real = m[0xF000:0x10000]
    lines = [n for n in range(128) if n != pending]
    total = len(lines) * 30
    same = sum(buf[n * 32 + x] == real[n * 32 + x] for n in lines for x in range(1, 31))
    screen = m[0x4000:0x5800]
    cells = {(n // 8, x) for n in range(128) for x in range(3, 29) if screen[dfile(n, x)] != shown[n * 32 + x]}
    return same, total, len(cells)


def main():
    missing = [p for p in WORLDS if not os.path.exists(p)]
    if missing:
        sys.exit(f"D2 check-gfx: run `make rzx-end` first (missing {', '.join(missing)})")
    fails = []
    for path in WORLDS:
        same, total, cells = check(path)
        ok = same == total and cells <= 40
        print(f"  {'ok  ' if ok else 'FAIL'}  {path}: buffer {same:,}/{total:,} bytes; "
              f"screen differs from it in {cells} character cells (sprites)")
        if not ok:
            fails.append(path)
    if fails:
        sys.exit(f"D2 check-gfx FAILED: {', '.join(fails)}")
    print("D2 check-gfx passed: the play area is rebuilt from the map and cell tables in all seven worlds")


if __name__ == "__main__":
    main()
