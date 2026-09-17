"""Rebuild arcade frames from a capture log (tools/arcade/capture.lua) and the graphics.

    python3 tools/arcade/frame.py LOG FRAME OUT.png      one frame as MAME draws it

The drawing follows MAME's screen_update_tnk3 (snk_v.cpp): the background tilemap
(64x64 tiles, columns first, scroll dx 15 dy 8), then 50 sprites in table order
(value 7 transparent, 6 a shadow that shows the colour at index | $200 of what is
under it), then the text layer (36x28, value 15 transparent except in the four side columns,
which MAME forces opaque; dy 8). The picture is
MAME's visible area: 288x216, bitmap lines 8-223.
"""
import struct
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from arcgfx import Gfx  # noqa: E402

W, H, Y0 = 288, 216, 8


class State:
    def __init__(self):
        self.bgram = bytearray(8192)
        self.txram = bytearray(2048)
        self.sprites = bytes(200)
        self.reg = {0xC8: 0, 0xC9: 0, 0xCA: 0, 0xCB: 0, 0xCC: 0}
        self.frame = 0
        self.sounds = []


def records(log):
    """Yields (kind, payload) from a capture log."""
    i, n = 0, len(log)
    while i < n:
        k = log[i:i + 1]
        i += 1
        if k == b"F":
            yield "F", struct.unpack_from("<I", log, i)[0]; i += 4
        elif k == b"S":
            yield "S", log[i:i + 200]; i += 200
        elif k == b"V":
            yield "V", struct.unpack_from("<HB", log, i); i += 3
        elif k == b"T":
            yield "T", struct.unpack_from("<HB", log, i); i += 3
        elif k == b"R":
            yield "R", (log[i], log[i + 1]); i += 2
        elif k == b"C":
            yield "C", log[i]; i += 1
        elif k == b"M":
            yield "M", log[i:i + 8192]; i += 8192
        else:
            raise ValueError(f"bad record {k!r} at {i - 1}")


def apply(state, kind, payload):
    if kind == "F":
        state.frame = payload
    elif kind == "S":
        state.sprites = payload
    elif kind == "V":
        state.bgram[payload[0]] = payload[1]
    elif kind == "T":
        state.txram[payload[0] & 0x7FF] = payload[1]
    elif kind == "R":
        state.reg[payload[0]] = payload[1]
    elif kind == "M":
        state.bgram[:] = payload
    elif kind == "C":
        state.sounds.append((state.frame, payload))


def scrolls(state):
    attr = state.reg[0xC8]
    bgx = state.reg[0xCC] | ((attr & 0x02) << 7)
    bgy = state.reg[0xCB] | ((attr & 0x10) << 4)
    spx = state.reg[0xCA] | ((attr & 0x01) << 8)
    spy = state.reg[0xC9] | ((attr & 0x08) << 5)
    return bgx, bgy, spx, spy


def render(state, gfx):
    """Returns (pens, rgb): 216 rows x 288 of palette indices and of RGB tuples."""
    bgx, bgy, spx, spy = scrolls(state)
    pens = [[0] * W for _ in range(H)]
    for row in range(H):
        y = row + Y0
        ty = (y - 8 + bgy) & 511
        line = pens[row]
        for x in range(W):
            tx = (x - 15 + bgx) & 511
            ti = (tx >> 3) * 64 + (ty >> 3)
            attr = state.bgram[2 * ti + 1]
            code = state.bgram[2 * ti] | ((attr & 0x30) << 4)
            colour = (attr & 0x0F) ^ 8
            line[x] = 0x80 + colour * 16 + gfx.bgtile(code)[ty & 7][tx & 7]
    s = state.sprites
    for offs in range(0, 200, 4):
        tile, attr = s[offs + 1], s[offs + 3]
        colour = attr & 0x0F
        sx = spx + 301 - 16 - s[offs + 2]
        sy = -spy + 7 - 16 + s[offs]
        sx += (attr & 0x80) << 1
        sy += (attr & 0x10) << 4
        tile |= (attr & 0x40) << 2
        tile |= (attr & 0x20) << 4
        sx &= 0x1FF
        sy &= 0x1FF
        if sx > 512 - 16:
            sx -= 512
        if sy > 512 - 16:
            sy -= 512
        pic = gfx.sprite(tile)
        for dy in range(16):
            row = sy + dy - Y0
            if not 0 <= row < H:
                continue
            for dx in range(16):
                x = sx + dx
                if not 0 <= x < W:
                    continue
                v = pic[dy][dx]
                if v == 7:
                    continue
                if v == 6:
                    pens[row][x] |= 0x200
                else:
                    pens[row][x] = colour * 8 + v
    offset = (state.reg[0xC8] & 0x40) << 2
    for row in range(H):
        y = row + Y0
        ty = y - 8
        if not 0 <= ty < 224:
            continue
        for x in range(W):
            col, r = x >> 3, ty >> 3
            c = col - 2
            index = (0x400 + r + ((c & 0x1F) << 5)) if c & 0x20 else (r + (c << 5))
            code = state.txram[index & 0x7FF]
            v = gfx.txtile(offset + code)[ty & 7][x & 7]
            if v != 15 or index & 0x400:    # TILE_FORCE_LAYER0: the side columns are opaque
                pens[row][x] = 0x180 + (code >> 5) * 16 + v
    rgb = [[gfx.palette[p & 0x3FF] for p in line] for line in pens]
    return pens, rgb


def state_at(log, frame):
    state = State()
    seen = False
    for kind, payload in records(log):
        if kind == "F" and seen:
            break
        apply(state, kind, payload)
        if kind == "F" and payload == frame:
            seen = True
    if not seen:
        raise ValueError(f"frame {frame} is not in the log")
    return state


def main():
    sys.path.insert(0, "tools")
    from zxscreen import write_png
    log = open(sys.argv[1], "rb").read()
    state = state_at(log, int(sys.argv[2]))
    _, rgb = render(state, Gfx())
    write_png(sys.argv[3], rgb)


if __name__ == "__main__":
    main()
