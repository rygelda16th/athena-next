; ---------------------------------------------------------------------------
; E2: the play area on Layer 2 (included in the engine, src/next/engine.asm).
;
; The game still builds its back buffer and copies it to the screen; the copy's
; call at $D137 now comes here (eng_copy), and after the original copy the play
; area is drawn on Layer 2 from the map, recoloured (tools/mkassets.py). Since E3
; Layer 2 is in front of the ULA inside its clip window, so the original's own
; picture and sprites there are never seen; the hardware sprites are in front of
; both (src/next/sprites.asm).
;
; THE PICTURE. As the original's buffer holds it (tools/l2ref.py, the reference):
; 15 map columns of 8 cells from the column before the map window, shifted left 2
; pixels a scroll step. On Layer 2 each map column has a fixed slot - its address
; divided by 8, modulo 16 - and the shift is Layer 2's X offset (NextReg $16), so
; only a change of window moves pictures. A shadow table holds the cell drawn in
; each slot's 8 rows, and a pass draws only the cells that differ from it: the
; column coming into view when the window moves, and cells the game changed.
;
; NEXTREGS. The interrupt routine switches Layer 2 on and off with NEXTREG
; instructions, which select a register and write it in one step. So the engine
; never selects a register through port $243B while interrupts are on; the only
; reads (the video line, in engine.asm's now) select and read with interrupts
; off.
;
; SHOWN ONLY IN PLAY. Layer 2 is on while passes are being drawn (the last draw
; less than HIDE_TICKS logic ticks ago) or the game is paused; otherwise - the
; world intro card, LIFE LOST, the hi-score table, the title - the ULA shows alone.
; ---------------------------------------------------------------------------

L2_BANK         EQU 44                  ; Layer 2 in 16K banks 44-46 (8K pages 88-93)
L2_PAGE0        EQU 88
HIDE_TICKS      EQU 25

E_PAL_WORLD     EQU $2020               ; the world whose palette is loaded (0 = none)
E_LAST_DRAW     EQU $2021               ; logic tick of the last play-area draw
E_PAUSED        EQU $2023               ; non-zero while the game waits in its pause
E_L2_SHOWN      EQU $2024               ; non-zero while Layer 2 is on
E_DRAWS         EQU $2025               ; play-area draws (16 bits)
E_CELLS_PAGE    EQU $2027               ; the current bank's first cell-sheet page
E_CELLS_COUNT   EQU $2028               ; cells in its sheet
E_BADCELLS      EQU $2029               ; codes that pointed past the sheet (16 bits)
E_SAMPLE_REQ    EQU $202B               ; set by a checker: keep the next draw's inputs and output
E_SAMPLE_DONE   EQU $202C               ; draws sampled
E_SAMPLE        EQU $3600               ; sample: window(2) shift world offset, the 120 map codes,
                                        ; the item and background blocks
E_SHADOW        EQU $3710               ; 16 slots x 8 rows: the cell drawn there ($FF = none)
E_COPY_RET      EQU $203A               ; the copy's real return address ($D13A)
E_L2_OFF_OLD    EQU $203C               ; E4: Layer 2's X offset at the last pass...
E_L2_OFF_NEW    EQU $203D               ; ...and this pass's
E_L2_TICK       EQU $203E               ; the logic tick this pass's offset was set on (16 bits)
E_L2_SNAP       EQU $2040               ; non-zero: the next offset is set, not glided to
E_SCR_REQ       EQU $2042               ; set by a checker: sample the next frame in mid-glide
E_SCR_DONE      EQU $2043               ; scroll samples taken
E_SCR_DRAW      EQU $3680               ; the last draw: window(2) shift world -, 120 codes, item, background
E_SCR_SAMPLE    EQU $3700               ; a sample: old new t shown
E_SCR_FROZEN    EQU $2500               ; a sample: the draw's inputs as E_SCR_DRAW held them
SAMPLE_PAGE0    EQU 84                  ; ...and the 256x128 Layer 2 lines, in pages 84-87
; the drawing's working variables (the engine's code is in ROM: nothing mutable there)
draw_window     EQU $2030
draw_col        EQU $2032
draw_shift      EQU $2034
draw_slot       EQU $2035
draw_offset     EQU $2036
draw_i          EQU $2037
draw_x          EQU $2038
draw_row        EQU $2039

