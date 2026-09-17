"""The arcade Athena's graphics and colours, decoded from the player's own set.

Reads data/arcade/athena.zip (MAME's `athena`, `athenab` or `sathena`; current or older
file names, found by CRC). Formats from MAME's snk.cpp / snk_v.cpp (BSD-3-Clause):
sprites 16x16 at 3 bits a pixel, background and text tiles 8x8 at 4 bits a pixel packed
low nibble first, colours from three PROMs with 4 weighted bits a channel.
"""
import zipfile
import zlib

# MAME's name -> CRC32. Only the files the enhanced port uses.
FILES = {
    "p5.6g": 0x42DBE029, "p6.6k": 0x596F1C8A,                      # sound program
    "p7.2p": 0xC63A871F, "p8.2s": 0x760568D8, "p9.2t": 0x57B35C73,  # sprites
    "p10.2b": 0xF269C0EB, "p11.2d": 0x18B4BCCA,                     # background, text tiles
    "3.2c": 0x294279AE, "2.1b": 0xD25C9099, "1.1c": 0xA4A4E7DC,     # colour PROMs
}
ZIP = "data/arcade/athena.zip"


def load(path=ZIP):
    """name -> bytes, matched by CRC whatever the file is called inside the zip."""
    z = zipfile.ZipFile(path)
    by_crc = {i.CRC: i.filename for i in z.infolist()}
    out = {}
    for name, crc in FILES.items():
        if crc not in by_crc:
            raise FileNotFoundError(f"{path}: no file with CRC {crc:08x} ({name})")
        data = z.read(by_crc[crc])
        if zlib.crc32(data) & 0xFFFFFFFF != crc:
            raise ValueError(f"{path}: {by_crc[crc]} fails its CRC")
        out[name] = data
    return out


def _bit(src, n):
    return 1 if src[n >> 3] & (0x80 >> (n & 7)) else 0


class Gfx:
    def __init__(self, roms=None):
        roms = roms or load()
        self.sp = roms["p7.2p"] + roms["p8.2s"] + roms["p9.2t"]
        self.bg = roms["p10.2b"]
        self.tx = roms["p11.2d"]
        self.proms = roms["3.2c"] + roms["2.1b"] + roms["1.1c"]
        self._sprites, self._bgtiles, self._txtiles = {}, {}, {}
        self.palette = [self._colour(i) for i in range(0x400)]

    def _colour(self, i):
        c, n = self.proms, 0x400
        b = lambda v, k: (v >> k) & 1
        r = 0x0E * b(c[i + 2 * n], 3) + 0x1F * b(c[i], 1) + 0x43 * b(c[i], 2) + 0x8F * b(c[i], 3)
        g = 0x0E * b(c[i + 2 * n], 2) + 0x1F * b(c[i + n], 2) + 0x43 * b(c[i + n], 3) + 0x8F * b(c[i], 0)
        bl = 0x0E * b(c[i + 2 * n], 0) + 0x1F * b(c[i + 2 * n], 1) + 0x43 * b(c[i + n], 0) + 0x8F * b(c[i + n], 1)
        return (r, g, bl)

    def sprite(self, code):
        """16 rows of 16 values 0-7 (7 transparent, 6 shadow)."""
        if code not in self._sprites:
            third = len(self.sp) * 8 // 3
            planes = (2 * third, third, 0)
            xo = list(range(7, -1, -1)) + list(range(15, 7, -1))
            rows = []
            for y in range(16):
                row = []
                for x in range(16):
                    v = 0
                    for p in planes:
                        v = v << 1 | _bit(self.sp, code * 256 + p + y * 16 + xo[x])
                    row.append(v)
                rows.append(row)
            self._sprites[code] = rows
        return self._sprites[code]

    def _tile(self, src, cache, code):
        if code not in cache:
            xo = (4, 0, 12, 8, 20, 16, 28, 24)
            rows = []
            for y in range(8):
                row = []
                for x in range(8):
                    v = 0
                    for p in range(4):
                        v = v << 1 | _bit(src, code * 256 + p + y * 32 + xo[x])
                    row.append(v)
                rows.append(row)
            cache[code] = rows
        return cache[code]

    def bgtile(self, code):
        return self._tile(self.bg, self._bgtiles, code & 0x3FF)

    def txtile(self, code):
        return self._tile(self.tx, self._txtiles, code & 0x1FF)
