; ---------------------------------------------------------------------------
; The engine: the enhanced port's own code, beside the original game.
;
; WHERE IT LIVES. The resume stub copies the 48K ROM into the Next's
; alternative ROM, writes this code over the part of it the game never uses
; (from ENGINE_ORG), and write-protects it. The game only calls the ROM for
; KEY-SCAN ($028E), which stays; something in the game writes into
; $0000-$3FFF (docs/oracle.md), and a write-protected ROM ignores it, exactly
; as a Spectrum does. The engine's variables are in a RAM page mapped at
; $2000-$3FFF (MMU1) for good: the only writes the game makes there are the
; feathered blade's blast drawn above the screen, at $384C-$3FF5, so the
; engine keeps nothing above E_TOP.
;
; HOW THE GAME REACHES IT (src/next/patches.asm, tools/nexpatches.py):
;   - the IM 2 vector table ($B700-$B800) points every interrupt at $B6B6,
;     three unused bytes holding JP eng_isr; eng_isr counts, then jumps to the
;     game's own interrupt jump at $B8B8
;   - RST $30 + a service byte replaces each EI; HALT frame wait and each of the
;     world loader's OUT (C),A to $7FFD
;   - JP to a wrapper replaces the start of the effect player ($C408), the tune
;     player ($DEC6) and WaitFrames ($C400)
;
; TIME. The Next raises one interrupt a display frame, from a line interrupt
; just below the play area (line 128). The game's logic runs on LOGIC TICKS, 50
; a second: at 50 Hz every interrupt is a tick; at 60 Hz one interrupt in six
; is dropped - counted, but not passed to the game's interrupt routine - so
; frame-counted waits, tune lengths and the pass pace keep the original's speed.
;
; THE PASS PACE (E1, docs/design.md). In the recording a main-loop pass takes
; exactly 4 frames unless it plays a sound effect or waits for a frame in the
; middle (the feathered blade, the carried items), which the original does on
; the beeper, blocking the game. So the pacer holds each pass to 4 logic ticks,
; plus the ticks the blocking parts would have added: their measured time,
; less the slack the original's own work left in its four frames (PACE_SLACK).
;
; Until E5 replaces the sound, the beeper routines run at 3.5 MHz (they are
; timing loops, and would play 8x too high at 28 MHz).
; ---------------------------------------------------------------------------

ENGINE_ORG      EQU $0400
E_BASE          EQU $2000
E_TOP           EQU $3800               ; nothing of the engine's at or above this

; ---- engine RAM (page ENGINE_RAM_PAGE at $2000) ----------------------------
E_MAGIC         EQU $2000               ; "ATHE"
E_TICK          EQU $2004               ; logic ticks (16 bits)
E_FRAMES        EQU $2006               ; display interrupts (16 bits)
E_HZ            EQU $2008               ; 50 or 60
E_ACC           EQU $2009               ; 60 Hz accumulator
E_START         EQU $200A               ; the current pass's start, in logic ticks
E_CREDIT        EQU $200C               ; blocking time this pass, in display lines (saturates)
E_FLAGS         EQU $200E               ; this pass: bit 0 effect, bit 1 frame wait, bit 2 tune
E_FX_RET        EQU $200F               ; the effect player's real return address
E_TUNE_RET      EQU $2011               ; the tune player's real return address
E_T0_FRAMES     EQU $2013               ; a timed section's start: display interrupts...
E_T0_LINE       EQU $2015               ; ...and lines since the interrupt
E_LPF           EQU $2017               ; display lines a frame: 312 or 262 (16 bits)
E_PASSES        EQU $2019               ; passes paced (16 bits)
E_SPEED         EQU $201B               ; the CPU speed to restore after the beeper (NextReg $07)
E_WAIT_TICK     EQU $201C               ; scratch: the tick a frame wait started on
E_HIST          EQU $2100               ; pass-length histogram, world 0-7 x kind 0-3 x length 0-15, 16 bits each

INT_LINE        EQU 128                 ; the line interrupt: just below the 128-line play area
PACE_TICKS      EQU 4
PACE_SLACK_Q    EQU 1                   ; the slack the original's own work leaves in its four
                                        ; frames, in quarter ticks: a quarter of a frame

; ---- the engine ------------------------------------------------------------

; Every interrupt. At 50 Hz each is a logic tick; at 60 Hz, five in six.
eng_isr:
        push af
        push hl
        ld hl,(E_FRAMES)
        inc hl
        ld (E_FRAMES),hl
        ld a,(E_ACC)
        add a,50
        ld hl,E_HZ
        cp (hl)
        jr c,.drop
        sub (hl)
        ld (E_ACC),a
        ld hl,(E_TICK)
        inc hl
        ld (E_TICK),hl
        pop hl
        pop af
        jp $b8b8                        ; the game's interrupt jump
