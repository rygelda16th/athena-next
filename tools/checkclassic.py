#!/usr/bin/env python3
"""Gate E5a: classic mode plays the original's beeper sound, note for note.

    make check-classic-sound     (inside the container)

Classic sound in the port is the original's own effect and tune players, run on the
original's clock: `eng_fx` and `eng_tune` (src/next/engine.asm) drop the CPU to 3.5 MHz
while they play, so every speaker edge comes from the same instructions at the same
T-state spacing, and the Next's DACs take the edges directly - no sampling, so none of
the aliasing a recording would add (docs/design.md, Sound). This check hears it.

RECORD (`checkclassic.py record 128k|next`, with ZEsarUX running and `--aofile`): for each
sound, a stub at $B9B8 (ten bytes nothing uses) is run from a fresh stop - DI; the call;
DI; JR $ - and the audio ZEsarUX renders (15,600 samples a second) is kept with where each
sound starts and ends. `128k` is the original machine with the player's snapshot; `next`
the port's play build. Tunes 0-3 play until a key, so they are cut after LOOP_SECONDS.

COMPARE (`checkclassic.py compare`, after four recordings - two a machine): the speaker
edges are recovered from each render
(crossings of the level half way between its two states, to a fraction of a sample):
  - the Next's 3.5 MHz is exactly 3.5 MHz and a 128K's is 3,546,900 Hz, so the same
    instructions take CLOCK (1.34%) longer on the Next: the port's times are divided by it
    (a quarter of a semitone - the hardware's, not the port's);
  - an effect runs with interrupts off, so it must have the original's edges (within
    COUNT_TOL), last as long (within DURATION_TOL) and have the same spread of gaps
    between them (the quarter, half and three-quarter points of the sorted gaps,
    within QUANTILE_TOL);
  - a tune's notes and rests are counted in interrupts, whose phase against the tune's
    start is arbitrary in both machines (so the first note can lose most of an interrupt),
    so a tune is compared note by note: runs of edges between rests, each with its pitch
    (within PITCH_TOL); NOTE_MATCH of the notes must match the original's in order and
    pitch, as many of those within LENGTH_TOL interrupts in length, and the tune's whole
    length within 2%. The port's notes measure 1.3-3% flat against the 128K's: 1.34% of
    that is the Next's exact 3.5 MHz against a 128K's 3,546,900 Hz, and the rest the
    engine's own interrupt handler inside a note. Tunes 0-3 play noise bursts whose edges
    differ from one run to the next, on either machine.

What is covered: all 14 tunes, the 7 effects called by fixed number (0, 1, 2, 4, 5, 10,
11), and effect 12, the rising heart, in each of its 16 variants ($BCCF from $1F to $10).
"""
import json
import math
import os
import statistics
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

OUT = "build/e5/classic"
RATE = 15600
STUB = 0xB9B8
LOOP_SECONDS = 12
COUNT_TOL = 0.08                            # edges or notes: the render drops the odd one
QUANTILE_TOL = 0.06                         # how far a gap between edges may differ
GAP_MATCH = 0.75                            # and how many of them must be that close
DURATION_TOL = 0.015
NOTE_MATCH = 0.65                           # tunes 0-3 play noise bursts that differ run to run
LENGTH_TOL = 2
FRAME = RATE / 50.0
CLOCK = 3546900 / 3500000                   # the 128K's clock against the Next's 3.5 MHz
GAP = 150                                   # samples: longer than any tone's half period, shorter than a rest
STRAY_EFFECT = 800                          # 51 ms: longer than any gap inside an effect
STRAY_TUNE = 4000                           # 0.26 s: longer than most rests inside a tune
PITCH_TOL = 0.06                            # octaves: the measured difference is 1.3-3% (see below)
PASSES = ("", "-b")                         # each machine is recorded twice: see compare()

SOUNDS = [("effect", n) for n in (0, 1, 2, 4, 5, 10, 11)] + \
         [("heart", m) for m in range(0x1F, 0x0F, -1)] + \
         [("tune", t) for t in range(14)]


def name(kind, n):
    return f"{kind} {n}" if kind != "heart" else f"effect 12 mask ${n:02X}"


# ---- record ----------------------------------------------------------------------------

