; ---------------------------------------------------------------------------
; Athena on the ZX Spectrum Next: the original game, rebuilt from the
; disassembly, as a .nex. Assemble from the repository root:
;
;   sjasmplus -DSPEED=0 src/next/athena.asm            build/athena.nex
;   sjasmplus -DSPEED=0 -DORACLE src/next/athena.asm   build/g3/athena-oracle-35.nex
;   sjasmplus -DSPEED=3 -DORACLE src/next/athena.asm   build/g3/athena-oracle-28.nex
;
; The eight RAM banks are check-reasm's output (build/g2/plain/bankN.bin),
; which reproduces the player's snapshot byte for byte; nothing of the game is
; in this file. See docs/where-things-stand.md, G3.
; ---------------------------------------------------------------------------

        DEVICE ZXSPECTRUMNEXT

    IFDEF ORACLE
        INCLUDE "build/g3/oracle_gen.asm"
VARS_PAGE    EQU 18
HANDLER_PAGE EQU 19
    ELSE
        INCLUDE "build/g3/play_gen.asm"
    ENDIF

        MMU 6 7, 0, $c000
        INCBIN "build/g2/plain/bank0.bin"
        MMU 6 7, 2, $c000
        INCBIN "build/g2/plain/bank1.bin"
        MMU 6 7, 4, $c000
        INCBIN "build/g2/plain/bank2.bin"
        MMU 6 7, 6, $c000
        INCBIN "build/g2/plain/bank3.bin"
        MMU 6 7, 8, $c000
        INCBIN "build/g2/plain/bank4.bin"
        MMU 6 7, 10, $c000
        INCBIN "build/g2/plain/bank5.bin"
        MMU 6 7, 12, $c000
        INCBIN "build/g2/plain/bank6.bin"
        MMU 6 7, 14, $c000
        INCBIN "build/g2/plain/bank7.bin"
        MMU 6 7, 0, $c000
        ASSERT {b $e985} == $c9

    IFDEF ORACLE
        oracle_pokes
    ENDIF

        ; bank 8: page 16 = $5B00-$5CFF as the snapshot has it, page 17 = the stub
        MMU 6, 16, $c000
    IFDEF ORACLE
        INCBIN "build/g3/sysvars_oracle.bin"
    ELSE
        INCBIN "build/g3/sysvars_play.bin"
    ENDIF
        MMU 7, 17, $e000
        INCLUDE "src/next/resume.asm"

    IFDEF ORACLE
        ; bank 9: page 18 = the handler's variables (paged in at $4000 while it
        ; runs), page 19 = the handler, assembled for $386E in the alternative ROM
        MMU 2, VARS_PAGE, $4000
v_magic:  db "ATHO"
v_status: db 0
v_events: db 0,0,0
v_checks: dw 0
v_want:   db 0
v_site:   db 0
v_hash:   dw 0
v_got:    dw 0
v_ckind:  db 0
v_ret:    dw 0
v_page:   db STREAM_BANK0*2
v_ptr:    dw $6000
v_rep:    db 0
v_a:      db 0
v_f:      db 0
v_kind:   db 0
v_flags:  db 0
v_int:    db 0
v_count:  dw 0
v_treg:   ds 18
        MMU 6, HANDLER_PAGE, $c000
        DISP $386e
        INCLUDE "src/next/oracle.asm"
        ENT
        ASSERT handler_end <= $3d00     ; the 48K ROM's unused space ends at $3CFF
        ; banks 10 and up: the stream
        MMU 7 n, STREAM_BANK0*2, $e000
        INCBIN "build/g3/stream.bin"
      IF SPEED == 3
        SAVENEX OPEN "build/g3/athena-oracle-28.nex", resume, $fff0, 8
      ELSE
        SAVENEX OPEN "build/g3/athena-oracle-35.nex", resume, $fff0, 8
      ENDIF
        SAVENEX CORE 3,0,0
        SAVENEX CFG 0,0,0,0
        SAVENEX BANK 5,2,0,1,3,4,6,7,8,9
        nex_stream_banks
    ELSE
        SAVENEX OPEN "build/athena.nex", resume, $fff0, 8
        SAVENEX CORE 3,0,0
        SAVENEX CFG 0,0,0,0
        SAVENEX BANK 5,2,0,1,3,4,6,7,8
    ENDIF
        SAVENEX CLOSE
