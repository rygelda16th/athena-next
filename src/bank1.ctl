@ $C000 start
@ $C000 org
b $C000 Bank 1: the world data that did not fit in the world banks
D $C000 Four 85-byte pieces, one for each world bank (3, 4, 6 and 7), at the offsets in #R$B8BB@main; #R$B8C3@main copies the current bank's piece to $B660, just past the world area.
B $C000,340,17
b $C154 Ending picture
D $C154 A whole screen, display file then attributes, that #R$B908@main copies to $4000 when the game is completed: the credits picture, shown while tune 0 plays.
B $C154,6912,32
b $DC54 Combat School advert
D $DC54 A whole screen that #R$B929@main copies to $4000 after the ending tune: an advert for Ocean's Combat School, shown until a key is pressed.
B $DC54,6912,32*192,8*32,32
b $F754 Unused
D $F754 2,220 bytes, all zero in the snapshot; no read of them was seen in the recording.
S $F754,256,$0100
B $F854,1964,8*245,4
