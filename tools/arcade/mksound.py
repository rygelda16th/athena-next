#!/usr/bin/env python3
"""E5: the arcade sound the enhanced port plays, built from tools/arcade/sound-cues.json and
the player's own arcade set.

    python3 tools/arcade/mksound.py          (make arcade-assets; inside the container)

For every cue the table names, the arcade board's chip writes are captured in MAME
(tools/arcade/soundcmd.lua: music 150 seconds, effects 8), found to loop or end, and
converted to AY register states a logic tick (tools/arcade/opl2ay.py): music on six voices
(AY 2 and AY 3), effects on three (AY 1). Writes, under build/ and never committed:

  build/e5/captures/cmdNNN.bin      the MAME captures
  build/assets/sound.bin            the sound pages: the directory, then every stream
  build/assets/sound_cues.asm       the pages and the cue tables src/next/sound.asm reads
  build/assets/sound_model.json     every cue's ticks as converted, for tools/checksound.py

The stream format is src/next/sound.asm's. A music cue that loops is cut at the end of its
first full repeat and jumps back to where the repeat starts: LOOPS finds the shortest
repeat of the key-on sequence (channel, block, frequency) that holds to the end of the
capture with the same timing, and its length is rounded to whole ticks.
"""
import json
import os
import struct
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import opl2ay                                   # noqa: E402

CUES = "tools/arcade/sound-cues.json"
CAPTURES = "build/e5/captures"
OUT = "build/assets"
SND_PAGE0 = 108                                 # 8K pages 108 on (banks 54 on): 2MB machines
MUSIC_SECONDS, EFFECT_SECONDS = 150, 8
TICK = 0.02


