#!/usr/bin/env python3
"""Export every graphic in Athena as PNG sheets: the reference for the new art.

    python3 tools/extract_gfx.py            # writes build/gfx/*.png and build/gfx/index.html

Reads YOUR files: data/athena128.z80 (graphics used in play, fonts, the two bank 1
screens and the four world banks), build/provenance/tape128.z80 from `make provenance`
(the title graphics, which the start-up code overwrites before the title snapshot) and
build/g2/script-gameover/end.z80 from `make scripts` (the panel labels, which exist only
between the end of a game and the next). Sets whose source file is missing are skipped
and reported. The pictures hold the game's graphics: they stay in build/, never commit
or publish them.

Formats (docs/disassembly.md, D2): "masked" graphics store a mask byte before each
graphic byte, drawn as (screen AND mask) OR graphic; "plain" graphics are one bit a
pixel. Both: bit 7 leftmost, lines top to bottom. In the sheets black is ink, white is
paper and pale blue is where a masked graphic lets the background through.
"""
import html
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from specfile import Z80Snapshot  # noqa: E402
from zxscreen import screen_rgb, write_png  # noqa: E402

OUT = "build/gfx"
TITLE, TAPE, GAMEOVER = "data/athena128.z80", "build/provenance/tape128.z80", "build/g2/script-gameover/end.z80"
INK, PAPER, CLEAR, GAP = (0, 0, 0), (255, 255, 255), (170, 205, 235), (255, 0, 255)

# (file, title, source, parts); a part is (address, bytes per line, lines, count, masked)
M, P = True, False
FIXED = [
    ("5c40-font", "Font, characters $30-$5B (digits, punctuation, capitals)", TITLE, [(0x5C40, 1, 8, 44, P)]),
    ("5da0-player-walk", "Player walking, facing right (PlayerFrame 0-3)", TITLE, [(0x5DA0, 2, 32, 4, M)]),
    ("5fa0-armour-head", "Head armour, levels 1 and 2", TITLE, [(0x5FA0, 2, 16, 2, M)]),
    ("6020-armour-waist", "Waist armour for each walking frame, levels 1 and 2", TITLE, [(0x6020, 2, 8, 8, M)]),
    ("6120-armour-hand", "Piece near the front hand, levels 1 and 2", TITLE, [(0x6120, 2, 8, 2, M)]),
    ("6160-weapons-1-4", "Weapon kinds 1-4, three frames each", TITLE, [(a, 3, 16, 3, M) for a in (0x6160, 0x6280, 0x63A0, 0x64C0)]),
    ("65e0-weapons-5-7", "Weapon kinds 5 (24x16) and 6-7 (24x24), two frames each", TITLE,
     [(0x65E0, 3, 16, 2, M), (0x66A0, 3, 24, 2, M), (0x67C0, 3, 24, 2, M)]),
    ("68e0-chain", "Chain pieces", TITLE, [(0x68E0, 2, 8, 2, M), (0x6920, 2, 16, 1, M)]),
    ("6960-strikes", "Weapon strike graphics", TITLE,
     [(0x6960, 3, 24, 1, M), (0x69F0, 2, 8, 1, M), (0x6A10, 3, 24, 1, M), (0x6AA0, 2, 16, 1, M), (0x6AE0, 4, 16, 1, M), (0x6B60, 2, 16, 1, M)]),
    ("6ba0-explosion", "Explosion frames", TITLE, [(0x6BA0, 2, 16, 4, M)]),
    ("6d60-player-climb", "Player climbing, with head and waist armour", TITLE,
     [(0x6D60, 2, 32, 2, M), (0x6E60, 2, 16, 2, M), (0x6EE0, 2, 8, 2, M)]),
    ("6f20-pieces", "Leg piece and crouch pieces", TITLE, [(0x6F20, 2, 8, 1, M), (0x6F40, 2, 8, 3, M)]),
    ("6fa0-flame-bomb", "Flame and bomb frames", TITLE, [(0x6FA0, 2, 16, 4, M)]),
    ("70a0-flight", "Winged legs and wings, facing right", TITLE, [(0x70A0, 2, 8, 4, M), (0x7120, 2, 16, 4, M)]),
    ("7220-left-facing", "Left-facing copies made at start-up", TITLE,
     [(0x7220, 2, 8, 1, M), (0x7240, 2, 16, 1, M), (0x7280, 3, 24, 1, M), (0x7310, 2, 8, 1, M), (0x7330, 3, 24, 1, M),
      (0x73C0, 2, 16, 1, M), (0x7400, 4, 16, 1, M), (0x7480, 2, 16, 1, M), (0x74C0, 2, 8, 3, M), (0x7520, 2, 16, 4, M)]),
    ("7620-heart", "Heart", TITLE, [(0x7620, 2, 16, 1, M)]),
    ("bab8-panel-pieces", "Fallen player, bar unit and bar end", TITLE, [(0xBAB8, 4, 16, 1, P), (0xBAF8, 2, 8, 1, P), (0xBB08, 2, 8, 1, P)]),
    ("f000-panel-labels", "Panel labels LIFE, STR, POW, HIT (saved after a game ends)", GAMEOVER,
     [(0xF000, 2, 32, 1, P), (0xF040, 2, 24, 1, P), (0xF070, 2, 16, 1, P), (0xF090, 2, 24, 1, P)]),
    ("f5d8-title", "Title: SNK logo, Imagine logo, Athena, ATHENA logo", TAPE,
     [(0xF5D8, 13, 32, 1, P), (0xF778, 13, 40, 1, P), (0xF980, 8, 128, 1, P), (0xFD80, 16, 40, 1, P)]),
]
WORLD_BANKS = {3: "worlds 1 and 2", 4: "worlds 3 and 4", 6: "worlds 5 and 6", 7: "world 7"}


