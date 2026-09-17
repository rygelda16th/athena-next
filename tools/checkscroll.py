#!/usr/bin/env python3
"""Gate E4: the play area scrolls in hardware, smoothly, and shows only what it should.

    make check-scroll      (inside the container; runs an oracle build)

The oracle build replays Rafal's recording through the port. Every SAMPLE_EVERY
seconds this asks the engine for a frame in the middle of a scroll glide (src/next/
sprites.asm scroll_update, E_SCR_REQ): a frame 1-3 logic ticks after a pass set a new
Layer 2 offset different from the last. The engine keeps the old and new offsets, the
ticks, the offset it set that frame, the inputs of the pass's draw (window, shift,
world, the 120 map codes, the item and background blocks) and the 128 lines of Layer 2.
The checker:

  - recomputes the new offset from the window and shift (tools/l2ref.py);
  - checks the offset shown is old + (new - old) x ticks / 4, rounded down;
  - checks every pixel of the 208x128 play area, seen through that offset, comes from a
    Layer 2 slot this draw holds, and equals the recoloured cell the map puts there.

It passes when every sample matches, every world gives MIN_SAMPLES samples, and the
oracle reaches the end of the recording.
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from zrcp import Zrcp               # noqa: E402
import checknex                     # noqa: E402
import l2ref                        # noqa: E402
from checksprites import Machine    # noqa: E402

PORT = int(os.environ.get("ZRCP_PORT", "10010"))
NEX = os.environ.get("NEX", "build/g3/athena-oracle-28.nex")
TIMEOUT = int(os.environ.get("SCROLL_TIMEOUT", "7200"))
SAMPLE_EVERY = int(os.environ.get("SAMPLE_EVERY", "6"))
MIN_SAMPLES = int(os.environ.get("MIN_SAMPLES", "3"))
FAILS = []
SMOKE = int(os.environ.get("SMOKE", "0"))     # seconds: a short run for check-levels, which
                                               # asks only that what it saw matched


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""), flush=True)
    if not ok:
        FAILS.append(what)


def main():
    z = Zrcp(port=PORT, timeout=60)
    m = Machine(z)
    checknex.load(z, NEX)
    time.sleep(1)
    sheets = {w: l2ref.load_sheet(w) for w in range(1, 8)}
    started, last_req, per_world, samples = time.time(), 0, {}, 0
    last_done = m.eng(0x43, 1)[0]
    while time.time() - started < (SMOKE or TIMEOUT):
        if checknex.vars_block(z, 5)[4]:
            break
        done = m.eng(0x43, 1)[0]
        if done != last_done:
            last_done = done
            d = m.eng(0x500, 5 + 122)
            smp = m.eng(0x1700, 4)
            window, shift, world = d[0] | d[1] << 8, d[2], d[3]
            codes, item, background = list(d[5:125]), d[125], d[126]
            old, new, t, shown = smp
            lines = m.phys(0x40000 + 84 * 8192, 128 * 256)
            if not 1 <= world <= 7:
                continue
            samples += 1
            per_world[world] = per_world.get(world, 0) + 1
            bad = []
            if new != l2ref.layer2_offset(window, shift):
                bad.append(f"new offset {new}, want {l2ref.layer2_offset(window, shift)}")
            diff = (new - old + 128) % 256 - 128
            if shown != (old + ((diff * t) >> 2)) & 255:
                bad.append(f"shown {shown}, want {(old + ((diff * t) >> 2)) & 255} (old {old} new {new} t {t})")
            layer = l2ref.expected_layer(window, shift, world, codes, item, background, sheets[world])
            wrong = stale = 0
            for y in range(128):
                row = lines[256 * y:256 * y + 256]
                for x in range(208):
                    lx = (24 + x + shown) & 255
                    want = layer[y][lx]
                    if want is None:
                        stale += 1
                    elif row[lx] != want:
                        wrong += 1
            if wrong or stale:
                bad.append(f"{wrong} pixels wrong, {stale} from slots this draw does not hold")
            print(f"    {time.time() - started:6.0f} s  world {world}  offset {old}->{new} t {t} shown {shown}  "
                  f"{'match' if not bad else '; '.join(bad)}", flush=True)
            if bad:
                check(False, f"sample {samples} in world {world}", "; ".join(bad))
                if len(FAILS) > 5:
                    break
        elif time.time() - last_req > SAMPLE_EVERY and m.eng(0x42, 1)[0] == 0:
            m.poke_eng(0x42, 1)
            last_req = time.time()
        time.sleep(0.5)
    verdict = checknex.vars_block(z, 5)[4]
    if SMOKE:
        check(samples >= 3 and not FAILS, f"{samples} samples matched in {SMOKE} seconds")
    else:
        check(verdict == 1, "the oracle reached the end of the recording with the scroll in", f"status {verdict}")
        for world in range(1, 8):
            check(per_world.get(world, 0) >= MIN_SAMPLES, f"world {world} sampled", f"{per_world.get(world, 0)} samples")
    z.cmd("exit-emulator")
    if FAILS:
        sys.exit(f"\nE4 check-scroll FAILED: {len(FAILS)} check(s)")
    print("\nE4 check-scroll passed")


if __name__ == "__main__":
    main()
