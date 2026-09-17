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
        ORG $c400 : jp eng_waitframes   ; WaitFrames: EI; HALT; DEC HL
        ORG $c408 : jp eng_fx           ; the effect player: POP HL; LD A,(HL); INC HL
        ORG $cefa : rst $30 : db 1      ; the pass's frame wait: EI; HALT
        ORG $d04d : rst $30 : db 2      ; WorldCompleted's flash: EI; HALT
        ORG $d991 : rst $30 : db 2      ; the feathered blade's extra wait: EI; HALT
        ORG $dec6 : jp eng_tune : nop   ; the tune player: LD ($DECF),SP
        ENDM
