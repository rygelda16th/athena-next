#!/usr/bin/env python3
"""Gate G3: athena.nex also runs in CSpect, the emulator David plays in.

    make check-cspect        (host side: runs CSpect under mono for a few seconds)

Builds tools/cspect/athprobe.cs into CSpect's folder, copies build/athena.nex to
CSpect's SD folder, runs it with the probe for six seconds, and checks what the
probe saw: IM 2 with I = $B7, the MMU as the resume stub leaves it, the title's
colour counter moving, and the screen - read through $4000 - equal pixel for pixel
to ZEsarUX's screenshot from make check-play. A CSpect window opens briefly.
"""

import os
import re
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from zxscreen import PALETTE, screen_rgb   # noqa: E402

CSPECT = os.environ.get("CSPECT", os.path.expanduser("~/src/cspect"))
LOG = "build/g3/athprobe.log"
FAILS = []


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""))
    if not ok:
        FAILS.append(what)


def main():
    env = dict(os.environ, PATH="/opt/homebrew/bin:" + os.environ.get("PATH", ""))
    subprocess.run(["mcs", "-target:library", f"-r:{CSPECT}/CSpect/Plugin.dll",
                    f"-out:{CSPECT}/CSpect/AthProbe.dll", "tools/cspect/athprobe.cs"], check=True, env=env)
    shutil.copy("build/athena.nex", f"{CSPECT}/sd/ATHENA.NEX")
    for f in (LOG, LOG + ".scr"):
        if os.path.exists(f):
            os.remove(f)
    env.update(ATHPROBE_LOG=os.path.abspath(LOG), ATHPROBE_SECONDS="6")
    subprocess.run(["mono", "CSpect.exe", "-w2", "-sound", "-mouse", "-basickeys", "-zxnext",
                    "-mmc=../sd/", "../sd/ATHENA.NEX"], cwd=f"{CSPECT}/CSpect", env=env,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)
    lines = [l for l in open(LOG) if l.startswith("t=")]
    check(len(lines) >= 5, "CSpect ran the game and the probe reported", f"{len(lines)} seconds")
    last = lines[-1]
    check("IM=2" in last and "I=$B7" in last, "IM 2, I = $B7", last.split(" MMU")[0])
    check("MMU=255 255 10 11 4 5 0 1" in last, "MMU as the resume stub leaves it")
    counters = {re.search(r"F253=\$(\w\w)", l).group(1) for l in lines}
    check(len(counters) > 1, "the title's colour counter moves", ",".join(sorted(counters)))
    scr = open(LOG + ".scr", "rb").read()
    pbm = open("build/g3/play-title.pbm", "rb").read().split(b"\n", 2)[2]
    rgb = screen_rgb(scr)
    bad = 0
    for y in range(192):
        for x in range(256):
            attr = scr[6144 + (y // 8) * 32 + x // 8]
            paper = PALETTE[((attr >> 3) & 7) + (8 if attr & 64 else 0)]
            if (rgb[y][x] != paper) != bool(pbm[y * 32 + x // 8] >> (7 - x % 8) & 1):
                bad += 1
    check(bad == 0, "the screen equals ZEsarUX's title, pixel for pixel", f"{bad} differ")
    if FAILS:
        sys.exit(f"\nG3 check-cspect FAILED: {len(FAILS)} check(s)")
    print("\nG3 check-cspect passed")


if __name__ == "__main__":
    main()
