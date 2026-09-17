#!/usr/bin/env python3
"""Gate G3: everything the oracle build needs from the recording.

    make oracle-stream      (inside the container; needs make check-reasm first)

WHY A STREAM. The game takes nothing from outside itself except port reads and
the R register (G3's first experiment: the in-game interrupt routine at $E986 is
EI/RETI, but LD A,R is read at eight places, and R counts every instruction the
CPU fetches - including the ones repeated while it sits in HALT - so its value
depends on CPU speed). Feed the port every one of those values, in program order,
and the game must take the path it took in the recording at any speed.

So this replays Rafal's recording on SkoolKit's C simulator with an instruction
trace over the whole of it, and writes:

  build/g3/stream.bin      one record per run of identical events:
                             byte 0   site index (bits 0-4); bit 6: a repeat
                                      count follows; bit 7: a checkpoint follows;
                                      $1F = end of stream
                             byte 1   the value A receives
                             [byte]   F, for sites whose instruction sets flags
                             [byte]   repeat count - 1 (runs of 2 to 256)
                             [3 bytes] checkpoint kind (0 light, 1 full) and the
                                      16-bit hash of the game state at the first
                                      event of the record
  build/g3/oracle_gen.asm  site table, patches, region tables, the recording's
                           start state (registers and its 85 differing bytes)
  build/g3/play_gen.asm    the snapshot's registers, for the plain build

                           $1D = a tune (below)

TUNES ARE NOT REPLAYED. The tune player ($DEC6, entered through the CALL $DED9
at $DECA) drives note lengths - and the aborting of its own tone and key-wait
loops - from interrupts, so its path depends on when interrupts arrive, which no
value stream can reproduce (found by the first oracle run, 2026-09-16: the port
left a tune's key-wait loop at a different read and diverged 187,995 events in).
The check build therefore turns that CALL into a service: a tune record carries
every byte the tune changed in $5B00-$FFFF (the stack excepted) and the registers
the reference had when it reached the tune's exit at $DECD, and the handler
applies both and jumps to $DECD. Events recorded inside a tune are not in the
stream. Record: $1D, count (16 bits), count x (address, value), then F A C B E D
IXl IXh IYl IYh F' A' C' B' E' D' L' H' (little-endian pairs, so POP AF and
LD rr,(nn) load them directly). The saved SP at $DECF is left to the port.

Checkpoints fall on every 1,024th event, and every 16,384th is a full one. The
hash is h = rotl16(h) ^ byte over each region, identical in tools/ and on the
machine (src/next/oracle.asm).
"""

import os
import struct
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from skoolkit import rzxplay                 # noqa: E402
from skoolkit.simutils import (A, F, B, C, D, E, H, L, IXh, IXl, IYh, IYl,  # noqa: E402
                                xA, xF, xB, xC, xD, xE, xH, xL)
from rzxsim import Replay                     # noqa: E402
from specfile import Rzx, Z80Snapshot         # noqa: E402
import nexpatches                             # noqa: E402

