# Coverage - what ran, what did not, and why

Gate G2. Reproduce with `make g2` (or `make bank-exec`, `make scripts`,
`make skool`, `make coverage`). Established 2026-09-16.

## Where code runs

Two runs of evidence, merged into `build/g2/map-all.txt` (5,772 addresses):

- **Rafal's recording**, all 119,655 frames (`make rzx-end`): 5,566 addresses.
- **Six scripted runs from the title** (`make scripts`, `tools/scripts/*.py`,
  played on SkoolKit's C simulator with a key schedule): define keys answered N
  and Y, Kempston, cursor and Sinclair selected, and keyboard selected then left
  alone for twenty minutes of game time. They add 206 addresses the recording
  never reached: the define-keys routine from `$F355`, the game-over path from
  `$BCE6`, and the cursor and Sinclair input code.

The menu has a trap worth knowing (corrected at D1): the first key press only
closes the credits (`$C2ED`), then the menu waits until **all** keys are up
(`$C2F6`) before it polls the 1-5 row at `$F1E9`, so a key held from that first
press is ignored until released. The scripts tap: three frames down, twelve up,
repeated.

| Where | Executed addresses | What |
|---|---|---|
| ROM | 28 | the keyboard scan (`$028E`-`$02B2`, `$032C`-`$0332`) |
| `$4000-$B8B7` | 0 | screen, system variables, world area, world settings, IM 2 table |
| `$B8B8-$BFFF` | 445 | interrupt entry, world loader, paging, more |
| `$C000-$F4C3` | 5,299 | the main program (bank 0) |
| banks 1, 3, 4, 6, 7 | 0 | data only (below) |

### Code never runs from another bank (`make bank-exec`)

SkoolKit's code maps have no bank, so this was the first question. The recording
writes port `$7FFD` 25 times, all from the loader in bank 2: `$B8D2` pages the
world's bank, `$B8E4` pages bank 1, `$B902` pages bank 0 back - seven times,
once per world - and `$B911`/`$B923`, `$B92F`/`$B941` do the same for the ending
and the hi-score screens. Every frame in which a bank other than 0 was paged at
any point (49 of them) was traced instruction by instruction: 129,252
instructions were fetched while bank 1, 3, 4, 6 or 7 was in, and **none at
`$C000` or above**. The replay engine used for that trace ends in the same
128K state as SkoolKit's own `rzxplay.py`, all eight banks compared.

The one `LD BC,$7FFD` never executed, at `$89FD`, sits in the world area; it is
the tape loader's, and world 1's data overwrites it.

## Sound: the 128K version never touches the AY

Every port write in the recording, counted: `$7FFD` 25 times, `$FE` 368,992
times (from `$C444`, `$DF78`, `$DF8A`, `$E004`-`$E049` and `$E155`), and
**nothing to `$FFFD` or `$BFFD`**. All of Athena's sound, 128K included, is
beeper. The `LD BC,$FFFD` found at `$FB28` while planning is workspace left over
from loading, not code. This corrects the plan, which assumed 128K AY music.

## The islands no run executed, explained

`make coverage` lists every block from `$B6B5` up that no run executed, sorted by
what the executed code says about it (`build/g2/coverage.txt`). In the
skeleton's own terms: 1 island is branched to, 38 are addressed, 191 are
referenced by nothing - about 7,650 bytes. Grouped:

| Range | Bytes | What it is | Evidence |
|---|---|---|---|
| `$B6B5-$B8B7` | 515 | data, the IM 2 vector table, and the stack | all 257 bytes of `$B700-$B800` are `$B8` (I = `$B7`, handler `$B8B8`) and never change; the only bytes that change in play are `$B899-$B8B6`, just under SP (`$B8AD`-`$B8B7` in the in-play snapshots); addressed from `$C274`, `$ECC6`, `$F2A5` |
| `$B8BB-$B8C2` | 8 | the loader's two four-entry tables: offsets into bank 1, and `$7FFD` values | indexed by the byte at `$BDB3`, read by `$B8EC` and `$B8CA` |
| `$B949-$BA8C` | 324 | **game variables** | addressed from dozens of routines (time `$B94D`, `$B953`, `$BA2A`, ...); 51-93 bytes differ from the title in every world |
| `$BA8D-$BAD3` | 71 | **input routine rewritten at run time** | executed, but its bytes differ in play (29 of them, identically in worlds 1, 4, 7); the cursor and Sinclair runs execute `$BA93`-`$BA9F`, which the recording never did |
| `$BAD4-$BB17` | 68 | data after it | the one "branched-to" island: the branch at `$BAD2` exists only in the title-time bytes above |
| `$BB18-$BCE5` | ~460 | **the message table** | its strings are addressed one by one (`$BB18` from `$C284`, `$BBBF` from `$CCC8`, `$BC23` from `$C004`, ...); the unreferenced pieces between them are SkoolKit's generator splitting each message from its terminator |
| `$BF52`, `$C089`, `$DC25`, `$DC68`, `$DCAA`, `$E098` | 2-41 each | small data between routines | `$C089` read by `$C09B`/`$C0C6`; the rest to be placed by D1-D5 |
| `$E16A-$E445` | 732 | tables | addressed from `$DEFB`, `$E080`-`$E0E9` |
| `$E446-$E976` | 1,329 | constant data reached through pointers (graphics, most likely) | `$E46D`-`$E976` never changes in any world; nothing addresses any of it directly |
| `$EE03-$F1C8` | 966 | tables, including ones the define-keys and input code read | addressed from `$CF18`, `$CF6C`, `$D248`, `$F1EF`, `$F233`, `$F361`, `$F384`, `$F413` |
| `$F2AA-$F354` | 171 | the menu and credits text | addressed from `$F1DE` |
| `$F424-$F49D` | 122 | define-keys prompts and key names | addressed from `$F358`-`$F402` (define-keys code) |
| `$F4AC-$F4BB` | 16 | data inside the interrupt routine (`$F49E`-`$F4C3`) | not addressed directly |
| `$F4C6-$FFFF` | ~2,870 | **workspace** | 821-1,436 bytes of it differ from the title in every world; at the title it holds loader leftovers |

Every island listed in `build/g2/coverage.txt` falls inside one of these rows
(checked by script when this was written). Naming each table, message and
variable is the complete disassembly's job (D1-D7); this gate only has to show that nothing
unexplained is hiding as data.

## The skeleton

- `src/athena.ctl` - the 64K view, bank 0 at `$C000`: named regions from `$4000`
  to `$B6B4`, then SkoolKit's reading of the merged map (163 code blocks, 123
  data, 107 text).
- `src/bank1.ctl`, `bank3.ctl`, `bank4.ctl`, `bank6.ctl`, `bank7.ctl` - data.
- `make check-ctl`: ctl to skool to ctl is identical, and no ctl line holds an
  instruction or a data statement.
- `make check-reasm`: two sjasmplus builds - plain, and with every instruction
  labelled and every resolvable address replaced by its label - both reproduce
  all 131,072 bytes. The labelled build's 952 "unreplaced address" warnings are
  the measure of work left: references into the middle of blocks, constants
  that look like addresses (`$7FFD`), and code/data boundaries still to fix.
