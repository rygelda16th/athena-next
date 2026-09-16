; ---------------------------------------------------------------------------
; The oracle handler: feed the game every value it took from outside during
; Rafal's recording, in order, and check its state as it goes.
;
; WHERE IT LIVES, AND WHY. The build patches every port read and every LD A,R
; the recording executed into RST $28 + a site index byte (tools/mkstream.py
; lists them), so something must answer at $0028. That something cannot be RAM:
; the game's text printer ($C25x) draws off-screen text into $0000-$3FFF, which
; on a Spectrum is ROM and ignores it - in RAM it wrote over the handler's jump
; at $0028 and killed the second tune service (found 2026-09-16). So the stub
; copies the 48K ROM into the Next's alternative ROM (NextReg $8C), patches the
; jump at $0028 and KEY-SCAN's IN A,(C) there, puts this code in the 48K ROM's
; unused space from $386E, and write-protects it. Writes to $0000-$3FFF are then
; ignored, exactly as the game expects.
;
; The handler's variables are in page VARS_PAGE and the stream in pages from
; STREAM_BANK0*2; both are paged in at $4000 and $6000 only while the handler
; runs (interrupts off) and the game's own pages are put back before it hashes
; game state, applies a tune record, or returns.
;
; Services (the byte after RST $28 has bit 7 set):
;   $80  OUT (C),A to $7FFD - page the RAM bank through MMU6/MMU7
;   $82  CALL $DED9 at $DECA, the tune player - do not play the tune; apply the
;        stream's tune record (the bytes it changed, the registers it left) and
;        continue at $DECD, its exit, as the reference did
;
; Verdict block at the start of VARS_PAGE (tools/checknex.py reads it by
; physical address):
;   +0  "ATHO"   +4 status: 0 running, 1 PASS (end of stream reached),
;                   2 wrong site, 3 wrong hash
;   +5  events consumed (24 bits)   +8 checkpoints passed (16)
;   +10 site wanted by the game     +11 site the stream holds
;   +12 hash expected (16)          +14 hash computed (16)   +16 kind
;   +17 return address of the RST (16)
; ---------------------------------------------------------------------------

GAME_MMU2 EQU 10                        ; bank 5 and bank 2 low halves, as the
GAME_MMU3 EQU 11                        ; game always has them at $4000-$7FFF

handler:
        push af                         ; SP+6 = F, SP+7 = A
        push bc
        push de
        push hl
        ld a,i                          ; P/V = IFF2: were interrupts on?
        di
        ld a,0
        jp po,.ints
        inc a
.ints:  nextreg $52,VARS_PAGE
        ld (v_int),a
        ld hl,8                         ; the RST's return address, which points
        add hl,sp                       ; at the site byte; step it past that byte
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (v_ret),de
        ld a,(de)
        inc de
        ld (hl),d
        dec hl
        ld (hl),e
        or a
        jp m,service

        ld (v_want),a
        ld a,(v_rep)
        or a
        jr z,.record
        dec a                           ; another event of the current run
        ld (v_rep),a
        ld a,(v_site)
        ld b,a
        ld a,(v_want)
        cp b
        jp nz,fail_site
        jr .deliver

.record:
        call stream_in
        call next_byte
        ld (v_flags),a
        and $1f
        cp $1f
        jp z,pass
        ld (v_site),a
        ld b,a
        ld a,(v_want)
        cp b
        jp nz,fail_site
        call next_byte
        ld (v_a),a
        ld a,(v_site)
        ld e,a
        ld d,0
        ld hl,site_kind
        add hl,de
        ld a,(hl)
        ld (v_kind),a
        or a
        jr z,.nof
        call next_byte
        ld (v_f),a
.nof:   ld a,(v_flags)
        bit 6,a
        jr z,.norep
        call next_byte
        ld (v_rep),a
.norep: ld a,(v_flags)
        bit 7,a
        jr z,.deliver
        call next_byte
        ld (v_ckind),a
        call next_byte
        ld (v_hash),a
        call next_byte
        ld (v_hash+1),a
        call checkpoint

.deliver:
        ld hl,6
        add hl,sp
        ld a,(v_kind)
        or a
        jr z,.keepf
        ld a,(v_f)
        ld (hl),a
.keepf: inc hl
        ld a,(v_a)
        ld (hl),a
        ld hl,(v_events)
        inc hl
        ld (v_events),hl
        ld a,h
        or l
        jr nz,exit
        ld hl,v_events+2
        inc (hl)