def memory(snap, top=0):
    m = bytearray(65536)
    m[0x4000:0x8000], m[0x8000:0xC000], m[0xC000:] = snap.bank(5), snap.bank(2), snap.bank(top)
    return m


def world_memory(snap, bank):
    """The 64K view with the bank's world copied to $7660, as #R$B8C3 does."""
    m = memory(snap)
    m[0x7660:0xB660] = snap.bank(bank)
    return m


def rows(m, a, wb, lines, masked):
    out = []
    for _ in range(lines):
        r = []
        for i in range(wb):
            mask, g = (m[a + 2 * i], m[a + 2 * i + 1]) if masked else (0, m[a + i])
            for bit in range(7, -1, -1):
                r.append(INK if g >> bit & 1 else CLEAR if mask >> bit & 1 else PAPER)
        out.append(r)
        a += wb * (2 if masked else 1)
    return out


def frames(m, part):
    a, wb, lines, count, masked = part
    step = wb * lines * (2 if masked else 1)
    return [rows(m, a + k * step, wb, lines, masked) for k in range(count)]


def sheet(pics, per_row=16, scale=3):
    """Pictures left to right with a gap, wrapping; magenta marks the gaps."""
    out = []
    for k in range(0, len(pics), per_row):
        grp = pics[k:k + per_row]
        h = max(len(p) for p in grp)
        band = []
        for y in range(h):
            r = []
            for p in grp:
                w = len(p[0])
                r += (p[y] if y < len(p) else [GAP] * w) + [GAP] * 2
            band.append(r)
        out += band + [[GAP] * len(band[0])] * 2
    width = max(len(r) for r in out)
    out = [r + [GAP] * (width - len(r)) for r in out]
    return [[px for px in r for _ in range(scale)] for r in out for _ in range(scale)]


def word(m, a):
    return m[a] | m[a + 1] << 8


