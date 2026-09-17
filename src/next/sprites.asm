; ---------------------------------------------------------------------------
; E3: everything that moves, on the Next's hardware sprites (included in the
; engine, src/next/engine.asm).
;
; WHAT IS DRAWN. The game keeps drawing its sprites on the ULA exactly as it
; always did - so its state, its stack and every operand it saves are unchanged
; for the oracle - but Layer 2 is now in front of the ULA inside the play area's
; clip window, so those ULA pixels are never seen. The engine records every draw
; instead:
;   - the three masked drawers ($EB1C 32 pixels wide, $EB72 16, $EBAF/$EBB0 24):
;     the graphic, its width and lines, the display address, and the call site
;   - the player's build: the background copy ($EDB4) starts it, and each masked
;     piece ($EDD5) is recorded with its place in the 16x32 buffer
; Each hook replaces the routine's first two instructions (DI; LD (nn),SP), runs
; them itself at the same stack depth, and jumps back.
;
; AT THE HEAD OF EACH PASS ($C553, CALL eng_passhead) the recorded draws become
; objects: each is cut into 16x16 hardware sprite images, recoloured (ink,
; the paper inside the mask, transparent where the mask shows the background),
; and the player is composited from its pieces into one 16x32 picture. Images
; are kept in a cache of the Next's 64 pattern slots, keyed by graphic, width,
; lines and tile; a new image goes into a slot no sprite on screen uses, so a
; pattern is never rewritten while it is shown. The player's two images alternate
; between two pairs of slots for the same reason.
;
; GLIDING. Every object is matched with the previous pass's object from the same
; call site that was nearest (within GLIDE_REACH pixels), and after each frame
; interrupt in the pass wait its sprites move from the old position to the new by
; the fraction of GLIDE_TICKS logic ticks that have passed. Unmatched objects
; appear at their place.
; ---------------------------------------------------------------------------

DL_MAX          EQU 40
PL_MAX          EQU 16
OBJ_MAX         EQU 40
SLOT_MAX        EQU 110                 ; hardware sprites in use at most
GLIDE_TICKS     EQU 4
GLIDE_REACH     EQU 32
TRANSPARENT     EQU $e3
IDX_PAPER       EQU 1
IDX_INK         EQU 2
IDX_PLAYER      EQU 3

E_DL_COUNT      EQU $2600               ; draws recorded this pass
E_DL            EQU $2601               ; 8 bytes each: width, lines, gfx(2), dfile(2), site(2)
E_PL_COUNT      EQU $2780               ; player pieces this pass ($FF: no player build seen)
E_PL            EQU $2781               ; 5 bytes each: lines, dest(2), gfx(2)
E_OBJ_COUNT     EQU $2800               ; objects built at the last pass head
E_OBJ           EQU $2801               ; 16 bytes each (below)
E_OLD_COUNT     EQU $2B00
E_OLD           EQU $2B01               ; the previous pass's objects, same layout
E_CUR_TICK      EQU $2E00               ; logic tick the objects were built at
E_SHOWN_SPR     EQU $2E02               ; hardware sprites made visible last frame
E_PSLOT         EQU $2E03               ; the player's pattern pair now shown: 0 or 2
E_STAMP         EQU $2E04               ; cache use counter
E_SPR_REQ       EQU $2E05               ; set by a checker: sample the next pass head and hold
E_SPR_DONE      EQU $2E06               ; samples taken
E_SPR_HOLD      EQU $2E07               ; non-zero: the engine waits at the pass head
E_CACHE         EQU $3400               ; 64 x 8: gfx(2) wl hash-lo tile stamp hash-hi used
E_PAT           EQU $3100               ; the 256-byte image being built
E_PBUF          EQU $3200               ; the player's 16x32 composite (0 clear, 1 paper, 2 ink)
E_DL_LAST       EQU $2E08               ; draws recorded in the pass just built (for the checker)
E_PL_LAST       EQU $2E09               ; player pieces in it ($FF: none)

; object layout (16 bytes)
O_X             EQU 0                   ; 16-bit, screen pixels
O_Y             EQU 2
O_PX            EQU 4                   ; where it glides from
O_PY            EQU 6
O_W             EQU 8                   ; tiles across
O_H             EQU 9                   ; tiles down
O_FLIP          EQU 10                  ; 1: mirrored (the player facing left)
O_SITE          EQU 11                  ; 16-bit call site
O_SLOT0         EQU 13                  ; index into E_SLOTS of its first tile
O_GLIDE         EQU 14                  ; 1 if matched with a previous object
O_KIND          EQU 15                  ; 0: Spectrum tiles; 1: arcade frames (C2): the entry's
                                        ; address in O_W (low) and O_H (high), its value in O_SLOT0

; C2: arcade art (src/next/arcade tables from tools/arcade/mkmapping.py)
E_ARC_ON        EQU $2E10               ; non-zero: look up arcade frames
E_ARC_PAGE      EQU $2E11               ; this world's map page (its images are on the next)
E_SLOT_END      EQU $2E12               ; 8-bit images use slots below this; arcade images above
E_ARC_KEYS      EQU $2E13               ; the map page's key table
E_ARC_NKEYS     EQU $2E15
E_ARC_PLAYER    EQU $2E16               ; the player was shown in arcade art this pass
E_BLOW          EQU $2E17               ; the last pass started a blow
E_PVAL          EQU $2E18               ; the player's pose value
E_MAP_EI        EQU $2E19               ; interrupts were on when the map page went in
ar_key          EQU $2E1A
ar_entry        EQU $2E1C
ar_flags        EQU $2E1E
ar_value        EQU $2E1F
fa_frames       EQU $2E20
fa_per          EQU $2E21
fa_table        EQU $2E22
fa_img          EQU $2E24
fa_pal          EQU $2E25
POSE_WALK       EQU 0
POSE_JUMP       EQU 1
POSE_FALL       EQU 2
POSE_CROUCH     EQU 3
POSE_BLOW       EQU 4
POSE_KICK       EQU 5
E_SLOTS         EQU $3000               ; pattern slot for each tile of each object, in order

; ---- the hooks ------------------------------------------------------------------

