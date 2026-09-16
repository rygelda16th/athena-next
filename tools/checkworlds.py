#!/usr/bin/env python3
"""D3 gate: the map format is right.

For each world snapshot from `make rzx-end` (build/g1/world1.z80 ... world7.z80) this
rebuilds the play-area buffer at $F000 from the PRISTINE world data in data/athena128.z80
(tools/render_world.py world_memory: the bank, the bank 1 tail, and what world set-up
writes), with the snapshot's map window, facing and scroll step, as tools/checkgfx.py
does. Play changes some map cells and, through the stale list walk at a world change,
some cell pictures; those are copied in from the snapshot, and then every buffer byte
must match. The counts of changed cells and pictures are printed.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import checkgfx  # noqa: E402
from render_world import WORLDS, world_memory, word  # noqa: E402
from specfile import Z80Snapshot  # noqa: E402


def check(title, world):
    path = f"build/g1/world{world}.z80"
    live = Z80Snapshot(open(path, "rb").read())
    lm, pm = live.view64(), world_memory(title, world)
    for a in (0xBA17, 0xBA18, 0xB952, 0xD4A2):
        pm[a] = lm[a]
    window, facing, count = word(lm, 0xBA17), lm[0xB952], lm[0xD4A2]
    pending = (live.hl - 0xF000) // 32 if 0xE989 <= live.pc < 0xEBB0 else None
    lines = [n for n in range(128) if n != pending]
    real = lm[0xF000:0x10000]

    def score():
        buf = checkgfx.picture(pm, window, facing, count)
        if pending is not None:
            before = checkgfx.picture(pm, window, facing, count + 1)
            buf = buf[:32 * (pending + 1)] + before[32 * (pending + 1):]
        return sum(buf[n * 32 + x] == real[n * 32 + x] for n in lines for x in range(1, 31))

    pristine = score()
    cells = [a for a in range(window - 16, window + 128) if pm[a] != lm[a]]
    table = word(pm, 0xDE2F)
    pictures = sorted({(a - table) // 32 for a in range(table, table + 32 * 131) if pm[a] != lm[a]})
    for a in cells:
        pm[a] = lm[a]
    for k in pictures:
        pm[table + 32 * k:table + 32 * (k + 1)] = lm[table + 32 * k:table + 32 * (k + 1)]
    return pristine, score(), len(lines) * 30, len(cells), len(pictures)


def main():
    missing = [f"build/g1/world{w}.z80" for w in WORLDS if not os.path.exists(f"build/g1/world{w}.z80")]
    if missing:
        sys.exit(f"D3 check-worlds: run `make rzx-end` first (missing {', '.join(missing)})")
    title = Z80Snapshot(open("data/athena128.z80", "rb").read())
    fails = []
    for world in WORLDS:
        pristine, patched, total, cells, pictures = check(title, world)
        ok = patched == total
        print(f"  {'ok  ' if ok else 'FAIL'}  world {world}: buffer from the pristine data {pristine:,}/{total:,}; "
              f"with {cells} map cells and {pictures} cell pictures changed in play: {patched:,}/{total:,}")
        if not ok:
            fails.append(str(world))
    if fails:
        sys.exit(f"D3 check-worlds FAILED: worlds {', '.join(fails)}")
    print("D3 check-worlds passed: every world's play area is its pristine map, plus the changes play made")


if __name__ == "__main__":
    main()
