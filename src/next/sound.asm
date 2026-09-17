; ---------------------------------------------------------------------------
; E5: sound (included in the engine, src/next/engine.asm).
;
; CLASSIC. The original's own effect and tune players play the original sound: the
; wrappers eng_fx and eng_tune run them at 3.5 MHz with E_SLOW set, and the
; interrupt handler switches to full speed for its own part while E_SLOW is set, so
; the notes lose no more time to interrupts than they did on a 128K
; (tools/checkclassic.py hears the difference).
;
; ARCADE (builds with -DARCADE and the builder's arcade set). The arcade board's
; music and effects, converted to AY register streams at build time
; (tools/arcade/mksound.py), play on the Next's three AY chips: the music on AY 2
; and AY 3 (six voices), the effects on AY 1. The streams are read on every logic
; tick by snd_tick, from the line interrupt, so they keep playing while the
; original's players block the game (they still run, for the logic's pace, with
; their speaker writes turned off by snd_beeper). Which cue plays when is decided
; here, from the original's own moments: the tune player's call site, the effect
; number, and state the pass head sees (the guardian, a blow, a jump).
;
; STREAM FORMAT (per logic tick): a mask byte, bit n set when voice n changes, then
; two bytes per changed voice: the tone period's low byte, then volume x 16 + the
; period's high nibble. Mask $80 ends the cue; $C0 jumps to its loop point. The
; first sound page holds the directory: "AS", then 256 x 6 bytes indexed by cue
; (the arcade's command number): page, offset (word), loop page, loop offset (word);
; a zero page means no such cue.
; ---------------------------------------------------------------------------

E_SLOW          EQU $2044               ; non-zero while an original sound player runs at 3.5 MHz
E_SND_ON        EQU $2045               ; arcade sound on
E_SND_MMU7      EQU $2046               ; slot 7 as the interrupted code had it
E_MUS_REQ       EQU $2047               ; $FF none; 0 stop; else a cue to start (set by main code)
E_FX_REQ        EQU $2048
E_MUS_CUR       EQU $2049               ; the cue playing (0 none)
E_FX_CUR        EQU $204A
E_MUS_PAGE      EQU $2050               ; music stream: page, offset, loop page, loop offset
E_MUS_PTR       EQU $2051
E_MUS_LPAGE     EQU $2053
E_MUS_LPTR      EQU $2054
E_FX_PAGE       EQU $2058               ; effect stream: the same
E_FX_PTR        EQU $2059
E_FX_LPAGE      EQU $205B
E_FX_LPTR       EQU $205C
E_SND_GUARD     EQU $2060               ; GuardianActive at the last pass head
E_SND_JUMP      EQU $2061               ; JumpCounter at the last pass head
E_SND_TICKS     EQU $2062               ; logic ticks the sound has run (16 bits, for the checker)
E_AY_SHADOW     EQU $2070               ; 3 x 16: what was last written to each chip's registers
sv_mask         EQU $2066
sv_voice        EQU $2067
sv_base         EQU $2069               ; the stream's variables: E_MUS_PAGE or E_FX_PAGE
sv_first        EQU $206B               ; the chip of the stream's first voice ($FE music, $FF effects)
sv_chip         EQU $206C               ; the chip selected: 0-2
E_SND_QUIET     EQU $206D               ; non-zero after a guardian is destroyed: no theme
AY_MUSIC        EQU $fe                 ; Turbosound selects: %1111 11nn, nn = 3 - chip
AY_EFFECTS      EQU $ff

; ---- classic: the beeper -----------------------------------------------------------

; The original's twelve speaker writes: the effect player, the tone generator, the tune
; effects' four sounds, the glide. A = 0 turns them off (JR $+2), 1 back on (OUT ($FE),A).
; Bank 0 is written through slot 2 with interrupts off, so it works whatever is paged.
snd_beeper:
        push bc
        push de
        push hl
        ld c,a
        ld a,i
        di
        push af
        ld hl,beeper_sites
        ld b,beeper_count
.site:  ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ld a,d
        rlca
        rlca
        rlca
        and 1                           ; $C000-$DFFF: page 0; $E000-$FFFF: page 1
        nextreg $52,a
        ld a,d
        and $1f
        or $40
        ld h,a
        ld l,e
        ld a,c
        or a
        ld a,$18
        ld e,$00
        jr z,.put
        ld a,$d3
        ld e,$fe
.put:   ld (hl),a
        inc hl
        ld (hl),e
        pop hl
        djnz .site
        nextreg $52,10
        pop af
        pop hl
        pop de
        pop bc
        ret po
        ei
        ret

beeper_sites:
        dw $c444, $df78, $df8a, $e004, $e00c, $e017, $e020, $e02c, $e033, $e03f, $e049, $e155
beeper_count EQU ($ - beeper_sites) / 2

; The arcade sound on: Turbosound on (NextReg $08 bit 1), the three chips silent, the
; original's speaker writes off. Interrupts off (the start-up, or E6's options).
snd_arcade_on:
        ld bc,$243b
        ld a,$08
        out (c),a
        inc b
        in a,(c)
        or %00000010
        nextreg $08,a
        ld hl,E_MUS_PAGE
        ld (sv_base),hl
        ld a,AY_MUSIC
        ld (sv_first),a
        call stream_silence
        ld hl,E_FX_PAGE
        ld (sv_base),hl
        ld a,AY_EFFECTS
        ld (sv_first),a
        call stream_silence
        xor a
        call snd_beeper
        ld a,1
        ld (E_SND_ON),a
        ret

