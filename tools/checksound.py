#!/usr/bin/env python3
"""Gate E5c: the arcade sound plays as converted, loops, and plays at the right moments.

    make check-arcade-sound     (inside the container; needs the player's arcade set)

THE PAGES (no emulator): every cue in tools/arcade/sound-cues.json is in the directory;
each stream decodes, tick by tick, to exactly the AY states the conversion made
(build/assets/sound_model.json); a looping cue's marker points at its loop tick; every
tune call site in the table is a real CALL $DEC6 in the player's snapshot.

THE LOOPS: each looping music cue is converted again for two repeats from the capture,
and the second repeat must give the same AY states as the first (LOOP_MATCH of the ticks
alike: the FM envelopes carry on across the loop, the stream does not).

THE PLAYER (`checksound.py player`, the arcade play build at its title): each cue is
started through the engine's request bytes; at random moments the emulator is stopped
and the stream's position, the engine's shadow of what it wrote and the three AY chips'
registers (ZEsarUX's get-io-ports) are read. The shadow must be the model's state for
the ticks the position says were played, and the chips must hold the shadow.

THE CAPTURES (`checksound.py capture`, E5b): every cue the table names has a capture with
writes on its own chip - the music on the board's first YM3526, the effects on its second -
and MAME, run again, gives the same writes byte for byte. (The design named a harness of its
own - a Z80 with two ymfm cores - to check MAME's render; MAME itself is that reference here,
and this check holds it to being repeatable.)

THE MOMENTS (`checksound.py moments`, the 28 MHz arcade oracle build): the recording is
replayed and sampled every SAMPLE_EVERY seconds: while a guardian is active its theme
must play (or a tune's cue after a lost life, or silence once it is destroyed); otherwise
the world's theme, a tune's cue, or silence after a guardian. Every world's theme and at
least one guardian theme must have been heard.
"""
import json
import os
import random
import re
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "arcade"))

FAILS = []
LOOP_MATCH = 0.80                      # AY states within a volume step, a tick either way
ENG = 0x40000 + 94 * 8192
SAMPLE_EVERY = 5


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""), flush=True)
    if not ok:
        FAILS.append(what)


def load():
    import mksound
    cues = json.load(open(mksound.CUES))
    model = json.load(open(f"{mksound.OUT}/sound_model.json"))
    blob = open(f"{mksound.OUT}/sound.bin", "rb").read()
    return mksound, cues, model, blob


def decode(blob, page0, cue, nv):
    """[(offset of the tick's mask, state after the tick)] and the end marker."""
    at = 2 + 6 * cue
    page, off = blob[at], blob[at + 1] | blob[at + 2] << 8
    lpage, loff = blob[at + 3], blob[at + 4] | blob[at + 5] << 8
    pos = (page - page0) * 0x2000 + off
    loop = (lpage - page0) * 0x2000 + loff
    state, ticks = [(0, 0)] * nv, []
    while True:
        mask = blob[pos]
        if mask >= 0x80:
            return ticks, mask, loop, pos
        start = pos
        pos += 1
        state = list(state)
        for v in range(nv):
            if mask >> v & 1:
                lo, hi = blob[pos], blob[pos + 1]
                state[v] = (lo | (hi & 15) << 8, hi >> 4)
                pos += 2
        ticks.append((start, state))


