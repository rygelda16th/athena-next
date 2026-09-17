#!/usr/bin/env python3
"""E1: the original's main-loop pass lengths over the whole recording.

    python3 tools/origpasses.py          (inside the container; writes build/e1/orig-passes.json)

A pass ends when a frame finishes with the CPU halted at $CEFB, the pass's frame
wait; the next frame's interrupt releases it. Each pass is attributed to the world
being played (the world load frames, docs/where-things-stand.md) and classed as
the engine classes it: 1 if the effect player wrote to the beeper ($C443-$C47F),
2 if the feathered blade's extra frame wait held it at $D992, 3 if the tune player
wrote to the beeper, 0 otherwise. The whole replay takes seconds: no instruction
trace, only port writes and frame ends.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rzxsim import Replay  # noqa: E402

WORLD_LOADS = [207, 12983, 27476, 41546, 56078, 70145, 85975]


def main():
    replay = Replay("data/athena.rzx")
    waits, fx, tune, blade = [], set(), set(), set()

    def on_port_write(frame, port, value, pc):
        if port & 1 == 0:
            if 0xC443 <= pc <= 0xC47F:
                fx.add(frame)
            elif 0xDED9 <= pc <= 0xE253:
                tune.add(frame)

    def on_frame_end(frame):
        r = replay.simulator.registers
        if r[28] and r[24] == 0xCEFB:
            waits.append(frame)
        elif r[28] and r[24] == 0xD992:
            blade.add(frame)

    replay.on_port_write, replay.on_frame_end = on_port_write, on_frame_end
    replay.run()
    hist = {}
    for a, b in zip(waits, waits[1:]):
        world = sum(1 for w in WORLD_LOADS if a >= w)
        frames = range(a + 1, b + 1)
        kind = 3 if any(f in tune for f in frames) else 1 if any(f in fx for f in frames) \
            else 2 if any(f in blade for f in frames) else 0
        key = f"{world},{kind}"
        hist.setdefault(key, [0] * 16)[min(b - a, 15)] += 1
    os.makedirs("build/e1", exist_ok=True)
    json.dump({"passes": len(waits) - 1, "hist": hist}, open("build/e1/orig-passes.json", "w"), indent=1)
    print(f"origpasses: {len(waits) - 1} passes -> build/e1/orig-passes.json")


if __name__ == "__main__":
    main()
