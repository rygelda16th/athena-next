#!/usr/bin/env python3
"""Play Rafal's recording to the end and watch the game while it plays.

    python3 tools/rzxwalk.py [--every FRAMES] [--out DIR]      (inside the container)

This is SkoolKit's own RZX player (skoolkit.rzxplay, C simulator) with one
addition: rzxplay calls a "screen" object once per frame, and this script
passes an object that, instead of drawing, looks at the machine:

- every frame: the named variables below and the disputed byte in bank 7,
  logging each change with its frame number;
- every --every frames, and on the last frame: the screen (.scr) and a row of
  variables;
- throughout: every address executed (16-bit, the format sna2ctl.py -m reads);
- whenever a bank other than 0 is paged at $C000 at a frame's end: the frame
  and the bank (the game only does this while it loads a world);
- at frames given with --at: the screen as PNG and a .z80 snapshot, so later
  gates can start from any world;
- at the end: a .z80 of the final state and a contact sheet of the screens.

Nothing here writes to the machine. Frame numbers are rzxplay's (0-based).
"""

import argparse
import collections
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import skoolkit                                        # noqa: E402
from skoolkit import rzxplay, read_bin_file            # noqa: E402
from skoolkit.simutils import get_state                # noqa: E402
from skoolkit.snapshot import write_snapshot           # noqa: E402
from zxscreen import contact_sheet, screen_rgb, write_png  # noqa: E402

# name: (bank, offset). Addresses from the POKE sites (docs/provenance.md);
# all in bank 0 ($C000) or bank 2 ($8000), which the game keeps paged.
VARIABLES = {
    "lives $C1EE": (0, 0x01EE),
    "energy $BF1B": (2, 0x3F1B),
    "time $B94D": (2, 0x394D),
    "megajumps $B953": (2, 0x3953),
    "immunity $BA2A": (2, 0x3A2A),
    "credits $CCB9": (0, 0x0CB9),
    "bank7 +$341B": (7, 0x341B),
}


class Probe:
    def __init__(self, out, every, at):
        self.out = out
        self.every = every
        self.at = at
        self.paged = []
        self.context = None
        self.last = {}
        self.changes = []
        self.rows = []
        self.screens = []
        self.paging = collections.Counter()

    def sample(self, frame, scr, banks):
        name = f"f{frame:06d}"
        with open(os.path.join(self.out, "frames", name + ".scr"), "wb") as f:
            f.write(bytes(scr))
        self.screens.append((f"{frame} {frame / 3000:4.1f}m", bytes(scr)))
        self.rows.append([frame] + [banks[b][o] for b, o in VARIABLES.values()])

    def draw(self, scr, frame, border):
        sim = self.context.simulator
        banks = sim.memory.banks
        self.paging[sim.memory.o7ffd] += 1
        if sim.memory.o7ffd & 7:
            self.paged.append((frame, sim.memory.o7ffd))
        if frame in self.at:
            name = self.at[frame]
            write_png(os.path.join(self.out, name + ".png"), screen_rgb(scr))
            ram, registers, state, machine = get_state(sim)
            write_snapshot(os.path.join(self.out, name + ".z80"), ram, registers, state, machine)
        for key, (b, o) in VARIABLES.items():
            v = banks[b][o]
            if self.last.get(key) != v:
                if key in self.last:
                    self.changes.append((frame, key, self.last[key], v, sim.registers[24]))
                self.last[key] = v
        if frame % self.every == 0:
            self.sample(frame, scr, banks)
        self.final = (frame, bytes(scr))
        return True


def play(args, at, every):
    options = argparse.Namespace(cmio=False, flags="0", force=False, fps=0, map=None,
                                 screen=False, python=False, quiet=True, scale=1,
                                 snapshot=None, stop=None, trace=None, dump=None)
    blocks = rzxplay.parse_rzx(args.rzx)
    probe = Probe(args.out, every, at)
    context = rzxplay.RZXContext(probe)
    probe.context = context
    context.exec_map = set()
    for block in blocks:
        if isinstance(block.obj, rzxplay.InputRecording):
            context.total_frames += len(block.obj.frames)
    started = time.time()
    while blocks:
        rzxplay.process_block(blocks.pop(0).obj, options, 0, context)
    return probe, context, time.time() - started