def static():
    mksound, cues, model, blob = load()
    import opl2ay
    wrong = []
    for cmd, m in model.items():
        cmd = int(cmd)
        ticks, marker, loop, end = decode(blob, mksound.SND_PAGE0, cmd, m["voices"])
        states = [s for _, s in ticks]
        want = [[tuple(v) for v in f] for f in m["frames"]]
        if states != want:
            first = next((i for i, (a, b) in enumerate(zip(states, want)) if a != b), min(len(states), len(want)))
            wrong.append(f"cue {cmd}: tick {first} of {len(want)} differs")
        if m["loop_tick"] is None:
            if marker != 0x80:
                wrong.append(f"cue {cmd}: ends with ${marker:02X}, not the end marker")
        elif marker != 0xC0 or ticks[m["loop_tick"]][0] != loop:
            wrong.append(f"cue {cmd}: the loop marker does not point at tick {m['loop_tick']}")
    check(not wrong, f"the sound pages decode to the conversion, tick for tick ({len(model)} cues)",
          "; ".join(wrong[:4]))
    used = {cues["setting_off"], cues["final_guardian"], cues["guardian_hit"], cues["guardian_destroyed"],
            cues["swing"], cues["jump"]} | set(cues["world_theme"].values()) | set(cues["guardian_theme"].values()) | \
        {v for k, v in cues["effects"].items() if k != "about" and v} | \
        {v for k, v in cues["tunes"].items() if k != "about" and isinstance(v, int) and v}
    missing = [c for c in used if str(c) not in model]
    check(not missing, "every cue the table names is in the pages", f"missing {missing}" if missing else "")
    from specfile import Z80Snapshot
    view = Z80Snapshot(open("data/athena128.z80", "rb").read()).view64()
    bad = [k for k in cues["tunes"] if k != "about" and bytes(view[int(k, 16) - 3:int(k, 16)]) != b"\xcd\xc6\xde"]
    check(not bad, "every tune moment is the return address of a CALL $DEC6 in the snapshot", ", ".join(bad))
    # the loops
    results = []
    for cmd, m in model.items():
        if m["loop_tick"] is None:
            continue
        lt, length = m["loop_tick"], m["ticks"] - m["loop_tick"]
        recs = opl2ay.load(f"{mksound.CAPTURES}/cmd{int(cmd):03d}.bin")
        loop = mksound.loop_of(recs, 0)
        ev = mksound.keyons(recs, 0)
        repeats = (ev[-1][0] / 1e6 - loop[0]) / loop[1] if loop else 0
        frames, _, _ = opl2ay.convert(recs, 0, 6, lt + 2 * length + 2, {})
        a = frames[lt:lt + length]
        near = 0
        for shift in (0, 1):
            b = frames[lt + length + shift:lt + 2 * length + shift]
            near = max(near, sum(1 for x, y in zip(a, b) if all(p == q and abs(v - w) <= 1
                                                              for (p, v), (q, w) in zip(sorted(x), sorted(y)))) / len(b))
        err = abs(length - loop[1] / mksound.TICK) if loop else 99
        results.append((int(cmd), repeats, err, near))
    bad = [r for r in results if r[1] < 2 or r[2] > 0.5 or r[3] < LOOP_MATCH]
    worst = min(results, key=lambda r: r[3]) if results else None
    check(results and not bad,
          f"every looping cue repeats note for note in its capture, loops within half a tick, and its second "
          f"repeat converts like the first ({len(results)} cues)",
          "; ".join(f"cue {c}: {rep:.1f} repeats, {e:.2f} ticks off, {n:.0%} alike" for c, rep, e, n in (bad or [worst])))
    return model, blob, mksound.SND_PAGE0


def zesarux():
    from zrcp import Zrcp
    return Zrcp(port=int(os.environ.get("ZRCP_PORT", "10010")), timeout=60)


def eng(z, off, n):
    z.cmd("set-memory-zone 0")
    try:
        return bytes.fromhex(z.cmd(f"read-memory {ENG + off} {n}").replace("\n", "").strip())
    finally:
        z.cmd("set-memory-zone -1")


def poke(z, off, value):
    z.cmd("set-memory-zone 0")
    try:
        z.cmd(f"write-memory {ENG + off} {value}")
    finally:
        z.cmd("set-memory-zone -1")


def chips(z):
    io = z.cmd("get-io-ports")
    out = {}
    for c, body in re.findall(r"AY-3-8912 chip (\d):\s*\n\s*Selected register: \d+\n((?:[0-9A-F]{2}:\s+[0-9A-F]{2}\s*\n)+)", io):
        out[int(c)] = [int(v, 16) for v in re.findall(r":\s+([0-9A-F]{2})", body)]
    return out


