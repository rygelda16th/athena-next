#!/usr/bin/env python3
"""Render each world's whole map from YOUR snapshot (D3).

    python3 tools/render_world.py            # build/worlds/worldN.png, worldN-parts.png

For each world it builds the 64K memory the game has after #R$B8C3 and #R$BDC0 set that
world up - the world bank copied to $7660-$B65F, bank 1's 85 bytes at $B660, the
background and item block codes at $CECA and $DE09, the cell table address at $DE2F and
the two replaced cell pictures for block codes $79 and $7A ($BE27-$BE40), all read from
the code in the snapshot - and draws every map column of eight cells exactly as #R$DDFD
does, in the play-area colour from header byte 19:

  worldN.png        the whole map as one strip: column c at x = 16c, cell row r at y = 16r
  worldN-parts.png  the upper part (the first 208 columns) above the lower part, aligned
                    so that a lower column sits under the upper column

The pictures hold the game's graphics: they stay in build/, never commit or publish them.
`make check-worlds` (tools/checkworlds.py) proves the format against the live snapshots.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from specfile import Z80Snapshot  # noqa: E402
from zxscreen import PALETTE, write_png  # noqa: E402

OUT = "build/worlds"

# world -> (bank, bank index for $B8BB, header address)
WORLDS = {1: (3, 0, 0x7660), 2: (3, 0, 0x7677), 3: (4, 1, 0x7660), 4: (4, 1, 0x7677),
          5: (6, 2, 0x7660), 6: (6, 2, 0x7677), 7: (7, 3, 0x7660)}
PART = 0x0680           # $D43A: the lower part is $0680 bytes (208 columns) on


def word(m, a):
    return m[a] | m[a + 1] << 8


def world_memory(snap, world):
    """The 64K after world set-up for this world (#R$B8C3, #R$BDC0 $BDE7-$BE40)."""
    bank, index, header = WORLDS[world]
    m = bytearray(snap.view64())
    m[0x7660:0xB660] = snap.bank(bank)
    extra = m[0xB8BB + index]                       # #R$B8BB
    m[0xB660:0xB6B5] = snap.bank(1)[extra:extra + 0x55]
    second = header == 0x7677
    m[0xCECA] = m[0xBDFE] if second else m[0xBDED]  # LD A,$82 / LD A,$93
    m[0xDE09] = m[0xBDEB] + (1 if second else 0)    # LD B,$C7 then INC B
    iy = word(m, 0xBE09) if second else word(m, 0xBDF7)   # LD IY,$0440 / $0420
    table = word(m, 0x7665)
    m[0xDE2F:0xDE31] = bytes((table & 0xFF, table >> 8))
    src = table + iy
    dst = table + word(m, 0xBE33)                   # LD DE,$0320: block $79
    for n in range(64):                             # two LDIRs of 32 from the same source
        m[dst + n] = m[src + n % 32]
    return m


def map_extent(m, world):
    header = WORLDS[world][2]
    return word(m, header + 1), word(m, header + 3)


def block_index(m, code):
    """#R$DDFD: which entry of the cell table a map cell code draws."""
    if code >= 0x79:
        a = code
    elif code >= 0x60:
        a = m[0xDE09]
    elif code >= 0x46 or code < 0x10:
        a = m[0xCECA]
    elif code >= 0x2E:
        a = code + 0x32
    else:
        a = code
    return (a - 0x60) & 0xFF


def cell_bits(m, code):
    """16 rows of 16 bits for one map code."""
    src = word(m, 0xDE2F) + 32 * block_index(m, code)
    return [m[(src + 2 * y) & 0xFFFF] << 8 | m[(src + 2 * y + 1) & 0xFFFF] for y in range(16)]


def render_columns(m, start, columns, bits_out=None):
    """Ink/paper bit rows (128 x 16*columns) for `columns` map columns from `start`."""
    rows = [[0] * (16 * columns) for _ in range(128)]
    cache = {}
    for c in range(columns):
        for r in range(8):
            code = m[start + 8 * c + r]
            if code not in cache:
                cache[code] = cell_bits(m, code)
            for y, v in enumerate(cache[code]):
                row = rows[16 * r + y]
                for x in range(16):
                    row[16 * c + x] = v >> (15 - x) & 1
    return rows


def colours(m, world):
    attr = m[WORLDS[world][2] + 19]                 # $BEC4: header byte 19
    bright = 8 if attr & 0x40 else 0
    return PALETTE[(attr & 7) + bright], PALETTE[((attr >> 3) & 7) + bright]


def to_rgb(bitrows, ink, paper):
    return [[ink if b else paper for b in row] for row in bitrows]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else OUT
    os.makedirs(out, exist_ok=True)
    snap = Z80Snapshot(open("data/athena128.z80", "rb").read())
    for world in WORLDS:
        m = world_memory(snap, world)
        start, length = map_extent(m, world)
        ink, paper = colours(m, world)
        cols = length // 8
        write_png(os.path.join(out, f"world{world}.png"), to_rgb(render_columns(m, start, cols), ink, paper))
        upper = cols if world == 7 else min(cols, PART // 8)   # world 7 is one part (D3)
        lower = cols - upper
        rows = to_rgb(render_columns(m, start, upper), ink, paper) + [[(40, 40, 40)] * (16 * upper) for _ in range(4)]
        for row in to_rgb(render_columns(m, start + PART, lower) if lower else [], ink, paper):
            rows.append(row + [(40, 40, 40)] * (16 * upper - len(row)))
        write_png(os.path.join(out, f"world{world}-parts.png"), rows)
        print(f"world {world}: map ${start:04X}-${start + length - 1:04X}, {cols} columns ({upper} upper, {lower} lower)")
    print(f"render_world: {len(WORLDS)} worlds in {out}/")


if __name__ == "__main__":
    main()