OUT = "build/g3"
IN_N, IN_C, LD_AR = 0, 1, 2
# runtime PC, kind, where the patch goes (None = the ROM copy, at run time), bytes there
SITES = [
    (0x0296, IN_C, None, b"\xED\x78"),     # ROM KEY-SCAN: IN A,(C)
    (0xBA8E, IN_N, 0xF473, b"\xDB\x1F"),   # Kempston routine, copied from $F472 at game start
    (0xBAA0, IN_N, 0xF485, b"\xDB\xFE"),
    (0xC2E6, IN_N, 0xC2E6, b"\xDB\xFE"),
    (0xC5AC, LD_AR, 0xC5AC, b"\xED\x5F"),
    (0xC5C8, LD_AR, 0xC5C8, b"\xED\x5F"),
    (0xC5D2, LD_AR, 0xC5D2, b"\xED\x5F"),
    (0xC6B1, LD_AR, 0xC6B1, b"\xED\x5F"),
    (0xD05B, IN_N, 0xD05B, b"\xDB\xFE"),
    (0xD11F, LD_AR, 0xD11F, b"\xED\x5F"),
    (0xD592, LD_AR, 0xD592, b"\xED\x5F"),
    (0xDC89, LD_AR, 0xDC89, b"\xED\x5F"),
    (0xDDBC, LD_AR, 0xDDBC, b"\xED\x5F"),
    (0xDF50, IN_N, 0xDF50, b"\xDB\xFE"),
    (0xF1E9, IN_N, 0xF1E9, b"\xDB\xFE"),
    (0xF1FA, IN_N, 0xF1FA, b"\xDB\x1F"),
]
SERVICE = [0xB8D2, 0xB8E4, 0xB902, 0xB911, 0xB923, 0xB92F, 0xB941]   # OUT (C),A to $7FFD
TUNE_CALL, TUNE_EXIT = 0xDECA, 0xDECD     # CALL $DED9 (the tune player) and where it comes back
TUNE_RECORD = 0x1D
ISR_IN = 0xF240           # the title interrupt's IN A,($9F): value unused, left unpatched
RST = 0xEF                # RST $28
CHECK_EVERY, FULL_EVERY = 1024, 16384
LIGHT = [(0xB949, 0xBA8D - 0xB949), (0xF4C6, 0x10000 - 0xF4C6)]
FULL = [(0x5B00, 0xB801 - 0x5B00),           # system variables to the IM 2 table
        (0xB8B8, 0xBA8D - 0xB8B8),           # (not $B801-$B8B7: the stack)
        (0xBAD4, 0xF244 - 0xBAD4),           # (not $BA8D-$BAD3: rewritten at game start)
        (0xF245, 0xF253 - 0xF245),           # (not $F244, $F253-$F254, $F2A6-$F2A7:
        (0xF255, 0xF2A6 - 0xF255),           #  the title interrupt's own counters and
        (0xF2A8, 0x10000 - 0xF2A8)]          #  its saved SP)


def without(regions, skip):
    """Split regions so that no address in skip is hashed. Patch sites are left out
    because the game overwrites some of its own code in play (the menu at $F1E9-$F486
    becomes workspace), and then neither the patch nor the original byte is there."""
    out = []
    for start, length in regions:
        run = None
        for a in range(start, start + length):
            if a in skip:
                if run:
                    out.append((run, a - run))
                    run = None
            elif run is None:
                run = a
        if run is not None:
            out.append((run, start + length - run))
    return out


def logical(banks, addr):
    if addr >= 0xC000:
        return banks[0], addr - 0xC000
    if addr >= 0x8000:
        return banks[2], addr - 0x8000
    return banks[5], addr - 0x4000


def region_bytes(banks, start, length):
    out = bytearray()
    addr = start
    end = start + length
    while addr < end:
        bank, off = logical(banks, addr)
        take = min(end - addr, 0x4000 - off)
        out += bank[off:off + take]
        addr += take
    return out


def z80_hash(regions, banks):
    h = 0
    for start, length in regions:
        for b in region_bytes(banks, start, length):
            h = ((h << 1) & 0xFFFF) | (h >> 15)
            h ^= b
    return h


