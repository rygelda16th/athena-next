; ---------------------------------------------------------------------------
; E6: controls and options (included in the engine, src/next/engine.asm).
;
; Play builds only reach this: the oracle builds keep the original's controls and
; code, so the recording replays exactly (docs/oracle.md).
;
; CONTROLS. The original's Kempston routine becomes eng_kempston: a Mega Drive pad in
; the Next's MD mode on port $1F gives right, left, down, up and fire as before, its
; second button (C) also jumps, and Start pauses. The original's waits read only the
; keyboard ($C2E5, under PRESS ANY KEY, the credits, CONTINUE? and the release from
; pause), so eng_anykey answers a pad button too.
;
; OPTIONS. The title's control menu gains "6 OPTIONS": a text screen in the game's own
; font where presets set the difficulty levers of docs/difficulty.md, which can then be
; changed one by one, with the bug-fix switch, the classic switch and a save to the SD
; card. opt_apply writes every lever into the game's own operands (the sites are in
; tools/nexpatches.py, OPTION_SITES); with every option at ORIGINAL the game's bytes are
; its own. PROVISIONAL: the Easier and Easy values are for David to set by play.
; ---------------------------------------------------------------------------

E_OPT           EQU $20A0               ; the settings, OPT_COUNT bytes (below)
OPT_PRESET      EQU 0                   ; 0 original, 1 easier, 2 easy, 3 own
OPT_LIVES       EQU 1                   ; 1-9
OPT_CONT        EQU 2                   ; continues, 0-9
OPT_CTIME       EQU 3                   ; CONTINUE? steps: 0 1 second, 1 2, 2 3
OPT_ENERGY      EQU 4                   ; 5-19 units
OPT_CONTACT     EQU 5                   ; 1: enemies harm
OPT_IMMUNE      EQU 6                   ; 0 short, 1 normal, 2 long
OPT_CLOCK       EQU 7                   ; minutes, 3-9
OPT_GUARD       EQU 8                   ; 0 normal, 1 weaker, 2 weakest
OPT_KEEP        EQU 9                   ; 1: keep the carried items after a lost life
OPT_POISON      EQU 10                  ; 1: poison drains energy
OPT_BLADE       EQU 11                  ; 1: the feathered blade costs energy
OPT_ENEMIES     EQU 12                  ; 1: the enemies the original loses at a screen edge
OPT_FIXES       EQU 13                  ; 1: the bug fixes
OPT_CLASSIC     EQU 14                  ; 1: the original's graphics and sound
OPT_COUNT       EQU 15
E_OPT_ROW       EQU $20B0               ; the row the cursor is on
E_PAD_TEST      EQU $20B1               ; non-zero: a checker's pad bits instead of port $1F
E_OPT_SD        EQU $20B2               ; the last SD result: 0 none, 1 loaded, 2 saved, $FF failed
E_OPT_READY     EQU $20BE               ; the settings have been loaded
ROWS            EQU OPT_COUNT + 1       ; the options, then SAVE AND GO BACK
OPT_TOP         EQU 4                   ; screen row of the first option
SD_PAGE         EQU 95                  ; the free half of bank 47: the SD stub and its buffer

; ---- controls ------------------------------------------------------------------------

