#!/usr/bin/env python3
"""Gate C2 (and C3): the arcade mapping is complete, built as it says, and shown in the game.

    make check-mapping     (inside the container; needs the player's arcade set)

Without the emulator:
  - every state in the art bible's tables A-C (docs/art-bible.md) is either mapped
    (tools/arcade/mapping.json "states") or listed as left on Spectrum art ("fallback");
  - every figure names real arcade tiles (0-1023, not blank) and colour sets (0-15), and
    every pose, weapon and draw names figures that exist;
  - each world bank's map page decodes to exactly the mapping expanded (every key, frame,
    offset, colour block) and its images are the arcade tiles with 7 and 3 swapped;
  - the approval sheet (build/c2/mapping/index.html) is built from this mapping.

In the emulator, the 28 MHz oracle build with -DARCADE replays the recording; every
SAMPLE_EVERY seconds the sprite check (tools/checksprites.py) holds a pass head and
compares every hardware sprite with what the page says the object shows: an arcade
object's pieces (place, colour block, 4-bit image) or, where the mapping has nothing,
the recoloured Spectrum tiles. It passes when every sample matches, the arcade player
and at least one mapped draw were seen, and the oracle still reaches the end.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "arcade"))
import checksprites                      # noqa: E402

NEX = os.environ.get("NEX", "build/g3/athena-oracle-28-arcade.nex")
FAILS = []
POSES = {"walk": 0, "jump": 1, "fall": 2, "crouch": 3, "blow": 4, "kick": 5}


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""), flush=True)
    if not ok:
        FAILS.append(what)


def bible_states():
    """Every state of the art bible's tables A-E, as the mapping names them: A-C by the
    first cell of each row; D as "D bank N type T"; E as "E bank N guardian"; and "items"."""
    text = open("docs/art-bible.md").read()
    states = []
    for table in ("A", "B", "C", "D", "E"):
        body = re.search(rf"^### {table}\. .*?\n(.*?)(?=^### )", text, re.S | re.M).group(1)
        bank = None
        for line in body.splitlines():
            if not line.startswith("| ") or line.startswith("| Asset") or line.startswith("| Bank") \
                    or line.startswith("|---"):
                continue
            cells = [c.strip().replace("**", "") for c in line.split("|")[1:-1]]
            if table in "ABC":
                name = re.sub(r"\s*\(.*?\)", "", cells[0]).strip()
                name = re.sub(r",? held$", "", name)
                for part in name.split(", "):
                    states.append(f"{table} {part}".lower())
            elif table == "D":
                bank = cells[0].split()[0] if cells[0] else bank
                states.append(f"D bank {bank} type {cells[1]}".lower())
            else:
                m = re.match(r"(\d)(, (first|final) guardian)?", cells[0])
                states.append(f"E bank {m.group(1)} {m.group(3) + ' ' if m.group(3) else ''}guardian".lower())
    return states + ["items"]


def covered_by(state, names):
    words = state.split()
    return any(" ".join(words[:k]) in names for k in range(1, len(words) + 1))


class Page:
    """A map page and its images, decoded."""

    def __init__(self, page, images):
        assert page[:2] == b"AM"
        self.nimages, nkeys, nblocks = page[2], page[3], page[4]
        at = 5
        self.blocks = {}
        for _ in range(nblocks):
            self.blocks[page[at]] = page[at + 1:at + 33]
            at += 33
        self.entries = {}
        for n in range(nkeys):
            key = page[at + 4 * n] | page[at + 4 * n + 1] << 8
            addr = page[at + 4 * n + 2] | page[at + 4 * n + 3] << 8
            e = addr - 0x4000
            flags, frames, per = page[e], page[e + 1], page[e + 2]
            value = page[e + 3] | page[e + 4] << 8
            fl = []
            for f in range(frames):
                fa = (page[e + 5 + 2 * f] | page[e + 6 + 2 * f] << 8) - 0x4000
                pieces = []
                for p in range(page[fa]):
                    dx, dy, img, pal = page[fa + 1 + 4 * p:fa + 5 + 4 * p]
                    pieces.append((dx - 256 if dx > 127 else dx, dy - 256 if dy > 127 else dy, img, pal))
                fl.append(pieces)
            self.entries[key] = dict(addr=addr, flags=flags, per=per, value=value, frames=fl)
        self.images = {127 - i: images[128 * i:128 * i + 128] for i in range(self.nimages)}


BANK_OF_WORLD = {1: 3, 2: 3, 3: 4, 4: 4, 5: 6, 6: 6, 7: 7}


class Arcade:
    """The arcade model the sprite check compares the engine with: the page of the world
    being played."""

    def __init__(self, pages):
        self.pages = pages
        self.player_seen = 0
        self.draws_seen = 0

    @property
    def page(self):
        return self.pages[BANK_OF_WORLD.get(self.world, 3)]

    def set_world(self, m):
        self.world = m.mem(0xBA33, 1)[0]

    def _pieces(self, m, e, pose_value):
        src = e["value"]
        if src == 0:
            value = m.eng(0x19, 1)[0]
        elif src == 1:
            value = pose_value
        else:
            value = m.mem(src, 1)[0]
        n = (value * e["per"] + e["per"] - 1) % len(e["frames"])     # held: the pass is over
        return [(dx, dy, img, pal, self.page.images[img]) for dx, dy, img, pal in e["frames"][n]]

    def player(self, m):
        self.set_world(m)
        g = lambda a: m.mem(a, 1)[0]
        if g(0xB94A) | g(0xBA27) | g(0xBA24) | g(0xBA25) | g(0xBA26) | g(0xCE4B):
            return None
        kind = g(0xBA2C) & 7
        base = (0x2000 if g(0xB952) else 0) | kind << 8
        blow = POSES["kick"] if kind == 5 else POSES["blow"] if 1 <= kind <= 4 else None
        poses = []
        if g(0xC95B) and blow is not None:
            poses.append((blow, 0))
        else:
            if blow is not None:                    # the second pass of a blow looks the same
                poses.append((blow, 1))
            jc = g(0xB953)
            if g(0xBA07):
                poses.append((POSES["crouch"], 0))
            elif jc:
                poses.append((POSES["jump"], 0 if jc >= 5 else 4 - jc))
            elif g(0xB954):
                poses.append((POSES["fall"], 0))
            else:
                poses.append((POSES["walk"], 2 * (g(0xB949) & 3) + (g(0xB950) & 1)))
        out = []
        for pose, value in poses:
            e = self.page.entries.get(base | pose)
            if e:
                out.append((e["addr"], self._pieces(m, e, value)))
        if out:
            self.player_seen += 1
        return out or None

    def draw(self, m, gfx, arc_player):
        self.set_world(m)
        key = gfx
        if 0xEE60 <= gfx < 0xEF80:
            w = m.mem(0xBA2E, 2)
            key = ((w[0] | w[1] << 8) + gfx - 0xEE60) | 0x8000
        e = self.page.entries.get(key)
        if not e or (e["flags"] & 1 and not arc_player):
            return None
        self.draws_seen += 1
        return [(e["addr"], self._pieces(m, e, 0))]

    def report(self, check):
        check(self.player_seen > 0, "the arcade player was shown", f"{self.player_seen} samples")
        check(self.draws_seen > 0, "mapped Spectrum pictures were shown in arcade art", f"{self.draws_seen} objects")


def static_checks():
    import mkmapping
    from arcgfx import Gfx
    mapping = json.load(open(mkmapping.MAPPING))
    states = bible_states()
    covered = {k.lower() for k in mapping["states"] if k != "about"} | \
              {k.lower() for k in mapping["fallback"] if k != "about"}
    missing = [s for s in states if not covered_by(s, covered)]
    extra = [c for c in covered if not any(s == c or s.startswith(c + " ") for s in states)]
    check(not missing and not extra, f"all {len(states)} states of tables A-E and the items are mapped or left on Spectrum art",
          f"missing {missing}, unknown {extra}" if missing or extra else "")
    gfx = Gfx()
    figures = {k: v for k, v in mapping["figures"].items() if k != "about"}
    player = set(n for spec in mapping["player"]["poses"].values() for n in spec["frames"])
    for kind, w in mapping["player"]["weapons"].items():
        if kind != "about":
            player |= set(w.get("with", {}).values()) | ({w["default"]} if "default" in w else set())
    blank = lambda t: all(v == 7 for row in gfx.sprite(t) for v in row)
    bad = []
    for name, pieces in figures.items():
        for dx, dy, tile, colour in pieces:
            if not 0 <= tile < 1023 or not 0 <= colour < 16:
                bad.append(f"{name}: tile {tile} set {colour}")
            elif blank(tile) or (name in player and blank(tile + 1)):
                bad.append(f"{name}: tile {tile} (or, for the player, its left-facing {tile + 1}) is blank")
    names = []
    for pose, spec in mapping["player"]["poses"].items():
        if pose not in POSES:
            bad.append(f"pose {pose} is not one the engine knows")
        names += spec["frames"]
    for kind, w in mapping["player"]["weapons"].items():
        if kind != "about":
            names += list(w.get("with", {}).keys()) + list(w.get("with", {}).values()) + \
                ([w["default"]] if "default" in w else [])
    for name, d in mapping["draws"].items():
        if name != "about":
            names += d["frames"]
    bad += [f"no figure {n}" for n in sorted(set(names)) if n not in figures]
    check(not bad, "every figure names real, non-blank arcade tiles and colour sets", "; ".join(bad[:5]))
    pages = {}
    for bank in mkmapping.BANKS:
        model = mkmapping.Model(mapping, bank).build()
        tiles = model.tiles()
        path = f"{mkmapping.OUT}/arcade_bank{bank}_map.bin"
        if not os.path.exists(path) or os.path.getmtime(path) < os.path.getmtime(mkmapping.MAPPING):
            check(False, f"bank {bank}'s map page is built from this mapping", "run make arcade-assets")
            continue
        page = Page(open(path, "rb").read(), open(f"{mkmapping.OUT}/arcade_bank{bank}_pat.bin", "rb").read())
        pages[bank] = page
        wrong = []
        if set(page.entries) != set(model.entries):
            wrong.append(f"keys differ: {len(page.entries)} vs {len(model.entries)}")
        for key, e in model.entries.items():
            p = page.entries.get(key)
            if not p:
                continue
            if (p["flags"], p["per"], p["value"]) != (e["flags"], e["per_pass"], e["value"]):
                wrong.append(f"key ${key:04X} header")
            want = [[(dx, dy, tile, colour) for dx, dy, tile, colour in f] for f in e["frames"]]
            if len(want) != len(p["frames"]):
                wrong.append(f"key ${key:04X} frames")
                continue
            for wf, pf in zip(want, p["frames"]):
                if len(wf) != len(pf):
                    wrong.append(f"key ${key:04X} pieces")
                    continue
                for (dx, dy, tile, colour), (pdx, pdy, img, pal) in zip(wf, pf):
                    if (dx, dy) != (pdx, pdy) or page.images.get(img) != mkmapping.image4(gfx, tile):
                        wrong.append(f"key ${key:04X} tile {tile}")
                    block = pal >> 4
                    if block in (0, 14) or page.blocks.get(block) is None:
                        wrong.append(f"key ${key:04X} block {block}")
                    else:
                        cols = page.blocks[block]
                        for i in range(8):
                            o = {3: 7, 7: 3}.get(i, i)
                            if o in (6, 7):
                                continue
                            c = mkmapping.nextreg44(mkmapping.rgb333(gfx.palette[colour * 8 + o]))
                            if cols[2 * i:2 * i + 2] != c:
                                wrong.append(f"key ${key:04X} set {colour} colour {o}")
                                break
        check(not wrong, f"bank {bank}'s map page is the mapping, tile for tile and colour for colour",
              f"{len(model.entries)} keys, {len(tiles)} images" if not wrong else "; ".join(sorted(set(wrong))[:5]))
    sheet = "build/c2/mapping/index.html"
    check(os.path.exists(sheet) and os.path.getmtime(sheet) >= os.path.getmtime(mkmapping.MAPPING),
          "the approval sheet is built from this mapping", sheet)
    return pages


def main():
    print("the mapping (tools/arcade/mapping.json):")
    pages = static_checks()
    if FAILS:
        sys.exit(f"\ncheck-mapping FAILED: {len(FAILS)} check(s)")
    if os.environ.get("STATIC_ONLY"):
        print("\ncheck-mapping (static) passed")
        return
    print("in the game (the arcade oracle build):")
    checksprites.FAILS = FAILS
    checksprites.check = check
    checksprites.run(NEX, Arcade(pages), "check-mapping")


if __name__ == "__main__":
    main()
