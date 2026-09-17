#!/usr/bin/env python3
"""Gate C1: the arcade capture records enough to rebuild what MAME shows.

    make check-capture      (inside the container; needs data/arcade/athena.zip)

Runs the player's own arcade set headless in MAME for 900 frames of its attract mode
with tools/arcade/capture.lua, saving MAME's own snapshots at frames 300, 600 and 900,
then rebuilds those frames from the capture log and the arcade graphics
(tools/arcade/frame.py) and compares them with the snapshots pixel for pixel. The
three frames cover the power-on test text, the title logo and a scrolled game screen
with sprites, the side panels and text.
"""
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "arcade"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import frame  # noqa: E402
import png    # noqa: E402
from arcgfx import Gfx  # noqa: E402

OUT = "build/c1/check"
FRAMES = (300, 600, 900)


def main():
    if not os.path.exists("data/arcade/athena.zip"):
        sys.exit("C1 check-capture: data/arcade/athena.zip is missing (the arcade set is optional; "
                 "this gate needs it)")
    shutil.rmtree(OUT, ignore_errors=True)
    os.makedirs(OUT)
    env = dict(os.environ, CAPTURE_OUT=f"{OUT}/capture.bin", CAPTURE_FRAMES=str(FRAMES[-1]),
               CAPTURE_SNAPS=",".join(str(f) for f in FRAMES))
    subprocess.run(["mame", "athena", "-rompath", "data/arcade", "-homepath", "/tmp/mame",
                    "-cfg_directory", "/tmp/mame/cfg", "-nvram_directory", "/tmp/mame/nvram",
                    "-snapshot_directory", f"{OUT}/snap", "-video", "none", "-sound", "none",
                    "-nothrottle", "-skip_gameinfo", "-autoboot_script", "tools/arcade/capture.lua"],
                   env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    log = open(f"{OUT}/capture.bin", "rb").read()
    gfx = Gfx()
    fails = 0
    for n, f in enumerate(FRAMES):
        snap = png.read(f"{OUT}/snap/athena/{n:04d}.png")
        _, rgb = frame.render(frame.state_at(log, f), gfx)
        bad = sum(1 for y in range(216) for x in range(288) if snap[y][x] != rgb[y][x])
        ok = bad == 0 and len(snap) == 216 and len(snap[0]) == 288
        print(f"  {'ok  ' if ok else 'FAIL'}  frame {f}: rebuilt from the log vs MAME's snapshot  [{bad} pixels differ]")
        fails += not ok
    if fails:
        sys.exit(f"\nC1 check-capture FAILED: {fails} frame(s)")
    print("\nC1 check-capture passed: frames rebuilt from the capture log match MAME pixel for pixel")


if __name__ == "__main__":
    main()
