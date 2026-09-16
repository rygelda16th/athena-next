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
; ORACLE builds (src/next/oracle.asm) replace the last write with NEXTREG $57:
; the game's own paging goes through the oracle handler there, so the 128K
; latches do not matter, and the alternative ROM holding the handler stays in.
; ---------------------------------------------------------------------------

resume:
        di
        ld sp,$fff0
        nextreg $07,SPEED               ; 0 = 3.5 MHz, 3 = 28 MHz

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

    IFDEF ORACLE
        ; The oracle handler goes into the Next's alternative ROM, write-protected
        ; like a real ROM (see src/next/oracle.asm for why). With NextReg $8C in
        ; write mode, reads come from the 48K ROM and writes go to the alternative
        ; ROM, so copying $0000-$3FFF onto itself copies the ROM across.
        nextreg $8c,%11100000           ; alt ROM on, write mode, 48K ROM locked
        ld hl,$0000
        ld de,$0000
        ld bc,$4000
        ldir
        ld a,$c3                        ; $0028 (RST $28): JP handler
        ld ($0028),a
        ld hl,handler
        ld ($0029),hl
        ld a,$ef                        ; KEY-SCAN's IN A,(C): RST $28 + its site index
        ld (ROM_SITE),a
        ld a,ROM_SITE_IDX
        ld (ROM_SITE+1),a
        nextreg $56,HANDLER_PAGE        ; the handler, assembled to run at $386E
        ld hl,$c000
        ld de,handler
        ld bc,handler_len
        ldir
        nextreg $8c,%10100000           ; alt ROM on for reads; writes now ignored
    ENDIF

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
    IFDEF ORACLE
        nextreg $57,1
    ELSE
        nextreg $8e,%00001011           ; bank 0 at $C000 (ports 7FFD/DFFD say so too), 48K ROM
    ENDIF
        ASSERT $ == $e985               ; the next fetch is bank 0's RET at $E985
