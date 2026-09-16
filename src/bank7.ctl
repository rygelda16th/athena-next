@ $C000 start
@ $C000 org
b $C000 World 7 header
D $C000 The header of world 7, the first world in this bank, at $7660 once #R$B8C3@main has copied the bank. #R$BDC0@main chooses it when bit 0 of the number of worlds completed is 0: it takes the map address through IX, plants the header's address at $BE88, and BeginLife copies bytes 0 and 11-22 into instruction operands at the start of every life. Nothing writes to the header.
D $C000 Byte 0: the lowest solid block code, copied to the operand at $DB91 of #R$DB90@main. Bytes 1-2: the map's address; the first map window ($BA17) is 32 bytes on. Bytes 3-4: the map's length, read only by #R$BCE6@main. Bytes 5-6: the cell table's address. Bytes 7-8: the guardian path's address. Bytes 9-10: the guardian graphics record's address. Byte 11: the map code type 4 enemies start on (to $C6AC). Byte 12: the map column at which the guardian appears (to $C58F). Bytes 13-14: the start list's address (to $D5D2). Byte 15: the number of list entries (to $D5DB). Bytes 16-17: the distance from each first-half enemy frame to its copy in the second half (to $CC7E). Byte 18: the end-of-map column, with bit 0 set when it is in the lower part of the map (to $D046, and as a JP NZ or JP Z opcode to $D03F). Byte 19: the play area attribute (#R$C07C@main). Byte 20: the column of the name on row 8. Bytes 21-22: the name's address.
D $C000 World 7: the name is WORLD (after THE LAST); the map is at $9116, 598 columns of eight cells; byte 12 holds $FF, which MapColumn (a low byte) still reaches twice, so world 7's first guardian also appears there, besides at the two fixed positions tested at $C565-$C57A; byte 11 holds $FF, a code no map cell holds, so no type 4 enemy starts; the start list has 40 entries; the play area is white ink on black; the end-of-map column is in the lower part, column 173.
@ $C000 label=W7Header
B $C000,1,1 The lowest block code that is solid.
W $C001,2,2 Address of the world's map (eight cells a column).
W $C003,2,2 Length of the world's map in bytes (a multiple of 8).
W $C005,2,2 Address of the bank's table of 16x16 map cell graphics (32 bytes each, block code $60 first).
W $C007,2,2 Address of the guardian's path, a list of two-byte display-file addresses (bit 7 of the high byte picks the second graphics record) ended by $FF.
W $C009,2,2 Address of the guardian's graphics record, two 8-byte entries (for each, the address, width in bytes and height in lines of the left part, then of the right part; masked graphics).
B $C00B,1,1 The map code a type 4 enemy starts on.
B $C00C,1,1 The map column at which the guardian appears.
W $C00D,2,2 Address of the world's list of position entries, copied by BeginLife to WorldListAddr at $D5D2 ($BE9C-$BE9F).
B $C00F,1,1 The number of entries in the world's list, copied by BeginLife to WorldListCount at $D5DB ($BEA4-$BEA5), the operand of LD B,$00 at $D5DA and read by #R$C169@main and #R$D5E3@main.
W $C010,2,2 The distance from each enemy frame in the first half of the bank's enemy frame area to its counterpart facing the other way in the second half; the area runs from $7696 to the first guardian graphic and this is half its length.
B $C012,1,1 The map column at which the world ends without a guardian kill, and in bit 0 which part of the map it is in.
B $C013,1,1 The attribute of the whole play area in this world.
B $C014,1,1 Low byte of the display-file address at which the world's name is printed in large letters (#R$C4ED@main, D=$48, so row 8 of the screen); it is the column that centres the name, 16 minus the name's length.
W $C015,2,2 Address of the world's name, a '#'-terminated message printed by #R$C4ED@main under WORLD OF (or THE LAST in world 7) on the intro card ($BEC8-$BECF).
b $C017 World 7 second guardian's addresses
D $C017 A second 23-byte header in the layout of #R$C000, but world set-up never selects it (world 7 is reached with an even number of worlds completed). Only bytes 7-8 (the second guardian's path, $B49D) and 9-10 (its graphics record, $B495) are read, by #R$C553@main at $C57D-$C580 when the view position $B95A reaches $046E; $C586 then sets $B951 to 1.
D $C017 The other bytes are never used to set up a world; only bytes 3-4 (zero) are also read, by the map transform #R$BCE6@main when a game ends in world 7, so it covers world 7's map alone. Bytes 1-4, 13-15 and 21-22 are zero, and bytes 11-12 hold $FF as in world 7's own header. Bytes 5-6 hold bank 7's cell table address, and byte 0, bytes 16-17 and bytes 18-20 hold the values of bank 3's headers (the lowest solid block code, the frame offset, world 1's end column, world 2's play area attribute and the name column), so this looks like a header copied from bank 3 and partly cleared.
@ $C017 label=W7GuardianHeader
B $C017,1,1 The lowest block code that is solid.
W $C018,2,2 Address of the world's map (eight cells a column).
W $C01A,2,2 Length of the world's map in bytes (a multiple of 8).
W $C01C,2,2 Address of the bank's table of 16x16 map cell graphics (32 bytes each, block code $60 first).
W $C01E,2,2 Address of the guardian's path, a list of two-byte display-file addresses (bit 7 of the high byte picks the second graphics record) ended by $FF.
W $C020,2,2 Address of the guardian's graphics record, two 8-byte entries (for each, the address, width in bytes and height in lines of the left part, then of the right part; masked graphics).
B $C022,1,1 The map code a type 4 enemy starts on.
B $C023,1,1 The map column at which the guardian appears.
W $C024,2,2 Address of the world's list of position entries, copied by BeginLife to WorldListAddr at $D5D2 ($BE9C-$BE9F).
B $C026,1,1 The number of entries in the world's list, copied by BeginLife to WorldListCount at $D5DB ($BEA4-$BEA5), the operand of LD B,$00 at $D5DA and read by #R$C169@main and #R$D5E3@main.
W $C027,2,2 The distance from each enemy frame in the first half of the bank's enemy frame area to its counterpart facing the other way in the second half; the area runs from $7696 to the first guardian graphic and this is half its length.
B $C029,1,1 The map column at which the world ends without a guardian kill, and in bit 0 which part of the map it is in.
B $C02A,1,1 The attribute of the whole play area in this world.
B $C02B,1,1 Low byte of the display-file address at which the world's name is printed in large letters (#R$C4ED@main, D=$48, so row 8 of the screen); it is the column that centres the name, 16 minus the name's length.
W $C02C,2,2 Address of the world's name, a '#'-terminated message printed by #R$C4ED@main under WORLD OF (or THE LAST in world 7) on the intro card ($BEC8-$BECF).
w $C02E Enemy template addresses for world 7
D $C02E Four words after the second header, shared by world 7. The first ($768E) is the address of the enemy template table (#R$FF46), which #R$C553@main indexes with the low five bits of a start list entry at $C675-$C682. The other three address the templates the main loop starts without a list entry: $7690 type 4 (at a map cell holding header byte 11, $C6D0), $7692 type 7 (at random at either edge, $C5C2) and $7694 type 6 (at alternating edges, $C5E8); they are the table's fourth, seventh and sixth entries. In world 7 the type 4 word is zero, and so is the fourth template.
@ $C02E label=W7TemplateAddrs
W $C02E,8,2
b $C036 Left-facing enemy frames for world 7
D $C036 The first half of the bank's enemy frame area, $7696-$8195 in the world area (2816 bytes). Each enemy template (#R$FF46) gives a frame address, a width in bytes and a height in lines, and every template's graphic here has two frames, one after the other: type 1 at $7696 (24x32), type 2 at $7816 (24x32), type 6 at $7996 (24x32), type 3 at $7B16 (32x32), type 5 at $7D16 (24x32), type 8 at $7E96 (24x32), type 9 at $8016 (24x32). The frames tile the half exactly, in address order.
D $C036 Each line is a mask byte then a graphic byte for each 8 pixels, bit 7 leftmost, drawn as (screen AND mask) OR graphic by the masked sprite drawers. The main loop (#R$C553@main, $CC4B-$CC6C) picks the frame from the enemy slot's byte 9. The type 7 template points to the flame and bomb frames at $6FA0 in the main program instead.
@ $C036 label=W7EnemyFrames
B $C036,2816,6*192,8*64,6
b $CB36 Right-facing enemy frames for world 7
D $CB36 The second half of the enemy frame area, $8196-$8C95 in the world area, laid out exactly like #R$C036: each frame here is 2816 bytes (header bytes 16-17) after its counterpart. #R$C553@main adds that offset at $CC7D-$CC80 for an enemy whose slot byte 9 has bit 7 set (one moving right: #R$DD41@main sets the bit for an enemy started in the left half and the movers flip it when the enemy turns), except for type 7. The first half (#R$C036) shows the enemies facing left, this half facing right.
D $CB36 They are the enemies facing the other way, but not all are plain mirror images: 6 of the 14 frames are exact bit-for-bit mirrors of their counterparts; the others differ in some lines and were drawn separately.
@ $CB36 label=W7EnemyFramesTurned
B $CB36,2816,6*192,8*64,6
b $D636 First guardian graphics for world 7
D $D636 $8C96-$8F95 in the world area: the first guardian's two frames, each a left and a right part 16 pixels wide and 48 lines high (192 bytes each), in the masked format (a mask byte before each graphic byte). The graphics record #R$FE25 gives each part's address and size; #R$D513@main draws the left part at the path's display address and the right part beside it. The second guardian's graphics follow at #R$D936.
@ $D636 label=W7GuardianGfx
B $D636,768,4
b $D936 Second guardian graphics for world 7
D $D936 $8F96-$9115 in the world area: one frame of world 7's second guardian, a left part 32 pixels wide (256 bytes) and a right part 16 pixels wide (128 bytes), both 32 lines high and masked. Its record is #R$FE35, one 8-byte entry: no entry in its path (#R$FE3D) has bit 7 set, so the 8 bytes after the record, which are the start of the path, are never used as a second entry.
@ $D936 label=W7Guardian2Gfx
B $D936,384,8*32,4
b $DAB6 World 7 map
D $DAB6 $9116-$A3C5 in the world area, at header bytes 1-4 ($7661): 598 map columns of eight cell codes each, top cell first, all in one part. World 7 has no lower part in use: the bottom row is solid along the whole map except for two short stretches (columns 301-306, and 520, 523 and 526-529 within columns 520-529), and those holes are closed off by solid cells above and beside them, so the player never falls to row 12 and the move to the lower part at $D42B@main never happens; the recording played the world with LowerScreen ($B957) at 0 throughout. (Were it to happen, the window would simply move 208 columns further along this same map.)
D $DAB6 Play starts with the map window ($BA17) at column 4 ($BE16-$BE1B), the player in column 10. In the recording the window ranged over columns 4-568. Nothing checks the window against the map's ends; walls in the map stop the player (#R$DD58@main).
D $DAB6 Cells: 20 item boxes ($60-$78), 6 stepping cells ($79/$7A), 32 climbable cells ($80/$B2), 379 breakable blocks ($C6 and up), no type 4 spawn cells; codes from $9F (header byte 0) up are solid. The codes and what play does to them are described at #R$DDFD@main, #R$DB90@main and #R$D65E@main.
@ $DAB6 label=W7Map
B $DAB6,4784,8
b $ED66 Map cell graphics for world 7
D $ED66 $A3C6-$B425 in the world area: 131 pictures of 16x16 pixels, 32 bytes each, two bytes a line, one bit a pixel (bit 7 leftmost); block code $60+n is entry n (header bytes 5-6; #R$DDFD@main). Entries 0-23 are the item pictures (map codes $2E-$45). The entries for codes $79 and $7A are blank here; world set-up (#R$BDC0@main, $BE27-$BE40) fills both with the picture of code $81 in the first world or $82 in the second, which are that world's background ($81 is the same picture as $93), so those cells look like background. The background block is code $93 or $82 (the operand at $CECA) and the block drawn over every item code is $C7 or $C8 (the operand at $DE09). Header byte 0 is the lowest solid code.
@ $ED66 label=W7Cells
B $ED66,4192,2
b $FDC6 Path of world 7's first guardian
D $FDC6 The guardian's path: two-byte display-file addresses, one taken per main loop pass by #R$D513@main, ended by $FF in place of an entry's low byte (no entry's low byte is $FF), after which the path starts again. Bit 7 of an entry's high byte selects the second pair of parts in the guardian record. #R$C553@main plants the address from header word $7667 when the map column reaches the header's guardian column.
D $FDC6 World 7's first guardian (header word $7667) has 47 entries, eleven with bit 7 set. It starts when $B95A reaches $023A, but also whenever the map column at $B95C reaches 255 (the header's guardian column is $FF and the column wraps in this long map), which the recording shows at $B95A=$01FE and $03FE.
@ $FDC6 label=W7GuardianPath
W $FDC6,94,2
B $FE24,1,1
b $FE25 Graphics record of world 7's first guardian
D $FE25 The guardian's graphics record, addressed by header word $7669: four parts of four bytes each, a masked graphic's address, its width in screen bytes and its lines. #R$D513@main draws parts 1 and 2 side by side, or parts 3 and 4 when the path entry has bit 7 set. The graphics follow the enemy frame area, from $7696 plus twice the $CC7E operand.
D $FE25 All four parts here are two bytes wide and 48 lines.
@ $FE25 label=W7GuardianRecord
W $FE25,2,2
B $FE27,2,2
W $FE29,2,2
B $FE2B,2,2
W $FE2D,2,2
B $FE2F,2,2
W $FE31,2,2
B $FE33,2,2
b $FE35 Graphics record of world 7's final guardian
D $FE35 The final guardian's record, addressed by the second header's word at $7680 and planted by #R$C553@main when $B95A reaches $046E. Only two parts (eight bytes): a four-byte-wide and a two-byte-wide part of 32 lines. Its path has no entry with bit 7 set, so #R$D513@main never reads the eight bytes after it (the start of the path).
@ $FE35 label=W7FinalGuardianRecord
W $FE35,2,2
B $FE37,2,2
W $FE39,2,2
B $FE3B,2,2
b $FE3D Path of world 7's final guardian
D $FE3D The guardian's path: two-byte display-file addresses, one taken per main loop pass by #R$D513@main, ended by $FF in place of an entry's low byte (no entry's low byte is $FF), after which the path starts again. Bit 7 of an entry's high byte selects the second pair of parts in the guardian record. #R$C553@main plants this path's address from the second header's word at $767E, with the record from $7680, when $B95A reaches $046E ($C571-$C589), and sets $B951 to 1.
D $FE3D The final guardian's path (second header word $767E) has 49 entries, none with bit 7 set. Destroying this guardian ($B951=1) leads to the congratulations message.
@ $FE3D label=W7FinalGuardianPath
W $FE3D,98,2
B $FE9F,1,1
t $FEA0 World 7 name
D $FEA0 WORLD: the name BeginLife (#R$BDC0@main, $BEC8-$BECF) prints in large letters on row 8 of world 7's intro card, from header bytes 21-22 at the column in byte 20, under THE LAST (which world 7 gets in place of WORLD OF, $BE6B-$BE7A), so the card reads THE LAST WORLD. It ends with '#', the terminator of #R$C4ED@main.
@ $FEA0 label=W7Name
T $FEA0,6,6
b $FEA6 Enemy start list for world 7
D $FEA6 World 7's list of 40 enemy starts, addressed by bytes 13-15 of the header at $7660. World 7's map is longer than 256 columns, so its entries are four bytes and are looked up by #R$D5E3@main (planted in place of #R$D5D1@main by BeginLife): a two-byte position matched against $B95A (the scroll position divided by 4), then the row with its started flag and the part, side and template byte, as in the other worlds' three-byte entries. The entries are in position order and all are for the upper part.
D $FEA6 The list is damaged before world 7 is ever played: #R$C169@main walks world 6's list positions over it at the world change, clearing bit 7 of nine bytes. Six enemies (entries 6, 12, 15, 21, 24 and 30) then start 128 positions (64 map columns) early, and three (12, 24 and 27) at the left edge instead of the right. #R$C169@main's own three-byte walk would damage more of it after a lost life or a change of part in world 7.
@ $FEA6 label=W7EnemyList
B $FEA6,160,4
b $FF46 Enemy templates for world 7
D $FF46 The enemy template table for world 7 (word $768E): nine five-byte slots for types 1-9, of which the fourth (type 4) is all zeros and the word at $7690 is 0; world 7 has no type 4 enemy, and its type 4 random spawn looks for cell code $FF (header byte 11), which never occurred in the recording. Each template is five bytes, copied into an enemy slot's bytes 4-8 by #R$DD41@main: width in screen bytes, lines, the address of the first of its frames, and the type, which is always the template number plus 1. #R$C553@main indexes the table with the template number from a list entry, and the words at $7690, $7692 and $7694 point at the type 4, 7 and 6 templates for the random spawns. Type 7's frames are at $6FA0 in the main program, the same in every world; the others are in this bank's frame area from $7696, with the frames for moving right at the $CC7E operand further on.
D $FF46 The congratulations message follows the table.
@ $FF46 label=W7EnemyTemplates
B $FF46,45,5
t $FF73 Congratulations message
D $FF73 The message shown when world 7's final guardian is destroyed: #R$D77A@main clears the play area and prints it from world-area $B5D3 at row 2, column 6 with #R$C292@main ($D85C-$D862), then plays tune 12 and waits for a key before the ending. It uses the printer's codes: $FF for a new row, $FC n to skip n columns and '#' to end, and the font's '<' for a full stop. It is longer than the bank: the last 51 bytes, including the '#', are the start of the 85 bytes #R$B8C3@main copies from bank 1 (bank 1 $C0FF, loaded at $B660).
@ $FF73 label=W7Congratulations
T $FF73,141,17:n2,19:n1*2,18:n1,17:n1,19:n1,18:n2,5
