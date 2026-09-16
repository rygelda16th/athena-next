@ $4000 start
@ $4000 org
b $4000 Display file
D $4000 The screen at the moment the snapshot was saved: the title's credits page.
B $4000,6144,32
b $5800 Attribute file
B $5800,768,32
b $5B00 System variables and workspace
D $5B00 Not examined yet. Nothing in this range executes during the recording.
B $5B00,7008,16*406,8
b $7660 World area
D $7660 The loader at #R$B8C3 copies the whole of the current world's bank here (16,384 bytes, #R$7660 to $B65F). In the snapshot, taken at the title screen before any world was loaded, it still holds what the tape loader left behind.
@ $7660 label=WorldArea
B $7660,16384,16 A whole world bank (3, 4, 6 or 7) copied by #R$B8C3. It starts with two 23-byte world headers, at $7660 for the first world and $7677 for the second (bank 7's second header is mostly zero). The data they point to all lies inside the area, except world 4's list (from its header) and the world-7 text at $B5D3 (addressed directly by $D85C), both of which run on into #R$B660.
b $B660 The part of the world data that did not fit in its bank
D $B660 85 bytes that #R$B8C3 copies from bank 1 for the current world bank (see #R$B8BB), straight after the 16,384-byte world area. The world data runs on into them.
D $B660 In worlds 3 and 4 (bank 4) they are the end of world 4's list of enemy starts, whose 28 three-byte entries start at $B65E. So $B660 is byte 2 of the first entry, $B661+3n (n = 0-26) are byte 0, $B662+3n byte 1 and $B663+3n byte 2 of the rest; the 28th entry ends at $B6B1, and $B6B2-$B6B4 lie beyond the list (world 3 uses its own list at $B610 and never reads this area). By offset: byte 0 is the view position at which the entry's enemy is started, matched against $B95C by #R$D5D1 ($D5DC CP (HL)); byte 1 bit 7 is set at $C654 when the entry matches and a free slot is found - before the upper/lower test at $C65A-$C664, so an entry for the other part of the map is marked too without an enemy being started - and its address is saved in slot bytes 10-11 ($C656, $C694-$C69A); the bit is reset for every entry at world set-up by #R$C169 ($C171, called from $BE5C and $DEB3) and for one entry by #R$D909 ($D91C) when that enemy's slot is freed; $C653 also loads the whole byte into D before the enemy is set up; byte 2 bit 6 must equal $B957 (upper or lower screen, $C65A-$C664), bit 7 picks the starting column value ($02 or $1A, $C66B-$C66F) and bits 0-4 are the enemy template number, times 5 into the template table whose address is at $768E ($C675-$C682).
D $B660 For world 7 (bank 7) they carry the rest of the congratulations message that starts at $B5D3, which the message printer at $C292 prints from $D85C. For worlds 1, 2, 5 and 6 (banks 3 and 6) they are all zeros. When world 5 loads, $C169 runs twice ($BE42 via $DE96, and $BE5C) with world 4's list address ($B65E) and count (28) still in place, before $BE9F and $BEA5 install world 5's, so RES 7 is applied to $B65F, $B662, ..., $B6B0; that is harmless because the bytes are zero. Nothing reads $B6B2-$B6B4 in any world.
@ $B660 label=WorldTail
B $B660,85,16*5,5 The 85 bytes of world data that continue past $B65F: the end of world 4's list of three-byte entries, or the end of world 7's congratulations message. Zero for the other worlds.
b $B6B5 Unused leftover of the graphics block
D $B6B5 75 bytes the game never reads or writes. The tape loads the graphics used in play at $9FFA-$B8B9, and the start-up code at #R$F0C0 moves them to $5DA0-$765F. Most of the old copy is later overwritten: the IM 2 vector table and the stack by the start-up code and play, and $9FFA-$B6B4 by every world load (#R$B8C3 fills $7660-$B6B4). These 75 bytes survive every world load, so they are a copy of $745B-$74A5. (So does the part of the stack area at $B801-$B898 that the stack never reaches, a copy of $75A7-$763E.)
@ $B6B5 label=LoaderLeftover
B $B6B5,75,8*9,3
b $B700 IM 2 vector table
D $B700 257 bytes, all $B8. The game runs in interrupt mode 2 with I=$B7, so when an interrupt is accepted the Z80 reads the address of the interrupt routine from $B700+n, where n is whatever byte is on the data bus (usually $FF on a Spectrum, so $B7FF-$B800). Every possible pair of bytes reads $B8B8, the jump at #R$B8B8, so the handler is found whatever the bus holds. The table never changes. The start-up code at #R$F0C0 fills it ($F0CF-$F0DB) and sets I=$B7 and interrupt mode 2 ($F0E8-$F0EC); the tune player repeats that setting at $DEF2-$DEF6 for every tune.
@ $B700 label=IM2VectorTable
B $B700,257,8*32,1
b $B801 Stack
D $B801 Space for the machine stack, which grows down from $B8B7 (the only constant setting is SP=$B8B7 at $BE47; the LD SP instructions at $C274, $ECC6 and $F2A5 restore values saved into their own operands at run time). Only its top few dozen bytes are ever used (in-play snapshots show changes down to $B899); the rest holds leftovers from loading. Interrupts push onto this stack, and so do the interrupt routines #R$F49E and #R$DFB2, so routines that borrow SP as a data pointer keep interrupts disabled while they do.
@ $B801 label=Stack
B $B801,183,8*22,7
c $B8B8 Jump to the current interrupt routine
D $B8B8 Every interrupt lands here: all bytes of the vector table at #R$B700 are $B8. The JP is in bank 2, which stays at $8000 whatever is paged at $C000. Its operand at $B8B9 is the address of the current interrupt routine and is rewritten at run time: #R$E986 while the start-up code at #R$F0C0 draws the title (it writes the whole JP at $F0DD-$F0E5), #R$F49E from $F1B4 while the credits and menu are up, #R$E986 in play (installed at $F225 when the game starts and at $DED4 when a tune ends), #R$DF90 while a tune plays (installed at $DEEF and $DFF2) and #R$DFEF while a tune effect sounds (installed at $DFBD). Nothing writes $F49E again once the menu has been left. In the recording these are the only values it holds at the end of a frame: $F49E for 204 frames, $E986 for 113,799, $DF90 for 5,209 and $DFEF for 442. The routines at $C000-$FFFF are in bank 0, so code that pages another bank there keeps interrupts disabled (#R$B8C3, #R$B908).
@ $B8B8 label=InterruptJump
C $B8B8,3 Jump to the current interrupt routine (the address at $B8B9 is rewritten as the game changes state)
b $B8BB Where each world bank's 85 extra bytes are in bank 1
D $B8BB Four offsets into RAM bank 1: $00, $55, $AA and $FF. There is one for each world bank, in the order 3, 4, 6, 7. The loader at #R$B8C3 indexes this table with the bank index held at $BDB3 and copies the 85 bytes that start at $C000 plus the offset in bank 1 to #R$B660, just past the world area. The four 85-byte pieces fill bank 1 from $C000 to $C153, so the credits picture starts right after them at $C154. Only bank 4's piece (the end of world 4's object list) and bank 7's piece (the end of world 7's congratulations message) hold anything the game reads. The pieces for banks 3 and 6 are all zeros.
@ $B8BB label=WorldTailOffsets
B $B8BB,4,4
b $B8BF Port $7FFD values that page in each world bank
D $B8BF Four values that #R$B8C3 writes to port $7FFD: $13, $14, $16 and $17. Each one pages RAM bank 3, 4, 6 or 7 in at $C000, and bit 4 is set so the 48K ROM stays paged. The table is indexed by the bank index held at $BDB3 (0-3). Banks 3, 4 and 6 hold two worlds each (1-2, 3-4, 5-6) and bank 7 holds world 7.
@ $B8BF label=WorldBankPorts
B $B8BF,4,4
c $B8C3 Load the next world from its RAM bank
D $B8C3 Pages in the RAM bank that holds the next world and copies all 16,384 bytes of it to the world area at #R$7660. Then it pages in bank 1 and copies the 85 bytes that follow that bank's data to #R$B660. Finally it pages bank 0 back in and jumps to #R$BDC0, which sets up the world just loaded.
D $B8C3 The bank is chosen by the byte at $BDB3, which is the operand of the LD A,$00 instruction at $BDB2 (self-modifying code). Just before jumping here, the code at $BDB4-$BDBA takes the number of worlds completed so far ($BA33, 0-6), halves it and writes the result there. So worlds 1 and 2 load from bank 3, worlds 3 and 4 from bank 4, worlds 5 and 6 from bank 6, and world 7 from bank 7. The same index picks the port value from #R$B8BF and the offset into bank 1 from #R$B8BB. Which of a bank's two worlds is played is decided later by #R$BDC0, at $BDF9, from bit 0 of $BA33.
D $B8C3 The 85 extra bytes are there because two worlds' data run past $B65F. World 4's list of 28 three-byte entries (from $B65E) ends at $B6B1, and world 7's congratulations message at $B5D3 carries on past $B65F. Banks 3 and 6 get 85 zero bytes.
D $B8C3 Interrupts are off the whole time. The IM 2 jump at #R$B8B8 goes to #R$E986 at every load (installed at $F225 before the first, and put back at $DED4 after every tune), and while a world bank is paged $E986 holds world data. The big copy takes about five frames: in the recording the world bank is paged at frame 207 and bank 1 at frame 212.
D $B8C3 The only way here is the JP at $BDBD. That happens when a game starts, either from the menu (JP $BD01 at $F22C) or after the hi-score table (JP $BCE6 at $C012). It also happens 256 frames after each of worlds 1-6 is completed ($D83C to $D04A, then JP $BD85 at $D056). Because everything arrives by jumps, between worlds the stack still holds the return address of the CALL $D77A at $C960 or $C98C. $BE47 resets SP later.
@ $B8C3 label=LoadWorld
C $B8C3,1 No interrupts while a world bank is paged: the IM 2 handler jumps into $C000-$FFFF
C $B8C4,3 Bank index (0-3): the number of worlds completed, halved, which $BDBA put here
C $B8C7,2 DE = bank index
C $B8CA,3 Look up this bank's port value in #R$B8BF
C $B8CE,1 A = $13, $14, $16 or $17
C $B8CF,3 Page RAM bank 3, 4, 6 or 7 in at $C000, keeping the 48K ROM
C $B8D4,3 Copy the whole bank, $C000-$FFFF...
C $B8D7,3 ...to the world area, #R$7660-$B65F
C $B8DD,2 This takes about five frames
N $B8DF Now fetch the 85 bytes that belong after this bank's data.
C $B8DF,2 Page RAM bank 1 in at $C000
C $B8E6,3 Bank index again
C $B8EC,3 Look up where this bank's extra bytes are in bank 1 (#R$B8BB)
C $B8F0,1 E = $00, $55, $AA or $FF (D is still 0)
C $B8F1,3 HL = start of the 85 bytes in bank 1
C $B8F5,3 Copy them to #R$B660, straight after the world area
N $B8FD Restore the normal paging and carry on.
C $B8FD,2 Page bank 0, the main program, back in
C $B904,1 Interrupts back on
C $B905,3 Set up the world just loaded
c $B908 Show the credits picture and the Combat School advert
D $B908 Shows what comes after world 7 is completed. First the credits picture from bank 1 is copied to the screen (Athena, with the programming, music and graphics credits) and tune 0 plays. Then an advert for Ocean's Combat School, also from bank 1, stays up until a key is pressed. After that the routine jumps into the hi-score table routine #R$BF6A at $BF6D, which clears the screen first.
D $B908 The only way here is the JP at $D86D, at the end of the world-7 completion sequence in #R$D77A (congratulations message, tune 12, wait for a key). Tune 0 plays until it ends or a key is pressed during a rest (its entry in the tune table at $E254 starts with INC A). In the recording the credits picture is paged in at frame 117,637 and a key cuts the tune short at frame 119,119, about 30 seconds in. The advert is copied in the same frame, and the key press that leaves it comes at frame 119,301.
D $B908 Each picture is a whole 6,912-byte screen (display file and attributes), copied straight to $4000. Interrupts are off while bank 1 is paged, for the reason given at #R$B8C3.
D $B908 The advert half, from $B929, is only reached when #R$DEC6 returns: nothing jumps or calls there. It starts with its own DI because the tune player re-enables interrupts before it returns.
@ $B908 label=ShowEnding
C $B908,1 No interrupts while bank 1 is paged
C $B909,3 Copy strips of the display file into the buffer at $F000
C $B90C,2 Page RAM bank 1 in at $C000
C $B913,3 The credits picture in bank 1...
C $B916,3 ...to the screen...
C $B919,3 ...6,912 bytes: pixels and attributes
C $B91E,2 Page bank 0 back in
C $B925,1 Play tune 0 (a key press can cut it short; one did after about 30 seconds in the recording)
C $B926,3 #R$DEC6 comes back with interrupts enabled
N $B929 After the tune, show the Combat School advert until a key is pressed, then go on to the hi-score table.
@ $B929 label=ShowAdvert
C $B929,1 Interrupts off again for paging
C $B92A,2 Page RAM bank 1 in at $C000
C $B931,3 The Combat School advert in bank 1...
C $B934,3 ...to the screen...
C $B937,3 ...pixels and attributes
C $B93C,2 Page bank 0 back in
C $B943,3 Wait until no key is down, then for a key press
C $B946,3 Clear the screen and go to the hi-score table
b $B949 Game variables
D $B949 The game's variables, followed by four constant tables. Three zero-fills (#R$C2FC) give the block its shape. Starting a new game clears $B949-$BA35 ($BD04, 237 bytes). At the end of each world, before the next is loaded, $BD85 clears $B949-$BA14 (204 bytes), so everything from $BA15 on is kept from world to world. When the screen is redrawn from the map window by #R$DE96 (at world set-up, $BE42) or from $DE99 (on a change between the upper and lower screens, via #R$DD66), $DEB3 re-arms the world's object list, $DEB8 puts back any pending map changes and $DEBE clears $B95E-$BA14 (183 bytes). When a life is lost while item $61 is not held, $CD15 clears $BA19-$BA2B (19 bytes: the carried items, jump count, armour, flight, immunity and energy-drain variables). $BA36-$BA8C is never cleared or written. At every world start and after every lost life, the set-up code at $BE47 also clears $B9C2-$BA06 ($BE54, 69 bytes: the enemy slots and $BA03-$BA06) and the low byte of $BA35 ($BE4B).
D $B949 $B949-$B95D: the player and the view. PlayerFrame, ClimbState, the clock digits ClockMinutes, ClockTens and ClockSeconds ($B94B-$B94D), PlayerScreenAddr ($B94E-$B94F), PlayerAnimTimer, FinalGuardian, FacingLeft, JumpCounter, Falling, GuardianActive, GuardianDamage, LowerScreen, ScrollPos ($B958-$B959), ScrollQuarter ($B95A-$B95B), MapColumn and PlayerRow.
D $B949 $B95E-$B9B7: MapChanges, ten 9-byte records of map cells to be put back. $B9B8-$B9C1: ten bytes nothing uses.
D $B949 $B9C2-$BA02: EnemySlots, five 13-byte slots. $BA03-$BA08: short-lived effects and flags (HitEffectTimer, ExplosionTimer, ShotTimer, CellAnimCode, Crouching, MapChangeCooldown). $BA09-$BA12: EnemyDrawList, five slot addresses. $BA13-$BA14: unused.
D $B949 $BA15-$BA35, kept from world to world: Score ($BA15-$BA16), MapWindow ($BA17-$BA18), HeldItems ($BA19-$BA22), JumpCount, ArmourA-ArmourC ($BA24-$BA26), Flying, FlyingItem6E, FlightFlagUnset ($BA27-$BA29), ImmunityTimer, EnergyDrain, WeaponKind, WeaponLevel, WeaponGfxAddr ($BA2E-$BA2F), ClockPassCounter, EnergyLossCounter, Type6SideCounter, WorldNumber, ArmourWear and PlayerBufferPos ($BA35-$BA36, high byte constant).
D $B949 $BA37-$BA8C, constant: ItemColours ($BA37-$BA4C), WeaponKinds ($BA4D-$BA53), WeaponItems ($BA54-$BA5A) and ItemHandlers ($BA5B-$BA8C).
D $B949 Some variables the game needs live elsewhere, mostly as operands of its own instructions: lives at $C1EE and credits at $CCB9, energy at $BF1B, the time bonus at $D073, and the world loader's variables (build/d1/paging.json).
@ $B949 label=GameVariables
B $B949,1,1 Animation frame of the player sprite, 0-3. #R$DAA7 steps it through 0, 1, 2, 3 and back to 0 on every second call (bit 0 of $B950), unless a jump is in progress ($B953 non-zero), and forces it to the value in the operand $CE4B when that is non-zero (3 while gliding, $C7FC). It is set to 1 when a jump starts ($C933), to 0 on landing ($C7EC) and when crouching ($C8A9), and to 3 or 0 for the firing pose ($C965, $C970, $C9B3). The sprite drawing code reads it.
@ $B94A label=ClimbState
B $B94A,1,1 Climbing state of the player: 0 when not climbing. It becomes 1 when up or down is held over a climbable map cell ($7F, $80 or $B2; tested at $C846-$C85A, $C8D5-$C8E1 and in $DB56) and the player moves four pixel lines ($C895 down, $C942 up); it becomes 4 at $C87E when down is held while climbing and the cell below is neither $B2 nor solid; walking left or right while it is non-zero turns 4 into 0 and anything else into 2 ($C9EB-$CA00, $CA94-$CAA9). It is cleared at $C8F0 after the last upward step. While bit 0 or bit 2 is set (1 or 4) the player cannot fire ($C98F AND $05, $D77A); while it is 0 (and $CE4B is 0) the player's pixel line is snapped to a character cell each pass ($CFEA-$CFF6); it also picks the player's pixel line when changing screen at $D443.
@ $B94B label=ClockMinutes
B $B94B,1,1 Minutes digit of the countdown clock (a number, not ASCII). Set to 5 at every world start ($BDAF, after the clear at $BD85); a lost life or a continue does not reset the clock ($CD33 JP $BE47 is past $BDAF). When it goes below 0 at $DB0F the game prints OUT OF TIME ($BC4E) and ends via #R$C3C0. The time bonus ($DAEE) can carry into it, so it can exceed 5.
@ $B94C label=ClockTens
B $B94C,1,1 Tens-of-seconds digit of the countdown clock, 0-5. It wraps from 0 to 5 with a borrow from $B94B at $DB08-$DB0F, and from 5 to 0 with a carry at $DAE4-$DAEE when the time bonus adds seconds.
@ $B94D label=ClockSeconds
B $B94D,1,1 Seconds digit of the countdown clock, 0-9. Decremented once every 13 main-loop passes by $DAF2 (via $BA30), wrapping 0 to 9 with a borrow from $B94C; each wrap also costs one unit of energy (#R$BEFE) while $BA2B is non-zero. Incremented by $DAD7 instead while the time bonus (operand $D073) is running. This is the POKE list's time address: one digit of the clock.
@ $B94E label=PlayerScreenAddr
W $B94E,2,2 Display-file address just right of the player sprite: the sprite's 16 pixels on each of its 32 lines are drawn into the two bytes before it on each line ($D13A-$D170 loads SP with the address and pushes, and PUSH writes below SP), so the sprite's left edge is 16 pixels to the left. It is set to $4010 (top line of the screen, column 16) at every world start ($BDA4). The column never changes (low byte always ends in 10000 binary: 16, 48, ... 240); jumping, falling and climbing move it up ($DD06, via $C312 DEC H) or down ($DD12, via $C303 INC H) one pixel line at a time. Changing between the world's upper and lower screens puts it on the top line ($D44C-$D454, high byte $40 or $44) or low on the screen ($D497-$D49F, high byte $48). $C3EB and $C3DA turn it into a character row and column; $C6E5 stores the row in $B95D once per pass.
@ $B950 label=PlayerAnimTimer
B $B950,1,1 Counter incremented by every call to #R$DAA7 (the player animation step, called when the player walks, climbs or starts a jump); the animation frame #R$B949 only advances when bit 0 is set, i.e. on every second call.
@ $B951 label=FinalGuardian
B $B951,1,1 Set to 1 at $C586 when world 7's second guardian is started ($B95A = $046E, with its data from the world header at $767E/$7680). When a world 7 guardian is destroyed, $D843 returns to play if it is 0 and goes on to the end of the game ($D848) if it is 1.
@ $B952 label=FacingLeft
B $B952,1,1 Direction the player faces: 1 = left, 0 = right. Walking left sets it ($CA0B, $CA3A, $CA6C), walking right clears it ($CAB3, $CADE, $CB0D); a first press in the other direction only turns the player round. $DD24 returns it with the zero flag set for right. It also picks the side from which shots and the player sprite are drawn ($D2CD, $D795, $D7F7, $DDD0).
@ $B953 label=JumpCounter
B $B953,1,1 Main-loop passes left in the current jump; 0 when not jumping. A jump starts at $C92E with 4, or with 12 when the jump-boost item is active and the jump count $BA23 is odd (and the player is not flying, $BA27 = 0). Each pass $C765-$C76D decrements it and moves the player up eight pixel lines ($C7B3); in a 12-pass jump the player only rises while 6 or more passes remain and hangs for the rest ($C77A-$C784). A blocked cell overhead ends the jump ($C7AC). While it is non-zero the player animation does not advance (#R$DAA7). This is the address the POKE list calls megajumps: it is the jump counter, and 12 is a high jump.
@ $B954 label=Falling
B $B954,1,1 1 while the player is falling. #R$DD9C sets it (at world start, when a jump ends and when the cell under the player is not solid, $CA28/$CACD); each pass it is set, $C7BB-$C7E5 tests the cells below and either moves the player down eight pixel lines ($C82C), or glides when flying ($BA27: two lines down, or four up while up is held), or clears it on landing ($C7E9).
@ $B955 label=GuardianActive
B $B955,1,1 Non-zero ($AF) while the end-of-world guardian is active; the main loop then calls #R$D513 instead of drawing the enemies. The random spawns in #R$C553 still run.
@ $B956 label=GuardianDamage
B $B956,1,1 Damage taken by the end-of-world guardian. Each hit adds the weapon level; from 64 damage sprites are drawn over it; at 80 or more it is destroyed, points are awarded and this is reset to 0.
@ $B957 label=LowerScreen
B $B957,1,1 $40 while the player is on the lower of the two screen-heights of map, 0 on the upper. When the player's row $B95D reaches 12 at $D42B it is set to $40, the map window $BA17 moves $0680 bytes on (via #R$DD66) and the player is put at the top of the screen; when the player is at row 0 on the lower screen and jumping or pressing up into an open cell, it is cleared, the window moves back and the player is put near the bottom ($D458-$D49F). With the opcode at $D03F it gates the end-of-map test at $D03B-$D047, which completes the world (256-frame wait at $D04A, then the next world at $BD85) when $B95C equals the world's end column at $D046.
@ $B958 label=ScrollPos
W $B958,2,2 Horizontal position of the view in the world, in scroll steps: set to 32 at world start ($BD99, after the clear), incremented at $CB1B for each step right and decremented at $CA7A for each step left; walking left stops at 0 ($C9E3-$C9E8). Once per pass $CFC7 derives $B95A (this divided by 4) and $B95C (divided by 8, low byte).
@ $B95A label=ScrollQuarter
W $B95A,2,2 $B958 divided by 4, stored each pass at $CFD6: the view's position in the units used by the world's position lists. $D5E3 looks it up in a list of 4-byte entries at the object-list address ($D5D2); it is saved in each timed map change ($D632); in world 7 the values $023A and $046E start the two guardians ($C565-$C57A).
@ $B95C label=MapColumn
B $B95C,1,1 Low byte of $B958 divided by 8, stored each pass at $CFE0: the map column of the window's left edge. The world's guardian starts when it equals the operand of CP at $C58E (set from the world header), and in world 7 unless one of the two $B95A positions matched first; #R$D5D1 looks it up in the world's 3-byte list; the world is completed when it equals the operand at $D046 (per world, from the header) with $B957 matching the test at $D03F ($D03B-$D056, 256-frame wait, then the next world at $BD85).
@ $B95D label=PlayerRow
B $B95D,1,1 Character row of the player's display-file address at $B94E, stored once per pass. The row on which type 7 and type 6 enemies are started.
@ $B95E label=MapChanges
B $B95E,90,16*5,10 Ten 9-byte records of map cells that have been changed for a while and will be put back (what changes them in play, such as a shot or the player, is not established here). Byte 0 is non-zero while the record is in use: it is set to 50 when the record is made and counts down one per pass at $CE8B; when it reaches 0 the cell is restored. Bytes 1-2 are the address of the map cell; byte 3 is the cell code stored at the time (the restore at $CE95 writes back byte 3 minus $19, matching the $19 added to the cell at $DBB9); bytes 4-5 are $B95A when the record was made (compared with the current value at $CEA7 to see whether the cell is on screen); bytes 6, 7 and 8 are copies of the operand $D746, register D and the operand $D744 and are used to redraw the cell ($CE9E-$CEA4). Records are made at $D619-$D645, which takes the first free record by stepping 9 bytes from $B955 with no count. #R$C190 puts every pending cell back (byte 3 minus C) and $DEBE then zero-fills $B95E-$BA14.
@ $B9B8 label=UnusedB9B8
B $B9B8,10,8,2 Ten bytes between the last map-change record and the enemy slots that nothing reads or writes except the clears at $BD04 and $BD85 and the zero-fill at $DEBE. The unbounded free-record search at $D61C could only reach them if all ten $B95E records were in use.
@ $B9C2 label=EnemySlots
B $B9C2,65,13 Five 13-byte enemy slots. Byte 0 non-zero = in use; 2 = column; 3 = row; 4-8 = copy of the enemy's five-byte template (8 = type); 9 is a state and direction byte (bit 7 set if it started on the left; bits 5-7 are changed as it moves); 10-11 written after spawning at $C694.
@ $BA03 label=HitEffectTimer
B $BA03,1,1 Passes left (2, 1) of a two-frame effect drawn after a map cell has been changed at $D742: set to 2 at $D74C, drawn from graphics $6BE0 or $6C60 (bit 1 picks) at $D3C5-$D3F1 and decremented at $D3F7; with weapon kinds 5-7 it is cleared at once ($D3CB).
@ $BA04 label=ExplosionTimer
B $BA04,1,1 Passes left (8 down to 1) of the animation drawn where an enemy was hit: $D874-$D896 takes the slot's position from its entry in $BA09, stores it at $D419 and sets this to 8; $D3FE-$D410 decrements it and draws phase 3 - (count / 2).
@ $BA05 label=ShotTimer
B $BA05,1,1 Passes left of a shot from weapon kind 6 or 7: set to 7 at $C99F when fire is pressed with such a weapon, decremented once per pass at $D291-$D298. While it is non-zero the player cannot climb ($C884, $C939) and $C968, $D02C, $D178, $D2DF and $D7C1 treat the shot as still in flight.
@ $BA06 label=CellAnimCode
B $BA06,1,1 Cell code of a three-step map-cell animation, or 0 when none is running. When the cell at column offset $31 beside the player is $79 or $7A, $C712-$C71D writes code minus $6D into it and sets this to $7B; $C606-$C621 then steps it to $7C and $7D, stepping when the counter in the operand at $C60E runs out while #R$DD93 returns Z (the counter is reloaded with 8 at $C638), and back to 0 after $7D, drawing the cell at the column saved in $C628.
@ $BA07 label=Crouching
B $BA07,1,1 1 while the player is crouching. Cleared at the start of the player's pass ($C6DB); set at $C8AD when down is held and the cell below is not climbable. While it is set the player cannot walk ($C9D9, $CA8A), the crouching graphic address $BA35 is used, and firing depends on the weapon ($C9AB, $D780).
@ $BA08 label=MapChangeCooldown
B $BA08,1,1 Set to 1 at $D60C when a map-change record is made ($B95E) and decremented at $CB21-$CB29; while it is non-zero #R$DBAB returns at once, so the cell check it does is skipped.
@ $BA09 label=EnemyDrawList
B $BA09,10,8,2 Five words, each the address of an enemy slot in $B9C2 (or 0 for none), in the order the enemies are processed. $D08C refills them every pass from five calls to #R$C51F, storing IY at $BA09, $BA0B, $BA0D, $BA0F and $BA11; $D0CE-$D109 walks them to write each enemy's number into the enemy position map at $EF80-$EFFF (skipped while a guardian is active); the enemies are drawn later in #R$D08C (a zero high byte means an empty entry), and $D1E6 and $D87B index them by slot number.
@ $BA13 label=UnusedBA13
W $BA13,2,2 Two bytes after the enemy list that nothing reads or writes except the clears ($BD04, $BD85, $DEBE).
@ $BA15 label=Score
W $BA15,2,2 Score counter; the display adds a fixed trailing zero (points = counter x 10).
@ $BA17 label=MapWindow
W $BA17,2,2 Address of the visible part of the world map (112 cells, eight per column); #R$C2D9 reads map cells relative to it. World set-up gives it its first value at $BE1B (header word 1 plus $20). Scrolling moves it by 8 (one column), in the direction the player faces, each time eight scroll steps are complete (#R$DDC4, via $D4A4); turning round while $D4A2 is 8 also moves it 8 in the new direction ($CA5E-$CA67 back, $CB02-$CB09 on); changing between the upper and lower screens moves it by $0680 through #R$DD66. A cell holding 0 is where a type 4 enemy may be started at random.
@ $BA19 label=HeldItems
B $BA19,10,8,2 The ten slots of the carried-items panel: each holds an item code ($60-$78) or 0 for an empty slot. When an item is collected, #R$DBE4 looks its code up in the item colour table at $BA37 (#R$C4B0) and, if it is there and not already held, puts it in the first empty slot (#R$C4A2 with A=0) and redraws the panel (#R$C33B, which prints each held item in the colour paired with its code). #R$C1AA and #R$C1B2 remove items $6A and $6E again; item $70's handler removes item $71. $CD10 and $D718 test whether item $61 is held. Losing a life empties the panel (and clears $BA23-$BA2B) unless item $61 is held ($CD0E-$CD1A).
@ $BA23 label=JumpCount
B $BA23,1,1 Number of jumps made since the jump-boost item (code $60) was collected. Its handler #R$DBF7 writes INC (HL) over the NOP at $C91F, so from then on every jump increments this byte, and bit 0 makes every second jump a 12-pass high jump ($B953). The NOP is put back at a new game ($BD62) and when a life is lost while item $61 is not held ($CD1E), which also clears this byte.
@ $BA24 label=ArmourA
B $BA24,1,1 First of three armour counters, 0-2. The handler for item $74 (and item $64, which raises all three) increments it up to 2 and sets $BA34 to 4 ($DCCA-$DCD3), then redraws the armour bar ($C0BC). When a piece wears out, #R$C178 decrements the first non-zero counter of $BA24, $BA25, $BA26 in that order. The three are summed by #R$DDA2 and read when drawing the player ($CDE1) and choosing items ($D6E5). Which piece of armour each counter is has not been established.
@ $BA25 label=ArmourB
B $BA25,1,1 Second armour counter, 0-2: as $BA24, raised by item $75 ($DC9C) or $64, worn out after $BA24 is empty. Read when drawing the player ($CDFA) and choosing items ($D6D7).
@ $BA26 label=ArmourC
B $BA26,1,1 Third armour counter, 0-2: as $BA24, raised by item $76 ($DCA1) or $64, worn out last. The armour bar ($C0BC) counts it twice (#R$DDA2 total plus $BA26 again), so the bar has up to 8 cells. Read when drawing the player ($CDAF) and choosing items ($D6C9, $D70E).
@ $BA27 label=Flying
B $BA27,1,1 1 while the player can fly. Set by the handlers for item $6A (#R$DC48) and item $6E (#R$DC5A). While it is set a jump always lasts 4 passes and never hangs ($C773, $C920), and falling becomes gliding: two pixel lines down per pass, or four up while up is held ($C7F4-$C82A). #R$C1AA clears it and removes item $6A from $BA19; that happens at every world start ($BD91, in the $BD85 set-up; a lost life does not clear it unless the $CD15 clear runs, i.e. item $61 is not held) and at $C74E (see $BA28).
@ $BA28 label=FlyingItem6E
B $BA28,1,1 1 when flight came from item $6E (#R$DC5A sets it together with $BA27). At $C740, when the map cell tested beside the player is $98, it is cleared and both flight items are taken away (#R$C1AA, #R$C1B2). While it is set the player is drawn with an extra graphic at $CE45, and the one drawn at $D1AB (for flight without it) is skipped. Cleared at every world start ($BD8E).
@ $BA29 label=FlightFlagUnset
B $BA29,1,1 A flag that is cleared by #R$C1B2 (which also removes item $6E from $BA19) and tested at $D19C, where a non-zero value would stop the flight graphic at $D1AB being drawn; no code sets it, so it is always 0.
@ $BA2A label=ImmunityTimer
B $BA2A,1,1 Immunity timer, in main-loop passes. Set to 200 by the item code at $DC54; while it is non-zero the pass skips the energy loss at $BEFE and flashes the LIFE label in random colours.
@ $BA2B label=EnergyDrain
B $BA2B,1,1 Non-zero while energy drains over time: each time the clock's seconds digit wraps (every ten clock seconds) $DAFB calls #R$BEFE. Item $70's handler ($DC68) sets it to 1 and changes the colour the energy display is drawn in (operand $BF16) from $42 to $43 via $BF52, unless item $71 is held, in which case $71 is used up instead; item $71's handler #R$DC7D clears it and restores colour $42 ($BF4B).
@ $BA2C label=WeaponKind
B $BA2C,1,1 Kind of weapon in use, 1-7: the entry for the weapon level $BA2D in the table at $BA4D (level 0 = kind 5, 1 = 3, 2 = 4, 3 = 7, 4 = 2, 5 = 1, 6 = 6). It is stored by $DCB5 whenever the level changes; the kind times 3 indexes the weapon data at $BCCE. Firing, the shot and the pickup rules test it: kinds 6 and 7 start the shot timer $BA05 ($C997); item $62 does not raise the level of kinds 1 and 6 ($DC01); kind 6 drops back to level 5 at $D033.
@ $BA2D label=WeaponLevel
B $BA2D,1,1 Weapon level, 0-6. Indexes the tables at $BA4D and $BCCE for the weapon's kind ($BA2C) and data; adds to the guardian's damage per hit; raised by an item (#R$DC01) or at random (#R$DDBC), lowered by another item (#R$DC61).
@ $BA2E label=WeaponGfxAddr
W $BA2E,2,2 Address of the current weapon's 288 bytes of graphics, from its entry in the table at $BCCE; $DCBC copies them to $EE60 whenever the weapon changes. Also read at $CF04 and $CF89.
@ $BA30 label=ClockPassCounter
B $BA30,1,1 Passes of the main loop left before the clock next ticks down: counts 12 to 0 and the tick comes when it goes below 0, so the clock ticks every 13 passes (the count is not decremented while the time bonus runs). A new game clears it ($BD04 clears $B949-$BA35), so the first pass of a new game ticks; the per-world clear at $BD85 stops at $BA14, so a new world keeps the count from the last.
@ $BA31 label=EnergyLossCounter
B $BA31,1,1 Counts calls to the energy-loss routine #R$BEFE; only every second call (when bit 0 becomes 0) actually wears armour and takes one unit of energy from $BF1B.
@ $BA32 label=Type6SideCounter
B $BA32,1,1 Counter advanced each time a type 6 enemy starts; its bit 0 picks the edge (even = left at column 1, odd = right at column 28). The one non-random side choice among the random spawns.
@ $BA33 label=WorldNumber
B $BA33,1,1 Number of worlds completed: 0-6 while a world is loading, then incremented at $BE46, so it holds the current world 1-7 during play. Halved, it picks the bank. Bit 0 at load time picks the first or second world in the bank ($BDF9). 7 selects world-7 behaviour ($BE6B, $C55D, $D837). Plus 3, it is the tune played whenever play (re)starts in a world, at a new world or after a life is lost ($BEDF-$BEE4).
@ $BA34 label=ArmourWear
B $BA34,1,1 Energy losses left before a piece of armour is lost. Every armour pickup sets it to 4 ($DCCC). On each energy loss in #R$BEFE, while it is non-zero, #R$C178 decrements it and when it reaches 0 decrements the first non-zero armour counter ($BA24). It is not reloaded then, so after one piece is lost no more wear until the next pickup.
@ $BA35 label=PlayerBufferPos
W $BA35,2,2 Where in the player sprite buffer at $5C00 the player's graphics are drawn: $5C00 normally, $5C10 (eight pixel lines lower, two bytes a line) while crouching. #R$EDD5 is called with this address in DE as the destination ($CDA3, again at $CDD0), masking the graphic into the buffer that $D13A-$D170 copies to the screen. Only the low byte changes ($C8A5 sets $10; $BE4B and $D1BD clear it); the high byte at $BA36 is the constant $5C.
b $BA37 Colours of the items that can be carried
D $BA37 Eleven pairs (item code, attribute) for the items that can be carried. #R$C4B0 searches the code bytes (twelve probes from $BA37, the last landing on $BA4D, the first byte of $BA4D's table, which is never an item code); an item not found is not added to $BA19. The carried-items printer ($C35A-$C362) takes the byte after the code as the colour to draw the item in.
@ $BA37 label=ItemColours
B $BA37,22,2
b $BA4D Weapon kind for each weapon level
D $BA4D Weapon kind (1-7) for each weapon level 0-6, read by #R$C141 / $C14C as $BA4D + level.
@ $BA4D label=WeaponKinds
B $BA4D,7,1
b $BA54 Item code for each weapon kind
D $BA54 Item code that gives each weapon kind 1-7, read at $D6B9-$D6C0 as $BA53 + kind; kind 5, the starting weapon, has no item (0). Each code's handler sets the level whose kind matches (see $BA2D).
@ $BA54 label=WeaponItems
B $BA54,7,1
w $BA5B Item handler addresses
D $BA5B Addresses of the 25 item handlers, for item codes $60-$78 in order. $DBCB-$DBE3 stores the item code in the operand $DBE5, doubles (code - $60) as the index, pushes the return address #R$DBE4 and jumps to the handler; #R$DBE4 then records the item in $BA19 if it can be carried.
@ $BA5B label=ItemHandlers
W $BA5B,50,2
s $BA8D Read the controls (routine written at game start)
D $BA8D This routine is empty (zeros) at the title. When the control method is chosen, #R$F1C9 fills it with one of two routines. The game calls it only from $C553, about once every four and a half frames in play (26,675 calls in the recording). Both versions leave the six flags at #R$BAB2 holding 0 for each control that is held. With KEMPSTON, $BA8D-$BAA5 is a copy of #R$F472: it reads the joystick at port $1F, then reads key 1 (the IN at $BAA0) for pause. With KEYBOARD, CURSOR or SINCLAIR 1, $BA8D-$BA9F is a copy of #R$F48B, which reads the six keys in the table at #R$BAA6. The six bytes copied after its RET, at $BAA0-$BAA5, are the start of #R$F49E and are never run. The menu is never shown again, so the version written here stays for every later game. The oracle leaves these bytes out of its hashes (tools/mkstream.py).
@ $BA8D label=ReadControls
S $BA8D,25,$19
b $BAA6 Key table in use
D $BAA6 The 12-byte key table read by the key-table version of #R$BA8D. #R$F1C9 fills it with a copy of #R$EFDC, #R$EFF4 or #R$EFE8, in the same layout: a half-row high byte and a bit mask for each of right, left, down, up, fire and pause. It is zero at the title and stays zero, unused, when KEMPSTON is chosen. Unlike the original tables, it survives play.
@ $BAA6 label=ControlKeys
B $BAA6,2,2 Right
B $BAA8,2,2 Left
B $BAAA,2,2 Down
B $BAAC,2,2 Up
B $BAAE,2,2 Fire
B $BAB0,2,2 Pause
b $BAB2 Control flags
D $BAB2 One byte per control, written by #R$BA8D on each call and read by the game. A flag is 0 while its control is held and non-zero otherwise: 1 with the Kempston routine, or the key's bit mask with a key table. Every reader tests only zero against non-zero. Three separate pieces of evidence fix the order as right, left, down, up, fire, pause. First, the Kempston routine stores joystick bits 0-4 in $BAB2-$BAB6 in turn. Second, DEFINE KEYS stores its first key, whose name it prints on the RIGHT line, in the first table entry. Third, the cursor and Sinclair tables begin with 8 and 7, the right-hand keys of those layouts. Readers: right at $CA83; left at $C9D2; down at $C832; up at $C7FF, $C8B3 and $D46C; fire at $C97F and $CF4B (which on this path stores a non-zero flag at $D17F, the operand of LD A,n at $D17E, also written at $CEFD and again only tested with OR A); pause at $D06B, which calls #R$C2ED when the flag is 0. In the recording, the pause flag is 0 in 263 frames.
@ $BAB2 label=InputRight
B $BAB2,1,1 Right: 0 while held
@ $BAB3 label=InputLeft
B $BAB3,1,1 Left: 0 while held
@ $BAB4 label=InputDown
B $BAB4,1,1 Down: 0 while held
@ $BAB5 label=InputUp
B $BAB5,1,1 Up: 0 while held
@ $BAB6 label=InputFire
B $BAB6,1,1 Fire: 0 while held
@ $BAB7 label=InputPause
B $BAB7,1,1 Pause: 0 while held with Kempston)
b $BAB8 Data block at BAB8
B $BAB8,28,8*3,4
b $BAD4 Data block at BAD4
B $BAD4,68,8*8,4
t $BB18 Message at BB18
T $BB18,8,8
b $BB20 Data block at BB20
B $BB20,1,1
t $BB21 Message at BB21
T $BB21,5,5
b $BB26 Data block at BB26
B $BB26,2,2
t $BB28 Message at BB28
T $BB28,4,4
b $BB2C Data block at BB2C
B $BB2C,1,1
t $BB2D Message at BB2D
T $BB2D,6,6
b $BB33 Data block at BB33
B $BB33,2,2
t $BB35 Message at BB35
T $BB35,4,4
b $BB39 Data block at BB39
B $BB39,7,7
t $BB40 Message at BB40
T $BB40,7,7
b $BB47 Data block at BB47
B $BB47,1,1
t $BB48 Message at BB48
T $BB48,32,32
b $BB68 Data block at BB68
B $BB68,1,1
t $BB69 Message at BB69
T $BB69,18,18
b $BB7B Data block at BB7B
B $BB7B,1,1
t $BB7C Message at BB7C
T $BB7C,9,9
b $BB85 Data block at BB85
B $BB85,1,1
t $BB86 Message at BB86
T $BB86,10,10
b $BB90 Data block at BB90
B $BB90,1,1
t $BB91 Message at BB91
T $BB91,13,13
b $BB9E Data block at BB9E
B $BB9E,3,3
t $BBA1 Message at BBA1
T $BBA1,7,7
b $BBA8 Data block at BBA8
B $BBA8,1,1
t $BBA9 Message at BBA9
T $BBA9,13,13
b $BBB6 Data block at BBB6
B $BBB6,1,1
t $BBB7 Message at BBB7
T $BBB7,7,7
b $BBBE Data block at BBBE
B $BBBE,1,1
t $BBBF Message at BBBF
T $BBBF,9,9
b $BBC8 Data block at BBC8
B $BBC8,3,3
t $BBCB Message at BBCB
T $BBCB,15,15
b $BBDA Data block at BBDA
B $BBDA,1,1
t $BBDB Message at BBDB
T $BBDB,10,10
b $BBE5 Data block at BBE5
B $BBE5,1,1
t $BBE6 Message at BBE6
T $BBE6,11,11
b $BBF1 Data block at BBF1
B $BBF1,2,2
t $BBF3 Message at BBF3
T $BBF3,11,11
b $BBFE Data block at BBFE
B $BBFE,1,1
t $BBFF Message at BBFF
T $BBFF,10,10
b $BC09 Data block at BC09
B $BC09,2,2
t $BC0B Message at BC0B
T $BC0B,10,10
b $BC15 Data block at BC15
B $BC15,2,2
t $BC17 Message at BC17
T $BC17,10,10
b $BC21 Data block at BC21
B $BC21,2,2
t $BC23 Message at BC23
T $BC23,24,24
b $BC3B Data block at BC3B
B $BC3B,4,4
t $BC3F Message at BC3F
T $BC3F,14,14
b $BC4D Data block at BC4D
B $BC4D,1,1
t $BC4E Message at BC4E
T $BC4E,11,11
b $BC59 Data block at BC59
B $BC59,1,1
t $BC5A Message at BC5A
T $BC5A,11,11
b $BC65 Data block at BC65
B $BC65,1,1
t $BC66 Message at BC66
T $BC66,9,9
b $BC6F Data block at BC6F
B $BC6F,1,1
t $BC70 Message at BC70
T $BC70,13,13
b $BC7D Data block at BC7D
B $BC7D,1,1
t $BC7E Message at BC7E
T $BC7E,8,8
b $BC86 Data block at BC86
B $BC86,1,1
t $BC87 Message at BC87
T $BC87,8,8
b $BC8F Data block at BC8F
B $BC8F,45,8*5,5
t $BCBC Message at BCBC
T $BCBC,3,3
b $BCBF Data block at BCBF
B $BCBF,39,8*4,7
c $BCE6 Start a new game after the hi-score table
D $BCE6 Reached only by the JP at $C012, after a game has ended and the hi-score table (#R$BF6A) has been shown. There is no way back to the control menu: the next game starts at $BD01 with the control method chosen at the title still in force.
D $BCE6 First it processes the maps of the world that was being played. #R$C190, called with C=0, walks the ten 9-byte records at $B95E and, for each one whose first byte is not zero, writes the record's fourth byte to the address held in its second and third bytes. Then #R$C0F1 is applied to every byte of both maps in the bank's world data: the first map starts at the address in the header word at $7661 and is ($7663) bytes long, and the second follows it directly, ($767A) bytes long. #R$C0F1 changes certain byte values into others (for example $C6 is added to $00-$02 and $07-$09, and $CD to $03-$06).
D $BCE6 None of this has any lasting effect, because $BD85 then reloads world 1 over the whole world area (#R$B8C3). Why the game does it is not known.
D $BCE6 The routine then runs on into $BD01 (NewGame), the entry used by the menu.
D $BCE6 NewGame ($BD01) sets up a game: it clears the screen, clears the game variables from $B949 to $BA35, allows three continues (the operand at $CCB9 is set to 4, one more than the number of CONTINUE? offers left) and five lives (#R$C1E2, which also prints the lives digit), installs the weapon for level 0 through the entry at $DCB2 (HL=$65E0, A=5, B=0: exactly what the lookup at $C14C returns for weapon level 0, and the same entry the weapon upgrade at $DCAC uses), and draws the panel: the panel pieces kept at $F000-$F0BF, the bar in columns 0-1 (#R$BF42), the column of 18 segments down columns 30-31 (#R$BEEA with $BAF8), the weapon colours (#R$C091), SCORE, TIME and LIVES from the message at $BB21 on rows 17-23, HI-SCORE (#R$C284), and the best score in the hi-score table ($BBE5) followed by a 0, since scores are shown ten times their stored value. It then runs on into $BD85.
D $BCE6 NewWorld ($BD85) is also entered by the JP at $D056 when a world is completed. It clears $B949-$BA14 (stopping short of the score at $BA15), resets a few player variables, sets the clock at $B94B to 5 minutes, writes the bank index for the next world into $BDB3 (half the number of worlds completed, $BA33) and jumps to #R$B8C3 to load it.
@ $BCE6 label=RestartGame
C $BCE6,2 Apply the ten records at $B95E with nothing subtracted
C $BCEB,3 DE = length of the bank's two maps together
C $BCF3,4 HL = start of the first map
C $BCF8,3 Transform each map byte
N $BD01 This entry point is used by the routine at #R$F1C9. This entry point is used by the control menu to start the first game. Set up a new game and draw the panel.
@ $BD01 label=NewGame
C $BD01,3 Clear the screen
C $BD04,3 Clear the game variables $B949-$BA35
C $BD0C,2 Three CONTINUE? offers
C $BD11,1 Install the weapon for level 0 (HL=$65E0, kind 5)
C $BD1A,3 Five lives, and print the digit
C $BD1D,2 Redraw the panel's corner pieces from $F000 in bright yellow
C $BD46,3 Draw the bar in columns 0-1 at its starting length
C $BD49,3 Draw 18 segments down columns 30-31 in bright white
C $BD55,3 and the piece at rows 11-12 of columns 30-31
C $BD61,1 Reset $C91F and colour the weapon display
C $BD68,3 Print SCORE, TIME, LIVES and their starting values
C $BD71,3 Print HI-SCORE
C $BD74,3 Print the best score in the table on row 18, column 13
C $BD80,2 with a 0 after it
N $BD85 This entry point is used by the routine at #R$C553. This entry point is used by the JP at $D056 when a world is completed. Reset the per-world variables and load the next world.
@ $BD85 label=NewWorld
C $BD85,3 Clear the variables $B949-$BA14 (not the score)
C $BDAD,2 Five minutes on the clock
C $BDB2,2 Its operand at $BDB3 is where the loader finds the bank index
C $BDB4,3 Bank index = worlds completed / 2
C $BDBD,3 Load the world
c $BDC0 Set up the world just loaded and start a life
D $BDC0 #R$B8C3 jumps here after copying a world into the world area, at the start of every game and between worlds.
D $BDC0 First the world intro: the play area is blanked (#R$C511), PRESS ANY KEY and TO PLAY are printed in the large characters of #R$C4ED and coloured bright yellow (#R$C07C), and an intro tune plays. The tune number is the operand at $BDE3, which is increased and wrapped to 0 after 3 before each play, so in the first game after loading the worlds get tunes 0, 1, 2, 3, 0, 1, 2 (it holds $FF as loaded); nothing resets it for a new game, so later games carry on from where the last one stopped. A key pressed during the tune ends it.
D $BDC0 Then the world's parameters are chosen. Each bank holds two worlds; bit 0 of the count of worlds completed so far ($BA33) picks the first header at $7660 (worlds 1, 3, 5, 7) or the second at $7677 (worlds 2, 4, 6), and with it a pair of values for $CECA and $DE09, the header address for $BE88 and a map pointer for $BA17. One 32-byte block, $0420 bytes past the address in $7665 for the first world in the bank or $0440 for the second, is copied twice, to $0320 and to $0340 bytes past that address; #R$DE96 runs (it makes 15 passes through $DDEE, eight map bytes each, starting eight bytes before the map pointer and writing to the buffer from $F001; clears bit 7 of the flag bytes with #R$C169, zeroes $D25B, applies the ten records at $B95E with C=$19 through #R$C190, reprints HI-SCORE and clears $B95E-$BA14), and the world count at $BA33 is increased. At a world change the #R$C169 calls here and in BeginLife come before $BE9F and $BEA5 install the new world's list address and count, so they walk the previous world's list positions over the newly loaded data; only after a lost life is the list current.
D $BDC0 BeginLife ($BE47) is where every life starts: at a new world by running on from above, and after a lost life by the JP at $CD33. It resets the stack pointer to $B8B7, which also discards the return address left on the stack by the CALL $D77A that led to a world change. It blanks the play area, clears the five enemy slots and the four bytes after them ($B9C2-$BA06), zeroes $BA35, $D215 and $BA03, clears bit 7 of the flag bytes in the list of three-byte entries (#R$C169), waits for an interrupt and redraws the ten entries of $BA19 on rows 22-23 ($C33B), and redraws the bar in columns 0-1 at its current length ($BF4B). It prints WORLD OF, or THE LAST in world 7, copies the header fields into the variables and instruction operands that use them ($DB91, $C6AC, $C58F, the list address and count at $D5D2 and $D5DB, the operand at $C63F, $CC7E, $D046, $D03F), prints the world's name from the address in the header, and colours the play area with an attribute from the header. Then it plays the world's start tune, number 3 plus the world count (tunes 4-10 for worlds 1-7), and jumps to the main loop at #R$C553.
D $BDC0 In world 7 BeginLife also sets the continues operand at $CCB9 to 1, so running out of lives there ends the game without the CONTINUE? offer.
@ $BDC0 label=SetUpWorld
C $BDC0,3 Blank the play area
C $BDC3,3 Print PRESS ANY KEY and TO PLAY
C $BDD3,2 in bright yellow
C $BDD8,3 Next intro tune, 0-3 in turn
C $BDE2,2 Tune played before each world starts. It is the operand of LD A,$FF at $BDE2 and goes up by one at each world load, wrapping from 4 to 0, so it cycles 0, 1, 2, 3.
C $BDE4,3 Play it; a key ends it
C $BDE7,3 Choose the first world's values...
C $BDF9,2 ...or the second's, if an odd number of worlds has been completed
C $BE42,3 Prepare the new map, apply the timed records and clear $B95E-$BA14
C $BE46,1 One more world reached
N $BE47 This entry point is used by the routine at #R$C553. This entry point is used by the JP at $CD33 after a life is lost. Start a life.
@ $BE47 label=BeginLife
C $BE47,3 Reset the stack
C $BE4E,3 Blank the play area
C $BE54,3 Clear the enemy slots
C $BE5C,3 Clear bit 7 of every flag byte in the list (the previous world's list at a world change)
C $BE5F,3 Wait for an interrupt and redraw the ten entries of $BA19 on rows 22-23
C $BE62,3 Redraw the bar in columns 0-1
C $BE65,3 WORLD OF, or in world 7 THE LAST, with no continues
C $BE80,3 Print it
C $BE87,3 Copy the world header's fields into the variables that use them
C $BEC3,1 Print the world's name and colour the play area
C $BEDF,3 Play the world's start tune (4-10)
C $BEE7,3 Enter the main loop
c $BEEA Routine at BEEA
D $BEEA Used by the routines at #R$BCE6 and #R$BEFE.
c $BEFE Routine at BEFE
D $BEFE Used by the routines at #R$D38B, #R$D991 and #R$DAF2.
N $BF15 This entry point is used by the routines at #R$BF39, #R$BF42, #R$C553, #R$D38B and #R$DDAE.
C $BF1A,2 Energy units left: the filled part of the energy bar. #R$BEFE moves one unit from here to the lost count at $BF28 and #R$BF5E moves one back; a life is lost at 0 ($CC9C).
C $BF27,2 Energy units lost: the empty part of the energy bar. #R$BEFE adds one, #R$BF5E takes one away, #R$BF39 adds an empty unit while the total is below 19, and $CD25-$CD2A refill the bar.
c $BF39 Routine at BF39
D $BF39 Used by the routines at #R$D38B and #R$DC4E.
c $BF42 Routine at BF42
D $BF42 Used by the routine at #R$BCE6.
N $BF4B This entry point is used by the routines at #R$BDC0 and #R$DC7D.
b $BF52 Data block at BF52
D $BF52 Used by the routine at #R$DC68.
B $BF52,4,4
c $BF56 Routine at BF56
D $BF56 Used by the routines at #R$BF39 and #R$C553.
c $BF5E Routine at BF5E
D $BF5E Used by the routines at #R$D38B and #R$DC51.
c $BF6A Show the hi-score table and enter a name
D $BF6A Shows the six best scores and, if the score is higher than one of them, moves the lower entries down, prints CONGRATULATIONS and lets the player type a name of up to seven characters (ENTER ends it early) into the new entry; then heads the table THE BEST SIX RANKING, plays tune 11 and starts a new game at #R$BCE6. #R$C3C0 enters at $BF6A, which first saves the panel pieces from the screen to $F000-$F0BF (#R$C1BF), because play overwrites that buffer and NewGame ($BD01) redraws the panel from it; the end of world 7 enters at $BF6D ($B946), after #R$B908 has already saved them before showing the ending pictures. The table itself is the six 12-byte entries at $BBDB (a rank and name in ten characters, then the score as a word).
@ $BF6A label=HiScoreTable
N $BF6D This entry point is used by the routine at #R$B908.
@ $BF6D label=HiScoreTableNoSave
B $BFF4,1,1 Sound effect number, read by #R$C408 (which returns past it)
N $BFFC The table is complete. Retitle it, play tune 11 and start the next game. The control menu is not shown again: play has overwritten the title and menu code.
C $BFFC,3 Blank the attributes of row 1 from column 4, hiding CONGRATULATIONS if it was printed
C $C004,3 Print THE BEST SIX RANKING in its place
C $C00D,2 Play tune 11
C $C012,3 Start a new game with the same controls
c $C015 Routine at C015
D $C015 Used by the routine at #R$BF6A.
c $C074 Routine at C074
D $C074 Used by the routine at #R$C015.
c $C07C Routine at C07C
D $C07C Used by the routines at #R$BDC0, #R$C511, #R$C553 and #R$D77A.
b $C089 Data block at C089
B $C089,8,8
c $C091 Routine at C091
D $C091 Used by the routines at #R$BCE6 and #R$D08C.
N $C0BC This entry point is used by the routine at #R$DCCA.
c $C0F1 Routine at C0F1
D $C0F1 Used by the routine at #R$BCE6.
c $C141 Routine at C141
D $C141 Used by the routines at #R$D65E and #R$DC01.
N $C14C This entry point is used by the routine at #R$DCAC.
c $C169 Routine at C169
D $C169 Used by the routines at #R$BDC0 and #R$DE96.
c $C178 Routine at C178
D $C178 Used by the routine at #R$BEFE.
c $C190 Routine at C190
D $C190 Used by the routines at #R$BCE6 and #R$DE96.
c $C1AA Routine at C1AA
D $C1AA Used by the routines at #R$BCE6 and #R$C553.
c $C1B2 Routine at C1B2
D $C1B2 Used by the routines at #R$BCE6 and #R$C553.
N $C1B8 This entry point is used by the routine at #R$C1AA.
c $C1BF Routine at C1BF
D $C1BF Used by the routines at #R$B908 and #R$BF6A.
c $C1E2 Routine at C1E2
D $C1E2 Used by the routines at #R$BCE6 and #R$C553.
N $C1E7 This entry point is used by the routines at #R$C553 and #R$DC39.
C $C1ED,2 Lives left, as an ASCII digit ('5' = 53 at the start). It is the operand of LD A,$00 at $C1ED in the lives printer $C1E7, which prints it only while it is below ':' ($3A), so a count above 9 is not shown. This is the address the POKE list calls lives, and it really is the lives count.
c $C1F4 Routine at C1F4
D $C1F4 Used by the routines at #R$D77A and #R$DC89.
N $C1F6 This entry point is used by the routines at #R$D77A and #R$DC39.
N $C203 This entry point is used by the routines at #R$BCE6 and #R$C015.
N $C235 This entry point is used by the routine at #R$DAF2.
N $C237 This entry point is used by the routines at #R$BCE6, #R$BF6A, #R$C015, #R$C1E2, #R$C28C and #R$F355.
C $C23E,3 Where the next character is printed: column in the low byte ($C23F), row in the high byte ($C240). It is the operand of LD DE,$1017 at $C23E (the value in the title snapshot) in the character printer at $C237, which advances the column after each character.
c $C284 Routine at C284
D $C284 Used by the routines at #R$BCE6 and #R$DE96.
c $C28C Routine at C28C
D $C28C Used by the routine at #R$BF6A.
N $C292 This entry point is used by the routines at #R$BCE6, #R$BF6A, #R$C284, #R$C3A5, #R$C553, #R$D77A, #R$F1C9 and #R$F355.
N $C29A This entry point is used by the routine at #R$F355.
c $C2D9 Routine at C2D9
D $C2D9 Used by the routines at #R$C553, #R$D65E, #R$D8D6, #R$DB56 and #R$DD58.
c $C2E5 Check for a key press
D $C2E5 Reads every half-row of the keyboard at once (a high byte of 0 selects all eight) and returns NZ if any key is held. The joystick is not read, so every wait built on this routine needs a key, even with KEMPSTON chosen. #R$C2F6 and #R$C2ED loop around it, and the CONTINUE? countdown at $CCE1 calls it directly. The recording reads the port here 745,423 times.
R $C2E5 O:A 0 if no key is held
R $C2E5 O:F Z set if no key is held
@ $C2E5 label=AnyKeyHeld
C $C2E5,1 Read all eight half-rows together
C $C2E8,2 Keep the five key bits (0 = held)
C $C2EA,2 Invert them: the result is 0 only if nothing is held
c $C2ED Wait for a fresh key press
D $C2ED Waits until no key is held, then waits until one is pressed, so a key already held does not count. It is used for the credits screen at the title (called from $F1C6, and the title snapshot is taken inside it), for the pause at $D06F, for each character of the hi-score name at $BFDD, and at $B943 and $D86A. It reads only the keyboard (#R$C2E5).
@ $C2ED label=WaitForKey
C $C2ED,3 Wait until no key is held
C $C2F0,3 Then wait until a key is pressed
c $C2F6 Wait until no key is held
D $C2F6 Loops on #R$C2E5 until no key on the keyboard is held. At the title, it runs at $F1C9 to wait for the key that closed the credits screen to be released before the control menu reads keys 1-5. In the recording that wait lasted from frame 146 to frame 153. It is also used by #R$C2ED, #R$C3C0 (after ABORT), the CONTINUE? countdown at $CCC0, and DEFINE KEYS (#R$F355) before each key and before its Y/N question.
@ $C2F6 label=WaitNoKey
C $C2F6,3 Loop while any key is held
c $C2FC Fill memory with zeros
D $C2FC Zeroes B bytes starting at HL (256 if B is 0). Among its callers, DEFINE KEYS (#R$F355) uses it to clear the keyboard key table #R$EFDC before reading the new keys.
R $C2FC B Number of bytes
R $C2FC HL Address of the first byte
R $C2FC O:C 0
R $C2FC O:HL Address after the last byte
@ $C2FC label=ClearBytes
C $C2FC,2 Fill value
C $C2FE,1 Zero the block
c $C303 Routine at C303
D $C303 Used by the routines at #R$C33B, #R$C4BD, #R$C553 and #R$DD12.
c $C312 Routine at C312
D $C312 Used by the routines at #R$DD06 and #R$DD1E.
c $C332 Get the character of the key being pressed
D $C332 Calls the ROM's KEY-SCAN ($028E), which leaves the key number in E and any shift key in D. The routine then drops the shift and jumps into the ROM's K-TEST at $032C, which looks the key up in the main key table at $0205 and returns. The result is a capital letter, a digit, $20 for SPACE, $0D for ENTER or $0E for SYMBOL SHIFT. KEY-SCAN's result is not checked, so both callers wait for a key first. The hi-score name entry at $BFE0 comes after #R$C2ED, and ENTER ends the name. DEFINE KEYS calls it at $F3B1 and names ENTER and SPACE from the result, but tests SYMBOL SHIFT and CAPS SHIFT on their ports itself. CAPS SHIFT on its own (key number $27) falls one byte past the end of the 39-byte table.
R $C332 O:A Character code
R $C332 O:DE Key number (D is 0)
R $C332 O:HL Address of the character in the ROM's key table
R $C332 O:F Carry set
@ $C332 label=KeyChar
C $C332,3 Scan the keyboard (ROM KEY-SCAN)
C $C335,2 Ignore any shift key
C $C338,3 Look the key up in the ROM's main key table and return
c $C33B Routine at C33B
D $C33B Used by the routines at #R$BDC0 and #R$DBE4.
c $C3A5 Routine at C3A5
D $C3A5 Used by the routines at #R$C3C0 and #R$C553.
c $C3C0 End the game
D $C3C0 Every game ends here, by a JP from one of three places, each passing the message in HL and its screen position (row, column) in DE: OUT OF LIFE when the last life is lost and no continue is taken ($CCF8), ABORT PRESSED when Q, W, E, R and T are held together ($D068), and OUT OF TIME when the clock runs out ($DB19).
D $C3C0 #R$C3A5 blanks the play area, prints the message and draws the 4x2-character graphic at $BAB8 below it (a fallen figure, in the render). The routine then waits until no key is held, plays tune 13 (the same tune as for a lost life at $CD0B), and goes to the hi-score table at #R$BF6A.
D $C3C0 On the way, if the game ended in world 3 or later ($BA33 >= 3; during play $BA33 holds the current world), it writes $FF into the loader's bank index at $BDB3. No run has executed that write, and $BD85 rewrites $BDB3 before the next load in any case, so it has no known effect (see build/d1/paging.json).
R $C3C0 HL Address of the message (OUT OF LIFE, ABORT PRESSED or OUT OF TIME)
R $C3C0 DE Screen position of the message: row in D, column in E
@ $C3C0 label=GameOver
C $C3C0,3 Blank the play area, print the message and the fallen figure
C $C3C3,3 Wait until no key is held
C $C3C6,2 Play tune 13
C $C3CB,3 Did the game end in world 3 or later?
C $C3D2,2 Then put $FF in the loader's bank index (no known effect)
C $C3D7,3 Show the hi-score table
c $C3DA Routine at C3DA
D $C3DA Used by the routines at #R$C553, #R$D08C, #R$D333, #R$D38B, #R$D513 and #R$D77A.
c $C3EB Routine at C3EB
D $C3EB Used by the routines at #R$C553, #R$DB56 and #R$DD58.
c $C400 Routine at C400
D $C400 Used by the routines at #R$C553 and #R$D77A.
c $C408 Routine at C408
D $C408 Used by the routines at #R$BF6A, #R$D08C, #R$D38B, #R$D65E, #R$D77A, #R$D8D6 and #R$DBAB.
c $C480 Find an enemy slot by its first byte
D $C480 Searches the five 13-byte enemy slots at $B9C2 for the first one whose first byte equals A. Called with A=0 it finds a free slot, which is how #R$C553 checks that a random enemy can be started before choosing where.
R $C480 A Value to look for (0 for a free slot)
R $C480 O:HL Address of the slot found
R $C480 O:F Zero flag set if one was found
@ $C480 label=FindEnemySlot
C $C480,3 Point one slot (13 bytes) before the first slot
C $C488,1 Move to the next slot
C $C489,1 Return with HL pointing at it if its first byte matches
c $C48E Count the active enemies of a type
D $C48E Counts the enemy slots at $B9C2 whose ninth byte equals A. That byte is the fifth byte of the template the enemy was started from (the enemy's type), and is 0 in an unused slot. #R$C553 starts a type 7 or type 6 enemy at random only if none of that type is active, and a type 4 only if fewer than two are.
R $C48E A Enemy type
R $C48E O:A Number of slots holding that type (also in C)
R $C48E O:F Zero flag set if there are none
@ $C48E label=CountEnemyType
C $C498,1 Does this slot hold an enemy of the type?
C $C49B,1 Count it if so
C $C49F,1 A=count, zero flag set if none
c $C4A2 Routine at C4A2
D $C4A2 Used by the routines at #R$C1B2, #R$C553, #R$D65E and #R$DBE4.
c $C4B0 Routine at C4B0
D $C4B0 Used by the routines at #R$C33B and #R$DBE4.
c $C4BD Routine at C4BD
D $C4BD Used by the routine at #R$C4ED.
c $C4ED Routine at C4ED
D $C4ED Used by the routines at #R$BDC0 and #R$C553.
c $C511 Routine at C511
D $C511 Used by the routines at #R$BDC0, #R$C3A5 and #R$D77A.
N $C512 This entry point is used by the routine at #R$C553.
c $C51F Routine at C51F
D $C51F Used by the routine at #R$D08C.
c $C553 Main game loop
D $C553 One pass of this loop is one step of play: it reads the controls, starts enemies, moves the player (scrolling the map when the player walks left or right), moves the enemies, handles a lost life, builds the player's sprite, waits for the next frame interrupt, and then checks for the end of the world, the abort keys and the pause key, and runs the clock. It then continues by jumps, not calls: through the clock routines #R$DAD7 or #R$DAF2 to the clock print at $DB1C, into #R$D08C, which draws the screen, and on through the loop tail in #R$D38B, whose six JP $C553 instructions ($D4BA, $D4C0, $D4D2, $D4EB, $D4F2, $D510) start the next pass. The stack is empty at the loop head (SP=$B8B7 at every pass traced).
D $C553 The loop is entered by JP $C553 at $BEE7, at the end of the world set-up code that starts at $BE47. That code runs at every world start and again after every lost life ($CD33 JP $BE47), so a lost life restarts the loop from the set-up, not from here.
D $C553 Each pass waits for a frame interrupt at $CEFA-$CEFB. The only other wait in a pass is the EI/HALT at #R$D991, in the weapon code reached from #R$D08C while weapon kind 6 is attacking (91 frames of world 7 ended halted there, none in worlds 1-6). Otherwise a pass is paced by the time it takes: a pass is never shorter than four frames, and in the recording it averaged 4.49, 4.49, 4.46, 4.43, 4.32, 4.36 and 4.36 frames in worlds 1-7 (frames from one world load to the next divided by the $CEFB HALTs in between, so including life-lost, world-complete and load pauses; 4.12-4.19 over ordinary passes of 12 frames or fewer). When the player does not scroll, the busy loop at #R$DAC9 takes the place of the scroll routine so that a pass takes about as long either way. About one frame interrupt per pass is lost (1.01-1.03 per pass, 23% of all frames in play), almost all while #R$D08C's call to the drawing routine at $EBFA runs with interrupts disabled; the game's interrupt routine in play is only EI/RETI (#R$E986), so a lost interrupt costs nothing but time.
D $C553 The ways out of the loop: energy used up with lives left shows LIFE LOST and goes to $BE47 (at $CD33); with no lives left, CONTINUE? is offered while continues remain ($CCB8), and OUT OF LIFE ends the game at #R$C3C0; killing a world 1-6 guardian (#R$D77A, JP NZ,$D04A at $D83C) or reaching the world's end-of-map column ($D03B-$D047) waits 256 frames at $D04A and starts the next world at $BD85; the world 7 guardian leads to the ending (#R$B908, from $D86D); holding Q, W, E, R and T ($D059) shows ABORT PRESSED, and the clock passing 0:00 ($DB13) shows OUT OF TIME, both ending the game at #R$C3C0.
@ $C553 label=MainLoop
C $C553,3 Read the controls into #R$BAB2-#R$BAB7
N $C556 Start the world's guardian when the map has scrolled far enough. Nothing is done while a guardian is active (#R$D513 draws it). In every world the guardian starts when the column at $B95C equals the value the world set-up stores at $C58F; its two addresses come from the world header at $7667-$766A. World 7 also has two fixed guardian positions, $B95A=$023A (header $7667-$766A) and $B95A=$046E (header $767E-$7681, with $B951 set to 1).
C $C556,3 Is a guardian already active?
C $C55A,3 Jump if so
C $C55D,3 Is this world 7?
C $C562,3 Jump if not
C $C565,3 World 7: has the scroll position reached the first guardian ($B95A=$023A)?
C $C56E,3 Jump if so to use the guardian in the world header
C $C571,3 Has it reached the second guardian ($B95A=$046E)?
C $C57A,3 Jump if not
C $C57D,3 Collect the second guardian's two addresses from the world header
C $C584,2 Note that this is the second world 7 guardian
C $C589,2 Join the common set-up
C $C58B,3 Has the map column reached the guardian's column? (The operand at $C58F comes from the world header.)
C $C590,3 Jump if not
C $C593,3 Collect the guardian's two addresses from the world header
C $C59A,3 Plant them in the guardian code at #R$D513
C $C5A4,2 Stop the player walking left while the guardian is active: XOR A ($AF) over the OR L at $C9E7 makes the left-walk test at $C9E3 always see scroll position 0 ($D832-$D834 put OR L back when a guardian is destroyed)
C $C5A9,3 Mark the guardian active (any non-zero value)
N $C5AC Start enemies at random. Once a pass (about every four and a half frames in play) the R register decides whether to start a type 7 enemy (a 1 in 16 chance) at the left or right edge, or else a type 6 enemy (3 in 128) at alternating edges, both on the row in $B95D. An enemy's type is the fifth byte of its template; the templates for types 4, 6 and 7 are addressed by $7690, $7694 and $7692 in the world data. An enemy is only started if none of its type is active (#R$C48E) and a slot is free (#R$C480).
C $C5AC,2 Take a pseudo-random number from the R register (0-127: nothing ever loads R, so bit 7 stays 0)
C $C5AE,2 Is it below 8 (a 1 in 16 chance)?
C $C5B0,3 If not, consider a type 6 enemy instead
C $C5B3,2 Is a type 7 enemy already active?
C $C5B8,3 Jump if so
C $C5BB,1 Is an enemy slot free (HL pointing at it)?
C $C5BF,3 Jump if not
C $C5C2,4 BC=address of this world's type 7 enemy template
C $C5C6,2 Start at column 1, the left edge
C $C5C8,2 Read R again to choose the side. This read comes 46, 50, 54 or 58 fetches after the one at $C5AC (4 more for each later free slot), so its bit 0 is that read's bit 0 unless an interrupt came in between
C $C5CA,2 Is it even?
C $C5CC,2 Jump if so to start at the left edge
C $C5CE,2 Otherwise start at column 29, the right edge
C $C5D2,2 Read R again for a type 6 enemy. Coming straight from $C5B0 this is the first read plus 4, so the test below passes only when that read was 124, 125 or 126
C $C5D4,2 Is it below 3 (3 in 128)?
C $C5D6,3 If not, start nothing at an edge this pass
C $C5D9,2 Is a type 6 enemy already active?
C $C5DE,3 Jump if so
C $C5E1,1 Is an enemy slot free (HL pointing at it)?
C $C5E5,3 Jump if not
C $C5E8,4 BC=address of this world's type 6 enemy template
C $C5EC,2 Start at column 1, the left edge
C $C5EF,3 Advance the side counter at $BA32 (type 6 enemies alternate sides; this choice is not random)
C $C5F3,2 Is it now even?
C $C5F6,2 Jump if so to start at the left edge
C $C5F8,2 Otherwise start at column 28, the right edge
C $C5FA,3 D=the player's row, as stored at $C6E5 on the previous pass
C $C5FE,1 Set the carry flag if the enemy starts in the left half of the screen (#R$DD41 then sets bit 7 of the slot's byte 9)
C $C601,1 Keep that flag for #R$DD41
C $C602,1 A=high byte of the template address (non-zero, marking the slot in use)
C $C603,3 Fill in the slot
N $C606 While $BA06 is non-zero (set to $7B at $C71D when the player steps on a map cell holding $79 or $7A), redraw that cell with #R$DB3B about every eight passes, using $7C, $7D and $7E in turn, and then clear $BA06. What this effect is in the game is not established.
N $C63E Start the enemy that the world's object list (#R$D5D1) holds for the column now at $B95C, if an enemy slot is free (#R$C480) and the entry is not yet marked as started (bit 7 of its second byte). The entry is marked before bit 6 is compared with $B957, so an entry for the other part of the map is marked and never starts.
N $C69B Start a type 4 enemy at a map cell holding 0. If fewer than two are active and one of the 112 map cells addressed by $BA17 holds 0, there is a 1 in 8 chance of starting one there, provided a slot is free.
C $C69B,2 Count the type 4 enemies
C $C6A0,2 Are there two or more?
C $C6A2,3 Jump if so
C $C6A5,3 HL=address of the visible map, eight cells per column
C $C6A8,3 Look for a cell holding 0 among its 112 bytes
C $C6AF,2 Jump if there is none
C $C6B1,2 Take a pseudo-random number (0-127) from R
C $C6B3,2 Is it below 16 (a 1 in 8 chance)?
C $C6B5,2 Jump if not
C $C6B7,1 Is an enemy slot free (HL pointing at it)?
C $C6BB,2 Jump if not
C $C6BD,2 A=offset of the zero cell plus 1
C $C6C0,2 Set the carry flag if offset+1 is below 56, roughly the first half (#R$DD41 then sets bit 7 of byte 9)
C $C6C3,1 Keep that flag for #R$DD41
C $C6C4,1 D=row: twice the low three bits of offset+1
C $C6C9,1 E=column: a quarter of offset+1, plus 1
C $C6D0,4 BC=address of this world's type 4 enemy template
C $C6D4,3 Fill in the slot
N $C6D7 Look at where the player stands. Store the player's character row (from the display address at $B94E) at $B95D, and test the map cells at the player's position with #R$DB9F, collecting what is there with #R$DBAB. A cell holding $79 or $7A starts the cell effect above; a cell holding $98 clears $BA28, if it is set, and calls #R$C1AA and #R$C1B2.
N $C75E Vertical movement. While $B954 is set the player falls eight pixel lines a pass (#R$DD12), or, while $BA27 is set, glides two lines down, or rises four lines (#R$DD06) while up is held and the cell above is clear; while $B953 counts down the player rises eight lines a pass (#R$DD06). The map cells below or above, tested with #R$DB90, end the movement.
C $C7FF,3 Is up held?
N $C832 Down held: on a $7F, $80 or $B2 cell the player climbs down (#R$DD12, with the state at $B94A set); elsewhere $BA07 is set to 1 and $BA35 to $10, a state the sprite and drawing code test.
C $C832,3 Is down held?
N $C8B3 Up held: on a $7F, $80 or $B2 cell the player climbs up (#R$DB56, #R$DD06); otherwise, if the cell above is clear, a rise starts with $B953 set to 4, or to 12 when bit 0 of $BA23 is set and $BA27 is zero.
C $C8B3,3 Is up held?
N $C950 Fire. #R$D77A runs the player's attack while a shot is out (the byte at $D25B) or the attack counter (the operand of LD A,$00 at $C95A) is running, and when fire is held. While attacking the player does not walk: these paths go straight to #R$DAC9. $D2A9 and $BA05 are set here for the weapon code reached from #R$D08C.
C $C97F,3 Is fire held?
N $C9C3 Left held, or a scroll step already begun ($D4A2 not 4 or 8) while facing left ($B952 non-zero, tested by #R$DD24). A player facing right first turns round; a player facing left scrolls the map one step with #R$EA4D, decrementing the scroll position at $B958 and the step count at $D4A2. The map cells beside the player (offsets $28 and $29, tested by #R$DD58) can block the walk, and nothing scrolls at $B958=0, the left end of the map.
C $C9D2,3 Is left held?
C $CA72,3 One scroll step fewer before the map window moves a column
C $CA76,3 Move the scroll position back one step
C $CA7D,3 Scroll the map
C $CA80,3 Skip the delay at #R$DAC9, which stands in for a scroll
N $CA83 Right held, or a scroll step already begun while facing right. As for left, but the scroll routine is #R$E989, $B958 is incremented and the cells tested are at offsets $38 and $39.
C $CA83,3 Is right held?
C $CB13,3 One scroll step fewer before the map window moves a column
C $CB17,3 Move the scroll position on one step
C $CB1E,3 Scroll the map, then fall through
N $CB21 This entry point is used by the routine at #R$DAC9. The pass rejoins here from the scroll routines, or from #R$DAC9 when the map did not scroll. Count down $BA08 (while it is non-zero #R$DBAB collects nothing).
@ $CB21 label=MainLoopAfterMove
C $CB21,3 Is the $BA08 countdown running?
C $CB26,3 Jump if not
C $CB29,1 Count it down
N $CB2A At weapon level 6 ($BA2D), and while the attribute at $59BE is $46, flash the 2x2 attribute block at rows 11-12, columns 30-31 by changing its INK every eight passes (the counter is the operand of LD A,$08 at $CB3A).
N $CB51 Move the enemies in the five 13-byte slots at #R$B9C2. Each active slot (byte 0 non-zero) is stepped according to its type (byte 8) and the map cells around it, its new graphic address is stored in bytes 0-1, and #R$DD29 checks its position (bytes 2-3); an enemy that has left the screen is removed by #R$D909, which also frees its object list entry.
N $CC9C Lose a life when the energy ($BF1B) is used up, except on a pass whose scroll step has just brought $D4A2 to zero (the loop tail resets it at $D4A1). The lives digit (the operand at $C1EE) is decremented and printed by $C1E7. While lives remain, LIFE LOST is shown, tune 13 is played and play restarts at $BE47 (below). When the digit reaches '0' a continue is needed: if any remain (the operand at $CCB9 is 4 in a new game, so three are offered, and 1 in world 7, so none), CONTINUE? is shown with a countdown from 9, one digit every 50 frames (#R$C400), and a key held when a digit is shown (#R$C2E5) resets the lives to 5 (#R$C1E2) and continues; otherwise OUT OF LIFE ends the game at #R$C3C0.
C $CC9C,3 Is there any energy left?
C $CCA0,3 Jump if so
C $CCA3,3 Has this pass's scroll step just brought $D4A2 to zero?
C $CCA7,3 Jump if so (the life is lost on a later pass)
C $CCAA,3 Take a life from the lives digit (the operand of LD A,n at $C1ED)
C $CCAF,3 Print it
C $CCB3,2 Was that the last life?
C $CCB6,2 Jump if not
C $CCB8,2 A=continues left plus one (the operand at $CCB9)
C $CCBA,1 Any continues left?
C $CCBB,2 Jump if not to OUT OF LIFE
C $CCBD,3 Use one
C $CCC0,3 Wait until no key is held
C $CCC3,2 Recolour the play area (A=5, via $C512)
C $CCC8,3 Print CONTINUE?
C $CCD1,2 Start the countdown at '9'
C $CCD3,3 Put the digit into the message
C $CCD7,3 Print it
C $CCE1,3 Is a key held?
C $CCE4,2 Jump if so to continue
C $CCE6,3 Wait 50 frames
C $CCEC,1 Next digit down
C $CCEE,2 Until the countdown has passed '0'
C $CCF2,3 OUT OF LIFE: end the game
C $CCFB,3 Continue: give five lives again
C $CD00,3 Show LIFE LOST
C $CD09,2 Play tune 13
N $CD0E Restart after a lost life or a continue. If #R$C4A2 returns NZ for A=$61, clear $BA19-$BA2B and put back the NOP at $C91F (an instruction byte that the item handler at $DBF9 rewrites); if it returns Z, clear only the byte at the HL it returns. Refill the energy bar to its full length (#R$BF56, #R$BF15) and jump into the world set-up at $BE47, which resets the stack, plays the world tune and comes back to #R$C553 at $BEE7.
C $CD0E,2 Clear $BA19-$BA2B unless #R$C4A2 returns Z for A=$61
C $CD1D,1 Put back the NOP at $C91F
C $CD23,2 Item $61 is held: use it up (clear its slot, which #R$C4A2 left HL pointing at) instead of clearing the other items
C $CD25,3 Refill the energy bar: energy = energy + energy lost
C $CD28,2 No energy lost
C $CD2D,3 Draw the bar
C $CD30,3 Restart the world from its set-up code (HL=$BA33, the world number; the set-up code at $BE47 does not use it)
N $CD36 Build the player's sprite. A display address at $B94E whose high byte has bit 6 clear is reset to $4010. The frame is chosen from $B949 and $B94A (graphics from $5DA0, the address kept at $CDA4), copied with #R$EDB4, overlaid with the pieces that $BA24, $BA25, $BA26, $BA07 and $BA28 select (#R$EDD5), and mirrored with #R$ECCB while the player faces left.
N $CE77 At a whole or half scroll column (#R$DD93), count down the ten 9-byte map-cell timers from $B95E. When one runs out, its cell is put back to its value less $19 (the $19 that #R$DBAB adds when a cell is collected) and, if the cell is on screen, redrawn with #R$DB3B.
C $CEC9,2 $93 when the first world in the bank is loaded, $82 for the second. It is the operand of LD C,$00 at $CEC9 and is also read at $DE19, where it replaces a block number before the block address is computed at $DE29-$DE36. What the value means is not established.
N $CED3 Work out where the drawing code in #R$D08C puts things this pass: 16 pixel lines below the player's display address (24 while $BA07 is set) and two columns left, kept at $CF8D, and eight lines above that, one column left (one right when facing left), kept at $D1AF.
C $CED3,3 Start from the player's display address
C $CED6,2 16 pixel lines down, or 24 while $BA07 is set
C $CEE5,1 Two columns left
C $CEE7,3 Keep it for the drawing code
C $CEEA,2 Eight pixel lines back up
C $CEEF,1 One more column left, or one right if the player faces left
C $CEF7,3 Keep that for the drawing code too
N $CEFA Wait for the next frame interrupt. This is the pass's one regular frame wait (#R$D991 adds a second one while weapon kind 6 is attacking); the rest of the pass is paced by how long it takes (see the routine description).
C $CEFA,1 Wait for the next frame
N $CEFC Set up the weapon graphic that #R$D08C draws with $EBB0: the operand at $D17F (non-zero to draw nothing), and the values for A, DE and HL at $D184, $D186 and $D189. The graphic depends on the weapon kind ($BA2C), the facing, $BA07, the attack state at $D2A9 and $B949, and on fire being held; the graphics come from $EE60 (copied there from the address at $BA2E), $EEC0 or $6640. The short DJNZ at $CF57 runs when nothing is drawn.
C $CEFC,1 Draw a weapon graphic this pass unless changed below
C $CF4B,3 Is fire held?
N $CFC7 Derive the scroll position in other units: $B95A is $B958 divided by 4, and $B95C the low byte of $B958 divided by 8, the map column. Unless $CE4B or $B94A is non-zero, align the player's display address at $B94E to the top of a character row.
C $CFC7,3 HL=scroll position
C $CFCA,1 Halve it twice (a logical shift: the carry is cleared first)
C $CFD6,3 Store scroll position / 4
C $CFD9,1 Halve it once more
C $CFDF,1 Store the low byte of (scroll position / 8), the map column
C $CFE3,3 Leave the player's position alone if $CE4B or $B94A is non-zero
C $CFF1,3 Otherwise clear the pixel-line bits of the display address, aligning the player to the top of a character row
N $CFF9 Advance the four-step animation counter (the operand at $CFFA) and point $D1AC ($7120 upwards, or $7520 when facing left) and $CE46 ($70A0 upwards) at the matching graphics.
C $CFF9,2 Advance the animation counter, 0-3 (the operand at $CFFA)
C $D004,1 A=counter*$40
C $D00A,3 Graphics for facing right, or for facing left
C $D016,3 Plant the frame's address in the drawing code
C $D019,1 A=counter*$20
C $D022,3 Plant the matching address at $CE46
N $D025 With the energy below 4, $BA05 zero and weapon kind 6, call #R$DC35 (the item handler that sets A=5 and joins $DCAC).
C $D025,3 Is the energy below 4?
C $D02A,2 Jump if not
C $D02C,3 Is $BA05 non-zero?
C $D033,3 Call #R$DC35 if the weapon kind is 6
N $D03B The second way to finish a world: reaching the end-of-map column. The world set-up stores the jump opcode at $D03F ($C2 JP NZ or $CA JP Z, from bit 0 of a header byte) and the column at $D046 (that byte with bit 0 set), so the test passes on the header's column in the part of the map the header selects ($B957 zero or non-zero). No pass in the recording met it: every world 1-6 ended through the guardian.
C $D03B,3 Is the player in the part of the map the world's end-of-map test needs? (The opcode at $D03F is JP NZ or JP Z, set by the world set-up.)
C $D042,3 Has the map column reached the world's end column (the operand at $D046, set by the world set-up)?
C $D045,2 Operand of CP $FF at $D045: the map column ($B95C) at which the world ends by the end-of-map test, the world header byte with bit 0 set. In the recording it was never met.
C $D047,3 Jump if not; otherwise the world is completed
N $D04A This entry point is used by the routine at #R$D77A. World completed, entered here from #R$D77A (JP NZ,$D04A at $D83C, from inside a call) when a world 1-6 guardian dies, or from the test above. For 256 frames call #R$C07C once a frame with the frame count (0, 255 ... 1) in A, which fills the attributes of the play area (16 rows of 26 cells from row 0, column 3) with it, so the play area flashes through the colours; then start the next world at $BD85, which clears the per-world variables and loads the world; the stack is reset later at $BE47.
@ $D04A label=WorldCompleted
C $D04A,2 256 frames
C $D04C,1 A=frames left (0 the first time)
C $D04D,1 Wait for the next frame
C $D050,3 Fill the play area's attributes with A (#R$C07C), so it flashes through the colours
C $D054,2 Repeat for all 256 frames
C $D056,3 Start the next world
N $D059 Holding Q, W, E, R and T together aborts the game.
C $D059,2 Read Q, W, E, R and T
C $D05D,2 Are all five held?
C $D062,3 Yes: show ABORT PRESSED and end the game (#R$C3C0)
N $D06B Pause until a fresh key press.
C $D06B,3 Is the pause key held?
C $D06F,3 Yes: wait for its release and then for any key (the joystick cannot resume)
N $D072 Time bonus. While the operand at $D073 is non-zero (#R$DC91 sets it to 60) each pass adds a second to the clock (#R$DAD7) instead of counting down, so a bonus adds one minute.
C $D072,2 Any time bonus left (the operand at $D073)?
C $D075,3 Jump if not to count the clock down
C $D078,1 Use one second of it
C $D07C,3 Add the second to the clock
N $D07F Count the passes at $BA30 and tick the clock down (#R$DAF2) every 13th pass, reloading the count with 12; the other passes only reprint the clock ($DB1C). The pass then goes on to #R$D08C.
C $D07F,3 Count down the passes to the next clock tick
C $D083,3 Jump if there are passes left, only to print the clock
C $D086,2 Otherwise reload the count for 13 passes
C $D089,3 Take a second off the clock
c $D08C Main loop: draw the play area and the sprites
D $D08C The second part of every pass of the main loop (#R$C553), reached by JP $D08C at the end of the clock print ($DB38), after the frame wait. It does not return: it runs on into the weapon code and the loop tail (#R$D38B, #R$D333, #R$D923, #R$D991), which jump back to $C553.
D $D08C In order: it clears the enemy position map at $EF80-$EFFF by pushing 64 zero words from SP=$F000; lists up to five active enemy slots at $BA09-$BA12 with five calls to #R$C51F; unless a guardian is active, writes each listed enemy's number (5 down to 1) into its cells of that map, which the loop tail reads for collisions; calls #R$C091; counts down the immunity timer at $BA2A and flashes the LIFE label while it runs (#R$D5C2); after a short delay, copies the play area from the buffer at $F000 to the screen with $EBFA; puts the player's sprite (16 pixels wide and 32 lines, from the buffer at $5C00) on the screen in the two bytes before the display address in $B94E on each of its 32 lines; draws the weapon graphic set up at $CEFC ($EBB0) and the other overlays ($EB72); draws the guardian (#R$D513) or the listed enemies ($E977, #R$EB11); runs the sound effect and shot counters at $D214 and $D25A (#R$C408); and while $BA05 counts down continues into the weapon code, #R$D991 for weapon kind 6 or #R$D923 for the others, otherwise into #R$D38B or straight to its $D3BE part.
D $D08C Two stretches run with interrupts disabled because they use SP as a data pointer: $EBFA (about 53,600 T-states, three quarters of a frame) and $D13A-$D170 (about 2,360 T-states). The first almost always spans a frame interrupt, which is lost: 1.01-1.03 lost interrupts per pass in every world.
@ $D08C label=DrawPass
N $D112 While the immunity timer at $BA2A is running (set to 200 by #R$DC54), count it down and flash the LIFE label at the top left of the status bar in random colours; otherwise keep it bright yellow.
C $D112,3 Is the immunity timer running?
C $D116,2 C=bright yellow on black, the LIFE label's usual colour
C $D118,3 Jump if the timer is not running
C $D11B,1 Count the timer down
C $D11F,2 Take a pseudo-random number from R
C $D121,2 Keep the INK and BRIGHT bits, so PAPER stays black and FLASH off
C $D123,2 Make INK odd: blue, magenta, cyan or white, never black
C $D126,3 Colour the LIFE label
B $D228,1,1 Sound effect number, read by #R$C408 (which returns past it)
N $D2DC This entry point is used by the routine at #R$D923.
@ $D2DC label=DrawPassWeapon
c $D333 Main loop: run the map-cell routines on five pairs of cells beside the player
D $D333 Part of the main loop's weapon code, reached only by JP $D333 at $DA9B (in #R$D991). For A=4 down to 0 it calls #R$D8D6 once and $D660 twice for the map cells at offsets worked out from A, the scroll step count at $D4A2 and the facing (#R$DD24), then joins the loop tail at $D3BE in #R$D38B. What the calls do to the cells is left to the weapon chunk.
@ $D333 label=WeaponOnCells
c $D38B Main loop: finish a pass
D $D38B The last part of every pass of the main loop (#R$C553). It is reached from #R$D08C (JP C,$D38B at $D2D9, or JP $D3BE from $D2AC, $D2B6, $D2E4, $D330) and from the weapon code (#R$D333 at $D388, #R$D991 at $D9F2 and $DA3E), and it ends every pass with one of six JP $C553 instructions.
D $D38B In order: while the operand at $D38C (set at $DCB9 by the weapon handler) is non-zero, it calls #R$D8D6 and #R$D64F for the map cells next to the player; from $D3BE it draws the effects that the counters $BA03 and $BA04 time ($E977, $EB72); from $D42B it moves the player between the two parts of the map: walking off the bottom of the screen (row 12 or more) sets $B957 to $40 and moves the map window ($BA17) $0680 on, and leaving by the top (row 0, with up held or a rise running, and the cell above passable) clears $B957 and moves it back (#R$DD66); at $D4A1 it completes a scroll column when the step count at $D4A2 (the operand of LD A,$08 at $D4A1) has reached 0 (#R$DDC4 resets it to 8 and moves the map window); and from $D4A5 it checks the enemy position map built by #R$D08C at the player's position.
D $D38B The collision check reads the cell of that map at $EFB9 plus half the player's row and, if it is empty and $BA07 is zero, the cell before it; if both are empty the pass ends. $FF lengthens the energy bar by one empty unit (#R$BF39 adds one to the energy-lost count at $BF28 while energy plus lost is below 19, then redraws the bar) and $FE moves up to three units from the lost part of the bar back to the energy (#R$BF5E, #R$BF15), each with sound effect 11 (#R$C408). Any other value is an enemy's number. Unless the immunity timer at $BA2A is running, it plays sound effect 1 and counts the contact at $D504 (the operand of LD A,$00 at $D503): with B three quarters of the armour total $BA24+$BA25+$BA26 read by #R$DDA2 (halved, plus that halved again), B contact passes go by between drains, and on the next one #R$BEFE is called (which takes energy on every second call, $BA31) and the count restarts. With no armour every contact pass calls #R$BEFE.
@ $D38B label=EndPass
N $D3BE This entry point is used by the routines at #R$D08C, #R$D333 and #R$D991.
@ $D3BE label=EndPassCounters
C $D46C,3 Is up held? (Not tested while $B953 is non-zero.)
C $D4A1,2 Operand of LD A,$08 at $D4A1: scroll steps left in the current map column, 8 down to 0. Each scroll step decrements it; when it reaches 0, #R$DDC4 (called at $D4A4) resets it to 8 and moves the map window at $BA17 a column. The movement code treats 8 and 4 as the points where the player may turn, climb or collect (#R$DD93, #R$DCD7, #R$DBAB), and a life is not lost on a pass that has just brought it to 0.
B $D4D1,1,1 Sound effect number, read by #R$C408 (which returns past it)
B $D4EA,1,1 Sound effect number, read by #R$C408 (which returns past it)
B $D4F8,1,1 Sound effect number, read by #R$C408 (which returns past it)
c $D513 Move and draw the end-of-world guardian
D $D513 Used by the main loop at $D1DE, in place of drawing the enemies, while $B955 is set. The guardian follows a list of display-file addresses set up at $C59A-$C5A0 from the world data ($7667 and $7669, or $767E and $7680 when $B95A holds $046E), taking one entry a pass and starting again at the $FF that ends it; bit 7 of an entry's high byte selects the second of two sets of graphics. Each pass it marks a block of 16 cells in the collision map at $EF80 with $FD, which is how #R$D77A knows the player's weapon has hit it, and draws it in two parts. Once its damage at $B956 reaches 64 it also draws one extra 16-line sprite per point of damage above 63 (1-16, since at 80 it is destroyed), each picked at random from the four 64-byte sprites at $6BA0 and placed at one of four spots chosen by the count divided by 4, so up to four sprites share each spot.
@ $D513 label=DrawGuardian
N $D588 Once the damage at $B956 reaches 64, draw one extra sprite per point above 63, each picked at random from four.
C $D588,3 Has the guardian taken 64 or more damage?
C $D58D,1 Return if not
C $D58E,2 B=damage minus 63: the number of sprites to draw (1-16)
C $D591,1 Save the count
C $D592,2 Take a pseudo-random number from R. Each later read in the same pass comes 546 or 549 fetches after the previous one, which advances R by 34 or 37 (mod 128), so the choices follow on from the first rather than being independent
C $D594,2 Keep 0-3
C $D596,1 Times 64
C $D59B,3 HL=address of one of the four 64-byte sprites at $6BA0
C $D59F,3 DE=the guardian's row and column (written at $D53C)
C $D5A2,2 Use the count divided by 4 to pick one of four spots
C $D5A6,1 Column offset 1 or 3
C $D5AD,1 Row offset 0 or 2
C $D5B6,3 Turn the row and column into a display-file address
C $D5B9,2 Draw the sprite, 16 lines high
C $D5BF,2 Next sprite
c $D5C2 Colour the LIFE label
D $D5C2 Fills the attributes of columns 0-1 on rows 0-3, where the status bar's LIFE label is, with C. Used once a main-loop pass at $D126: bright yellow normally, a random colour while the immunity timer at $BA2A runs.
R $D5C2 C Attribute byte
@ $D5C2 label=ColourLifeLabel
C $D5CA,1 Colour column 0 and column 1 of this row
C $D5CD,1 Move to column 0 of the next row
c $D5D1 Routine at D5D1
D $D5D1 Used by the routine at #R$C553.
C $D5D1,3 Address of the current world's list of 3-byte entries. It is the operand of LD HL,$0000 at $D5D1 and comes from bytes 13-14 of the world header.
C $D5DA,2 Number of entries in the current world's list of 3-byte entries. It is the operand of LD B,$00 at $D5DA and comes from byte 15 of the world header.
c $D5E3 Routine at D5E3
c $D603 Routine at D603
N $D604 This entry point is used by the routine at #R$D65E.
c $D64F Routine at D64F
D $D64F Used by the routine at #R$D38B.
c $D65E Routine at D65E
D $D65E Used by the routine at #R$D64F.
N $D660 This entry point is used by the routines at #R$D08C and #R$D333.
N $D663 This entry point is used by the routine at #R$DCD7.
N $D742 This entry point is used by the routine at #R$D603.
B $D75E,1,1 Sound effect number, read by #R$C408 (which returns past it)
c $D763 Routine at D763
D $D763 Used by the routine at #R$D65E.
c $D77A Routine at D77A
D $D77A Used by the routine at #R$C553.
N $D8A5 Hitting an enemy whose template has bit 5 of its second byte set (for example the type 6 enemy; some templates in the ($768E) table have it too) may upgrade a weak weapon at random.
C $D8A5,4 Is bit 5 of the enemy's template byte set?
C $D8A9,2 Jump if not
C $D8AB,3 A=weapon level
C $D8AF,2 Jump unless it is level 0
C $D8B1,3 Upgrade the weapon on a one in two chance
C $D8B6,2 Level 1?
C $D8B8,2 If so, try for an upgrade
C $D8BA,2 Level 4?
C $D8BC,2 If so, try for an upgrade
B $D8D4,1,1 Sound effect number, read by #R$C408 (which returns past it)
c $D8D6 Routine at D8D6
D $D8D6 Used by the routines at #R$D08C, #R$D333 and #R$D38B.
B $D907,1,1 Sound effect number, read by #R$C408 (which returns past it)
c $D909 Routine at D909
D $D909 Used by the routines at #R$C553 and #R$D77A.
c $D923 Routine at D923
D $D923 Used by the routine at #R$D08C.
c $D986 Routine at D986
D $D986 Used by the routine at #R$D923.
c $D991 Routine at D991
D $D991 Used by the routine at #R$D08C.
c $DA9E Routine at DA9E
D $DA9E Used by the routine at #R$D991.
c $DAA7 Routine at DAA7
D $DAA7 Used by the routine at #R$C553.
c $DAC9 Take the time of a scroll when the map does not scroll
D $DAC9 Part of the main loop (#R$C553). Every movement path that does not scroll the map jumps here (22 JP $DAC9 instructions between $C881 and $CB10) instead of calling #R$EA4D or #R$E989. The busy loop runs 3,000 times at 45 T-states each, about 135,000 T-states, close to the 150,000 a scroll takes, so a pass lasts about as long whether or not the map scrolls. It then rejoins the loop at $CB21.
D $DAC9 Either way this part of a pass lasts nearly two frames (a frame of the recording is about 69,800 T-states); a whole pass takes four frames or more (#R$C553).
@ $DAC9 label=NoScrollDelay
C $DAC9,3 3,000 turns of a 45 T-state loop
C $DACC,1 Waste time
C $DACE,1 Until the count runs out
C $DAD4,3 Rejoin the main loop
c $DAD7 Add a second to the clock
D $DAD7 Part of the main loop (#R$C553), reached only by JP $DAD7 at $D07C while the time bonus at $D073 is running. It adds one second to the clock digits at $B94B-$B94D (minutes, tens of seconds, seconds; plain values, not ASCII), carrying from the seconds into the tens at 10 and from the tens into the minutes at 6. The minutes are not limited. It continues at $DB1C to print the clock.
D $DAD7 The bonus runs for 60 passes, so it adds one minute of game time in about five seconds of real time (247 frames in the example below); in the recording each bonus added exactly one minute (for example 3:20 to 4:20 over frames 18,817-19,064).
@ $DAD7 label=AddBonusSecond
C $DAD7,3 Add a second
C $DADB,1 Has it reached 10?
C $DADE,3 Jump if not to print the clock
C $DAE1,2 Seconds back to 0 and carry into the tens
C $DAE5,1 Have the tens reached 6?
C $DAE8,3 Jump if not to print the clock
C $DAEB,2 Tens back to 0 and carry into the minutes
C $DAEF,3 Print the clock
c $DAF2 Take a second off the clock, and print the clock
D $DAF2 Part of the main loop (#R$C553), reached only by JP $DAF2 at $D089 on every 13th pass (not while a time bonus runs). It takes one second off the clock digits at $B94B-$B94D (minutes, tens of seconds, seconds), borrowing from the tens when the seconds pass 0 and from the minutes when the tens do. In world 2 of the recording (frames 15,000-17,000) the clock ticked once every 54.25 frames on average (52-66), about 12.95 passes, so a clock second is a little longer than a real one.
D $DAF2 Each time the seconds wrap from 0 to 9, and while the flag at $BA2B is set, it calls #R$BEFE, which takes energy on every second call, so energy then falls once every twenty clock seconds.
D $DAF2 When the minutes go below 0 the clock has run out: OUT OF TIME is shown and the game ends at #R$C3C0.
D $DAF2 The entry at $DB1C is used on every pass, directly from $D083 and at the end of #R$DAD7: it prints the three digits on row 18, minutes at column 25 and the seconds at columns 27-28, skipping column 26, and continues the pass at #R$D08C.
@ $DAF2 label=TickClock
C $DAF2,3 Take a second off
C $DAF6,3 Jump if the seconds did not pass 0
C $DAF9,2 Seconds back to 9
C $DAFB,3 Is the energy drain flag set?
C $DAFF,3 Jump if not
C $DB02,1 Drain energy (every second call does)
C $DB07,1 Borrow from the tens
C $DB09,3 Jump if they did not pass 0
C $DB0C,2 Tens back to 5, and borrow from the minutes
C $DB10,3 Jump if the minutes did not pass 0
C $DB13,3 Time is up: show OUT OF TIME and end the game
N $DB1C This entry point is used by the routines at #R$C553 and #R$DAD7. Print the clock. This entry is used on every pass.
@ $DB1C label=PrintClock
C $DB1C,3 Print at row 18, column 25
C $DB22,3 Minutes
C $DB28,3 Skip column 26
C $DB2C,3 Tens of seconds
C $DB32,3 Seconds
C $DB38,3 Carry on with the pass
c $DB3B Routine at DB3B
D $DB3B Used by the routines at #R$C553, #R$D65E and #R$DBAB.
c $DB56 Routine at DB56
D $DB56 Used by the routine at #R$C553.
c $DB90 Routine at DB90
D $DB90 Used by the routines at #R$C553, #R$D38B and #R$DD58.
c $DB9F Routine at DB9F
D $DB9F Used by the routine at #R$C553.
c $DBAB Routine at DBAB
D $DBAB Used by the routine at #R$C553.
B $DBCA,1,1 Sound effect number, read by #R$C408 (which returns past it)
c $DBE4 Routine at DBE4
N $DBE6 This entry point is used by the routine at #R$DBFD.
c $DBF7 Routine at DBF7
c $DBFD Routine at DBFD
c $DC01 Routine at DC01
N $DC0A This entry point is used by the routine at #R$DDBC.
c $DC17 Routine at DC17
c $DC1C Routine at DC1C
c $DC25 Data block at DC25
c $DC29 Routine at DC29
N $DC2E This entry point is used by the routine at #R$DC25.
c $DC31 Data block at DC31
c $DC35 Routine at DC35
D $DC35 Used by the routine at #R$C553.
c $DC39 Routine at DC39
c $DC48 Routine at DC48
D $DC48 Used by the routine at #R$DC5A.
c $DC4E Routine at DC4E
c $DC51 Routine at DC51
D $DC51 Used by the routine at #R$DC17.
c $DC54 Routine at DC54
D $DC54 Used by the routine at #R$DC17.
c $DC5A Routine at DC5A
c $DC61 Routine at DC61
c $DC68 Data block at DC68
c $DC7D Routine at DC7D
c $DC89 Collect item $40: a random score bonus
D $DC89 The handler for the map item $40: entry 18 of the handler table at $BA5B, reached through the JP (HL) at $DBE3 when the player collects an item (#R$DBAB). It adds 5 plus the R register (0-127) to the score counter at $BA15. The score is displayed with a fixed trailing zero, so the bonus is 50-1,320 points. It ran 12 times in the recording, adding 9 to 117 to the counter (90-1,170 points).
@ $DC89 label=ItemScoreBonus
C $DC89,2 Take a pseudo-random number (0-127) from R
C $DC8B,2 Add 5
C $DC8D,1 C=bonus, 5-132
C $DC8E,3 Add it to the score
c $DC91 Routine at DC91
D $DC91 Used by the routine at #R$DC39.
c $DC97 Routine at DC97
D $DC97 Used by the routine at #R$DC1C.
c $DC9C Routine at DC9C
D $DC9C Used by the routine at #R$DC1C.
c $DCA1 Routine at DCA1
D $DCA1 Used by the routine at #R$DC1C.
c $DCA6 Routine at DCA6
c $DCAA Data block at DCAA
c $DCAC Routine at DCAC
D $DCAC Used by the routines at #R$DC29, #R$DC35, #R$DC61 and #R$DCA6.
N $DCB2 This entry point is used by the routines at #R$BCE6 and #R$DC01.
c $DCCA Routine at DCCA
D $DCCA Used by the routines at #R$DC97, #R$DC9C and #R$DCA1.
c $DCD7 Routine at DCD7
D $DCD7 Used by the routine at #R$C553.
c $DD06 Routine at DD06
D $DD06 Used by the routine at #R$C553.
c $DD12 Routine at DD12
D $DD12 Used by the routine at #R$C553.
c $DD1E Routine at DD1E
D $DD1E Used by the routines at #R$C553, #R$D08C, #R$D923 and #R$D991.
c $DD24 Routine at DD24
D $DD24 Used by the routines at #R$C553, #R$D08C, #R$D333, #R$D763, #R$D77A, #R$D923, #R$D986, #R$D991, #R$DA9E and #R$DD66.
c $DD29 Routine at DD29
D $DD29 Used by the routine at #R$C553.
c $DD41 Fill in an enemy slot
D $DD41 Starts an enemy in the slot at HL: marks it in use, sets its column and row, copies the five bytes of its template into bytes 4-8 (byte 8 being its type) and sets byte 9 to $80 if the carry flag in the alternate flags is set (the enemy starts in the left half of the screen), or $00 otherwise. Byte 1 is left alone. Used by the three random spawns in #R$C553 and by $C691.
R $DD41 A Non-zero value marking the slot in use
R $DD41 BC Address of the enemy's five-byte template
R $DD41 D Row
R $DD41 E Column
R $DD41 HL Address of the slot
R $DD41 F' Carry set to set bit 7 of byte 9 (the enemy starts on the left)
R $DD41 O:HL Address of byte 9 of the slot
@ $DD41 label=FillEnemySlot
C $DD41,1 Mark the slot in use
C $DD44,1 Column
C $DD46,1 Row
C $DD4E,2 Copy the template into bytes 4-8
C $DD51,2 Byte 9: start with bit 7 reset
C $DD53,1 Did the enemy start on the left?
C $DD55,2 If so, set bit 7
c $DD58 Routine at DD58
D $DD58 Used by the routine at #R$C553.
c $DD66 Routine at DD66
D $DD66 Used by the routine at #R$D38B.
c $DD93 Routine at DD93
D $DD93 Used by the routine at #R$C553.
c $DD9C Routine at DD9C
D $DD9C Used by the routines at #R$BCE6 and #R$C553.
c $DDA2 Routine at DDA2
D $DDA2 Used by the routine at #R$C091.
c $DDAE Routine at DDAE
D $DDAE Used by the routine at #R$DC29.
c $DDBC Upgrade the weapon on a one in two chance
D $DDBC Used by #R$D77A when the player's weapon hits an enemy whose template has bit 5 of its second byte set while the weapon level at $BA2D is 0, 1 or 4. If bit 0 of the R register is set, the weapon goes up a level through $DC0A (unless it is already at level 6), without the weapon-kind check the item at #R$DC01 makes; otherwise nothing happens. In the recording this ran 17 times and upgraded the weapon 8 times.
@ $DDBC label=MaybeUpgradeWeapon
C $DDBC,2 Take a pseudo-random number from R
C $DDBE,2 Is it even?
C $DDC0,1 Return if so: no upgrade
C $DDC1,3 Otherwise upgrade the weapon
c $DDC4 Routine at DDC4
D $DDC4 Used by the routine at #R$D38B.
N $DDEE This entry point is used by the routine at #R$DE96.
c $DDFD Routine at DDFD
D $DDFD Used by the routine at #R$DDC4.
C $DE08,2 $C7 when the first world in the bank is loaded, $C8 for the second. It is the operand of LD A,$00 at $DE08. It is a substitute block number: at $DE03, a block code of $60 or more is replaced by this value and indexed at $DE29 into the block table at ($DE2F), as $DE19 does with the byte at $CECA. Why those codes are replaced is not established.
N $DE29 This entry point is used by the routine at #R$DB3B.
C $DE2E,3 Base address of a table of 32-byte blocks in the world area, taken from the word at $7665 (header bytes 5-6, shared by both worlds in a bank). It is the operand of LD BC,$0000 at $DE2E, where HL = (A-$60)*32 + base.
c $DE96 Routine at DE96
D $DE96 Used by the routine at #R$BDC0.
N $DE99 This entry point is used by the routine at #R$DD66.
c $DEC6 Play a tune
D $DEC6 Play tune A, then put the in-game interrupt routine back. SP is saved first into the operand of the LD SP instruction at $DECE (address $DECF). However the tune ends, the stack is then put back exactly as it was on entry, discarding the interpreter's return address and anything the tune left on the stack. A tune can end normally: the RET Z at $DF13 returns to $DECD. It can also be cut short by a key press during a rest, when the rest loop jumps from $DF57 straight to $DECD. Interrupts are disabled while the stack pointer is reset and the vector is changed back to #R$E986. Otherwise the tune interrupt routine #R$DF90, still installed, could count down L and throw away the caller's return address. Returns with interrupts enabled even if the caller had them off, so #R$B908 disables them again at $B929. When the tune uses effects, IX is corrupted (#R$DF90, #R$DFEF). The recording calls it 23 times: 22 tunes finish (8 of them cut short by a key) and the 23rd, tune 11 from $C00F, is still playing when the recording ends.
R $DEC6 A Number of the tune
@ $DEC6 label=PlayTune
C $DEC6,4 Save SP in the LD SP instruction at $DECE
C $DECA,3 Play the tune (the interpreter returns here at the end marker)
N $DECD This entry point is used by the routine at #R$DF4E. The tune has ended, or a key was pressed during a rest ($DF57 jumps here).
@ $DECD label=EndTune
C $DECD,1 Keep the tune interrupt routine out while the stack is reset
C $DECE,3 Restore SP as it was on entry, discarding whatever the tune left on the stack
C $DED1,3 Put the in-game interrupt routine back
C $DED7,1 Re-enable interrupts
c $DED9 Tune interpreter
D $DED9 Play tune A: look it up in the table at $E254, install the tune interrupt routine and interpret the tune's bytes. This description covers only the use of interrupts; the tune format, the commands through the table at $E27E and the tone generator #R$DF5A belong with the sound routines. The tune's first table byte is written over the instruction at $DF54 in the rest loop #R$DF4E: INC A lets a key press end the tune, XOR A makes it ignore keys. Interrupts are disabled while #R$DF90 is installed at $DEEF, together with I=$B7 and interrupt mode 2, which are set again for every tune. They stay disabled while tune bytes are interpreted. They are enabled only once L holds a length in interrupts, just before calling the tone generator (EI at $DF3B) or the rest loop. Neither call returns by itself: #R$DF90 counts L down and, when it reaches zero, discards the interrupted address so that its RETI returns to $DF3F or $DF4A. A note of length n sounds for n-1 interrupts and is followed by a rest of one interrupt. An $FF byte makes the RET Z at $DF13 return, at the top level to $DECD in #R$DEC6.
R $DED9 A Number of the tune
@ $DED9 label=RunTune
C $DEE2,3 Set the rest loop's key check for this tune (INC A: a key ends the tune; XOR A: keys are ignored)
C $DEEA,1 Interrupts off while the tune interrupt routine is installed
C $DEEC,3 Install the tune interrupt routine
C $DEF2,2 Make sure interrupt mode 2 is on with the vector table at $B700
C $DF05,3 No tune effects yet
C $DF0C,3 Reset the effect countdown
N $DF0F This entry point is used by the routine at #R$E09E.
@ $DF0F label=TuneLoop
C $DF3A,1 L = length of the note in interrupts, less the one-interrupt rest that follows it
C $DF3B,1 Let the tune interrupt routine time the note
C $DF3C,3 Sound the note until the tune interrupt routine ends it
C $DF3F,1 Then rest for one interrupt
C $DF46,1 L = length of the rest in interrupts
C $DF47,3 Wait out the rest (a key may end the tune)
C $DF4A,1 Interrupts off while the next tune byte is interpreted
c $DF4E Rest during a tune
D $DF4E Called from the tune interpreter with L holding the length of a rest in interrupts. It loops, reading the keyboard, until #R$DF90 counts L to zero and returns past it to the caller. The instruction at $DF54 is set for each tune at $DEE2. With INC A, any key pressed makes A non-zero and the tune is abandoned through $DECD in #R$DEC6, which also resets the stack. With XOR A, A is always zero and the keyboard is ignored.
R $DF4E L Length of the rest, in interrupts
@ $DF4E label=TuneRest
C $DF4E,1 Let the tune interrupt routine count the rest
C $DF50,2 Read all the keyboard half-rows at once
C $DF52,2 Set the bits that are not keys
C $DF54,1 INC A: zero only if no key is pressed; XOR A (set per tune): always zero
C $DF55,2 Keep resting until the tune interrupt routine ends the rest
C $DF57,3 A key was pressed: abandon the tune
c $DF5A Routine at DF5A
D $DF5A Used by the routines at #R$DED9 and #R$E114.
c $DF90 Tune interrupt routine
D $DF90 Installed by the tune interpreter #R$DED9 while a tune plays. It interrupts the tone generator #R$DF5A, the rest loop #R$DF4E, or the same tone generator #R$DF5A called from the tune command at #R$E114 ($E151, with L=1, returning to $E154), and it works on the interrupted code's registers: L holds the number of interrupts left in the current note or rest. Normally it decrements L and returns. When L reaches zero it restores AF and then pops the interrupted address as well, so that the RETI returns to the address that called the endless tone or rest loop ($DF3F or $DF4A in the interpreter, $E154 in #R$E114). That is the only way those loops finish, and A and F then hold the discarded address. When tune effects are on ($E2B2 non-zero) it also counts down $E2B3. When that reaches zero it leaves L alone, restores AF, pushes the address of #R$DFB2 on top of the interrupted address and returns there with RETI. The effect code then runs with interrupts enabled, as a continuation of this interrupt. This corrupts IX. #R$DFEF re-enters at $DFAA to count the interrupt that ends the effect.
R $DF90 L Interrupts left in the current note or rest (in the interrupted code's register set)
@ $DF90 label=TuneInterrupt
C $DF90,1 Save the interrupted AF
C $DF91,3 Are tune effects on?
C $DF95,2 If not, just count the note
C $DF97,3 Count down to the next effect
C $DF9E,2 Not yet: just count the note
C $DFA0,1 Time for an effect: restore the interrupted AF
C $DFA1,4 Push the effect starter's address on top of the interrupted address
C $DFA7,1 Re-enable interrupts
C $DFA8,2 and 'return' to the effect starter
N $DFAA This entry point is used by the routine at #R$DFEF. Count one interrupt off the current note or rest (also entered from #R$DFEF).
@ $DFAA label=CountTuneTick
C $DFAA,1 One interrupt fewer left
C $DFAB,2 Still going: go and return to the interrupted code
C $DFAD,1 Finished: restore AF
C $DFAE,1 Restore AF, or when finished discard the interrupted address so that RETI returns to the loop's caller
C $DFAF,1 Re-enable interrupts
c $DFB2 Start the next tune effect
D $DFB2 Reached from #R$DF90 by a RETI, not through the vector, when the effect countdown at $E2B3 runs out. The address where the tone generator or rest loop was interrupted is still on top of the stack. It saves AF, BC, DE and HL and counts the interrupt that brought it here off L, but never down to zero, so a note due to end now ends at the next interrupt instead. Then it installs #R$DFEF as the interrupt routine and enables interrupts. Next it reads the effect list at the address held in $E2B4. Bytes with bit 7 set are commands, run through the table at $E28E with the list pointer in DE. The first byte with bit 7 reset ends the reading: its low five bits, less one, become the new countdown, and bits 5 and 6 choose one of four effect routines through the table at $E29A ($DFFD, $E024, $E010, $E038). Each of those loops for ever making sound, so the effect lasts until the next interrupt, which #R$DFEF uses to end it.
R $DFB2 L Interrupts left in the current note or rest
@ $DFB2 label=StartTuneEffect
C $DFB2,1 Save the interrupted registers
C $DFB5,1 Count this interrupt off the note or rest
C $DFB8,1 but leave at least one, so the note ends at the next interrupt instead
C $DFB9,1 Save HL too
C $DFBA,3 Make the next interrupt end the effect
C $DFC0,1 Interrupts on: the effect lasts until the next one
C $DFC1,3 Pick up the effect list pointer
C $DFC4,1 Read the next byte of the effect list
C $DFC7,3 Bit 7 reset: an effect
C $DFCA,2 Otherwise run this command (table at $E28E) with the list pointer in DE
C $DFD2,2 and read on
C $DFD4,1 The low five bits, less one, are the countdown to the next effect
C $DFDB,1 Bits 5 and 6 choose the effect routine
C $DFE2,3 Save the list pointer
C $DFE5,2 Look the routine up in the table at $E29A
N $DFEE This entry point is used by the routine at #R$DED9.
C $DFEE,1 Jump to it (an effect routine loops until the next interrupt)
c $DFEF End a tune effect
D $DFEF The interrupt routine while a tune effect sounds (installed at $DFBD). It puts #R$DF90 back as the interrupt routine and pops the address the effect routine was interrupted at into IX, where it is thrown away. It restores HL, DE and BC as #R$DFB2 saved them and continues at $DFAA in #R$DF90. That counts this interrupt off L and either returns to the note or rest that was interrupted before the effect, restoring the AF saved by #R$DFB2, or ends it. Runs with interrupts disabled until the RETI there. Leaves IX corrupted.
R $DFEF L Interrupts left in the current note or rest (restored from the stack)
@ $DFEF label=EndTuneEffect
C $DFEF,3 Put the tune interrupt routine back
C $DFF5,2 Discard the address the effect routine was interrupted at
C $DFF7,1 Restore the registers saved by #R$DFB2
C $DFFA,3 Count this interrupt and return to the note or rest
c $DFFD Routine at DFFD
c $E010 Routine at E010
c $E024 Routine at E024
c $E038 Routine at E038
c $E04D Routine at E04D
c $E055 Routine at E055
c $E05B Routine at E05B
c $E069 Routine at E069
N $E07F This entry point is used by the routines at #R$E04D and #R$E05B.
c $E08C Routine at E08C
D $E08C Used by the routine at #R$E069.
b $E098 Data block at E098
B $E098,6,6
c $E09E Routine at E09E
c $E0AA Routine at E0AA
b $E0B0 Data block at E0B0
B $E0B0,17,8*2,1
c $E0C1 Routine at E0C1
N $E0D0 This entry point is used by the routine at #R$E0E9.
c $E0DD Routine at E0DD
D $E0DD Used by the routine at #R$E0E9.
c $E0E9 Routine at E0E9
c $E100 Routine at E100
c $E114 Routine at E114
b $E16A Data block at E16A
B $E16A,328,8
@ $E2B2 label=TuneEffectsOn
B $E2B2,1,1 Non-zero while the current tune's effect list is active.
@ $E2B3 label=TuneEffectCountdown
B $E2B3,1,1 Interrupts until the next tune effect starts.
@ $E2B4 label=TuneEffectList
W $E2B4,2,2 Address of the next byte of the tune's effect list.
B $E2B6,400,8
t $E446 Message at E446
T $E446,4,4
b $E44A Data block at E44A
B $E44A,2,2
t $E44C Message at E44C
T $E44C,5,5
b $E451 Data block at E451
B $E451,1,1
t $E452 Message at E452
T $E452,4,4
b $E456 Data block at E456
B $E456,7,7
t $E45D Message at E45D
T $E45D,8,8
b $E465 Data block at E465
B $E465,1,1
t $E466 Message at E466
T $E466,7,7
b $E46D Data block at E46D
B $E46D,335,8*41,7
t $E5BC Message at E5BC
T $E5BC,3,3
b $E5BF Data block at E5BF
B $E5BF,1,1
t $E5C0 Message at E5C0
T $E5C0,4,4
b $E5C4 Data block at E5C4
B $E5C4,3,3
t $E5C7 Message at E5C7
T $E5C7,3,3
b $E5CA Data block at E5CA
B $E5CA,1,1
t $E5CB Message at E5CB
T $E5CB,29,29
b $E5E8 Data block at E5E8
B $E5E8,3,3
t $E5EB Message at E5EB
T $E5EB,4,4
b $E5EF Data block at E5EF
B $E5EF,372,8*46,4
t $E763 Message at E763
T $E763,7,7
b $E76A Data block at E76A
B $E76A,9,8,1
t $E773 Message at E773
T $E773,7,7
b $E77A Data block at E77A
B $E77A,4,4
t $E77E Message at E77E
T $E77E,3,3
b $E781 Data block at E781
B $E781,4,4
t $E785 Message at E785
T $E785,15,15
b $E794 Data block at E794
B $E794,177,8*22,1
t $E845 Message at E845
T $E845,3,3
b $E848 Data block at E848
B $E848,15,8,7
t $E857 Message at E857
T $E857,4,4
b $E85B Data block at E85B
B $E85B,9,8,1
t $E864 Message at E864
T $E864,4,4
b $E868 Data block at E868
B $E868,1,1
t $E869 Message at E869
T $E869,4,4
b $E86D Data block at E86D
B $E86D,1,1
t $E86E Message at E86E
T $E86E,10,10
b $E878 Data block at E878
B $E878,255,8*31,7
c $E977 Routine at E977
D $E977 Used by the routines at #R$C33B, #R$D08C, #R$D38B, #R$D513, #R$D8D6 and #R$ED4E.
c $E986 In-game interrupt routine
D $E986 The interrupt routine during play and whenever no tune is playing after the menu. It does nothing but re-enable interrupts and return. Its job is to end the HALT in the game's EI; HALT waits ($C33B, $C400, $CEFA, $D04D, $D991); the interrupt does no timing work of its own. It is installed at $F225 when the game starts and at $DED4 when a tune ends. It lives in bank 0 at $C000-$FFFF, so code that pages another bank there keeps interrupts disabled (#R$B8C3, #R$B908).
@ $E986 label=GameInterrupt
C $E986,1 Re-enable interrupts
C $E987,2 and return to the interrupted code
c $E989 Routine at E989
D $E989 Used by the routines at #R$C553 and #R$DD66.
c $EA4D Routine at EA4D
D $EA4D Used by the routine at #R$C553.
c $EB11 Routine at EB11
D $EB11 Used by the routines at #R$D08C and #R$D513.
N $EB1C This entry point is used by the routine at #R$D991.
N $EB72 This entry point is used by the routines at #R$D08C, #R$D38B, #R$D513, #R$D923 and #R$D991.
N $EBB0 This entry point is used by the routines at #R$D08C and #R$D991.
c $EBFA Routine at EBFA
D $EBFA Used by the routine at #R$D08C.
c $EC9C Routine at EC9C
D $EC9C Used by the routines at #R$BCE6, #R$BF6A and #R$F1C9.
c $ECCB Routine at ECCB
D $ECCB Used by the routine at #R$C553.
c $ECE9 Routine at ECE9
D $ECE9 Used by the routine at #R$DCAC.
c $ED23 Routine at ED23
D $ED23 Used by the routines at #R$C511, #R$F1C9 and #R$F4BC.
c $ED4E Routine at ED4E
D $ED4E Used by the routines at #R$BCE6, #R$BEEA, #R$BEFE, #R$C33B and #R$C3A5.
C $ED84,2 The attribute #R$ED4E colours a drawn graphic with (operand of LD A,$07 at $ED84). Callers poke it before drawing; the entry at $ED86 skips the LD A and uses the caller's A instead (#R$C07C, $C348).
N $ED86 This entry point is used by the routines at #R$C07C and #R$C33B.
c $ED98 Routine at ED98
D $ED98 Used by the routine at #R$C1BF.
c $EDB4 Routine at EDB4
D $EDB4 Used by the routine at #R$C553.
c $EDD5 Routine at EDD5
D $EDD5 Used by the routine at #R$C553.
b $EE03 Data block at EE03
B $EE03,105,8*13,1
t $EE6C Message at EE6C
T $EE6C,3,3
b $EE6F Data block at EE6F
B $EE6F,45,8*5,5
t $EE9C Message at EE9C
T $EE9C,3,3
b $EE9F Data block at EE9F
B $EE9F,9,8,1
t $EEA8 Message at EEA8
T $EEA8,4,4
b $EEAC Data block at EEAC
B $EEAC,31,8*3,7
t $EECB Message at EECB
T $EECB,3,3
b $EECE Data block at EECE
B $EECE,5,5
t $EED3 Message at EED3
T $EED3,3,3
b $EED6 Data block at EED6
B $EED6,11,8,3
t $EEE1 Message at EEE1
T $EEE1,3,3
b $EEE4 Data block at EEE4
B $EEE4,20,8*2,4
t $EEF8 Message at EEF8
T $EEF8,3,3
b $EEFB Data block at EEFB
B $EEFB,5,5
t $EF00 Message at EF00
T $EF00,6,6
b $EF06 Data block at EF06
B $EF06,18,8*2,2
t $EF18 Message at EF18
T $EF18,3,3
b $EF1B Data block at EF1B
B $EF1B,5,5
t $EF20 Message at EF20
T $EF20,3,3
b $EF23 Data block at EF23
B $EF23,1,1
t $EF24 Message at EF24
T $EF24,3,3
b $EF27 Data block at EF27
B $EF27,4,4
t $EF2B Message at EF2B
T $EF2B,4,4
b $EF2F Data block at EF2F
B $EF2F,9,8,1
t $EF38 Message at EF38
T $EF38,3,3
b $EF3B Data block at EF3B
B $EF3B,5,5
t $EF40 Message at EF40
T $EF40,3,3
b $EF43 Data block at EF43
B $EF43,13,8,5
t $EF50 Message at EF50
T $EF50,3,3
b $EF53 Data block at EF53
B $EF53,5,5
t $EF58 Message at EF58
T $EF58,3,3
b $EF5B Data block at EF5B
B $EF5B,6,6
t $EF61 Message at EF61
T $EF61,3,3
b $EF64 Data block at EF64
B $EF64,4,4
t $EF68 Message at EF68
T $EF68,3,3
b $EF6B Data block at EF6B
B $EF6B,6,6
t $EF71 Message at EF71
T $EF71,3,3
b $EF74 Data block at EF74
B $EF74,17,8*2,1
t $EF85 Message at EF85
T $EF85,6,6
b $EF8B Data block at EF8B
B $EF8B,8,8
t $EF93 Message at EF93
T $EF93,3,3
b $EF96 Data block at EF96
B $EF96,2,2
t $EF98 Message at EF98
T $EF98,3,3
b $EF9B Data block at EF9B
B $EF9B,14,8,6
t $EFA9 Message at EFA9
T $EFA9,6,6
b $EFAF Data block at EFAF
B $EFAF,45,8*5,5
b $EFDC Keyboard key table (default or defined keys)
D $EFDC Six two-byte entries, one each for right, left, down, up, fire and pause. Each entry holds the high byte of the key's half-row port and the key's bit mask, as read by #R$F48B. The default keys are X (right), Z (left), SYMBOL SHIFT (down), L (up), ENTER (fire) and 1 (pause). DEFINE KEYS (#R$F355) clears these 12 bytes and writes the new keys here in the same order. #R$F1C9 copies the table to #R$BAA6 when key 1 (KEYBOARD) is chosen. Play overwrites it with other data, so it only matters until the game starts.
@ $EFDC label=KeyboardKeys
B $EFDC,2,2 Right: X
B $EFDE,2,2 Left: Z
B $EFE0,2,2 Down: SYMBOL SHIFT
B $EFE2,2,2 Up: L
B $EFE4,2,2 Fire: ENTER
B $EFE6,2,2 Pause: 1
b $EFE8 Sinclair Interface 2 key table
D $EFE8 The key table #R$F1C9 copies to #R$BAA6 for SINCLAIR 1. It uses the keys that Sinclair Interface 2's first joystick produces: 7 (right), 6 (left), 8 (down), 9 (up) and 0 (fire), with 1 for pause. The layout is the same as #R$EFDC.
@ $EFE8 label=SinclairKeys
B $EFE8,2,2 Right: 7
B $EFEA,2,2 Left: 6
B $EFEC,2,2 Down: 8
B $EFEE,2,2 Up: 9
B $EFF0,2,2 Fire: 0
B $EFF2,2,2 Pause: 1
b $EFF4 Cursor-key table
D $EFF4 The key table #R$F1C9 copies to #R$BAA6 for CURSOR. It uses the cursor keys 8 (right), 5 (left), 6 (down) and 7 (up), with 0 for fire and 1 for pause. The layout is the same as #R$EFDC.
@ $EFF4 label=CursorKeys
B $EFF4,2,2 Right: 8
B $EFF6,2,2 Left: 5
B $EFF8,2,2 Down: 6
B $EFFA,2,2 Up: 7
B $EFFC,2,2 Fire: 0
B $EFFE,2,2 Pause: 1
b $F000 Data block at F000
B $F000,192,8
c $F0C0 Start the game and draw the title screen
D $F0C0 The game's entry point. Imagine's tape loader, which runs from the area the worlds are later loaded into, finishes with IM 1, a zeroed R register, SP=$9ED8, EI and JP $F0C0. This code runs once: nothing in the game jumps back here, and it is not in any recorded or scripted run after the title snapshot was taken.
D $F0C0 First it moves data from where the loader left it to where the game uses it: 6,336 bytes of graphics used during play from $9FFA to $5DA0-$765F (for example the four 64-byte sprites at $6BA0 read at $D59B), 352 bytes of font from $EE60 to $5C40 (characters $30-$5B, 0 to [, eight bytes each, as the character printer at $C237 addresses them) and a 256-byte bit-reversal table from $F4C6 to $5B00 (each byte holds its index with the bits in reverse order; #R$ECE9 uses it to mirror graphics). It fills the IM 2 vector table at #R$B700 with $B8, writes JP $E986 at #R$B8B8, and switches to interrupt mode 2 with I=$B7. So the interrupt routine while the title is drawn is #R$E986, which only re-enables interrupts and returns.
D $F0C0 Then it draws the title screen: black border, the screen cleared by #R$EC9C, the figure of Athena at both sides, the ATHENA logo at the top, the Imagine and SNK logos at the bottom, each coloured by #R$ED4E with the attribute poked into $ED85 beforehand, patches of colour filled in by #R$F4AC, and the copyright line printed by #R$C28C on the bottom row.
D $F0C0 Another 800 bytes go from $9CDA to $FCE0-$FFFF only after the logos are drawn, because that copy overwrites part of their graphics. Then it installs the title interrupt routine #R$F49E, which cycles the logo's colours (#R$F240), prints the credits text at $F2EE from row 6, column 9 in white, and waits at #R$C2ED for a key. When one is pressed it runs on into #R$F1C9, the control menu. The title snapshot data/athena128.z80 was taken during that wait, with $F1C9 on the stack.
D $F0C0 There is no timeout and no second page: the credits stay on screen until a key is pressed, and the title is never drawn again, since part of its graphics is gone and the game restarts at #R$BCE6 after a game over.
@ $F0C0 label=Start
C $F0C0,1 No interrupts while the machine is set up
C $F0C1,3 Put the stack under the interrupt jump at $B8B8
C $F0C4,3 Move the graphics used in play from $9FFA to $5DA0-$765F
C $F0CF,3 Fill all 257 bytes of the IM 2 vector table at $B700 with $B8
C $F0DD,2 Make $B8B8 a JP to the do-nothing interrupt routine at $E986
C $F0E8,2 Interrupt mode 2 with I=$B7, and enable interrupts
C $F0EF,3 Move the font (characters $30-$5B) from $EE60 to $5C40
C $F0FA,3 Move the bit-reversal table from $F4C6 to $5B00
N $F105 Draw the title screen.
C $F105,1 Black border
C $F108,3 Clear the screen and attributes
T $F10B,3,3 Draw Athena at the left in bright yellow
B $F10E,64,8
B $F14E,8,8 Draw the ATHENA logo across the top; the title interrupt cycles its colours
B $F156,4,4
T $F15A,3,3 Draw the Imagine logo in bright cyan
B $F15D,33,8*4,1
T $F17E,3,3
B $F181,6,6
T $F187,5,5 Colour the letters SNK bright blue
B $F18C,6,6
T $F192,3,3 Colour the words under the Imagine logo bright white
B $F195,8,8
T $F19D,3,3 Two more white cells on row 21
B $F1A0,16,8
N $F1B0 Show the credits and wait for a key.
B $F1B0,8,8 Install the title interrupt routine, which cycles the logo's colours
B $F1B8,8,8 Print the credits in plain white from row 6, column 9
B $F1C0,9,8,1
c $F1C9 Choose the control method
D $F1C9 Shows the control menu and sets up the control routine the player picks. The routine is reached from the start-up code just before it. The credits screen at $F1B8-$F1C8 calls #R$C2ED to wait for a key, and the title snapshot's stack holds $F1C9 as that call's return address (at $B8B5). This routine waits for that key to be released, blanks the credits, prints the menu (#R$F2AA) and then reads keys 1-5 over and over, with no wait for release between reads. Key 1 (KEYBOARD) copies the key table at #R$EFDC (the default keys, or the ones set by DEFINE KEYS) to #R$BAA6 and the key-table routine #R$F48B to #R$BA8D. Key 3 (CURSOR) and key 4 (SINCLAIR 1) do the same with the tables at #R$EFF4 and #R$EFE8. Key 2 (KEMPSTON) copies the joystick routine #R$F472 to #R$BA8D and leaves $BAA6 alone, but only if the joystick port reads with bit 7 clear. Key 5 goes to #R$F355 to define the keys, and that routine comes back to $F1D6. The routine then points the IM 2 jump at $B8B8 at the in-game interrupt routine $E986 instead of the title's #R$F49E, calls #R$EC9C and enters the game at $BD01. The routine and table have to be copied because play overwrites this area: in every world snapshot, $EFDC-$EFFF and $F472-$F49D hold other bytes. Nothing in the game jumps back to this menu (after game over or ABORT, $C012 jumps to $BCE6, which runs on into $BD01), so the method chosen here stays in force for every later game. Quirk: once the Kempston test fails, A holds the byte read from port $1F, not the keyboard row, so the tests for keys 3, 4 and 5 are made on the joystick byte. A port that reads $FF fails all three, and the menu reads the keys again; stray bits 2-4 would select option 3, 4 or 5 instead.
D $F1C9 Interrupts are disabled around the Kempston read and around the change of vector. The vector change is a single instruction, which an interrupt cannot split, so that DI is only a precaution; the reason for the DI around the port read is not evident.
@ $F1C9 label=SelectControls
C $F1C9,3 Wait until the key that closed the credits screen is released
C $F1CC,3 Blank columns 8-23 of screen row 16 (#R$ED23)
N $F1D6 This entry point is used by the routine at #R$F355.
@ $F1D6 label=ShowControlMenu
C $F1D6,2 Print the menu in bright white on black (the attribute the text printer writes at $C27F)
C $F1DB,3 Blank columns 8-23 of rows 6-15
C $F1DE,3 Print the menu from row 7, column 10
N $F1E7 Read keys 1-5 until one of them picks a control method.
C $F1E7,2 Read keys 1-5
C $F1EB,2 Is key 1 (KEYBOARD) pressed?
C $F1EF,3 Yes: use the keyboard key table
C $F1F5,2 Is key 2 (KEMPSTON) pressed?
C $F1F9,1 Yes: read the Kempston port with interrupts disabled
C $F1FC,2 Bit 7 set: no Kempston interface, so skip key 2 (the key tests that follow now test the Kempston byte)
C $F202,3 Kempston: copy only the joystick routine
C $F207,2 Is key 3 (CURSOR) pressed?
C $F20B,3 Yes: use the cursor-key table
N $F20E Copy in the control routine (for keys 1, 3 and 4, its key table too) and start the game.
C $F20E,3 Copy the chosen key table to #R$BAA6
C $F216,3 and use the key-table routine with it
C $F219,3 Copy the chosen routine (25 bytes) to #R$BA8D
C $F221,1 Replace the title interrupt routine #R$F49E with the in-game one at $E986
C $F22C,3 Start the game
C $F22F,2 Is key 4 (SINCLAIR 1) pressed?
C $F233,3 Yes: use the Sinclair Interface 2 table
C $F238,2 Is key 5 (DEFINE KEYS) pressed?
C $F23A,3 None of keys 1-5: read them again
C $F23D,3 Define the keys; #R$F355 comes back to $F1D6
c $F240 Cycle the colours at the top of the title screen
D $F240 Called by #R$F49E on every interrupt. Every third call it moves the ink of a 16x5-character block at the top of the title screen (attribute rows 0-4, columns 7-22) one step through the bright colours on black paper, blue up to white and back down to blue. Each colour is held for three interrupts and the two end colours for six, because at each end the step that goes too far is undone. The routine keeps all its state in its own instructions: the countdown is the operand of LD A at $F243 (address $F244), reloaded with 3 when it reaches zero; the current attribute is the operand of LD A at $F252 (address $F253); the direction is the opcode at $F254, DEC A or INC A, rewritten when the ink goes past white ($48) or reaches black ($40). The fill uses the stack pointer as a write pointer: with SP set just past the end of a row, eight PUSH DE instructions write sixteen copies of the attribute downwards. SP is saved first into the operand of the LD SP instruction at $F2A5 (address $F2A6), so that one instruction puts it back; the interrupted code's SP is not known in advance, so it cannot be a constant. Interrupts must stay off meanwhile, or an interrupt's return address would be pushed into the attribute file; they are already off inside an interrupt, so the DI at $F242 changes nothing. The routine re-enables them itself before returning. The first instruction reads port $9F and throws the value away (A is reloaded at once).
@ $F240 label=CycleTitleColours
C $F240,2 Read port $9F (the value is not used)
C $F242,1 Interrupts off (they already are inside an interrupt)
C $F243,2 Count down to the next colour step (the operand at $F244 is the counter)
C $F246,3 Store the new count
C $F249,1 Return unless this is the third interrupt
C $F24A,2 Start the count again at 3
C $F24F,3 Point HL at the instruction that steps the colour
C $F252,2 Pick up the current attribute (the operand at $F253)
C $F254,1 Step the ink down (DEC A) or up (INC A)
C $F255,2 Has the ink gone past white?
C $F25A,2 If so, step downwards from now on
C $F25C,1 and go back to white, which is shown for a second step
C $F25D,2 Has the ink gone below blue?
C $F262,2 If so, step upwards from now on
C $F264,1 and go back to blue, which is shown for a second step
C $F265,3 Save the attribute for next time
C $F268,1 Put the attribute in both D and E
C $F26A,4 Save SP in the LD SP instruction at $F2A5
C $F26E,3 Fill row 0, columns 7-22: each PUSH writes two attribute bytes downwards from $5816
C $F279,3 Fill row 1, columns 7-22
C $F284,3 Fill row 2, columns 7-22
C $F28F,3 Fill row 3, columns 7-22
C $F29A,3 Fill row 4, columns 7-22
C $F2A5,3 Restore SP (the operand was written at $F26A)
C $F2A8,1 Re-enable interrupts
t $F2AA Message at F2AA
T $F2AA,8,8
b $F2B2 Data block at F2B2
B $F2B2,2,2
t $F2B4 Message at F2B4
T $F2B4,10,10
b $F2BE Data block at F2BE
B $F2BE,1,1
t $F2BF Message at F2BF
T $F2BF,10,10
b $F2C9 Data block at F2C9
B $F2C9,1,1
t $F2CA Message at F2CA
T $F2CA,8,8
b $F2D2 Data block at F2D2
B $F2D2,1,1
t $F2D3 Message at F2D3
T $F2D3,12,12
b $F2DF Data block at F2DF
B $F2DF,1,1
t $F2E0 Message at F2E0
T $F2E0,13,13
b $F2ED Data block at F2ED
B $F2ED,1,1
t $F2EE Message at F2EE
T $F2EE,14,14
b $F2FC Data block at F2FC
B $F2FC,6,6
t $F302 Message at F302
T $F302,13,13
b $F30F Data block at F30F
B $F30F,2,2
t $F311 Message at F311
T $F311,14,14
b $F31F Data block at F31F
B $F31F,6,6
t $F325 Message at F325
T $F325,11,11
b $F330 Data block at F330
B $F330,2,2
t $F332 Message at F332
T $F332,14,14
b $F340 Data block at F340
B $F340,6,6
t $F346 Message at F346
T $F346,14,14
b $F354 Data block at F354
B $F354,1,1
c $F355 Routine at F355
D $F355 Used by the routine at #R$F1C9.
t $F424 Message at F424
T $F424,7,7
b $F42B Data block at F42B
B $F42B,2,2
t $F42D Message at F42D
T $F42D,5,5
b $F432 Data block at F432
B $F432,1,1
t $F433 Message at F433
T $F433,4,4
b $F437 Data block at F437
B $F437,1,1
t $F438 Message at F438
T $F438,4,4
b $F43C Data block at F43C
B $F43C,4,4
t $F440 Message at F440
T $F440,4,4
b $F444 Data block at F444
B $F444,1,1
t $F445 Message at F445
T $F445,5,5
b $F44A Data block at F44A
B $F44A,1,1
t $F44B Message at F44B
T $F44B,5,5
b $F450 Data block at F450
B $F450,1,1
t $F451 Message at F451
T $F451,5,5
b $F456 Data block at F456
B $F456,1,1
t $F457 Message at F457
T $F457,6,6
b $F45D Data block at F45D
B $F45D,1,1
t $F45E Message at F45E
T $F45E,4,4
b $F462 Data block at F462
B $F462,1,1
t $F463 Message at F463
T $F463,14,14
b $F471 Data block at F471
B $F471,1,1
c $F472 Kempston joystick routine (template)
D $F472 #R$F1C9 copies all 25 bytes to #R$BA8D when KEMPSTON is chosen. The routine never runs here, but it runs as $BA8D-$BAA5 throughout the recording, called from $C553. It reads the joystick, whose bits 0-4 are set for right, left, down, up and fire, and stores each bit inverted in #R$BAB2-#R$BAB6. Each flag is 0 while its direction or fire is held, and 1 otherwise. It then stores key 1 in #R$BAB7 as the pause flag. Key 1 is the only key this method reads, and it cannot be redefined. The routine's only jump is relative and all of its addresses are absolute, so the copy runs unchanged: DJNZ $F47B here is DJNZ $BA96 at $BA9C. Play overwrites these bytes.
@ $F472 label=KempstonTemplate
C $F472,1 Read the Kempston joystick (port $1F)
C $F475,1 Invert the bits so that 0 means held
C $F476,3 Point at the first control flag (right)
C $F479,2 Five joystick bits: right, left, down, up, fire
C $F47B,2 Clear this flag and shift the next joystick bit into it
C $F480,1 Move to the next flag
C $F483,2 Read keys 1-5 (this is the IN at $BAA0 in play)
C $F487,2 Keep key 1: 0 while it is held
C $F489,1 Store it as the pause flag #R$BAB7
c $F48B Key-table control routine (template)
D $F48B #R$F1C9 copies this routine to #R$BA8D for KEYBOARD, CURSOR and SINCLAIR 1, and copies the chosen 12-byte key table to #R$BAA6. The routine handles six controls in this order: right, left, down, up, fire and pause. For each one it reads the half-row named in the table and stores the key's bit in #R$BAB2-#R$BAB7, which is 0 while the key is held and otherwise the bit mask itself. The routine is 19 bytes, but the menu copies 25, so the first six bytes of #R$F49E land after its RET at $BAA0-$BAA5. They are never run. HL starts one byte before the table ($BAA5) because the loop steps forward before each read. Like #R$F472, it uses only a relative jump, so the copy runs unchanged (DJNZ $F493 here is DJNZ $BA95 at $BA9D). The routine never runs here, and play overwrites these bytes.
@ $F48B label=KeyTableTemplate
C $F48B,3 One byte before the key table at #R$BAA6
C $F48E,3 First control flag (right)
C $F491,2 Six controls: right, left, down, up, fire, pause
C $F493,1 Pick up the key's half-row (this is $BA95 in play)
C $F495,2 Read that half-row
C $F497,1 Keep the key's bit: 0 while the key is held
C $F499,1 Store it in this control's flag
C $F49A,1 Move to the next flag
c $F49E Title screen interrupt routine
D $F49E The interrupt routine while the title and menu are on screen; the start-up code installs it at $F1B4, once the title is drawn. It saves the registers the colour cycler uses, calls #R$F240 to cycle the colours of the block at the top of the screen, and returns with interrupts enabled. The menu replaces it with #R$E986 at $F225 once a control method is chosen, and it is never installed again: during play the game overwrites this routine and #R$F240 with other data (12 of these 14 bytes and 99 of the 106 bytes at $F240-$F2A9 differ from the title in every in-play snapshot). In the recording it runs on the first 204 interrupts (frames 0-203), interrupting the menu's key loops at $C2E5-$C2E8 and $F1E7-$F238.
@ $F49E label=TitleInterrupt
C $F49E,1 Save AF, BC, DE and HL
C $F4A2,3 Cycle the title colours
C $F4A5,1 Restore the registers
C $F4A9,1 Re-enable interrupts
C $F4AA,2 and return to the menu
c $F4AC Fill a rectangle of attribute cells
D $F4AC Fills C rows of B attribute cells with A, starting at HL and moving down a row (32 cells) each time. It is only used by the start-up code at #R$F0C0, to colour patches of the title screen ($F130-$F19A).
R $F4AC A Attribute
R $F4AC B Width in cells
R $F4AC C Height in rows
R $F4AC HL Address of the top left attribute cell
@ $F4AC label=FillAttributes
c $F4BC Routine at F4BC
D $F4BC Used by the routines at #R$F1C9 and #R$F355.
b $F4C6 Data block at F4C6
B $F4C6,1108,8*138,4
t $F91A Message at F91A
T $F91A,3,3
b $F91D Data block at F91D
B $F91D,316,8*39,4
t $FA59 Message at FA59
T $FA59,4,4
b $FA5D Data block at FA5D
B $FA5D,231,8*28,7
t $FB44 Message at FB44
T $FB44,3,3
b $FB47 Data block at FB47
B $FB47,1209,8*151,1