def player():
    import checknex
    model, blob, page0 = static()
    z = zesarux()
    checknex.load(z, "build/athena-arcade.nex")
    time.sleep(3)
    check(eng(z, 0x45, 1)[0] == 1, "the arcade build starts with the arcade sound on")
    random.seed(1987)
    samples, wrong = 0, []
    for cmd in sorted(model, key=int):
        m = model[cmd]
        music = m["kind"] == "music"
        req, cur, base = (0x47, 0x49, 0x50) if music else (0x48, 0x4A, 0x58)
        poke(z, req, int(cmd))
        span = m["ticks"] / 50.0 * (1.3 if m["loop_tick"] is not None else 0.9)
        for _ in range(3 if music else 2):
            time.sleep(random.uniform(0.05, max(0.1, span / 20)))   # the emulator runs at 20x
            z.cmd("enter-cpu-step")
            try:
                playing = eng(z, cur, 1)[0]
                pos = eng(z, base, 3)
                shadow = eng(z, 0x70, 48)
                ay = chips(z)
            finally:
                z.cmd("exit-cpu-step")
            if playing != int(cmd):
                if m["loop_tick"] is None and playing == 0:
                    continue                                        # it ended
                wrong.append(f"cue {cmd}: engine plays {playing}")
                continue
            ticks, marker, loop, end = decode(blob, page0, int(cmd), m["voices"])
            offset = (pos[0] - page0) * 0x2000 + (pos[1] | pos[2] << 8)
            done = [i for i, (o, _) in enumerate(ticks) if o < offset]
            state = ticks[done[-1]][1] if done else [(0, 0)] * m["voices"]
            first = 1 if music else 0                               # chip index: $FE is 1, $FF is 0
            for v in range(m["voices"]):
                chip, ch = first + v // 3, v % 3
                sh = shadow[16 * chip:16 * chip + 16]
                got = (sh[2 * ch] | (sh[2 * ch + 1] & 15) << 8, sh[8 + ch])
                if got != tuple(state[v]):
                    wrong.append(f"cue {cmd} voice {v}: shadow {got}, model {tuple(state[v])} after {len(done)} ticks")
                    break
                if chip in ay:
                    reg = ay[chip]
                    if (reg[2 * ch], reg[2 * ch + 1] & 15, reg[8 + ch] & 15) != (sh[2 * ch], sh[2 * ch + 1] & 15, sh[8 + ch]):
                        wrong.append(f"cue {cmd} voice {v}: AY chip {chip} holds {reg[:11]}, shadow {list(sh[:11])}")
                        break
            samples += 1
        poke(z, req, 0)
        time.sleep(0.1)
    check(not wrong and samples > 2 * len(model),
          f"the engine played every cue as converted ({samples} samples), and the chips hold what it wrote",
          "; ".join(wrong[:4]))
    z.cmd("exit-emulator")