def record(machine):
    from zrcp import Zrcp
    import checknex
    raw = f"{OUT}/{machine}.raw"
    z = Zrcp(port=int(os.environ.get("ZRCP_PORT", "10010")), timeout=60)
    if machine.startswith("128k"):
        z.cmd("smartload /work/data/athena128.z80")
        time.sleep(0.5)
    else:
        checknex.load(z, "build/athena.nex")
        time.sleep(3)                       # the resume stub and the engine's set-up
    size = lambda: os.path.getsize(raw)

    def emulated_wait(samples):
        start = size()
        t = time.time()
        while size() < start + samples and time.time() - t < 60:
            time.sleep(0.02)

    def pc():
        return int(z.cmd("get-registers").split("PC=")[1][:4], 16)

    log = []
    only = os.environ.get("ONLY")
    for kind, n in SOUNDS:
        if only and name(kind, n) != only:
            continue
        z.cmd("enter-cpu-step")
        if kind == "tune":
            stub = [0xF3, 0x3E, n, 0xCD, 0xC6, 0xDE, 0xF3, 0x18, 0xFE]
        else:
            stub = [0xF3, 0xCD, 0x08, 0xC4, 12 if kind == "heart" else n, 0xF3, 0x18, 0xFE]
            if kind == "heart":
                z.cmd(f"write-memory {0xBCCF} {n}")
        for i, b in enumerate(stub):
            z.cmd(f"write-memory {STUB + i} {b}")
        end_pc = STUB + len(stub) - 2
        z.cmd("set-register SP=B8A0H")
        z.cmd(f"set-register PC={STUB:04X}H")
        start = size()
        z.cmd("exit-cpu-step")
        t = time.time()
        cut = False
        while pc() != end_pc:
            if kind == "tune" and n <= 3 and size() - start > LOOP_SECONDS * RATE:
                cut = True
                break
            if time.time() - t > 300:
                sys.exit(f"record {machine}: {name(kind, n)} did not end")
            time.sleep(0.02)
        z.cmd("enter-cpu-step")
        end = size()
        z.cmd(f"set-register PC={end_pc - 1:04X}H")  # DI; JR $: silent until the next
        z.cmd("exit-cpu-step")
        emulated_wait(RATE // 2)
        log.append(dict(kind=kind, n=n, start=start, end=end, cut=cut))
        print(f"  {machine}: {name(kind, n)}  bytes {start}-{end}{'  (cut)' if cut else ''}", flush=True)
    emulated_wait(8192)
    json.dump(log, open(f"{OUT}/{machine}.json", "w"))
    z.cmd("exit-emulator")


# ---- compare ---------------------------------------------------------------------------

def edges(raw, entry, stray=None):
    """Crossing times (samples from the segment's first) of the sound in this entry."""
    stray = stray or (STRAY_TUNE if entry["kind"] == "tune" else STRAY_EFFECT)
    lo = max(0, entry["start"] - 4096)      # ZEsarUX writes 4,096 bytes at a time
    hi = min(len(raw), entry["end"] + 4096)
    seg = raw[lo:hi]
    idle = statistics.mode(seg[:2048]) if len(seg) > 2048 else seg[0]
    vals = sorted(set(seg))
    far = max(vals, key=lambda v: abs(v - idle))
    mid = (idle + far) / 2.0
    out = []
    for i in range(1, len(seg)):
        a, b = seg[i - 1] - mid, seg[i] - mid
        if (a < 0 <= b) or (a >= 0 > b):
            out.append(i - 1 + (a / (a - b) if a != b else 0))
    # the sound itself: the first run of edges with no gap of STRAY samples that starts
    # where the sound was asked for. ZEsarUX's audio file now and then holds a stray
    # sample from its buffer, which reads as an edge, and the window takes in the silence
    # either side.
    runs, run = [], []
    for t in out:
        if run and t - run[-1] > stray:
            runs.append(run)
            run = []
        run.append(t)
    if run:
        runs.append(run)
    at = entry["start"] - lo - 200
    for r in runs:
        if r[0] >= at and len(r) >= 4:
            return r
    return max(runs, key=len) if runs else []


def notes(e, scale):
    """[(start, end, pitch)] runs of edges without a rest: times from the first edge,
    divided by scale; pitch as the nearest quarter-tone of the median edge interval."""
    out, first = [], 0
    for i in range(1, len(e) + 1):
        if i == len(e) or e[i] - e[i - 1] > GAP:
            run = e[first:i]
            if len(run) >= 4:
                period = statistics.median(b - a for a, b in zip(run, run[1:])) / scale
                out.append(((run[0] - e[0]) / scale, (run[-1] - e[0]) / scale, math.log2(period)))
            first = i
    return out


def align(na, nb):
    """The longest in-order pairing of notes whose pitches are within PITCH_TOL octaves."""
    n, m = len(na), len(nb)
    best = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n - 1, -1, -1):
        for j in range(m - 1, -1, -1):
            if abs(na[i][2] - nb[j][2]) <= PITCH_TOL:
                best[i][j] = best[i + 1][j + 1] + 1
            else:
                best[i][j] = max(best[i + 1][j], best[i][j + 1])
    out, i, j = [], 0, 0
    while i < n and j < m:
        if abs(na[i][2] - nb[j][2]) <= PITCH_TOL and best[i][j] == best[i + 1][j + 1] + 1:
            out.append((na[i], nb[j]))
            i, j = i + 1, j + 1
        elif best[i + 1][j] >= best[i][j + 1]:
            i += 1
        else:
            j += 1
    return out


