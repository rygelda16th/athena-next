@ $4000 start
@ $4000 org
b $4000 Display file
D $4000 The screen at the moment the snapshot was saved: the title's credits page.
B $4000,6144,32
b $5800 Attribute file
B $5800,768,32
b $5B00 Bit-reversal table
D $5B00 Entry n is n with its eight bits in reverse order (bit 7 swapped with bit 0, bit 6 with bit 1, and so on), so looking up a byte of a graphic here mirrors it left to right.
D $5B00 The start-up code at #R$F0C0 moves the table here from $F4C6. Its page is fixed: the two mirroring routines load $5B into the high byte of an address register and the byte to be mirrored into the low byte. #R$ECCB mirrors the player sprite buffer at #R$5C00, and #R$ECE9 mirrors the weapon graphics copied to $EE60.
D $5B00 The clear-screen routine at #R$EC9C sets SP to $5B00 and pushes downwards into the attribute file, so it never touches this table.
@ $5B00 label=BitReverseTable
B $5B00,256,16
b $5C00 Player sprite buffer
D $5C00 Workspace in which the player is put together each pass: 32 pixel lines of 2 bytes each (16 pixels wide, 32 high), plain bitmap with no mask, left pixel in bit 7.
D $5C00 #R$EDB4 first fills it with the background the player covers, copied from the play-area buffer at $F000; #R$EDD5 then lays the parts of the player over it (the body, and the armour pieces and other extras chosen from the variables at $BA24-$BA28), each part a graphic stored with its mask (a mask byte before each graphic byte), from $5DA0-$711F; #R$ECCB mirrors the whole buffer through #R$5B00 when the player faces the other way; and the code at $D13F, straight after #R$EBFA has put the play area on the screen, copies the buffer to the display file ending at the player's screen address (PlayerScreenAddr, $B94E): the copy points SP there and pushes each line leftwards. PlayerBufferPos ($BA35) says where in this buffer a part is drawn.
D $5C00 The bytes here at start-up are whatever the loader left; nothing initialises them.
@ $5C00 label=PlayerSpriteBuffer
B $5C00,64,2
b $5C40 Font
D $5C40 The game's 44 characters, 8 bytes each (8x8 pixels, top line first, left pixel in bit 7), for character codes $30-$5B: the digits 0-9, then ':' ($3A), ')' ($3B), '.' ($3C), '/' ($3D), '(' ($3E), '?' ($3F), what looks like a copyright sign ($40), the letters A-Z ($41-$5A) and '-' ($5B). The punctuation does not follow ASCII order.
D $5C40 The start-up code at #R$F0C0 moves the font here from $EE60, an area play later reuses for the weapon graphics. The printer at $C237 finds a character at $5C00 + 8 x (code - $28), i.e. $5C40 + 8 x (code - $30), and copies it to the screen a word at a time with SP pointing into the font. The routine at #R$C4BD reads characters through IX and draws each bit two pixels wide.
@ $5C40 label=Font
B $5C40,352,8
b $5DA0 Player graphics: walking
D $5DA0 Four frames of Athena walking, facing right, 16x32 pixels, 128 bytes each. Each pixel line is 4 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom; the drawing routines keep the background where the mask bit is 1 and then set the graphic's bits.
D $5DA0 The start-up code at #R$F0C0 moves these and the rest of the graphics up to $765F from $9FFA. A frame is not drawn in one go: #R$EDD5 lays its top 16 lines into the player buffer #R$5C00 from $CDAC, lines 16-23 from $CE34 (unless body armour replaces them, #R$6020) and lines 24-31 from $CE6C (unless the winged legs at #R$70A0 or the piece at #R$6F20 replace them). While climbing, #R$6D60 is used instead.
@ $5DA0 label=PlayerFrames
B $5DA0,512,4
b $5FA0 Player graphics: helmets
D $5FA0 Two 16x16 helmets, 64 bytes each, laid over the top of the player by #R$EDD5 from $CDD6: the first when ArmourC ($BA26) is 1, the second when it is 2. Each pixel line is 4 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom; the drawing routines keep the background where the mask bit is 1 and then set the graphic's bits. The climbing versions are at #R$6E60.
@ $5FA0 label=ArmourCGfx
B $5FA0,128,4
b $6020 Player graphics: body armour
D $6020 Eight 16x8 pieces, 32 bytes each: the middle of the body (lines 16-23) in the four walking frames with ArmourB ($BA25) at 1 ($6020-$609F), then at 2 ($60A0-$611F). #R$EDD5 draws the one for the current frame from $CE25 in place of the body's own lines. Each pixel line is 4 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom; the drawing routines keep the background where the mask bit is 1 and then set the graphic's bits. The climbing version is at #R$6EE0.
@ $6020 label=ArmourBGfx
B $6020,256,4
b $6120 Player graphics: armour A pieces
D $6120 Two 16x8 pieces, 32 bytes each, drawn by #R$EDD5 from $CDF6 into lines 16-23 of the player buffer before the body's middle lines go over them: the first when ArmourA ($BA24) is 1, the second when it is 2; not drawn while climbing. Each pixel line is 4 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom; the drawing routines keep the background where the mask bit is 1 and then set the graphic's bits.
@ $6120 label=ArmourAGfx
B $6120,64,4
b $6160 Weapon kind 1 graphics: club
D $6160 Three 24x16 frames, 96 bytes each, of a short club or stick (two level, one raised). Each pixel line is 6 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom.
D $6160 The weapon table at $BCCE points here for weapon kind 1. #R$EBB0 draws the frames straight from here facing right (from $D18B); when the weapon changes, $DCBC copies 288 bytes to $EE60, where #R$ECE9 mirrors them for facing left.
@ $6160 label=WeaponKind1Gfx
B $6160,288,6
b $6280 Weapon kind 2 graphics: sword
D $6280 Three 24x16 frames, 96 bytes each, of a sword drawn in outline (two level, one raised). Each pixel line is 6 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom.
D $6280 The weapon table at $BCCE points here for weapon kind 2. #R$EBB0 draws the frames straight from here facing right (from $D18B); when the weapon changes, $DCBC copies 288 bytes to $EE60, where #R$ECE9 mirrors them for facing left.
@ $6280 label=WeaponKind2Gfx
B $6280,288,6
b $63A0 Weapon kind 3 graphics: mace
D $63A0 Three 24x16 frames, 96 bytes each, of a round-headed mace or hammer (two level, one raised). Each pixel line is 6 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom.
D $63A0 The weapon table at $BCCE points here for weapon kind 3. #R$EBB0 draws the frames straight from here facing right (from $D18B); when the weapon changes, $DCBC copies 288 bytes to $EE60, where #R$ECE9 mirrors them for facing left.
@ $63A0 label=WeaponKind3Gfx
B $63A0,288,6
b $64C0 Weapon kind 4 graphics: axe
D $64C0 Three 24x16 frames, 96 bytes each, of a double-bladed axe (two level, one raised). Each pixel line is 6 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom.
D $64C0 The weapon table at $BCCE points here for weapon kind 4. #R$EBB0 draws the frames straight from here facing right (from $D18B); when the weapon changes, $DCBC copies 288 bytes to $EE60, where #R$ECE9 mirrors them for facing left.
@ $64C0 label=WeaponKind4Gfx
B $64C0,288,6
b $65E0 Weapon kind 5 graphics
D $65E0 Two 24x16 frames, 96 bytes each, of a curved segmented weapon like a flail or whip: the weapon at level 0. Each pixel line is 6 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom.
D $65E0 The weapon table at $BCCE points here for weapon kind 5. #R$EBB0 draws the frames straight from here facing right (from $D18B); when the weapon changes, $DCBC copies 288 bytes to $EE60, where #R$ECE9 mirrors them for facing left. This set is only 192 bytes, so that copy also takes in the first 96 bytes of kind 6 (#R$66A0), after its own two frames.
@ $65E0 label=WeaponKind5Gfx
B $65E0,192,6
b $66A0 Weapon kind 6 graphics
D $66A0 Two 24x24 frames, 144 bytes each, of a large feathered or flame-like shape. Each pixel line is 6 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom.
D $66A0 The weapon table at $BCCE points here for weapon kind 6. #R$EBB0 draws the frames straight from here facing right (from $D18B); when the weapon changes, $DCBC copies 288 bytes to $EE60, where #R$ECE9 mirrors them for facing left.
@ $66A0 label=WeaponKind6Gfx
B $66A0,288,6
b $67C0 Weapon kind 7 graphics: ball and chain
D $67C0 Two 24x24 frames, 144 bytes each, of a ball on a chain. Each pixel line is 6 bytes: a mask byte then a graphic byte for each 8 pixels from the left, bit 7 leftmost, lines top to bottom.
D $67C0 The weapon table at $BCCE points here for weapon kind 7. #R$EBB0 draws the frames straight from here facing right (from $D18B); when the weapon changes, $DCBC copies 288 bytes to $EE60, where #R$ECE9 mirrors them for facing left.
@ $67C0 label=WeaponKind7Gfx
B $67C0,288,6
b $68E0 Ball and chain pieces
D $68E0 Three masked graphics that the routine at $D923 draws in a row with #R$EB72: $68E0, a 16x8 end piece; $6900, a 16x8 chain link, drawn once per link; and $6920, a 16x16 ball. Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom. Facing left, the end and the ball come from the mirrored copies at #R$7220; the link is used both ways.
@ $68E0 label=ChainGfx
B $68E0,128,4
b $6960 Strike graphics, A=3-4
D $6960 $6960 is a 24x24 cluster of dithered streaks (6 bytes a line, three mask-graphic pairs), which #R$D991 draws twice side by side; $69F0 is a 16x8 wisp (4 bytes a line) drawn before them. The left-facing copies are at $7280 and $7310, reached by adding $0920 in #R$DA9E.
@ $6960 label=StrikeGfxB
B $6960,176,6*24,4
b $6A10 Strike graphics, A=5 or more
D $6A10 $6A10 is a 24x24 dithered beam (6 bytes a line, three mask-graphic pairs), drawn twice by #R$D991; $6AA0 is a 16x16 fireball-like blob (4 bytes a line) drawn after them. The left-facing copies are at $7330 and $73C0, reached by adding $0920 in #R$DA9E.
@ $6A10 label=StrikeGfxA
B $6A10,208,6*24,4
b $6AE0 Strike graphics, A=0-2
D $6AE0 $6AE0 is a 32x16 dithered shaft (8 bytes a line, four mask-graphic pairs), drawn twice end to end by #R$EB1C; $6B60 is its 16x16 pointed tip (4 bytes a line), drawn by #R$EB72. The left-facing copies are at $7400 and $7480, reached by adding $0920 in #R$DA9E.
@ $6AE0 label=StrikeGfxC
B $6AE0,192,8*16,4
b $6BA0 Explosion frames
D $6BA0 Four 16x16 masked frames, 64 bytes each: a dark ball, a ring of dots, four stars and scattered dots. Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom.
D $6BA0 They are drawn by #R$EB72 in three places: in order as the counter at $BA04 runs down ($D414-$D424); one picked at random with LD A,R over a damaged guardian ($D592-$D5BB, #R$D513); and $6BE0 or $6C60 twice side by side ($D3D1-$D3F1).
@ $6BA0 label=ExplosionFrames
B $6BA0,256,4
b $6CA0 Unused
D $6CA0 192 bytes for which no reader was seen in a trace of every fourth frame of the recording, and to which no instruction operand points. They do not decode cleanly as masked graphics of any of the game's widths.
@ $6CA0 label=UnusedGfx6CA0
B $6CA0,192,16
b $6D60 Player graphics: climbing
D $6D60 Two frames of Athena climbing, seen from behind, 16x32 pixels, 128 bytes each, used in place of #R$5DA0 while ClimbState ($B94A) is 1 or 4 ($CD66-$CD75 add $0FC0). Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom. Like the walking frames they go into the player buffer #R$5C00 in three parts: lines 0-15, 16-23 and 24-31.
@ $6D60 label=ClimbFrames
B $6D60,256,4
b $6E60 Player graphics: helmets from behind
D $6E60 The two helmets of #R$5FA0 seen from behind, 16x16, 64 bytes each, drawn over the climbing frames ($CDCC adds $0EC0 to the helmet address). Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom.
@ $6E60 label=ClimbArmourCGfx
B $6E60,128,4
b $6EE0 Player graphics: body armour from behind
D $6EE0 Two 16x8 pieces, 32 bytes each, for the two climbing frames: the armoured middle of the body, used for either level of ArmourB ($BA25) while climbing ($CE1C-$CE22). Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom.
@ $6EE0 label=ClimbArmourBGfx
B $6EE0,64,4
b $6F20 Player graphics: leg piece
D $6F20 A 16x8 masked piece that #R$EDD5 draws over the player's lines 24-31 from $CE5D when the operand of LD A,$00 at $CE4A is non-zero and the player is not climbing. Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom. In the recording it is drawn only in worlds 3 and 4.
@ $6F20 label=PlayerLegPieceGfx
B $6F20,32,4
b $6F40 Small 16x8 graphics
D $6F40 Three 16x8 masked graphics drawn to the screen by #R$EB72: $6F40, a small peak, one cell beside the player while Crouching ($BA07) is set ($D1C0-$D1D4); $6F60, a solid bar, and $6F80, the same bar dithered, drawn alternately from $D280-$D28E. Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom. The left-facing copies are at #R$74C0.
@ $6F40 label=SmallPiecesGfx
B $6F40,96,4
b $6FA0 Flame and bomb frames
D $6FA0 Four 16x16 masked frames, 64 bytes each: two round flame-topped shapes (the second darker), then two round bomb-like balls with sparks at the top. Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom. They are drawn through the object drawer that returns to $D20E, the same path that draws the enemies from the world bank, in every world.
@ $6FA0 label=FlameBombFrames
B $6FA0,256,4
b $70A0 Player graphics: winged legs
D $70A0 Four 16x8 masked frames, 32 bytes each, of small flapping wings at foot height, laid over the player's lines 24-31 by #R$EDD5 from $CE6C while FlyingItem6E ($BA28) is set; $D01E-$D022 plant $70A0 + 32 x the animation counter at $CE46. Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom.
@ $70A0 label=WingedLegsFrames
B $70A0,128,4
b $7120 Wing frames facing right
D $7120 Four 16x16 masked frames, 64 bytes each, of a wing flapping, drawn by #R$EB72 from $D1B3 while flying without item $6E; $D00A-$D016 plant $7120 + 64 x the animation counter at $D1AC. Each pixel line is 4 bytes: mask then graphic for the left 8 pixels, then for the right 8; bit 7 leftmost, lines top to bottom. The left-facing copies are at #R$7520.
@ $7120 label=WingFrames
B $7120,256,4
b $7220 Chain and strike graphics facing left
D $7220 Ready-made mirror images of the ball and chain pieces and strike graphics: $7220 mirrors #R$68E0 (16x8), and $7240-$74BF mirror $6920-$6B9F byte range for byte range ($7240 the ball, $7280 and $7310 the #R$6960 set, $7330 and $73C0 the #R$6A10 set, $7400 and $7480 the #R$6AE0 set). Each line has its mask-graphic pairs in reverse order with every byte bit-reversed. The routines reach them by loading the address directly ($D944, $D97B) or by adding $0920 (#R$DA9E).
@ $7220 label=LeftStrikeGfx
B $7220,672,4*24,6*24,4*8,6*24,4*16,8*16,4
b $74C0 Small 16x8 graphics facing left
D $74C0 Mirror images of the three graphics at #R$6F40: the peak at $74C0 ($D1CC), and the two bars at $74E0 and $7500 ($D27D adds $0580).
@ $74C0 label=LeftSmallPiecesGfx
B $74C0,96,4
b $7520 Wing frames facing left
D $7520 Mirror images of the four wing frames at #R$7120, chosen at $D012 when the player faces left.
@ $7520 label=LeftWingFrames
B $7520,256,4
b $7620 Heart
D $7620 A 16x16 masked dithered heart (4 bytes a line, mask then graphic for each half), drawn by #R$EB72 from $D257 after $D24C clears a byte of the enemy position map at $EF80. It is the last of the graphics moved here by #R$F0C0; the world area starts at #R$7660.
@ $7620 label=HeartGfx
B $7620,64,4
b $7660 World area
D $7660 The loader at #R$B8C3 copies the whole of the current world's bank here (16,384 bytes, #R$7660 to $B65F). In the snapshot, taken at the title screen before any world was loaded, it still holds what the tape loader left behind.
@ $7660 label=WorldArea
B $7660,16384,16 A whole world bank (3, 4, 6 or 7) copied by #R$B8C3. It starts with two 23-byte world headers, at $7660 for the first world and $7677 for the second (bank 7's second header is never used to set up a world: only its bytes 7-10, the path and graphics record of world 7's second guardian, are read in play, at $C57D; its zero map length at $767A is also read by the map transform #R$BCE6 when a game ends in world 7). The data they point to all lies inside the area, except world 4's list (from its header) and the world-7 text at $B5D3 (addressed directly by $D85C), both of which run on into #R$B660.
b $B660 The part of the world data that did not fit in its bank
D $B660 85 bytes that #R$B8C3 copies from bank 1 for the current world bank (see #R$B8BB), straight after the 16,384-byte world area. The world data runs on into them.
D $B660 In worlds 3 and 4 (bank 4) they are the end of world 4's list of enemy starts, whose 28 three-byte entries start at $B65E. So $B660 is byte 2 of the first entry, $B661+3n (n = 0-26) are byte 0, $B662+3n byte 1 and $B663+3n byte 2 of the rest; the 28th entry ends at $B6B1, and $B6B2-$B6B4 lie beyond the list (world 3 uses its own list at $B610 and never reads this area). By offset: byte 0 is the map column (MapColumn, $B95C) at which the entry's enemy is started by #R$D5D1 ($D5DC CP (HL)); byte 1 bit 7 is set at $C654 when the entry matches and a free slot is found - before the upper/lower test at $C65A-$C664, so an entry for the other part of the map is marked too without an enemy being started - and its address is saved in slot bytes 10-11 ($C656, $C694-$C69A); the bit is reset for every entry by #R$C169 ($C171, called from $BE5C at every life start and from $DEB3, which runs at world set-up and at every move between the upper and lower parts through #R$DD66) and for one entry by #R$D909 ($D91C) when that enemy's slot is freed; $C653 also loads the whole byte into D before the enemy is set up; byte 2 bit 6 must equal $B957 (upper or lower screen, $C65A-$C664), bit 7 picks the starting column (2, or $1A adjusted by 4 minus the template's width to $1E minus the width, $C66B-$C68C) and bits 0-4 are the enemy template number, times 5 into the template table whose address is at $768E ($C675-$C682).
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
B $B95E,90,16*5,10 Ten 9-byte records, one for each item box a weapon blow has opened in the last 50 counts (the record stays in use after its item is collected) (#R$D603, called from #R$D65E). Byte 0 is non-zero while the record is in use: it is set to 50 when the record is made and counts down at $CE8B on each pass where the scroll step count is 4 or 8 (#R$DD93), so not on the passes between while the view is scrolling; when it reaches 0 the cell is given the box code less $19, a background code, and the item is gone. Bytes 1-2 are the address of the map cell; byte 3 is the code of the box that was opened ($60-$78, or $5F when an emptied $78 box is struck again, see #R$D65E; the restore at $CE95 writes back byte 3 minus $19, which is in $47-$5F and drawn as background, the same range an item collected by #R$DBAB is left in); bytes 4-5 are $B95A when the record was made (compared with the current value at $CEA7 to see whether the cell is on screen); bytes 6, 7 and 8 are copies of the operand $D746, register D and the operand $D744 and are used to redraw the cell ($CE9E-$CEA4). Records are made at $D619-$D645, which takes the first free record by stepping 9 bytes from $B955 with no count. #R$C190 puts every pending cell back (byte 3 minus C) and $DEBE then zero-fills $B95E-$BA14.
@ $B9B8 label=UnusedB9B8
B $B9B8,10,8,2 Ten bytes between the last map-change record and the enemy slots that nothing reads or writes except the clears at $BD04 and $BD85 and the zero-fill at $DEBE. The unbounded free-record search at $D61C could only reach them if all ten $B95E records were in use.
@ $B9C2 label=EnemySlots
B $B9C2,65,13 Five 13-byte enemy slots. Byte 0 non-zero = in use; 2 = column; 3 = row; 4-8 = copy of the enemy's five-byte template (8 = type); 9 is a state and direction byte (bit 7 set while it moves right: #R$DD41 sets it for an enemy started on the left and the movers flip it when it turns round ($CC07, $CC33); while it is set the enemy is drawn from the second half of the frame area, +the operand at $CC7E; bits 0-2 the frame number, 1-2, or 1-4 for type 7; bits 5-7 are changed as it moves); 10-11 are the address of the started flag (byte 1, or byte 2 in world 7) of the list entry that started it, written at $C694-$C69A and used by #R$D909 to clear that flag when the slot is freed.
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
W $BA17,2,2 Address of the map column the play area is built around (eight cells a column): the buffer at $F000 holds the 15 columns from eight bytes before it (#R$DE96), 13 of them on screen, and moves a column at a time with the scroll (#R$DDC4); 112 cells from it are the ones checked for enemy starts; #R$C2D9 reads map cells relative to it. World set-up gives it its first value at $BE1B (header word 1 plus $20). Scrolling moves it by 8 (one column), in the direction the player faces, each time eight scroll steps are complete (#R$DDC4, via $D4A4); turning round while $D4A2 is 8 also moves it 8 in the new direction ($CA5E-$CA67 back, $CB02-$CB09 on); changing between the upper and lower screens moves it by $0680 through #R$DD66. A cell holding the world's type 4 code (header byte 11, the operand at $C6AC) is where a type 4 enemy may be started at random.
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
B $BAB8,64,4
b $BAF8 Data block at BAF8
B $BAF8,16,2
b $BB08 Data block at BB08
B $BB08,16,2
t $BB18 Messages
D $BB18 Messages for the panel, the world start screen, CONTINUE? and the hi-score entry, one after another, each ending with '#'. They are in the game's font, where '<' is drawn as a full stop, '=' as a slash, '>' and ';' as brackets and '[' as a hyphen. #R$C292 prints them in the small font and understands the control codes $FF (new row) and $FC n (skip n columns); #R$C4ED prints them twice the size.
D $BB18 The six tape messages from $BB69 to $BBA8 are never used: nothing in the 128K game's memory refers to them.
@ $BB18 label=Messages
T $BB18,9,9
N $BB21 The rest of the panel text, printed from row 17, column 3 by the new-game code ($BD68): SCORE and TIME on row 17, the starting score and clock on row 18, and LIVES on row 23.
T $BB21,39,5:n2:4:n1:6:n2:4:n7:8
N $BB48 The copyright line on the bottom row of the title and the hi-score table (#R$C28C).
T $BB48,33,33
N $BB69 Six tape-loading messages (and a blank one) that nothing in the game uses.
T $BB69,64,19,10,11,14,2,8
N $BBA9 PRESS ANY KEY and TO PLAY, printed large on the world start screen (#R$C4ED from $BDC9 and $BDD0).
T $BBA9,22,14,8
N $BBBF CONTINUE? at row 4, column 12 ($CCCE), then the countdown digit, which $CCD3 writes into the first byte of its one-character message before printing it large ($CCDD).
T $BBBF,12,10,2
N $BBCB CONGRATULATIONS, above the hi-score table when a score gets in ($BFAE).
T $BBCB,16,16
b $BBDB Message at BBDB
T $BBDB,10,10
W $BBE5,2,2
T $BBE7,10,10
W $BBF1,2,2
T $BBF3,10,10
W $BBFD,2,2
T $BBFF,10,10
W $BC09,2,2
T $BC0B,10,10
W $BC15,2,2
T $BC17,10,10
W $BC21,2,2
t $BC23 More messages
D $BC23 The rest of the messages, after the hi-score table: the table's heading, the four ways play can stop, and the two words that open the world intro card. Same form as #R$BB18.
@ $BC23 label=MoreMessages
T $BC23,43,24:n4:15
N $BC4E OUT OF TIME ($DB13), OUT OF LIFE ($CCF2), LIFE LOST ($CD00) and ABORT PRESSED ($D062), printed in the blanked play area by #R$C3A5.
T $BC4E,48,12*2,10,14
N $BC7E WORLD OF for worlds 1-6 and THE LAST for world 7, printed large at the top of the world intro card ($BE84).
T $BC7E,18,9
b $BC90 Data block at BC90
B $BC90,44,8*5,4
t $BCBC Message at BCBC
T $BCBC,3,3
b $BCBF Data block at BCBF
B $BCBF,39,8*4,7
c $BCE6 Start a new game after the hi-score table
D $BCE6 Reached only by the JP at $C012, after a game has ended and the hi-score table (#R$BF6A) has been shown. There is no way back to the control menu: the next game starts at $BD01 with the control method chosen at the title still in force.
D $BCE6 First it processes the maps of the world that was being played. #R$C190, called with C=0, walks the ten 9-byte records at $B95E and, for each one whose first byte is not zero, writes the record's fourth byte to the address held in its second and third bytes. Then #R$C0F1 is applied to every byte of both maps in the bank's world data: the first map starts at the address in the header word at $7661 and is ($7663) bytes long, and the second follows it directly, ($767A) bytes long. #R$C0F1 changes certain byte values into others (for example $C6 is added to $00-$02 and $07-$09, and $CD to $03-$06).
D $BCE6 Together the two steps undo most of what play does to a map (#R$C0F1 describes each change it reverses, and what it misses): the boxes still pending get their codes back, and broken blocks, emptied boxes, struck $C6 blocks and stepped-on $79 and $7A cells get their original codes. None of this has any lasting effect, because $BD85 then reloads world 1 over the whole world area (#R$B8C3), and every later world is copied fresh from its bank too; it looks like a survivor of a version that kept its maps in memory from game to game.
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
D $BDC0 Then the world's parameters are chosen. Each bank holds two worlds; bit 0 of the count of worlds completed so far ($BA33) picks the first header at $7660 (worlds 1, 3, 5, 7) or the second at $7677 (worlds 2, 4, 6), and with it a pair of values for $CECA and $DE09, the header address for $BE88 and a map pointer for $BA17. One 32-byte block, $0420 bytes past the address in $7665 for the first world in the bank or $0440 for the second (the pictures of block codes $81 and $82), is copied twice, to $0320 and to $0340 bytes past that address (the entries for block codes $79 and $7A, which are blank in every bank). Block $81 is the same picture as the first world's background block $93 in every bank, and $82 is the second world's background block, so map cells holding $79 or $7A look like plain background; when the main loop finds one in the player's lower cell ($C6FC-$C70E) at the start of a scroll column ($D4A2 = 8, $C713-$C718) it rewrites the cell as $0C or $0D, codes also drawn as background, and sets $BA06 to $7B ($C71A-$C71D); #R$DE96 runs (it makes 15 passes through $DDEE, eight map bytes each, starting eight bytes before the map pointer and writing to the buffer from $F001; clears bit 7 of the flag bytes with #R$C169, zeroes $D25B, applies the ten records at $B95E with C=$19 through #R$C190, reprints HI-SCORE and clears $B95E-$BA14), and the world count at $BA33 is increased. At a world change the #R$C169 calls here and in BeginLife come before $BE9F and $BEA5 install the new world's list address and count, so they walk the previous world's list positions over the newly loaded data; only after a lost life is the list current.
D $BDC0 BeginLife ($BE47) is where every life starts: at a new world by running on from above, and after a lost life by the JP at $CD33. It resets the stack pointer to $B8B7, which also discards the return address left on the stack by the CALL $D77A that led to a world change. It blanks the play area, clears the five enemy slots and the four bytes after them ($B9C2-$BA06), zeroes $BA35, $D215 and $BA03, clears bit 7 of the flag bytes in the list of three-byte entries (#R$C169), waits for an interrupt and redraws the ten entries of $BA19 on rows 22-23 ($C33B), and redraws the bar in columns 0-1 at its current length ($BF4B). It prints WORLD OF, or THE LAST in world 7, and plants the list search the main loop calls at $C63E (#R$D5D1, or #R$D5E3 for world 7's four-byte list) as the operand at $C63F. It then copies the chosen header's fields into the instruction operands and variables that use them: byte 0 (the lowest solid block code) to $DB91, byte 11 (the map code type 4 enemies start on) to $C6AC, byte 12 (the guardian's map column) to $C58F, bytes 13-15 (the list address and count) to $D5D2 and $D5DB, bytes 16-17 (the offset of the second-half enemy frames) to $CC7E, and byte 18 (the end column, bit 0 choosing the upper or lower part) to $D046 and, as a JP NZ or JP Z opcode, to $D03F. It prints the world's name (bytes 21-22) at row 8, column byte 20, and colours the play area with byte 19. Then it plays the world's start tune, number 3 plus the world count (tunes 4-10 for worlds 1-7), and jumps to the main loop at #R$C553.
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
C $BE0B,3 Plant the background block code, $93 or $82 (#R$CEC9)
C $BE0E,1 and the block drawn over item codes, $C7 or $C8 (#R$DDFD)
C $BE12,4 Keep the chosen header's address for BeginLife ($BE87)
C $BE16,3 The first map window is 32 bytes (four columns) into the map whose address is header bytes 1-2
C $BE1F,4 The cell table's address (bytes 5-6 of the first header, for either world) goes to the operand at $DE2F
C $BE27,1 Copy the 32-byte picture IY bytes into the cell table (block $81 in the first world, $82 in the second, the world's background picture) over the blank entries for block codes $79 (table+$0320) and $7A (table+$0340), so those cells are drawn like the background block
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
C $BE8A,1 Byte 0, the lowest solid block code, to the operand at $DB91
C $BE8E,3 Byte 11, the map code type 4 enemies start on, to the operand at $C6AC
C $BE96,1 Byte 12, the guardian's map column, to the operand at $C58F
C $BE9B,1 Bytes 13-14, the start list's address, to WorldListAddr
C $BEA3,1 Byte 15, the number of list entries, to WorldListCount
C $BEA8,1 Bytes 16-17, the distance to the right-facing enemy frames, to the operand at $CC7E
C $BEB0,1 Byte 18, the end-of-map column, with bit 0 set, to the operand at $D046
C $BEB8,2 Bit 0 of it picks the test at $D03F: JP NZ ($C2) for a column in the upper part, JP Z ($CA) for the lower
C $BEC3,1 Print the world's name and colour the play area
C $BEC6,1 Print the name (address in bytes 21-22) in large letters at row 8, column byte 20
C $BED2,1 Colour the play area with byte 19
C $BED6,1 Zero $D215 and $BA03
C $BEDF,3 Play the world's start tune (4-10)
C $BEE7,3 Enter the main loop
c $BEEA Draw units of a panel bar
D $BEEA Draws B units of the bar graphic #R$BAF8 one below another, starting at row D, column E, in the attribute held at $ED85. B may be 0, which draws nothing. The energy bar redraw #R$BF15 uses it twice (full units, then empty ones), and NewGame uses it to draw the 18 cells of the right-hand column at rows 3-20 ($BD4D-$BD52) before the POW piece and the weapon and armour colours go over them.
R $BEEA B Number of units
R $BEEA D Row of the first unit
R $BEEA E Column
R $BEEA O:D Row after the last unit
@ $BEEA label=DrawBarUnits
c $BEFE Lose a unit of energy
D $BEFE On every second call, wears the armour (#R$C178, while the count at $BA34 is non-zero), moves one unit from the energy ($BF1B) to the lost count ($BF28) and redraws the energy bar. Called on enemy contact (#R$D38B), by the time drain every ten clock seconds while $BA2B is set ($DB03) and at $DA42.
D $BEFE DrawEnergyBar at $BF15 is the redraw on its own. The bar is in columns 0-1 of the panel from row 4 down: first one unit (#R$BAF8) for each unit of energy in the energy colour (the operand at $BF16, $42 bright red, or $43 bright magenta while energy drains over time), then one for each lost unit in bright white ($47), then the end cap #R$BB08 in bright yellow ($46). The bar is only ever redrawn over itself or made longer, so nothing needs erasing below it.
R $BEFE O:A Corrupted
R $BEFE O:BC Corrupted
R $BEFE O:DE Corrupted
R $BEFE O:HL Corrupted
@ $BEFE label=LoseEnergy
C $BEFE,3 Act on every second call only
C $BF05,3 Wear the armour while its count is running
C $BF0D,3 One unit from the energy to the lost count
N $BF15 This entry point is used by the routines at #R$BF39, #R$BF42, #R$C553, #R$D38B and #R$DDAE.
@ $BF15 label=DrawEnergyBar
C $BF15,2 Full units in the energy colour (operand $BF16)
C $BF1A,2 Energy units left: the filled part of the energy bar. #R$BEFE moves one unit from here to the lost count at $BF28 and #R$BF5E moves one back; a life is lost at 0 ($CC9C).
C $BF1C,3 from row 4, column 0
C $BF22,2 Then the lost units in bright white, carrying on down
C $BF27,2 Energy units lost: the empty part of the energy bar. #R$BEFE adds one, #R$BF5E takes one away, #R$BF39 adds an empty unit while the total is below 19, and $CD25-$CD2A refill the bar.
C $BF2C,3 Then the end cap in bright yellow ($47 - 1)
c $BF39 Add an empty unit to the energy bar
D $BF39 Adds one to the lost count at $BF28, making the bar one unit longer with an empty unit, and redraws it; nothing happens once energy plus lost units reach 19, the bar's longest (rows 4-22, with the cap on row 23). Used when the player's cell in the enemy position map holds $FF (#R$D38B) and by the item handler at $DC4E.
@ $BF39 label=LengthenEnergyBar
c $BF42 Reset the energy bar
D $BF42 Sets the energy to 11 units with none lost, then (from ResetEnergyColour at $BF4B) sets the bar colour to bright red ($42) and redraws the bar (#R$BF15). NewGame uses the whole routine ($BD46); the start of each life ($BE62) and the item handler #R$DC7D ($DC86) use $BF4B to put the colour back without touching the energy.
@ $BF42 label=ResetEnergyBar
N $BF4B This entry point is used by the routines at #R$BDC0 and #R$DC7D.
@ $BF4B label=ResetEnergyColour
N $BF4D This entry point is used by the routine at #R$BF52.
c $BF52 Colour the energy bar for draining
D $BF52 Sets the energy bar colour to bright magenta ($43) and redraws the bar. The item $70 handler jumps here ($DC74) when it starts the energy drain over time.
@ $BF52 label=DrainEnergyColour
c $BF56 Get the energy bar's length
D $BF56 Returns the number of units in the energy bar, full and empty together, and points HL at the lost count. Used by #R$BF39 and by the refill after a life is lost ($CD25-$CD2D), which zeroes the lost count and makes all of the bar full.
R $BF56 O:A Energy units plus lost units
R $BF56 O:HL $BF28
@ $BF56 label=EnergyTotal
c $BF5E Regain a unit of energy
D $BF5E Moves one unit from the lost count ($BF28) back to the energy ($BF1B), if any are lost. It does not redraw: #R$D38B calls it three times and then redraws with #R$BF15.
R $BF5E O:A Lost count less one ($FF if none were lost)
@ $BF5E label=RegainEnergy
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
c $C07C Colour the play area
D $C07C Fills the attributes of the play area, character rows 0-15 and columns 3-28, with the attribute in A, through the attribute-filling end of #R$ED4E (entry $ED86) with its row width set to 26. The play area has no attributes of its own: #R$EBFA copies only pixels, so the whole area is this one colour.
D $C07C World set-up uses it for the world's colour, byte 19 of the world header ($BED3, after the world name is printed); it also blanks the area to black with A=0 (#R$C511, $BE4E), colours the PRESS ANY KEY card bright yellow ($BDD5), and is called in the 256-frame loop at the end of a world ($D050) and after the last guardian ($D84B). It returns with interrupts enabled.
R $C07C A Attribute
@ $C07C label=ColourPlayArea
C $C07C,3 26 attribute bytes a row
C $C081,3 from row 0, column 3
C $C084,2 for 16 rows
C $C086,3 Fill them with A
b $C089 Colours of the weapon strength and armour bars
D $C089 Eight attributes, one per cell of a bar in the right-hand column, in two-cell steps of four colours. #R$C091 colours the STR bar from the top down and #R$C0BC the HIT bar from the bottom up with the first entries of this table, as many as the weapon level plus 2 or the armour count.
@ $C089 label=PowerBarColours
B $C089,8,8
c $C091 Colour the weapon strength and armour bars
D $C091 Colours the two bars of the right-hand column (columns 30-31), each eight cells long and drawn in the bar units NewGame put there. The STR bar, rows 3-10 below the STR label, fills downwards: weapon level ($BA2D) plus 2 cells take their colours from the table at #R$C089 and the rest are bright white ($47). The HIT bar, rows 20 up to 13 above the HIT label, fills upwards the same way with one cell for each armour count: the three counters $BA24-$BA26 added up (#R$DDA2) plus $BA26 again.
D $C091 ColourArmourBar at $C0BC does only the HIT bar; the armour item handlers reach it through $DCD4. The whole routine runs on every pass of the main loop ($D10F) and at NewGame ($BD65).
R $C091 O:A Corrupted
R $C091 O:BC Corrupted
R $C091 O:DE Corrupted
R $C091 O:HL Corrupted
R $C091 O:IX Corrupted
@ $C091 label=ColourPowerBars
C $C091,3 STR cells to colour: weapon level + 2
C $C098,3 From row 3, column 30, downwards
C $C0A2,3 Two cells a row from the colour table
C $C0AD,2 The rest of the eight rows in bright white
N $C0BC This entry point is used by the routine at #R$DCCA.
@ $C0BC label=ColourArmourBar
C $C0BC,3 HIT cells to colour: the three armour counts plus the third again
C $C0C3,3 From row 20, column 30, upwards
C $C0DF,2 The rest of the eight rows in bright white
c $C0F1 Undo play's change to one map cell
D $C0F1 Turns a map cell code that play leaves behind back into the code the map started with. #R$BCE6 runs it over every byte of both maps in the bank after a game, and between them the two routines undo most of what play does to a map: a broken block's remains become the whole block again ($00-$02 and $07-$09 have $C6 added, $03-$06 have $CD added, and the half-broken $C9-$CB, left by a first blow to $D0-$D2, have 7 added; the test also takes $C8, which play never makes), a $C6 block that was struck into the climbable $7F is put back, a $79 or $7A cell that was stepped on ($0C-$0F, the stepped and struck states) is put back, and an item box that was opened and emptied ($47-$5E, after #R$C190 with C=0 has written back the boxes still pending) has $19 added to become the box again. Anything else is left alone.
D $C0F1 The work is wasted in this version. #R$BCE6 goes on into NewGame and NewWorld, which reload world 1's bank over the whole world area (#R$B8C3), and every world is freshly copied from its bank when it starts. The routine looks like a survivor of a version that kept one copy of each map in memory and had to repair it for the next game. It is also not an exact inverse: $CC, the half-broken state of a $D3 block, is not handled; nor is $5F, an emptied $78 box (the range tested is $47-$5E); world 7's blocks $D5-$E2 lose 7 at a blow and come back as lower codes; $00, the filler in the unused columns at the start of each lower part, would become $C6; and it turns $D4, which world 7 uses once as a real block, into $A0.
R $C0F1 HL Address of the map cell
@ $C0F1 label=RepairMapCell
C $C0F1,1 $00-$09, the remains of a block broken at one blow?
C $C0F6,2 $00-$02 become $C6-$C8 and $07-$09 become $CD-$CF, the one-blow blocks
C $C100,2 $03-$06 become the two-blow blocks $D0-$D3
C $C105,2 $0C/$0D, a $79/$7A cell stepped on: put $79/$7A back
C $C111,2 $0E/$0F, a stepped cell that was struck: put $79/$7A back
C $C11D,2 $D4 becomes $A0
C $C124,2 $7F, a struck $C6 block: put $C6 back
C $C12B,2 $C8-$CB, half-broken two-blow blocks: add 7
C $C137,2 $47-$5E, an emptied item box: add $19 to give the box code back
c $C141 Routine at C141
D $C141 Used by the routines at #R$D65E and #R$DC01.
N $C14C This entry point is used by the routine at #R$DCAC.
c $C169 Clear the started marks in the enemy start list
D $C169 Clears bit 7 of the second byte of every entry in the list whose address and count are in the operands at $D5D2 and $D5DB, so that every enemy in the list can start again. Called from BeginLife ($BE5C) at every life start, and from $DEB3 in #R$DE96, which runs at world set-up ($BE42) and at every move between the upper and lower parts of the map (#R$DD66).
D $C169 Two faults. At a world change both calls come before $BE9F and $BEA5 install the new world's list, so the walk uses the previous world's list positions over the data just loaded. After world 2 that clears bit 7 of five bytes of cell graphics 90 and 92 in bank 4 ($B261, $B270, $B297, $B29A, $B29D), which world 3 then draws; after world 6 it clears bit 7 of nine bytes of world 7's list, moving six enemies 64 map columns (128 $B95A units) earlier and three to the left edge. The other changes (worlds 2, 4, 5, 6 and a new game) hit only bytes with bit 7 already clear.
D $C169 And it always steps three bytes, but world 7's entries are four, so in world 7 it would clear bit 7 of position and side bytes and miss three of every four started flags. In the recording world 7 never lost a life or changed part, so this never ran there.
@ $C169 label=ClearListMarks
C $C169,3 HL=address of the world's list of enemy starts (the operand at $D5D2)
C $C16C,3 B=number of entries (the operand at $D5DB)
C $C170,1 Clear the started flag, bit 7 of the entry's second byte
C $C173,1 On to the next 3-byte entry
c $C178 Routine at C178
D $C178 Used by the routine at #R$BEFE.
c $C190 Write back the map cells of every pending map change
D $C190 Walks the ten 9-byte records of MapChanges ($B95E) and, for each one in use (byte 0 not zero), writes byte 3 minus C to the map address in bytes 1-2. The records are made by #R$D65E when a weapon breaks open an item box: byte 3 is the box's code, so the value written is either the box itself (C=0) or the box's code less $19 (C=$19), which lies in $47-$5F and is drawn as plain background. Nothing is redrawn and the records are left as they are; both callers go on to discard them or the whole map.
D $C190 #R$DE96 calls it with C=$19 at world set-up and, through $DE99, whenever the player moves between the upper and lower parts of the map, just before clearing $B95E-$BA14: an item uncovered but not yet timed out (the main loop does the same at $CE95 when a record times out) vanishes when the view is rebuilt, whether or not it was collected. #R$BCE6 calls it with C=0 after a game, putting the boxes back ahead of the map repair by #R$C0F1.
R $C190 C Amount to subtract from each record's stored code
@ $C190 label=PutBackMapChanges
C $C190,3 Ten records, the first at $B95E
C $C195,3 Next record
C $C19A,1 Skip a record not in use
C $C19E,1 DE=the map cell's address
C $C1A3,1 Write back the stored box code less C
c $C1AA Routine at C1AA
D $C1AA Used by the routines at #R$BCE6 and #R$C553.
c $C1B2 Routine at C1B2
D $C1B2 Used by the routines at #R$BCE6 and #R$C553.
N $C1B8 This entry point is used by the routine at #R$C1AA.
c $C1BF Save the panel's label pieces from the screen
D $C1BF Copies the four label pieces of the panel from the screen to $F000-$F0BF: LIFE (columns 0-1, rows 0-3), STR (columns 30-31, rows 0-2), POW (columns 30-31, rows 11-12) and HIT (columns 30-31, rows 21-23). NewGame draws the panel from that copy ($BD22-$BD5E), but play uses $F000 as the play area buffer and overwrites it, so the pieces have to be saved again before every new game: the hi-score table does it on entry (#R$BF6A) and the ending does it before paging in its pictures (#R$B908). The first game uses the copy the tape loaded there.
R $C1BF O:DE $F0C0
@ $C1BF label=SavePanelPieces
c $C1E2 Reset the lives to five and print them
D $C1E2 Sets the lives digit (the operand at $C1EE) to '5' and continues into PrintLives at $C1E7, which prints that digit at row 23, column 29, just after the word LIVES on the panel. Called when a new game starts ($BD1A) and when a CONTINUE is taken ($CCFB).
D $C1E2 PrintLives is also called on its own after a life is lost ($CCAF) and when an extra life is collected ($DC3D). It prints nothing when the digit is ':' or more, so a tenth life is counted but the panel keeps showing the last digit printed.
R $C1E2 O:A Corrupted
R $C1E2 O:B Corrupted
R $C1E2 O:DE Corrupted
@ $C1E2 label=ResetLives
C $C1E2,2 Five lives, as the digit '5'
N $C1E7 This entry point is used by the routines at #R$C553 and #R$DC39.
@ $C1E7 label=PrintLives
C $C1E7,3 Text position row 23, column 29
C $C1ED,2 Lives left, as an ASCII digit ('5' = 53 at the start). It is the operand of LD A,$00 at $C1ED in the lives printer $C1E7, which prints it only while it is below ':' ($3A), so a count above 9 is not shown. This is the address the POKE list calls lives, and it really is the lives count.
C $C1EF,2 Only a single digit can be shown
c $C1F4 Add to the score and print it
D $C1F4 Adds C (the entry at $C1F4) or BC (the entry AddScoreBC at $C1F6) to the score word at $BA15 and prints the new score as five digits at row 18, column 3 of the panel (#R$C203).
D $C1F4 The panel shows six digits: the sixth is the last 0 of the panel text at $BB21, printed once by the new-game code ($BD6E) and never reprinted, so the score shown is ten times the value at $BA15. Killing an enemy adds points through $C1F4 ($D8CE), and so does the random bonus of item $40 (#R$DC89, which jumps here); $D82B and $DC43 add larger amounts through $C1F6.
R $C1F4 C Points to add (entry $C1F4)
R $C1F4 BC Points to add (entry $C1F6)
R $C1F4 O:HL Last digit's remainder (0)
@ $C1F4 label=AddScore
C $C1F4,2 Points in C only
N $C1F6 This entry point is used by the routines at #R$D77A and #R$DC39.
@ $C1F6 label=AddScoreBC
C $C1F6,3 Text position row 18, column 3
C $C1FC,3 Add the points to the score, then print it
c $C203 Print a number as five digits
D $C203 Prints HL in decimal as five digits with leading zeros, at the text position in $C23F-$C240, by dividing by 10,000, 1,000, 100, 10 and 1 in turn.
D $C203 PrintDigitOf at $C21E is a 16-bit division by shifting: it divides HL by DE, prints the quotient as a digit (which must be below 10) and leaves the remainder in HL for the next call. The entry PrintDigit at $C235 prints the value 0-9 in A; the clock ($DB25-$DB35) uses it for the minutes and the two seconds digits.
R $C203 HL Number to print (entry $C203)
R $C203 DE Divisor (entry $C21E)
R $C203 A Digit value 0-9 (entry $C235)
R $C203 O:HL Remainder (entry $C21E)
@ $C203 label=PrintNumber
C $C203,3 Ten thousands
C $C209,3 Thousands
C $C20F,3 Hundreds
C $C215,3 Tens
C $C21B,3 Units, falling into the divide-and-print step
@ $C21E label=PrintDigitOf
C $C21E,1 Dividend in A (high) and C (low); remainder builds up in HL
C $C225,2 Shift the next dividend bit into HL and try subtracting the divisor
C $C22E,1 Too small: add the divisor back
C $C22F,1 Carry now 1 if the subtraction went
C $C232,2 Shift in the last quotient bit: A = quotient
N $C235 This entry point is used by the routine at #R$DAF2.
@ $C235 label=PrintDigit
C $C235,2 Make it an ASCII digit and print it
c $C237 Print a character
D $C237 Draws one 8x8 character from the font (#R$5C40) at the text position held in the operand at $C23F (column) and $C240 (row), sets that cell's attribute to the text colour held in the operand at $C280, and moves the text position one column right. Every piece of small text in the game comes through here: the message printer #R$C292, the number printer #R$C203, the lives digit (#R$C1E7), the hi-score table and name entry, and DEFINE KEYS.
D $C237 The display address is worked out the way the ROM's CL-ADDR does it: the row's third ($40, $48 or $50) in the high byte, and the row within the third times 32 plus the column in the low byte; INC H then steps from one pixel line of the cell to the next. For speed the glyph is read by pointing the stack pointer at it and popping two bytes at a time, so interrupts are disabled while SP is borrowed, and the routine ends with EI whatever the interrupt state was on entry.
D $C237 No address this routine writes can fall below $4000: the high byte is $40 OR (row AND $18) plus at most 7, and the attribute high byte is $58 OR (row AND $18)/8. A row of 24 or more would write into the attribute file and the memory after it, not into $0000-$3FFF. The column is not checked either: a column of 32 or more is ORed into the row bits of the low byte.
R $C237 A Character code ($30-$5B)
R $C237 O:A Corrupted
R $C237 O:B Corrupted
R $C237 O:DE Corrupted
@ $C237 label=PrintChar
C $C237,1 No interrupts while SP points into the font
C $C239,2 B = (code - $28) * 4: half the glyph's offset from $5C00
C $C23E,3 Where the next character is printed: column in the low byte ($C23F), row in the high byte ($C240). It is the operand of LD DE,$1017 at $C23E (the value in the title snapshot) in the character printer at $C237, which advances the column after each character.
C $C241,1 Advance the column for the next character
C $C246,2 Low byte of the display address: row within the third times 32, plus the column
C $C24E,1 High byte: $40, $48 or $50 for the third the row is in
C $C254,2 HL = $5C00 + 8 * (code - $28), the glyph
C $C25C,1 Keep the high byte for the attribute address
C $C25D,4 Save SP in the operand of LD SP at $C274, then point SP at the glyph
C $C262,1 HL = display address
C $C263,1 Pop the glyph two bytes at a time and write one byte to each of the cell's eight pixel lines
C $C274,3 Put the stack pointer back (operand written at $C25D)
C $C277,2 H = $58-$5A: the attribute address of the same cell
C $C27F,2 Colour the cell with the text colour (operand $C280: $07 for the title credits, $47 from the menu on)
C $C282,1 Interrupts back on, even if they were off on entry
c $C284 Print HI-SCORE on the panel
D $C284 Prints HI-SCORE at row 17, column 12, above the hi-score digits. Used by the new-game code ($BD71) after the rest of the panel text, and by $DEBB.
R $C284 O:HL Address of the closing '#'
@ $C284 label=PrintHiScoreLabel
c $C28C Print the copyright line
D $C28C Prints the copyright line from $BB48 at the start of the bottom row (row 23, column 0), then continues into the message printer #R$C292. Used by the start-up code when it draws the title screen ($F1A2) and by the hi-score table (#R$BF6A, $BF76).
R $C28C O:HL Address of the closing '#'
@ $C28C label=PrintCopyright
c $C292 Print a message
D $C292 Prints the message at HL in the small font, starting at row D, column E, one character at a time through #R$C237. The message is ASCII in the game's font (so '.' is written '<', '/' '=', '(' '>' and ')' ';', and '-' is '[') with these codes handled here:
D $C292 '#' ($23) ends the message; HL is left pointing at it, so a caller can INC HL to reach the message after it.
D $C292 A space ($20) moves one column right without drawing, so whatever was in that cell stays.
D $C292 $FF starts a new row at the column the message started at (kept in the operand at $C2B8).
D $C292 $FC followed by a byte n moves n columns right.
D $C292 Any other code, including other codes with bit 7 set, is drawn as a character.
R $C292 HL Message
R $C292 D Row
R $C292 E Column
R $C292 O:HL Address of the closing '#'
@ $C292 label=PrintMessage
C $C292,4 Set the text position
C $C296,1 Remember the first column for $FF (operand of LD E at $C2B7)
N $C29A This entry point is used by the routine at #R$F355.
C $C29A,1 Space: skip a column without drawing
C $C2A7,2 '#' ends the message, HL pointing at it
C $C2AA,2 Codes below $80 are printed
C $C2AF,2 $FF: next row, back at the first column
C $C2B7,2 The column the message being printed by #R$C292 started at (operand of LD E,n at $C2B7); the $FF control code returns to it on the next row.
C $C2C0,2 $FC n: skip n columns
C $C2C9,3 Store the new column and move past the code
C $C2D0,1 Anything else is drawn
c $C2D9 Read a map cell near the player
D $C2D9 Returns the map cell at a position given relative to the map window ($BA17). A holds a character row of the play area; halving it gives the cell row, since a map cell is two character rows high. Most callers pass the player's even row (from #R$C3EB or $B95D), but some pass that row plus 4, the cell two below the player's top cell ($C7CD, $CA1B, $CAC3), or plus 1 ($C812, same cell). E holds eight times a column offset plus a row adjustment: $30 and $31 for the player's upper and lower cells (map column 6 of the window, the seventh of the 13 shown), $2F for the cell above the player's head (one byte before column 6 row 0, so the row adds up to the cell one above the player), $32 for the cell under the player's feet, and $28/$29 and $38/$39 for the cells beside the player (#R$DD58). The cell's address is left in HL, so a caller can change the cell (#R$DBAB, #R$D65E).
D $C2D9 There is no range check: with the player in the lowest rows, E=$32 reads a cell at the top of the next column, and the lower part of the map is simply the window moved $0680 bytes on ($D43A).
R $C2D9 A Character row of the play area (usually the player's even row; some callers add 1 or 4)
R $C2D9 E Eight times the column offset from the map window, plus the row adjustment
R $C2D9 O:A The cell's code
R $C2D9 O:HL Address of the cell
R $C2D9 O:BC The offset added to the window
@ $C2D9 label=GetMapCell
C $C2D9,2 Character row / 2 = cell row (a cell is two rows high)
C $C2DB,1 plus eight times the column, plus any row adjustment
C $C2DC,3 HL=map window + offset
C $C2E3,1 A=the cell's code
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
c $C303 Move a display address down one pixel line
D $C303 Moves the display address in HL to the pixel line below: the next line of the same character cell, or the top line of the cell below, crossing into the next third of the screen when needed. From the bottom line of the screen it gives $5800 plus the column, the attribute file.
R $C303 HL Display address
R $C303 O:HL Display address one pixel line lower
R $C303 O:A Corrupted
@ $C303 label=PixelLineDown
c $C312 Move a display address up one pixel line
D $C312 Moves the display address in HL to the pixel line above: the previous line of the same cell, or the bottom line of the cell above, crossing into the previous third when needed. Nothing stops it at the top of the screen: from the top line of row 0 it gives $3FE0 plus the column, below the display file.
R $C312 HL Display address
R $C312 O:HL Display address one pixel line higher
R $C312 O:A Corrupted
@ $C312 label=PixelLineUp
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
c $C33B Draw the carried items
D $C33B Redraws the carried-items row of the panel. After waiting for an interrupt, it blacks out the attributes of rows 22-23, columns 3-22, then draws each item held in the ten slots at $BA19 as a 16x16 icon in a box, left to right from row 22, column 3, two columns apart. Empty slots are skipped without leaving a gap, so the icons are always packed to the left, and the pixels of icons no longer shown stay behind under black attributes.
D $C33B An item's icon is the world's 32-byte map block graphic for its code (the block table at the address in $DE2F, entry code - $60), coloured with the attribute paired with its code in #R$BA37 (found by #R$C4B0). A one-pixel frame is then drawn round the edge of the 16x16 cell over the graphic.
D $C33B Called at the start of each life ($BE5F) and by the item handlers after an item is gained or lost ($DBF4, $DC7A).
R $C33B O:A Corrupted
R $C33B O:BC Corrupted
R $C33B O:DE Corrupted
R $C33B O:HL Corrupted
@ $C33B label=DrawCarriedItems
C $C33B,1 Wait for the next interrupt
C $C33D,3 Black out rows 22-23, columns 3-22
C $C34B,3 Ten slots, drawn from row 22, column 3
C $C356,1 Empty slot: skip it without moving along
C $C35A,3 Take the item's colour from its pair in the item colour table
C $C363,2 HL = the item's 32-byte block graphic: (code - $60) * 32 into the world's block table
C $C372,3 Draw it, 2 bytes by 2 rows
C $C378,1 Frame the cell: a full top line...
C $C387,2 ...the left and right edges of the next 14 lines...
C $C394,2 ...and a full bottom line
C $C399,1 Next icon two columns right
c $C3A5 Blank the play area and show a message over a fallen figure
D $C3A5 Clears the play area (#R$C511), prints the message at HL at row D, column E (#R$C292), and draws the 32x16 picture at #R$BAB8 in white at row 12, column 9. Used for LIFE LOST ($CD06) and, through #R$C3C0, for OUT OF TIME, OUT OF LIFE and ABORT PRESSED; every caller prints at row 3.
R $C3A5 HL Message
R $C3A5 D Row
R $C3A5 E Column
@ $C3A5 label=ShowStopMessage
C $C3A5,1 Blank the play area, keeping the message and its position
C $C3AC,3 Print the message
C $C3AF,2 Draw the fallen figure in white, 4 bytes by 2 rows, at row 12, column 9
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
c $C3DA Convert a display address to a row and column
D $C3DA Returns the character row and column of the display address in HL, ignoring which pixel line of the cell it is on. The reverse of #R$E977.
R $C3DA HL Display address
R $C3DA O:D Row (0-23)
R $C3DA O:E Column
R $C3DA O:A Column
R $C3DA O:H Third times 8 ($00, $08 or $10)
@ $C3DA label=AddrToRowCol
c $C3EB Convert a display address to an even row and a column
D $C3EB As #R$C3DA, but an odd row is rounded up to the next even one. Used by the player's movement code.
R $C3EB HL Display address
R $C3EB O:D Even row
R $C3EB O:E Column
R $C3EB O:A Column
R $C3EB O:H Third times 8
@ $C3EB label=AddrToEvenRowCol
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
c $C4A2 Find an item among the carried items
D $C4A2 Looks for A in the ten carried-item slots at $BA19. With A=0 it finds the first empty slot, which is how a picked-up item is given a place ($DBEB-$DBF0); with an item code it tells whether that item is held ($C1B8, $CD10, $D718, $DC6A).
R $C4A2 A Item code, or 0 for an empty slot
R $C4A2 O:F Z set if found
R $C4A2 O:HL The slot found ($BA22 if none)
@ $C4A2 label=FindCarriedItem
c $C4B0 Find an item in the item colour table
D $C4B0 Looks for item code A among the code bytes of the pairs at #R$BA37. The routine makes twelve probes, one more than there are pairs, so the last one tests the first byte of #R$BA4D; that byte is never an item code.
R $C4B0 A Item code
R $C4B0 O:F Z set if found
R $C4B0 O:HL The code byte of the pair found (its colour follows)
R $C4B0 O:B Probes left
@ $C4B0 label=FindItemColour
c $C4BD Draw one large character
D $C4BD Draws the 8x8 glyph at IX as a 16x16 character at display address HL. Each glyph byte is turned into two bytes, one for its left four bits and one for its right four, and each of those is written to two pixel lines. The widening is done by rotating the output byte left and ORing it with itself after each bit, so a set pixel also spreads to the right within its output byte (a lone top bit becomes the five leftmost pixels, for example): the result is a bold double-size letter rather than an exact enlargement.
D $C4BD The second pixel line of each pair is reached with INC H alone, so a character whose top is on the last pixel line of a character row would spill into the wrong place; the callers always start at a row's top line.
R $C4BD IX Glyph (eight bytes)
R $C4BD HL Display address
R $C4BD O:HL Display address sixteen pixel lines lower
R $C4BD O:IX Glyph address + 8
@ $C4BD label=DrawLargeGlyph
C $C4BD,2 Eight glyph bytes
C $C4C2,2 Two screen bytes from each: the left four bits, then the right four
C $C4C8,1 Take the glyph's top four bits one at a time into D, two output bits each, ORing D with itself shifted as it goes (this widens and thickens the pixels)
C $C4D7,1 Write the byte on this pixel line and the one below
C $C4DF,1 Back to the first column, down two pixel lines
C $C4E7,2 Next glyph byte
c $C4ED Print a message in large letters
D $C4ED Prints the message at HL with 16x16 characters, starting at the display address in DE. A space moves one large character (two columns) right; '#' ends the message and no other control code is understood. It sets no attributes: the callers colour the area afterwards (#R$C07C after PRESS ANY KEY TO PLAY and after the world intro card).
D $C4ED Used for PRESS ANY KEY / TO PLAY on the world start screen ($BDC9, $BDD0), WORLD OF or THE LAST ($BE84) and the world's name ($BECF) on the intro card, and the CONTINUE? countdown digit ($CCDD).
R $C4ED HL Message
R $C4ED DE Display address of the top left pixel line of the first character
R $C4ED O:HL Address of the closing '#'
R $C4ED O:DE Display address after the last character
@ $C4ED label=PrintLarge
C $C4ED,1 '#' ends the message
C $C4F1,2 A space just moves on
C $C4F7,2 IX = the glyph, $5C00 + 8 * (code - $28)
C $C506,1 HL = display address, DE = glyph; draw the character
C $C50C,1 Two columns right for the next character
c $C511 Blank the play area
D $C511 Sets the play area's attributes to 0 (#R$C07C) and then clears its pixels: 26 bytes (columns 3-28) of each of the 128 pixel lines of character rows 0-15, by #R$ED23. Used by world set-up before the intro card ($BDC0), at the start of every life ($BE51), by the routine at $C3A5 ($C3A7) and after the last guardian ($D859). The buffer at $F000 is not touched.
@ $C511 label=BlankPlayArea
C $C511,1 Black on black
N $C512 This entry point is used by the routine at #R$C553.
@ $C512 label=ClearPlayAreaColour
C $C515,3 Just past column 28 of pixel line 0
C $C518,2 13 words: columns 3-28
C $C51A,2 Character rows 0-15
C $C51C,3 Clear the pixels
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
N $C606 While $BA06 is non-zero (set to $7B at $C71D when the player steps on a map cell holding $79 or $7A), redraw that cell with #R$DB3B about every eight passes, using $7C, $7D and $7E in turn, and then clear $BA06. It marks a $79 or $7A cell the player has stood on at a scroll column start ($C708-$C71A, now $0C or $0D); a weapon blow on that cell releases a heart (#R$D8D6).
N $C63E Start the enemy that the world's object list (#R$D5D1) holds for the column now at $B95C, if an enemy slot is free (#R$C480) and the entry is not yet marked as started (bit 7 of its second byte). The entry is marked before bit 6 is compared with $B957, so an entry for the other part of the map is marked without starting; no slot records it, so it stays marked until a #R$C169 walk (a lost life, a move between the upper and lower parts of the map through #R$DD66, or a world set-up) clears every mark. In world 7 BeginLife plants #R$D5E3 in the CALL here, which looks up four-byte entries by $B95A instead.
C $C63E,3 Find the list entry for this position: #R$D5D1 (by map column) or, in world 7, #R$D5E3 (by $B95A); HL=its byte 0, or byte 1 in world 7
C $C641,2 Jump if there is none
C $C643,1 Is an enemy slot free?
C $C648,1 DE=the list entry
C $C649,2 Jump if not
C $C64B,1 HL=the entry's row and started flag, DE=the slot
C $C64D,2 Jump if the entry has already started its enemy
C $C653,1 D=the row (bit 7 still clear)
C $C654,2 Mark the entry as started
C $C656,3 Keep the flag's address for the slot (the operand at $C696)
C $C659,1 Is the entry for the part of the map the player is in (bit 6 of the next byte against $B957)?
C $C662,2 IX=the slot
C $C664,3 Jump if not (the entry stays marked)
C $C669,2 E=column 2 (the left edge) if bit 7 is clear, or $1A for the right
C $C671,1 Keep a carry for #R$DD41 if the column is below 16 (it will set bit 7 of byte 9: moving right)
C $C675,1 HL=the address of template number (bits 0-4) in the table at word $768E
C $C683,1 For the right edge, E=$1E minus the template's width, so the enemy's right edge is at column 29
C $C68D,1 BC=the template; A=its high byte, non-zero, to mark the slot in use
C $C690,1 HL=the slot
C $C691,3 Fill it in
C $C694,1 Slot bytes 10-11=the address of the list entry's started flag, which #R$D909 clears when the slot is freed
N $C69B Start a type 4 enemy at a map cell holding the world's spawn code. If fewer than two are active and one of the 112 map cells addressed by $BA17 holds the code the world set-up planted at $C6AC (world header byte 11: $9F in worlds 1-2, $88 in worlds 3-4, $8E in worlds 5-6, $FF in world 7, which has no type 4 template), there is a 1 in 8 chance of starting one there, provided a slot is free.
C $C69B,2 Count the type 4 enemies
C $C6A0,2 Are there two or more?
C $C6A2,3 Jump if so
C $C6A5,3 HL=address of the visible map, eight cells per column
C $C6A8,3 Look for a cell holding the world's spawn code (the operand at $C6AC, from header byte 11) among its 112 bytes
C $C6AF,2 Jump if there is none
C $C6B1,2 Take a pseudo-random number (0-127) from R
C $C6B3,2 Is it below 16 (a 1 in 8 chance)?
C $C6B5,2 Jump if not
C $C6B7,1 Is an enemy slot free (HL pointing at it)?
C $C6BB,2 Jump if not
C $C6BD,2 A=offset of the cell found plus 1
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
C $CC4B,1 Step the frame number in bits 0-2 of byte 9 (the movers above have reset it to 0 after frame 2, or after frame 4 for type 7)
C $CC50,2 A=frame number, 1-4
C $CC52,2 DE=lines (byte 5)
C $CC57,1 HL=lines x width (byte 4)...
C $CC5F,1 ...x 2 (a mask byte before each graphic byte): DE=the size of one frame
C $CC62,3 HL=the first frame (bytes 6-7, from the template)
C $CC68,1 Add one frame size for each frame after the first
C $CC6F,4 Moving right (bit 7 of byte 9) and not type 7? Then use the matching frame in the second half of the world's frame area
C $CC7D,3 Half the frame area's length (the operand, from header bytes 16-17, planted at $BEAC)
C $CC81,3 Keep the frame's address in bytes 0-1 (high byte first; it is non-zero, so the slot stays in use)
C $CC87,3 Is the enemy still in the play area (#R$DD29)?
C $CC90,3 Free the slot if not, releasing its list entry (#R$D909)
C $CC93,3 Next slot
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
N $CE77 At a whole or half scroll column (#R$DD93), count down the ten 9-byte map-cell timers from $B95E. When one runs out, its cell is given the stored box code less $19, a background code, so an uncovered item that was not collected disappears (one that was collected is already background); if the cell is on screen it is redrawn with #R$DB3B and the background block.
C $CEC9,2 $93 when the first world in the bank is loaded, $82 for the second. It is the operand of LD C,$00 at $CEC9 and is also read at $DE19, where it replaces a block number before the block address is computed at $DE29-$DE36. It is the code of the world's plain background block: #R$DDFD draws map cells holding $00-$0F or $46-$5F with it, and here it is passed to #R$DB3B in C to draw a background cell into the buffer.
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
C $D0C8,2 A guardian is active: wait instead of writing the enemies to the map (100 DJNZs), which keeps the start of the copy below at about the same time after the frame interrupt
C $D0DB,2 An empty entry: a short delay in place of the map writes, for the same reason
N $D112 While the immunity timer at $BA2A is running (set to 200 by #R$DC54), count it down and flash the LIFE label at the top left of the status bar in random colours; otherwise keep it bright yellow.
C $D112,3 Is the immunity timer running?
C $D116,2 C=bright yellow on black, the LIFE label's usual colour
C $D118,3 Jump if the timer is not running
C $D11B,1 Count the timer down
C $D11F,2 Take a pseudo-random number from R
C $D121,2 Keep the INK and BRIGHT bits, so PAPER stays black and FLASH off
C $D123,2 Make INK odd: blue, magenta, cyan or white, never black
C $D126,3 Colour the LIFE label
N $D129 Draw the play area and the player. The sprites drawn on the screen last pass disappear as the copy passes them and come back only when they are drawn again below; a sprite drawn after the beam has passed its lines in the frame after the copy is missing from that TV frame, which is the game's flicker.
C $D129,2 A short wait: 180 turns of a 21 T-state loop
C $D12F,3 Copy bytes 3-28 of the 128 lines of the buffer at $F000...
C $D132,1 ...to columns 3-28 of pixel lines 0-127 (#R$EBFA); a frame interrupt is lost during it
C $D13A,1 Now put the player's 16-by-32-pixel sprite, background included, from the buffer at $5C00 onto the screen; SP is used as a pointer, so no interrupts
C $D13B,4 Save SP (in the operand at $D16E)
C $D13F,3 HL'=start of the sprite buffer
C $D143,3 HL=the player's display address; each line's two bytes go into the two bytes to its left
C $D146,2 16 pairs of lines
C $D149,1 Point SP at the next four bytes of the buffer and move HL' on past them
C $D150,1 BC=this line's two bytes, DE=the next line's
C $D152,1 Write BC into the two bytes before HL
C $D154,1 Down a pixel line and write DE the same way
C $D157,1 Down a pixel line; after the last line of a character row, move L on to the next row and take H back to the row's top line (unless L overflowed into the next third, where H is already right)
C $D168,1 Next pair of lines
C $D16D,3 Restore SP
C $D171,3 Draw the held weapon with #R$EBAF unless ClimbState has bit 0 or bit 2 set, a shot is in flight (ShotTimer $BA05), or the operand at $D17F (set at $CEFD or $CF52) is non-zero
C $D183,2 Line count, display address and graphic address, all written at $CFBD-$CFC4
C $D18E,3 While flying ($BA27), unless the flight came from item $6E ($BA28), $BA29 is set or the player is climbing, draw the 16-line flight graphic (the operand at $D1AC, set at $D016) at the display address in the operand at $D1AF (set at $CEF7)
C $D1B6,3 Is the player crouching ($BA07)?
C $D1BC,1 Put PlayerBufferPos back to $5C00 (crouching moved it eight lines down)
C $D1C0,3 Draw the 8-line crouching graphic at $6F40 one column left of the weapon's display address (the operand at $CF8D), or the one at $74C0 one column right when facing left
C $D1D7,3 Is a guardian active? If so draw it (#R$D513) instead of the enemies
C $D1E4,2 Draw the enemies listed at $BA09-$BA12, in list order
C $D1E9,1 Skip an empty entry
C $D1F3,2 IY=the enemy's slot
C $D1F6,3 DE=display address of the slot's column (byte 2) and character row (byte 3), from #R$E977
C $D1FF,3 HL=graphic address of the current frame (bytes 0 and 1, high byte first, set at $CC81), C=lines (byte 5), A=width in bytes (byte 4)
C $D20B,3 Draw it straight onto the screen
C $D214,2 While the counter here (set to $20 at $D8F2) is running, draw the rising heart: count down
B $D228,1,1 Sound effect number, read by #R$C408 (which returns past it)
C $D229,3 Move its display address (the operand at $D22A, set at $D900) up two pixel lines with #R$C312
C $D234,3 D=character row, E=column. From row 15 down, draw nothing; otherwise write the value at $D24D (set at $D8ED) into the heart's cell of the enemy position map
C $D24E,4 Draw the 16-line heart at $7620 there
C $D25A,3 DE=display address of the thrown shot (the operand here, set from $CF8D at $D2CA), or 0 when there is none
C $D261,2 End the shot when it has reached column 2 or 29
C $D272,1 Move it a column right, or left if it was thrown facing left (the operand at $D277, set at $D2D0), when BC=$0580 picks the left-facing graphics
C $D280,3 Draw the 8-line shot at its old address: $6F60 or $6F80 on alternate columns, $0580 further on when going left
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
C $D437,3 Move the map window to the lower part of the map, $0680 bytes on...
C $D43E,3 ...and rebuild the buffer at the current scroll position (#R$DD66)
C $D46C,3 Is up held? (Not tested while $B953 is non-zero.)
C $D48B,3 Move the map window back to the upper part, $0680 bytes back...
C $D494,3 ...and rebuild the buffer at the current scroll position (#R$DD66)
C $D4A1,2 Operand of LD A,$08 at $D4A1: scroll steps left in the current map column, 8 down to 0. Each scroll step decrements it; when it reaches 0, #R$DDC4 (called at $D4A4) resets it to 8 and moves the map window at $BA17 a column. The movement code treats 8 and 4 as the points where the player may turn, climb or collect (#R$DD93, #R$DCD7, #R$DBAB), and a life is not lost on a pass that has just brought it to 0.
C $D4A4,3 After the eighth step: move the window a column and draw the new edge column (#R$DDC4)
B $D4D1,1,1 Sound effect number, read by #R$C408 (which returns past it)
B $D4EA,1,1 Sound effect number, read by #R$C408 (which returns past it)
B $D4F8,1,1 Sound effect number, read by #R$C408 (which returns past it)
c $D513 Move and draw the end-of-world guardian
D $D513 Used by the main loop at $D1DE, in place of drawing the enemies, while $B955 is set. The guardian follows a list of display-file addresses set up at $C59A-$C5A0 from the world data ($7667 and $7669, or $767E and $7680 when $B95A holds $046E), taking one entry a pass and starting again at the $FF that ends it; bit 7 of an entry's high byte selects the second of two sets of graphics. Each pass it marks a block of 16 cells in the collision map at $EF80 with $FD, which is how #R$D77A knows the player's weapon has hit it, and draws it in two parts. Once its damage at $B956 reaches 64 it also draws one extra 16-line sprite per point of damage above 63 (1-16, since at 80 it is destroyed), each picked at random from the four frames of the explosion animation at $6BA0 (16 by 16 pixels, 64 bytes each; the same frames #R$D38B draws where an enemy is hit) and placed at one of four spots chosen by the count divided by 4, so up to four sprites share each spot.
@ $D513 label=DrawGuardian
C $D513,3 HL=address of this pass's entry in the guardian's path (the operand here, planted at $C59A and moved on below)
C $D517,2 At the $FF that ends the path, go back to its start (the operand at $D51D, planted at $C59D)
C $D521,1 DE=the entry, a display address
C $D525,3 Keep the address of the next entry for the next pass
C $D528,4 IX=the guardian's graphics record (the operand here, planted at $C5A0); bit 7 of the entry's high byte picks the second record, 8 bytes on
C $D535,2 Take the flag bit off the display address
C $D538,1 D=character row, E=column (#R$C3DA), for the map below; C3DA leaves H holding only the third ($00, $08 or $10)
C $D53C,3 Keep HL (the third in H, the display address's low byte in L) at $D5A0 for the explosion sprites below
C $D53F,1 L=the index of a cell in the enemy position map ($EF80 upwards) for the guardian: column/2*8 plus half the first row of its third. It is worked out from L and H (the low byte and the third) rather than E and D, so the row within the third drops out and the marked block always starts on row 0 or row 8
C $D54D,3 Mark a block of cells four wide and four high with $FD, the guardian's number in the map
C $D55E,1 Draw the first part of the guardian at its display address: graphic address (record bytes 0-1), width in bytes (byte 2) and lines (byte 3)
C $D574,3 Draw the second part (graphic address, width and lines from record bytes 4-7) straight to its right, the first part's width further on
N $D588 Once the damage at $B956 reaches 64, draw one extra sprite per point above 63, each picked at random from four.
C $D588,3 Has the guardian taken 64 or more damage?
C $D58D,1 Return if not
C $D58E,2 B=damage minus 63: the number of sprites to draw (1-16)
C $D591,1 Save the count
C $D592,2 Take a pseudo-random number from R. Each later read in the same pass comes 546 or 549 fetches after the previous one, which advances R by 34 or 37 (mod 128), so the choices follow on from the first rather than being independent
C $D594,2 Keep 0-3
C $D596,1 Times 64
C $D59B,3 HL=address of one of the four 64-byte sprites at $6BA0
C $D59F,3 D=the third the guardian is in ($00, $08 or $10) and E=the low byte of its display address (row within the third times 32, plus the column), as written at $D53C
C $D5A2,2 Use the count divided by 4 to pick one of four spots
C $D5A6,1 Column offset 1 or 3
C $D5AD,1 Row offset 0 or 2 (#R$E977 ORs it into the row within the third rather than adding it, so it has no effect when the guardian is on the third, fourth, seventh or eighth row of a third)
C $D5B6,3 Turn the row and column into a display-file address
C $D5B9,2 Draw the sprite, 16 lines high
C $D5BF,2 Next sprite
c $D5C2 Colour the LIFE label
D $D5C2 Fills the attributes of columns 0-1 on rows 0-3, where the status bar's LIFE label is, with C. Used once a main-loop pass at $D126: bright yellow normally, a random colour while the immunity timer at $BA2A runs.
R $D5C2 C Attribute byte
@ $D5C2 label=ColourLifeLabel
C $D5CA,1 Colour column 0 and column 1 of this row
C $D5CD,1 Move to column 0 of the next row
c $D5D1 Find the enemy start list entry for the map column
D $D5D1 Used by the main loop at $C63E in worlds 1-6. Searches the world's list of three-byte enemy start entries (address and count planted in the operands at $D5D2 and $D5DB by the world set-up, from header bytes 13-15) for the first entry whose byte 0 equals the map column at $B95C.
D $D5D1 Only the first match is ever found, whether or not it has already started its enemy or is for the other part of the map, so a later entry with the same column can never start (worlds 1, 2, 5 and 6 each have such duplicates).
D $D5D1 The entry format (column; row and started flag; part, side and template number) is described with the world data, where each bank's lists are.
R $D5D1 O:HL Address of byte 0 of the entry found
R $D5D1 O:F Zero flag set if one was found (also, with HL just past the list, if none was found and the map column is 255, since the failure path is INC A)
@ $D5D1 label=FindListEntry
C $D5D1,3 Address of the current world's list of 3-byte entries. It is the operand of LD HL,$0000 at $D5D1 and comes from bytes 13-14 of the world header.
C $D5DA,2 Number of entries in the current world's list of 3-byte entries. It is the operand of LD B,$00 at $D5DA and comes from byte 15 of the world header.
c $D5E3 Find the world 7 enemy start list entry for the scroll position
D $D5E3 World 7's version of #R$D5D1: BeginLife plants this address in the CALL at $C63E ($BE7A-$BE7D) because world 7's map is longer than 256 columns, so the map column at $B95C repeats. Its list entries are four bytes: a two-byte position compared with $B95A (the scroll position divided by 4, half a column), then the row and started flag and the part, side and template byte, as in the three-byte entries.
D $D5E3 It returns HL pointing at the entry's second byte, one byte on from where #R$D5D1 leaves it, so the code at $C64B finds the flag and template bytes at the same offsets from HL.
D $D5E3 #R$C169 still walks this list three bytes at a time, which damages it (see #R$C169).
R $D5E3 O:HL Address of byte 1 of the entry found
R $D5E3 O:F Zero flag set if one was found
@ $D5E3 label=FindListEntryW7
c $D603 Open an item box and uncover its item
D $D603 The end of #R$D65E for an item box. The box's code is stored in the operand at $D62F and $BA08 is set to 1, so that #R$DBAB does not collect the item in the same pass. Until item $60 has been collected ($C91F still 0) the item is replaced by $60. A map-change record is then made in the first free slot of MapChanges ($B95E), found by stepping nine bytes at a time from $B955 with no limit: byte 0 = 50 (the count), bytes 1-2 = the cell's address, byte 3 = the box's code, bytes 4-5 = ScrollQuarter ($B95A, to tell later whether the cell is still on screen), bytes 6-8 = the drawing row ($D746), the extra rows (D) and the buffer column ($D744), everything #R$DB3B needs to redraw the cell. Finally the cell is given the item's code less $32, whose picture #R$DDFD draws, and the routine joins #R$D65E at $D742 to draw the item's picture into the buffer.
D $D603 #R$D65E returns into $D603 (it pushes that address before choosing an item for boxes $5F-$68), with B still the box code; boxes $69-$78 jump to $D604 with the code in A.
R $D603 A Box code (entry $D604)
R $D603 B Box code (entry $D603)
R $D603 C Code of the item to uncover ($60-$78)
R $D603 D Rows to add when drawing
R $D603 HL (operand at $D605) Address of the cell
@ $D603 label=OpenItemBox
C $D603,1 A=the box's code
N $D604 This entry point is used by the routine at #R$D65E.
@ $D604 label=OpenItemBoxA
C $D604,3 HL=the cell's address (operand written at $D673)
C $D607,3 Keep the box code for the record
C $D60A,2 No collecting in this pass (MapChangeCooldown)
C $D60F,3 Until item $60 has been collected ($C91F still NOP) every box gives item $60
C $D617,1 B=rows to add; DE=the cell's address
C $D619,3 Find the first free map-change record (no limit on the search)
C $D627,2 Byte 0: count 50
C $D629,1 Bytes 1-2: the cell's address
C $D62D,1 Byte 3: the box code (operand written at $D607)
C $D630,1 Bytes 4-5: ScrollQuarter now
C $D63A,1 Bytes 6-8: the character row, the rows to add and the buffer column, for redrawing
C $D646,1 HL=the cell, A=the item code, D=rows to add
C $D649,2 The cell will hold the item code less $32, drawn as the item's picture
c $D64F Strike a map cell several times
D $D64F Strikes one map cell B times through #R$D65E, keeping BC, DE and HL across each blow. #R$D38B calls it at $D3AE and $D3BB with B from the operand at $D38C, which the weapon-level handler sets, so a strong weapon can take a block that needs two blows ($D0-$D3) through both in one pass: in the recording a $D0 block became $03 within a single frame 125 times.
R $D64F B Number of blows
R $D64F A Even character row
R $D64F E Offset from the map window
@ $D64F label=StrikeCellRepeatedly
c $D65E Strike a map cell with the weapon
D $D65E What a blow does to the map. The cell is found with #R$C2D9 from A (an even character row) and E (the offset from the map window); nothing happens while a guardian is active ($B955). By its code:
D $D65E - below $5F (background, uncovered items, stepped cells): no effect, carry set. - $5F-$68, item boxes whose contents depend on the player: the item is chosen at $D689-$D71E from the box code and the weapon, armour, energy and carried items (for example $64-$66 give armour items $74-$76 unless that armour counter is already 2, and $5F/$60 give item $61 unless it is held), with item $72 as the fallback. $5F is never a closed box: it is what an emptied $78 box leaves ($78-$19), and because the test is CP $5F such a cell is treated as a box again, giving item $61 (or $72 if $61 is held); when that record times out the cell gets $46, which #R$DB9F still accepts, so collecting it gives item $78 once more. - $69-$78, item boxes that hold the item of the same code. - $79-$C5: solid scenery that cannot be broken; carry set. - $C6: becomes the climbable $7F, drawn at once. - $C7-$CF: broken, leaving code-$C6 ($01-$09), drawn as the world's background. - $D0 and above: loses 7 (so $D0-$D3 take two blows, through $C9-$CC); the new code is drawn.
D $D65E An opened box goes through #R$D603: until item $60 has been collected (its handler puts an INC at $C91F) every box yields item $60; the cell then holds the item's code less $32 ($2E-$46), which #R$DDFD draws as the item's picture, and a map-change record is made so that the picture turns into background after 50 counts (the main loop at $CE7D) or when the view is rebuilt (#R$C190). Every change is drawn into the buffer straight away with #R$DB3B at row $D746 plus D and buffer byte $D744 (set by #R$D763), starts the hit effect ($BA03=2, drawn at $D3CE/$D3DE) and plays sound effect 2; the routine then returns with Z set.
D $D65E Entry $D660 first works out the buffer column with #R$D763; entry $D663, used by #R$DCD7 for blows from below, expects $D744 and $D746 already set.
R $D65E A Even character row
R $D65E D Rows to add when drawing (0 or 2)
R $D65E E Offset from the map window: eight times the column, plus the row
R $D65E H Buffer column adjustment for #R$D763 (entry $D660)
R $D65E O:F Z set if the cell changed; carry set (Z clear) if the blow had no effect on a passable or unbreakable cell; Z and carry both clear if a guardian is active ($B955)
@ $D65E label=StrikeMapCell
C $D65E,2 No column adjustment
N $D660 This entry point is used by the routines at #R$D08C and #R$D333.
@ $D660 label=StrikeMapCellAt
C $D660,3 Work out the buffer column of the cell ($D744)
N $D663 This entry point is used by the routine at #R$DCD7.
@ $D663 label=StrikeMapCellHere
C $D663,3 HL=the struck cell, A=its code
C $D666,3 Blows do nothing to the map while a guardian is active
C $D66C,2 $C6 and up: a breakable block
C $D671,1 B=C=the code; keep the cell's address in the operand at $D605
C $D676,2 Below $5F: nothing to break (carry set)
C $D679,2 $79-$C5: unbreakable scenery or wall (carry set)
C $D67E,2 $69-$78: a box holding the item of its own code
C $D683,4 $5F-$68: choose the item, then return into #R$D603 to open the box
C $D689,2 Item $72 unless a rule below gives another
C $D71F,2 (Always below $79 here) Open the box
C $D724,2 $D0 and up: take 7 off and draw the new block
C $D730,2 $C6: becomes the climbable $7F
C $D73B,2 $C7-$CF: broken, leaving code-$C6 and the background drawn
N $D742 This entry point is used by the routine at #R$D603.
C $D742,1 Write the new code into the map
C $D743,2 Operand at $D744: the buffer column
C $D745,2 Operand at $D746: the character row
C $D747,3 Draw block C in the cell
C $D74A,2 Start the hit effect at the cell
C $D75B,3 Sound effect 2
B $D75E,1,1 Sound effect number, read by #R$C408 (which returns past it)
C $D75F,1 Z: the cell changed
C $D761,1 Carry: unbreakable
c $D763 Work out the buffer column of a struck cell
D $D763 Sets $D744, the buffer byte at which #R$D65E redraws a struck cell, from the cell's offset in E: a quarter of it (two bytes a map column) plus 2, kept to 0-31 (AND $1F), less 4 bytes (E less $10 first) when the player faces left, plus H, which callers set from the scroll step count to allow for a cell half scrolled. A is kept.
R $D763 A Kept
R $D763 E Offset from the map window
R $D763 H Adjustment in bytes for the scroll position
@ $D763 label=StrikeColumn
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
c $D8D6 Release a heart from a stepped-on cell
D $D8D6 Part of a weapon blow. Looks at the map cell in the player's row at column offset A from the map window and, if it holds $0C or $0D - a $79 or $7A cell the player has stood on ($C708-$C71A in the main loop) - adds 2 to it ($0E or $0F, after which the cell does nothing more) and releases a heart: $D24D is set to $FE for a $79 cell or $FF for a $7A cell, the rising-heart counter at $D215 to $20, and the heart's display address ($D22A) to character column 14, one row above the player's row when the cell was stepped on (the operand at $C632 holds that row plus 2, and 3 is taken off); sound effect 10 plays. The main loop's drawing code (#R$D08C at $D214-$D25A) then draws the heart rising and writes $D24D into the enemy position map, where the collision check in #R$D38B turns $FE into up to three units of energy back and $FF into one more unit of bar length.
D $D8D6 Any other cell code returns at once. Each $79/$7A cell therefore gives one heart per visit to the world: the codes stay $0E/$0F until the bank is reloaded.
R $D8D6 A Offset from the map window, eight times the column (the player's cell row is added)
@ $D8D6 label=StrikeSteppedCell
B $D907,1,1 Sound effect number, read by #R$C408 (which returns past it)
c $D909 Free an enemy slot
D $D909 Frees the enemy slot at IX: zeroes byte 0 (in use), byte 8 (type) and byte 12. If the slot was started from the world's enemy start list (byte 11 non-zero), clears bit 7 of the list entry's started flag, whose address is in bytes 10-11, and zeroes byte 11, so that entry can start its enemy again the next time its column (or, in world 7, position) is reached.
D $D909 Called by the enemy mover at $CC90 when an enemy has left the play area (#R$DD29 returned no carry), and at $D888 in #R$D77A.
R $D909 IX Address of the slot
@ $D909 label=FreeEnemySlot
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
D $DAC9 Either way this part of a pass lasts nearly two frames (a 128K frame is 70,908 T-states; SkoolKit's simulator, which leaves out the ULA's contention delays, counts about 69,900 on average between the recording's frames); a whole pass takes four frames or more (#R$C553).
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
c $DB3B Draw a block into one cell of the play area buffer
D $DB3B Redraws a single 16-by-16 cell of the buffer at $F000 when the map changes under the view, without a full redraw: the main loop's cell animation at $C635 (cells holding $79 or $7A), #R$DBAB when an item is collected (with the background block), the main loop at $CECB when a map-change record times out (with the background block), and #R$D65E at $D747 when a weapon blow changes a cell (with the cell's new block or the item's picture).
D $DB3B The line is worked out in steps of eight lines: A (with bit 0 ignored) plus D, times 8, so A+D=2 is the second cell row. E is the byte offset of the cell's left byte within a buffer line; callers compute it from the scroll position, so the cell lines up with the shifted picture. The block is then drawn by #R$DDFD's entry at $DE29, which enables interrupts when it has finished.
R $DB3B A Line of the cell's top in steps of eight lines (bit 0 ignored)
R $DB3B D Further steps of eight lines
R $DB3B E Byte offset of the cell within a buffer line
R $DB3B C Block code ($60 or more)
@ $DB3B label=DrawBlockAt
C $DB3B,1 Make A even
C $DB42,1 Add the extra rows and multiply by eight lines...
C $DB49,1 ...of 32 bytes: 256 bytes a step
C $DB4E,2 HL=buffer address of the cell's top-left byte
C $DB51,1 DE=that address
C $DB52,1 Draw block C there
c $DB56 Test whether the player is on a climbable cell
D $DB56 Reads the two map cells the player occupies (column 6 of the map window, the cell at the player's row and the one below it, #R$C2D9 with E=$30 and $31) and returns with the carry flag set if either holds one of the three climbable codes: $7F, $80 or $B2. These are the vines and ladders: up or down held on one of them moves the player a step up or down instead of jumping or crouching ($C86D-$C876, $C8D5-$C8E7), and $B2 is also allowed as the cell above when leaving the lower part of the map by the top ($D47D). Code $7F does not occur in any pristine map: it is what a breakable block $C6 becomes when struck (#R$D65E, $D730-$D737), so breaking such a block uncovers a climbable cell.
R $DB56 O:F Carry set if either of the player's cells is climbable
@ $DB56 label=IsPlayerOnClimbable
C $DB56,3 The player's upper cell: column 6 of the window at the player's row
C $DB62,2 A vine or ladder ($80, $B2, or $7F left by a struck $C6 block)?
C $DB71,3 The player's lower cell, one row further down the column
C $DB7D,2 Climbable?
C $DB8C,1 Neither: carry clear
C $DB8E,1 Climbable: carry set
c $DB90 Test whether a map cell code can be moved through
D $DB90 The movement code's wall test. Returns with the carry flag set if the player can move into a cell holding code A, and clear if the cell stops the player: codes below $60 (the background codes $00-$0F and $46-$5F and the uncovered item pictures $2E-$45) and codes from $78 up to one below the world's limit pass; the item boxes $60-$77 and every code from the limit up are solid.
D $DB90 The limit is the operand of CP $AE at $DB90, which world set-up copies from byte 0 of the world header at $BE8B: $AE in worlds 1 and 2, $A6 in worlds 3, 4 and 6, $A4 in world 5 and $9F in world 7. So each world's cell table is ordered with its scenery (drawn but not solid) below the limit and its walls and floors from the limit up.
D $DB90 Item code $78 is the one item code that is not solid, because the test for the boxes is CP $78 rather than CP $79. Code $B2, although above every world's limit, is climbable, and callers test for it before calling here ($C868, $D47D).
R $DB90 A Map cell code
R $DB90 O:F Carry set if the cell can be moved through, clear if it is solid
@ $DB90 label=IsCellPassable
C $DB90,2 At or above the world's solid limit (operand written from header byte 0 at $BE8B)? Solid: return with carry clear
C $DB93,2 Below $60 (background, uncovered items): passable, carry set
C $DB96,2 $78 up to the limit: scenery, passable (jump to set carry)
C $DB9B,1 $60-$77, closed item boxes: solid, carry clear
C $DB9D,1 Passable
c $DB9F Test whether a map cell holds an uncovered item
D $DB9F Returns with the carry flag clear if code A is in the range $2D-$46, the codes a map cell holds once a weapon has broken open an item box and the item's picture shows (#R$D65E writes the box's item code minus $32, $2E-$46, into the cell). Any other code returns with carry set. The main loop calls it for the player's upper and lower cells ($C6F4, $C756) and collects the item with #R$DBAB when the carry is clear.
D $DB9F The range is one wider than the pictures at each end: $2D never occurs, and $46, the cell left by item $78, is drawn as background by #R$DDFD but can still be collected here.
R $DB9F A Map cell code
R $DB9F O:F Carry clear (and Z set) for $2D-$46, carry set otherwise
@ $DB9F label=IsCellItemPicture
C $DB9F,2 Below $2D: not an item, carry set
C $DBA2,2 $47 and above: not an item
C $DBA7,1 $2D-$46: an uncovered item, carry clear
C $DBA9,1 Not an item
c $DBAB Collect the item in a map cell
D $DBAB Called by the main loop when one of the player's two cells holds an uncovered item picture (#R$DB9F). Nothing happens unless the scroll step count at $D4A2 is 4, which is when the player stands squarely on the cell, and the map-change cooldown $BA08 is zero, so an item cannot be taken in the pass that uncovered it.
D $DBAB The cell's code has $19 added, turning a picture code $2E-$45 into $47-$5E, which #R$DDFD draws as the world's background, so the item vanishes from the map; the cell is also redrawn at once in the buffer with the background block (#R$DB3B at buffer byte 14, the cell under the player at that scroll position) and sound effect 5 plays. The picture's block code (the cell's old code plus $32, $60-$78) is the item code: it is stored in the operand of LD A,$00 at $DBE4 and used to pick the item's handler from the table at $BA5B ((code-$60)*2 bytes in). The handler is jumped to with $DBE4 as its return address, and $DBE4 then adds the item to the carried items if it is one that is shown there.
D $DBAB The change is permanent for the rest of the world: no map-change record is made, so only reloading the world from its bank (#R$B8C3) brings the item back. (The records at $B95E belong to the box that was broken, see #R$D65E.)
R $DBAB A Code of the cell (an item picture, $2E-$46)
R $DBAB D Even character row of the player
R $DBAB E Rows to add: 0 for the upper cell, 2 for the lower
R $DBAB HL Address of the cell
@ $DBAB label=CollectCellItem
C $DBAB,1 B=the cell's code
C $DBAC,3 Only when the player stands squarely on the cell (scroll step count 4)
C $DBB2,3 and not in the pass that opened the box (MapChangeCooldown)
C $DBB7,1 Keep the code
C $DBB8,1 Add $19: the picture code becomes a background code, and the item is gone from the map
C $DBBC,3 Redraw the cell in the buffer with the background block, at the player's row plus E rows, buffer byte 14
C $DBC7,3 Sound effect 5
B $DBCA,1,1 Sound effect number, read by #R$C408 (which returns past it)
C $DBCB,1 A=the cell's code again
C $DBCC,2 plus $32 is the item code ($60-$78), kept in the operand of LD A,$00 at $DBE4
C $DBD1,2 Pick the item's handler from the table at $BA5B
C $DBDF,3 and jump to it, returning to $DBE4 to add the item to the carried items
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
c $DCD7 Strike the cell above the player's head
D $DCD7 Called from the main loop at $C90B while the player rises, when the scroll step count is 4. If D is not zero and armour counter $BA26 is not zero, it strikes the cell above the player's head (offset $2F) $BA26 times through #R$D65E's entry $D663, after setting the redraw column $D744 to $0E and the row $D746 to the player's row less 2 ($DCEA-$DD03): the head armour breaks blocks from below.
R $DCD7 D Non-zero to strike
@ $DCD7 label=StrikeCellAbove
c $DD06 Routine at DD06
D $DD06 Used by the routine at #R$C553.
c $DD12 Routine at DD12
D $DD12 Used by the routine at #R$C553.
c $DD1E Routine at DD1E
D $DD1E Used by the routines at #R$C553, #R$D08C, #R$D923 and #R$D991.
c $DD24 Get the player's facing
D $DD24 Loads A with FacingLeft ($B952) and sets the flags from it: zero means the player faces right.
R $DD24 O:A The facing: zero for right
R $DD24 O:F Zero flag set if facing right
@ $DD24 label=GetFacing
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
c $DD58 Test a map cell beside the player for walking
D $DD58 The wall test for walking. Reads the map cell at offset C from the map window in the player's row (#R$C2D9 with the player's even character row) and tests it with #R$DB90, returning with the carry flag set if the player may move into it. The main loop calls it only when the scroll step count is 4, with the player squarely on a cell: for a step left it tests offsets $28 and $29 (the player's two cells in column 5, $CA40-$CA4D) and for a step right $38 and $39 (column 7, $CAE4-$CAF1); if either is solid the player does not walk.
D $DD58 This is all that bounds the player sideways: nothing checks the map window against the ends of the map or of a part, so the maps themselves stop the player, with solid cells or with a gap in the floor that drops the player into the lower part (as at the right end of world 3's upper part). The left end of world 1's upper part is open: in map column 0 only the floor cell is solid, and the eight bytes before the map, read as a column, hold no solid cell at the player's height or underfoot, so a player walking off the left end would not be stopped but would fall. The recording never walks there: world 1's window stays between map columns 4 and 189.
R $DD58 C Offset from the map window: eight times the column, plus the row in the column
R $DD58 O:F Carry set if the cell can be moved through
@ $DD58 label=IsSideCellPassable
C $DD58,3 D=the player's even character row
C $DD5E,1 Read the cell at offset C in that row
C $DD63,3 and test it: carry set if the player can move into it
c $DD66 Move the map window and rebuild the buffer at the scroll position
D $DD66 Used by the loop tail (#R$D38B) when the player moves between the upper and lower parts of the map, where the window moves $0680 bytes. It stores the new window in $BA17, redraws the whole buffer (#R$DE96's entry $DE99, which also resets the map's run-time state) and then scrolls the fresh picture left with #R$E989 as many two-pixel steps as the scroll position needs, so the view does not jump.
D $DD66 With n steps left in $D4A2: facing right, the picture is drawn from the window and shifted 8-n steps; facing left, it is shifted n steps, except that at n=8 it is drawn from one column further on and not shifted. The picture from the window is the one whose first hidden column is eight bytes before it (#R$DE96). This is the relation between window, facing and step count that #R$DDC4 maintains.
D $DD66 Each step is about 150,000 T-states, so a move at a late scroll position costs several frames.
R $DD66 HL New map window
@ $DD66 label=SetMapWindow
C $DD66,3 Set the new map window
C $DD69,3 B=scroll steps left in this column
C $DD6D,3 Facing right?
C $DD72,2 Facing right: 8-B steps have been taken
C $DD78,2 Facing left at the start of a column...
C $DD7D,3 ...draw from one column on, unshifted
C $DD83,1 Redraw the buffer from the window in HL (#R$DE96)
C $DD88,1 No steps to make up?
C $DD8B,1 Scroll the fresh picture two pixels left, B times
c $DD93 Test for a scroll step count of 4 or 8
D $DD93 Returns with the zero flag set when the scroll step count at $D4A2 is 4 or 8, the two steps at which the player stands squarely on a map cell; the main loop and #R$C606 use it to time cell tests and effects to whole cells.
R $DD93 O:F Zero flag set if the count is 4 or 8
@ $DD93 label=IsWholeColumnStep
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
c $DDC4 Move the map window a column and draw the new edge column
D $DDC4 Called at $D4A4 in the loop tail (#R$D38B) when the scroll step count at $D4A2 has reached 0, that is when eight two-pixel steps have moved the buffer a whole 16-pixel cell. It sets the count back to 8, moves the map window at $BA17 eight bytes (one map column) in the direction the player faces, and draws that column's eight cells into the hidden cell at the leading edge of the buffer, from where the next eight steps scroll it into view: facing right, the map column 13 columns past the new window ($68 bytes on) into bytes 29-30 of each line; facing left, the column at the new window itself into bytes 1-2.
D $DDC4 The asymmetry is how the window is kept. With the window at map column k (MapWindow = map start + 8k) and n steps left in $D4A2, bytes 1-2 of the buffer show map column k-1 moved 8-n steps (facing right) or n steps (facing left) to the left, two pixels a step. Moving the window here, and the adjustment by 8 when the player turns while n is 8 ($CA5E-$CA67, $CB02-$CB09), keep that true across a column change, which is also what #R$DD66 relies on to rebuild the buffer.
D $DDC4 The entry point at $DDEE draws any eight-cell map column; #R$DE96 uses it 15 times for a full redraw. The DI at the start protects only the set-up: #R$DDFD enables interrupts again at $DE94 after each cell.
@ $DDC4 label=DrawEdgeColumn
C $DDC4,1 Only until the first cell is drawn (#R$DDFD enables interrupts)
C $DDC5,2 Eight more scroll steps before the next column
C $DDCA,3 HL=map window
C $DDCD,3 One map column is eight cells
C $DDD0,3 Is the player facing left?
C $DDD7,1 Facing right: move the window a column on
C $DDDB,3 The column 13 past it, 15th of the buffer...
C $DDDF,3 ...goes in the hidden bytes 29-30 of each line
C $DDE5,1 Facing left: move the window a column back
C $DDEB,3 and draw the column at the window into the hidden bytes 1-2
N $DDEE This entry point is used by the routine at #R$DE96. Draw the eight cells of the map column at HL into the buffer, the top line of the first starting at DE.
@ $DDEE label=DrawMapColumn
C $DDEE,2 Eight cells down the column
C $DDF0,1 Draw one cell
C $DDF5,1 DE=buffer address 16 lines further down
C $DDF6,1 Next map cell of the column
C $DDFB,1 HL now points at the next column's first map cell
c $DDFD Draw a map cell into the play area buffer
D $DDFD Used by #R$DDC4 (entry $DDEE) for each of the eight cells of a map column. It turns the cell's code into a block code, finds that block in the world's block table and copies it into the buffer at $F000.
D $DDFD The table's address is the operand at $DE2F, which world set-up takes from the word at $7665, so both worlds in a bank share one table. Each entry is 32 bytes, a 16-by-16-pixel graphic stored as 16 lines of two bytes, top line first, bit 7 of the first byte leftmost; a block code B selects the entry (B-$60)*32 bytes into the table. Codes of $79 and above are block codes already. The item codes $60-$78 (see #R$BA19) are all drawn as the block whose code is the operand at $DE09. Codes $2E-$45 have $32 added, so they show blocks $60-$77, the first 24 entries of the table, which are pictures of the items. Codes $00-$0F and $46-$5F are drawn as the block whose code is the operand at $CECA, the world's plain background. Codes $10-$2D would be used unchanged and select entries far past the table; no such code was on screen anywhere in the recording.
D $DDFD The entry point at $DE29 draws the block whose code is in A; #R$DB3B uses it. The copy points SP at the block and pops it two bytes at a time, so it runs with interrupts disabled and enables them again at $DE94 whatever the caller's state.
R $DDFD HL Address of the map cell
R $DDFD DE Buffer address of the cell's top-left byte
R $DDFD O:HL Buffer address of the cell below (DE+$0200)
R $DDFD O:DE $001F
@ $DDFD label=DrawMapCell
C $DDFD,1 Pick up the cell's code
C $DDFE,2 $79 and above: a block code already
C $DE03,2 $60-$78, an item: draw the world's item block instead
C $DE08,2 $C7 when the first world in the bank is loaded, $C8 for the second (the operand of LD A,$00 at $DE08): the block drawn for every map cell holding an item code, $60-$78. Codes of $79 and above have already gone to $DE29, so only $60-$78 are replaced here.
C $DE0D,2 (Always below $60 here)
C $DE11,2 $46-$5F: draw the background block
C $DE15,2 $00-$0F: draw the background block
C $DE19,3 The world's background block code
C $DE1F,2 $10-$2D are used unchanged
C $DE27,2 $2E-$45: the item picture blocks $60-$77
N $DE29 This entry point is used by the routine at #R$DB3B. Draw the block whose code ($60 or more) is in A into the buffer at DE.
@ $DE29 label=DrawBlock
C $DE29,2 Entry number
C $DE2E,3 Address of the world's table of 16-by-16-pixel blocks (32 bytes each, two bytes a line), taken from the word at $7665 (header bytes 5-6, shared by both worlds in a bank). It is the operand of LD BC,$0000 at $DE2E, where HL = (A-$60)*32 + base for block code A. World set-up ($BE2F-$BE40) overwrites the entries for block codes $79 and $7A with the same 32 bytes.
C $DE31,1 times 32
C $DE36,1 HL=address of the block
C $DE37,1 SP is about to point into the block
C $DE38,4 Save the stack pointer (operand of LD SP at $DE91)
C $DE3C,1 SP=block, HL=buffer address
C $DE3D,3 DE=$1F: from the second byte of a line to the first byte of the next
C $DE41,1 Copy 16 lines of two bytes each
C $DE90,1 HL=buffer address of the cell below
C $DE91,3 Restore the stack pointer
c $DE96 Redraw the play area buffer from the map window
D $DE96 Draws the whole play area into the buffer at $F000 from the map, and then resets the map's run-time state. World set-up calls it at $BE42 with the map window at $BA17 just set; #R$DD66 enters at $DE99 with the window in HL when the player moves between the upper and lower parts of the map.
D $DE96 The buffer gets 15 map columns of eight cells, starting with the column eight bytes before the window: column k (0-14) goes into bytes 1+2k and 2+2k of every line, cell row r into lines 16r to 16r+15 (#R$DDC4's entry $DDEE, #R$DDFD). Columns 0 and 14 are the hidden edge cells; the 13 between them are what #R$EBFA shows, unshifted. Nothing is drawn in bytes 0 and 31. Each cell's copy enables interrupts again when it ends.
D $DE96 It then zeroes $D25B, clears bit 7 of the flag bytes in the world's list (#R$C169), applies the ten records at $B95E through #R$C190 with C=$19, prints the panel captions HI-SCORE, SCORE and TIME (#R$C284, text at $BB18) and clears the 183 bytes $B95E-$BA14 ($C2FC).
R $DE96 HL Map window (entry at $DE99)
@ $DE96 label=RedrawPlayArea
C $DE96,3 HL=map window
N $DE99 This entry point is used by the routine at #R$DD66.
@ $DE99 label=RedrawFromWindow
C $DE99,3 Start one column before it
C $DE9F,3 at byte 1 of the buffer's top line
C $DEA2,2 15 columns
C $DEA6,3 Draw a column of eight cells
C $DEAA,1 Two bytes (16 pixels) to the right for the next column
C $DEAF,1 Then reset the map's run-time state
C $DEB3,3 Clear bit 7 of the flag bytes in the world's list
C $DEB6,2 Apply the ten records at $B95E
C $DEBB,3 Print the panel captions HI-SCORE, SCORE and TIME
C $DEBE,3 Clear $B95E-$BA14
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
c $E977 Convert a character row and column to a display-file address
D $E977 Returns the display-file address of the top pixel line of the character cell at row D, column E. It is the same calculation as the ROM's CL-ADDR: the display file holds each of the three 64-line thirds as 2,048 bytes in which pixel line p of character row r starts 256*p+32*r bytes in, so the high byte is $40, $48 or $50 for the third and the low byte is the row within the third times 32 plus the column. Stepping down one pixel line from such an address is therefore INC H, with a carry into L (add 32, and take 8 back off H unless L overflowed into the next third) every eighth line, which is what every sprite drawer here does.
D $E977 Used wherever a sprite or effect is placed by cell: the enemies (#R$D08C at $D1FC), the guardian's damage sprites (#R$D513), the hit and explosion effects ($D3E1, $D41B), $D8FD, #R$ED4E (which draws plain graphics a character cell at a time) and $C37A.
R $E977 D Character row (0-23)
R $E977 E Column (0-31)
R $E977 O:DE Display-file address
@ $E977 label=ScreenAddress
c $E986 In-game interrupt routine
D $E986 The interrupt routine during play and whenever no tune is playing after the menu. It does nothing but re-enable interrupts and return. Its job is to end the HALT in the game's EI; HALT waits ($C33B, $C400, $CEFA, $D04D, $D991); the interrupt does no timing work of its own. It is installed at $F225 when the game starts and at $DED4 when a tune ends. It lives in bank 0 at $C000-$FFFF, so code that pages another bank there keeps interrupts disabled (#R$B8C3, #R$B908).
@ $E986 label=GameInterrupt
C $E986,1 Re-enable interrupts
C $E987,2 and return to the interrupted code
c $E989 Scroll the play area buffer two pixels left
D $E989 Used when the view moves right (the player faces right): the main loop calls it at $CB1E after counting a step off $D4A2, and #R$DD66 calls it to put a freshly drawn buffer at the right scroll position. It shifts bytes 1-30 of each of the 128 lines of the buffer at $F000 (240 pixels) one bit left, twice, with 30 RL instructions a pass written out in full rather than looped. Bytes 0 and 31 are not touched.
D $E989 The carry is clear for the first pass of each line, so a zero enters at the right; but the bit that leaves byte 1 in the first pass is carried into the bottom of byte 30 in the second, so a stray pixel from the left edge can appear in bit 0 of byte 30. Both ends are hidden cells (the copy #R$EBFA shows bytes 3-28 only), and bytes 29-30 are redrawn by #R$DDC4 when the eighth step completes a cell.
D $E989 A call takes about 149,700 T-states (just over two frames) with interrupts enabled; #R$DAC9 wastes a similar time on passes that do not scroll.
@ $E989 label=ScrollBufferLeft
C $E989,3 Byte 30 of the top line
C $E98C,2 128 lines
C $E98E,3 32 bytes a line
C $E991,1 No bit to shift into byte 30 at first
C $E992,1 Remember where the line's byte 30 is
C $E993,2 Shift bytes 30 down to 1 one bit left
C $E9EC,1 Again from byte 30: the bit that left byte 1 goes into its bit 0
C $EA46,1 Byte 30 of the next line (the addition clears the carry)
C $EA48,1 Until all 128 lines have moved two pixels
c $EA4D Scroll the play area buffer two pixels right
D $EA4D The mirror image of #R$E989, used when the view moves left (the player faces left): the main loop calls it at $CA7D after counting a step off $D4A2. It shifts bytes 1-30 of each of the 128 lines of the buffer at $F000 one bit right, twice, with 30 RR instructions a pass written out in full. Bytes 0 and 31 are not touched.
D $EA4D A zero enters bit 7 of byte 1 in the first pass, but the bit that leaves byte 30 in the first pass is carried into bit 7 of byte 1 in the second. Both edge cells are hidden (#R$EBFA shows bytes 3-28), and bytes 1-2 are redrawn by #R$DDC4 when the eighth step completes a cell.
D $EA4D #R$DD66 never uses this routine: after a full redraw it reaches every scroll position with left shifts only. A call takes about 149,700 T-states with interrupts enabled.
@ $EA4D label=ScrollBufferRight
C $EA4D,3 Byte 1 of the top line
C $EA50,2 128 lines
C $EA52,3 32 bytes a line
C $EA55,1 No bit to shift into byte 1 at first
C $EA56,1 Remember where the line's byte 1 is
C $EA57,2 Shift bytes 1 up to 30 one bit right
C $EAB0,1 Again from byte 1: the bit that left byte 30 goes into its bit 7
C $EB0B,1 Byte 1 of the next line (the addition clears the carry)
C $EB0C,1 Until all 128 lines have moved two pixels
c $EB11 Draw a masked sprite 16, 24 or 32 pixels wide on the screen
D $EB11 Draws a masked sprite straight into the display file, one pixel line at a time: every screen byte is ANDed with the sprite's mask byte and ORed with its graphic byte. A picks the width in bytes: 2 goes to #R$EB71 (16 pixels) and 3 to #R$EBAF (24 pixels); any other value (4 in practice) is drawn here, 32 pixels wide, from $EB1C, which #R$D991 also calls directly (at $DA65 and $DA7F, with 16 lines in A).
D $EB11 A sprite of width w bytes is stored as 2w bytes a pixel line, top line first, each screen byte as a mask byte followed by its graphic byte, left byte first, bit 7 the leftmost pixel. A mask bit of 1 keeps the pixel underneath.
D $EB11 The enemies are drawn through here each pass (#R$D08C at $D20B, with the graphic address, width and line count from the enemy's slot) and the guardian in two parts side by side (#R$D513). Because they go straight to the screen after the play area has been copied over them by $EBFA, they are missing from the screen from the moment the copy passes their lines until they are redrawn; see #R$D08C.
D $EB11 The routine uses SP to read the sprite and to read and write the screen, so interrupts are disabled throughout. The saved SP is kept in the operand at $EB6D and the current line's display address in the operand at $EB37.
R $EB11 A Width in bytes: 2, 3, or anything else for 4
R $EB11 C Number of pixel lines
R $EB11 A Number of pixel lines (entry at $EB1C)
R $EB11 DE Display-file address of the sprite's top left byte
R $EB11 HL Address of the sprite (mask and graphic bytes)
@ $EB11 label=DrawSprite
N $EB1C This entry point is used by the routine at #R$D991.
@ $EB1C label=DrawSprite32
c $EB71 Draw a masked sprite 16 pixels wide on the screen
D $EB71 Draws a 16-pixel-wide masked sprite straight into the display file, in the format described at #R$EB11: four bytes a pixel line (mask, graphic, mask, graphic). #R$EB11 enters at $EB71 with the line count in C; everything else calls $EB72 with it in A.
D $EB71 It returns the display address of the line below the sprite in DE, so a caller can stack sprites vertically. Users: the enemies of width 2 (through #R$EB11), the flight graphic, the crouching overlay, the shot and effect graphics in #R$D08C, the hit and explosion effects in #R$D38B, the guardian's damage sprites (#R$D513) and the weapon code (#R$D923, #R$D991).
D $EB71 Interrupts are disabled while it runs (SP is the data pointer); the saved SP is kept in the operand at $EBAB.
R $EB71 C Number of pixel lines (entry at $EB71)
R $EB71 A Number of pixel lines (entry at $EB72)
R $EB71 DE Display-file address of the sprite's top left byte
R $EB71 HL Address of the sprite
R $EB71 O:DE Display-file address of the line below the sprite
@ $EB71 label=DrawSprite16C
C $EB71,1 A=number of lines
N $EB72 This entry point is used by the routines at #R$D08C, #R$D38B, #R$D513, #R$D923 and #R$D991.
@ $EB72 label=DrawSprite16
C $EB72,1 No interrupts while SP is used as a pointer
C $EB73,4 Save SP (in the operand at $EBAB)
C $EB77,1 HL'=display address
C $EB7A,1 Keep the line count in A'
C $EB7C,1 Point SP at this line of the sprite and move HL on four bytes
C $EB81,1 C=mask and B=graphic for the left byte, E=mask and D=graphic for the right byte
C $EB84,1 BC=the two screen bytes
C $EB86,1 Left byte = (screen AND mask) OR graphic
C $EB8C,1 Right byte likewise
C $EB92,1 Write them back
C $EB93,1 Down a pixel line; after the last line of a character row, move L on to the next row and take H back to the row's top line (unless L overflowed into the next third)
C $EBA4,1 Next line
C $EBA9,1 DE=display address of the line below the sprite
C $EBAA,3 Restore SP
c $EBAF Draw a masked sprite 24 pixels wide on the screen
D $EBAF Draws a 24-pixel-wide masked sprite straight into the display file, in the format described at #R$EB11: six bytes a pixel line (mask, graphic for each of three screen bytes). #R$EB11 enters at $EBAF with the line count in C; the weapon code calls $EBB0 with it in A: the held weapon each pass at $D18B in #R$D08C, whose line count, display address and graphic address are the operands at $D184, $D186 and $D189 set up at $CFBD-$CFC4 (#R$C553), and the thrown weapon in #R$D991.
D $EBAF It returns the display address of the line below the sprite in DE. Interrupts are disabled while it runs (SP is the data pointer); the saved SP is kept in the operand at $EBF6.
R $EBAF C Number of pixel lines (entry at $EBAF)
R $EBAF A Number of pixel lines (entry at $EBB0)
R $EBAF DE Display-file address of the sprite's top left byte
R $EBAF HL Address of the sprite
R $EBAF O:DE Display-file address of the line below the sprite
@ $EBAF label=DrawSprite24C
N $EBB0 This entry point is used by the routines at #R$D08C and #R$D991.
@ $EBB0 label=DrawSprite24
c $EBFA Copy the play area from the buffer to the screen
D $EBFA Called once a pass by #R$D08C (at $D137, with HL'=$F003 and HL=A=$4013) to copy the play area from the back buffer at $F000 to the display file. Each of the buffer's 128 lines is 32 bytes; bytes 3-28 of line n are copied to columns 3-28 of pixel line n, so the picture fills character rows 0-15, columns 3-28 (208 by 128 pixels). Bytes 1-2 and 29-30 of each buffer line are the hidden edge cells where new map columns are drawn before they scroll into view. Attributes are not touched: the whole play area is one colour, set by #R$C07C.
D $EBFA The copy borrows the stack pointer as a data pointer, so it runs with interrupts disabled. For each line it points SP at the buffer and pops eight words into BC, DE, AF, IX, BC', DE', AF' and IY, then points SP just past the destination and pushes them back in reverse order: 16 bytes to columns 3-18, then 10 more (three words and two words) to columns 19-28. The self-modified operands hold the low byte of the display address just past the end of each part ($EC3A: column 19, used at $EC39 to reset L; $EC1C: column 29, used at $EC1B). The display file is not laid out line by line: within a third of the screen, the high byte of an address selects the pixel line inside a character row and the low byte's top three bits the character row, so the loop runs INC H for the eight pixel lines of a character row and adds $20 to L for the next character row. The first loop ($EBFF-$EC47) does the top third (H=$40-$47), the second ($EC4C-$EC94) the middle third (H=$48-$4F); the source pointer simply advances 32 bytes a line.
D $EBFA The routine's own instructions take 53,575 T-states. On a 128K the ULA delays its 3,328 writes to the display file by an estimated 3,300-4,000 T-states (the recording's frames run that much longer than the simulator's); entered about 14,000 T-states into a frame, it would re-enable interrupts a few hundred T-states after the next interrupt pulse has ended, so one frame interrupt is lost in every pass, as in the recording.
R $EBFA HL' Buffer address of the first byte to copy ($F003)
R $EBFA HL Display file address just past the first 16 bytes of the top line ($4013)
R $EBFA A Low byte of HL
@ $EBFA label=CopyPlayArea
C $EBFA,1 SP is about to be used as a data pointer
C $EBFB,4 Save the stack pointer (operand of LD SP at $EC97)
C $EBFF,3 Display address low byte just past the first 16 bytes of each line in this character row
C $EC02,2 and the one just past the last 10 bytes
C $EC07,1 Pop the line's first 16 bytes from the buffer into BC, DE, AF, IX...
C $EC0E,1 ...and BC', DE', AF', IY
C $EC15,1 Push the second eight bytes into columns 11-18 of the display line
C $EC1B,2 Point past column 28 for the second part
C $EC1D,1 Push the first eight bytes into columns 3-10
C $EC24,2 Buffer byte 19 of the line
C $EC26,1 Pop ten more bytes: six here...
C $EC2A,1 ...and four here, pushed into columns 25-28
C $EC30,1 then the six into columns 19-24
C $EC34,3 Next buffer line (32 bytes on from the last)
C $EC39,2 Back to column 19 of...
C $EC3B,1 ...the next pixel line of this character row
C $EC3C,2 Until all eight are done
C $EC41,2 Next character row of the top third
C $EC47,3 Until the eighth row (lines 0-63) is done
C $EC4A,2 The middle third (lines 64-127): the same loop with H=$48-$4F
C $EC97,3 Restore the stack pointer
C $EC9A,1 A frame interrupt that fell in the copy is lost
c $EC9C Clear the screen
D $EC9C Zeroes the whole display file and attribute file, $4000-$5AFF, leaving the screen black. It points the stack pointer at $5B00 and pushes 3,456 zero words, so interrupts are off until the stack pointer is back. Used by the start-up code, NewGame ($BD01), the hi-score table ($BF6D) and the control menu when a game starts ($F229).
R $EC9C O:B 0
R $EC9C O:HL 0
@ $EC9C label=ClearScreen
C $EC9C,1 No interrupts while SP is used to clear the screen
C $EC9D,4 Save SP in the operand of LD SP at $ECC6
C $ECA1,3 Push down from the end of the attribute file
C $ECA4,2 128 rounds of 27 zero words: 6,912 bytes, $4000-$5AFF
C $ECC6,3 Put the stack pointer back
c $ECCB Mirror the player's sprite buffer left to right
D $ECCB Reflects the 16-by-32-pixel sprite buffer at $5C00-$5C3F in place: on each line the two bytes swap places and each is bit-reversed through the table at $5B00.
D $ECCB The player's graphics are stored facing right only. When the player faces left, #R$C553 calls this twice while building the sprite: once at $CDA0, straight after #R$EDB4 has copied in the background, and once at $CE74, after all the pieces have been masked on (#R$EDD5). The background is mirrored twice and comes back as it was, while the pieces, drawn in between, end up facing left.
@ $ECCB label=MirrorPlayerBuffer
c $ECE9 Mirror the weapon graphics at $EE60 left to right
D $ECE9 Reflects the 288 bytes at $EE60-$EF7F in place, as 48 lines of a 24-pixel masked graphic (six bytes a line: mask and graphic for each of three screen bytes): the first and third mask/graphic pairs swap places and all six bytes are bit-reversed through the table at $5B00.
D $ECE9 The weapon upgrade code at $DCB2 (#R$DCAC) copies the current weapon's 288 bytes of graphics to $EE60 and jumps here, so $EE60 holds a left-facing copy of graphics stored facing right; the right-facing original stays where it is (its address kept in WeaponGfxAddr, $BA2E). #R$C553 picks $EE60 or the original by the player's facing ($CF04-$CF18, $CF89-$CF9E) for the weapon drawn by #R$EBAF.
@ $ECE9 label=MirrorWeaponGfx
c $ED23 Clear a rectangle of the display file
D $ED23 Clears the pixels of a rectangle of character rows, pushing zero words downwards from just past its right edge. For each of C character rows it points SP at HL on each of the row's eight pixel lines (INC H steps a pixel line in the display file's order) and pushes A zero words, then moves HL down a character row. It runs with interrupts disabled because SP is borrowed, and returns with them enabled.
D $ED23 Used for the play area by #R$C511 (columns 3-28 of rows 0-15), and in the start-up code (#R$F0C0): $F1D3 clears eight words of one character row from $5018, and $F4C3 eight words of ten rows from $40D8.
R $ED23 HL Display file address just past the right end of the rectangle's top pixel line
R $ED23 A Width in words (two bytes)
R $ED23 C Number of character rows
@ $ED23 label=ClearScreenRows
C $ED23,1 SP is about to be borrowed
C $ED24,4 Save it (operand of LD SP at $ED49)
C $ED28,3 Words to push on each line
C $ED2B,3 Zero
C $ED2E,2 Eight pixel lines a character row
C $ED30,1 Clear one line leftwards from HL
C $ED36,1 Next pixel line of this character row
C $ED3B,1 Next character row...
C $ED3F,2 ...moving H back to the row's first pixel line unless it has crossed into the next third
C $ED45,1 Until C rows are clear
C $ED49,3 Restore the stack pointer
c $ED4E Draw a graphic and colour it
D $ED4E Copies a graphic of B bytes by C character rows from HL to the screen at row D, column E (converted by #R$E977), eight pixel lines a row, then fills the same B by C cells of the attribute file with the attribute held in the operand at $ED85. The graphic is plain screen bytes, one pixel line after another, with no mask, so it replaces what was there.
D $ED4E FillAttrs at $ED86 is the attribute half on its own: it fills C rows of the attribute file from HL with A, the width taken from the operand at $ED87 (which the main entry sets to B). #R$C07C and #R$C33B use it that way.
D $ED4E The whole routine runs with interrupts disabled and ends with EI, including when entered at $ED86. Nothing in it borrows the stack pointer or pages memory: the DI is not needed for its own correctness.
R $ED4E HL Graphic (entry $ED4E); attribute address (entry $ED86)
R $ED4E B Width in bytes (entry $ED4E)
R $ED4E C Height in character rows
R $ED4E DE Row (D) and column (E) (entry $ED4E)
R $ED4E A Attribute (entry $ED86)
R $ED4E O:HL Attribute address of the row after the last one
@ $ED4E label=DrawGraphic
C $ED4F,1 Width into the LDIR count and the attribute width
C $ED56,1 Keep width and height; DE = display address of the top left cell
C $ED5A,1 Keep the display address for the attributes; B = rows to draw
C $ED5D,2 Copy one pixel line (width in the operand at $ED5E)
C $ED65,1 Next pixel line, until eight are done
C $ED6C,1 Next character row: down 32 in the low byte, back 8 in the high byte unless that crossed into the next third
C $ED79,1 HL = the graphic's first attribute cell
C $ED84,2 The attribute #R$ED4E colours a drawn graphic with (operand of LD A,$07 at $ED84). Callers poke it before drawing; the entry at $ED86 skips the LD A and uses the caller's A instead (#R$C07C, $C348).
N $ED86 This entry point is used by the routines at #R$C07C and #R$C33B.
@ $ED86 label=FillAttrs
C $ED86,2 Fill one row of attributes (width in the operand at $ED87)
C $ED90,1 Next attribute row
c $ED98 Copy a two-byte-wide strip of the screen
D $ED98 Copies B pixel lines of the two screen bytes at display address HL, top to bottom, to DE. #R$C1BF uses it to save the panel's four label pieces to $F000-$F0BF.
R $ED98 HL Display address
R $ED98 DE Destination
R $ED98 B Pixel lines
R $ED98 O:DE Byte after the copy
R $ED98 O:HL Display address below the strip
@ $ED98 label=SaveStrip
c $EDB4 Copy the background under the player into the player's sprite buffer
D $EDB4 The first step in building the player's sprite (#R$C553 at $CD9A): copies the 16-by-32-pixel patch of the play area buffer at $F000 that lies under the player (two bytes from each of 32 consecutive 32-byte buffer lines) into the sprite buffer at $5C00-$5C3F, two bytes a line. The player's graphics are then masked onto this copy (#R$EDD5) and the whole buffer, background included, is put on the screen by #R$D08C at $D13A, so the player needs no mask when it reaches the screen.
D $EDB4 The caller works out the buffer address from the player's display address at $B94E ($CD79-$CD99): the pixel line from the high and low bytes, times 32, plus $F00E, so the player is always taken from buffer columns 14 and 15. These are the columns the player occupies on the screen: its display address ($xx10 normally, column 16) is one byte past its right-hand byte, because the copy at $D13A-$D170 PUSHes each line below that address.
D $EDB4 Interrupts are disabled while it runs (SP is the data pointer); the saved SP is kept in the operand at $EDD1.
R $EDB4 HL Address of the top left byte of the patch in the play area buffer
@ $EDB4 label=CopyPlayerBackground
c $EDD5 Mask a 16-pixel-wide graphic into the player's sprite buffer
D $EDD5 Draws part of the player's sprite into the sprite buffer at $5C00, where #R$EDB4 has already put the background: each buffer byte is ANDed with the graphic's mask byte and ORed with its graphic byte. The graphic has the same four-bytes-a-line layout as the 16-pixel sprites of #R$EB71 (mask, graphic, mask, graphic); the buffer is two bytes a line.
D $EDD5 It returns the buffer address of the line below the graphic in DE, which is how #R$C553 builds the player from pieces stacked downwards ($CDA3-$CE6C): the body's top 16 lines, then two 8-line pieces for the lower body and legs, each replaced or overlaid when armour or other items are held. PlayerBufferPos ($BA35) says where the first piece goes: $5C00, or eight lines lower while crouching.
D $EDD5 Interrupts are disabled while it runs (SP is the data pointer); the saved SP is kept in the operand at $EDFF.
R $EDD5 A Number of lines
R $EDD5 DE Address in the sprite buffer ($5C00-$5C3F)
R $EDD5 HL Address of the graphic
R $EDD5 O:DE Buffer address of the line below the graphic
@ $EDD5 label=MaskIntoPlayerBuffer
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
b $F000 Panel labels, and the start of the play area buffer
D $F000 As loaded, these 192 bytes are the four labels of the side panels, each 16 pixels wide and stored as two bytes a line: LIFE (32 lines, $F000), STR (24 lines, $F040), POW (16 lines, $F070) and HIT (24 lines, $F090). A new game draws them at $BD22-$BD5E (#R$ED4E) at the top left and at rows 0, 11 and 21 of columns 30-31; #R$C1BF copies them back from the screen before the hi-score table (#R$BF6A) and the ending (#R$B908).
D $F000 The same memory is the top of the play area buffer, $F000-$FFFF: 128 lines of 32 bytes, one line for each of pixel lines 0-127 of the screen. #R$DE96 and #R$DDC4 draw 15 cells of 16 pixels into bytes 1-30 of each line, #R$E989 and #R$EA4D scroll bytes 1-30 two pixels at a time, and #R$EBFA copies bytes 3-28 to columns 3-28 of the screen; bytes 1-2 and 29-30 are hidden edge cells and bytes 0 and 31 are never used. So the first redraw of a game overwrites the labels here (they are on the screen by then), together with the start-up code from #R$F0C0 on, and they are only valid again once #R$C1BF has saved them at the end of the game.
@ $F000 label=PanelLabels
B $F000,192,2
c $F0C0 Start the game and draw the title screen
D $F0C0 The game's entry point. Imagine's tape loader, which runs from the area the worlds are later loaded into, finishes with IM 1, a zeroed R register, SP=$9ED8, EI and JP $F0C0. This code runs once: nothing in the game jumps back here, and it is not in any recorded or scripted run after the title snapshot was taken.
D $F0C0 First it moves data from where the loader left it to where the game uses it: 6,336 bytes of graphics used during play from $9FFA to $5DA0-$765F (for example the four 64-byte sprites at $6BA0 read at $D59B), 352 bytes of font from $EE60 to $5C40 (characters $30-$5B: the digits, a few punctuation marks and the capital letters, with $5B drawn as a hyphen; eight bytes each, as the character printer at $C237 addresses them) and a 256-byte bit-reversal table from $F4C6 to $5B00 (each byte holds its index with the bits in reverse order; #R$ECE9 uses it to mirror graphics). It fills the IM 2 vector table at #R$B700 with $B8, writes JP $E986 at #R$B8B8, and switches to interrupt mode 2 with I=$B7. So the interrupt routine while the title is drawn is #R$E986, which only re-enables interrupts and returns.
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
C $F10B,2 Draw Athena at the left in bright yellow
C $F11C,3 and again at the right
C $F128,3 Colour the left figure's bikini top red
C $F133,3 and the right figure's (A still holds the attribute)
C $F13C,3 Colour the left figure's bikini bottom
C $F145,3 and the right figure's
C $F14E,3 Draw the ATHENA logo across the top; the title interrupt cycles its colours
C $F15A,2 Draw the Imagine logo in bright cyan
C $F16B,2 Draw the SNK logo in white
C $F17C,2 Colour the SNK emblem green on bright white
C $F187,2 Colour the letters SNK bright blue
C $F192,2 Colour the words under the Imagine logo bright white
C $F19D,1 Two more white cells on row 21
C $F1A2,3 Print the copyright line on row 23
C $F1A5,3 Move 800 bytes from $9CDA to $FCE0; this overwrites the logo graphics just drawn
N $F1B0 Show the credits and wait for a key.
C $F1B0,1 Install the title interrupt routine, which cycles the logo's colours
C $F1B8,2 Print the credits in plain white from row 6, column 9
C $F1C6,3 Wait for a key, then carry on into the control menu
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
t $F2AA Control menu text
D $F2AA The control menu: SELECT, a blank row, then 1 KEYBOARD, 2 KEMPSTON, 3 CURSOR, 4 SINCLAIR 1 and 5 DEFINE KEYS, one to a row. #R$F1C9 prints it at row 7, column 10 with #R$C292 in bright white. Like the rest of $F001-$F4FE, it is overwritten during play, so it exists only until the first game starts.
@ $F2AA label=ControlMenuText
T $F2AA,68,8:n2:10:n1:10:n1:8:n1:12:n1:14
t $F2EE Credits text
D $F2EE The credits page of the title: programming, graphics and music, each credit on three rows with the second row indented by the $FC code. The start-up code prints it at row 6, column 9 in plain white with #R$C292 and waits for a key (#R$C2ED); #R$F1C9 then blanks it with #R$ED23. Overwritten during play like the control menu text before it.
@ $F2EE label=CreditsText
T $F2EE,103,14:n3:2:n1:13:n2:14:n3:2:n1:11:n2:14:n3:2:n1:15
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
