#!/usr/bin/env python3
"""Gate G2: rebuild all eight RAM banks from the disassembly, byte for byte.

    make check-reasm      (inside the container; needs `make skool` first)

For each of two builds:
  plain     skool2asm.py -H -l             addresses as written
  labelled  skool2asm.py -H -l -c -s       every instruction labelled and every
                                           address operand that SkoolKit can
                                           resolve replaced by its label - the
                                           form later gates will move code in
the skool files (work/athena.skool for the 64K view, work/bankN.skool for banks
1, 3, 4, 6, 7) are converted to assembly, wrapped in one sjasmplus source that
places them in a 128K device image (banks 5, 2 and 0 from the 64K view; each
other bank paged into slot 3 inside its own MODULE so labels cannot collide),
assembled, and every bank compared with data/athena128.z80.

The comparison is against the very snapshot the skool files were made from, so
nothing is excluded: every one of the 131,072 bytes must match.
"""

import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from specfile import Z80Snapshot   # noqa: E402

OTHER_BANKS = (1, 3, 4, 6, 7)
BUILDS = {"plain": ["-H", "-l"], "labelled": ["-H", "-l", "-c", "-s"]}


def run(cmd, cwd=None, out=None):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if out:
        with open(out, "w") as f:
            f.write(r.stdout)
    return r


def build(name, options, snap):
    d = f"build/g2/{name}"
    os.makedirs(d, exist_ok=True)
    warnings = []
    for skool in ["athena"] + [f"bank{n}" for n in OTHER_BANKS]:
        r = run(["skool2asm.py", *options, f"work/{skool}.skool"], out=f"{d}/{skool}.asm")
        if r.returncode:
            sys.exit(f"skool2asm failed on {skool}: {r.stderr.strip()}")
        warnings += [f"{skool}: {w}" for w in r.stderr.splitlines() if w.startswith("WARNING")]
    src = ['  DEVICE ZXSPECTRUM128',
           '  INCLUDE "athena.asm"',
           '  SAVEBIN "bank5.bin",$4000,$4000',
           '  SAVEBIN "bank2.bin",$8000,$4000',
           '  SAVEBIN "bank0.bin",$C000,$4000']
    for n in OTHER_BANKS:
        src += [f'  MODULE bank{n}', '  SLOT 3', f'  PAGE {n}', f'  INCLUDE "bank{n}.asm"',
                f'  SAVEBIN "bank{n}.bin",$C000,$4000', '  ENDMODULE']
    with open(f"{d}/build.asm", "w") as f:
        f.write("\n".join(src) + "\n")
    r = run(["sjasmplus", "--nologo", "--msg=war", "build.asm"], cwd=d)
    messages = [ln for ln in (r.stdout + r.stderr).splitlines() if ln.strip()]
    if r.returncode:
        print("\n".join(messages[-20:]))
        sys.exit(f"sjasmplus failed on the {name} build")
    results = {}
    for n in range(8):
        got = open(f"{d}/bank{n}.bin", "rb").read()
        want = snap.bank(n)
        diff = [i for i in range(16384) if got[i] != want[i]]
        results[n] = diff
    return results, warnings, messages


def main():
    snap = Z80Snapshot(open("data/athena128.z80", "rb").read())
    failed = False
    for name, options in BUILDS.items():
        results, warnings, messages = build(name, options, snap)
        total = sum(len(v) for v in results.values())
        print(f"{name} build (skool2asm.py {' '.join(options)}):")
        for n in range(8):
            diff = results[n]
            where = f", first at +${diff[0]:04X}" if diff else ""
            print(f"  bank {n}: {16384 - len(diff):,} of 16,384 bytes identical{where}")
        print(f"  skool2asm warnings: {len(warnings)}; sjasmplus messages: {len(messages)}")
        for w in (warnings + messages)[:6]:
            print(f"    {w}")
        if total:
            failed = True
        print(f"  => {'IDENTICAL' if not total else f'{total} bytes differ'}")
    if failed:
        sys.exit("G2 check-reasm FAILED")
    print("G2 check-reasm passed: both builds reproduce all 131,072 bytes")


if __name__ == "__main__":
    main()