; ---- arcade: the interrupt's tick --------------------------------------------------

; Called on every logic tick from eng_isr (AF and HL already saved).
snd_tick:
        ld a,(E_SND_ON)
        or a
        ret z
        push bc
        push de
        ld hl,(E_SND_TICKS)
        inc hl
        ld (E_SND_TICKS),hl
        ld bc,$243b                     ; slot 7 as it was: the main code reads NextRegs
        ld a,$57                        ; only with interrupts off (rdreg)
        out (c),a
        inc b
        in a,(c)
        ld (E_SND_MMU7),a
        ; the music
        ld hl,E_MUS_PAGE
        ld (sv_base),hl
        ld a,AY_MUSIC
        ld (sv_first),a
        ld hl,E_MUS_REQ
        call stream_request
        ld a,(E_MUS_CUR)
        or a
        call nz,stream_step
        ; the effects
        ld hl,E_FX_PAGE
        ld (sv_base),hl
        ld a,AY_EFFECTS
        ld (sv_first),a
        ld hl,E_FX_REQ
        call stream_request
        ld a,(E_FX_CUR)
        or a
        call nz,stream_step
        ld a,(E_SND_MMU7)
        nextreg $57,a
        pop de
        pop bc
        ret

; HL -> a request byte (then the cue byte after it is CUR: MUS_REQ+2 / FX_REQ+2).
stream_request:
        ld a,(hl)
        cp $ff
        ret z
        ld (hl),$ff
        inc hl
        inc hl                          ; HL -> the CUR byte
        ld (hl),a
        or a
        jr z,.stop
        ; the directory entry: page SND_PAGE0, offset 2 + 6 x cue
        push hl
        ld l,a
        ld h,0
        ld e,l
        ld d,h
        add hl,hl
        add hl,de
        add hl,hl                       ; x 6
        ld de,$e002
        add hl,de
        ld a,SND_PAGE0
        nextreg $57,a
        ld de,(sv_base)
        ld bc,6
        ldir                            ; page, offset, loop page, loop offset
        pop hl
        ld de,(sv_base)
        ld a,(de)
        or a
        ret nz
        ld (hl),0                       ; no such cue: nothing plays
.stop:  jp stream_silence

; The stream at sv_base: one tick.
stream_step:
        call stream_byte
        cp $80
        jr c,.voices
        cp $c0
        jr nz,.end
        ld hl,(sv_base)                 ; loop: the loop point becomes the position
        push hl
        inc hl
        inc hl
        inc hl
        pop de
        ld bc,3
        ldir
        jr stream_step
.end:   ld hl,(sv_base)                 ; the CUR byte is 7 or 10 bytes before... see snd_cur
        call snd_cur
        ld (hl),0
        jp stream_silence
.voices:
        ld (sv_mask),a
        xor a
        ld (sv_voice),a
.v:     ld a,(sv_mask)
        or a
        ret z
        srl a
        ld (sv_mask),a
        jr nc,.next
        call stream_byte
        ld e,a                          ; period low
        call stream_byte
        ld d,a                          ; volume x 16 + period high
        call ay_voice