def moments():
    import checknex
    mksound, cues, model, blob = load()
    z = zesarux()
    checknex.load(z, os.environ.get("NEX", "build/g3/athena-oracle-28-arcade.nex"))
    time.sleep(1)
    tunes = {v for k, v in cues["tunes"].items() if k != "about" and isinstance(v, int) and v} | {cues["setting_off"]}
    heard, guardians, samples, wrong = set(), set(), 0, []
    started = time.time()
    while time.time() - started < 7200:
        if checknex.vars_block(z, 5)[4]:
            break
        time.sleep(SAMPLE_EVERY)
        z.cmd("enter-cpu-step")
        try:
            world = checknex.mem(z, 0xBA33, 1)[0]
            guardian = checknex.mem(z, 0xB955, 1)[0]
            final = checknex.mem(z, 0xB951, 1)[0]
            playing, req = eng(z, 0x49, 1)[0], eng(z, 0x47, 1)[0]
            quiet = eng(z, 0x6D, 1)[0]
            snd_guard = eng(z, 0x60, 1)[0]
        finally:
            z.cmd("exit-cpu-step")
        if not 1 <= world <= 7 or req != 0xFF or bool(guardian) != bool(snd_guard):
            continue                                                # between a change and its tick
        samples += 1
        theme = cues["world_theme"][str(world)]
        if guardian:
            theme_g = cues["final_guardian"] if final else cues["guardian_theme"][str(world)]
            want = {theme_g} | tunes | ({0} if quiet else set())    # a life lost; destroyed
            if playing == theme_g:
                guardians.add(playing)
        else:
            want = {theme} | tunes | ({0} if quiet else set())
            if playing == theme:
                heard.add(world)
        if playing not in want:
            wrong.append(f"world {world}{' guardian' if guardian else ''}: cue {playing}, expected {sorted(want)}")
        print(f"    {time.time() - started:6.0f} s  world {world}  guardian {guardian:02X}  cue {playing}"
              f"{'' if playing in want else '  WRONG'}", flush=True)
    verdict = checknex.vars_block(z, 5)[4]
    check(verdict == 1, "the oracle reached the end of the recording with the arcade sound in", f"status {verdict}")
    check(not wrong, f"the right cue played at every sample ({samples})", "; ".join(wrong[:4]))
    check(heard == set(range(1, 8)), "every world's theme was heard", f"worlds {sorted(heard)}")
    check(len(guardians) >= 1, "a guardian's theme was heard", f"cues {sorted(guardians)}")
    z.cmd("exit-emulator")


def capture():
    """E5b: the captures are the arcade's own, and MAME gives the same ones every time."""
    import mksound
    import opl2ay
    cues = json.load(open(mksound.CUES))
    music = {cues["setting_off"], cues["final_guardian"]} | set(cues["world_theme"].values()) | \
        set(cues["guardian_theme"].values()) | \
        {v for k, v in cues["tunes"].items() if k != "about" and isinstance(v, int) and v}
    effects = {cues["guardian_hit"], cues["guardian_destroyed"], cues["swing"], cues["jump"]} | \
        {v for k, v in cues["effects"].items() if k != "about" and v}
    missing, quiet = [], []
    for cmd in sorted(music | effects):
        path = f"{mksound.CAPTURES}/cmd{cmd:03d}.bin"
        if not os.path.exists(path):
            missing.append(cmd)
            continue
        recs = opl2ay.load(path)
        chip = 0 if cmd in music else 1
        if not [r for r in recs if r[1] == chip]:
            quiet.append(cmd)
    check(not missing and not quiet, f"every cue has a capture with writes on its own chip "
          f"({len(music)} music, {len(effects)} effects)",
          f"missing {missing}, silent {quiet}" if missing or quiet else "")
    again = []
    for cmd, seconds in ((sorted(music)[0], mksound.MUSIC_SECONDS), (sorted(effects)[0], mksound.EFFECT_SECONDS)):
        path = f"{mksound.CAPTURES}/cmd{cmd:03d}.bin"
        keep = open(path, "rb").read()
        os.rename(path, path + ".keep")
        try:
            mksound.capture(cmd, seconds)
            same = open(path, "rb").read() == keep
        finally:
            os.replace(path + ".keep", path)
        again.append((cmd, same))
    check(all(same for _, same in again), "MAME captures the same chip writes the second time",
          ", ".join(f"command {c}: {'same' if ok else 'DIFFERENT'}" for c, ok in again))


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "static"
    print(f"E5 arcade sound ({mode}):")
    {"static": static, "player": player, "moments": moments, "capture": capture}[mode]()
    if FAILS:
        sys.exit(f"\nE5 check-arcade-sound ({mode}) FAILED: {len(FAILS)} check(s)")
    print(f"\nE5 check-arcade-sound ({mode}) passed")


if __name__ == "__main__":
    main()