.drop:  ld (E_ACC),a
        pop hl
        pop af
        ei
        reti

; RST $30 + service byte. Registers are kept; interrupts are left as the
; service leaves them.
svc_entry:
        push af
        push bc
        push de
        push hl
        ld hl,8
        add hl,sp                       ; the return address points at the service byte
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,(de)
        inc de
        ld (hl),d
        dec hl
        ld (hl),e
        dec a
        jp z,svc_pace                   ; 1: the pass's frame wait ($CEFA)
        dec a
        jp z,svc_wait                   ; 2: a frame wait inside a pass or a screen
        dec a
        jp z,svc_page                   ; 3: OUT (C),A to $7FFD
svc_return:
        pop hl
        pop de
        pop bc
        pop af
        ret

; ---- timing -----------------------------------------------------------------

; HL = display interrupts, DE = lines since the last one. Interrupts stay on:
; the display interrupt count is read before and after the line, and the pair
; is taken again if an interrupt came in between or the beam is on the
; interrupt's own line.
now:
        push af
        push bc
.again: ld hl,(E_FRAMES)
        ld bc,$243b
        ld a,$1e
        out (c),a
        inc b
        in a,(c)
        and 1
        ld d,a
        dec b
        ld a,$1f
        out (c),a
        inc b
        in a,(c)
        ld e,a                          ; DE = the video line
        push hl
        ld hl,(E_FRAMES)
        pop bc
        or a
        sbc hl,bc
        ld h,b
        ld l,c
        jr nz,.again
        ld a,d                          ; the interrupt's own line is ambiguous
        or a
        jr nz,.norm
        ld a,e
        cp INT_LINE
        jr z,.again
.norm:  ex de,hl                        ; lines since the interrupt: line - 128, mod LPF
        ld bc,INT_LINE
        or a
        sbc hl,bc
        jr nc,.pos
        ld bc,(E_LPF)
        add hl,bc
.pos:   ex de,hl
        pop bc
        pop af
        ret

t_start:
        push hl
        push de
        call now
        ld (E_T0_FRAMES),hl
        ld (E_T0_LINE),de
        pop de
        pop hl
        ret

; E_CREDIT += display lines since t_start (saturating).
t_credit:
        push af
        push bc
        push de
        push hl
        call now                        ; HL frames, DE line
        ld bc,(E_T0_FRAMES)
        or a
        sbc hl,bc                       ; HL = whole frames elapsed
        ld a,h
        or a
        jr nz,.sat                      ; 256 frames or more: saturate
        ld b,l                          ; lines = frames x LPF + (line - line0)
        ld hl,0
        inc b
        jr .mulend
.mul:   ld a,(E_LPF)
        ld c,a
        ld a,(E_LPF+1)
        push bc
        ld b,a
        add hl,bc
        pop bc
        jr c,.sat
.mulend:
        djnz .mul
        add hl,de
        jr c,.sat
        ld bc,(E_T0_LINE)
        or a
        sbc hl,bc
        jr nc,.add
        ld hl,0
.add:   ld bc,(E_CREDIT)
        add hl,bc
        jr nc,.store
.sat:   ld hl,$ffff
.store: ld (E_CREDIT),hl
        pop hl
        pop de
        pop bc
        pop af
        ret

; ---- the pass pacer (service 1) -----------------------------------------------
svc_pace:
        ; extra ticks = ceil((credit - slack) / lines per tick), slack = PACE_SLACK_Q / 4 ticks
        ld hl,(E_LPF)                   ; lines per logic tick: a frame at 50 Hz, 1.2 frames at 60 Hz
        ld a,(E_HZ)
        cp 60
        jr nz,.tl
        ld de,52                        ; 262 x 1.2 = 314
        add hl,de
.tl:    ld b,h
        ld c,l                          ; BC = lines a tick
        push bc
        ld hl,0                         ; slack = tick x PACE_SLACK_Q / 4
        ld a,PACE_SLACK_Q
.sl:    add hl,bc
        dec a
        jr nz,.sl
        srl h
        rr l
        srl h
        rr l
        ex de,hl                        ; DE = slack
        ld hl,(E_CREDIT)
        or a
        sbc hl,de
        pop bc
        ld a,PACE_TICKS
        jr c,.want
        jr z,.want
.ex:    inc a                           ; one more tick for each part of a tick left over
        or a
        sbc hl,bc
        jr z,.want
        jr nc,.ex