; The copy's call at $D137. $EBFA saves SP into its own code ($EC98), which the
; oracle hashes, so it must run at the original's stack depth: the return address
; is swapped for the tail's and the copy is jumped to, not called.
eng_copy:
        ex (sp),hl
        ld (E_COPY_RET),hl
        ld hl,eng_copy_tail
        ex (sp),hl
        jp $ebfa                        ; the original copy, with every side effect it has
eng_copy_tail:
        push hl                         ; return to $D13A in the end
        push hl
        ld hl,(E_COPY_RET)
        ex (sp),hl
        pop hl
        ex (sp),hl                      ; the stack: $D13A; HL as $EBFA left it
        push af
        push bc
        push de
        push hl
        push ix
        push iy
        exx
        push bc
        push de
        push hl
        exx
        ex af,af'
        push af
        ex af,af'
        call draw_play
        pop af
        ex af,af'
        exx
        pop hl
        pop de
        pop bc
        exx
        pop iy
        pop ix
        pop hl
        pop de
        pop bc
        pop af
        ret

; Columns 3-28 of pixel lines 0-127 to paper.
ula_clear:
        ld hl,$4003
        ld c,128
.line:  push hl
        ld (hl),0
        ld d,h
        ld e,l
        inc de
        ld b,0
        push bc
        ld bc,25
        ldir
        pop bc
        pop hl
        ld de,32
        add hl,de
        dec c
        jr nz,.line
        ret

; The pause's key wait at $D06F: CALL Z,$C2ED comes here.
eng_pause:
        push af
        ld a,1
        ld (E_PAUSED),a
        pop af
        call $c2ed
        push af
        xor a
        ld (E_PAUSED),a
        pop af
        ret

; Called from eng_isr on every logic tick: Layer 2 on in play, off otherwise.
l2_visibility:
        push af
        push hl
        push de
        ld a,(E_PAUSED)
        or a
        jr nz,.on
        ld hl,(E_TICK)
        ld de,(E_LAST_DRAW)
        or a
        sbc hl,de
        ld a,h
        or a
        jr nz,.off
        ld a,l
        cp HIDE_TICKS
        jr nc,.off
.on:    ld a,(E_CLASSIC)                ; E6: classic mode keeps the original's picture
        or a
        jr nz,.off
        ld a,(E_DRAWS)
        ld hl,E_DRAWS+1
        or (hl)
        jr z,.off                       ; nothing drawn yet
        ld a,(E_L2_SHOWN)
        or a
        jr nz,.done
        nextreg $69,%10000000           ; Layer 2 on
        nextreg $15,%00000001           ; and the sprites (layers: sprites, Layer 2, ULA)
        ld a,1
        ld (E_L2_SHOWN),a
        jr .done
.off:   ld a,(E_L2_SHOWN)
        or a
        jr z,.done
        nextreg $69,%00000000           ; Layer 2 off
        nextreg $15,%00000000           ; and the sprites
        xor a
        ld (E_L2_SHOWN),a
.done:  pop de
        pop hl
        pop af
        ret

; ---- drawing ----------------------------------------------------------------------

; The world's palette and cell sheet, when the world changes.
world_setup:
        ld (E_PAL_WORLD),a
        ld c,a
        ld b,0
        ld hl,world_cells-1
        add hl,bc
        ld a,(hl)                       ; the bank's first sheet page
        ld (E_CELLS_PAGE),a
        ld hl,world_count-1
        add hl,bc
        ld a,(hl)
        ld (E_CELLS_COUNT),a
        ld a,c                          ; palette: page PAL_PAGE, 512 bytes a world from 0
        dec a
        add a,a                         ; world - 1, times 2 ($0200 bytes each)
        ld h,a
        ld l,0
        ld de,$4000
        add hl,de
        nextreg $52,PAL_PAGE
        nextreg $43,%00010000           ; Layer 2's first palette, written from index 0
        nextreg $40,0
        ld b,0
.pal:   ld a,(hl)
        inc hl
        nextreg $44,a
        ld a,(hl)
        inc hl
        nextreg $44,a
        djnz .pal
        ; the sprite palette (E3): paper, the world's highlight as ink, the player
        ld a,(E_PAL_WORLD)
        dec a
        add a,a
        ld h,a
        ld l,18 * 2                     ; index 18 (HIGHLIGHT) of this world's palette
        ld de,$4000
        add hl,de
        nextreg $43,%00100000           ; the sprites' first palette
        nextreg $40,IDX_PAPER
        nextreg $44,%00100100           ; paper: dark grey-green
        nextreg $44,0
        ld a,(hl)
        nextreg $44,a                   ; ink: the world's highlight
        inc hl
        ld a,(hl)
        nextreg $44,a
        nextreg $44,%11101101           ; the player: warm pink
        nextreg $44,1
        ld a,1
        ld (E_L2_SNAP),a                ; E4: no glide into a new world
        ld hl,E_SHADOW                  ; nothing is drawn in this world's colours yet
        ld de,E_SHADOW+1
        ld bc,127
        ld (hl),$ff
        ldir
        call arc_world                  ; C2: the arcade images and colours, if any
        nextreg $52,10                  ; bank 5's first half back
        ret

