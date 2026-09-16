#!/usr/bin/env python3
"""Play the original from a snapshot with scripted key presses, at full speed.

    python3 tools/scriptplay.py SCRIPT      (inside the container)

The recording covers what Rafal did. This covers what he did not - the menu
options, redefining keys, running out of lives - by driving SkoolKit's C
simulator the way its own trace.py does (interrupts on, a draw callback once per
frame), with the keyboard filled from a schedule instead of from a window.

SCRIPT is a Python file defining:
  SNAPSHOT = "data/athena128.z80"      where to start
  FRAMES = 3000                        how long to run
  PRESS = [(first, last, "5"), ...]    keys held from frame first to last-1
  SHOTS = [100, 200, ...]              frames to save as PNG (+ .z80 if SNAP)
  SNAP = False
  OUT = "build/g2/script-name"
It writes OUT/map.txt (the executed addresses, sna2ctl.py -m format),
OUT/fNNNNNN.png, OUT/sheet.png and OUT/end.z80.

Key names: 0-9, A-Z, ENTER, SPACE, CAPS, SYMBOL. Kempston (port $1F) reads as
nothing pressed; KEMPSTON = [(first, last, bits)] presses its bits instead.
"""

import os
import runpy
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import skoolkit                                           # noqa: E402
from skoolkit import CSimulator, read_bin_file             # noqa: E402
from skoolkit.simutils import from_snapshot, get_state     # noqa: E402
from skoolkit.snapshot import Snapshot, write_snapshot     # noqa: E402
from skoolkit.trace import Tracer                          # noqa: E402
from zxscreen import contact_sheet, screen_rgb, write_png  # noqa: E402

ROWS = ["CAPS Z X C V", "A S D F G", "Q W E R T", "1 2 3 4 5",
        "0 9 8 7 6", "P O I U Y", "ENTER L K J H", "SPACE SYMBOL M N B"]
KEYS = {name: (row, bit) for row, names in enumerate(ROWS)
        for bit, name in enumerate(names.split())}


class ScriptTracer(Tracer):
    kempston = 0

    def read_port(self, registers, port):
        if port & 0xFF == 0x1F:
            return self.kempston
        return super().read_port(registers, port)


def main():
    script = runpy.run_path(sys.argv[1])
    out = script["OUT"]
    os.makedirs(out, exist_ok=True)
    press = [(a, b, [KEYS[k] for k in keys.split("+")]) for a, b, keys in script.get("PRESS", [])]
    kempston = script.get("KEMPSTON", [])
    shots = set(script.get("SHOTS", []))
    frames = script["FRAMES"]

    snap = Snapshot.get(script.get("SNAPSHOT", "data/athena128.z80"))
    sim = from_snapshot(CSimulator, snap, {}, {"ay": [None] * 16},
                        {"fast_djnz": False, "fast_ldir": False})
    sim.memory.out7ffd(snap.out7ffd)
    tracer = ScriptTracer(sim, snap.border, snap.out7ffd, snap.outfffd, list(snap.ay),
                          snap.outfe, True)
    sim.set_tracer(tracer)
    keyboard = tracer.keyboard = [0] * 8
    exec_map = set()
    frame0 = sim.registers[25] // sim.frame_duration
    sheet = []

    def draw(scr, frame, border, kb):
        f = frame - frame0
        for i in range(8):
            keyboard[i] = 0
        for a, b, keys in press:
            if a <= f < b:
                for row, bit in keys:
                    keyboard[row] |= 1 << bit
        tracer.kempston = 0
        for a, b, bits in kempston:
            if a <= f < b:
                tracer.kempston |= bits
        tracer.border[:] = [(0, tracer.border[-1][1])]
        if f in shots:
            write_png(os.path.join(out, f"f{f:06d}.png"), screen_rgb(scr))
            sheet.append((str(f), bytes(scr)))
            if script.get("SNAP"):
                ram, registers, state, machine = get_state(sim)
                write_snapshot(os.path.join(out, f"f{f:06d}.z80"), ram, registers, state, machine)
        return f < frames

    sim.trace(snap.pc, None, 0, 0, True, draw, exec_map, keyboard, None, None)

    with open(os.path.join(out, "map.txt"), "w") as f:
        for addr in sorted(exec_map):
            f.write(f"${addr:04X}\n")
    ram, registers, state, machine = get_state(sim)
    write_snapshot(os.path.join(out, "end.z80"), ram, registers, state, machine)
    if sheet:
        font = bytes(read_bin_file(skoolkit.ROM48))[0x3D00:0x4000]
        contact_sheet(os.path.join(out, "sheet.png"), sheet, font, columns=5)
    print(f"{out}: {frames} frames, {len(exec_map):,} addresses executed, {len(sheet)} shots")


if __name__ == "__main__":
    main()
