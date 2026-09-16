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
D $7660 The loader at #R$B8C3 copies the whole of the current world's bank here (16,384 bytes, #R$7660 to #R$B65F). In the snapshot, taken at the title screen before any world was loaded, it still holds what the tape loader left behind.
B $7660,16384,16
b $B660 World settings
D $B660 85 bytes the loader at #R$B8C3 copies from bank 1 for the current world.
B $B660,85,16*5,5
b $B6B5 Data block at B6B5
B $B6B5,515,8*64,3
c $B8B8 Routine at B8B8
b $B8BB Data block at B8BB
B $B8BB,8,8
c $B8C3 Routine at B8C3
D $B8C3 Used by the routine at #R$BCE6.
c $B908 Routine at B908
D $B908 Used by the routine at #R$D77A.
b $B949 Data block at B949
B $B949,250,8*31,2
t $BA43 Message at BA43
T $BA43,3,3
b $BA46 Data block at BA46
B $BA46,14,8,6
t $BA54 Message at BA54
T $BA54,4,4
b $BA58 Data block at BA58
B $BA58,53,8*6,5
c $BA8D Routine at BA8D
D $BA8D Used by the routine at #R$C553.
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
c $BCE6 Routine at BCE6
D $BCE6 Used by the routine at #R$BF6A.
N $BD01 This entry point is used by the routine at #R$F1C9.
N $BD85 This entry point is used by the routine at #R$C553.
c $BDC0 Routine at BDC0
D $BDC0 Used by the routine at #R$B8C3.
N $BE47 This entry point is used by the routine at #R$C553.
c $BEEA Routine at BEEA
D $BEEA Used by the routines at #R$BCE6 and #R$BEFE.
c $BEFE Routine at BEFE
D $BEFE Used by the routines at #R$D38B, #R$D991 and #R$DAF2.
N $BF15 This entry point is used by the routines at #R$BF39, #R$BF42, #R$C553, #R$D38B and #R$DDAE.
c $BF39 Routine at BF39
D $BF39 Used by the routines at #R$D38B and #R$DC4E.
c $BF42 Routine at BF42
D $BF42 Used by the routine at #R$BCE6.
N $BF4B This entry point is used by the routines at #R$BDC0 and #R$DC7D.
b $BF52 Data block at BF52
B $BF52,4,4
c $BF56 Routine at BF56
D $BF56 Used by the routines at #R$BF39 and #R$C553.
c $BF5E Routine at BF5E
D $BF5E Used by the routines at #R$D38B and #R$DC51.
c $BF6A Routine at BF6A
D $BF6A Used by the routine at #R$C3C0.
N $BF6D This entry point is used by the routine at #R$B908.
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
c $C1F4 Routine at C1F4
D $C1F4 Used by the routines at #R$D77A and #R$DC89.
N $C1F6 This entry point is used by the routines at #R$D77A and #R$DC39.
N $C203 This entry point is used by the routines at #R$BCE6 and #R$C015.
N $C235 This entry point is used by the routine at #R$DAF2.
N $C237 This entry point is used by the routines at #R$BCE6, #R$BF6A, #R$C015, #R$C1E2, #R$C28C and #R$F355.
c $C284 Routine at C284
D $C284 Used by the routines at #R$BCE6 and #R$DE96.
c $C28C Routine at C28C
D $C28C Used by the routine at #R$BF6A.
N $C292 This entry point is used by the routines at #R$BCE6, #R$BF6A, #R$C284, #R$C3A5, #R$C553, #R$D77A, #R$F1C9 and #R$F355.
N $C29A This entry point is used by the routine at #R$F355.
c $C2D9 Routine at C2D9
D $C2D9 Used by the routines at #R$C553, #R$D65E, #R$D8D6, #R$DB56 and #R$DD58.
c $C2E5 Routine at C2E5
D $C2E5 Used by the routines at #R$C2ED, #R$C2F6 and #R$C553.
c $C2ED Routine at C2ED
D $C2ED Used by the routines at #R$B908, #R$BF6A, #R$C553 and #R$D77A.
c $C2F6 Routine at C2F6
D $C2F6 Used by the routines at #R$C2ED, #R$C3C0, #R$C553, #R$F1C9 and #R$F355.
c $C2FC Routine at C2FC
D $C2FC Used by the routines at #R$BCE6, #R$BDC0, #R$BF6A, #R$C553, #R$DE96 and #R$F355.
c $C303 Routine at C303
D $C303 Used by the routines at #R$C33B, #R$C4BD, #R$C553 and #R$DD12.
c $C312 Routine at C312
D $C312 Used by the routines at #R$DD06 and #R$DD1E.
c $C332 Routine at C332
D $C332 Used by the routines at #R$BF6A and #R$F355.
c $C33B Routine at C33B
D $C33B Used by the routines at #R$BDC0 and #R$DBE4.
c $C3A5 Routine at C3A5
D $C3A5 Used by the routines at #R$C3C0 and #R$C553.
c $C3C0 Routine at C3C0
D $C3C0 Used by the routines at #R$C553 and #R$DAF2.
c $C3DA Routine at C3DA
D $C3DA Used by the routines at #R$C553, #R$D08C, #R$D333, #R$D38B, #R$D513 and #R$D77A.
c $C3EB Routine at C3EB
D $C3EB Used by the routines at #R$C553, #R$DB56 and #R$DD58.
c $C400 Routine at C400
D $C400 Used by the routines at #R$C553 and #R$D77A.
c $C408 Routine at C408
D $C408 Used by the routines at #R$BF6A, #R$D08C, #R$D38B, #R$D65E, #R$D77A, #R$D8D6 and #R$DBAB.
c $C480 Routine at C480
D $C480 Used by the routine at #R$C553.
c $C48E Routine at C48E
D $C48E Used by the routine at #R$C553.
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
c $C553 Routine at C553
D $C553 Used by the routines at #R$BDC0 and #R$D38B.
N $CB21 This entry point is used by the routine at #R$DAC9.
N $D04A This entry point is used by the routine at #R$D77A.
c $D08C Routine at D08C
D $D08C Used by the routine at #R$DAF2.
N $D2DC This entry point is used by the routine at #R$D923.
c $D333 Routine at D333
D $D333 Used by the routine at #R$D991.
c $D38B Routine at D38B
D $D38B Used by the routine at #R$D08C.
N $D3BE This entry point is used by the routines at #R$D08C, #R$D333 and #R$D991.
B $D4FB,4,4
c $D513 Routine at D513
D $D513 Used by the routine at #R$D08C.
c $D5C2 Routine at D5C2
D $D5C2 Used by the routine at #R$D08C.
c $D5D1 Routine at D5D1
D $D5D1 Used by the routine at #R$C553.
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
c $D763 Routine at D763
D $D763 Used by the routine at #R$D65E.
c $D77A Routine at D77A
D $D77A Used by the routine at #R$C553.
c $D8D6 Routine at D8D6
D $D8D6 Used by the routines at #R$D08C, #R$D333 and #R$D38B.
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
c $DAC9 Routine at DAC9
D $DAC9 Used by the routine at #R$C553.
c $DAD7 Routine at DAD7
D $DAD7 Used by the routine at #R$C553.
c $DAF2 Routine at DAF2
D $DAF2 Used by the routine at #R$C553.
N $DB1C This entry point is used by the routines at #R$C553 and #R$DAD7.
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
c $DBE4 Routine at DBE4
N $DBE6 This entry point is used by the routine at #R$DBFD.
c $DBF7 Routine at DBF7
c $DBFD Routine at DBFD
c $DC01 Routine at DC01
N $DC0A This entry point is used by the routine at #R$DDBC.
c $DC17 Routine at DC17
c $DC1C Routine at DC1C
b $DC25 Data block at DC25
B $DC25,4,4
c $DC29 Routine at DC29
b $DC31 Data block at DC31
B $DC31,4,4
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
b $DC68 Data block at DC68
B $DC68,21,8*2,5
c $DC7D Routine at DC7D
c $DC89 Routine at DC89
c $DC91 Routine at DC91
D $DC91 Used by the routine at #R$DC39.
c $DC97 Routine at DC97
D $DC97 Used by the routine at #R$DC1C.
c $DC9C Routine at DC9C
D $DC9C Used by the routine at #R$DC1C.
c $DCA1 Routine at DCA1
D $DCA1 Used by the routine at #R$DC1C.
c $DCA6 Routine at DCA6
b $DCAA Data block at DCAA
B $DCAA,2,2
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
c $DD41 Routine at DD41
D $DD41 Used by the routine at #R$C553.
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
c $DDBC Routine at DDBC
D $DDBC Used by the routine at #R$D77A.
c $DDC4 Routine at DDC4
D $DDC4 Used by the routine at #R$D38B.
N $DDEE This entry point is used by the routine at #R$DE96.
c $DDFD Routine at DDFD
D $DDFD Used by the routine at #R$DDC4.
N $DE29 This entry point is used by the routine at #R$DB3B.
c $DE96 Routine at DE96
D $DE96 Used by the routine at #R$BDC0.
N $DE99 This entry point is used by the routine at #R$DD66.
c $DEC6 Routine at DEC6
D $DEC6 Used by the routines at #R$B908, #R$BDC0, #R$BF6A, #R$C3C0, #R$C553 and #R$D77A.
N $DECD This entry point is used by the routine at #R$DF4E.
c $DED9 Routine at DED9
D $DED9 Used by the routine at #R$DEC6.
N $DF0F This entry point is used by the routine at #R$E09E.
c $DF4E Routine at DF4E
D $DF4E Used by the routine at #R$DED9.
c $DF5A Routine at DF5A
D $DF5A Used by the routines at #R$DED9 and #R$E114.
c $DF90 Routine at DF90
N $DFAA This entry point is used by the routine at #R$DFEF.
c $DFB2 Routine at DFB2
N $DFEE This entry point is used by the routine at #R$DED9.
c $DFEF Routine at DFEF
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
B $E16A,732,8*91,4
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
c $E986 Routine at E986
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
B $EFAF,348,8*43,4
t $F10B Message at F10B
T $F10B,3,3
b $F10E Data block at F10E
B $F10E,76,8*9,4
t $F15A Message at F15A
T $F15A,3,3
b $F15D Data block at F15D
B $F15D,33,8*4,1
t $F17E Message at F17E
T $F17E,3,3
b $F181 Data block at F181
B $F181,6,6
t $F187 Message at F187
T $F187,5,5
b $F18C Data block at F18C
B $F18C,6,6
t $F192 Message at F192
T $F192,3,3
b $F195 Data block at F195
B $F195,8,8
t $F19D Message at F19D
T $F19D,3,3
b $F1A0 Data block at F1A0
B $F1A0,41,8*5,1
c $F1C9 Routine at F1C9
N $F1D6 This entry point is used by the routine at #R$F355.
c $F240 Routine at F240
D $F240 Used by the routine at #R$F49E.
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
B $F471,45,8*5,5
c $F49E Routine at F49E
D $F49E Used by the routine at #R$B8B8.
b $F4AC Data block at F4AC
B $F4AC,16,8
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
