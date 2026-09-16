@ $C000 start
@ $C000 org
b $C000 World 1 header
D $C000 The header of world 1, the first world in this bank, at $7660 once #R$B8C3@main has copied the bank. #R$BDC0@main chooses it when bit 0 of the number of worlds completed is 0: it takes the map address through IX, plants the header's address at $BE88, and BeginLife copies bytes 0 and 11-22 into instruction operands at the start of every life. Nothing writes to the header.
D $C000 Byte 0: the lowest solid block code, copied to the operand at $DB91 of #R$DB90@main. Bytes 1-2: the map's address; the first map window ($BA17) is 32 bytes on. Bytes 3-4: the map's length, read only by #R$BCE6@main. Bytes 5-6: the cell table's address. Bytes 7-8: the guardian path's address. Bytes 9-10: the guardian graphics record's address. Byte 11: the map code type 4 enemies start on (to $C6AC). Byte 12: the map column at which the guardian appears (to $C58F). Bytes 13-14: the start list's address (to $D5D2). Byte 15: the number of list entries (to $D5DB). Bytes 16-17: the distance from each first-half enemy frame to its copy in the second half (to $CC7E). Byte 18: the end-of-map column, with bit 0 set when it is in the lower part of the map (to $D046, and as a JP NZ or JP Z opcode to $D03F). Byte 19: the play area attribute (#R$C07C@main). Byte 20: the column of the name on row 8. Bytes 21-22: the name's address.
D $C000 World 1: the name is FOREST; the map is at $8A96, 395 columns of eight cells; the guardian appears at map column 187; the start list has 28 entries; the play area is bright cyan ink on black; the end-of-map column is in the lower part, column 173.
@ $C000 label=W1Header
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
b $C017 World 2 header
D $C017 The header of world 2, the second world in this bank, at $7677 once #R$B8C3@main has copied the bank. #R$BDC0@main chooses it when bit 0 of the number of worlds completed is 1: it takes the map address through IX, plants the header's address at $BE88, and BeginLife copies bytes 0 and 11-22 into instruction operands at the start of every life. Nothing writes to the header.
D $C017 Byte 0: the lowest solid block code, copied to the operand at $DB91 of #R$DB90@main. Bytes 1-2: the map's address; the first map window ($BA17) is 32 bytes on. Bytes 3-4: the map's length, read only by #R$BCE6@main. Bytes 5-6: the cell table's address. Bytes 7-8: the guardian path's address. Bytes 9-10: the guardian graphics record's address. Byte 11: the map code type 4 enemies start on (to $C6AC). Byte 12: the map column at which the guardian appears (to $C58F). Bytes 13-14: the start list's address (to $D5D2). Byte 15: the number of list entries (to $D5DB). Bytes 16-17: the distance from each first-half enemy frame to its copy in the second half (to $CC7E). Byte 18: the end-of-map column, with bit 0 set when it is in the lower part of the map (to $D046, and as a JP NZ or JP Z opcode to $D03F). Byte 19: the play area attribute (#R$C07C@main). Byte 20: the column of the name on row 8. Bytes 21-22: the name's address.
D $C017 World 2: the name is CAVERN; the map is at $96EE, 392 columns of eight cells; the guardian appears at map column 191; the start list has 22 entries; the play area is yellow ink on black; the end-of-map column is in the lower part, column 169. Bytes 5-10 repeat the first header's cell table, path and record addresses; world set-up reads those from the first header only, so this world shares the first world's guardian.
@ $C017 label=W2Header
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
w $C02E Enemy template addresses for worlds 1 and 2
D $C02E Four words after the second header, shared by worlds 1 and 2. The first ($768E) is the address of the enemy template table (#R$FC3F), which #R$C553@main indexes with the low five bits of a start list entry at $C675-$C682. The other three address the templates the main loop starts without a list entry: $7690 type 4 (at a map cell holding header byte 11, $C6D0), $7692 type 7 (at random at either edge, $C5C2) and $7694 type 6 (at alternating edges, $C5E8); they are the table's fourth, seventh and sixth entries.
@ $C02E label=W12TemplateAddrs
W $C02E,8,2
b $C036 Left-facing enemy frames for worlds 1 and 2
D $C036 The first half of the bank's enemy frame area, $7696-$7E55 in the world area (1984 bytes). Each enemy template (#R$FC3F) gives a frame address, a width in bytes and a height in lines, and every template's graphic here has two frames, one after the other: type 1 at $7696 (32x32), type 2 at $7896 (24x16), type 3 at $7956 (24x32), type 4 at $7AD6 (16x16), type 5 at $7B56 (24x32), type 6 at $7CD6 (24x32). The frames tile the half exactly, in address order.
D $C036 Each line is a mask byte then a graphic byte for each 8 pixels, bit 7 leftmost, drawn as (screen AND mask) OR graphic by the masked sprite drawers. The main loop (#R$C553@main, $CC4B-$CC6C) picks the frame from the enemy slot's byte 9. The type 7 template points to the flame and bomb frames at $6FA0 in the main program instead.
@ $C036 label=W12EnemyFrames
B $C036,1984,8*64,6*96,4*32,6
b $C7F6 Right-facing enemy frames for worlds 1 and 2
D $C7F6 The second half of the enemy frame area, $7E56-$8615 in the world area, laid out exactly like #R$C036: each frame here is 1984 bytes (header bytes 16-17) after its counterpart. #R$C553@main adds that offset at $CC7D-$CC80 for an enemy whose slot byte 9 has bit 7 set (one moving right: #R$DD41@main sets the bit for an enemy started in the left half and the movers flip it when the enemy turns), except for type 7. The first half (#R$C036) shows the enemies facing left, this half facing right.
D $C7F6 They are the enemies facing the other way, but not all are plain mirror images: 4 of the 12 frames are exact bit-for-bit mirrors of their counterparts; the others differ in some lines and were drawn separately.
@ $C7F6 label=W12EnemyFramesTurned
B $C7F6,1984,8*64,6*96,4*32,6
b $CFB6 Guardian graphics for worlds 1 and 2
D $CFB6 $8616-$8A95 in the world area: two frames, each a left part 32 pixels wide and a right part 16 pixels wide, 48 lines high (384 and 192 bytes), in the masked format (a mask byte before each graphic byte). The graphics record #R$FB8B gives each part's address and size; #R$D513@main draws the left part at the path's display address and the right part beside it. The two worlds share it: world set-up takes the path and record from the first header only.
@ $CFB6 label=W12GuardianGfx
B $CFB6,1152,8*48,4*48,8*48,4
b $D436 World 1 map
D $D436 $8A96-$96ED in the world area, at header bytes 1-4 of the first header ($7661): 395 map columns of eight cell codes each, top cell first. The first 208 columns ($0680 bytes, bank $D436-$DAB5) are the upper part and the other 187 (from bank $DAB6) the lower part. A column of the lower part lies $0680 bytes after the upper column above it: falling off the bottom of the screen moves the map window $0680 bytes on and climbing out of the top moves it back (#R$D38B@main at $D42B-$D494), so the two parts line up column for column.
D $D436 Two runs of columns are filled with $00, lower-part columns 0-33 and 115-116; #R$DDFD@main draws them as the background block. The recording never enters world 1's lower part, so it never shows them.
D $D436 Play starts with the map window ($BA17) at column 4 ($BE16-$BE1B), the player in column 10. In the recording the window (the leftmost column shown) ranged over columns 4-189 of the upper part and the lower part was never entered. Nothing checks the window against the map's ends; walls in the map stop the player (#R$DD58@main).
D $D436 Cells: 44 item boxes ($60-$78), 4 stepping cells ($79/$7A), 55 climbable cells ($80/$B2), 241 breakable blocks ($C6 and up), 10 type 4 spawn cells (code $9F, header byte 11); codes from $AE (header byte 0) up are solid. The codes and what play does to them are described at #R$DDFD@main, #R$DB90@main and #R$D65E@main.
@ $D436 label=W1Map
B $D436,1664,8
N $DAB6 The lower part: map columns 208-394, each $0680 bytes below the upper column it lies under.
B $DAB6,1496,8
b $E08E World 2 map
D $E08E $96EE-$A32D in the world area, at header bytes 1-4 of the second header ($7678): 392 map columns of eight cell codes each, top cell first. The first 208 columns ($0680 bytes, bank $E08E-$E70D) are the upper part and the other 184 (from bank $E70E) the lower part. A column of the lower part lies $0680 bytes after the upper column above it: falling off the bottom of the screen moves the map window $0680 bytes on and climbing out of the top moves it back (#R$D38B@main at $D42B-$D494), so the two parts line up column for column.
D $E08E Columns that the recording never shows are filled with $00 (lower-part columns 0-16), which #R$DDFD@main draws as the background block.
D $E08E Play starts with the map window ($BA17) at column 4 ($BE16-$BE1B), the player in column 10. In the recording the window (the leftmost column shown) ranged over columns 4-191 of the upper part and 28-155 of the lower part. Nothing checks the window against the map's ends; walls in the map stop the player (#R$DD58@main).
D $E08E Cells: 34 item boxes ($60-$78), 2 stepping cells ($79/$7A), 64 climbable cells ($80/$B2), 418 breakable blocks ($C6 and up), no type 4 spawn cells; codes from $AE (header byte 0) up are solid. The codes and what play does to them are described at #R$DDFD@main, #R$DB90@main and #R$D65E@main.
@ $E08E label=W2Map
B $E08E,1664,8
N $E70E The lower part: map columns 208-391, each $0680 bytes below the upper column it lies under.
B $E70E,1472,8
b $ECCE Map cell graphics for worlds 1 and 2
D $ECCE $A32E-$B1AD in the world area: 116 pictures of 16x16 pixels, 32 bytes each, two bytes a line, one bit a pixel (bit 7 leftmost); block code $60+n is entry n (header bytes 5-6; #R$DDFD@main). Both worlds of the bank use this table. Entries 0-23 are the item pictures (map codes $2E-$45). The entries for codes $79 and $7A are blank here; world set-up (#R$BDC0@main, $BE27-$BE40) fills both with the picture of code $81 in the first world or $82 in the second, which are that world's background ($81 is the same picture as $93), so those cells look like background. The background block is code $93 or $82 (the operand at $CECA) and the block drawn over every item code is $C7 or $C8 (the operand at $DE09). Header byte 0 is the lowest solid code.
@ $ECCE label=W12Cells
B $ECCE,3712,2
b $FB4E Guardian path for worlds 1 and 2
D $FB4E The guardian's path: two-byte display-file addresses, one taken per main loop pass by #R$D513@main, ended by $FF in place of an entry's low byte (no entry's low byte is $FF), after which the path starts again. Bit 7 of an entry's high byte selects the second pair of parts in the guardian record. #R$C553@main plants the address from header word $7667 when the map column reaches the header's guardian column.
D $FB4E Worlds 1 and 2 share this path and the record after it (both headers hold the same words). It has 30 entries, ten of them with bit 7 set, all with display addresses in the middle third of the screen.
@ $FB4E label=W12GuardianPath
W $FB4E,60,2
B $FB8A,1,1
b $FB8B Guardian graphics record for worlds 1 and 2
D $FB8B The guardian's graphics record, addressed by header word $7669: four parts of four bytes each, a masked graphic's address, its width in screen bytes and its lines. #R$D513@main draws parts 1 and 2 side by side, or parts 3 and 4 when the path entry has bit 7 set. The graphics follow the enemy frame area, from $7696 plus twice the $CC7E operand.
D $FB8B Here every part is 48 lines; parts 1 and 3 are four bytes wide and parts 2 and 4 two, so the guardian is 48 pixels wide.
@ $FB8B label=W12GuardianRecord
W $FB8B,2,2
B $FB8D,2,2
W $FB8F,2,2
B $FB91,2,2
W $FB93,2,2
B $FB95,2,2
W $FB97,2,2
B $FB99,2,2
t $FB9B World 1 name
D $FB9B Forest: the name BeginLife (#R$BDC0@main, $BEC8-$BECF) prints in large letters on row 8 of the world's intro card, from header bytes 21-22 at the column in byte 20, under WORLD OF. It ends with '#', the terminator of #R$C4ED@main.
@ $FB9B label=W1Name
T $FB9B,7,7
t $FBA2 World 2 name
D $FBA2 Cavern: the name BeginLife (#R$BDC0@main, $BEC8-$BECF) prints in large letters on row 8 of the world's intro card, from header bytes 21-22 at the column in byte 20, under WORLD OF. It ends with '#', the terminator of #R$C4ED@main.
@ $FBA2 label=W2Name
T $FBA2,7,7
b $FBA9 Enemy start list for world 1
D $FBA9 World 1's list of 28 enemy starts, addressed by bytes 13-15 of the header at $7660. Each entry is three bytes: the map column at which the enemy starts (matched against $B95C by #R$D5D1@main, which takes the first match); the row in bits 0-6 with bit 7 set while the entry's enemy is started (#R$C553@main at $C654, cleared by #R$D909@main and #R$C169@main); and the part of the map in bit 6 (0 upper, 1 lower, against $B957), the side in bit 7 (0 left edge, 1 right edge) and the template number in bits 0-4, an index into the template table at word $768E.
D $FBA9 The entries are not in column order. Entries 18 and 27 share a column, so entry 27 can never be found.
@ $FBA9 label=W1EnemyList
B $FBA9,84,3
b $FBFD Enemy start list for world 2
D $FBFD World 2's list of 22 enemy starts, addressed by bytes 13-15 of the header at $7677; the format is as for #R$FBA9 (world 1's list). Entries 4 and 13 share a column, so entry 13 can never be found.
@ $FBFD label=W2EnemyList
B $FBFD,66,3
b $FC3F Enemy templates for worlds 1 and 2
D $FC3F The enemy template table for worlds 1 and 2 (word $768E): seven templates, types 1-7. Each template is five bytes, copied into an enemy slot's bytes 4-8 by #R$DD41@main: width in screen bytes, lines, the address of the first of its frames, and the type, which is always the template number plus 1. #R$C553@main indexes the table with the template number from a list entry, and the words at $7690, $7692 and $7694 point at the type 4, 7 and 6 templates for the random spawns. Type 7's frames are at $6FA0 in the main program, the same in every world; the others are in this bank's frame area from $7696, with the frames for moving right at the $CC7E operand further on.
D $FC3F Nothing marks the end of the table; zeros follow it to the end of the bank.
@ $FC3F label=W12EnemyTemplates
B $FC3F,35,5
s $FC62 Unused
D $FC62 926 zero bytes to the end of the bank ($B2C2-$B65F in the world area); bank 3's 85 bytes in bank 1 are zero too. Nothing reads them, except that a new game started after one that ended in worlds 3 to 7 walks that world's leftover start list over part of this area (#R$C169@main), clearing bit 7 of bytes that are already zero.
@ $FC62 label=W12Unused
S $FC62,926,$039E