; A = port $1F (or the checker's bits).
pad_read:
        ld a,(E_PAD_TEST)
        or a
        ret nz
        in a,($1f)
        ret

; The Kempston routine (the original's template at $F472, copied to $BA8D): the six
; control flags at $BAB2-$BAB7, 0 while held.
eng_kempston:
        call pad_read
        ld c,a
        bit 5,a                         ; C also jumps
        jr z,.noc
        set 3,c
.noc:   ld a,c
        cpl
        ld hl,$bab2
        ld b,5
.flag:  ld (hl),0
        rra
        rl (hl)
        inc hl
        djnz .flag
        ld a,$f7                        ; key 1 pauses, as before
        in a,($fe)
        and 1
        bit 7,c                         ; and so does Start
        jr z,.pause
        xor a
.pause: ld (hl),a
        ret

; $C2E5, AnyKeyHeld: NZ if a key or a pad button is held.
eng_anykey:
        xor a
        in a,($fe)
        and $1f
        xor $1f
        ret nz
        call pad_read
        and %11110000                   ; fire (B), C, A, Start
        ret

; ---- the menu ------------------------------------------------------------------------

; $F1E4: print the control menu, and the options line under it.
eng_menu_print:
        call $c292
        call text_in
        ld a,(E_OPT_READY)              ; the first time: the settings from the card
        or a
        jr nz,.ready
        inc a
        ld (E_OPT_READY),a
        call opt_load
        call opt_apply
.ready: ld hl,txt_menu6
        ld de,14 * 256 + 10
        call $c292
        jp text_out

; The options screen's words live in page 95 (src/next/optext.asm), mapped at $6000
; while they are printed; the game's own graphics are there the rest of the time.
text_in:
        nextreg $53,SD_PAGE
        ret

text_out:
        nextreg $53,11
        ret

; $F23A: none of keys 1-5 - key 6 opens the options; else read again.
eng_menu_more:
        ld a,$ef
        in a,($fe)
        bit 4,a
        jp nz,$f1e7
        call options
        jp $f1d6                        ; show the control menu again, as DEFINE KEYS does

; ---- the options screen ------------------------------------------------------------

options:
        call text_in
        call opt_blank
        ld hl,txt_title
        ld de,(OPT_TOP - 2) * 256 + 12
        ld a,$47
        call print_at
        xor a
        ld (E_OPT_ROW),a
.draw:  call opt_draw
        call opt_release
.wait:  halt
        call opt_keys                   ; C = up, down, left, right, select bits
        ld a,c
        or a
        jr z,.wait
        ld hl,E_OPT_ROW
        bit 0,c
        jr z,.nup
        ld a,(hl)
        or a
        jr z,.draw
        dec (hl)
        jr .draw
.nup:   bit 1,c
        jr z,.ndown
        ld a,(hl)
        cp ROWS - 1
        jr nc,.draw
        inc (hl)
        jr .draw
.ndown: ld a,(hl)
        cp ROWS - 1
        jr z,.last
        bit 2,c
        ld b,-1
        jr nz,.change
        bit 3,c
        ld b,1
        jr nz,.change
        bit 4,c
        jr z,.draw
        ld b,1                          ; select also steps forward
.change:
        call opt_step
        call opt_apply
        jr .draw
.last:  bit 4,c
        jr z,.draw
        call opt_save
        call opt_draw
        call opt_release
        ld b,50
.show:  halt
        djnz .show
        call opt_blank
        jp text_out

; Wait until no key or pad button is held.
opt_release:
        halt
        call eng_anykey
        jr nz,opt_release
        call opt_keys
        ld a,c
        or a
        jr nz,opt_release
        ret

; C = bit 0 up (Q, 7, pad), 1 down (A, 6, pad), 2 left (O, 5, pad), 3 right (P, 8, pad),
; 4 select (ENTER, SPACE, 0, fire).
opt_keys:
        ld c,0
        ld a,$fb
        in a,($fe)
        rra
        jr c,.q
        set 0,c
.q:     ld a,$fd
        in a,($fe)
        rra
        jr c,.a
        set 1,c
.a:     ld a,$df
        in a,($fe)
        rra
        jr c,.p
        set 3,c
.p:     rra
        jr c,.o
        set 2,c
.o:     ld a,$ef                        ; 0, 9, 8, 7, 6
        in a,($fe)
        rra
        jr c,.zero
        set 4,c
.zero:  rra
        rra
        jr c,.eight
        set 3,c
.eight: rra
        jr c,.seven
        set 0,c
.seven: rra
        jr c,.six
        set 1,c
.six:   ld a,$f7                        ; 5
        in a,($fe)
        bit 4,a
        jr nz,.five
        set 2,c
.five:  ld a,$bf
        in a,($fe)
        rra
        jr c,.enter
        set 4,c
.enter: ld a,$7f
        in a,($fe)
        rra
        jr c,.space
        set 4,c
.space: call pad_read
        rra
        jr nc,.pr
        set 3,c
.pr:    rra
        jr nc,.pl
        set 2,c
.pl:    rra
        jr nc,.pd
        set 1,c
.pd:    rra
        jr nc,.pu
        set 0,c
.pu:    rra
        ret nc
        set 4,c
        ret

; B = +1 or -1: the option on the cursor's row steps; a lever makes the preset "own",
; the preset loads its levers.
opt_step:
        ld a,(E_OPT_ROW)
        ld e,a
        ld d,0
        ld hl,opt_limits
        add hl,de
        add hl,de
        ld c,(hl)                       ; C = lowest
        inc hl
        ld a,(hl)
        ld (os_high),a
        ld hl,E_OPT
        add hl,de
        ld a,(hl)
        add a,b
        cp c
        jp m,.wrap_high
        jr c,.wrap_high
        ld b,a
        ld a,(os_high)
        cp b
        ld a,b
        jr nc,.store
        ld a,c                          ; past the highest: the lowest
        jr .store
.wrap_high:
        ld a,(os_high)
.store: ld (hl),a
        ld a,e
        or a
        jr nz,.lever
        ld a,(hl)                       ; the preset: load its levers (not for "own")
        cp 3
        ret z
        jp opt_preset
.lever: cp OPT_FIXES
        ret nc                          ; the switches do not touch the preset
        ld a,3
        ld (E_OPT + OPT_PRESET),a
        ret

os_high         EQU $20B4

; The levers of preset A.
opt_preset:
        ld l,a
        ld h,0
        ld e,l
        ld d,h
        add hl,hl                       ; x 2
        add hl,hl                       ; x 4
        add hl,hl                       ; x 8
        add hl,de
        add hl,de
        add hl,de                       ; x 11: the levers of each preset
        ld de,presets
        add hl,de
        ld de,E_OPT + 1
        ld bc,11
        ldir
        ret

; Lowest and highest value of each option.
opt_limits:
        db 0, 3                         ; preset: original, easier, easy, own (the levers as they are)
        db 1, 9                         ; lives
        db 0, 9                         ; continues
        db 0, 2                         ; continue time
        db 5, 19                        ; energy
        db 0, 1                         ; contact
        db 0, 2                         ; immunity
        db 3, 9                         ; clock
        db 0, 2                         ; guardian
        db 0, 1                         ; keep items
        db 0, 1                         ; poison
        db 0, 1                         ; blade cost
        db 0, 1                         ; every enemy
        db 0, 1                         ; bug fixes
        db 0, 1                         ; classic

; Levers 1-11 of each preset. PROVISIONAL: David sets these by play.
presets:
        db 5, 3, 0, 11, 1, 1, 5, 0, 0, 1, 1  ; ORIGINAL: the game as it was
        db 7, 5, 1, 15, 1, 2, 7, 1, 0, 1, 1  ; EASIER
        db 9, 9, 2, 19, 1, 2, 9, 2, 1, 0, 0  ; EASY

; Default settings: the original, everything off.
opt_defaults:
        ld a,0
        call opt_preset
        xor a
        ld (E_OPT + OPT_PRESET),a
        ld (E_OPT + OPT_FIXES),a
        ld (E_OPT + OPT_CLASSIC),a
        ret

; ---- drawing -----------------------------------------------------------------------------

; Blank rows 2-21, columns 1-30: pixels and attributes.
opt_blank:
        ld hl,$4000 + 2 * 8 * 32
        ld b,20 * 8
.line:  push bc
        push hl
        inc hl
        ld (hl),0
        ld d,h
        ld e,l
        inc de
        ld bc,29
        ldir
        pop hl
        ld de,32
        add hl,de
        pop bc
        djnz .line
        ld hl,$5800 + 2 * 32
        ld b,20
.attr:  push bc
        push hl
        inc hl
        ld (hl),0
        ld d,h
        ld e,l
        inc de
        ld bc,29
        ldir
        pop hl
        ld de,32
        add hl,de
        pop bc
        djnz .attr
        ret

; HL = message, D = row, E = column, A = attribute.
print_at:
        ld ($c280),a
        jp $c292

opt_draw:
        ld b,0
.row:   push bc
        ld a,(E_OPT_ROW)
        cp b
        ld a,$47                        ; bright white, the cursor's row bright yellow
        jr nz,.col
        ld a,$46
.col:   ld (od_attr),a
        ld a,b
        add a,OPT_TOP
        ld d,a
        ld e,3
        ld (od_pos),de
        ld a,b                          ; the label
        add a,a
        ld l,a
        ld h,0
        ld de,opt_labels
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        ld de,(od_pos)
        ld a,(od_attr)
        call print_at
        pop bc
        push bc
        ld a,b
        cp ROWS - 1
        jr z,.next
        call opt_value                  ; HL = the value's text
        ld de,(od_pos)
        ld e,20
        ld a,(od_attr)
        call print_at
.next:  pop bc
        inc b
        ld a,b
        cp ROWS
        jr nz,.row
        ld a,(E_OPT_SD)                 ; after a save: what happened
        or a
        ret z
        ld hl,txt_saved
        cp 2
        jr z,.sd
        ld hl,txt_loaded
        cp 1
        jr z,.sd
        ld hl,txt_nocard
.sd:    ld de,(OPT_TOP + ROWS + 1) * 256 + 3
        ld a,$45
        jp print_at

od_attr         EQU $20B5
od_pos          EQU $20B6

; B = option -> HL = its value as text (a buffer for numbers).
opt_value:
        ld e,b
        ld d,0
        ld hl,E_OPT
        add hl,de
        ld a,(hl)
        ld hl,value_kinds
        add hl,de
        ld c,(hl)                       ; 0 number, 1 off/on, 2 list 0-2 per option
        ld b,a
        ld a,c
        or a
        jr nz,.text
        ld a,b                          ; a number: two digits, the first blank if 0
        ld hl,ov_buf
        ld c,$20
.tens:  cp 10
        jr c,.units
        sub 10
        ld c,$31
        jr .tens                        ; at most 19
.units: ld (hl),c
        inc hl
        add a,$30
        ld (hl),a
        inc hl
        ld (hl),$20
        inc hl
        ld (hl),$20
        inc hl
        ld (hl),$20
        inc hl
        ld (hl),$23
        ld hl,ov_buf
        ret
.text:  dec c
        ld hl,txt_offon
        jr z,.pick
        ld hl,opt_lists                 ; kind 2: this option's own three words
        add hl,de
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
.pick:  ld a,b                          ; the B-th '#'-ended word
        or a
        ret z
.skip:  ld a,(hl)
        inc hl
        cp $23
        jr nz,.skip
        djnz .skip
        ret

ov_buf          EQU $20B8

value_kinds:    db 2, 0, 0, 2, 0, 1, 2, 0, 2, 1, 1, 1, 1, 1, 1

opt_lists:
        dw txt_presets, 0, 0, txt_ctime, 0, 0, txt_immune, 0, txt_guard, 0, 0, 0, 0, 0, 0

; ---- applying -----------------------------------------------------------------------------

; Every lever into the game's operands; the bug fixes in or out; classic mode.
opt_apply:
        ld a,(E_OPT + OPT_LIVES)
        add a,$30
        ld ($c1e3),a                    ; LD A,'5' at $C1E2: the lives digit
        ld a,(E_OPT + OPT_CONT)
        inc a
        ld ($bd0d),a                    ; LD A,4 at $BD0C: continues + 1 at a new game
        ld a,(E_OPT + OPT_CTIME)
        inc a
        ld b,a
        xor a
.ct:    add a,50
        djnz .ct
        ld ($cce7),a                    ; LD HL,50 at $CCE6: frames a CONTINUE? step
        ld a,(E_OPT + OPT_ENERGY)
        ld ($bf43),a                    ; LD A,11 at $BF42: energy at a new game
        ld a,(E_OPT + OPT_CONTACT)
        or a
        ld a,$c2                        ; $D4F2 JP NZ: harm unless immune
        jr nz,.contact
        ld a,$c3                        ; JP: never harm
.contact:
        ld ($d4f2),a
        ld a,(E_OPT + OPT_IMMUNE)
        ld hl,immune_values
        call pick
        ld ($dc55),a                    ; LD A,200 at $DC54: immunity passes
        ld a,(E_OPT + OPT_CLOCK)
        ld ($bdae),a                    ; LD A,5 at $BDAD: minutes a world
        ld a,(E_OPT + OPT_GUARD)
        ld hl,guard_values
        call pick
        ld ($d819),a                    ; CP 80 at $D818: guardian damage to destroy
        ld a,(E_OPT + OPT_KEEP)
        or a
        ld a,$28                        ; $CD13 JR Z: keep items only with item $61
        jr z,.keep
        ld a,$18                        ; JR: always keep
.keep:  ld ($cd13),a
        ld a,(E_OPT + OPT_POISON)
        or a
        ld a,$cd                        ; $DB03 CALL $BEFE: the drain
        jr nz,.poison
        ld a,$21                        ; LD HL,$BEFE: no drain (HL is popped straight after)
.poison:
        ld ($db03),a
        ld a,(E_OPT + OPT_BLADE)
        or a
        ld a,$cc                        ; $DA42 CALL Z,$BEFE: the blade's cost
        jr nz,.blade
        ld a,$21                        ; LD HL,$BEFE: free (HL is loaded straight after)
.blade: ld ($da42),a
        ld a,(E_OPT + OPT_ENEMIES)      ; the enemies the original loses at a screen edge
        ld hl,$cc24
        or a
        jr nz,.enemies
        ld (hl),$dd
        inc hl
        ld (hl),$35
        inc hl
        ld (hl),$02
        jr .fixes
.enemies:
        ld (hl),$cd                     ; CALL eng_ledge; JP $CC33
        inc hl
        ld (hl),eng_ledge & 255
        inc hl
        ld (hl),eng_ledge >> 8
        inc hl
        ld (hl),$c3
        inc hl
        ld (hl),$33
        inc hl
        ld (hl),$cc
.fixes: call fixes_apply
        ld a,(E_OPT + OPT_CLASSIC)
        jp classic_apply

immune_values:  db 100, 200, 255
guard_values:   db 80, 64, 48

; A = index, HL = table -> A = entry.
pick:   ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        ret

; ---- the bug fixes (docs/disassembly.md, the Bugs page) -------------------------------------
; Fixed with the switch on: World 7's guardian column ($C58B), a full item panel
; ($DBEF), energy not redrawn ($DC51), a struck heart taken for an enemy ($D874).
; Nothing to fix on the Next: the first game's list walk (the alternative ROM is
; write-protected, as a Spectrum's ROM is) and the blade drawn above the screen (the
; engine skips sprites above the screen; the writes land in ROM space).
; NOT YET FIXED (E6 leaves them for later): the world 7 enemy list damaged at the world
; change, the guardian's hit area ignoring its row, guardian damage carried over.
fixes_apply:
        ld ix,fix_sites
        ld b,fix_count
.site:  ld e,(ix+0)
        ld d,(ix+1)                     ; DE = the site
        push ix
        pop hl
        ld a,(E_OPT + OPT_FIXES)
        or a
        ld a,2                          ; the original's bytes
        jr z,.copy
        ld a,5                          ; the fixed bytes
.copy:  push bc
        ld c,a
        ld b,0
        add hl,bc
        ld bc,3
        ldir
        pop bc
        ld de,8
        add ix,de
        djnz .site
        ret

; Each: the site, its original three bytes, the fixed three bytes.
fix_sites:
        dw $c58b : db $3a, $5c, $b9 : db $cd : dw fix_guardcol      ; LD A,($B95C)
        dw $dbef : db $af, $cd, $a2 : db $cd : dw fix_panel         ; XOR A; CALL $C4A2 (first 3)
        dw $dc51 : db $c3, $5e, $bf : db $c3 : dw fix_energy        ; JP $BF5E
        dw $d874 : db $b7, $c8, $47 : db $cd : dw fix_heart         ; OR A; RET Z; LD B,A
fix_count EQU ($ - fix_sites) / 8

; $C58B LD A,($B95C) before CP n (the world's guardian column): a column of $FF means
; no guardian, so the view column is made never to match it.
fix_guardcol:
        ld a,($c58f)
        inc a
        ld a,($b95c)
        ret nz
        cp $ff
        ret nz
        xor a
        ret

; $DBEF XOR A; CALL $C4A2: find an empty slot; with none, the item is not carried
; (the original went on to overwrite the tenth slot). The CALL's last byte, $C4, is
; left in place after the fixed three bytes and skipped by the return address.
fix_panel:
        pop hl
        inc hl                          ; past the $C4 left over
        push hl
        xor a
        call $c4a2
        ret z                           ; a free slot: carry on and store the item
        pop hl                          ; none: return from the item handler
        ret

; $DC51 JP $BF5E: a unit of energy, and the bar redrawn at once.
fix_energy:
        call $bf5e
        jp $bf15

; $D874 OR A; RET Z; LD B,A: a heart's $FE or $FF is not an enemy number.
fix_heart:
        or a
        jr z,.none
        cp $fe
        jr nc,.none
        ld b,a
        ret
.none:  pop hl                          ; return from the routine, as RET Z did
        xor a
        ret

; The original's ledge step-back at $CC24 can push an enemy started at a screen edge
; outside the bounds #R$DD29 keeps, and it is freed in the same pass and never seen
; (721 of the recording's 851 list starts). With EVERY ENEMY on, the step stays inside
; them, so those enemies appear - which makes the game harder, so it is its own switch.
eng_ledge:
        push af
        bit 7,(ix+9)
        jr nz,.left
        inc (ix+2)
        ld a,30
        sub (ix+4)                      ; the last column $DD29 keeps
        cp (ix+2)
        jr nc,.done
        ld (ix+2),a
        jr .done
.left:  dec (ix+2)
        ld a,(ix+2)
        cp 2
        jr nc,.done
        ld a,2
        ld (ix+2),a
.done:  pop af
        ret

; ---- classic mode --------------------------------------------------------------------------

; A = 1: the original's graphics and sound; 0: the enhanced port's.
classic_apply:
        ld (E_CLASSIC),a
        or a
        jr z,.new
        xor a                           ; the arcade art and sound off, the beeper on
        ld (E_ARC_ON),a
        ld (E_SND_ON),a
        inc a
        jp snd_beeper
.new:
    IFDEF ARCADE
        ld a,1
        ld (E_ARC_ON),a
        ld a,(E_SND_ON)
        or a
        ret nz
        ld a,i
        di
        push af
        call snd_arcade_on
        pop af
        ret po
        ei
    ENDIF
        ret

; ---- the SD card ----------------------------------------------------------------------------
; esxDOS pages itself over $0000-$3FFF during a call, which only works with the ROM paged
; there, not the alternative ROM holding the engine or the engine's RAM at $2000. So the
; calls run from a stub copied into page 95 at $4000, which switches the alternative ROM
; and the engine's RAM out and back in around them, with interrupts off.

; The stub is src/next/sdstub.asm, in page 95 at $4000 from the .nex itself.

opt_save:
        ld hl,E_OPT
        ld de,sd_save_ops
        call sd_run
        ld a,2
        jr nz,.done
        ld a,$ff
.done:  ld (E_OPT_SD),a
        ret

; At start-up, before the title: the saved settings if the card has them.
opt_load:
        call opt_defaults
        ld hl,E_OPT
        ld de,sd_load_ops
        call sd_run
        jr z,.none
        ld hl,E_OPT                     ; every value inside its limits, or the defaults
        ld de,opt_limits
        ld b,OPT_COUNT
.check: ld a,(de)
        inc de
        cp (hl)
        jr z,.low
        jr nc,.none                     ; below the lowest
.low:   ld a,(de)
        inc de
        cp (hl)
        jr c,.none                      ; above the highest
        inc hl
        djnz .check
        ld a,1
        ld (E_OPT_SD),a
        ret
.none:  call opt_defaults
        xor a
        ld (E_OPT_SD),a
        ret

; HL = the settings, DE = the operations (read or write). NZ if they worked.
sd_run:
        ld a,i
        di
        push af
        push hl                         ; the settings
        push de                         ; the operation
        nextreg $52,SD_PAGE             ; the stub (src/next/sdstub.asm)
        pop de
        ld ($4001),de                   ; the stub's JP: the operation
        pop hl
        push hl
        ld de,SD_BUF                    ; the settings into the buffer
        ld bc,OPT_COUNT
        ldir
        call $4000
        pop de                          ; the buffer back into the settings, if it worked
        ld a,(SD_RESULT)
        or a
        ld a,0
        jr nz,.out
        ld hl,SD_BUF
        ld bc,OPT_COUNT
        ldir
        ld a,1
.out:   ld (sd_ok),a
        nextreg $52,10
        pop af
        jp po,.di
        ei
.di:    ld a,(sd_ok)
        or a
        ret

sd_ok           EQU $20BF

