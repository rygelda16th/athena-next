#!/usr/bin/env python3
"""C2: the arcade art the enhanced port shows, built from tools/arcade/mapping.json and
the player's own arcade set.

    python3 tools/arcade/mkmapping.py        (make arcade-assets; needs data/arcade/athena.zip)

Writes, all under build/ and never committed:

  build/assets/arcade_bankN_map.bin    one 8K page per world bank (3, 4, 6, 7): the palette
                                       blocks, the keys and the frames the engine looks up
  build/assets/arcade_bankN_pat.bin    the bank's 4-bit sprite images, 128 bytes each
  build/assets/arcade.asm              the pages they load into
  build/assets/arcade_model.json       the same tables for tools/checkmapping.py
  build/c2/mapping/index.html          the approval sheet: each Spectrum picture beside the
                                       arcade frames that replace it (local, never published)

THE MAP PAGE (paged in at $4000; offsets below are from $4000, words little-endian):
  +0 "AM", +2 images, +3 keys, +4 palette blocks, then for each block: its number and
  16 colours as NextReg $44 takes them (2 bytes each); then the keys, 4 bytes each: the
  key and the address of its entry; then entries and frames.
  ENTRY: flags (bit 0: only while the player is shown in arcade art), frames, frames
  a pass, value source (a word: 0 the engine's pass count, 1 the player's pose value,
  else a game address), then a word per frame: the address of the frame.
  FRAME: pieces, then 4 bytes each: dx, dy (signed), image number (4-bit pattern
  64-127... counted down from 127), palette offset (block x 16).

KEYS. A Spectrum picture drawn by $EB1C/$EB72/$EBB0 is keyed by its address; a weapon
drawn from the mirrored copy at $EE60 by WeaponGfxAddr plus its offset, with bit 15
set. The player is keyed by facing (bit 13), weapon kind (bits 8-10) and pose
(src/next/sprites.asm, player_key).

IMAGES AND COLOURS. The arcade's 3-bit pixels become 4-bit: 7 (transparent) and 3 swap,
so transparency is index 3 in every block, the low nibble of the transparent index $E3.
Each colour set gets a palette block other than 0 (the recoloured Spectrum sprites) and
14 ($E3 itself); value 6, the arcade's shadow, becomes the mapping's shadow colour.
"""
import base64
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from arcgfx import Gfx                      # noqa: E402

MAPPING = "tools/arcade/mapping.json"
OUT = "build/assets"
SHEET = "build/c2/mapping"
BANKS = (3, 4, 6, 7)
WORLD_OF_BANK = {3: 1, 4: 3, 6: 5, 7: 7}
ARC_PAGE0 = 96                              # 8K pages 96-107: bank n's map page, then two image pages
PAGES_PER_BANK = 3
POSES = {"walk": 0, "jump": 1, "fall": 2, "crouch": 3, "blow": 4, "kick": 5}
WEAPON_GFX = {1: 0x6160, 2: 0x6280, 3: 0x63A0, 4: 0x64C0, 5: 0x65E0, 6: 0x66A0, 7: 0x67C0}
WEAPON_FRAMES = {1: 3, 2: 3, 3: 3, 4: 3, 5: 2, 6: 3, 7: 3}
BLOCKS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15]
FLAG_WITH_PLAYER = 1


