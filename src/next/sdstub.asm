; ---------------------------------------------------------------------------
; E6: the SD card calls for the options (src/next/options.asm, sd_run), in page 95 at
; $4000, put there by the .nex. esxDOS pages itself over $0000-$3FFF during a call,
; which only works with the ROM paged there - not the alternative ROM holding the
; engine, nor the engine's RAM at $2000 - so this runs from $4000 and switches both out
; and back in around the calls, with interrupts off. sd_run writes the operation's
; address into the JP at $4001 and the settings into SD_BUF.
; ---------------------------------------------------------------------------

        ORG $4000
sd_stub:
        jp 0
sd_off: nextreg $8c,%00000000           ; the ROM, not the alternative ROM
        nextreg $51,$ff                 ; and no RAM at $2000: esxDOS's own goes there
        ret
sd_on:  nextreg $51,ENGINE_RAM_PAGE
        nextreg $8c,%10100000
        ret

sd_save_ops:
        call sd_off
        ld a,'*'
        ld ix,sd_name
        ld hl,sd_name
        ld b,$0e                        ; write, create or truncate
        rst $08
        db $9a                          ; F_OPEN
        jr c,.done
        ld (sd_handle),a
        ld ix,SD_BUF
        ld hl,SD_BUF
        ld bc,OPT_COUNT
        rst $08
        db $9e                          ; F_WRITE
        push af
        ld a,(sd_handle)
        rst $08
        db $9b                          ; F_CLOSE
        pop af
        jr c,.done
        xor a
.done:  ld (SD_RESULT),a
        jp sd_on

sd_load_ops:
        call sd_off
        ld a,'*'
        ld ix,sd_name
        ld hl,sd_name
        ld b,$01                        ; read
        rst $08
        db $9a
        jr c,.done
        ld (sd_handle),a
        ld ix,SD_BUF
        ld hl,SD_BUF
        ld bc,OPT_COUNT
        rst $08
        db $9d                          ; F_READ
        push af
        push bc
        ld a,(sd_handle)
        rst $08
        db $9b
        pop bc
        pop af
        jr c,.done
        ld a,c                          ; a short file is no file
        cp OPT_COUNT
        ld a,$ff
        jr nz,.done
        xor a
.done:  ld (SD_RESULT),a
        jp sd_on

sd_handle:      db 0
sd_name:        db "athena.cfg", 0
SD_BUF:         ds OPT_COUNT            ; the settings, as read or to write
SD_RESULT:      db 0                    ; 0 done, else the esxDOS error
