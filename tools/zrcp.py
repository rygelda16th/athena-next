"""Minimal ZEsarUX remote command protocol (ZRCP) client.

ZRCP is line-oriented telnet: send a command, read until the "command> " prompt.
This is the only channel the project uses for measurement, so it stays small and
stdlib-only.
"""

import contextlib
import socket
import time

PROMPT = "command>"
STEP_PROMPT = "command@cpu-step>"


class Zrcp:
    def __init__(self, host="127.0.0.1", port=10000, timeout=20.0):
        deadline = time.time() + timeout
        while True:
            try:
                self.sock = socket.create_connection((host, port), timeout=5)
                break
            except OSError:
                if time.time() > deadline:
                    raise
                time.sleep(0.5)
        self.sock.settimeout(timeout)
        self._read_until_prompt()

    def _read_until_prompt(self):
        # In step mode (enter-cpu-step) the prompt becomes "command@cpu-step>".
        buf = ""
        while PROMPT not in buf and STEP_PROMPT not in buf:
            chunk = self.sock.recv(65536)
            if not chunk:
                break
            buf += chunk.decode(errors="replace")
        return buf.split(STEP_PROMPT)[0].split(PROMPT)[0].strip()

    def cmd(self, text):
        self.sock.sendall((text + "\n").encode())
        return self._read_until_prompt()

    # --- conveniences ------------------------------------------------------

    def registers(self):
        """CPU registers as a dict of upper-case name -> int."""
        out = {}
        for token in self.cmd("get-registers").split():
            if "=" in token:
                name, _, value = token.partition("=")
                try:
                    out[name.upper()] = int(value, 16)
                except ValueError:
                    pass
        return out

    def pc(self):
        return self.registers().get("PC")

    def nextreg(self, index):
        return self.cmd(f"tbblue-get-register {index}")

    def run_to(self, address, timeout=30.0):
        """Continue until PC == address. Returns False on timeout."""
        self.cmd("run")
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self.pc() == address:
                return True
            time.sleep(0.05)
        return False

    @contextlib.contextmanager
    def sound_held(self, snd_hold):
        """Stop the interrupt borrowing MMU slot 3 while state is read.

        The music player lives in its own page and the sound interrupt swaps
        that page into slot 3 two hundred times a second, then puts back
        whatever was there. Slot 3 is also where the actor records, STAT_LIST
        and SPR_INDEX live - so a read that lands inside the borrow returns the
        player's own code where an actor should be. It shows up as one record
        in thirty being impossible, a different one each time, and it survives
        world_frozen and hold_flag because neither stops the interrupt.

        snd_hold is the program's own guard for this: the interrupt returns
        before it borrows anything. Freezing it for the length of a read is
        what every checker that reads the statics page has to do.

        Pass the address of snd_hold (sym["snd_hold"]).
        """
        self.cmd("set-memory-zone -1")
        self.cmd(f"write-memory {snd_hold} 1")
        time.sleep(0.05)                # let an interrupt already inside finish
        try:
            yield
        finally:
            self.cmd("set-memory-zone -1")
            self.cmd(f"write-memory {snd_hold} 0")

    def close(self):
        try:
            self.sock.sendall(b"exit\n")
        except OSError:
            pass
        self.sock.close()
