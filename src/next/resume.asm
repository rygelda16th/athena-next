; ---------------------------------------------------------------------------
; Resume the original game from a snapshot's state, on a ZX Spectrum Next.
;
; Lives in 16K bank 8, page 17, at $E000; the NEX loader pages bank 8 in at
; $C000 and jumps here. Pages 0-15 (banks 0-7) already hold the game's RAM,
; rebuilt byte for byte from the disassembly.
;
; The problem it solves: the 128K paging ports ($7FFD, $DFFD, $1FFD) remap BOTH
; $0000-$3FFF and $C000-$FFFF on every write, so code at $C000 cannot select the
; ROM and then page bank 0 over itself. NextReg $8E can: with bit 3 clear it
; selects the ROM without touching $C000-$FFFF, and with bit 3 set it pages the
; RAM bank as a port write would. The last instruction here pages bank 0 over
; this very code, so the next fetch comes from the GAME at $E985 - where bank 0
; holds a RET (the byte before the in-game interrupt routine at $E986; asserted
; by the build). That RET pops the snapshot's PC, pushed below its SP.
;
; E1 on: every build installs the engine (src/next/engine.asm) in the alternative
; ROM, maps its RAM page at $2000, and ends with NEXTREG $57: the game's own paging
; goes through the engine, so the 128K latches do not matter, and the alternative
; ROM holding the engine stays in.
; ---------------------------------------------------------------------------

