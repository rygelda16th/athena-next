"""Where the enhanced port reaches into the original game (src/next/patches.asm).

Each entry is (address, the original bytes there). tools/mkstream.py leaves every
one of these addresses out of the oracle's state hashes, because the port holds
different bytes there; tools/checknex.py checks the running game differs from the
snapshot at exactly these addresses (and the ones the game itself changes).
Addresses and bytes only - the same kind of fact a POKE list holds.
"""

ENGINE_PATCHES = [
    (0xB6B6, bytes.fromhex("00be00")),       # unused: JP eng_isr
    (0xB700, bytes([0xB8]) * 257),           # IM 2 vector table: every entry -> $B6B6
    (0xB8D2, bytes.fromhex("ed79")),         # the world loader's OUT (C),A: RST $30, 3
    (0xB8E4, bytes.fromhex("ed79")),
    (0xB902, bytes.fromhex("ed79")),
    (0xB911, bytes.fromhex("ed79")),
    (0xB923, bytes.fromhex("ed79")),
    (0xB92F, bytes.fromhex("ed79")),
    (0xB941, bytes.fromhex("ed79")),
    (0xC33B, bytes.fromhex("fb76")),         # DrawCarriedItems: EI; HALT -> RST $30, 2
    (0xC400, bytes.fromhex("fb762b")),       # WaitFrames -> JP eng_waitframes
    (0xC408, bytes.fromhex("e17e23")),       # the effect player -> JP eng_fx
    (0xCEFA, bytes.fromhex("fb76")),         # the pass's frame wait -> RST $30, 1
    (0xD04D, bytes.fromhex("fb76")),         # WorldCompleted's flash -> RST $30, 2
    (0xD991, bytes.fromhex("fb76")),         # the feathered blade's wait -> RST $30, 2
    (0xDEC6, bytes.fromhex("ed73cfde")),     # the tune player -> JP eng_tune; NOP
]


def addresses():
    return {a + i for a, orig in ENGINE_PATCHES for i in range(len(orig))}


def verify(view):
    """Raise if the snapshot does not hold the original bytes at every site."""
    for a, orig in ENGINE_PATCHES:
        if bytes(view[a:a + len(orig)]) != orig:
            raise ValueError(f"engine patch site ${a:04X} holds {bytes(view[a:a + len(orig)]).hex()}, "
                             f"expected {orig.hex()}")
