#!/usr/bin/env python3
"""Gate E6: the controls and the options do what they say, and cost the original nothing.

    make check-options      (inside the container)

With every option off the game is the original: the oracle builds do not even contain
the options (make check-oracle), and the play build's bytes are the snapshot's outside
the listed patches (make check-play). This check drives the play build in ZEsarUX, with
its esxDOS handler standing in for the SD card (build/e6/sd):

  1. the pad answers the original's keyboard-only wait under the credits (the engine's
     E_PAD_TEST stands in for port $1F: ZEsarUX has no Mega Drive pad);
  2. the control menu shows 6 OPTIONS, and key 6 opens the options screen;
  3. each preset writes its levers into the game's operands (tools/nexpatches.py,
     OPTION_SITES), and back to ORIGINAL restores every byte;
  4. each lever changes its own site and makes the preset OWN; the bug-fix switch puts
     the fixes in and takes them out; classic mode turns the enhanced picture and sound off;
  5. SAVE writes the settings to the card, and a fresh start loads and applies them;
  6. a game started with 9 lives, 19 energy and 9 minutes has them;
  7. in play with KEMPSTON chosen, the pad's second button sets the up (jump) flag and
     Start the pause flag.
"""
import os
import shutil
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from zrcp import Zrcp               # noqa: E402
import checknex                     # noqa: E402
import nexpatches                   # noqa: E402

PORT = int(os.environ.get("ZRCP_PORT", "10010"))
SD = "build/e6/sd"
ENG = 0x40000 + checknex.ENGINE_RAM_PAGE * 8192
E_OPT, E_PAD_TEST, E_OPT_SD, E_CLASSIC = 0xA0, 0xB1, 0xB2, 0xB3
OPT_COUNT = 15
FAILS = []
# preset -> the levers 1-11 (src/next/options.asm, presets)
PRESETS = [[5, 3, 0, 11, 1, 1, 5, 0, 0, 1, 1], [7, 5, 1, 15, 1, 2, 7, 1, 0, 1, 1], [9, 9, 2, 19, 1, 2, 9, 2, 1, 0, 0]]