def world_loads(paged):
    """Group the frames with a non-zero bank at $C000 into load bursts."""
    bursts = []
    for frame, value in paged:
        if bursts and frame - bursts[-1][1] <= 50:
            bursts[-1][1] = frame
        else:
            bursts.append([frame, frame, value & 7])
    return bursts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rzx", default="data/athena.rzx")
    ap.add_argument("--out", default="build/g1")
    ap.add_argument("--every", type=int, default=1500, help="frames between samples (1500 = 30 s)")
    ap.add_argument("--settle", type=int, default=250,
                    help="frames after a load to picture its title card (250 = 5 s)")
    ap.add_argument("--play", type=int, default=1500,
                    help="frames after a world load to picture and snapshot play (1500 = 30 s)")
    args = ap.parse_args()
    os.makedirs(os.path.join(args.out, "frames"), exist_ok=True)

    probe, context, elapsed = play(args, {}, args.every)
    sim = context.simulator

    last_frame, last_scr = probe.final
    if last_frame % args.every:
        probe.sample(last_frame, last_scr, sim.memory.banks)

    with open(os.path.join(args.out, "map.txt"), "w") as f:
        for addr in sorted(context.exec_map):
            f.write(f"${addr:04X}\n")
    ram, registers, state, machine = get_state(sim)
    write_snapshot(os.path.join(args.out, "end.z80"), ram, registers, state, machine)

    with open(os.path.join(args.out, "variables.tsv"), "w") as f:
        f.write("frame\tminutes\t" + "\t".join(VARIABLES) + "\n")
        for row in probe.rows:
            f.write(f"{row[0]}\t{row[0] / 3000:.1f}\t" + "\t".join(str(v) for v in row[1:]) + "\n")
    with open(os.path.join(args.out, "paging.tsv"), "w") as f:
        f.write("frame\t7ffd\tbank_at_C000\n")
        for frame, value in probe.paged:
            f.write(f"{frame}\t{value:02X}\t{value & 7}\n")
    with open(os.path.join(args.out, "changes.tsv"), "w") as f:
        f.write("frame\tvariable\tfrom\tto\tpc_at_frame_end\n")
        for frame, key, old, new, pc in probe.changes:
            f.write(f"{frame}\t{key}\t{old}\t{new}\t${pc:04X}\n")

    font = bytes(read_bin_file(skoolkit.ROM48))[0x3D00:0x4000]
    contact_sheet(os.path.join(args.out, "sheet.png"), probe.screens, font)

    # Second pass: a picture and a snapshot a few seconds into each world, the
    # ending and the last frame. The names say what the paging showed.
    bursts = world_loads(probe.paged)
    at, rows, world = {}, [], 0
    for first, last, bank in bursts:
        if bank == 1:
            name = "ending" if "ending" not in at.values() else "ending2"
        else:
            world += 1
            name = f"world{world}"
        if name.startswith("world"):
            at[last + args.settle] = name + "-card"     # the WORLD OF ... title card
            at[last + args.play] = name                 # in play, a start point for later gates
        else:
            at[last + args.settle] = name
        rows.append((name, first, last, bank))
    at[probe.final[0]] = "last-frame"
    play(args, at, 1 << 30)
    with open(os.path.join(args.out, "worlds.tsv"), "w") as f:
        f.write("name\tload_first_frame\tload_last_frame\tminutes\tbank_at_C000\tsnapshot_frame\n")
        for name, first, last, bank in rows:
            snap = last + (args.play if name.startswith("world") else args.settle)
            f.write(f"{name}\t{first}\t{last}\t{first / 3000:.1f}\t{bank}\t{snap}\n")

    counts = collections.Counter(k for _, k, _, _, _ in probe.changes)
    print(f"played {context.frame_count + 1:,} frames in {elapsed:.1f} s "
          f"({(context.frame_count + 1) / 50 / max(elapsed, 1e-9):.0f}x real time)")
    print(f"executed addresses: {len(context.exec_map):,}")
    print("$7FFD at frame ends: " + ", ".join(f"{v:02X} x{n}" for v, n in probe.paging.most_common()))
    print("changes per variable: " + ", ".join(f"{k} {counts.get(k, 0)}" for k in VARIABLES))
    b7 = [c for c in probe.changes if c[1] == "bank7 +$341B"]
    print(f"bank 7 +$341B: starts {probe.rows[0][-1]:02X}, "
          + (", ".join(f"frame {fr}: {o:02X}->{n:02X}" for fr, _, o, n, _ in b7[:10]) or "never changed"))
    print("world loads: " + ", ".join(f"{n} {fr / 3000:.1f}m (bank {b})" for n, fr, _, b in rows))
    print(f"wrote {args.out}/sheet.png ({len(probe.screens)} screens), variables.tsv, changes.tsv, "
          f"paging.tsv, worlds.tsv, map.txt, end.z80, and {len(at)} PNG + .z80 pairs")

    fails = []
    if context.frame_count + 1 != 119655:
        fails.append(f"played {context.frame_count + 1} frames, expected 119,655")
    if world != 7:
        fails.append(f"found {world} world loads, expected 7")
    if b7:
        fails.append("bank 7 +$341B changed during play")
    if fails:
        sys.exit("G1 rzx-end FAILED: " + "; ".join(fails))
    print("G1 rzx-end passed: the recording plays to the end through seven worlds")


if __name__ == "__main__":
    main()