def rgb333(c):
    return tuple((v * 7 + 127) // 255 for v in c)


def nextreg44(c3):
    r, g, b = c3
    return bytes([r << 5 | g << 2 | b >> 1, b & 1])


def value_source(v):
    if v in ("passes", "none"):
        return 0
    if v.startswith("0x"):
        return int(v, 16)
    return 1                                # a player value the engine computes


class Model:
    """The mapping expanded: every key's entry, as pieces with tile numbers."""

    def __init__(self, mapping, bank=None):
        self.m = mapping
        self.bank = bank
        self.figures = {k: v for k, v in mapping["figures"].items() if k != "about"}
        self.entries = {}                   # key -> dict(flags, per_pass, value, frames=[[piece]], name)

    def figure(self, name, left):
        out = []
        for dx, dy, tile, colour in self.figures[name]:
            out.append((-dx if left else dx, dy, tile + 1 if left else tile, colour))
        return out

    def build(self):
        player = self.m["player"]
        weapons = {int(k): v for k, v in player["weapons"].items() if k != "about"}
        for facing in (0, 1):
            for kind in range(8):
                w = weapons.get(kind, {})
                for pose, spec in player["poses"].items():
                    frames = []
                    for name in spec["frames"]:
                        pieces = self.figure(name, facing)
                        if "with" in w:
                            extra = w["with"].get(name, w.get("default"))
                            if extra:
                                pieces += self.figure(extra, facing)
                        frames.append(pieces)
                    key = facing << 13 | kind << 8 | POSES[pose]
                    self.entries[key] = dict(name=f"player {pose}, weapon kind {kind}, facing {'left' if facing else 'right'}",
                                             flags=0, per_pass=spec["per_pass"], value=value_source(spec["value"]),
                                             frames=frames, spectrum=("player", pose, kind))
        for kind, w in weapons.items():
            if not w.get("hide_spectrum"):
                continue
            for i in range(WEAPON_FRAMES[kind]):
                address = WEAPON_GFX[kind] + 96 * i
                for key in (address, address | 0x8000):
                    self.entries[key] = dict(name=f"weapon kind {kind} picture {i} (hidden)", flags=FLAG_WITH_PLAYER,
                                             per_pass=1, value=0, frames=[[]], spectrum=("weapon", kind, i))
        draws = list(self.m["draws"].items())
        if self.bank is not None:
            draws += list(self.m.get("bank_draws", {}).get(str(self.bank), {}).items())
        for name, d in draws:
            if name == "about":
                continue
            key = int(d["address"], 16)
            width, lines = d.get("size", [16, 16])
            self.entries[key] = dict(name=name, flags=0, per_pass=d["per_pass"], value=value_source(d["value"]),
                                     frames=[self.figure(f, False) for f in d["frames"]],
                                     spectrum=("draw", key, width, lines))
        return self

    def tiles(self):
        seen = []
        for key in sorted(self.entries):
            for frame in self.entries[key]["frames"]:
                for _, _, tile, _ in frame:
                    if tile not in seen:
                        seen.append(tile)
        return seen

    def colours(self):
        seen = []
        for key in sorted(self.entries):
            for frame in self.entries[key]["frames"]:
                for _, _, _, colour in frame:
                    if colour not in seen:
                        seen.append(colour)
        return seen


def image4(gfx, tile):
    out = bytearray()
    pic = gfx.sprite(tile)
    for y in range(16):
        for x in range(0, 16, 2):
            a, b = ({7: 3, 3: 7}.get(pic[y][x], pic[y][x]), {7: 3, 3: 7}.get(pic[y][x + 1], pic[y][x + 1]))
            out.append(a << 4 | b)
    return bytes(out)


def map_page(model, gfx, pattern_of, block_of, shadow):
    page = bytearray(b"AM")
    keys = sorted(model.entries)
    page += bytes([len(pattern_of), len(keys), len(block_of)])
    for colour, block in block_of.items():
        page.append(block)
        for i in range(16):
            o = {3: 7, 7: 3}.get(i, i)
            if i >= 8 or o == 7:
                c = (0, 0, 0)
            elif o == 6:
                c = tuple(shadow)
            else:
                c = rgb333(gfx.palette[colour * 8 + o])
            page += nextreg44(c)
    table_at = len(page)
    page += bytes(4 * len(keys))
    frame_at = {}
    entry_at = {}
    for key in keys:
        e = model.entries[key]
        for frame in e["frames"]:
            body = bytes([len(frame)]) + b"".join(
                bytes([dx & 255, dy & 255, pattern_of[tile], block_of[colour] << 4]) for dx, dy, tile, colour in frame)
            if body not in frame_at:
                frame_at[body] = len(page)
                page += body
    for n, key in enumerate(keys):
        e = model.entries[key]
        at = len(page)
        entry_at[key] = at
        page += bytes([e["flags"], len(e["frames"]), e["per_pass"], e["value"] & 255, e["value"] >> 8])
        for frame in e["frames"]:
            body = bytes([len(frame)]) + b"".join(
                bytes([dx & 255, dy & 255, pattern_of[tile], block_of[colour] << 4]) for dx, dy, tile, colour in frame)
            page += (0x4000 + frame_at[body]).to_bytes(2, "little")
        page[table_at + 4 * n:table_at + 4 * n + 4] = key.to_bytes(2, "little") + (0x4000 + at).to_bytes(2, "little")
    if len(page) > 0x2000:
        sys.exit(f"mkmapping: the map page is {len(page)} bytes, over 8K")
    return bytes(page)


def spectrum_picture(mem, spectrum):
    """(width, rows of 0 clear / 1 paper / 2 ink) for the approval sheet."""
    kind = spectrum[0]
    if kind == "player":
        pose = spectrum[1]
        frame = {"walk": 0, "jump": 1, "fall": 1, "crouch": 0, "blow": 3, "kick": 0}[pose]
        address, width, lines = 0x5DA0 + 128 * frame, 16, 32
    elif kind == "weapon":
        address, width, lines = WEAPON_GFX[spectrum[1]] + 96 * spectrum[2], 24, 16
    else:
        address, width, lines = spectrum[1], spectrum[2], spectrum[3]
    wb = width // 8
    rows = []
    for y in range(lines):
        row = []
        for b in range(wb):
            mask, g = mem[address + (y * wb + b) * 2], mem[address + (y * wb + b) * 2 + 1]
            for bit in range(7, -1, -1):
                row.append(2 if g >> bit & 1 else (0 if mask >> bit & 1 else 1))
        rows.append(row)
    return rows


def sheet(models, gfx, mems):
    from zxscreen import write_png
    os.makedirs(SHEET, exist_ok=True)
    html = ["<!doctype html><title>Athena arcade mapping</title><style>body{background:#333;color:#eee;"
            "font:14px sans-serif}img{image-rendering:pixelated;vertical-align:middle;margin:4px}"
            "td{padding:4px 8px;border-bottom:1px solid #555}</style>",
            f"<h1>Arcade mapping ({models[BANKS[0]].m['status']})</h1><p>Local only: built from your own files.</p><table>"]
    shown = set()
    rows = [(bank, key, models[bank]) for bank in BANKS for key in sorted(models[bank].entries)]
    for bank, key, model in rows:
        e = model.entries[key]
        mem = mems[bank]
        if e["spectrum"][0] == "player" and (e["spectrum"][2] not in (0, 3) or key >> 13):
            continue                        # one weapon-less and one club set, facing right
        sig = (e["name"], key) if bank_specific(model.m, e) else (e["name"], key, "all")
        if not bank_specific(model.m, e):
            sig = (e["name"], key)
        if sig in shown:
            continue
        shown.add(sig)
        spec = spectrum_picture(mem, e["spectrum"])
        colours = {0: (40, 40, 40), 1: (90, 110, 90), 2: (220, 220, 160)}
        pics = [[[colours[v] for v in row] for row in spec]]
        for frame in e["frames"]:
            box = [[(40, 40, 40)] * 48 for _ in range(48)]
            for dx, dy, tile, colour in frame:
                pic = gfx.sprite(tile)
                for y in range(16):
                    for x in range(16):
                        v = pic[y][x]
                        X, Y = dx + x + 12, dy + y + 8
                        if v != 7 and 0 <= X < 48 and 0 <= Y < 48:
                            box[Y][X] = tuple(shadow_rgb(model)) if v == 6 else gfx.palette[colour * 8 + v]
            pics.append(box)
        cells = []
        for n, p in enumerate(pics):
            path = f"{SHEET}/b{bank}-k{key:04x}-{n}.png"
            write_png(path, [[px for px in r for _ in range(3)] for r in p for _ in range(3)])
            data = base64.b64encode(open(path, "rb").read()).decode()
            os.remove(path)
            cells.append(f'<img src="data:image/png;base64,{data}">')
        where = f"bank {bank}, " if bank_specific(model.m, e) else ""
        html.append(f"<tr><td>{where}{e['name']}<br>key ${key:04X}</td><td>{cells[0]}</td><td>{''.join(cells[1:])}</td></tr>")
    html.append("</table><h2>Left on Spectrum art</h2><ul>")
    for state, why in models[BANKS[0]].m["fallback"].items():
        if state != "about":
            html.append(f"<li>{state}: {why}</li>")
    html.append("</ul>")
    open(f"{SHEET}/index.html", "w").write("\n".join(html))


def bank_specific(m, e):
    return any(e["name"] == n for d in m.get("bank_draws", {}).values() if isinstance(d, dict) for n in d)


def shadow_rgb(model):
    return [v * 255 // 7 for v in model.m["shadow"]]


def main():
    mapping = json.load(open(MAPPING))
    gfx = Gfx()
    os.makedirs(OUT, exist_ok=True)
    lines = ["; Generated by tools/arcade/mkmapping.py from the player's own arcade set. Not committed.",
             f"ARC_PAGE0 EQU {ARC_PAGE0}"]
    models = {}
    for n, bank in enumerate(BANKS):
        model = Model(mapping, bank).build()
        models[bank] = model
        page, images, tiles, colours = bank_pages(model, gfx, mapping)
        open(f"{OUT}/arcade_bank{bank}_map.bin", "wb").write(page)
        open(f"{OUT}/arcade_bank{bank}_pat.bin", "wb").write(images)
        lines += [f"ARC_BANK{bank}_MAP EQU {ARC_PAGE0 + n * PAGES_PER_BANK}",
                  f"ARC_BANK{bank}_PAT EQU {ARC_PAGE0 + n * PAGES_PER_BANK + 1}"]
        print(f"mkmapping: bank {bank}: {len(model.entries)} keys, {len(tiles)} images, {len(colours)} colour sets, "
              f"map page {len(page)} bytes")
    open(f"{OUT}/arcade.asm", "w").write("\n".join(lines) + "\n")
    from specfile import Z80Snapshot
    import render_world as rw
    snap = Z80Snapshot(open("data/athena128.z80", "rb").read())
    sheet(models, gfx, {bank: rw.world_memory(snap, WORLD_OF_BANK[bank]) for bank in BANKS})
    print(f"mkmapping: -> {OUT}/arcade_*; sheet {SHEET}/index.html")


def bank_pages(model, gfx, mapping):
    tiles, colours = model.tiles(), model.colours()
    if len(tiles) > 120:
        sys.exit(f"mkmapping: {len(tiles)} images; at most 120 fit beside the recoloured sprites")
    if len(colours) > len(BLOCKS):
        sys.exit(f"mkmapping: {len(colours)} colour sets; at most {len(BLOCKS)} blocks")
    pattern_of = {tile: 127 - n for n, tile in enumerate(tiles)}
    block_of = {colour: BLOCKS[n] for n, colour in enumerate(colours)}
    page = map_page(model, gfx, pattern_of, block_of, mapping["shadow"])
    images = b"".join(image4(gfx, t) for t in tiles)
    if len(images) > 0x4000:
        sys.exit("mkmapping: the images are over two pages")
    return page, images, tiles, colours


if __name__ == "__main__":
    main()