.next:  ld hl,sv_voice
        inc (hl)
        jr .v

; HL = sv_base -> HL = the stream's CUR byte.
snd_cur:
        ld de,E_MUS_PAGE
        or a
        sbc hl,de
        ld hl,E_MUS_CUR
        ret z
        ld hl,E_FX_CUR
        ret

; A = the stream's next byte (pages its page into slot 7).
stream_byte:
        push de
        ld hl,(sv_base)
        ld a,(hl)
        nextreg $57,a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)                       ; DE = offset in the page
        push de
        ex de,hl
        ld a,h
        or $e0
        ld h,a
        ld a,(hl)                       ; the byte
        pop de
        inc de
        bit 5,d
        jr z,.same
        ld de,0                         ; on to the next page
        ld hl,(sv_base)
        inc (hl)
.same:  ld hl,(sv_base)
        inc hl
        ld (hl),e
        inc hl
        ld (hl),d
        pop de
        ret

; Voice sv_voice of the stream: E = period low, D = volume x 16 + period high.
ay_voice:
        ld a,(sv_first)
        ld c,a
        ld a,(sv_voice)
        cp 3
        jr c,.chip
        sub 3
        dec c                           ; the second music chip
.chip:  ld b,a                          ; B = channel 0-2
        ld a,c
        call ay_select
        ld a,b
        add a,a
        ld c,a                          ; register: period low
        ld a,e
        call ay_write
        inc c
        ld a,d
        and 15
        call ay_write
        ld a,b
        add a,8
        ld c,a
        ld a,d
        rrca
        rrca
        rrca
        rrca
        and 15
        jp ay_write

; Select chip A ($FF, $FE or $FD) for the writes that follow.
ay_select:
        push bc
        ld bc,$fffd
        out (c),a
        pop bc
        cpl
        and 3
        ld (sv_chip),a
        ret

; Write A to AY register C of the selected chip, and to its shadow.
ay_write:
        push bc
        push hl
        push af
        ld a,(sv_chip)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,c
        ld hl,E_AY_SHADOW
        add a,l
        ld l,a
        pop af
        ld (hl),a
        pop hl
        push af
        ld a,c
        ld bc,$fffd
        out (c),a
        pop af
        ld b,$bf
        out (c),a
        pop bc
        ret

; Silence the chips of the stream at sv_base (volumes 0, tones on, noise off).
stream_silence:
        ld a,(sv_first)
        ld c,a
        ld e,1
        cp AY_MUSIC
        jr nz,.one
        ld e,2
.one:   push bc
        push de
        ld a,c
        call ay_select
        ld c,7
        ld a,%00111000
        call ay_write
        ld c,8
        xor a
        call ay_write
        inc c
        call ay_write
        inc c
        call ay_write
        pop de
        pop bc
        dec c
        dec e
        jr nz,.one
        ret

; ---- arcade: the cues ----------------------------------------------------------------

; Main code: start music cue A (0 stops), unless it is already playing.
snd_music:
        push hl
        ld hl,E_MUS_CUR
        cp (hl)
        jr z,.same
        ld (E_MUS_REQ),a
.same:  pop hl
        ret

; Main code: start effect cue A.
snd_effect:
        ld (E_FX_REQ),a
        ret