eng_d32:
        push af
        push bc
        push de
        push hl
        ld c,32
        call dl_add
        pop hl
        pop de
        pop bc
        pop af
        di
        ld ($eb6d),sp
        jp $eb21

eng_d16:
        push af
        push bc
        push de
        push hl
        ld c,16
        call dl_add
        pop hl
        pop de
        pop bc
        pop af
        di
        ld ($ebab),sp
        jp $eb77

eng_d24:
        push af
        push bc
        push de
        push hl
        ld c,24
        call dl_add
        pop hl
        pop de
        pop bc
        pop af
        di
        ld ($ebf6),sp
        jp $ebb5

; A = lines, C = width, HL = graphic, DE = display address; the drawer's caller's
; return address is at SP+10.
dl_add:
        ld b,a
        ld a,(E_DL_COUNT)
        cp DL_MAX
        ret nc
        push hl
        ld l,a                          ; entry = E_DL + count x 8
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        push de
        ld de,E_DL
        add hl,de
        pop de
        ld (hl),c
        inc hl
        ld (hl),b
        inc hl
        ex (sp),hl                      ; HL = graphic, stack = entry pointer
        ld a,l
        ex (sp),hl
        ld (hl),a
        inc hl
        ex (sp),hl
        ld a,h
        ex (sp),hl
        ld (hl),a
        inc hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        push hl
        ld hl,14                        ; the site: SP+10 at entry, +4 for the two pushes here
        add hl,sp
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ex de,hl                        ; DE = site
        pop hl
        ld (hl),e
        inc hl
        ld (hl),d
        pop hl                          ; the graphic
        ld hl,E_DL_COUNT
        inc (hl)
        ret

eng_pbg:
        push af
        xor a
        ld (E_PL_COUNT),a
        pop af
        di
        ld ($edd1),sp
        jp $edb9

eng_play:
        push af
        push bc
        push de
        push hl
        ld b,a
        ld a,(E_PL_COUNT)
        cp PL_MAX
        jr nc,.full
        push hl
        ld l,a                          ; entry = E_PL + count x 5
        ld h,0
        ld c,l
        add hl,hl
        add hl,hl
        ld a,c
        add a,l
        ld l,a
        ld a,0
        adc a,h
        ld h,a
        ld a,c
        push de
        ld de,E_PL
        add hl,de
        pop de
        ld (hl),b
        inc hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        pop de                          ; the graphic
        ld (hl),e
        inc hl
        ld (hl),d
        ld hl,E_PL_COUNT
        inc (hl)
.full:  pop hl
        pop de
        pop bc
        pop af
        di
        ld ($edff),sp
        jp $edda

; ---- the pass head ----------------------------------------------------------------

eng_passhead:
        push af
        push bc
        push de
        push hl
        push ix
        push iy
        call build_objects
        call snd_passhead               ; E5: the arcade cues the pass head sees
        ld a,(E_SPR_REQ)
        or a
        call nz,spr_sample
        pop iy
        pop ix
        pop hl
        pop de
        pop bc
        pop af
        jp $ba8d                        ; the call it replaced: read the controls

build_objects:
        ; the old objects, for gliding
        ld hl,E_OBJ_COUNT
        ld de,E_OLD_COUNT
        ld bc,1 + OBJ_MAX * 16
        ldir
        xor a
        ld (E_OBJ_COUNT),a
        ld hl,E_STAMP
        inc (hl)
        call cache_unmark
        ld ix,E_OBJ
        ld iy,E_SLOTS
        xor a
        ld (E_ARC_PLAYER),a
        ; the player first
        ld a,(E_PL_COUNT)
        ld (E_PL_LAST),a
        cp $ff
        jr z,.noplayer
        or a
        jr z,.noplayer
        call player_object
.noplayer:
        ld a,$ff
        ld (E_PL_COUNT),a
        ; then every recorded draw, in order
        ld a,(E_DL_COUNT)
        ld (E_DL_LAST),a
        or a
        jr z,.done
        ld b,a
        ld hl,E_DL
.draw:  push bc
        push hl
        call draw_object
        pop hl
        ld de,8
        add hl,de
        pop bc
        djnz .draw
.done:  xor a
        ld (E_DL_COUNT),a
        call match_objects
        ld hl,(E_TICK)
        ld (E_CUR_TICK),hl
        jp frame_update

