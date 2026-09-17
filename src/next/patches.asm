; ---------------------------------------------------------------------------
; Where the enhanced port reaches into the original game (E1 on).
;
; Applied to the rebuilt banks after they are loaded, in every build. The
; addresses and the bytes they replace are listed in tools/nexpatches.py, which
; the oracle's stream generator leaves out of every state hash, and
; tools/checknex.py checks the running game holds exactly these differences.
; ---------------------------------------------------------------------------

engine_patches MACRO
        ; bank 2, at $8000
        MMU 4 5, 4, $8000
        ORG $b6b6                       ; three unused bytes (LoaderLeftover)
        jp eng_isr
        ORG $b700                       ; the IM 2 vector table: every entry -> $B6B6
        ds 257,$b6
        ORG $b8d2 : rst $30 : db 3      ; the world loader's seven OUT (C),A to $7FFD
        ORG $b8e4 : rst $30 : db 3
        ORG $b902 : rst $30 : db 3
        ORG $b911 : rst $30 : db 3
        ORG $b923 : rst $30 : db 3
        ORG $b92f : rst $30 : db 3
        ORG $b941 : rst $30 : db 3
        ; bank 0, at $C000
        MMU 6 7, 0, $c000
        ORG $c33b : rst $30 : db 2      ; DrawCarriedItems: EI; HALT
        ORG $c553 : call eng_passhead   ; the main loop's head: CALL $BA8D (E3)
        ORG $c400 : jp eng_waitframes   ; WaitFrames: EI; HALT; DEC HL
        ORG $c408 : jp eng_fx           ; the effect player: POP HL; LD A,(HL); INC HL
        ORG $cefa : rst $30 : db 1      ; the pass's frame wait: EI; HALT
        ORG $d04d : rst $30 : db 4      ; WorldCompleted's flash: EI; HALT (E5: the music stops)
        ORG $d06f : call z,eng_pause    ; the pause's key wait: CALL Z,$C2ED (E2)
        ORG $d137 : call eng_copy       ; the play area's copy: CALL $EBFA (E2)
        ORG $d991 : rst $30 : db 2      ; the feathered blade's extra wait: EI; HALT
        ORG $dec6 : jp eng_tune : nop   ; the tune player: LD ($DECF),SP
        ORG $eb1c : jp eng_d32          ; the 32-pixel drawer: DI; LD ($EB6D),SP (E3)
        ORG $eb72 : jp eng_d16          ; the 16-pixel drawer: DI; LD ($EBAB),SP (E3)
        ORG $ebb0 : jp eng_d24          ; the 24-pixel drawer: DI; LD ($EBF6),SP (E3)
        ORG $edb4 : jp eng_pbg          ; the player's background copy: DI; LD ($EDD1),SP (E3)
        ORG $edd5 : jp eng_play         ; a player piece: DI; LD ($EDFF),SP (E3)
    IFNDEF ORACLE
        ; E6, play builds only (the oracle replays the original's controls)
        ORG $c2e5 : jp eng_anykey       ; AnyKeyHeld: XOR A; IN A,($FE) - a pad button counts
        ORG $f1e4 : call eng_menu_print ; the control menu's CALL $C292: and 6 OPTIONS
        ORG $f23a : jp nz,eng_menu_more ; JP NZ,$F1E7: key 6 opens the options
        ORG $f472 : jp eng_kempston     ; the Kempston template: XOR A; IN A,($1F) - the MD pad
    ENDIF
        ENDM
