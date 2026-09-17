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
    (0xD06F, bytes.fromhex("ccedc2")),       # the pause's key wait -> CALL Z,eng_pause (E2)
    (0xD137, bytes.fromhex("cdfaeb")),       # the play area's copy -> CALL eng_copy (E2)
    (0xD991, bytes.fromhex("fb76")),         # the feathered blade's wait -> RST $30, 2
    (0xDEC6, bytes.fromhex("ed73cfde")),     # the tune player -> JP eng_tune; NOP
    (0xC553, bytes.fromhex("cd8dba")),       # the main loop's head -> CALL eng_passhead (E3)
    (0xEB1C, bytes.fromhex("f3ed73")),       # the 32-pixel drawer -> JP eng_d32 (E3)
    (0xEB72, bytes.fromhex("f3ed73")),       # the 16-pixel drawer -> JP eng_d16 (E3)
    (0xEBB0, bytes.fromhex("f3ed73")),       # the 24-pixel drawer -> JP eng_d24 (E3)
    (0xEDB4, bytes.fromhex("f3ed73")),       # the player's background copy -> JP eng_pbg (E3)
    (0xEDD5, bytes.fromhex("f3ed73")),       # a player piece -> JP eng_play (E3)
]

# Written while the game runs, and only with the arcade sound on (E5, src/next/sound.asm
# snd_beeper): the original's speaker writes, OUT ($FE),A, become JR $+2 so its effect
# and tune players still pace the game but make no sound. Left out of the hashes in
# every build; checknex.py does not expect them patched.
RUNTIME_PATCHES = [(a, bytes.fromhex("d3fe")) for a in
                   (0xC444, 0xDF78, 0xDF8A, 0xE004, 0xE00C, 0xE017, 0xE020, 0xE02C, 0xE033, 0xE03F, 0xE049, 0xE155)]


# Play builds only (E6, src/next/options.asm): the oracle builds keep the original's
# controls. checknex.py's play check expects these; the oracle's hashes never see them.
PLAY_PATCHES = [
    (0xC2E5, bytes.fromhex("afdbfe")),       # AnyKeyHeld -> JP eng_anykey (a pad button counts)
    (0xF1E4, bytes.fromhex("cd92c2")),       # the control menu's CALL $C292 -> CALL eng_menu_print
    (0xF23A, bytes.fromhex("c2e7f1")),       # JP NZ,$F1E7 -> JP NZ,eng_menu_more (6 OPTIONS)
    (0xF472, bytes.fromhex("afdb1f")),       # the Kempston template -> JP eng_kempston (MD pad)
]

# Written by the options (play builds, src/next/options.asm opt_apply): each lever's operand
# or instruction, and the bug fixes' three bytes. Original bytes while every option is off.
OPTION_SITES = [
    (0xC1E3, bytes.fromhex("35")),           # lives digit
    (0xBD0D, bytes.fromhex("04")),           # continues + 1 at a new game
    (0xCCE7, bytes.fromhex("32")),           # frames a CONTINUE? step
    (0xBF43, bytes.fromhex("0b")),           # energy at a new game
    (0xD4F2, bytes.fromhex("c2")),           # JP NZ: contact harms unless immune
    (0xDC55, bytes.fromhex("c8")),           # immunity passes
    (0xBDAE, bytes.fromhex("05")),           # minutes a world
    (0xD819, bytes.fromhex("50")),           # guardian damage to destroy
    (0xCD13, bytes.fromhex("28")),           # JR Z: keep items only with item $61
    (0xDB03, bytes.fromhex("cd")),           # CALL $BEFE: the poison drain
    (0xDA42, bytes.fromhex("cc")),           # CALL Z,$BEFE: the blade's cost
    (0xC58B, bytes.fromhex("3a5cb9")),       # fix: world 7's guardian column
    (0xDBEF, bytes.fromhex("afcda2")),       # fix: a full item panel
    (0xDC51, bytes.fromhex("c35ebf")),       # fix: energy redrawn
    (0xD874, bytes.fromhex("b7c847")),       # fix: a heart is not an enemy
    (0xCC24, bytes.fromhex("dd3502")),       # every enemy: the ledge step-back stays in bounds
]


def addresses():
    return {a + i for a, orig in ENGINE_PATCHES + RUNTIME_PATCHES for i in range(len(orig))}


def verify(view):
    """Raise if the snapshot does not hold the original bytes at every site."""
    for a, orig in ENGINE_PATCHES + RUNTIME_PATCHES:
        if bytes(view[a:a + len(orig)]) != orig:
            raise ValueError(f"engine patch site ${a:04X} holds {bytes(view[a:a + len(orig)]).hex()}, "
                             f"expected {orig.hex()}")
