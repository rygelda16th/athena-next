#!/usr/bin/env python3
"""Gate E7: the three build levels all build and all play.

    make check-levels       (inside the container)

The port is built at three levels (docs/design.md, docs/art-bible.md):

  1. the Spectrum files alone: the recoloured scenery and the recoloured sprites;
  2. with the builder's arcade set: the arcade art for the mapped characters and the
     arcade music and effects on the AY chips;
  3. with David's hand-made art on top (data/art; this check uses one made from the
     original for the purpose, so the level is proven before he draws anything).

For each level it builds the assets and both .nex files, checks the .nex holds what that
level should (the arcade pages, the hand-made cells), runs `checknex.py play` on the play
build, and runs the renderer, sprite and scroll checks over the first SMOKE seconds of
the recording - every sample they take must match (at level 2 the sprite check is the
mapping's, which knows the arcade art). The full-length runs of those checks,
and the oracle, are the per-step gates (make e2, e3, e4, c2, e5, e6).
"""
import json
import os
import shutil
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

SMOKE = int(os.environ.get("SMOKE", "180"))
OUT = "build/levels"
ART = f"{OUT}/art"
FAILS = []
PORT = int(os.environ.get("ZRCP_PORT", "10010"))


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""), flush=True)
    if not ok:
        FAILS.append(what)


def run(cmd, env=None, quiet=True):
    e = dict(os.environ, **(env or {}))
    r = subprocess.run(cmd, shell=True, env=e, capture_output=True, text=True)
    if r.returncode and quiet:
        print(r.stdout[-2000:], r.stderr[-2000:])
    return r.returncode == 0, r.stdout


def with_zesarux(cmd, env=None):
    """One ZEsarUX and one checker in it, as the Makefile's gates do."""
    line = (f"zesarux --vo null --ao null --machine tbblue --enable-remoteprotocol "
            f"--remoteprotocol-port {PORT} --enable-breakpoints --tbblue-max-turbo-rom 8 "
            f"--tbblue-max-turbo-everywhere 8 --nosplash --noconfigfile --emulatorspeed 2000 "
            f"--enable-esxdos-handler --esxdos-root-dir /work/{OUT}/sd "
            f">/tmp/zesarux.log 2>&1 & sleep 3; {cmd}")
    return run(line, env)


def hand_made_cell():
    """One 16x16 cell for level 3: bank 3's cell 5, recoloured differently."""
    from specfile import Z80Snapshot
    from zxscreen import write_png
    import render_world as rw
    import mkassets
    os.makedirs(f"{ART}/cells/bank3", exist_ok=True)
    m = rw.world_memory(Z80Snapshot(open("data/athena128.z80", "rb").read()), 1)
    table = rw.word(m, 0x7665)
    bits = [m[table + 32 * 5 + 2 * y] << 8 | m[table + 32 * 5 + 2 * y + 1] for y in range(16)]
    cell = mkassets.recolour(bits)
    pal = {16: (0, 0, 0), 17: (255, 109, 0), 18: (255, 255, 146), 19: (146, 36, 0)}
    write_png(f"{ART}/cells/bank3/005.png", [[pal[cell[y * 16 + x]] for x in range(16)] for y in range(16)])


def build(level):
    """Build the assets and both .nex files for this level. True if it all built."""
    art = {"ART_DIR": ART, "ART_OUT": f"{OUT}/artout"} if level == 3 else {}
    if level == 3:
        hand_made_cell()
        ok, _ = run("python3 tools/artimport.py", art)
        if not ok:
            return False
        shutil.copy(f"{OUT}/artout/cells_bank3.json", "build/art/cells_bank3.json")
    elif os.path.exists("build/art/cells_bank3.json"):
        os.remove("build/art/cells_bank3.json")
    ok, _ = run("python3 tools/mkassets.py")
    if not ok:
        return False
    if level == 2:
        ok, _ = run("python3 tools/arcade/mkmapping.py && python3 tools/arcade/mksound.py")
        if not ok:
            return False
    arcade = " -DARCADE" if level == 2 else ""
    ok, _ = run(f"sjasmplus --nologo --msg=war -DSPEED=3{arcade} src/next/athena.asm")
    if not ok:
        return False
    ok, _ = run(f"sjasmplus --nologo --msg=war -DSPEED=3 -DORACLE{arcade} src/next/athena.asm")
    return ok


def main():
    os.makedirs(f"{OUT}/sd", exist_ok=True)
    import mkassets
    for level, name in ((1, "the Spectrum files alone"), (2, "with the arcade set"), (3, "with hand-made art")):
        print(f"level {level}, {name}:")
        built = build(level)
        check(built, f"level {level} builds")
        if not built:
            continue
        play = "build/athena-arcade.nex" if level == 2 else "build/athena.nex"
        oracle = "build/g3/athena-oracle-28-arcade.nex" if level == 2 else "build/g3/athena-oracle-28.nex"
        size = os.path.getsize(play)
        check((level == 2) == (size > 380000), f"level {level}'s .nex carries the arcade pages only if it should",
              f"{size} bytes")
        sheet = open("build/assets/cells_bank3.bin", "rb").read()
        cell = sheet[256 * 5:256 * 6]
        hand = any(b >= mkassets.ART_FIRST for b in cell)
        check((level == 3) == hand, f"level {level}'s scenery has hand-made cells only if it should",
              f"cell 5 of bank 3 uses {sorted(set(cell))}")
        ok, out = with_zesarux(f"python3 -u tools/checknex.py play")
        check(ok, f"level {level} runs the original at 28 MHz with the engine in", out.strip().split("\n")[-1])
        sprites = "checkmapping.py" if level == 2 else "checksprites.py"   # level 2 shows arcade art
        for checker, what in (("checkrender.py", "the play area"), (sprites, "the sprites"),
                              ("checkscroll.py", "the scroll")):
            ok, out = with_zesarux(f"python3 -u tools/{checker}", {"SMOKE": str(SMOKE), "NEX": oracle})
            last = [l for l in out.strip().split("\n") if l.strip()][-1] if out.strip() else ""
            check(ok, f"level {level}: {what} matched over the first {SMOKE} seconds", last)
    if FAILS:
        sys.exit(f"\nE7 check-levels FAILED: {len(FAILS)} check(s)")
    print("\nE7 check-levels passed")


if __name__ == "__main__":
    main()
