"""Spectrum screens to PNG, and contact sheets of them. Standard library only.

A screen is the 6,912 bytes of the display file, then 768 attribute bytes
(FLASH, BRIGHT, PAPER, INK; FLASH is drawn unflashed).

THE DISPLAY FILE IS NOT 192 CONSECUTIVE 32-BYTE LINES. Within each of the three
2,048-byte thirds, character row r (0-7) is 32 bytes on and pixel line p (0-7)
of that row is 256 bytes on:

    address = $4000 + 2048 * third + 256 * p + 32 * r + column

That is what the ROM does (CL-ADDR at $0E9B puts character row n at
$4000 + 2048*(n div 8) + 32*(n mod 8), and the print routine steps pixel lines
with INC H), what SkoolKit's scr_udgs() does, and what ZEsarUX displays: this
renderer matches ZEsarUX's own screenshot of athena128.z80 in all 49,152 pixels,
where the consecutive-lines reading got 1,577 of a one-in-nine sample wrong. The
first version of this file used consecutive lines and drew every screen as
shredded stripes.
"""

import struct
import zlib

# The usual 0xD7 non-bright / 0xFF bright palette.
_BASE = [(0, 0, 0), (0, 0, 1), (1, 0, 0), (1, 0, 1), (0, 1, 0), (0, 1, 1), (1, 1, 0), (1, 1, 1)]
PALETTE = [tuple(c * 0xD7 for c in rgb) for rgb in _BASE] + \
          [tuple(c * 0xFF for c in rgb) for rgb in _BASE]


def screen_rgb(scr):
    """6,912 bytes -> 192 rows of 256 (r, g, b) tuples."""
    rows = []
    for y in range(192):
        row = []
        line = 2048 * (y // 64) + 256 * (y % 8) + 32 * ((y // 8) % 8)
        for cx in range(32):
            attr = scr[6144 + (y // 8) * 32 + cx]
            bright = 8 if attr & 0x40 else 0
            ink = PALETTE[(attr & 7) + bright]
            paper = PALETTE[((attr >> 3) & 7) + bright]
            bits = scr[line + cx]
            for bit in range(7, -1, -1):
                row.append(ink if bits >> bit & 1 else paper)
        rows.append(row)
    return rows


def write_png(path, rows):
    height, width = len(rows), len(rows[0])
    raw = b"".join(b"\0" + bytes(v for px in row for v in px) for row in rows)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def contact_sheet(path, screens, font, columns=8, scale_down=2):
    """screens: [(label, 6912 bytes)]. Each tile is the screen at half size with
    its label under it in the ROM font (font = the 768 bytes from ROM $3D00)."""
    tile_w, tile_h = 256 // scale_down, 192 // scale_down
    label_h = 10
    pad = 4
    cell_w, cell_h = tile_w + pad, tile_h + label_h + pad
    n_rows = (len(screens) + columns - 1) // columns
    width, height = columns * cell_w + pad, n_rows * cell_h + pad
    grey = (48, 48, 48)
    canvas = [[grey] * width for _ in range(height)]
    for i, (label, scr) in enumerate(screens):
        ox = pad + (i % columns) * cell_w
        oy = pad + (i // columns) * cell_h
        rgb = screen_rgb(scr)
        for y in range(tile_h):
            src = rgb[y * scale_down]
            dst = canvas[oy + y]
            for x in range(tile_w):
                dst[ox + x] = src[x * scale_down]
        _text(canvas, ox, oy + tile_h + 1, label, font)
    write_png(path, canvas)


def _text(canvas, x, y, text, font):
    white = (230, 230, 230)
    for ch in text:
        code = ord(ch) - 32
        if 0 <= code < 96:
            glyph = font[code * 8:code * 8 + 8]
            for gy in range(8):
                for gx in range(8):
                    if glyph[gy] >> (7 - gx) & 1 and y + gy < len(canvas) and x + gx < len(canvas[0]):
                        canvas[y + gy][x + gx] = white
        x += 8