.want:  ld e,a                          ; E = ticks the pass must last
.wait:  ld hl,(E_TICK)
        ld bc,(E_START)
        or a
        sbc hl,bc
        ld a,h
        or a
        jr nz,.done
        ld a,l
        cp e
        jr nc,.done
        ei
        halt
        jr .wait
.done:  ; record the pass: histogram[world][kind][min(length,15)]
        ld a,h
        or a
        jr nz,.long
        ld a,l
        cp 16
        jr c,.len
.long:  ld a,15
.len:   ld c,a                          ; C = length
        ld a,(E_FLAGS)
        ld b,0
        bit 2,a
        jr z,.k1
        ld b,3
        jr .kind
.k1:    bit 0,a
        jr z,.k2
        ld b,1
        jr .kind
.k2:    bit 1,a
        jr z,.kind
        ld b,2
.kind:  ld a,($ba33)                    ; WorldNumber, 1-7 in play
        and 7
        add a,a
        add a,a
        add a,b                         ; world x 4 + kind
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl                       ; x 16
        ld b,0
        add hl,bc                       ; + length
        add hl,hl                       ; x 2 bytes
        ld bc,E_HIST
        add hl,bc
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc bc
        ld (hl),b
        dec hl
        ld (hl),c
        ld hl,(E_PASSES)
        inc hl
        ld (E_PASSES),hl
        ld hl,(E_TICK)
        ld (E_START),hl
        ld hl,0
        ld (E_CREDIT),hl
        xor a
        ld (E_FLAGS),a
        ei
        jp svc_return

; ---- a frame wait (service 2): EI; HALT, one logic tick ------------------------
svc_wait:
        call t_start
        call wait_tick
        call t_credit
        ld hl,E_FLAGS
        set 1,(hl)
        ei
        jp svc_return

wait_tick:
        ld hl,(E_TICK)
        ld (E_WAIT_TICK),hl
.w:     ei
        halt
        ld hl,(E_TICK)
        ld bc,(E_WAIT_TICK)
        or a
        sbc hl,bc
        jr z,.w
        ret

; ---- WaitFrames ($C400): HL logic ticks, HL=0 meaning 65,536 ------------------
; Leaves what the original leaves: HL = 0, A = 0, F as OR L gives it, interrupts on.
eng_waitframes:
        push bc
.loop:  push hl
        call wait_tick
        pop hl
        dec hl
        ld a,h
        or l
        jr nz,.loop
        pop bc
        xor a                           ; A = 0, F = $44 as OR L left it
        ei
        ret

; ---- the world loader's paging (service 3): OUT (C),A with BC = $7FFD -----------
; Pages the RAM bank in bits 0-2 at $C000 through MMU6/MMU7, which is all the
; recording's writes do; MMU1 keeps the engine's page. Interrupts untouched.
svc_page:
        ld hl,7                         ; A as the game had it: saved at SP+7
        add hl,sp
        ld a,(hl)
        and 7
        add a,a
        nextreg $56,a
        inc a
        nextreg $57,a
        jp svc_return

; ---- the effect player ($C408), at 3.5 MHz -------------------------------------
eng_fx:
        nextreg $07,0
        call t_start
        pop hl                          ; $C408 POP HL
        ld a,(hl)                       ; $C409 LD A,(HL)
        inc hl                          ; $C40A INC HL: the real return address
        ld (E_FX_RET),hl
        ld hl,eng_fx_tail               ; $C40B pushes it twice: return here, and
        jp $c40b                        ; HL comes back as this address
eng_fx_tail:
        push af
        ld a,(E_SPEED)
        nextreg $07,a
        call t_credit
        ld hl,E_FLAGS
        set 0,(hl)
        pop af
        ld hl,(E_FX_RET)                ; HL = the return address, as the original leaves it
        jp (hl)

; ---- the tune player ($DEC6), at 3.5 MHz ---------------------------------------
eng_tune:
        nextreg $07,0
        call t_start
        ex (sp),hl                      ; the real return address...
        ld (E_TUNE_RET),hl
        ld hl,eng_tune_tail             ; ...becomes the tail
        ex (sp),hl
        ld ($decf),sp                   ; $DEC6 LD ($DECF),SP
        jp $deca
eng_tune_tail:
        push af
        push hl
        ld a,(E_SPEED)
        nextreg $07,a
        call t_credit
        ld hl,E_FLAGS
        set 2,(hl)
        pop hl
        pop af
        push hl                         ; return to the real caller with HL, AF intact
        ld hl,(E_TUNE_RET)
        ex (sp),hl
        ret

engine_end:
