#!/usr/bin/env python3
"""E2 reference: what the play area on Layer 2 must show for a game state.

Used by tools/checkrender.py (make check-render). Given the game's 64K memory at the
moment the engine has drawn the play area (src/next/engine.asm, eng_copy) and the
recoloured cell sheets from tools/mkassets.py, it returns the 208x128 palette
indices the screen must show at columns 3-28, lines 0-127.

The picture follows the original's back buffer exactly (tools/checkgfx.py, D2): 15
map columns of 8 cells drawn from the column before the map window, shifted left 2
pixels for every scroll step since the window last moved. The cell a map code shows
is the original's choice (#R$DDFD), except that codes $79 and $7A - which the game's
world set-up fills with a copy of the world's background cell - show that cell.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from checkgfx import word, block_index  # noqa: E402

BANK_OF_WORLD = {1: 3, 2: 3, 3: 4, 4: 4, 5: 6, 6: 6, 7: 7}


def window_and_shift(m):
    """#R$DD66 as checkgfx.picture() applies it: the window the buffer was drawn from,
    and the 2-pixel shifts since."""
    window, facing, count = word(m, 0xBA17), m[0xB952], m[0xD4A2]
    if count > 8:
        count -= 8
        window = window + 8 if facing else window - 8
    if facing and count == 8:
        return window + 8, 0
    if facing:
        return window, count
    return window, 8 - count


def cell_index(m, world, code, count):
    n = block_index(m, code)
    if n in (0x19, 0x1A):                  # $79, $7A: the world's background cell
        return 0x21 if world % 2 else 0x22 # $0420 or $0440 into the table
    if n >= count:                         # past the sheet (never seen in the maps): background
        return (m[0xCECA] - 0x60) & 0xFF
    return n


def expected(m, sheet):
    """208 x 128 palette indices (rows of lists) for the play area."""
    window, shifts = window_and_shift(m)
    codes = [m[(window - 8 + k) & 0xFFFF] for k in range(120)]
    return expected_from(window, shifts, m[0xBA33], codes, m[0xDE09], m[0xCECA], sheet)


def expected_from(window, shifts, world, codes, item_block, background_block, sheet):
    """The same, from the inputs the engine samples: the window and shift it used, the
    world, the 120 map codes of the 15 columns from window - 8, and the world's item
    and background block codes."""
    m = {0xDE09: item_block, 0xCECA: background_block}
    count = len(sheet) // 256
    img = [[0] * 208 for _ in range(128)]
    for i in range(15):
        x0 = 8 + 16 * i - 2 * shifts - 24          # screen x of the column, less the play area's left edge
        for row in range(8):
            n = cell_index(m, world, codes[8 * i + row], count)
            cell = sheet[256 * n:256 * n + 256]
            for y in range(16):
                line = img[16 * row + y]
                for x in range(16):
                    sx = x0 + x
                    if 0 <= sx < 208:
                        line[sx] = cell[16 * y + x]
    return img


def layer2_offset(window, shifts):
    """The X offset the engine must set so that map column slots line up."""
    return (16 * ((window >> 3) - 1) - 8 + 2 * shifts) & 0xFF


def visible(layer2, offset):
    """The play area as Layer 2 shows it: pixel (x, y) is layer2[y][(x + offset) & 255]."""
    return [[layer2[y][(24 + x + offset) & 0xFF] for x in range(208)] for y in range(128)]


def load_sheet(world):
    return open(f"build/assets/cells_bank{BANK_OF_WORLD[world]}.bin", "rb").read()


def expected_layer(window, shifts, world, codes, item_block, background_block, sheet):
    """Layer 2's 256x128 pixels as the engine leaves them after a draw: the 15 map columns
    from window - 8 at their slots, None where no column of this draw is."""
    m = {0xDE09: item_block, 0xCECA: background_block}
    count = len(sheet) // 256
    layer = [[None] * 256 for _ in range(128)]
    first = ((window - 8) & 0xFFFF) >> 3
    for i in range(15):
        slot = (first + i) & 15
        for row in range(8):
            n = cell_index(m, world, codes[8 * i + row], count)
            cell = sheet[256 * n:256 * n + 256]
            for y in range(16):
                for x in range(16):
                    layer[16 * row + y][16 * slot + x] = cell[16 * y + x]
    return layer
