@ $C000 start
@ $C000 org
b $C000 World 3 header
D $C000 The header of world 3, the first world in this bank, at $7660 once #R$B8C3@main has copied the bank. #R$BDC0@main chooses it when bit 0 of the number of worlds completed is 0: it takes the map address through IX, plants the header's address at $BE88, and BeginLife copies bytes 0 and 11-22 into instruction operands at the start of every life. Nothing writes to the header.
D $C000 Byte 0: the lowest solid block code, copied to the operand at $DB91 of #R$DB90@main. Bytes 1-2: the map's address; the first map window ($BA17) is 32 bytes on. Bytes 3-4: the map's length, read only by #R$BCE6@main. Bytes 5-6: the cell table's address. Bytes 7-8: the guardian path's address. Bytes 9-10: the guardian graphics record's address. Byte 11: the map code type 4 enemies start on (to $C6AC). Byte 12: the map column at which the guardian appears (to $C58F). Bytes 13-14: the start list's address (to $D5D2). Byte 15: the number of list entries (to $D5DB). Bytes 16-17: the distance from each first-half enemy frame to its copy in the second half (to $CC7E). Byte 18: the end-of-map column, with bit 0 set when it is in the lower part of the map (to $D046, and as a JP NZ or JP Z opcode to $D03F). Byte 19: the play area attribute (#R$C07C@main). Byte 20: the column of the name on row 8. Bytes 21-22: the name's address.
D $C000 World 3: the name is SKY; the map is at $9096, 334 columns of eight cells; the guardian appears at map column 177; the start list has 26 entries; the play area is white ink on black; the end-of-map column is in the upper part, column 83.
@ $C000 label=W3Header
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
b $C017 World 4 header
D $C017 The header of world 4, the second world in this bank, at $7677 once #R$B8C3@main has copied the bank. #R$BDC0@main chooses it when bit 0 of the number of worlds completed is 1: it takes the map address through IX, plants the header's address at $BE88, and BeginLife copies bytes 0 and 11-22 into instruction operands at the start of every life. Nothing writes to the header.
D $C017 Byte 0: the lowest solid block code, copied to the operand at $DB91 of #R$DB90@main. Bytes 1-2: the map's address; the first map window ($BA17) is 32 bytes on. Bytes 3-4: the map's length, read only by #R$BCE6@main. Bytes 5-6: the cell table's address. Bytes 7-8: the guardian path's address. Bytes 9-10: the guardian graphics record's address. Byte 11: the map code type 4 enemies start on (to $C6AC). Byte 12: the map column at which the guardian appears (to $C58F). Bytes 13-14: the start list's address (to $D5D2). Byte 15: the number of list entries (to $D5DB). Bytes 16-17: the distance from each first-half enemy frame to its copy in the second half (to $CC7E). Byte 18: the end-of-map column, with bit 0 set when it is in the lower part of the map (to $D046, and as a JP NZ or JP Z opcode to $D03F). Byte 19: the play area attribute (#R$C07C@main). Byte 20: the column of the name on row 8. Bytes 21-22: the name's address.
D $C017 World 4: the name is LABYRINTH; the map is at $9B06, 386 columns of eight cells; the guardian appears at map column 178; the start list has 28 entries; the play area is cyan ink on black; the end-of-map column is in the lower part, column 255. Bytes 5-10 repeat the first header's cell table, path and record addresses; world set-up reads those from the first header only, so this world shares the first world's guardian.
@ $C017 label=W4Header
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
w $C02E Enemy template addresses for worlds 3 and 4
D $C02E Four words after the second header, shared by worlds 3 and 4. The first ($768E) is the address of the enemy template table (#R$FF83), which #R$C553@main indexes with the low five bits of a start list entry at $C675-$C682. The other three address the templates the main loop starts without a list entry: $7690 type 4 (at a map cell holding header byte 11, $C6D0), $7692 type 7 (at random at either edge, $C5C2) and $7694 type 6 (at alternating edges, $C5E8); they are the table's fourth, seventh and sixth entries.
@ $C02E label=W34TemplateAddrs
W $C02E,8,2
b $C036 Left-facing enemy frames for worlds 3 and 4
D $C036 The first half of the bank's enemy frame area, $7696-$8155 in the world area (2752 bytes). Each enemy template (#R$FF83) gives a frame address, a width in bytes and a height in lines, and every template's graphic here has two frames, one after the other: type 4 at $7696 (16x16), type 1 at $7716 (24x16), type 3 at $77D6 (32x24), type 2 at $7956 (24x32), type 5 at $7AD6 (24x32), type 8 at $7C56 (24x32), type 9 at $7DD6 (32x32), type 6 at $7FD6 (24x32). The frames tile the half exactly, in address order.
D $C036 Each line is a mask byte then a graphic byte for each 8 pixels, bit 7 leftmost, drawn as (screen AND mask) OR graphic by the masked sprite drawers. The main loop (#R$C553@main, $CC4B-$CC6C) picks the frame from the enemy slot's byte 9. The type 7 template points to the flame and bomb frames at $6FA0 in the main program instead.
@ $C036 label=W34EnemyFrames
B $C036,2752,4*32,6*32,8*48,6*192,8*64,6
b $CAF6 Right-facing enemy frames for worlds 3 and 4
D $CAF6 The second half of the enemy frame area, $8156-$8C15 in the world area, laid out exactly like #R$C036: each frame here is 2752 bytes (header bytes 16-17) after its counterpart. #R$C553@main adds that offset at $CC7D-$CC80 for an enemy whose slot byte 9 has bit 7 set (one moving right: #R$DD41@main sets the bit for an enemy started in the left half and the movers flip it when the enemy turns), except for type 7. The first half (#R$C036) shows the enemies facing left, this half facing right.
D $CAF6 They are the enemies facing the other way, but not all are plain mirror images: 9 of the 16 frames are exact bit-for-bit mirrors of their counterparts; the others differ in some lines and were drawn separately.
@ $CAF6 label=W34EnemyFramesTurned
B $CAF6,2752,4*32,6*32,8*48,6*192,8*64,6
b $D5B6 Guardian graphics for worlds 3 and 4
D $D5B6 $8C16-$9095 in the world area: two frames, each a left part 32 pixels wide and a right part 16 pixels wide, 48 lines high (384 and 192 bytes), in the masked format (a mask byte before each graphic byte). The graphics record #R$FF65 gives each part's address and size; #R$D513@main draws the left part at the path's display address and the right part beside it. The two worlds share it: world set-up takes the path and record from the first header only.
@ $D5B6 label=W34GuardianGfx
B $D5B6,1152,8*48,4*48,8*48,4
b $DA36 World 3 map
D $DA36 $9096-$9B05 in the world area, at header bytes 1-4 of the first header ($7661): 334 map columns of eight cell codes each, top cell first. The first 208 columns ($0680 bytes, bank $DA36-$E0B5) are the upper part and the other 126 (from bank $E0B6) the lower part. A column of the lower part lies $0680 bytes after the upper column above it: falling off the bottom of the screen moves the map window $0680 bytes on and climbing out of the top moves it back (#R$D38B@main at $D42B-$D494), so the two parts line up column for column.
D $DA36 Columns that the recording never shows are filled with $00 (lower-part columns 0-10), which #R$DDFD@main draws as the background block.
D $DA36 Play starts with the map window ($BA17) at column 4 ($BE16-$BE1B), the player in column 10. In the recording the window (the leftmost column shown) ranged over columns 1-177 of the upper part and 12-106 of the lower part. Nothing checks the window against the map's ends; walls in the map stop the player (#R$DD58@main).
D $DA36 Cells: 40 item boxes ($60-$78), 7 stepping cells ($79/$7A), 7 climbable cells ($80/$B2), 221 breakable blocks ($C6 and up), no type 4 spawn cells; codes from $A6 (header byte 0) up are solid. The codes and what play does to them are described at #R$DDFD@main, #R$DB90@main and #R$D65E@main.
@ $DA36 label=W3Map
B $DA36,1664,8
N $E0B6 The lower part: map columns 208-333, each $0680 bytes below the upper column it lies under.
B $E0B6,1008,8
b $E4A6 World 4 map
D $E4A6 $9B06-$A715 in the world area, at header bytes 1-4 of the second header ($7678): 386 map columns of eight cell codes each, top cell first. The first 208 columns ($0680 bytes, bank $E4A6-$EB25) are the upper part and the other 178 (from bank $EB26) the lower part. A column of the lower part lies $0680 bytes after the upper column above it: falling off the bottom of the screen moves the map window $0680 bytes on and climbing out of the top moves it back (#R$D38B@main at $D42B-$D494), so the two parts line up column for column.
D $E4A6 Columns that the recording never shows are filled with $00 (upper-part columns 201-207 and lower-part columns 0-10), which #R$DDFD@main draws as the background block.
D $E4A6 Play starts with the map window ($BA17) at column 4 ($BE16-$BE1B), the player in column 10. In the recording the window (the leftmost column shown) ranged over columns 4-178 of the upper part and 18-116 of the lower part. Nothing checks the window against the map's ends; walls in the map stop the player (#R$DD58@main).
D $E4A6 Cells: 37 item boxes ($60-$78), 0 stepping cells ($79/$7A), 59 climbable cells ($80/$B2), 334 breakable blocks ($C6 and up), 10 type 4 spawn cells (code $88, header byte 11); codes from $A6 (header byte 0) up are solid. The codes and what play does to them are described at #R$DDFD@main, #R$DB90@main and #R$D65E@main.
@ $E4A6 label=W4Map
B $E4A6,1664,8
N $EB26 The lower part: map columns 208-385, each $0680 bytes below the upper column it lies under.
B $EB26,1424,8
b $F0B6 Map cell graphics for worlds 3 and 4
D $F0B6 $A716-$B595 in the world area: 116 pictures of 16x16 pixels, 32 bytes each, two bytes a line, one bit a pixel (bit 7 leftmost); block code $60+n is entry n (header bytes 5-6; #R$DDFD@main). Both worlds of the bank use this table. Entries 0-23 are the item pictures (map codes $2E-$45). The entries for codes $79 and $7A are blank here; world set-up (#R$BDC0@main, $BE27-$BE40) fills both with the picture of code $81 in the first world or $82 in the second, which are that world's background ($81 is the same picture as $93), so those cells look like background - except in world 3, where bank 4's entries for codes $81 and $93 are themselves blank, so the copy changes nothing. The background block is code $93 or $82 (the operand at $CECA) and the block drawn over every item code is $C7 or $C8 (the operand at $DE09). Header byte 0 is the lowest solid code. When world 3 follows world 2, the leftover walk of world 2's start list (#R$C169@main) clears bit 7 in five bytes of the entries for codes $BA and $BC.
@ $F0B6 label=W34Cells
B $F0B6,3712,2
b $FF36 Guardian path for worlds 3 and 4
D $FF36 The guardian's path: two-byte display-file addresses, one taken per main loop pass by #R$D513@main, ended by $FF in place of an entry's low byte (no entry's low byte is $FF), after which the path starts again. Bit 7 of an entry's high byte selects the second pair of parts in the guardian record. #R$C553@main plants the address from header word $7667 when the map column reaches the header's guardian column.
D $FF36 Worlds 3 and 4 share this path (23 entries, five with bit 7 set) and the record after it.
@ $FF36 label=W34GuardianPath
W $FF36,46,2
B $FF64,1,1
b $FF65 Guardian graphics record for worlds 3 and 4
D $FF65 The guardian's graphics record, addressed by header word $7669: four parts of four bytes each, a masked graphic's address, its width in screen bytes and its lines. #R$D513@main draws parts 1 and 2 side by side, or parts 3 and 4 when the path entry has bit 7 set. The graphics follow the enemy frame area, from $7696 plus twice the $CC7E operand.
D $FF65 All four parts are 48 lines; parts 1 and 3 are four bytes wide, parts 2 and 4 two.
@ $FF65 label=W34GuardianRecord
W $FF65,2,2
B $FF67,2,2
W $FF69,2,2
B $FF6B,2,2
W $FF6D,2,2
B $FF6F,2,2
W $FF71,2,2
B $FF73,2,2
t $FF75 World 3 name
D $FF75 Sky: the name BeginLife (#R$BDC0@main, $BEC8-$BECF) prints in large letters on row 8 of the world's intro card, from header bytes 21-22 at the column in byte 20, under WORLD OF. It ends with '#', the terminator of #R$C4ED@main.
@ $FF75 label=W3Name
T $FF75,4,4
t $FF79 World 4 name
D $FF79 Labyrinth: the name BeginLife (#R$BDC0@main, $BEC8-$BECF) prints in large letters on row 8 of the world's intro card, from header bytes 21-22 at the column in byte 20, under WORLD OF. It ends with '#', the terminator of #R$C4ED@main.
@ $FF79 label=W4Name
T $FF79,10,10
b $FF83 Enemy templates for worlds 3 and 4
D $FF83 The enemy template table for worlds 3 and 4 (word $768E): nine templates, types 1-9. Each template is five bytes, copied into an enemy slot's bytes 4-8 by #R$DD41@main: width in screen bytes, lines, the address of the first of its frames, and the type, which is always the template number plus 1. #R$C553@main indexes the table with the template number from a list entry, and the words at $7690, $7692 and $7694 point at the type 4, 7 and 6 templates for the random spawns. Type 7's frames are at $6FA0 in the main program, the same in every world; the others are in this bank's frame area from $7696, with the frames for moving right at the $CC7E operand further on.
D $FF83 World 3's list follows straight after the ninth template.
@ $FF83 label=W34EnemyTemplates
B $FF83,45,5
b $FFB0 Enemy start list for world 3
D $FFB0 World 3's list of 26 enemy starts, addressed by bytes 13-15 of the header at $7660. Each entry is three bytes: the map column at which the enemy starts (matched against $B95C by #R$D5D1@main, which takes the first match); the row in bits 0-6 with bit 7 set while the entry's enemy is started (#R$C553@main at $C654, cleared by #R$D909@main and #R$C169@main); and the part of the map in bit 6 (0 upper, 1 lower, against $B957), the side in bit 7 (0 left edge, 1 right edge) and the template number in bits 0-4, an index into the template table at word $768E.
@ $FFB0 label=W3EnemyList
B $FFB0,78,3
b $FFFE Start of the enemy start list for world 4
D $FFFE The first two bytes of world 4's list of 28 enemy starts (header at $7677, bytes 13-15): the column and row bytes of entry 0. The list does not fit in the bank; its remaining 82 bytes are the first 82 of the 85 bytes that #R$B8C3@main copies from bank 1 for this bank (bank 1 $C055, loaded at $B660). The format is as for #R$FFB0 (world 3's list).
@ $FFFE label=W4EnemyList
B $FFFE,2,2