def check(ok, what, detail=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {what}" + (f"  [{detail}]" if detail else ""), flush=True)
    if not ok:
        FAILS.append(what)


class Next:
    def __init__(self):
        self.z = Zrcp(port=PORT, timeout=60)

    def eng(self, off, n):
        self.z.cmd("set-memory-zone 0")
        try:
            return bytes.fromhex(self.z.cmd(f"read-memory {ENG + off} {n}").replace("\n", "").strip())
        finally:
            self.z.cmd("set-memory-zone -1")

    def poke(self, off, value):
        self.z.cmd("set-memory-zone 0")
        try:
            self.z.cmd(f"write-memory {ENG + off} {value}")
        finally:
            self.z.cmd("set-memory-zone -1")

    def mem(self, addr, n):
        return checknex.mem(self.z, addr, n)

    def pc(self):
        return int(self.z.cmd("get-registers").split("PC=")[1][:4], 16)

    def key(self, k, hold=0.3):
        code = k if isinstance(k, int) else ord(k)
        self.z.cmd(f"send-keys-event {code} 1")
        time.sleep(hold)
        self.z.cmd(f"send-keys-event {code} 0")
        time.sleep(hold + 0.2)

    def until(self, test, seconds=10):
        t = time.time()
        while time.time() - t < seconds:
            if test():
                return True
            time.sleep(0.2)
        return False


def expected_bytes(levers, fixes):
    lives, cont, ctime, energy, contact, immune, clock, guard, keep, poison, blade = levers
    want = {0xC1E3: 0x30 + lives, 0xBD0D: cont + 1, 0xCCE7: 50 * (ctime + 1), 0xBF43: energy,
            0xD4F2: 0xC2 if contact else 0xC3, 0xDC55: (100, 200, 255)[immune], 0xBDAE: clock,
            0xD819: (80, 64, 48)[guard], 0xCD13: 0x18 if keep else 0x28, 0xDB03: 0xCD if poison else 0x21,
            0xDA42: 0xCC if blade else 0x21}
    return want


def compare_sites(n, levers, fixes):
    want = expected_bytes(levers, fixes)
    bad = [f"${a:04X} {n.mem(a, 1)[0]:02X} want {v:02X}" for a, v in want.items() if n.mem(a, 1)[0] != v]
    for a, orig in nexpatches.OPTION_SITES:
        if len(orig) == 3 and a != 0xCC24:
            got = n.mem(a, 3)
            if (got == orig) == bool(fixes):
                bad.append(f"fix ${a:04X} {'not in' if fixes else 'still in'}: {got.hex()}")
    return bad


def start(fresh):
    if fresh and os.path.exists(SD):
        shutil.rmtree(SD)
    os.makedirs(SD, exist_ok=True)
    subprocess.Popen(["zesarux", "--vo", "null", "--ao", "null", "--machine", "tbblue", "--enable-remoteprotocol",
                      "--remoteprotocol-port", str(PORT), "--enable-breakpoints", "--tbblue-max-turbo-rom", "8",
                      "--tbblue-max-turbo-everywhere", "8", "--nosplash", "--noconfigfile",
                      "--enable-esxdos-handler", "--esxdos-root-dir", f"/work/{SD}", "--nex-no-automount-esxdos",
                      "--joystickemulated", "Kempston"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(3)
    n = Next()
    checknex.load(n.z, "build/athena.nex")
    time.sleep(3)
    return n


def to_menu(n):
    n.poke(E_PAD_TEST, 0x80)                # Start on the pad answers the credits' wait
    shown = n.until(lambda: 0xF1E7 <= n.pc() <= 0xF23D, 5)
    n.poke(E_PAD_TEST, 0)
    shown = shown or n.until(lambda: 0xF1E7 <= n.pc() <= 0xF23D, 5)
    return shown


def main():
    print("E6 controls and options:")
    n = start(True)
    check(to_menu(n), "the pad's Start answers the credits screen's keyboard-only wait",
          f"PC ${n.pc():04X}")
    pixels = sum(bin(b).count("1") for line in range(8) for b in n.mem(0x4000 + (14 * 8 + line) * 32 + 10, 9))
    check(pixels > 40, "the control menu shows 6 OPTIONS on row 14", f"{pixels} pixels set")
    n.key("6")
    opened = n.until(lambda: n.pc() < 0x2000, 3)
    title = sum(bin(b).count("1") for line in range(8) for b in n.mem(0x4000 + (2 * 8 + line) * 32 + 12, 7))
    check(opened and title > 30, "key 6 opens the options screen", f"PC ${n.pc():04X}, {title} title pixels")
    # presets: the cursor is on PRESET
    opts = n.eng(E_OPT, OPT_COUNT)
    check(list(opts[1:12]) == PRESETS[0] and opts[0] == 0, "the settings start as the original", opts.hex())
    for preset in (1, 2):
        n.key("p")
        opts = n.eng(E_OPT, OPT_COUNT)
        bad = compare_sites(n, PRESETS[preset], False)
        check(opts[0] == preset and list(opts[1:12]) == PRESETS[preset] and not bad,
              f"preset {('EASIER', 'EASY')[preset - 1]} writes its levers into the game", "; ".join(bad[:4]))
    n.key("p")                              # OWN: the levers stay
    n.key("p")                              # back to ORIGINAL
    unchanged = [f"${a:04X}" for a, orig in nexpatches.OPTION_SITES if n.mem(a, len(orig)) != orig]
    check(n.eng(E_OPT, 1)[0] == 0 and not unchanged, "ORIGINAL puts every byte back", ", ".join(unchanged))
    # each lever: one step right from ORIGINAL
    levers = list(PRESETS[0])
    for row in range(1, 12):
        n.key("a")
        n.key("p")
        opts = n.eng(E_OPT, OPT_COUNT)
        lo_hi = [(1, 9), (0, 9), (0, 2), (5, 19), (0, 1), (0, 2), (3, 9), (0, 2), (0, 1), (0, 1), (0, 1)][row - 1]
        levers[row - 1] = levers[row - 1] + 1 if levers[row - 1] < lo_hi[1] else lo_hi[0]
        bad = compare_sites(n, levers, False)
        check(list(opts[1:12]) == levers and opts[0] == 3 and not bad, f"lever {row} changes its own site",
              "; ".join(bad[:3]) or opts.hex())
    n.key("a")
    n.key("p")                              # EVERY ENEMY on
    check(n.mem(0xCC24, 3) != bytes.fromhex("dd3502"), "the every-enemy switch changes the ledge step",
          n.mem(0xCC24, 6).hex())
    n.key("p")
    check(n.mem(0xCC24, 3) == bytes.fromhex("dd3502"), "and puts it back")
    n.key("a")
    n.key("p")                              # BUG FIXES on
    check(not compare_sites(n, levers, True), "the bug-fix switch puts the four fixes in",
          "; ".join(compare_sites(n, levers, True)[:3]))
    n.key("p")
    check(not compare_sites(n, levers, False), "and takes them out again")
    n.key("a")
    n.key("p")                              # CLASSIC on
    check(n.eng(E_CLASSIC, 1)[0] == 1, "classic mode switches on")
    n.key("p")
    check(n.eng(E_CLASSIC, 1)[0] == 0, "and off")
    # lives 9, energy 19, minutes 9 for the game below; then SAVE
    saved_want = None
    for row, value in ((1, 9), (4, 19), (7, 9)):
        for _ in range(20):
            if n.eng(0xB0, 1)[0] == row:
                break
            n.key("q" if n.eng(0xB0, 1)[0] > row else "a", 0.15)
        for _ in range(20):
            if n.eng(E_OPT + row, 1)[0] == value:
                break
            n.key("p", 0.15)
        check(n.eng(E_OPT + row, 1)[0] == value, f"option {row} set to {value}", n.eng(E_OPT, OPT_COUNT).hex())
    for _ in range(20):
        if n.eng(0xB0, 1)[0] == OPT_COUNT:
            break
        n.key("a", 0.15)
    saved_want = n.eng(E_OPT, OPT_COUNT)
    n.key(32)                               # SPACE
    n.until(lambda: 0xF1E7 <= n.pc() <= 0xF23D, 8)
    path = f"{SD}/athena.cfg"
    ondisk = open(path, "rb").read() if os.path.exists(path) else b""
    check(n.eng(E_OPT_SD, 1)[0] == 2 and ondisk == saved_want, "SAVE writes the settings to the card",
          f"result {n.eng(E_OPT_SD, 1)[0]}, file {ondisk.hex()}, settings {saved_want.hex()}")
    n.z.cmd("exit-emulator")
    time.sleep(2)
    # a fresh start: loaded at the menu, applied; then a game
    n = start(False)
    to_menu(n)
    loaded = n.eng(E_OPT, OPT_COUNT)
    check(n.eng(E_OPT_SD, 1)[0] == 1 and loaded == saved_want and n.mem(0xC1E3, 1) == b"9",
          "a fresh start loads the settings from the card and applies them", loaded.hex())
    n.key("2")                              # KEMPSTON
    playing = n.until(lambda: n.mem(0xB94B, 1)[0] != 0 and n.eng(0x19, 2) != b"\0\0", 20)
    time.sleep(3)
    got = (n.mem(0xC1EE, 1)[0], n.mem(0xBF1B, 1)[0], n.mem(0xB94B, 1)[0])
    check(playing and got[:2] == (ord("9"), 19) and got[2] in (9, 8), "a game starts with 9 lives, 19 energy and 9 minutes",
          f"lives digit {chr(got[0])}, energy {got[1]}, minutes {got[2]}")
    n.poke(E_PAD_TEST, 0x20)                # the pad's C button
    time.sleep(1)
    up = n.mem(0xBAB5, 1)[0]
    n.poke(E_PAD_TEST, 0x80)                # Start
    time.sleep(1)
    pause = n.mem(0xBAB7, 1)[0]
    n.poke(E_PAD_TEST, 0)
    check(up == 0 and pause == 0, "with KEMPSTON, the pad's C button jumps and Start pauses",
          f"up flag {up}, pause flag {pause}")
    n.z.cmd("exit-emulator")
    if FAILS:
        sys.exit(f"\nE6 check-options FAILED: {len(FAILS)} check(s)")
    print("\nE6 check-options passed")


if __name__ == "__main__":
    main()
