# The oracle - proving the port is still the original game

Gate G3. Reproduce with `make g3` (or `make oracle-stream`, `make nex`,
`make check-play`, `make check-oracle`). Established 2026-09-16.

## What it is for

Every enhancement after G3 changes code that the original shares with its game
logic. The oracle is the test that says the logic did not change: Rafal's
forty-minute recording is replayed *through the port on a Next* and the game's
state is compared with the original's at 893 points along the way. It must hold
at 3.5 MHz and at 28 MHz, because the enhanced port will run at 28 MHz.

## Why replaying key presses is not enough

The first experiment asked whether the game's logic depends on how many
interrupts a main-loop pass spans. The in-game interrupt routine at `$E986` is
`EI; RETI` - it does nothing - so at first sight it does not. But:

- **The game reads the R register for randomness** (`LD A,R` at `$C5AC`, `$C5C8`,
  `$C5D2`, `$C6B1`, `$D11F`, `$D592`, `$DC89`, `$DDBC`). R counts every opcode
  the CPU fetches, including the ones it repeats while halted, so its value
  depends on CPU speed. Enemies would choose differently at 28 MHz.
- **Tunes are driven by interrupts.** The tune player (`$DEC6`) installs its own
  interrupt routines (`$DF90`, `$DFEF`) that count note lengths in the
  interrupted code's L register and, when a note ends, throw away a return
  address to abort the tone generator or the key-wait loop. How many port reads
  a note takes is a matter of timing.
- **Busy-wait loops** read the keyboard port as fast as the CPU allows (1,091,225
  reads at `$DF50`, 745,423 at `$C2E6`), so their read counts are timing too.

So the oracle replays *everything the game takes from outside*, not key presses.

## How it works

**The stream** (`make oracle-stream`, `tools/mkstream.py`). SkoolKit's C simulator
replays the recording with an instruction trace over all 119,655 frames and
records, in program order, every value the game took from a port or from R: the
site, the value A received and, where the instruction sets flags, F. Runs of
identical values are compressed. Every 1,024th event carries a hash of the game's
state; every 16,384th hashes all of `$5B00-$FFFF` except the stack, the input
routine rewritten at game start, the title interrupt's own counters, and every
patched byte. **Tunes are not replayed**: each of the 22 tunes that finish becomes one
record holding the bytes the tune changed (at most 24) and the registers it left,
and the 1,091,225 reads inside tunes are not in the stream. The result is 914,021
events in 141,374 records - 348,106 bytes.

**The check build** (`build/g3/athena-oracle-35.nex`, `-28.nex`). The game as
check-reasm rebuilt it, with 23 instructions patched into `RST $28` + a byte:
the 15 static sites and the Kempston routine's template (the recording's
control method), the seven `OUT (C),A` the world loader pages with, and the
`CALL $DED9` that plays a tune. The resume stub (`src/next/resume.asm`) starts
the game from the recording's own start state, and the handler
(`src/next/oracle.asm`) answers every `RST $28`:

- an event: check the site is the one the stream expects, hand back its value
  (and flags), and at a checkpoint hash the game's memory and compare;
- `$80`: page the RAM bank the loader asked for, through the MMU;
- `$82`: apply the tune record and continue at the tune's exit, `$DECD`.

A verdict block (status, events, checkpoints, the failing site or hash) lives in
the handler's variables page, and `tools/checknex.py` reads it by physical
address while the emulator runs.

## Four things that went wrong, and what they changed

1. **Replaying a tune diverged** 187,995 events in: at 20x emulator speed the
   port left a tune's key-wait loop at a different read. That is how the
   tune player's interrupt-driven control flow was found, and why tunes became a
   service instead of being replayed.
2. **The handler was destroyed by the game.** It first lived in RAM paged at
   `$0000-$3FFF`. Something in the game writes into `$0000-$3FFF` - on a Spectrum
   that is ROM and the writes vanish; in RAM they overwrote `JP handler` at `$0028`,
   found by stepping ZEsarUX 2,000 opcodes at a time until those three bytes
   changed. (This was first blamed on the text printer at `$C25x`; D2 showed that
   routine cannot address below `$4000`, so which instruction writes there is still
   open - `docs/disassembly.md`.) The handler now lives in the Next's
   **alternative ROM** (NextReg `$8C`): the stub copies the 48K ROM into it, adds
   the handler in the ROM's unused space from `$386E`, and write-protects it, so
   the game's stray writes are ignored exactly as on the original.
3. **A full checkpoint failed on 8 bytes that were all patch sites.** The game
   overwrites its menu code (all of `$F001`-`$F4FE`, patch sites included) with data during play, and the
   reference had hashed the patch bytes rather than what was really there. Patched
   bytes are now left out of every hash, on both sides.
4. **The recording ends inside a tune.** With all 914,021 events consumed and all
   893 checkpoints matched, the game called the tune player once more and the
   tune service found the end of the stream where it expected a tune record.
   Everything the recording holds had been replayed; the tune service now treats
   the end of the stream as the pass it is, as the event path always did.

## Emulator facts this depended on

- ZEsarUX treats NextReg `$8E` like a port write and remaps `$C000-$FFFF` even with
  bit 3 clear, contrary to the Next's documentation; the stub selects the ROM from
  16 bytes of game RAM, saved and put back, so either behaviour is safe.
- ZEsarUX's alternative ROM: `$8C` bits 7:6 = `11` writes to it while reads still
  come from the ROM; `10` reads it and ignores writes; bit 5 locks the 48K ROM.
- ZEsarUX's memory zone 0 on a Next puts RAM page n at `$40000 + n * 8192`.
- `--emulatorspeed 2000` runs the machine twenty times faster than real time.
- Headless ZEsarUX breakpoints (including memory breakpoints) do not stop the
  machine; `enter-cpu-step` plus `run N` in chunks, with `cpu-history`, does.
