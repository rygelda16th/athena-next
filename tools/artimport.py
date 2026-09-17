#!/usr/bin/env python3
"""H: David's hand-made art, checked and brought into the build.

    python3 tools/artimport.py          (make check-art; the art stays in data/art)

David draws the scenery cells (and any enemy the arcade has no counterpart for) as PNGs
in `data/art/`, which git ignores; nothing of his art is committed until he decides
(docs/art-bible.md). This reads them, checks each against the art bible's limits, and
writes what the build needs:

  data/art/cells/bank<N>/<n>.png        one 16x16 cell of that world bank, <n> its place in
                                       the bank's cell table (0 up), as build/gfx's
                                       bank<N>-cells sheet shows them, left to right
  build/art/cells_bank<N>.json         the checked cells as palette indices, for mkassets
  build/art/sheet-bank<N>.png          a contact sheet of the bank's hand-made cells
                                       beside the recoloured originals, for David to approve

THE LIMITS (docs/art-bible.md): a cell is 16x16 pixels; every colour must be one of the
world's four (paper, ink, highlight, shadow) or a colour of the world's palette that the
build can add - at most PALETTE_ROOM new colours a bank, since Layer 2's palette holds
256 and the port uses 16-19 for the recoloured art; and the picture must be for a cell
the bank has.

With no art in data/art this writes nothing, and the build is the same as without it.
"""
import json
import os
import re
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mkassets                          # noqa: E402

ART = os.environ.get("ART_DIR", "data/art")
OUT = os.environ.get("ART_OUT", "build/art")
PALETTE_ROOM = 200                       # indices 20-219 are free for hand-made colours
FAILS = []


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""), flush=True)
    if not ok:
        FAILS.append(what)


def read_png(path):
    """(width, height, [[(r, g, b)]]) from a PNG written in any of the usual colour types."""
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")
    i, idat, palette, trns = 8, b"", None, None
    width = height = depth = colour = 0
    while i < len(data):
        n = struct.unpack(">I", data[i:i + 4])[0]
        kind, body = data[i + 4:i + 8], data[i + 8:i + 8 + n]
        if kind == b"IHDR":
            width, height, depth, colour = struct.unpack(">IIBB", body[:10])
        elif kind == b"PLTE":
            palette = [tuple(body[k:k + 3]) for k in range(0, len(body), 3)]
        elif kind == b"tRNS":
            trns = body
        elif kind == b"IDAT":
            idat += body
        i += 12 + n
    if depth != 8:
        raise ValueError(f"{path}: {depth} bits a channel; 8 are wanted")
    per = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[colour]
    raw = zlib.decompress(idat)
    stride = width * per
    rows, prev = [], bytearray(stride)
    for y in range(height):
        f = raw[y * (stride + 1)]
        line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for x in range(stride):
            a = line[x - per] if x >= per else 0
            b = prev[x]
            c = prev[x - per] if x >= per else 0
            if f == 1:
                line[x] = (line[x] + a) & 255
            elif f == 2:
                line[x] = (line[x] + b) & 255
            elif f == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        prev = line
        row = []
        for x in range(width):
            px = line[x * per:(x + 1) * per]
            if colour == 3:
                row.append(palette[px[0]])
            elif colour in (0, 4):
                row.append((px[0], px[0], px[0]))
            else:
                row.append(tuple(px[:3]))
        rows.append(row)
    return width, height, rows


def rgb333(c):
    return tuple(round(v * 7 / 255) for v in c)


def sheet(bank, world, art):
    """The bank's hand-made cells beside the recoloured originals, for David to approve."""
    from specfile import Z80Snapshot
    from zxscreen import write_png
    import render_world as rw
    m = rw.world_memory(Z80Snapshot(open("data/athena128.z80", "rb").read()), world)
    table, end = rw.word(m, 0x7665), rw.word(m, 0x7667)
    colours = [tuple(v * 255 // 7 for v in c) for c in art["colours"]]
    rules = [tuple(v * 255 // 7 for v in c) for c in mkassets.RULES[world]]
    places = sorted(int(k) for k in art["cells"])
    rows = [[(30, 30, 30)] * (len(places) * 20) for _ in range(44)]
    for i, place in enumerate(places):
        src = table + 32 * place
        bits = [m[src + 2 * y] << 8 | m[src + 2 * y + 1] for y in range(16)]
        old = mkassets.recolour(bits)
        new = art["cells"][str(place)]
        for y in range(16):
            for x in range(16):
                rows[y + 2][i * 20 + 2 + x] = rules[{16: 0, 17: 1, 18: 2, 19: 3}[old[y * 16 + x]]]
                rows[y + 24][i * 20 + 2 + x] = colours[new[y * 16 + x]]
    write_png(f"{OUT}/sheet-bank{bank}.png", [[p for p in r for _ in range(3)] for r in rows for _ in range(3)])


def main():
    os.makedirs(OUT, exist_ok=True)
    banks = {}
    for bank in sorted(set(mkassets.BANK_OF_WORLD.values())):
        folder = f"{ART}/cells/bank{bank}"
        if not os.path.isdir(folder):
            continue
        world = next(w for w, b in mkassets.BANK_OF_WORLD.items() if b == bank)
        names = sorted(f for f in os.listdir(folder) if f.lower().endswith(".png"))
        cells, colours = {}, []
        for name in names:
            code = re.match(r"(\d{1,3})\D", name)
            if not code:
                check(False, f"bank {bank}: {name} is not named after a cell's place in the table")
                continue
            w, h, rows = read_png(f"{folder}/{name}")
            if (w, h) != (16, 16):
                check(False, f"bank {bank}: {name} is {w}x{h}", "cells are 16x16")
                continue
            indices = []
            for row in rows:
                for px in row:
                    c = rgb333(px)
                    if c not in colours:
                        colours.append(c)
                    indices.append(colours.index(c))
            cells[int(code.group(1))] = indices
        check(len(colours) <= PALETTE_ROOM, f"bank {bank}: {len(colours)} colours in its hand-made cells",
              f"at most {PALETTE_ROOM} fit beside the recoloured art")
        if cells:
            banks[bank] = {"colours": [list(c) for c in colours],
                           "cells": {str(k): v for k, v in cells.items()}}
            json.dump(banks[bank], open(f"{OUT}/cells_bank{bank}.json", "w"))
            check(True, f"bank {bank}: {len(cells)} hand-made cells, {len(colours)} colours",
                  f"world {world}")
            sheet(bank, world, banks[bank])
    if not banks:
        print("  (no hand-made art in data/art: the build is the same without it)")
    if FAILS:
        sys.exit(f"\ncheck-art FAILED: {len(FAILS)} check(s)")
    print("\ncheck-art passed")


if __name__ == "__main__":
    main()