def capture(cmd, seconds):
    path = f"{CAPTURES}/cmd{cmd:03d}.bin"
    if not (os.path.exists(path) and os.path.getsize(path) > 0):
        os.makedirs(CAPTURES, exist_ok=True)
        env = dict(os.environ, SOUND_CMD=str(cmd), SOUND_OUT=path, SOUND_SECONDS=str(seconds))
        subprocess.run(["mame", "athena", "-rompath", "data/arcade", "-homepath", "/tmp/mame",
                        "-cfg_directory", "/tmp/mame/cfg", "-nvram_directory", "/tmp/mame/nvram",
                        "-video", "none", "-sound", "none", "-nothrottle", "-skip_gameinfo",
                        "-autoboot_script", "tools/arcade/soundcmd.lua"],
                       env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if not os.path.exists(path) or os.path.getsize(path) == 0:
            sys.exit(f"mksound: MAME made no capture of command {cmd} (is data/arcade/athena.zip there?)")
    return opl2ay.load(path)


def keyons(recs, chip):
    reg, on, ev = {}, {}, []
    for t, c, r, v in recs:
        if c != chip:
            continue
        reg[r] = v
        if 0xB0 <= r <= 0xB8:
            ch = r - 0xB0
            k = bool(v & 0x20)
            if k and not on.get(ch):
                ev.append((t, ch, (v >> 2) & 7, reg.get(0xA0 + ch, 0) | ((v & 3) << 8)))
            on[ch] = k
    return ev


def loop_of(recs, chip):
    """(start seconds, length seconds) of the repeat that holds to the end, or None."""
    ev = keyons(recs, chip)
    n = len(ev)
    notes = [e[1:] for e in ev]
    times = [e[0] for e in ev]
    for start in range(0, min(n // 3, 400)):
        for j in range(start + 4, n - 4):
            if notes[j] != notes[start]:
                continue
            p = j - start
            if n - start < 2 * p:
                break
            period = times[j] - times[start]
            if all(notes[k] == notes[k + p] and abs((times[k + p] - times[k]) - period) < 30000
                   for k in range(start, n - p)):
                return times[start] / 1e6, period / 1e6
    return None


def encode(frames, nvoices, loop_tick):
    """(bytes, offset of the loop tick) - loop_tick None for a cue that ends."""
    out, prev, loop_at = bytearray(), [None] * nvoices, None
    for t, f in enumerate(frames):
        if t == loop_tick:
            loop_at = len(out)
            prev = [None] * nvoices             # the loop point sets every voice
        mask, body = 0, bytearray()
        for v in range(nvoices):
            period, vol = f[v]
            if (period, vol) != prev[v]:
                mask |= 1 << v
                body += bytes([period & 255, vol << 4 | (period >> 8) & 15])
                prev[v] = (period, vol)
        out.append(mask)
        out += body
    out.append(0xC0 if loop_tick is not None else 0x80)
    return bytes(out), loop_at


def main():
    cues = json.load(open(CUES))
    music = {cues["setting_off"], cues["final_guardian"]} | set(cues["world_theme"].values()) | \
        set(cues["guardian_theme"].values()) | \
        {v for k, v in cues["tunes"].items() if k != "about" and isinstance(v, int) and v}
    effects = {cues["guardian_hit"], cues["guardian_destroyed"], cues["swing"], cues["jump"]} | \
        {v for k, v in cues["effects"].items() if k != "about" and v}
    ins_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "instruments.json")
    instruments = json.load(open(ins_path)) if os.path.exists(ins_path) else {}
    streams, model = {}, {}
    for cmd in sorted(music | effects):
        is_music = cmd in music
        chip, nv = (0, 6) if is_music else (1, 3)
        recs = capture(cmd, MUSIC_SECONDS if is_music else EFFECT_SECONDS)
        writes = [r for r in recs if r[1] == chip]
        loop = loop_of(recs, chip) if is_music else None
        if loop:
            loop_tick = round(loop[0] / TICK)
            ticks = loop_tick + round(loop[1] / TICK)
        else:
            loop_tick = None
            ticks = int((writes[-1][0] / 1e6 if writes else 0) / TICK) + 25
        frames, patches, drums = opl2ay.convert(recs, chip, nv, ticks, instruments)
        if not loop:
            while len(frames) > 1 and all(v[1] == 0 for v in frames[-1]):
                frames.pop()
        data, loop_at = encode(frames, nv, loop_tick)
        streams[cmd] = (data, loop_at)
        model[cmd] = dict(kind="music" if is_music else "effect", voices=nv, ticks=len(frames),
                          loop_tick=loop_tick, frames=frames, bytes=len(data), drums=drums)
        print(f"  command {cmd}: {'music' if is_music else 'effect'}, {len(frames)} ticks"
              f"{f', loops from tick {loop_tick}' if loop else ''}, {len(data)} bytes", flush=True)
    # the pages: directory, then the streams
    blob = bytearray(b"AS") + bytes(6 * 256)
    for cmd, (data, loop_at) in sorted(streams.items()):
        at = len(blob)
        blob += data
        loop = at + (loop_at if loop_at is not None else 0)
        entry = bytes([SND_PAGE0 + at // 0x2000]) + (at % 0x2000).to_bytes(2, "little") + \
            bytes([SND_PAGE0 + loop // 0x2000]) + (loop % 0x2000).to_bytes(2, "little")
        blob[2 + 6 * cmd:8 + 6 * cmd] = entry
        model[cmd]["offset"] = at
    pages = (len(blob) + 0x1FFF) // 0x2000
    os.makedirs(OUT, exist_ok=True)
    open(f"{OUT}/sound.bin", "wb").write(blob)
    tunes = [(int(k, 16), v) for k, v in cues["tunes"].items() if k != "about"]
    code = {"intro": 0xFD, "theme": 0xFE}
    lines = ["; Generated by tools/arcade/mksound.py from tools/arcade/sound-cues.json. Not committed.",
             f"SND_PAGE0               EQU {SND_PAGE0}",
             f"SND_PAGES               EQU {pages}",
             f"CUE_SETTING_OFF         EQU {cues['setting_off']}",
             f"CUE_GUARDIAN_HIT        EQU {cues['guardian_hit']}",
             f"CUE_FINAL_GUARDIAN      EQU {cues['final_guardian']}",
             f"CUE_GUARDIAN_DESTROYED  EQU {cues['guardian_destroyed']}",
             f"CUE_SWING               EQU {cues['swing']}",
             f"CUE_JUMP                EQU {cues['jump']}",
             "tune_sites:"]
    for site, v in tunes:
        lines.append(f"        dw ${site:04X} : db {code.get(v, v)}")
    lines.append("        dw 0")
    lines.append("world_theme:    db " + ", ".join(str(cues["world_theme"][str(w)]) for w in range(1, 8)))
    lines.append("guardian_theme: db " + ", ".join(str(cues["guardian_theme"][str(w)]) for w in range(1, 8)))
    fx = [cues["effects"].get(str(n), 0) for n in range(13)]
    lines.append("fx_cue:         db " + ", ".join(str(v) for v in fx))
    open(f"{OUT}/sound_cues.asm", "w").write("\n".join(lines) + "\n")
    json.dump({str(k): v for k, v in model.items()}, open(f"{OUT}/sound_model.json", "w"))
    print(f"mksound: {len(streams)} cues, {len(blob)} bytes in {pages} pages from {SND_PAGE0}")


if __name__ == "__main__":
    main()