; HL -> a recorded draw. Adds an object at IX with its tiles' slots at IY.
draw_object:
        ld a,(E_OBJ_COUNT)
        cp OBJ_MAX
        ret nc
        ld c,(hl)                       ; width in pixels
        inc hl
        ld b,(hl)                       ; lines
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)                       ; DE = graphic
        inc hl
        push de
        ld e,(hl)
        inc hl
        ld d,(hl)                       ; DE = display address
        inc hl
        ld a,d
        cp $40
        jp c,.skip                      ; above the screen (the blade's blast): not shown
        cp $58
        jp nc,.skip
        push hl
        call dfile_xy                   ; HL = x, DE = y
        ld (ix+O_X),l
        ld (ix+O_X+1),h
        ld (ix+O_Y),e
        ld (ix+O_Y+1),d
        pop hl
        ld a,(hl)
        ld (ix+O_SITE),a
        inc hl
        ld a,(hl)
        ld (ix+O_SITE+1),a
        ld (ix+O_FLIP),0
        ld a,c                          ; tiles across: (width + 15) / 16
        add a,15
        rrca
        rrca
        rrca
        rrca
        and 15
        ld (ix+O_W),a
        ld a,b
        add a,15
        rrca
        rrca
        rrca
        rrca
        and 15
        ld (ix+O_H),a
        push iy
        pop hl
        ld de,E_SLOTS
        or a
        sbc hl,de
        ld (ix+O_SLOT0),l
        pop hl                          ; the graphic
        ld (ix+O_KIND),0
        ld a,(E_ARC_ON)
        or a
        jr z,.tiles
        push bc
        push hl
        call draw_key
        call arc_lookup
        pop hl
        pop bc
        jr c,.tiles
        ld a,(ar_flags)
        rra
        jp nc,arc_object
        ld a,(E_ARC_PLAYER)             ; a weapon the arcade player carries itself
        or a
        jp nz,arc_object
.tiles:
        ; each tile: ty down, tx across
        ld e,0                          ; ty
.ty:    ld d,0                          ; tx
.tx:    push bc
        push de
        push hl
        call tile_slot                  ; A = slot for (HL, C width, B lines, D tx, E ty)
        ld (iy+0),a
        inc iy
        pop hl
        pop de
        pop bc
        inc d
        ld a,d
        cp (ix+O_W)
        jr nz,.tx
        inc e
        ld a,e
        cp (ix+O_H)
        jr nz,.ty
        ld de,16
        add ix,de
        ld hl,E_OBJ_COUNT
        inc (hl)
        ret
.skip:  pop de
        ret

; DE = display address -> HL = x, DE = y (screen pixels).
dfile_xy:
        ld a,e
        and 31
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl                       ; x = column x 8
        push hl
        ld a,d
        rrca
        rrca
        rrca
        and 3                           ; third
        ld h,a
        ld a,e
        rlca
        rlca
        rlca
        and 7                           ; row within the third
        ld l,a
        ld a,h
        add a,a
        add a,a
        add a,a                         ; third x 8 rows
        add a,l
        add a,a
        add a,a
        add a,a                         ; x 8 lines
        ld l,a
        ld a,d
        and 7
        add a,l
        ld e,a
        ld d,0
        pop hl
        ret

; ---- the pattern cache ----------------------------------------------------------------

cache_unmark:
        ld hl,E_CACHE+7
        ld de,8
        ld b,64
.u:     ld (hl),0
        add hl,de
        djnz .u
        ret

; A = the slot holding (graphic HL, width C, lines B, tile D,E), built and uploaded if new.
tile_slot:
        ld a,d
        rlca
        rlca
        rlca
        rlca
        or e
        ld (ts_tile),a
        ld (ts_gfx),hl
        ld a,c
        ld (ts_w),a
        ld a,b
        ld (ts_lines),a
        ld a,c                          ; wl = (bytes a line - 1) x 64 + lines
        rrca
        rrca
        rrca
        and 7
        dec a
        rrca
        rrca
        and $c0
        or b
        ld (ts_wl),a
        call tile_hash                  ; ts_hash: the tile's source bytes, which can change
        ; look for it                   ; under the same address (the weapon copy is mirrored in place)
        push ix
        ld ix,E_CACHE+32                ; slots 0-3 are the player's
        ld c,4
.look:  ld a,(ix+0)
        cp l
        jr nz,.next
        ld a,(ix+1)
        cp h
        jr nz,.next
        ld a,(ts_wl)
        cp (ix+2)
        jr nz,.next
        ld a,(ts_tile)
        cp (ix+4)
        jr nz,.next
        ld a,(ts_hash)
        cp (ix+3)
        jr nz,.next
        ld a,(ts_hash+1)
        cp (ix+6)
        jr nz,.next
        ld (ix+7),1                     ; used by this pass's objects
        ld a,(E_STAMP)
        ld (ix+5),a
        ld a,c
        pop ix
        ret
.next:  ld de,8
        add ix,de
        inc c
        ld a,(E_SLOT_END)
        cp c
        jr nz,.look
        ; not there: the oldest slot no object shown or being built uses
        call victim                     ; A = slot, IX = its cache entry
        push af
        ld hl,(ts_gfx)
        ld (ix+0),l
        ld (ix+1),h
        ld a,(ts_wl)
        ld (ix+2),a
        ld a,(ts_hash)
        ld (ix+3),a
        ld a,(ts_hash+1)
        ld (ix+6),a
        ld a,(ts_tile)
        ld (ix+4),a
        ld a,(E_STAMP)
        ld (ix+5),a
        ld (ix+7),1
        call build_tile
        pop af
        push af
        call upload_pattern
        pop af
        pop ix
        ret

; ts_hash = h = rotl16(h) xor byte over the tile's mask and graphic bytes (ts_*).
tile_hash:
        push bc
        push de
        push hl
        ld hl,0
        ld (ts_hash),hl
        ld a,(ts_tile)
        and 15
        add a,a
        add a,a
        add a,a
        add a,a
        ld (th_line),a                  ; first line
        ld a,(ts_tile)
        rrca
        rrca
        rrca
        rrca
        and 15
        add a,a
        ld (th_b0),a                    ; first screen byte of the tile: 2 x tx
        ld a,(ts_w)
        rrca
        rrca
        rrca
        and 7
        ld (th_wb),a
        ld b,16
.line:  ld a,(th_line)
        ld c,a
        ld a,(ts_lines)
        dec a
        cp c
        jr c,.done                      ; past the graphic
        push bc
        ld a,(th_wb)                    ; row = gfx + line x 2 x wb
        add a,a
        ld h,0
        ld l,a
        ld a,c
        call mul_hl_a
        ld de,(ts_gfx)
        add hl,de
        ld a,(th_b0)                    ; + 2 x first byte
        add a,a
        ld e,a
        ld d,0
        add hl,de
        ld a,(th_wb)                    ; bytes of this tile: min(2, wb - 2 x tx)
        ld c,a
        ld a,(th_b0)
        ld d,a
        ld a,c
        sub d
        jr c,.nobytes
        jr z,.nobytes
        cp 2
        jr c,.one
        ld a,2
.one:   add a,a                         ; mask and graphic
        ld c,a
.byte:  ld de,(ts_hash)
        ex de,hl
        add hl,hl                       ; rotate left 16
        jr nc,.nc
        inc l
.nc:    ex de,hl
        ld a,(hl)
        xor e
        ld e,a
        ld (ts_hash),de
        inc hl
        dec c
        jr nz,.byte
.nobytes:
        pop bc
        ld hl,th_line
        inc (hl)
        djnz .line
.done:  pop hl
        pop de
        pop bc
        ret

ts_wl           EQU $2EEB
ts_hash         EQU $2EEC
th_line         EQU $2EEE
th_b0           EQU $2EEF
th_wb           EQU $2EDF

ts_gfx          EQU $2E0A
ts_w            EQU $2E0C
ts_lines        EQU $2E0D
ts_tile         EQU $2E0E

; The cache slot to reuse, oldest first: one this pass's objects do not use and no sprite
; shows; failing that (the arcade build keeps fewer 8-bit slots), one this pass does not
; use, which the frame update straight after re-points. A = the slot, IX = its entry.
victim:
        ld a,1
        ld (vt_tier),a
.tier:  ld ix,E_CACHE+32
        ld c,4
        ld b,$ff                        ; best slot: none yet
        ld l,0                          ; its age + 1
.v:     ld a,(ix+7)
        or a
        jr nz,.vn                       ; used this pass
        ld a,(vt_tier)
        dec a
        jr nz,.age
        ld a,c
        call slot_shown
        jr nz,.vn                       ; shown
.age:   ld a,(E_STAMP)
        sub (ix+5)
        inc a
        jr nz,.a1
        dec a                           ; 255 or older
.a1:    cp l
        jr c,.vn
        jr z,.vn
        ld l,a
        ld b,c
.vn:    ld de,8
        add ix,de
        inc c
        ld a,(E_SLOT_END)
        cp c
        jr nz,.v
        ld a,b
        cp $ff
        jr nz,.found
        ld a,(vt_tier)
        inc a
        ld (vt_tier),a
        cp 3
        jr c,.tier
        ld hl,(E_CACHE_FULL)            ; every slot used this pass: the cache is too small
        inc hl
        ld (E_CACHE_FULL),hl
        ld b,4
        jr .slot
.found: ld a,(vt_tier)
        dec a
        jr z,.slot
        ld hl,(E_CACHE_SHOWN)           ; a shown slot had to be taken
        inc hl
        ld (E_CACHE_SHOWN),hl
.slot:  ld a,b
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,E_CACHE
        add hl,de
        push hl
        pop ix
        ret

vt_tier         EQU $2E26
E_CACHE_SHOWN   EQU $2E27               ; times a slot a sprite showed was reused (16 bits)
E_CACHE_FULL    EQU $2E29               ; times no slot was free at all (16 bits)

; Z clear if slot A is shown by a visible hardware sprite (the last frame update's).
slot_shown:
        push bc
        push hl
        ld c,a
        ld hl,E_SHOWN_TABLE
        ld a,(E_SHOWN_SPR)
        or a
        jr z,.no
        ld b,a
.s:     ld a,(hl)
        cp c
        jr z,.yes
        inc hl
        djnz .s
.no:    xor a
        pop hl
        pop bc
        ret
.yes:   or 1
        pop hl
        pop bc
        ret

E_SHOWN_TABLE   EQU $2F00               ; the pattern slot of each visible sprite, last frame

; Build E_PAT for the tile described by ts_*: the graphic's pixels in that 16x16
; square; ink where the graphic bit is set, transparent where only the mask is,
; paper where neither is; transparent past the graphic's width or lines.
build_tile:
        ld a,(ts_tile)
        and 15
        ld (bt_ty),a
        ld a,(ts_tile)
        rrca
        rrca
        rrca
        rrca
        and 15
        ld (bt_tx),a
        ld a,(ts_w)
        rrca
        rrca
        rrca
        and 7
        ld (bt_wb),a
        ld hl,E_PAT
        ld b,0                          ; py
.py:    ld a,(bt_ty)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,b                         ; line
        ld c,a
        ld a,(ts_lines)
        dec a
        cp c
        jr c,.blank                     ; line >= lines
        push hl
        ld a,(bt_wb)                    ; row = gfx + line x 2 x wb
        add a,a
        ld h,0
        ld l,a
        ld a,c
        call mul_hl_a
        ld de,(ts_gfx)
        add hl,de
        ld (bt_row),hl
        pop hl
        ld c,0                          ; px
.px:    ld a,(bt_tx)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,c                         ; X
        ld (bt_x),a
        rrca
        rrca
        rrca
        and 31                          ; screen byte
        ld e,a
        ld a,(bt_wb)
        dec a
        cp e
        ld a,TRANSPARENT
        jr c,.put                       ; byte >= wb
        push hl
        ld hl,(bt_row)
        ld d,0
        add hl,de
        add hl,de
        ld a,(hl)
        ld (bt_mask),a
        inc hl
        ld a,(hl)
        ld (bt_gfx),a
        ld a,(bt_x)
        and 7
        ld e,a
        ld a,$80
        jr z,.bit
.sh:    srl a
        dec e
        jr nz,.sh
.bit:   ld e,a                          ; E = the pixel's bit
        pop hl
        ld a,(bt_gfx)
        and e
        ld a,IDX_INK
        jr nz,.put
        ld a,(bt_mask)
        and e
        ld a,TRANSPARENT
        jr nz,.put
        ld a,IDX_PAPER
.put:   ld (hl),a
        inc hl
        inc c
        ld a,c
        cp 16
        jr nz,.px
        jr .next
.blank: ld c,16
.bl:    ld (hl),TRANSPARENT
        inc hl
        dec c
        jr nz,.bl
.next:  inc b
        ld a,b
        cp 16
        jp nz,.py
        ret

bt_wb           EQU $2E0F
bt_row          EQU $2EF0
bt_tx           EQU $2EE2
bt_ty           EQU $2EE3
bt_x            EQU $2EE4
bt_mask         EQU $2EE5
bt_gfx          EQU $2EE6

; HL = HL x A (A small).
mul_hl_a:
        push de
        ex de,hl
        ld hl,0
        or a
        jr z,.done
.m:     add hl,de
        dec a
        jr nz,.m
.done:  pop de
        ret

; Upload E_PAT to pattern slot A.
upload_pattern:
        push bc
        push hl
        ld bc,$303b
        out (c),a
        ld hl,E_PAT
        ld bc,$005b                     ; B = 0: 256 bytes
        otir
        pop hl
        pop bc
        ret

; ---- the player ------------------------------------------------------------------------

player_object:
        ld (ix+O_KIND),0
        ld a,(E_ARC_ON)
        or a
        jr z,.spectrum
        call player_key                 ; C: a pose the mapping cannot show
        jr c,.spectrum
        call arc_lookup
        jr c,.spectrum
        call player_place
        ret c
        ld (ix+O_FLIP),0
        ld (ix+O_SITE),$ff
        ld (ix+O_SITE+1),$ff
        ld a,1
        ld (E_ARC_PLAYER),a
        jp arc_object
.spectrum:
        ; composite the pieces
        ld hl,E_PBUF
        ld de,E_PBUF+1
        ld bc,511
        ld (hl),0
        ldir
        ld a,(E_PL_COUNT)
        ld b,a
        ld hl,E_PL
.piece: push bc
        push hl
        call player_piece
        pop hl
        ld de,5
        add hl,de
        pop bc
        djnz .piece
        call player_place
        ret c
        ld (ix+O_W),1
        ld (ix+O_H),2
        ld a,($b952)                    ; FacingLeft
        or a
        jr z,.fl
        ld a,1
.fl:    ld (ix+O_FLIP),a
        ld (ix+O_SITE),$ff
        ld (ix+O_SITE+1),$ff
        push iy
        pop hl
        ld de,E_SLOTS
        or a
        sbc hl,de
        ld (ix+O_SLOT0),l
        ; the two images, into the pair not shown now
        ld a,(E_PSLOT)
        xor 2
        ld (E_PSLOT),a
        ld c,a
        ld hl,E_PBUF
        call player_tile
        ld (iy+0),c
        inc iy
        inc c
        ld hl,E_PBUF+256
        call player_tile
        ld (iy+0),c
        inc iy
        ld de,16
        add ix,de
        ld hl,E_OBJ_COUNT
        inc (hl)
        ret

; HL -> 256 composite states: build and upload them to slot C.
player_tile:
        push bc
        ld de,E_PAT
        ld b,0
.p:     ld a,(hl)
        inc hl
        or a
        ld a,TRANSPARENT
        jr z,.put
        dec hl
        ld a,(hl)
        inc hl
        cp 2
        ld a,IDX_PLAYER
        jr z,.put
        ld a,IDX_PAPER
.put:   ld (de),a
        inc de
        djnz .p
        pop bc
        ld a,c
        jp upload_pattern

; HL -> a recorded piece: lines, dest(2), gfx(2). Masks it into E_PBUF the way
; #R$EDD5 masks it into the player buffer: a graphic bit sets ink, a clear mask bit
; with a clear graphic bit sets paper, a set mask bit keeps what is there.
player_piece:
        ld a,(hl)
        ld (pp_lines),a
        inc hl
        ld a,(hl)                       ; dest low byte: $5C00 + 2 x line
        srl a
        ld (pp_line),a
        inc hl
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (pp_gfx),de
.line:  ld a,(pp_lines)
        or a
        ret z
        ld a,(pp_line)
        cp 32
        ret nc
        ld l,a                          ; DE = E_PBUF + line x 16
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,E_PBUF
        add hl,de
        ex de,hl
        ld hl,(pp_gfx)
        ld c,2
.byte:  ld a,(hl)                       ; mask
        inc hl
        ld b,(hl)                       ; graphic
        inc hl
        push hl
        ld h,a
        ld l,8
.bits:  rl b
        jr nc,.nog
        ld a,2
        ld (de),a
        rl h
        jr .nb
.nog:   rl h
        jr c,.nb
        ld a,1
        ld (de),a
.nb:    inc de
        dec l
        jr nz,.bits
        pop hl
        dec c
        jr nz,.byte
        ld (pp_gfx),hl
        ld hl,pp_line
        inc (hl)
        ld hl,pp_lines
        dec (hl)
        jr .line

pp_lines        EQU $2EE7
pp_line         EQU $2EE8
pp_gfx          EQU $2EE9

; Position at IX from the display address at $B94E, two bytes right of the player.
; C if the player is not on the screen.
player_place:
        ld de,($b94e)
        dec e
        dec e
        ld a,d
        cp $40
        ret c
        cp $58
        ccf
        ret c
        call dfile_xy
        ld (ix+O_X),l
        ld (ix+O_X+1),h
        ld (ix+O_Y),e
        ld (ix+O_Y+1),d
        or a
        ret

; ---- arcade art (C2) --------------------------------------------------------------------

; HL = the player's key: facing (bit 13), weapon kind (bits 8-10), pose; E_PVAL its
; value. C when the arcade art has no such pose: climbing, flying, gliding, armour.
player_key:
        ld a,($b94a)                    ; ClimbState
        ld hl,$ba27                     ; Flying
        or (hl)
        ld hl,$ba24                     ; ArmourA-ArmourC
        or (hl)
        inc hl
        or (hl)
        inc hl
        or (hl)
        ld hl,$ce4b                     ; the glide operand
        or (hl)
        scf
        ret nz
        ; a blow: AttackFlag (the operand at $C95B) is set on the pass one starts, and
        ; the pass after it is the blow's second
        ld a,($c95b)
        or a
        ld c,0
        jr nz,.blow
        ld a,(E_BLOW)
        or a
        ld c,1
        jr z,.noblow
.blow:  ld a,c
        cpl
        and 1
        ld (E_BLOW),a                   ; 1 after the first pass, 0 after the second
        ld a,($ba2c)                    ; WeaponKind
        ld b,POSE_KICK
        cp 5
        jr z,.pose
        jr nc,.noblow
        or a
        jr z,.noblow
        ld b,POSE_BLOW
        jr .pose
.noblow:
        ld c,0
        ld b,POSE_CROUCH
        ld a,($ba07)                    ; Crouching
        or a
        jr nz,.pose
        ld b,POSE_JUMP
        ld a,($b953)                    ; JumpCounter: 4 - it, 0-3
        or a
        jr z,.nojump
        cp 5
        jr nc,.pose
        cpl
        add a,5
        ld c,a
        jr .pose
.nojump:
        ld b,POSE_FALL
        ld a,($b954)                    ; Falling
        or a
        jr nz,.pose
        ld b,POSE_WALK
        ld a,($b949)                    ; 2 x PlayerFrame + bit 0 of PlayerAnimTimer
        and 3
        add a,a
        ld c,a
        ld a,($b950)
        and 1
        or c
        ld c,a
.pose:  ld a,c
        ld (E_PVAL),a
        ld a,($ba2c)
        and 7
        ld h,a
        ld a,($b952)                    ; FacingLeft
        or a
        jr z,.right
        set 5,h
.right: ld l,b
        or a
        ret

; HL = a drawn graphic -> HL = its key: itself, or for the mirrored weapon copy at
; $EE60-$EF7F the weapon's own graphic (WeaponGfxAddr) at the same offset, bit 15 set.
draw_key:
        push de
        push hl
        ld de,$ee60
        or a
        sbc hl,de
        jr c,.plain
        ld de,$0120
        sbc hl,de
        jr nc,.plain
        add hl,de
        ld de,($ba2e)
        add hl,de
        set 7,h
        pop de
        pop de
        ret
.plain: pop hl
        pop de
        ret

; HL = key. NC: found, with ar_entry, ar_flags and ar_value set. C: not in the map.
arc_lookup:
        ld (ar_key),hl
        ld a,(E_ARC_NKEYS)
        or a
        scf
        ret z
        ld b,a
        call map_in
        ld hl,(E_ARC_KEYS)
.k:     ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ld hl,(ar_key)
        or a
        sbc hl,de
        pop hl
        jr z,.hit
        jr c,.miss                      ; the keys are in order
        inc hl
        inc hl
        djnz .k
.miss:  call map_out
        scf
        ret
.hit:   ld e,(hl)
        inc hl
        ld d,(hl)
        ld (ar_entry),de
        ld a,(de)
        ld (ar_flags),a
        inc de
        inc de
        inc de
        ld a,(de)
        ld l,a
        inc de
        ld a,(de)
        ld h,a                          ; HL = where the value comes from
        call map_out
        ld a,h
        or a
        jr nz,.addr
        ld a,l
        or a
        ld a,(E_PASSES)
        jr z,.val
        ld a,(E_PVAL)
        jr .val
.addr:  ld a,(hl)
.val:   ld (ar_value),a
        or a
        ret

; The object at IX shows the entry just looked up.
arc_object:
        ld hl,(ar_entry)
        ld (ix+O_W),l
        ld (ix+O_H),h
        ld a,(ar_value)
        ld (ix+O_SLOT0),a
        ld (ix+O_KIND),1
        ld de,16
        add ix,de
        ld hl,E_OBJ_COUNT
        inc (hl)
        ret

; The world's map page in at $4000 with interrupts off, and out again.
map_in:
        ld a,i
        di
        ld a,0
        jp po,.off
        inc a
.off:   ld (E_MAP_EI),a
        ld a,(E_ARC_PAGE)
        nextreg $52,a
        ret

map_out:
        nextreg $52,10
        ld a,(E_MAP_EI)
        or a
        ret z
        ei
        ret

; Show the arcade object at IX: frame (value x frames a pass + the pass's fraction)
; mod frames, each piece a 4-bit sprite at the object's gliding place plus its offset.
fu_arc:
        call map_in
        ld l,(ix+O_W)
        ld h,(ix+O_H)
        inc hl
        ld a,(hl)
        ld (fa_frames),a
        inc hl
        ld a,(hl)
        ld (fa_per),a
        inc hl
        inc hl
        inc hl
        ld (fa_table),hl
        ld b,a                          ; value x frames a pass
        ld e,(ix+O_SLOT0)
        ld d,0
        ld hl,0
.mul:   add hl,de
        djnz .mul
        push hl
        ld a,(fa_per)                   ; + min(t x frames a pass / 4, frames a pass - 1)
        ld b,a
        ld a,(fu_t)
        ld e,a
        ld hl,0
.mt:    add hl,de
        djnz .mt
        srl l
        srl l
        ld a,(fa_per)
        dec a
        cp l
        jr c,.cl
        ld a,l
.cl:    pop hl
        ld e,a
        ld d,0
        add hl,de
        ld a,(fa_frames)
        call mod_hl_a
        add a,a
        ld e,a
        ld d,0
        ld hl,(fa_table)
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)                       ; DE = the frame
        ld a,(de)
        inc de
        or a
        jp z,map_out
        ld b,a
.piece: ld a,(fu_n)
        cp SLOT_MAX
        jp nc,map_out
        push bc
        ld a,(de)                       ; X = x + dx + 32
        inc de
        call sext_a
        push de
        ld de,(fu_x)
        add hl,de
        ld de,32
        add hl,de
        ld (fu_sx),hl
        pop de
        ld a,(de)                       ; Y = y + dy + 32
        inc de
        call sext_a
        push de
        ld de,(fu_y)
        add hl,de
        ld de,32
        add hl,de
        pop de
        ld a,(de)
        inc de
        ld (fa_img),a
        ld a,(de)
        inc de
        ld (fa_pal),a
        push de
        ld a,(fu_n)
        ld bc,$303b
        out (c),a
        ld bc,$0057
        ld de,(fu_sx)
        ld a,e
        out (c),a                       ; attr 0: X
        ld a,l
        out (c),a                       ; attr 1: Y
        ld a,d
        and 1
        ld e,a
        ld a,(fa_pal)
        or e
        out (c),a                       ; attr 2: palette offset, X MSB
        ld a,(fa_img)
        and 63
        or %11000000
        out (c),a                       ; attr 3: visible, attr 4 follows, pattern
        ld a,(fa_img)
        and $40
        or $80
        ld e,a
        ld a,h
        and 1
        or e
        out (c),a                       ; attr 4: 4-bit, the pattern's 7th bit, Y MSB
        ld de,(fu_shown)
        ld a,$ff                        ; no 8-bit slot
        ld (de),a
        inc de
        ld (fu_shown),de
        pop de
        ld hl,fu_n
        inc (hl)
        pop bc
        dec b
        jp nz,.piece
        jp map_out

; HL = A sign-extended.
sext_a:
        ld l,a
        rla
        sbc a,a
        ld h,a
        ret

; A = HL mod A (A non-zero).
mod_hl_a:
        ld c,a
        ld b,16
        xor a
.d:     add hl,hl
        rla
        jr c,.sub
        cp c
        jr c,.n
.sub:   sub c
        inc l
.n:     djnz .d
        ret

; World set-up with arcade art: this world's palette blocks, key table and images.
arc_world:
        ld a,(E_ARC_ON)
        or a
        ret z
        ld a,(E_PAL_WORLD)
        ld c,a
        ld b,0
        ld hl,arc_pages-1
        add hl,bc
        ld a,(hl)
        ld (E_ARC_PAGE),a
        call map_in
        ld a,($4002)                    ; images: 4-bit patterns 127 down
        ld (fa_frames),a
        ld b,a
        ld a,128
        sub b
        srl a
        ld (E_SLOT_END),a               ; 8-bit images stay below them
        ld a,($4003)
        ld (E_ARC_NKEYS),a
        nextreg $43,%00100000           ; the sprites' first palette
        ld hl,$4004
        ld b,(hl)
        inc hl
        ld a,b
        or a
        jr z,.noblk
.blk:   ld a,(hl)                       ; block number
        inc hl
        add a,a
        add a,a
        add a,a
        add a,a
        nextreg $40,a
        ld c,32
.col:   ld a,(hl)
        inc hl
        nextreg $44,a
        dec c
        jr nz,.col
        djnz .blk
.noblk: ld (E_ARC_KEYS),hl
        ld a,(E_ARC_PAGE)               ; the images, from the next page
        inc a
        nextreg $52,a
        inc a
        nextreg $53,a
        ld hl,$4000
        ld a,(fa_frames)
        ld b,a
        ld c,127
.img:   push bc
        ld a,c
        srl a
        bit 0,c
        jr z,.even
        or $80                          ; the pattern's second half
.even:  ld bc,$303b
        out (c),a
        ld bc,$805b
        otir
        pop bc
        dec c
        djnz .img
        nextreg $53,11
        jp map_out

arc_pages:
    IFDEF ARCADE
        db ARC_BANK3_MAP, ARC_BANK3_MAP, ARC_BANK4_MAP, ARC_BANK4_MAP
        db ARC_BANK6_MAP, ARC_BANK6_MAP, ARC_BANK7_MAP
    ELSE
        db 0, 0, 0, 0, 0, 0, 0
    ENDIF

; ---- gliding ------------------------------------------------------------------------

; For each new object, the nearest old object from the same site within reach.
match_objects:
        ld a,(E_OBJ_COUNT)
        or a
        ret z
        ld b,a
        ld ix,E_OBJ
.obj:   push bc
        ld (ix+O_GLIDE),0
        ld a,(E_OLD_COUNT)
        or a
        jr z,.none
        ld c,a
        ld iy,E_OLD
        ld hl,$7fff
        ld (mo_best),hl
.old:   ld a,(iy+O_SITE)
        cp (ix+O_SITE)
        jr nz,.onext
        ld a,(iy+O_SITE+1)
        cp (ix+O_SITE+1)
        jr nz,.onext
        ; distance = |dx| + |dy|
        ld l,(ix+O_X)
        ld h,(ix+O_X+1)
        ld e,(iy+O_X)
        ld d,(iy+O_X+1)
        or a
        sbc hl,de
        call abs_hl
        push hl
        ld l,(ix+O_Y)
        ld h,(ix+O_Y+1)
        ld e,(iy+O_Y)
        ld d,(iy+O_Y+1)
        or a
        sbc hl,de
        call abs_hl
        pop de
        add hl,de
        ld de,GLIDE_REACH+1
        or a
        sbc hl,de
        jr nc,.onext
        add hl,de
        ld de,(mo_best)
        or a
        sbc hl,de
        jr nc,.onext
        add hl,de
        ld (mo_best),hl
        ld a,(iy+O_X)
        ld (ix+O_PX),a
        ld a,(iy+O_X+1)
        ld (ix+O_PX+1),a
        ld a,(iy+O_Y)
        ld (ix+O_PY),a
        ld a,(iy+O_Y+1)
        ld (ix+O_PY+1),a
        ld (ix+O_GLIDE),1
.onext: ld de,16
        add iy,de
        dec c
        jr nz,.old
.none:  ld de,16
        add ix,de
        pop bc
        dec b
        jp nz,.obj
        ret

mo_best         EQU $2EF2

abs_hl:
        bit 7,h
        ret z
        ld a,h
        cpl
        ld h,a
        ld a,l
        cpl
        ld l,a
        inc hl
        ret

; Set every visible sprite, and Layer 2's scroll, for this display frame. Keeps IX and IY.
frame_update:
        push ix
        push iy
        call scroll_update
        call fu_body
        pop iy
        pop ix
        ret

; E4: Layer 2's X offset = old + (new - old) x t / GLIDE_TICKS, t the logic ticks since
; the pass set the new offset (the shorter way round, as a signed 8-bit difference).
scroll_update:
        ld hl,(E_TICK)
        ld de,(E_L2_TICK)
        or a
        sbc hl,de
        ld a,h
        or a
        ld a,GLIDE_TICKS
        jr nz,.t
        ld a,l
        cp GLIDE_TICKS
        jr c,.t
        ld a,GLIDE_TICKS
.t:     ld c,a                          ; C = t
        ld a,(E_L2_OFF_OLD)
        ld b,a
        ld a,(E_L2_OFF_NEW)
        sub b                           ; A = signed difference
        ld e,a
        ld d,0
        bit 7,e
        jr z,.m
        dec d                           ; DE = sign-extended difference
.m:     ld hl,0
        ld a,c
        or a
        jr z,.z
.mul:   add hl,de
        dec c
        jr nz,.mul
.z:     sra h
        rr l
        sra h
        rr l                            ; / 4
        ld a,l
        add a,b
        ld (E_L2_OFF_SHOWN),a
        nextreg $16,a
        ld a,(E_SCR_REQ)                ; a checker wants a frame in mid-glide
        or a
        ret z
        ld a,(E_L2_OFF_OLD)
        ld b,a
        ld a,(E_L2_OFF_NEW)
        cp b
        ret z
        ld hl,(E_TICK)
        ld de,(E_L2_TICK)
        or a
        sbc hl,de
        ld a,h
        or a
        ret nz
        ld a,l
        or a
        ret z
        cp GLIDE_TICKS
        ret nc
        ld (E_SCR_SAMPLE+2),a
        ld a,b
        ld (E_SCR_SAMPLE),a
        ld a,(E_L2_OFF_NEW)
        ld (E_SCR_SAMPLE+1),a
        ld a,(E_L2_OFF_SHOWN)
        ld (E_SCR_SAMPLE+3),a
        ld hl,E_SCR_DRAW                ; the draw's inputs, frozen with the sample
        ld de,E_SCR_FROZEN
        ld bc,127
        ldir
        xor a
        ld (E_SCR_REQ),a
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
        ld hl,E_SCR_DONE
        inc (hl)
        ret

E_L2_OFF_SHOWN  EQU $2041               ; the offset set this frame (for the checker)

fu_body:
        ld a,(E_SPR_HOLD)
        or a
        ld a,GLIDE_TICKS
        jr nz,.held
        ld hl,(E_TICK)
        ld de,(E_CUR_TICK)
        or a
        sbc hl,de
        ld a,h
        or a
        ld a,GLIDE_TICKS
        jr nz,.held
        ld a,l
        cp GLIDE_TICKS
        jr c,.held
        ld a,GLIDE_TICKS
.held:  ld (fu_t),a
        ld a,(E_OBJ_COUNT)
        ld (fu_left),a
        xor a
        ld (fu_n),a
        ld ix,E_OBJ
        ld hl,E_SHOWN_TABLE
        ld (fu_shown),hl
.obj:   ld a,(fu_left)
        or a
        jp z,.hide
        dec a
        ld (fu_left),a
        ; position: glide from P to X by t / GLIDE_TICKS
        ld l,(ix+O_X)
        ld h,(ix+O_X+1)
        ld a,(ix+O_GLIDE)
        or a
        jr z,.nx
        ld e,(ix+O_PX)
        ld d,(ix+O_PX+1)
        call glide
.nx:    ld (fu_x),hl
        ld l,(ix+O_Y)
        ld h,(ix+O_Y+1)
        ld a,(ix+O_GLIDE)
        or a
        jr z,.ny
        ld e,(ix+O_PY)
        ld d,(ix+O_PY+1)
        call glide
.ny:    ld (fu_y),hl
        ld a,(ix+O_KIND)
        or a
        jr z,.ftiles
        call fu_arc
        ld de,16
        add ix,de
        jp .obj
.ftiles:
        ; tiles
        ld a,(ix+O_SLOT0)
        ld e,a
        ld d,0
        ld hl,E_SLOTS
        add hl,de
        ld (fu_slotp),hl
        ld c,0                          ; ty
.fty:   ld b,0                          ; tx
.ftx:   ld a,(fu_n)
        cp SLOT_MAX
        jr nc,.skiptile
        push bc
        ; X = x + 32 + 16 x (flip ? w - 1 - tx : tx)
        ld a,(ix+O_FLIP)
        or a
        ld a,b
        jr z,.nf
        ld a,(ix+O_W)
        dec a
        sub b
.nf:    add a,a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,(fu_x)
        add hl,de
        ld de,32
        add hl,de
        ld (fu_sx),hl
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,(fu_y)
        add hl,de
        ld de,32
        add hl,de                       ; HL = Y
        ld a,(fu_n)
        push bc
        ld bc,$303b
        out (c),a
        ld bc,$0057
        ld de,(fu_sx)
        ld a,e
        out (c),a                       ; attr 0: X
        ld a,l
        out (c),a                       ; attr 1: Y
        ld a,d
        and 1
        ld e,a
        ld a,(ix+O_FLIP)
        rlca
        rlca
        rlca
        and 8
        or e
        out (c),a                       ; attr 2: X mirror, X MSB
        ld de,(fu_slotp)
        ld a,(de)
        inc de
        ld (fu_slotp),de
        ld de,(fu_shown)
        ld (de),a
        inc de
        ld (fu_shown),de
        and 63
        or %11000000
        out (c),a                       ; attr 3: visible, attr 4 follows, pattern
        ld a,h
        and 1
        out (c),a                       ; attr 4: 8-bit pattern, Y MSB
        pop bc
        ld hl,fu_n
        inc (hl)
        pop bc
.skiptile:
        inc b
        ld a,b
        cp (ix+O_W)
        jp nz,.ftx
        inc c
        ld a,c
        cp (ix+O_H)
        jp nz,.fty
        ld de,16
        add ix,de
        jp .obj
.hide:  ; hide sprites shown last frame beyond this frame's count
        ld a,(fu_n)
        ld c,a
        ld a,(E_SHOWN_SPR)
        cp c
        jr c,.hdone
        jr z,.hdone
        ld b,a
.h:     ld a,c
        push bc
        ld bc,$303b
        out (c),a
        ld bc,$0057
        xor a
        out (c),a
        out (c),a
        out (c),a
        out (c),a                       ; attr 3: invisible, no attr 4
        pop bc
        inc c
        ld a,c
        cp b
        jr nz,.h
.hdone: ld a,(fu_n)
        ld (E_SHOWN_SPR),a
        ret

fu_t            EQU $2EF4
fu_left         EQU $2EF5
fu_n            EQU $2EF6
fu_x            EQU $2EF7
fu_y            EQU $2EF9
fu_sx           EQU $2EFB
fu_slotp        EQU $2EFD
fu_shown        EQU $2EE0

; HL = new, DE = old -> HL = old + (new - old) x t / GLIDE_TICKS.
glide:
        ld a,(fu_t)
        cp GLIDE_TICKS
        ret nc
        or a
        sbc hl,de                       ; HL = delta
        push de
        ld e,l
        ld d,h
        ld hl,0
        or a
        jr z,.z
.m:     add hl,de
        dec a
        jr nz,.m
.z:     sra h                           ; / 4
        rr l
        sra h
        rr l
        pop de
        add hl,de
        ret

; ---- the checker's sample (tools/checksprites.py) ----------------------------------------
; Copies the recorded draws, the player's pieces and the objects, shows the objects at
; their final places, and holds the game at the pass head until the checker clears
; E_SPR_HOLD.
spr_sample:
        xor a
        ld (E_SPR_REQ),a
        ld a,1
        ld (E_SPR_HOLD),a
        call frame_update
        ld hl,E_SPR_DONE
        inc (hl)
.hold:  ei
        halt
        ld a,(E_SPR_HOLD)
        or a
        jr nz,.hold
        ret