world_cells:    db CELLS_BANK3_PAGE, CELLS_BANK3_PAGE, CELLS_BANK4_PAGE, CELLS_BANK4_PAGE
                db CELLS_BANK6_PAGE, CELLS_BANK6_PAGE, CELLS_BANK7_PAGE
world_count:    db CELLS_BANK3_COUNT, CELLS_BANK3_COUNT, CELLS_BANK4_COUNT, CELLS_BANK4_COUNT
                db CELLS_BANK6_COUNT, CELLS_BANK6_COUNT, CELLS_BANK7_COUNT

draw_play:
        ld a,($ba33)                    ; WorldNumber
        dec a
        cp 7
        ret nc                          ; not in a world
        inc a
        ld hl,E_PAL_WORLD
        cp (hl)
        call nz,world_setup
        ; the window and the shift (tools/l2ref.py window_and_shift)
        ld hl,($ba17)                   ; MapWindow
        ld a,($d4a2)                    ; the scroll step count
        ld c,a
        ld a,($b952)                    ; facing
        ld b,a
        ld a,c
        cp 9
        jr c,.le8
        sub 8
        ld c,a
        ld de,8
        inc b
        dec b
        jr z,.back
        add hl,de
        jr .le8
.back:  or a
        sbc hl,de
.le8:   inc b
        dec b
        jr z,.left
        ld a,c
        cp 8
        jr nz,.right
        ld de,8
        add hl,de
        xor a
        jr .shift
.right: ld a,c
        jr .shift
.left:  ld a,8
        sub c
.shift: ld (draw_shift),a
        ld (draw_window),hl
        ; X offset = 16 x ((window / 8) - 1) - 8 + 2 x shift
        ld de,-8
        add hl,de                       ; the first column drawn: window - 8
        ld (draw_col),hl
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l                            ; L = its slot, before masking
        ld a,l
        ld (draw_slot),a
        add a,a
        add a,a
        add a,a
        add a,a
        sub 8
        ld b,a
        ld a,(draw_shift)
        add a,a
        add a,b
        ld (draw_offset),a
        ; E4: glide Layer 2's offset from the last pass's to this one's over the pass
        ; (frame_update sets it each frame); a jump of more than 16 pixels snaps
        ld b,a
        ld a,(E_L2_OFF_NEW)
        ld (E_L2_OFF_OLD),a
        ld c,a
        ld a,b
        ld (E_L2_OFF_NEW),a
        sub c
        jp p,.pos
        neg
.pos:   cp 17
        jr c,.glide
        ld a,b
        ld (E_L2_OFF_OLD),a
.glide: ld hl,(E_TICK)
        ld (E_L2_TICK),hl
        ld a,(E_L2_SNAP)
        or a
        jr z,.nosnap
        xor a
        ld (E_L2_SNAP),a
        ld a,b
        ld (E_L2_OFF_OLD),a
.nosnap:
        ; 15 columns x 8 cells
        ld a,15
        ld (draw_i),a
.col:   ld a,(draw_slot)
        and 15
        ld (draw_x),a
        ld a,0
        ld (draw_row),a
.cell:  ld hl,(draw_col)
        ld a,(draw_row)
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        call cell_index                 ; A = the cell to draw
        ld c,a
        ld a,(draw_x)                   ; the shadow entry: slot x 8 + row
        add a,a
        add a,a
        add a,a
        ld hl,draw_row
        add a,(hl)
        ld e,a
        ld d,0
        ld hl,E_SHADOW
        add hl,de
        ld a,c
        cp (hl)
        jr z,.same
        ld (hl),a
        call put_cell
