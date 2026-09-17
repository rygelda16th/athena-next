#!/usr/bin/env python3
"""E5: the arcade's FM music and effects, converted to the Next's AY chips.

    python3 tools/arcade/opl2ay.py CAPTURE [--chip 0|1] [--voices N] [--loop START,LENGTH] -> AY frames

Input: a capture from tools/arcade/soundcmd.lua (time, chip, register, value for the arcade
board's two YM3526 FM chips). Output: one AY register state per 50 Hz tick (the Next's
logic tick), for up to 6 music voices (AY 1 and 2) or 3 effect voices (AY 0).

THE CONVERSION (the method of wolf3d-next's music.inc, for this chip's clock):
  - each FM channel's frequency number and block give the note:
    f = fnum x 55,556 / 2^(20 - block) Hz (the chips run at 4 MHz: 4,000,000 / 72);
    AY period = 1,750,000 / (16 f)
  - loudness: the carrier's total level (0.75 dB a step) plus a model of its envelope:
    key-on starts at full level (attack is taken as instant), the decay rate brings it
    down to the sustain level, a sustaining patch holds there while the key is held, and
    the release rate brings it down after key-off (the decay and release times: rate r
    takes 39.3 s / 2^(r-1) from full to silence). In additive connection both operators
    sound, so the louder counts.
  - AY volume = 15 - attenuation / 2 dB, clamped
  - voices: channels keep the voice they got while they sound; a new note takes a free
    voice, or the quietest one.
The drum mode ($BD bit 5) is reported if a capture uses it; none of the captures so far do.
The instrument table (tools/arcade/instruments.json, keyed by a hash of each patch's
registers) can raise or lower a patch's volume and move it an octave: tuned by ear.
"""
import hashlib
import json
import os
import struct
import sys

CLOCK = 4000000 / 72
AY_CLOCK = 1750000
TICK_US = 20000
MOD_OPS = [0, 1, 2, 8, 9, 10, 16, 17, 18]


def load(path):
    d = open(path, "rb").read()
    return [struct.unpack("<IBBB", d[i * 7:i * 7 + 7]) for i in range(len(d) // 7)]


def decay_db_per_tick(rate):
    if rate == 0:
        return 0.0
    full_ms = 39300.0 / (2 ** (rate - 1))
    return 96.0 * (TICK_US / 1000.0) / full_ms


class Chip:
    def __init__(self):
        self.reg = [0] * 256
        self.env = [96.0] * 9          # dB below full, per channel carrier
        self.env_m = [96.0] * 9        # modulator (additive connection only)
        self.key = [False] * 9
        self.stage = ["off"] * 9       # decay, sustain, release, off
        self.drums = False

    def write(self, r, v):
        self.reg[r] = v
        if r == 0xBD and v & 0x20:
            self.drums = True
        if 0xB0 <= r <= 0xB8:
            ch = r - 0xB0
            on = bool(v & 0x20)
            if on and not self.key[ch]:
                self.env[ch] = 0.0
                self.env_m[ch] = 0.0
                self.stage[ch] = "decay"
            elif not on and self.key[ch]:
                self.stage[ch] = "release"
            self.key[ch] = on

    def patch(self, ch):
        mo, co = MOD_OPS[ch], MOD_OPS[ch] + 3
        regs = [self.reg[0x20 + mo], self.reg[0x20 + co], self.reg[0x40 + mo] & 0xC0, self.reg[0x40 + co],
                self.reg[0x60 + mo], self.reg[0x60 + co], self.reg[0x80 + mo], self.reg[0x80 + co],
                self.reg[0xC0 + ch]]
        return hashlib.sha1(bytes(regs)).hexdigest()[:10]

    def tick(self):
        for ch in range(9):
            co = MOD_OPS[ch] + 3
            dr, sl = self.reg[0x60 + co] & 15, (self.reg[0x80 + co] >> 4) * 3.0
            rr, sustain = self.reg[0x80 + co] & 15, bool(self.reg[0x20 + co] & 0x20)
            if sl >= 45:
                sl = 93.0
            st = self.stage[ch]
            if st == "decay":
                self.env[ch] = min(96.0, self.env[ch] + decay_db_per_tick(dr))
                if self.env[ch] >= sl:
                    self.env[ch] = sl
                    self.stage[ch] = "sustain" if sustain else "fall"
            elif st == "fall":
                self.env[ch] = min(96.0, self.env[ch] + decay_db_per_tick(rr))
            elif st == "release":
                self.env[ch] = min(96.0, self.env[ch] + decay_db_per_tick(rr))
            if self.env[ch] >= 96.0:
                self.stage[ch] = "off"

    def voice(self, ch, instruments):
        """(frequency Hz, attenuation dB, patch id) or None if silent."""
        if self.stage[ch] == "off":
            return None
        b0 = self.reg[0xB0 + ch]
        fnum = self.reg[0xA0 + ch] | ((b0 & 3) << 8)
        block = (b0 >> 2) & 7
        if fnum == 0:
            return None
        f = fnum * CLOCK / (1 << (20 - block))
        co = MOD_OPS[ch] + 3
        att = (self.reg[0x40 + co] & 63) * 0.75 + self.env[ch]
        pid = self.patch(ch)
        ins = instruments.get(pid, {})
        att -= ins.get("gain_db", 0)
        f *= 2 ** ins.get("octave", 0)
        if att >= 40:
            return None
        return (f, att, pid)


def convert(recs, chip_no, nvoices, ticks, instruments):
    chip = Chip()
    frames, voice_of, patches = [], {}, {}
    i = 0
    for t in range(ticks):
        end = (t + 1) * TICK_US
        while i < len(recs) and recs[i][0] < end:
            _, c, r, v = recs[i]
            if c == chip_no:
                chip.write(r, v)
            i += 1
        chip.tick()
        live = {}
        for ch in range(9):
            v = chip.voice(ch, instruments)
            if v:
                live[ch] = v
                patches.setdefault(v[2], 0)
                patches[v[2]] += 1
        # keep assignments; free voices of silent channels
        for ch in list(voice_of):
            if ch not in live:
                del voice_of[ch]
        used = set(voice_of.values())
        for ch in sorted(live, key=lambda c: live[c][1]):
            if ch in voice_of:
                continue
            free = [v for v in range(nvoices) if v not in used]
            if free:
                voice_of[ch] = free[0]
                used.add(free[0])
            else:
                # steal the quietest assigned channel's voice if this one is louder
                q = max(voice_of, key=lambda c: live[c][1])
                if live[q][1] > live[ch][1]:
                    voice_of[ch] = voice_of.pop(q)
        state = [(0, 0)] * nvoices
        for ch, v in voice_of.items():
            f, att, _ = live[ch]
            period = max(1, min(4095, round(AY_CLOCK / (16 * f))))
            vol = max(0, min(15, round(15 - att / 2)))
            state[v] = (period, vol)
        frames.append(state)
    return frames, patches, chip.drums


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("capture")
    ap.add_argument("--chip", type=int, default=0)
    ap.add_argument("--voices", type=int, default=6)
    ap.add_argument("--seconds", type=float, default=150)
    a = ap.parse_args()
    ins_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "instruments.json")
    instruments = json.load(open(ins_path)) if os.path.exists(ins_path) else {}
    frames, patches, drums = convert(load(a.capture), a.chip, a.voices, int(a.seconds * 50), instruments)
    sounding = sum(1 for f in frames if any(v[1] for v in f))
    print(f"{len(frames)} ticks, {sounding} sounding, {len(patches)} patches, drums {drums}")


if __name__ == "__main__":
    main()
