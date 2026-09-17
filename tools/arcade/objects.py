#!/usr/bin/env python3
"""C2: the arcade's characters, assembled from a capture log's sprite tables.

    python3 tools/arcade/objects.py LOG [LOG...]     -> build/c2/objects.json, build/c2/sheet-N.png

Every frame's 50 sprites are placed as MAME draws them (tools/arcade/frame.py); sprites
whose 16x16 squares touch or overlap belong to one character. A character is its tiles
and colour sets relative to its top-left corner, so the same drawing seen anywhere on
screen is one entry. Each distinct character is counted, with the frames it was seen on,
and drawn onto contact sheets in order of how often it appears: the material the mapping
(docs/art-bible.md, "Converted arcade art") is chosen from.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import frame                 # noqa: E402
from arcgfx import Gfx       # noqa: E402

OUT = "build/c2"


def sprite_list(state):
    """[(x, y, tile, colour)] of the visible sprites, as screen positions."""
    _, _, spx, spy = frame.scrolls(state)
    s, out = state.sprites, []
    for offs in range(0, 200, 4):
        tile, attr = s[offs + 1], s[offs + 3]
        sx = spx + 301 - 16 - s[offs + 2] + ((attr & 0x80) << 1)
        sy = -spy + 7 - 16 + s[offs] + ((attr & 0x10) << 4)
        tile |= (attr & 0x40) << 2 | (attr & 0x20) << 4
        sx &= 0x1FF
        sy &= 0x1FF
        if sx > 496:
            sx -= 512
        if sy > 496:
            sy -= 512
        y = sy - frame.Y0
        if -16 < sx < frame.W and -16 < y < frame.H:
            out.append((sx, y, tile, attr & 0x0F))
    return out


def clusters(sprites):
    n = len(sprites)
    parent = list(range(n))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for i in range(n):
        for j in range(i + 1, n):
            if abs(sprites[i][0] - sprites[j][0]) <= 16 and abs(sprites[i][1] - sprites[j][1]) <= 16:
                parent[find(i)] = find(j)
    groups = {}
    for i in range(n):
        groups.setdefault(find(i), []).append(sprites[i])
    return list(groups.values())


def key(group):
    x0, y0 = min(s[0] for s in group), min(s[1] for s in group)
    return tuple(sorted((s[0] - x0, s[1] - y0, s[2], s[3]) for s in group)), (x0, y0)


def main():
    os.makedirs(OUT, exist_ok=True)
    found = {}
    for path in sys.argv[1:]:
        log = open(path, "rb").read()
        state = frame.State()
        try:
            for kind, payload in frame.records(log):
                frame.apply(state, kind, payload)
                if kind == "S":
                    for g in clusters(sprite_list(state)):
                        k, pos = key(g)
                        e = found.setdefault(k, {"count": 0, "first": (os.path.basename(path), state.frame)})
                        e["count"] += 1
        except ValueError:
            pass
    ranked = sorted(found.items(), key=lambda kv: -kv[1]["count"])
    gfx = Gfx()
    index = []
    for n, (k, e) in enumerate(ranked):
        w = max(t[0] for t in k) + 16
        h = max(t[1] for t in k) + 16
        index.append({"id": n, "tiles": [list(t) for t in k], "w": w, "h": h, "count": e["count"],
                      "first": e["first"]})
    json.dump(index, open(f"{OUT}/objects.json", "w"))
    # contact sheets: 12 characters a row, each in a 64x64 box, 60 a sheet
    from zxscreen import write_png
    for sheet in range(0, min(len(index), 600), 60):
        rows = [[(40, 40, 40)] * (12 * 68) for _ in range(5 * 68)]
        for i, obj in enumerate(index[sheet:sheet + 60]):
            bx, by = (i % 12) * 68, (i // 12) * 68
            for dx, dy, tile, colour in obj["tiles"]:
                pic = gfx.sprite(tile)
                for y in range(16):
                    for x in range(16):
                        v = pic[y][x]
                        X, Y = bx + dx + x, by + dy + y
                        if v == 7 or X >= bx + 64 or Y >= by + 64:
                            continue
                        rows[Y][X] = (20, 20, 20) if v == 6 else gfx.palette[colour * 8 + v]
        write_png(f"{OUT}/sheet-{sheet // 60:02d}.png", [[p for p in r for _ in range(2)] for r in rows for _ in range(2)])
    print(f"objects: {len(index)} distinct characters from {len(sys.argv) - 1} logs -> {OUT}/")


if __name__ == "__main__":
    main()
