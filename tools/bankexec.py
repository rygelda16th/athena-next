#!/usr/bin/env python3
"""Gate G2, killing experiment: does code ever run at $C000-$FFFF from a bank
other than 0?

    make bank-exec      (inside the container)

SkoolKit's code maps are 16-bit, so the answer decides how the disassembly is
laid out: if only bank 0 ever executes at $C000, one skool file covers all the
code in the 64K view and banks 1, 3, 4, 6 and 7 are data; if not, each bank that
runs code needs its own coverage and its own skool file.

Pass 1 replays the whole recording at full speed and logs every write to port
$7FFD (the 128K paging port: any even port with bit 15 clear). Pass 2 replays it
again and traces, instruction by instruction, every frame in which $7FFD was
written or a bank other than 0 was paged - and records every instruction fetched
at $C000 or above while that bank was not bank 0.

The answer is written to build/g2/bankexec.txt and printed.
"""

import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rzxsim import Replay   # noqa: E402
from specfile import Z80Snapshot   # noqa: E402

RZX = "data/athena.rzx"
OUT = "build/g2"


def main():
    os.makedirs(OUT, exist_ok=True)

    # ---- pass 1: every $7FFD write -------------------------------------------
    writes = []                     # (frame, value, pc of the OUT)
    paged_frames = set()
    state = {"bank": 0}
    replay = Replay(RZX)

    def port_write(frame, port, value, pc):
        if port & 0x8002 == 0:
            writes.append((frame, value, pc))
            paged_frames.add(frame)
            state["bank"] = value & 7

    def frame_end(frame):
        if state["bank"]:
            paged_frames.add(frame)
            paged_frames.add(frame + 1)

    replay.on_port_write = port_write
    replay.on_frame_end = frame_end
    frames = replay.run()
    final_pc = replay.simulator.registers[24]
    # The replay engine must be rzxplay's frame loop exactly: its final RAM must
    # equal the end snapshot rzxplay itself wrote at G1 (make rzx-end).
    end = Z80Snapshot(open("build/g1/end.z80", "rb").read())
    same_as_rzxplay = all(bytes(replay.simulator.memory.banks[n]) == end.bank(n) for n in range(8))

    # ---- pass 2: trace those frames -------------------------------------------
    hits = collections.Counter()    # (bank, pc) -> count
    traced = collections.Counter()  # bank -> instructions fetched anywhere
    replay2 = Replay(RZX)
    replay2.trace_frames = frozenset(paged_frames)

    def instruction(frame, pc, out7ffd):
        bank = out7ffd & 7
        traced[bank] += 1
        if bank and pc >= 0xC000:
            hits[(bank, pc)] += 1

    replay2.on_instruction = instruction
    frames2 = replay2.run()

    sites = collections.Counter((pc, value & 7) for _, value, pc in writes)
    lines = [
        f"frames replayed: {frames:,} (pass 2: {frames2:,}); final PC ${final_pc:04X}",
        f"final RAM equals rzxplay's end snapshot (build/g1/end.z80): {same_as_rzxplay}",
        f"$7FFD writes: {len(writes)} in {len({f for f, _, _ in writes})} frames",
        "writes by site and bank:",
    ]
    for (pc, bank), n in sorted(sites.items()):
        lines.append(f"  OUT at ${pc:04X} -> bank {bank}: {n}")
    lines.append(f"frames traced instruction by instruction: {len(paged_frames):,}")
    lines.append("instructions fetched in those frames, by bank at $C000: " +
                 ", ".join(f"bank {b} {n:,}" for b, n in sorted(traced.items())))
    if hits:
        lines.append(f"CODE RUN AT $C000-$FFFF FROM A BANK OTHER THAN 0: {len(hits)} addresses")
        for (bank, pc), n in sorted(hits.items())[:40]:
            lines.append(f"  bank {bank} ${pc:04X} x{n}")
        verdict = "NO - other banks run code; per-bank coverage needed"
    else:
        verdict = "YES - only bank 0 ever runs at $C000; banks 1, 3, 4, 6, 7 are data"
    lines.append(f"verdict: {verdict}")
    text = "\n".join(lines)
    print(text)
    with open(os.path.join(OUT, "bankexec.txt"), "w") as f:
        f.write(text + "\n")
    if frames != 119655 or frames2 != 119655 or not same_as_rzxplay:
        sys.exit("G2 bank-exec FAILED: the replay is not rzxplay's replay")


if __name__ == "__main__":
    main()
