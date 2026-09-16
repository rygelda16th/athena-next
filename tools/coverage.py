#!/usr/bin/env python3
"""Gate G2: what the recording never ran, and why that might be.

    make coverage      (host or container; needs `make skool`)

Every block from $B6B5 up that is not code in src/athena.ctl was never executed
in Rafal's playthrough. This sorts those islands by the evidence the executed
code gives about them:

  branched-to   executed code JPs, JRs, CALLs or DJNZs into it: code the
                recording never needed (a menu option, a death, a path)
  addressed     executed code loads its address (LD rr,nn / LD A,(nn) / ...):
                data, or code reached indirectly
  unreferenced  nothing executed mentions it: a jump-table target, dead code,
                or data used only through computed pointers

and writes build/g2/coverage.txt. It reads work/athena.skool (written in hex by
`make skool`), so the instruction text is SkoolKit's.
"""

import collections
import re
import sys

LINE = re.compile(r"^([a-z* ])\$([0-9A-F]{4}) (.*?)(?:\s+;.*)?$")
BRANCH = re.compile(r"^(?:CALL|JP|JR|DJNZ)\b(?:\s+\w+,)?\s*\$([0-9A-F]{4})\b")
ADDRESS = re.compile(r"\$([0-9A-F]{4})\b")
START = 0xB6B5


def main():
    blocks = []            # [kind, start, [(address, instruction)]]
    for raw in open("work/athena.skool"):
        m = LINE.match(raw.rstrip("\n"))
        if not m:
            continue
        marker, addr, text = m.group(1), int(m.group(2), 16), m.group(3).strip()
        if marker.isalpha():               # b$... c$... t$... starts a block
            blocks.append([marker, addr, []])
        if blocks:
            blocks[-1][2].append((addr, text))

    # Block starts and ends
    spans = []
    for i, (kind, start, ins) in enumerate(blocks):
        end = blocks[i + 1][1] if i + 1 < len(blocks) else 0x10000
        spans.append((kind, start, end, ins))

    branched = collections.defaultdict(list)
    addressed = collections.defaultdict(list)
    for kind, start, end, ins in spans:
        if kind != "c":
            continue
        for addr, text in ins:
            b = BRANCH.match(text)
            if b:
                branched[int(b.group(1), 16)].append(addr)
                continue
            if text.startswith(("DEFB", "DEFW", "DEFM", "DEFS")):
                continue
            for a in ADDRESS.findall(text):
                addressed[int(a, 16)].append(addr)

    report = collections.defaultdict(list)
    for kind, start, end, ins in spans:
        if kind == "c" or end <= START:
            continue
        inside = lambda d: sorted({t: v for t, v in d.items() if start <= t < end}.items())
        br, ad = inside(branched), inside(addressed)
        if br:
            cls = "branched-to"
        elif ad:
            cls = "addressed"
        else:
            cls = "unreferenced"
        report[cls].append((start, end, kind, br, ad))

    out = []
    total = {c: sum(e - s for s, e, *_ in report[c]) for c in ("branched-to", "addressed", "unreferenced")}
    out.append(f"islands from ${START:04X} that no run executed (recording or scripts): "
               + ", ".join(f"{c} {len(report[c])} ({total[c]:,} bytes)"
                           for c in ("branched-to", "addressed", "unreferenced")))
    for cls in ("branched-to", "addressed", "unreferenced"):
        out.append(f"\n{cls}:")
        for start, end, kind, br, ad in report[cls]:
            refs = br if br else ad
            by = "; ".join(f"${t:04X} from " + ",".join(f"${s:04X}" for s in srcs[:3])
                           for t, srcs in refs[:3])
            out.append(f"  ${start:04X}-${end - 1:04X} {end - start:5d} bytes [{kind}]"
                       + (f"  {by}" if by else ""))
    text = "\n".join(out)
    with open("build/g2/coverage.txt", "w") as f:
        f.write(text + "\n")
    print("\n".join(out[:1]))
    for cls in ("branched-to", "addressed", "unreferenced"):
        print(f"{cls}: {len(report[cls])} islands, {total.get(cls, 0):,} bytes")
    print("full list: build/g2/coverage.txt")


if __name__ == "__main__":
    sys.exit(main())
