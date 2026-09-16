"""Readers for the Spectrum file formats this project touches: .z80 and .rzx.

Standard library only, so the host-side checks need no container. SkoolKit has
its own readers; these exist so that the data gate does not depend on the tool
whose output it is about to be used to judge.

Format references: the .z80 layout as documented at worldofspectrum.org's
faq/reference/z80format.htm (v1/v2/v3 headers, ED ED nn bb run-length blocks,
128K pages 3-10 = RAM banks 0-7), and the RZX 0.12 specification (blocks
0x10 creator, 0x30 snapshot, 0x80 input recording).
"""

import struct
import zlib


class Z80Snapshot:
    """A 128K .z80 snapshot: registers, paging state and RAM banks 0-7."""

    def __init__(self, raw):
        self.raw = raw
        (self.a, self.f, self.c, self.b, self.l, self.h, pc1, self.sp,
         self.i, r) = struct.unpack("<BBBBBBHHBB", raw[:12])
        flags = raw[12]
        self.r = (r & 0x7F) | ((flags & 1) << 7)
        (self.de, self.bc_, self.de_, self.hl_, self.a_, self.f_, self.iy,
         self.ix) = struct.unpack("<HHHHBBHH", raw[13:27])
        self.bc = self.c | self.b << 8
        self.hl = self.l | self.h << 8
        self.iff1, self.iff2 = raw[27], raw[28]
        self.im = raw[29] & 3
        if pc1 != 0:
            raise ValueError("version 1 .z80 (48K only) - a 128K snapshot was expected")
        self.ext_len = struct.unpack("<H", raw[30:32])[0]
        self.version = 2 if self.ext_len == 23 else 3
        self.pc = struct.unpack("<H", raw[32:34])[0]
        self.hw_mode = raw[34]
        self.port_7ffd = raw[35]
        self.modify_hw = (raw[37] >> 7) & 1
        self.port_fffd = raw[38]
        self.ay = list(raw[39:55])
        self.pages = {}
        pos = 32 + self.ext_len
        while pos < len(raw):
            length, page = struct.unpack("<HB", raw[pos:pos + 3])
            pos += 3
            if length == 0xFFFF:
                data = raw[pos:pos + 16384]
                pos += 16384
            else:
                data = _unrle(raw[pos:pos + length])
                pos += length
            if len(data) != 16384:
                raise ValueError(f"page {page} decodes to {len(data)} bytes, not 16384")
            self.pages[page] = data

    @property
    def is_128k(self):
        # v2: modes 3/4 = 128K / 128K+IF1; v3: modes 4/5/6 = 128K / +IF1 / +MGT.
        modes = (3, 4) if self.version == 2 else (4, 5, 6)
        return self.hw_mode in modes and not self.modify_hw

    def bank(self, n):
        return self.pages[n + 3]

    def view64(self):
        """The 64K the CPU saw: a blank ROM area, bank 5, bank 2, the paged bank."""
        return (bytes(16384) + self.bank(5) + self.bank(2)
                + self.bank(self.port_7ffd & 7))


def _unrle(src):
    out = bytearray()
    i = 0
    while i < len(src):
        if i + 3 < len(src) and src[i] == 0xED and src[i + 1] == 0xED:
            out += bytes([src[i + 3]]) * src[i + 2]
            i += 4
        else:
            out.append(src[i])
            i += 1
    return bytes(out)


class Rzx:
    """An RZX input recording: creator, embedded snapshots, input blocks."""

    def __init__(self, raw):
        if raw[:4] != b"RZX!":
            raise ValueError("not an RZX file")
        self.version = (raw[4], raw[5])
        self.creator = None
        self.snapshots = []      # (extension, bytes)
        self.input_blocks = []   # (frame count, tstates at start, flags)
        pos = 10
        while pos < len(raw):
            block_id = raw[pos]
            length = struct.unpack("<I", raw[pos + 1:pos + 5])[0]
            body = raw[pos + 5:pos + length]
            if block_id == 0x10:
                name = body[:20].split(b"\0")[0].decode("ascii", "replace")
                self.creator = (name,) + struct.unpack("<HH", body[20:24])
            elif block_id == 0x30:
                flags = struct.unpack("<I", body[:4])[0]
                ext = body[4:8].split(b"\0")[0].decode("ascii").lower()
                data = zlib.decompress(body[12:]) if flags & 2 else body[12:]
                self.snapshots.append((ext, data))
            elif block_id == 0x80:
                frames, _, tstates, flags = struct.unpack("<IBII", body[:13])
                self.input_blocks.append((frames, tstates, flags))
            pos += length

    @property
    def frames(self):
        return sum(b[0] for b in self.input_blocks)
