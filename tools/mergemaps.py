#!/usr/bin/env python3
"""Gate G2: one code map from every run - the recording and the scripted runs.

    make scripts      (runs tools/scripts/*.py, then this)

Writes build/g2/map-all.txt in the format sna2ctl.py -m reads, and prints what
each scripted run added to the recording's own map.
"""

import glob


def load(path):
    return {int(line[1:5], 16) for line in open(path) if line.startswith("$")}


def main():
    recording = load("build/g1/map.txt")
    union = set(recording)
    for path in sorted(glob.glob("build/g2/script-*/map.txt")):
        run = load(path)
        new = sorted(run - recording)
        sample = ", ".join(f"${a:04X}" for a in new[:6])
        print(f"  {path.split('/')[2]:24s} {len(run):5,} addresses, {len(new):4,} the recording "
              f"never ran{': ' + sample if new else ''}")
        union |= run
    with open("build/g2/map-all.txt", "w") as f:
        for addr in sorted(union):
            f.write(f"${addr:04X}\n")
    print(f"build/g2/map-all.txt: {len(union):,} addresses "
          f"(recording {len(recording):,}, scripts +{len(union) - len(recording):,})")


if __name__ == "__main__":
    main()