resume:
        di
        ld sp,$fff0
        nextreg $07,SPEED               ; 0 = 3.5 MHz, 3 = 28 MHz (the enhanced port runs at 28)

        ; Select the 48K BASIC ROM (1FFD bit 2, 7FFD bit 4). Done from game RAM,
        ; not from here: ZEsarUX treats NextReg $8E like a port write and remaps
        ; $C000-$FFFF even with bit 3 clear, where the Next's documentation says it
        ; must not - which paged bank 0 over this stub and ran the game's beeper
        ; routine at $E009 instead (found by check-play, 2026-09-16). The routine
        ; puts this stub's pages back itself, so either behaviour is safe.
        ld hl,SCRATCH
        ld de,scratch_save
        ld bc,rom_select_len
        ldir
        ld hl,rom_select
        ld de,SCRATCH
        ld bc,rom_select_len
        ldir
        call SCRATCH
        ld hl,scratch_save
        ld de,SCRATCH
        ld bc,rom_select_len
        ldir

        ; The engine (src/next/engine.asm) - and in ORACLE builds the oracle
        ; handler - goes into the Next's alternative ROM, write-protected like a
        ; real ROM (see src/next/oracle.asm for why). With NextReg $8C in write
        ; mode, reads come from the 48K ROM and writes go to the alternative ROM,
        ; so copying $0000-$3FFF onto itself copies the ROM across.
        nextreg $8c,%11100000           ; alt ROM on, write mode, 48K ROM locked
        ld hl,$0000
        ld de,$0000
        ld bc,$4000
        ldir
        ld a,$c3                        ; $0030 (RST $30): JP svc_entry
        ld ($0030),a
        ld hl,svc_entry
        ld ($0031),hl
        nextreg $56,ENGINE_PAGE         ; the engine, assembled to run at ENGINE_ORG
        ld hl,$c000
        ld de,ENGINE_ORG
        ld bc,engine_image_len
        ldir
    IFDEF ORACLE
        ld a,$c3                        ; $0028 (RST $28): JP handler
        ld ($0028),a
        ld hl,handler
        ld ($0029),hl
        ld a,$ef                        ; KEY-SCAN's IN A,(C): RST $28 + its site index
        ld (ROM_SITE),a
        ld a,ROM_SITE_IDX
        ld (ROM_SITE+1),a
        nextreg $56,HANDLER_PAGE        ; the handler, assembled to run at HANDLER_ORG
        ld hl,$c000
        ld de,handler
        ld bc,handler_len
        ldir
    ENDIF
        nextreg $8c,%10100000           ; alt ROM on for reads; writes now ignored

        ; The engine's RAM, at $2000-$3FFF for good.
        nextreg $51,ENGINE_RAM_PAGE
        ld hl,E_BASE
        ld de,E_BASE+1
        ld bc,$1fff
        ld (hl),0
        ldir
        ld hl,"TA"                      ; "ATHE"
        ld (E_MAGIC),hl
        ld hl,"EH"
        ld (E_MAGIC+2),hl
        ld a,SPEED
        ld (E_SPEED),a
        ld a,64                         ; E3: the image cache may use every pattern slot
        ld (E_SLOT_END),a
        ld a,$ff                        ; E5: no sound requests
        ld (E_MUS_REQ),a
        ld (E_FX_REQ),a
    IFDEF ARCADE
        ld a,1                          ; C2: arcade art on (E6's classic mode turns it off)
        ld (E_ARC_ON),a
        call snd_arcade_on              ; E5: the arcade sound on, the beeper off
    ENDIF
        ld bc,$243b                     ; 50 or 60 Hz: NextReg $05 bit 2
        ld a,$05
        out (c),a
        inc b
        in a,(c)
        ld hl,312
        ld e,50
        bit 2,a
        jr z,.hz
        ld hl,262
        ld e,60
.hz:    ld (E_LPF),hl
        ld a,e
        ld (E_HZ),a
        ; E2/E3: Layer 2 in banks 44-46, clipped to the play area, in front of the
        ; ULA (so the original's own play-area picture and sprites are hidden),
        ; with the hardware sprites in front of both; off until the first draw.
        nextreg $12,L2_BANK
        nextreg $16,0
        nextreg $17,0
        nextreg $1c,%00000001           ; reset the Layer 2 clip index
        nextreg $18,24
        nextreg $18,231
        nextreg $18,0
        nextreg $18,127
        nextreg $14,$00                 ; transparent: RGB332 $00, the ULA's black
        nextreg $4a,$00                 ; and what shows through: black
        nextreg $15,%00000000           ; layers: sprites, Layer 2, ULA; sprites off until play
        nextreg $1c,%00000010           ; reset the sprite clip index
        nextreg $19,24                  ; sprites clipped to the play area too
        nextreg $19,231
        nextreg $19,0
        nextreg $19,127
        nextreg $4b,$e3                 ; the sprites' transparent index
        nextreg $69,%00000000
        ; One interrupt a frame, from line 128 - just below the play area -
        ; instead of the ULA's at the top of the frame.
        nextreg $23,INT_LINE
        nextreg $22,%00000110

        ; $5B00-$5CFF as the snapshot has it: a NEX loader may have used it.
        nextreg $56,16
        ld hl,$c000
        ld de,$5b00
        ld bc,$0200
        ldir
        nextreg $56,0                   ; bank 0's first half at $C000, for good

        ld a,REG_R
        ld r,a
        ld a,REG_I
        ld i,a
        im 2

        ld bc,REG_BC_
        ld de,REG_DE_
        ld hl,REG_HL_
        exx
        ld sp,alt_af
        pop af
        ex af,af'
        ld ix,REG_IX
        ld iy,REG_IY
        ld hl,REG_PC                    ; what the final RET will pop
        ld (REG_SP-2),hl
        ld bc,REG_BC
        ld de,REG_DE
        ld hl,REG_HL
        ld sp,main_af
        pop af
        ld sp,REG_SP-2
        jp final

SCRATCH EQU $b880                       ; 16 bytes of bank 2, saved and put back
rom_select:                             ; position independent: runs at SCRATCH
        nextreg $8e,%00000011
        nextreg $56,16
        nextreg $57,17
        ret
rom_select_len EQU $ - rom_select
scratch_save: ds rom_select_len

alt_af: dw REG_A_ << 8 | REG_F_
main_af: dw REG_A << 8 | REG_F

        ORG $e981
final:
        nextreg $57,1                   ; bank 0's second half over this code: the
        ASSERT $ == $e985               ; next fetch is bank 0's RET at $E985. The
                                        ; game's own paging goes through the engine
                                        ; (service 3), so the 128K latches do not matter.