.same:
        ld a,(draw_row)
        inc a
        ld (draw_row),a
        cp 8
        jr nz,.cell
        ld hl,(draw_col)
        ld de,8
        add hl,de
        ld (draw_col),hl
        ld a,(draw_slot)
        inc a
        ld (draw_slot),a
        ld a,(draw_i)
        dec a
        ld (draw_i),a
        jr nz,.col
        ld hl,(E_TICK)
        ld (E_LAST_DRAW),hl
        ld hl,(E_DRAWS)
        inc hl
        ld (E_DRAWS),hl
        ; E4: keep this draw's inputs for a scroll sample (tools/checkscroll.py)
        ld hl,(draw_window)
        ld (E_SCR_DRAW),hl
        ld a,(draw_shift)
        ld (E_SCR_DRAW+2),a
        ld a,($ba33)
        ld (E_SCR_DRAW+3),a
        ld hl,(draw_window)
        ld de,-8
        add hl,de
        ld de,E_SCR_DRAW+5
        ld bc,120
        ldir
        ld a,($de09)
        ld (de),a
        inc de
        ld a,($ceca)
        ld (de),a
        ld a,(E_SAMPLE_REQ)
        or a
        call nz,sample
        ret


; A = map code -> A = cell index (#R$DDFD; $79/$7A show the world's background cell).
cell_index:
        cp $79
        jr nc,.a
        cp $60
        jr c,.lt60
        ld a,($de09)                    ; the world's item block
        jr .a
.lt60:  cp $46
        jr nc,.bg
        cp $10
        jr c,.bg
        cp $2e
        jr c,.a
        add a,$32                       ; item pictures
        jr .a
.bg:    ld a,($ceca)                    ; the world's background block
.a:     sub $60
        cp $19
        jr z,.swap
        cp $1a
        jr nz,.range
.swap:  ld a,(E_PAL_WORLD)
        rra
        ld a,$21
        ret c                           ; odd worlds: the first of the bank
        inc a
        ret
.range: ld hl,E_CELLS_COUNT
        cp (hl)
        ret c
        ld hl,(E_BADCELLS)
        inc hl
        ld (E_BADCELLS),hl
        ld a,($ceca)
        sub $60
        ret

; Copy cell A to Layer 2 at slot (draw_x) x 16, line (draw_row) x 16.
put_cell:
        ld l,a
        rrca
        rrca
        rrca
        rrca
        rrca
        and 7                           ; the sheet page: cell / 32
        ld b,a
        ld a,(E_CELLS_PAGE)
        add a,b
        nextreg $52,a                   ; the cell's page at $4000
        ld a,l
        and 31
        ld h,a
        ld l,0
        ld de,$4000
        add hl,de                       ; HL = the cell
        ld a,(draw_row)
        ld b,a
        srl a
        add a,L2_PAGE0
        nextreg $53,a                   ; the Layer 2 page holding that cell row, at $6000
        ld a,b
        and 1                           ; line 0 or 16 within the page
        rrca
        rrca
        rrca
        rrca
        ld d,a                          ; x 256 lines... 16 lines = $1000
        ld a,(draw_x)
        add a,a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld a,d
        add a,$60
        ld d,a                          ; DE = $6000 + line x 256 + x
        ld a,16
.line:  push de
        ld bc,16
        ldir
        pop de
        inc d
        dec a
        jr nz,.line
        nextreg $52,10
        nextreg $53,11
        ret

; A checker asked for this draw: keep its inputs and output (tools/checkrender.py).
sample:
        xor a
        ld (E_SAMPLE_REQ),a
        ld hl,(draw_window)
        ld (E_SAMPLE),hl
        ld a,(draw_shift)
        ld (E_SAMPLE+2),a
        ld a,($ba33)
        ld (E_SAMPLE+3),a
        ld a,(draw_offset)
        ld (E_SAMPLE+4),a
        ld hl,(draw_window)
        ld de,-8
        add hl,de
        ld de,E_SAMPLE+5
        ld bc,120
        ldir
        ld a,($de09)
        ld (de),a
        inc de
        ld a,($ceca)
        ld (de),a
        ld b,4                          ; Layer 2 lines 0-127 -> pages 84-87
        ld c,0
.pg:    ld a,c
        add a,L2_PAGE0
        nextreg $52,a
        ld a,c
        add a,SAMPLE_PAGE0
        nextreg $53,a
        push bc
        ld hl,$4000
        ld de,$6000
        ld bc,$2000
        ldir
        pop bc
        inc c
        djnz .pg
        nextreg $52,10
        nextreg $53,11
        ld hl,E_SAMPLE_DONE
        inc (hl)
        ret
