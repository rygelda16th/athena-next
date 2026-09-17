#!/usr/bin/env python3
"""Gate E2: the play area on Layer 2 is exactly what the reference says.

    make check-render      (inside the container; runs the 28 MHz oracle build)

The oracle build replays Rafal's recording through the port, so every world is
played. Every SAMPLE_EVERY seconds this asks the engine to sample its next play-area
draw (src/next/render.asm, E_SAMPLE_REQ): the engine keeps the window and shift it
drew from, the world, the 120 map codes and the item and background blocks it used,
and copies the 128 lines of Layer 2 it drew into pages 84-87. The checker then:

  - recomputes the X offset from the window and shift (tools/l2ref.py) and compares it
    with the one the engine set;
  - builds the 208x128 play area the reference expects from the sampled inputs and the
    recoloured cell sheets (tools/mkassets.py), and compares it pixel for pixel with the
    sampled Layer 2 lines as the offset shows them. The sample copies the map codes
    straight from the game's memory, apart from the draw loop, so a draw that read
    the wrong cells shows up as a difference.

It passes when every sample matches, every world 1-7 was sampled at least MIN_SAMPLES
times, no map code pointed past a sheet, and the oracle itself reached its end.
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from zrcp import Zrcp               # noqa: E402
import checknex                     # noqa: E402
import l2ref                        # noqa: E402

PORT = int(os.environ.get("ZRCP_PORT", "10010"))
NEX = os.environ.get("NEX", "build/g3/athena-oracle-28.nex")
ENGINE_RAM_PAGE = checknex.ENGINE_RAM_PAGE
SAMPLE_PAGE0 = 84
SAMPLE_EVERY = 6
MIN_SAMPLES = 3
TIMEOUT = int(os.environ.get("RENDER_TIMEOUT", "7200"))
FAILS = []


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""), flush=True)
    if not ok:
        FAILS.append(what)


def phys(z, addr, n):
    z.cmd("set-memory-zone 0")
    try:
        out = bytearray()
        while n:
            take = min(n, 4096)
            out += bytes.fromhex(z.cmd(f"read-memory {addr} {take}").replace("\n", "").strip())
            addr += take
            n -= take
        return bytes(out)
    finally:
        z.cmd("set-memory-zone -1")


def eng(z, off, n):
    return phys(z, 0x40000 + ENGINE_RAM_PAGE * 8192 + off, n)


def write_eng(z, off, value):
    z.cmd("set-memory-zone 0")
    try:
        z.cmd(f"write-memory {0x40000 + ENGINE_RAM_PAGE * 8192 + off} {value}")
    finally:
        z.cmd("set-memory-zone -1")


def main():
    z = Zrcp(port=PORT, timeout=60)
    checknex.load(z, NEX)
    time.sleep(1)
    sheets = {w: l2ref.load_sheet(w) for w in range(1, 8)}
    per_world, samples, started = {}, 0, time.time()
    last_done = eng(z, 0x2C, 1)[0]
    last_request = 0
    while time.time() - started < TIMEOUT:
        verdict = checknex.vars_block(z, 5)[4]
        done = eng(z, 0x2C, 1)[0]
        if done != last_done:
            last_done = done
            s = eng(z, 0x400, 5 + 120 + 2)
            window, shift, world, offset = s[0] | s[1] << 8, s[2], s[3], s[4]
            codes, item, background = list(s[5:125]), s[125], s[126]
            lines = phys(z, 0x40000 + SAMPLE_PAGE0 * 8192, 128 * 256)
            layer2 = [lines[256 * y:256 * y + 256] for y in range(128)]
            if not 1 <= world <= 7:
                continue
            want_offset = l2ref.layer2_offset(window, shift)
            got = l2ref.visible(layer2, offset)
            want = l2ref.expected_from(window, shift, world, codes, item, background, sheets[world])
            bad = sum(1 for y in range(128) for x in range(208) if got[y][x] != want[y][x])
            samples += 1
            per_world[world] = per_world.get(world, 0) + 1
            ok = bad == 0 and offset == want_offset
            print(f"    {time.time() - started:6.0f} s  world {world}  window ${window:04X} shift {shift}  "
                  f"offset {offset} (want {want_offset})  {bad} pixels differ", flush=True)
            if not ok:
                check(False, f"sample {samples}: world {world} window ${window:04X} shift {shift}",
                      f"{bad} pixels differ, offset {offset} want {want_offset}")
                if len(FAILS) > 5:
                    break
        if verdict:
            break
        if time.time() - last_request > SAMPLE_EVERY and eng(z, 0x2B, 1)[0] == 0:
            write_eng(z, 0x2B, 1)
            last_request = time.time()
        time.sleep(1)
    verdict = checknex.vars_block(z, 5)[4]
    check(verdict == 1, "the oracle reached the end of the recording with the renderer in", f"status {verdict}")
    for world in range(1, 8):
        check(per_world.get(world, 0) >= MIN_SAMPLES, f"world {world} sampled",
              f"{per_world.get(world, 0)} samples")
    bad_cells = eng(z, 0x29, 2)
    check(bad_cells == b"\x00\x00", "no map code pointed past its cell sheet",
          f"{bad_cells[0] | bad_cells[1] << 8}")
    draws = eng(z, 0x25, 2)
    print(f"  {draws[0] | draws[1] << 8} play-area draws, {samples} sampled")
    z.cmd("exit-emulator")
    if FAILS:
        sys.exit(f"\nE2 check-render FAILED: {len(FAILS)} check(s)")
    print("\nE2 check-render passed")


if __name__ == "__main__":
    main()
