@ $C000 start
@ $C000 org
b $C000 World 5 header
D $C000 The header of world 5, the first world in this bank, at $7660 once #R$B8C3@main has copied the bank. #R$BDC0@main chooses it when bit 0 of the number of worlds completed is 0: it takes the map address through IX, plants the header's address at $BE88, and BeginLife copies bytes 0 and 11-22 into instruction operands at the start of every life. Nothing writes to the header.
D $C000 Byte 0: the lowest solid block code, copied to the operand at $DB91 of #R$DB90@main. Bytes 1-2: the map's address; the first map window ($BA17) is 32 bytes on. Bytes 3-4: the map's length, read only by #R$BCE6@main. Bytes 5-6: the cell table's address. Bytes 7-8: the guardian path's address. Bytes 9-10: the guardian graphics record's address. Byte 11: the map code type 4 enemies start on (to $C6AC). Byte 12: the map column at which the guardian appears (to $C58F). Bytes 13-14: the start list's address (to $D5D2). Byte 15: the number of list entries (to $D5DB). Bytes 16-17: the distance from each first-half enemy frame to its copy in the second half (to $CC7E). Byte 18: the end-of-map column, with bit 0 set when it is in the lower part of the map (to $D046, and as a JP NZ or JP Z opcode to $D03F). Byte 19: the play area attribute (#R$C07C@main). Byte 20: the column of the name on row 8. Bytes 21-22: the name's address.
D $C000 World 5: the name is SEA; the map is at $8CD6, 403 columns of eight cells; the guardian appears at map column 189; the start list has 47 entries; the play area is green ink on black; the end-of-map column is in the lower part, column 181.
@ $C000 label=W5Header
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
b $C017 World 6 header
D $C017 The header of world 6, the second world in this bank, at $7677 once #R$B8C3@main has copied the bank. #R$BDC0@main chooses it when bit 0 of the number of worlds completed is 1: it takes the map address through IX, plants the header's address at $BE88, and BeginLife copies bytes 0 and 11-22 into instruction operands at the start of every life. Nothing writes to the header.
D $C017 Byte 0: the lowest solid block code, copied to the operand at $DB91 of #R$DB90@main. Bytes 1-2: the map's address; the first map window ($BA17) is 32 bytes on. Bytes 3-4: the map's length, read only by #R$BCE6@main. Bytes 5-6: the cell table's address. Bytes 7-8: the guardian path's address. Bytes 9-10: the guardian graphics record's address. Byte 11: the map code type 4 enemies start on (to $C6AC). Byte 12: the map column at which the guardian appears (to $C58F). Bytes 13-14: the start list's address (to $D5D2). Byte 15: the number of list entries (to $D5DB). Bytes 16-17: the distance from each first-half enemy frame to its copy in the second half (to $CC7E). Byte 18: the end-of-map column, with bit 0 set when it is in the lower part of the map (to $D046, and as a JP NZ or JP Z opcode to $D03F). Byte 19: the play area attribute (#R$C07C@main). Byte 20: the column of the name on row 8. Bytes 21-22: the name's address.
D $C017 World 6: the name is HELL; the map is at $996E, 391 columns of eight cells; the guardian appears at map column 184; the start list has 33 entries; the play area is magenta ink on black; the end-of-map column is in the lower part, column 169. Bytes 5-10 repeat the first header's cell table, path and record addresses; world set-up reads those from the first header only, so this world shares the first world's guardian.
@ $C017 label=W6Header
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
w $C02E Enemy template addresses for worlds 5 and 6
D $C02E Four words after the second header, shared by worlds 5 and 6. The first ($768E) is the address of the enemy template table (#R$FF20), which #R$C553@main indexes with the low five bits of a start list entry at $C675-$C682. The other three address the templates the main loop starts without a list entry: $7690 type 4 (at a map cell holding header byte 11, $C6D0), $7692 type 7 (at random at either edge, $C5C2) and $7694 type 6 (at alternating edges, $C5E8); they are the table's fourth, seventh and sixth entries.
@ $C02E label=W56TemplateAddrs
W $C02E,8,2
b $C036 Left-facing enemy frames for worlds 5 and 6
D $C036 The first half of the bank's enemy frame area, $7696-$7FD5 in the world area (2368 bytes). Each enemy template (#R$FF20) gives a frame address, a width in bytes and a height in lines, and every template's graphic here has two frames, one after the other: type 4 at $7696 (16x16), type 1 at $7716 (24x32), type 2 at $7896 (24x16), type 3 at $7956 (24x32), type 5 at $7AD6 (24x32), type 8 at $7C56 (32x32), type 6 at $7E56 (24x32). The frames tile the half exactly, in address order.
D $C036 Each line is a mask byte then a graphic byte for each 8 pixels, bit 7 leftmost, drawn as (screen AND mask) OR graphic by the masked sprite drawers. The main loop (#R$C553@main, $CC4B-$CC6C) picks the frame from the enemy slot's byte 9. The type 7 template points to the flame and bomb frames at $6FA0 in the main program instead.
@ $C036 label=W56EnemyFrames
B $C036,2368,4*32,6*224,8*64,6
b $C976 Right-facing enemy frames for worlds 5 and 6
D $C976 The second half of the enemy frame area, $7FD6-$8915 in the world area, laid out exactly like #R$C036: each frame here is 2368 bytes (header bytes 16-17) after its counterpart. #R$C553@main adds that offset at $CC7D-$CC80 for an enemy whose slot byte 9 has bit 7 set (one moving right: #R$DD41@main sets the bit for an enemy started in the left half and the movers flip it when the enemy turns), except for type 7. The first half (#R$C036) shows the enemies facing left, this half facing right.
D $C976 They are the enemies facing the other way, but not all are plain mirror images: 10 of the 14 frames are exact bit-for-bit mirrors of their counterparts; the others differ in some lines and were drawn separately.
@ $C976 label=W56EnemyFramesTurned
B $C976,2368,4*32,6*224,8*64,6
b $D2B6 Guardian graphics for worlds 5 and 6
D $D2B6 $8916-$8CD5 in the world area: two frames, each a left part 32 pixels wide and a right part 16 pixels wide, 40 lines high (320 and 160 bytes), in the masked format (a mask byte before each graphic byte). The graphics record #R$FE17 gives each part's address and size; #R$D513@main draws the left part at the path's display address and the right part beside it. The two worlds share it: world set-up takes the path and record from the first header only.
@ $D2B6 label=W56GuardianGfx
B $D2B6,960,8*40,4*40,8*40,4
b $D676 World 5 map
D $D676 $8CD6-$996D in the world area, at header bytes 1-4 of the first header ($7661): 403 map columns of eight cell codes each, top cell first. The first 208 columns ($0680 bytes, bank $D676-$DCF5) are the upper part and the other 195 (from bank $DCF6) the lower part. A column of the lower part lies $0680 bytes after the upper column above it: falling off the bottom of the screen moves the map window $0680 bytes on and climbing out of the top moves it back (#R$D38B@main at $D42B-$D494), so the two parts line up column for column.
D $D676 Columns that the recording never shows are filled with $00 (lower-part columns 0-3), which #R$DDFD@main draws as the background block.
D $D676 Play starts with the map window ($BA17) at column 4 ($BE16-$BE1B), the player in column 10. In the recording the window (the leftmost column shown) ranged over columns 4-191 of the upper part and 10-105 of the lower part. Nothing checks the window against the map's ends; walls in the map stop the player (#R$DD58@main).
D $D676 Cells: 33 item boxes ($60-$78), 9 stepping cells ($79/$7A), 0 climbable cells ($80/$B2), 194 breakable blocks ($C6 and up), 6 type 4 spawn cells (code $8E, header byte 11); codes from $A4 (header byte 0) up are solid. The codes and what play does to them are described at #R$DDFD@main, #R$DB90@main and #R$D65E@main.
@ $D676 label=W5Map
B $D676,1664,8
N $DCF6 The lower part: map columns 208-402, each $0680 bytes below the upper column it lies under.
B $DCF6,1560,8
b $E30E World 6 map
D $E30E $996E-$A5A5 in the world area, at header bytes 1-4 of the second header ($7678): 391 map columns of eight cell codes each, top cell first. The first 208 columns ($0680 bytes, bank $E30E-$E98D) are the upper part and the other 183 (from bank $E98E) the lower part. A column of the lower part lies $0680 bytes after the upper column above it: falling off the bottom of the screen moves the map window $0680 bytes on and climbing out of the top moves it back (#R$D38B@main at $D42B-$D494), so the two parts line up column for column.
D $E30E Columns that the recording never shows are filled with $00 (lower-part columns 0-9), which #R$DDFD@main draws as the background block.
D $E30E Play starts with the map window ($BA17) at column 4 ($BE16-$BE1B), the player in column 10. In the recording the window (the leftmost column shown) ranged over columns 4-185 of the upper part and 49-60 of the lower part. Nothing checks the window against the map's ends; walls in the map stop the player (#R$DD58@main).
D $E30E Cells: 35 item boxes ($60-$78), 9 stepping cells ($79/$7A), 23 climbable cells ($80/$B2), 383 breakable blocks ($C6 and up), 2 type 4 spawn cells (code $8E, header byte 11); codes from $A6 (header byte 0) up are solid. The codes and what play does to them are described at #R$DDFD@main, #R$DB90@main and #R$D65E@main.
@ $E30E label=W6Map
B $E30E,1664,8
N $E98E The lower part: map columns 208-390, each $0680 bytes below the upper column it lies under.
B $E98E,1464,8
b $EF46 Map cell graphics for worlds 5 and 6
D $EF46 $A5A6-$B425 in the world area: 116 pictures of 16x16 pixels, 32 bytes each, two bytes a line, one bit a pixel (bit 7 leftmost); block code $60+n is entry n (header bytes 5-6; #R$DDFD@main). Both worlds of the bank use this table. Entries 0-23 are the item pictures (map codes $2E-$45). The entries for codes $79 and $7A are blank here; world set-up (#R$BDC0@main, $BE27-$BE40) fills both with the picture of code $81 in the first world or $82 in the second, which are that world's background ($81 is the same picture as $93), so those cells look like background. The background block is code $93 or $82 (the operand at $CECA) and the block drawn over every item code is $C7 or $C8 (the operand at $DE09). Header byte 0 is the lowest solid code.
@ $EF46 label=W56Cells
B $EF46,3712,2
b $FDC6 Guardian path for worlds 5 and 6
D $FDC6 The guardian's path: two-byte display-file addresses, one taken per main loop pass by #R$D513@main, ended by $FF in place of an entry's low byte (no entry's low byte is $FF), after which the path starts again. Bit 7 of an entry's high byte selects the second pair of parts in the guardian record. #R$C553@main plants the address from header word $7667 when the map column reaches the header's guardian column.
D $FDC6 Worlds 5 and 6 share this path (40 entries, 20 with bit 7 set) and the record after it.
@ $FDC6 label=W56GuardianPath
W $FDC6,80,2
B $FE16,1,1
b $FE17 Guardian graphics record for worlds 5 and 6
D $FE17 The guardian's graphics record, addressed by header word $7669: four parts of four bytes each, a masked graphic's address, its width in screen bytes and its lines. #R$D513@main draws parts 1 and 2 side by side, or parts 3 and 4 when the path entry has bit 7 set. The graphics follow the enemy frame area, from $7696 plus twice the $CC7E operand.
D $FE17 All four parts are 40 lines; parts 1 and 3 are four bytes wide, parts 2 and 4 two.
@ $FE17 label=W56GuardianRecord
W $FE17,2,2
B $FE19,2,2
W $FE1B,2,2
B $FE1D,2,2
W $FE1F,2,2
B $FE21,2,2
W $FE23,2,2
B $FE25,2,2
t $FE27 World 5 name
D $FE27 Sea: the name BeginLife (#R$BDC0@main, $BEC8-$BECF) prints in large letters on row 8 of the world's intro card, from header bytes 21-22 at the column in byte 20, under WORLD OF. It ends with '#', the terminator of #R$C4ED@main.
@ $FE27 label=W5Name
T $FE27,4,4
t $FE2B World 6 name
D $FE2B Hell: the name BeginLife (#R$BDC0@main, $BEC8-$BECF) prints in large letters on row 8 of the world's intro card, from header bytes 21-22 at the column in byte 20, under WORLD OF. It ends with '#', the terminator of #R$C4ED@main.
@ $FE2B label=W6Name
T $FE2B,5,5
b $FE30 Enemy start list for world 5
D $FE30 World 5's list of 47 enemy starts, addressed by bytes 13-15 of the header at $7660. Each entry is three bytes: the map column at which the enemy starts (matched against $B95C by #R$D5D1@main, which takes the first match); the row in bits 0-6 with bit 7 set while the entry's enemy is started (#R$C553@main at $C654, cleared by #R$D909@main and #R$C169@main); and the part of the map in bit 6 (0 upper, 1 lower, against $B957), the side in bit 7 (0 left edge, 1 right edge) and the template number in bits 0-4, an index into the template table at word $768E.
D $FE30 Entries 34, 39 and 43 repeat the columns of entries 5, 7 and 8, so they can never be found.
@ $FE30 label=W5EnemyList
B $FE30,141,3
b $FEBD Enemy start list for world 6
D $FEBD World 6's list of 33 enemy starts (header at $7677); the format is as for #R$FE30 (world 5's list). Entries 8 and 25 repeat entry 7's column, and 29 and 32 repeat 10 and 12, so those four can never be found.
D $FEBD When world 7 loads, #R$C169@main walks this list's positions over world 7's list (see world 7's list in bank 7).
@ $FEBD label=W6EnemyList
B $FEBD,99,3
b $FF20 Enemy templates for worlds 5 and 6
D $FF20 The enemy template table for worlds 5 and 6 (word $768E): eight templates, types 1-8. Each template is five bytes, copied into an enemy slot's bytes 4-8 by #R$DD41@main: width in screen bytes, lines, the address of the first of its frames, and the type, which is always the template number plus 1. #R$C553@main indexes the table with the template number from a list entry, and the words at $7690, $7692 and $7694 point at the type 4, 7 and 6 templates for the random spawns. Type 7's frames are at $6FA0 in the main program, the same in every world; the others are in this bank's frame area from $7696, with the frames for moving right at the $CC7E operand further on.
D $FF20 Zeros follow it to the end of the bank.
@ $FF20 label=W56EnemyTemplates
B $FF20,40,5
s $FF48 Unused
D $FF48 184 zero bytes to the end of the bank ($B5A8-$B65F in the world area); bank 6's 85 bytes in bank 1 are zero too. When world 5 follows world 4, the leftover walk of world 4's start list (#R$C169@main) clears bit 7 of $B65F and of bytes in the tail from bank 1, all already zero.
@ $FF48 label=W56Unused
S $FF48,184,$B8