; eng_tune calls this before the original's tune player runs (E_TUNE_RET set): the
; cue for the tune's call site. 0: no change; $FE: the world's theme; $FD: the world
; intro (world 1's "Setting Off", later worlds their theme).
snd_tune:
        push af
        ld a,(E_SND_ON)
        or a
        jr z,.off
        push bc
        push de
        push hl
        xor a                           ; a tune: whatever follows is a new start, and a
        ld (E_SND_QUIET),a              ; guardian from before it is not one leaving now
        ld a,($b955)
        ld (E_SND_GUARD),a
        ld hl,tune_sites
.find:  ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld a,b
        or c
        jr z,.done
        ld a,(hl)
        inc hl
        push hl
        ld hl,(E_TUNE_RET)
        or a
        sbc hl,bc
        pop hl
        jr nz,.find
        cp $fd
        jr c,.play
        jr nz,.state                    ; $FE: the music for now
        ld a,($ba33)                    ; $FD, the intro: world 1's Setting Off
        cp 1
        ld a,CUE_SETTING_OFF
        jr z,.play
.state: call state_music                ; a life lost in a guardian fight goes back to its theme
.play:  or a
        call nz,snd_music
.done:  pop hl
        pop de
        pop bc
.off:   pop af
        ret

; eng_fx calls this with A = the effect number before the original's player runs.
snd_fx:
        push af
        ld a,(E_SND_ON)
        or a
        jr z,.done
        pop af
        push af
        push hl
        cp 13
        jr nc,.none
        or a
        jr nz,.table
        ld a,($b955)                    ; effect 0 on the guardian: a hit, not a kill
        or a
        ld a,CUE_GUARDIAN_HIT
        jr nz,.play
        xor a
.table: ld hl,fx_cue
        push de
        ld e,a
        ld d,0
        add hl,de
        pop de
        ld a,(hl)
        or a
        jr z,.none
.play:  call snd_effect
.none:  pop hl
.done:  pop af
        ret

; Service 4, WorldCompleted's flash ($D04D): once, the music stops and the guardian's
; destruction sounds; then the frame wait it replaces.
svc_done:
        ld a,(E_SND_ON)
        or a
        jp z,svc_wait
        ld a,(E_SND_QUIET)
        or a
        jp nz,svc_wait
        inc a
        ld (E_SND_QUIET),a
        xor a
        call snd_music
        ld a,CUE_GUARDIAN_DESTROYED
        call snd_effect
        jp svc_wait

; A = the music for play now: the guardian's theme while one is active (the final
; guardian's own in world 7), else the world's theme.
state_music:
        push de
        push hl
        ld a,($ba33)                    ; WorldNumber, 1-7
        dec a
        and 7
        cp 7
        jr c,.world
        xor a
.world: ld e,a
        ld d,0
        ld hl,world_theme
        ld a,($b955)                    ; GuardianActive
        or a
        jr z,.pick
        ld a,($b951)                    ; FinalGuardian
        or a
        ld a,CUE_FINAL_GUARDIAN
        jr nz,.done
        ld hl,guardian_theme
.pick:  add hl,de
        ld a,(hl)
.done:  pop hl
        pop de
        ret

; From the pass head: the guardian, a blow and a jump.
snd_passhead:
        ld a,(E_SND_ON)
        or a
        ret z
        ld a,($b955)                    ; GuardianActive
        ld hl,E_SND_GUARD
        cp (hl)
        ld (hl),a
        jr z,.theme
        or a
        jr z,.gone
        call state_music                ; the guardian's theme
        call snd_music
        jr .moves
.gone:  ld a,1                          ; destroyed: the theme stops until the next world
        ld (E_SND_QUIET),a
        xor a
        call snd_music
        ld a,CUE_GUARDIAN_DESTROYED
        call snd_effect
        jr .moves
.theme: ld a,(E_SND_QUIET)
        or a
        jr nz,.moves
        ld a,(E_MUS_CUR)                ; nothing playing in play: the world's theme
        or a
        jr nz,.moves
        ld a,(E_MUS_REQ)
        cp $ff
        jr nz,.moves
        ld a,($b955)
        or a
        jr nz,.moves
        call state_music
        call snd_music
.moves: ld a,($c95b)                    ; AttackFlag: a blow starts
        or a
        ld a,CUE_SWING
        call nz,snd_effect
        ld a,($b953)                    ; JumpCounter: a jump starts
        ld hl,E_SND_JUMP
        ld b,(hl)
        ld (hl),a
        or a
        ret z
        ld a,b
        or a
        ret nz
        ld a,CUE_JUMP
        jp snd_effect

; ---- the cue tables (provisional: David names the tunes and places them by ear) -----
; docs/design.md, Sound: the moments, from the 128K disassembly. The numbers are the
; arcade sound program's command numbers (tools/arcade/sound-cues.json lists why).

    IFDEF ARCADE
        INCLUDE "build/assets/sound_cues.asm"
    ELSE
SND_PAGE0               EQU 0
CUE_SETTING_OFF         EQU 0
CUE_GUARDIAN_HIT        EQU 0
CUE_FINAL_GUARDIAN      EQU 0
CUE_GUARDIAN_DESTROYED  EQU 0
CUE_SWING               EQU 0
CUE_JUMP                EQU 0
tune_sites:     db 0
world_theme:    ds 7
guardian_theme: ds 7
fx_cue:         ds 13
    ENDIF