def main():
    os.makedirs(OUT, exist_ok=True)
    index = {pc: i for i, (pc, *_rest) in enumerate(SITES)}
    kind = {pc: k for pc, k, *_rest in SITES}
    patches = {}
    for i, (pc, k, at, orig) in enumerate(SITES):
        if at is not None:
            patches[at], patches[at + 1] = RST, i
    # The world loader's OUT (C),A sites (SERVICE) are the engine's since E1
    # (tools/nexpatches.py), so they are not poked here; the handler's $80 service
    # remains, unused.
    patches[TUNE_CALL], patches[TUNE_CALL + 1], patches[TUNE_CALL + 2] = RST, 0x82, 0x00
    skip = set(patches) | nexpatches.addresses()
    if set(patches) & nexpatches.addresses():
        sys.exit("an oracle patch overlaps an engine patch")
    full = without(FULL, skip)
    light = without(LIGHT, skip)

    snap = Z80Snapshot(open("data/athena128.z80", "rb").read())
    rzx_snap = Z80Snapshot(Rzx(open("data/athena.rzx", "rb").read()).snapshots[0][1])
    view = snap.view64()
    for pc, k, at, orig in SITES:
        if at is not None and view[at:at + 2] != orig:
            sys.exit(f"patch site ${at:04X} holds {view[at:at + 2].hex()}, expected {orig.hex()}")
    for pc in SERVICE:
        if view[pc:pc + 2] != b"\xED\x79":
            sys.exit(f"service site ${pc:04X} is not OUT (C),A")
    nexpatches.verify(view)
    if view[TUNE_CALL:TUNE_CALL + 3] != b"\xCD\xD9\xDE":
        sys.exit(f"${TUNE_CALL:04X} is not CALL $DED9")

    # ---- trace the whole recording ----------------------------------------------
    events = []          # (site index, A, F or None, hash or None, checkpoint kind)
                         # or ("tune", [(address, value)], registers)
    stray_reads = {}
    state = {"pending": None, "tune": None, "port_events": 0, "tunes": 0, "tune_events": 0}
    replay = Replay("data/athena.rzx")
    replay.trace_frames = range(0, 1 << 30)

    class All:
        def __contains__(self, frame):
            return True
    replay.trace_frames = All()

    def ram():
        banks = replay.simulator.memory.banks
        return bytes(banks[5][0x1B00:]) + bytes(banks[2]) + bytes(banks[0])   # $5B00-$FFFF

    def instruction(frame, pc, out7ffd):
        pending = state["pending"]
        regs = replay.simulator.registers
        if pending is not None:
            i, n, h, ck = pending
            f = regs[1] if SITES[i][1] != IN_N else None
            events.append((i, regs[0], f, h, ck))
            state["pending"] = None
        if pc == TUNE_CALL and state["tune"] is None:
            state["tune"] = ram()
            return
        if pc == TUNE_EXIT and state["tune"] is not None:
            before, after = state["tune"], ram()
            changes = [(0x5B00 + k, after[k]) for k in range(len(after))
                       if after[k] != before[k] and not 0xB801 <= 0x5B00 + k <= 0xB8B7
                       and 0x5B00 + k not in (0xDECF, 0xDED0)]   # the port's own saved SP
            r = regs
            reg_bytes = bytes([r[F], r[A], r[C], r[B], r[E], r[D], r[IXl], r[IXh], r[IYl], r[IYh],
                               r[xF], r[xA], r[xC], r[xB], r[xE], r[xD], r[xL], r[xH]])
            events.append(("tune", changes, reg_bytes))
            state["tune"] = None
            state["tunes"] += 1
            return
        i = index.get(pc)
        if i is not None:
            if state["tune"] is not None:
                state["tune_events"] += 1
                return
            n = state["port_events"]
            state["port_events"] += 1
            h = ck = None
            if n % CHECK_EVERY == 0:
                ck = 1 if n % FULL_EVERY == 0 else 0
                h = z80_hash(full if ck else light, replay.simulator.memory.banks)
            state["pending"] = (i, n, h, ck)

    base_read = rzxplay.RZXTracer.read_port

    def read_port(self, registers, port):
        pc = registers[24]
        if pc not in index and pc != ISR_IN:
            stray_reads[pc] = stray_reads.get(pc, 0) + 1
        return base_read(self, registers, port)

    rzxplay.RZXTracer.read_port = read_port
    replay.on_instruction = instruction
    started = time.time()
    frames = replay.run()
    rzxplay.RZXTracer.read_port = base_read
    if stray_reads:
        sys.exit(f"port reads from unlisted sites: {stray_reads}")

    # ---- encode ---------------------------------------------------------------------
    out = bytearray()
    records = checks = fulls = 0
    j = 0
    tune_records = 0
    while j < len(events):
        if events[j][0] == "tune":
            _, changes, reg_bytes = events[j]
            out.append(TUNE_RECORD)
            out += struct.pack("<H", len(changes))
            for addr, value in changes:
                out += struct.pack("<HB", addr, value)
            out += reg_bytes
            tune_records += 1
            j += 1
            continue
        i, a, f, h, ck = events[j]
        run = 1
        while (j + run < len(events) and run < 256 and events[j + run][0] != "tune"
               and events[j + run][:3] == (i, a, f) and events[j + run][3] is None):
            run += 1
        b0 = i | (0x40 if run > 1 else 0) | (0x80 if h is not None else 0)
        out += bytes([b0, a])
        if f is not None:
            out.append(f)
        if run > 1:
            out.append(run - 1)
        if h is not None:
            out += bytes([ck, h & 0xFF, h >> 8])
            checks += 1
            fulls += ck
        records += 1
        j += run
    out.append(0x1F)
    with open(f"{OUT}/stream.bin", "wb") as fh:
        fh.write(out)

    # ---- the assembler's view ------------------------------------------------------------
    pages = (len(out) + 0x1FFF) // 0x2000
    banks16 = (pages + 1) // 2
    lines = [
        "; Generated by tools/mkstream.py from the player's own files. Not committed.",
        f"SITE_COUNT      EQU {len(SITES)}",
        f"ROM_SITE        EQU ${SITES[0][0]:04X}",
        "ROM_SITE_IDX    EQU 0",
        f"STREAM_BYTES    EQU {len(out)}",
        f"STREAM_BANK0    EQU 10",
        f"STREAM_BANKS    EQU {banks16}",
        f"EVENTS          EQU {state['port_events']}",
        f"CHECKPOINTS     EQU {checks}",
    ]
    for name, s in (("REG", rzx_snap),):
        for reg, v in (("A", s.a), ("F", s.f), ("BC", s.bc), ("DE", s.de), ("HL", s.hl),
                       ("IX", s.ix), ("IY", s.iy), ("SP", s.sp), ("PC", s.pc), ("I", s.i),
                       ("R", s.r), ("A_", s.a_), ("F_", s.f_), ("BC_", s.bc_), ("DE_", s.de_),
                       ("HL_", s.hl_)):
            lines.append(f"{name}_{reg:<11} EQU ${v:04X}")
    lines.append("nex_stream_banks MACRO")
    lines.append("  SAVENEX BANK " + ",".join(str(10 + k) for k in range(banks16)))
    lines.append("  ENDM")
    lines.append("site_kind_table MACRO")
    lines.append("  DB " + ",".join(str(k) for _, k, _, _ in SITES))
    lines.append("  ENDM")
    for tname, regions in (("light", light), ("full", full)):
        lines.append(f"{tname}_region_table MACRO")
        for s, n in regions:
            lines.append(f"  DW ${s:04X},{n}")
        lines.append("  DW 0,0")
        lines.append("  ENDM")
    # patches and the recording's start state, per 16K bank, applied after INCBIN
    pokes = {0: {}, 2: {}, 5: {}, 1: {}, 3: {}, 4: {}, 6: {}, 7: {}}
    for a, b in patches.items():
        bank, off = (0, a - 0xC000) if a >= 0xC000 else (2, a - 0x8000)
        pokes[bank][off] = b
    for n in range(8):
        for off in range(0x4000):
            if rzx_snap.bank(n)[off] != snap.bank(n)[off]:
                pokes[n][off] = rzx_snap.bank(n)[off]
    lines.append("oracle_pokes MACRO")
    for n, d in pokes.items():
        if not d:
            continue
        lines.append(f"  MMU 6 7, {2 * n}")
        for off, b in sorted(d.items()):
            lines.append(f"  ORG ${0xC000 + off:04X} : DB ${b:02X}")
    lines.append("  ENDM")
    with open(f"{OUT}/oracle_gen.asm", "w") as fh:
        fh.write("\n".join(lines) + "\n")
    with open(f"{OUT}/sysvars_oracle.bin", "wb") as fh:
        fh.write(rzx_snap.bank(5)[0x1B00:0x1D00])
    with open(f"{OUT}/sysvars_play.bin", "wb") as fh:
        fh.write(snap.bank(5)[0x1B00:0x1D00])
    play = ["; Generated by tools/mkstream.py from the player's own snapshot. Not committed."]
    s = snap
    for reg, v in (("A", s.a), ("F", s.f), ("BC", s.bc), ("DE", s.de), ("HL", s.hl),
                   ("IX", s.ix), ("IY", s.iy), ("SP", s.sp), ("PC", s.pc), ("I", s.i),
                   ("R", s.r), ("A_", s.a_), ("F_", s.f_), ("BC_", s.bc_), ("DE_", s.de_),
                   ("HL_", s.hl_)):
        play.append(f"REG_{reg:<11} EQU ${v:04X}")
    with open(f"{OUT}/play_gen.asm", "w") as fh:
        fh.write("\n".join(play) + "\n")

    print(f"{frames:,} frames traced in {time.time() - started:.0f} s")
    print(f"{state['port_events']:,} events in {records:,} records, {checks} checkpoints ({fulls} full); "
          f"{state['tunes']} tunes skipped, holding {state['tune_events']:,} events; "
          f"{tune_records} tune records, largest {max((len(e[1]) for e in events if e[0] == 'tune'), default=0)} bytes changed")
    print(f"stream.bin {len(out):,} bytes = {pages} 8K pages in {banks16} 16K banks from bank 10")
    print(f"{len(SITES) - 1 + len(SERVICE) + 1} patched instructions; start state differs from the snapshot in "
          f"{sum(1 for n in range(8) for o in range(0x4000) if rzx_snap.bank(n)[o] != snap.bank(n)[o])} bytes")


if __name__ == "__main__":
    main()