def compare():
    """Each machine is recorded twice and each sound compared across the four pairs, best
    first: ZEsarUX's audio file now and then repeats or drops a buffer, which no rerun of
    the port can fix and no difference in the port can cause."""
    fails = []
    logs, raws = {}, {}
    for machine in ("128k", "next"):
        for p in PASSES:
            logs[machine + p] = json.load(open(f"{OUT}/{machine}{p}.json"))
            raws[machine + p] = open(f"{OUT}/{machine}{p}.raw", "rb").read()
    for n, a0 in enumerate(logs["128k"]):
        label = name(a0["kind"], a0["n"])
        best, detail = None, ""
        for pa in PASSES:
            for pb in PASSES:
                a, b = logs["128k" + pa][n], logs["next" + pb][n]
                ea, eb = edges(raws["128k" + pa], a), edges(raws["next" + pb], b)
                if len(ea) < 4 or len(eb) < 4:
                    continue
                if a["kind"] != "tune":
                    ia = sorted(y - x for x, y in zip(ea, ea[1:]))
                    ib = sorted((y - x) / CLOCK for x, y in zip(eb, eb[1:]))
                    ratio = ((eb[-1] - eb[0]) / CLOCK) / (ea[-1] - ea[0])
                    steps = 64              # the two sorted lists of gaps, point by point
                    close = sum(1 for k in range(steps)
                                if abs(ib[int(k * (len(ib) - 1) / (steps - 1))] /
                                       max(0.01, ia[int(k * (len(ia) - 1) / (steps - 1))]) - 1) <= QUANTILE_TOL)
                    alike = close / steps
                    count = abs(len(ea) - len(eb)) / max(len(ea), len(eb))
                    ok = count <= COUNT_TOL and alike >= GAP_MATCH and abs(ratio - 1) <= DURATION_TOL
                    score = (ok, alike)
                    text = (f"{len(ea)} edges over {(ea[-1] - ea[0]) / RATE * 1000:.1f} ms, port {len(eb)};"
                            f" {alike:.0%} of its gaps within {QUANTILE_TOL:.0%}, length {ratio:.4f} of the original's")
                else:
                    na, nb = notes(ea, 1.0), notes(eb, CLOCK)
                    if a["cut"] or b["cut"]:
                        limit = min(ea[-1] - ea[0], (eb[-1] - eb[0]) / CLOCK) - RATE
                        na = [x for x in na if x[1] < limit]
                        nb = [x for x in nb if x[1] < limit]
                    matched = align(na, nb)
                    share = len(matched) / max(1, len(na), len(nb))
                    timed = sum(1 for x, y in matched if abs((x[1] - x[0]) - (y[1] - y[0])) <= LENGTH_TOL * FRAME)
                    # the length of the part that matched, so a stray edge at either end
                    # cannot stretch it (the port's clock does not come into a tune's
                    # length: its notes and rests are counted in interrupts)
                    length = 9 if not matched else \
                        (((matched[-1][1][1] - matched[0][1][0]) * CLOCK) /
                         max(1, matched[-1][0][1] - matched[0][0][0]))
                    cut = a["cut"] or b["cut"]          # a looping tune is cut where it is cut
                    ok = (share >= NOTE_MATCH and timed >= NOTE_MATCH * len(matched)
                          and abs(len(na) - len(nb)) <= max(4, 0.1 * len(na))
                          and (cut or abs(length - 1) <= 0.02))
                    score = (ok, share)
                    text = (f"{len(na)} notes{' (cut)' if a['cut'] else ''}, port {len(nb)}; {share:.0%} in the same"
                            f" order at the same pitch, {timed} of them within {LENGTH_TOL} interrupts in length,"
                            f" {length:.4f} of the original's length")
                if best is None or score > best:
                    best, detail = score, text
        ok = bool(best and best[0])
        print(f"  {'ok  ' if ok else 'FAIL'}  {label}: {detail}", flush=True)
        if not ok:
            fails.append(label)
    if fails:
        sys.exit(f"\nE5 check-classic-sound FAILED: {len(fails)} of {len(SOUNDS)} sounds: {', '.join(fails[:6])}")
    print(f"\nE5 check-classic-sound passed: {len(SOUNDS)} sounds")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    if sys.argv[1] == "record":
        record(sys.argv[2])
    else:
        compare()