def world_sets(m):
    """Map cells, enemy frames (the first half of the frame area: enemies that started on the
    right, facing left - D3) and guardian parts."""
    cells = [rows(m, a, 2, 16, P) for a in range(word(m, 0x7665), word(m, 0x7667), 32)]
    parts = []
    for guard in (word(m, 0x7669), word(m, 0x7680)):    # guardian records of the bank's two world headers
        for s in (0, 8):
            a1, w1, l1, a2, w2, l2 = (word(m, guard + s), m[guard + s + 2], m[guard + s + 3],
                                      word(m, guard + s + 4), m[guard + s + 6], m[guard + s + 7])
            if (0x7696 <= a1 < 0xB660 and w1 in (2, 3, 4) and 0x7696 <= a2 < 0xB660 and w2 in (2, 3, 4)
                    and (a1, w1, l1) not in parts):
                parts += [(a1, w1, l1), (a2, w2, l2)]
    guard_start = min((p[0] for p in parts), default=word(m, 0x7661))
    half = 0x7696 + (guard_start - 0x7696) // 2           # the second half holds the turned frames
    table, templates = word(m, 0x768E), []
    for k in range(16):
        wb, lines, a = m[table + 5 * k], m[table + 5 * k + 1], word(m, table + 5 * k + 2)
        if wb in (2, 3, 4) and 0 < lines <= 48 and 0x7696 <= a < half:
            templates.append((a, wb, lines))
    starts = sorted({t[0] for t in templates} | {half})
    enemies = []
    for a, wb, lines in sorted(set(templates)):
        end = next(s for s in starts if s > a)
        size = wb * lines * 2
        enemies.append([rows(m, a + k * size, wb, lines, M) for k in range(min(8, (end - a) // size))])
    # each guardian frame is a left part and a right part drawn side by side (#R$D513)
    guardians = []
    for left, right in zip(parts[0::2], parts[1::2]):
        a, b = rows(m, *left, M), rows(m, *right, M)
        guardians.append([ra + (b[y] if y < len(b) else [CLEAR] * len(b[0])) for y, ra in enumerate(a)])
    return cells, enemies, guardians


def main():
    os.makedirs(OUT, exist_ok=True)
    snaps, made, skipped = {}, [], []

    def snap(path):
        if path not in snaps:
            snaps[path] = Z80Snapshot(open(path, "rb").read()) if os.path.exists(path) else None
        return snaps[path]

    for name, title, src, parts in FIXED:
        z = snap(src)
        if z is None:
            skipped.append(f"{name} (needs {src})")
            continue
        m = memory(z)
        pics = [f for part in parts for f in frames(m, part)]
        write_png(f"{OUT}/{name}.png", sheet(pics, per_row=11 if name.endswith("font") else 16))
        made.append((name, title, src))

    t = snap(TITLE)
    if t is None:
        sys.exit(f"extract_gfx: {TITLE} is missing - run `make fetch`")
    for off, name, title in ((0x0154, "bank1-ending", "Ending picture (bank 1)"), (0x1C54, "bank1-combat-school", "Combat School advert (bank 1)")):
        write_png(f"{OUT}/{name}.png", screen_rgb(bytes(t.bank(1)[off:off + 6912])))
        made.append((name, title, TITLE))
    for bank, worlds in WORLD_BANKS.items():
        m = world_memory(t, bank)
        cells, enemies, guardians = world_sets(m)
        write_png(f"{OUT}/bank{bank}-cells.png", sheet(cells, per_row=20))
        made.append((f"bank{bank}-cells", f"Map cells, {worlds} ({len(cells)})", TITLE))
        write_png(f"{OUT}/bank{bank}-enemies.png", sheet([f for e in enemies for f in e], per_row=12))
        made.append((f"bank{bank}-enemies", f"Enemy frames, {worlds}, facing left ({sum(len(e) for e in enemies)} frames of {len(enemies)} enemies)", TITLE))
        if guardians:
            write_png(f"{OUT}/bank{bank}-guardian.png", sheet(guardians, per_row=4))
            made.append((f"bank{bank}-guardian", f"Guardian parts, {worlds}", TITLE))

    with open(f"{OUT}/index.html", "w") as f:
        f.write("<!doctype html><title>Athena graphics</title><style>body{font:14px sans-serif;margin:16px}"
                "img{image-rendering:pixelated;max-width:100%;border:1px solid #ccc}h2{font-size:15px}</style>"
                "<h1>Athena graphics</h1><p>From your own files; for local use only.</p>")
        for name, title, src in made:
            f.write(f"<h2>{html.escape(title)}</h2><p><code>{name}.png</code> from <code>{src}</code></p><img src='{name}.png'>")
    print(f"extract_gfx: {len(made)} sheets in {OUT}/ (open {OUT}/index.html)")
    for s in skipped:
        print(f"  skipped {s}")


if __name__ == "__main__":
    main()