exit:   ld a,(v_int)
        nextreg $52,GAME_MMU2
        nextreg $53,GAME_MMU3
        or a
        jr z,.di
        pop hl
        pop de
        pop bc
        pop af
        ei
        ret
.di:    pop hl
        pop de
        pop bc
        pop af
        ret

; RST $28 + $80 replaces OUT (C),A with BC = $7FFD: page the 16K RAM bank A
; names at $C000 through the MMU, which leaves $0000-$3FFF alone.
service:
        cp $82
        jp z,tune
        ld hl,7
        add hl,sp
        ld a,(hl)
        and 7
        add a,a
        nextreg $56,a
        inc a
        nextreg $57,a
        jr exit

tune:
        ld (v_want),a
        call stream_in
        call next_byte
        ld (v_site),a
        cp $1f                          ; the recording ended before this tune did:
        jp z,pass                       ; everything it held has been replayed
        cp $1d
        jp nz,fail_site
        call next_byte
        ld (v_count),a
        call next_byte
        ld (v_count+1),a
.poke:  ld hl,(v_count)
        ld a,h
        or l
        jr z,.regs
        dec hl
        ld (v_count),hl
        call next_byte
        ld e,a
        call next_byte
        ld d,a
        call next_byte
        nextreg $52,GAME_MMU2           ; the game's own memory for the write
        nextreg $53,GAME_MMU3
        ld (de),a
        nextreg $52,VARS_PAGE
        call stream_in
        jr .poke
.regs:  ld de,v_treg
        ld b,18
.rb:    call next_byte
        ld (de),a
        inc de
        djnz .rb
        ld hl,10                        ; forget the handler's frame and the RST:
        add hl,sp                       ; the stack is as it was at $DECA
        ld sp,hl
        ld bc,(v_treg+12)               ; alternate set first
        ld de,(v_treg+14)
        ld hl,(v_treg+16)
        exx
        ld hl,(v_treg+10)               ; F' low, A' high
        push hl
        pop af
        ex af,af'
        ld ix,(v_treg+6)
        ld iy,(v_treg+8)
        ld bc,(v_treg+2)
        ld de,(v_treg+4)
        ld hl,(v_treg+0)                ; F low, A high
        push hl
        pop af
        nextreg $52,GAME_MMU2
        nextreg $53,GAME_MMU3
        jp $decd                        ; the tune's exit: DI, SP back, vector back, EI, RET

; Page the stream's current page in at $6000.
stream_in:
        ld a,(v_page)
        nextreg $53,a
        ret

; A = the next stream byte; preserves BC and DE.
next_byte:
        ld hl,(v_ptr)
        ld a,(hl)
        inc hl
        bit 7,h
        jr z,.same
        ld hl,$6000
        push af
        ld a,(v_page)
        inc a
        ld (v_page),a
        nextreg $53,a
        pop af
.same:  ld (v_ptr),hl
        ret

; Hash the regions for checkpoint kind (v_ckind) with the game's own memory
; paged in, and compare with v_hash.
checkpoint:
        ld hl,(v_hash)
        push hl                         ; expected
        ld a,(v_ckind)
        ld hl,light_regions
        or a
        jr z,.table
        ld hl,full_regions
.table: push ix
        push hl
        pop ix
        nextreg $52,GAME_MMU2
        nextreg $53,GAME_MMU3
        ld hl,0
.region:
        ld e,(ix+0)
        ld d,(ix+1)
        ld c,(ix+2)
        ld b,(ix+3)
        inc ix
        inc ix
        inc ix
        inc ix
        ld a,b
        or c
        jr z,.done
.byte:  add hl,hl                       ; h = rotl16(h) ^ byte
        jr nc,.nc
        inc l
.nc:    ld a,(de)
        xor l
        ld l,a
        inc de
        dec bc
        ld a,b
        or c
        jr nz,.byte
        jr .region
.done:  pop ix
        pop de                          ; expected
        nextreg $52,VARS_PAGE
        call stream_in
        ld (v_got),hl
        or a
        sbc hl,de
        jp nz,fail_hash
        ld hl,(v_checks)
        inc hl
        ld (v_checks),hl
        ret

pass:   ld a,1
        jr stop
fail_site:
        ld a,2
        jr stop
fail_hash:
        ld a,3
stop:   ld (v_status),a
.hang:  di
        halt
        jr .hang

site_kind:
        site_kind_table
light_regions:
        light_region_table
full_regions:
        full_region_table
handler_end:
handler_len EQU handler_end - handler
