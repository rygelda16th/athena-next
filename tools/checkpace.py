#!/usr/bin/env python3
"""Gate E1: the port keeps the original's pace.

    make check-pace     (after make check-oracle, which records the port's pass lengths)

The oracle replays Rafal's recording through the port, so the port runs exactly the
original's passes. The engine (src/next/engine.asm) records how many logic ticks each
took, by world and by kind (0 plain, 1 with a sound effect, 2 with a frame wait inside,
3 with a tune); tools/origpasses.py measures the same from the recording. Checked, for
each speed's run:

  passes     the port paced as many passes in each world as the recording has (the
             pacer runs at every pass's frame wait, so any difference is a missed pass)
  plain      passes with no blocking sound or wait take exactly 4 ticks, as 99% of the
             original's do
  blocking   passes with an effect or a wait: the port's mean length within 0.5 of a
             frame of the original's, per world
  pace       each world's mean pass length (all passes up to 12 frames) within 2% of the
             original's - the game's speed

and, from a short run of the play build with the engine told the display is 60 Hz:

  60 Hz      five logic ticks in every six interrupts

Only the 28 MHz runs are paced: at 3.5 MHz the new renderer cannot draw a pass inside
four frames (the 3.5 MHz oracle build exists to replay the recording, not to be played),
so `make check-pace` takes build/e1/pace-28.json and, where the arcade set is in,
build/e1/pace-28-arcade.json.
"""
import json
import os
import sys

FAILS = []


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""))
    if not ok:
        FAILS.append(what)


def stats(hist, world, kinds, cap=12):
    n = total = 0
    for k in kinds:
        for length, count in enumerate(hist.get(f"{world},{k}", [0] * 16)):
            if 1 <= length <= cap:
                n += count
                total += count * length
    return n, (total / n if n else 0.0)


def main():
    orig = json.load(open("build/e1/orig-passes.json"))["hist"]
    runs = sys.argv[1:] or [r for r in ("build/e1/pace-28.json", "build/e1/pace-28-arcade.json")
                            if os.path.exists(r)]
    for run in runs:
        port = json.load(open(run))["hist"]
        print(f"{run}:")
        for world in range(1, 8):
            on = sum(sum(orig.get(f"{world},{k}", [0] * 16)) for k in range(4))
            pn = sum(sum(port.get(f"{world},{k}", [0] * 16)) for k in range(4))
            check(abs(on - pn) <= 2, f"world {world}: passes", f"recording {on}, port {pn}")
            plain = port.get(f"{world},0", [0] * 16)
            share = plain[4] / max(1, sum(plain))
            check(share >= 0.99, f"world {world}: plain passes take 4 ticks", f"{share:.1%} of {sum(plain)}")
            o_n, o_mean = stats(orig, world, (1, 2))
            p_n, p_mean = stats(port, world, (1, 2))
            check(abs(o_mean - p_mean) <= 0.5, f"world {world}: passes with an effect or a wait",
                  f"recording {o_n} at {o_mean:.2f} frames, port {p_n} at {p_mean:.2f}")
            o_n, o_mean = stats(orig, world, (0, 1, 2))
            p_n, p_mean = stats(port, world, (0, 1, 2))
            check(abs(p_mean / o_mean - 1) <= 0.02 if o_mean else False, f"world {world}: pace",
                  f"recording {o_mean:.3f} frames a pass, port {p_mean:.3f} ({p_mean / o_mean - 1:+.2%})")
    try:
        hz = json.load(open("build/e1/hz60.json"))
        ratio = hz["ticks"] / hz["interrupts"] if hz["interrupts"] else 0
        check(abs(ratio - 5 / 6) < 0.02, "60 Hz: five logic ticks in six interrupts",
              f"{hz['ticks']} ticks in {hz['interrupts']} interrupts")
    except FileNotFoundError:
        check(False, "60 Hz run recorded", "build/e1/hz60.json missing: make check-hz60")
    if FAILS:
        sys.exit(f"\nE1 check-pace FAILED: {len(FAILS)} check(s)")
    print("\nE1 check-pace passed")


if __name__ == "__main__":
    main()
