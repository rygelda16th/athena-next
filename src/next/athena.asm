; ---------------------------------------------------------------------------
; Athena on the ZX Spectrum Next: the original game, rebuilt from the
; disassembly, as a .nex. Assemble from the repository root:
;
;   sjasmplus -DSPEED=3 src/next/athena.asm            build/athena.nex (28 MHz)
;   sjasmplus -DSPEED=0 -DORACLE src/next/athena.asm   build/g3/athena-oracle-35.nex
;   sjasmplus -DSPEED=3 -DORACLE src/next/athena.asm   build/g3/athena-oracle-28.nex
;
; Add -DARCADE for the arcade art (C2): tools/arcade/mkmapping.py's pages from the
; player's own arcade set, and -arcade in each file name.
;
; The eight RAM banks are check-reasm's output (build/g2/plain/bankN.bin),
; which reproduces the player's snapshot byte for byte; nothing of the game is
; in this file. See docs/where-things-stand.md, G3.
; ---------------------------------------------------------------------------

        DEVICE ZXSPECTRUMNEXT

ENGINE_RAM_PAGE EQU 94                  ; bank 47: the engine's variables, at $2000 in play
ENGINE_PAGE     EQU 82                  ; bank 41: the engine's image, before the stub copies it
HANDLER_ORG     EQU $1C00               ; the oracle handler, in the alternative ROM (the engine is below)

        INCLUDE "build/assets/assets.asm"   ; tools/mkassets.py: the recoloured scenery
    IFDEF ARCADE
        INCLUDE "build/assets/arcade.asm"   ; tools/arcade/mkmapping.py: the arcade art
    ENDIF
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

        INCLUDE "src/next/patches.asm"
        engine_patches
    IFDEF ORACLE
        oracle_pokes
    ENDIF

        ; banks 32-40: the recoloured cell sheets and the world palettes
        MMU 7 n, CELLS_BANK3_PAGE, $e000
        INCBIN "build/assets/cells_bank3.bin"
        MMU 7 n, CELLS_BANK4_PAGE, $e000
        INCBIN "build/assets/cells_bank4.bin"
        MMU 7 n, CELLS_BANK6_PAGE, $e000
        INCBIN "build/assets/cells_bank6.bin"
        MMU 7 n, CELLS_BANK7_PAGE, $e000
        INCBIN "build/assets/cells_bank7.bin"
        MMU 6, PAL_PAGE, $c000
        INCBIN "build/assets/palettes.bin"
    IFDEF ARCADE
        ; banks 48-53: each world bank's arcade map page, then its images
        MMU 6, ARC_BANK3_MAP, $c000
        INCBIN "build/assets/arcade_bank3_map.bin"
        MMU 6 7, ARC_BANK3_PAT, $c000
        INCBIN "build/assets/arcade_bank3_pat.bin"
        MMU 6, ARC_BANK4_MAP, $c000
        INCBIN "build/assets/arcade_bank4_map.bin"
        MMU 6 7, ARC_BANK4_PAT, $c000
        INCBIN "build/assets/arcade_bank4_pat.bin"
        MMU 6, ARC_BANK6_MAP, $c000
        INCBIN "build/assets/arcade_bank6_map.bin"
        MMU 6 7, ARC_BANK6_PAT, $c000
        INCBIN "build/assets/arcade_bank6_pat.bin"
        MMU 6, ARC_BANK7_MAP, $c000
        INCBIN "build/assets/arcade_bank7_map.bin"
        MMU 6 7, ARC_BANK7_PAT, $c000
        INCBIN "build/assets/arcade_bank7_pat.bin"
        ; banks 54-58: the arcade sound (tools/arcade/mksound.py)
        ASSERT SND_PAGES <= 10
        MMU 7 n, SND_PAGE0, $e000
        INCBIN "build/assets/sound.bin"
    ENDIF
        MMU 6 7, 0, $c000

        ; bank 8: page 16 = $5B00-$5CFF as the snapshot has it, page 17 = the stub
        MMU 6, 16, $c000
    IFDEF ORACLE
        INCBIN "build/g3/sysvars_oracle.bin"
    ELSE
        INCBIN "build/g3/sysvars_play.bin"
    ENDIF
        MMU 7, 17, $e000
        INCLUDE "src/next/resume.asm"

        ; bank 41, page 82: the engine, copied into the alternative ROM by the stub
        MMU 6, ENGINE_PAGE, $c000
engine_image:
        DISP ENGINE_ORG
        INCLUDE "src/next/engine.asm"
        ENT
engine_image_len EQU $ - engine_image
    IFDEF ORACLE
        ASSERT ENGINE_ORG + engine_image_len <= HANDLER_ORG
    ELSE
        ASSERT ENGINE_ORG + engine_image_len <= $2000
        ; bank 47, page 95: the SD card stub and the options screen's text (E6)
        MMU 2, SD_PAGE, $4000
        INCLUDE "src/next/sdstub.asm"
        MMU 3, SD_PAGE, $6000
        INCLUDE "src/next/optext.asm"
    ENDIF

    IFDEF ORACLE
        ; bank 9: page 18 = the handler's variables (paged in at $4000 while it
        ; runs), page 19 = the handler, assembled for HANDLER_ORG in the alternative ROM
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
        DISP HANDLER_ORG
        INCLUDE "src/next/oracle.asm"
        ENT
        ASSERT handler_end <= $2000     ; below the engine's RAM at $2000
        ; banks 10 and up: the stream
        MMU 7 n, STREAM_BANK0*2, $e000
        INCBIN "build/g3/stream.bin"
      IFDEF ARCADE
       IF SPEED == 3
        SAVENEX OPEN "build/g3/athena-oracle-28-arcade.nex", resume, $fff0, 8
       ELSE
        SAVENEX OPEN "build/g3/athena-oracle-35-arcade.nex", resume, $fff0, 8
       ENDIF
      ELSE
       IF SPEED == 3
        SAVENEX OPEN "build/g3/athena-oracle-28.nex", resume, $fff0, 8
       ELSE
        SAVENEX OPEN "build/g3/athena-oracle-35.nex", resume, $fff0, 8
       ENDIF
      ENDIF
        SAVENEX CORE 3,0,0
      IFDEF ARCADE
        SAVENEX CFG 0,0,0,1             ; the arcade pages are above bank 47: 2MB machines
      ELSE
        SAVENEX CFG 0,0,0,0
      ENDIF
        SAVENEX BANK 5,2,0,1,3,4,6,7,8,9
        nex_stream_banks
        SAVENEX BANK 32,33,34,35,36,37,38,39,40,41
      IFDEF ARCADE
        SAVENEX BANK 48,49,50,51,52,53,54,55,56,57,58
      ENDIF
    ELSE
      IFDEF ARCADE
        SAVENEX OPEN "build/athena-arcade.nex", resume, $fff0, 8
      ELSE
        SAVENEX OPEN "build/athena.nex", resume, $fff0, 8
      ENDIF
        SAVENEX CORE 3,0,0
      IFDEF ARCADE
        SAVENEX CFG 0,0,0,1             ; the arcade pages are above bank 47: 2MB machines
      ELSE
        SAVENEX CFG 0,0,0,0
      ENDIF
        SAVENEX BANK 5,2,0,1,3,4,6,7,8
        SAVENEX BANK 32,33,34,35,36,37,38,39,40,41,47
      IFDEF ARCADE
        SAVENEX BANK 48,49,50,51,52,53,54,55,56,57,58
      ENDIF
    ENDIF
        SAVENEX CLOSE
