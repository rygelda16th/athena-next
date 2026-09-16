# Difficulty - what makes Athena hard, and the controls E6 can offer

D4, 2026-09-17. Every effect here was tested with scripted runs of the original from a
world snapshot, against the same run unpoked (`build/d4/combat`, `build/d4/items`), and
checked by an adversarial review. The addresses are the 64K view (bank 0 at `$C000`).
E6's options default to the original; the oracle runs with all of them off.

## Why it is hard

- **Contact is expensive.** Standing still at the start of world 1 with no armour, a life
  lasts about 8-14 seconds: every pass an enemy shares the player's cell calls the
  energy-loss routine (`$BEFE`), which takes a unit on every second call, from a bar of
  11 units. Armour stretches the gap between calls (total T of the three pieces:
  every (T/2 + T/4 + 1)th contact pass), and wears away.
- **Standing blows miss small enemies.** A standing blow reaches the upper of the
  player's two map rows; the small enemies at the start of world 1 walk in the lower
  row, so they have to be hit crouching - and the starting weapon, the kick, cannot
  strike from a crouch at all.
- **Five lives, three continues, none in world 7**, five minutes a world, and the clock
  is not reset by a lost life.

## The published POKEs, as they really behave in the 128K version

| Address | Instruction | POKE | What it does | Beware |
|---|---|---|---|---|
| `$CCAD` | `DEC (HL)` on the lives digit | 0 | lives never go down | the game can no longer end by OUT OF LIFE (it still ends by OUT OF TIME, the abort key or completing world 7) |
| `$CCBA` | `DEC A` on Credits | **`$B7` (OR A)** | CONTINUE? offered every time | **0 ends the game at once** (the flags left by the compare before it say "no credits") |
| `$CCED` | `DEC A` on the CONTINUE? countdown | 0 | the countdown stays on 9 | not infinite continues: infinite time to answer; the game waits for a key |
| `$CD13`, `$CD14` | `JR Z` after the item `$61` test | `$18`, `$10` | a lost life keeps carried items, armour, flight, immunity | **`$CD13` alone still empties the tenth item slot** |
| `$BF10` | `DEC (HL)` on EnergyUnits | 0 | energy never goes down | the bar grows one unit on every loss and, past row 23, draws over the attribute file, the font and the player graphics; also NOP `$BF14` |
| `$D4F2` | `JP NZ,$C553` (the immunity test) | `$C3` | enemy contact never costs energy or wears armour | contact is silent; the time drain and the feathered blade still cost energy |
| `$DAF4` | high byte of `LD HL,$B94D` in the clock tick | 0 | the clock stops | **every tick then looks like a seconds wrap: a poison drain runs ten times faster**. Safer: `JP $DB1C` at `$D089` (freezes the clock, and also switches off the drain) |
| `$C76C` | `DEC A` on JumpCounter | 0 | a jump never runs out: the player rises until the cell above is solid | lets the player skip platforms |

## Controls for E6

| Lever | Where | Original |
|---|---|---|
| Lives at a new game and a continue | digit loaded at `$C1E2` (shown as one digit) | 5 |
| Continues | Credits operand `$CCB9`, set at `$BD0E` (new game) and `$BE74` (world 7) | 3, none in world 7 |
| Time to answer CONTINUE? | start digit at `$CCD1`, 50 frames a step at `$CCE6` | 9, 10 seconds |
| Contact damage | every-second-call test in `$BEFE` (`$BF01`-`$BF04`, shared with the drain and the blade); the armour count at `$D4F9`-`$D50D`; `$D4F2` | a unit every second contact pass without armour |
| Immunity length (item `$6D`, and `$63`) | operand of `LD A,$C8` at `$DC54` | 200 passes, about 16 s |
| Energy at a new game | `LD A,$0B` at `$BF42` (room for 19, `$BF3C`) | 11 units |
| Poison drain (item `$70`) | the call at `$DB03`; set at `$DC71` | a unit every 20 clock seconds |
| Clock per world | minutes at `$BDAF`; 13 passes a clock second (`$D086`) | 5:00 |
| Guardian strength | `CP $50` at `$D818` (damage sprites from 64, `$D588`) | 80 damage |
| Keep objects on a lost life | `$CD13`-`$CD14` as above | item `$61` only |
| Feathered blade's energy cost | `CALL Z,$BEFE` at `$DA42`; taken away below 4 units at `$D025`-`$D038` | a unit every second blast |

Bug fixes worth offering as separate options (D3, D4): the world 7 enemy list damaged at
the world change (`$C169`), world 7's guardian column `$FF` still matching, the full item
panel overwriting the tenth slot (`$DBE4`), and energy regained by items `$63` and `$6C`
without redrawing the bar.
