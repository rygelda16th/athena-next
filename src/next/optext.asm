; ---------------------------------------------------------------------------
; E6: the options screen's text, in page 95 at $7000, put there by the .nex. The
; options screen maps that page at $6000 while it draws (src/next/options.asm), so
; the game's own printer reads the words from there; the engine's own ROM is too
; small to hold them.
; ---------------------------------------------------------------------------

        ORG $7000
; The game's font: '<' is a full stop, '=' a slash, '[' a hyphen; '#' ends a message.
txt_menu6:      db "6<OPTIONS#"
txt_title:      db "OPTIONS#"
txt_offon:      db "OFF   #ON    #"
txt_presets:    db "ORIGINAL#EASIER  #EASY    #OWN     #"
txt_ctime:      db "10 SECS#20 SECS#30 SECS#"
txt_immune:     db "SHORT #NORMAL#LONG  #"
txt_guard:      db "NORMAL #WEAKER #WEAKEST#"
txt_saved:      db "SAVED ON THE CARD        #"
txt_loaded:     db "LOADED FROM THE CARD     #"
txt_nocard:     db "NO CARD = NOT SAVED      #"
opt_labels:
        dw lb_preset, lb_lives, lb_cont, lb_ctime, lb_energy, lb_contact, lb_immune
        dw lb_clock, lb_guard, lb_keep, lb_poison, lb_blade, lb_enemies, lb_fixes, lb_classic, lb_save
lb_preset:      db "PRESET#"
lb_lives:       db "LIVES#"
lb_cont:        db "CONTINUES#"
lb_ctime:       db "TIME TO CONTINUE#"
lb_energy:      db "ENERGY#"
lb_contact:     db "ENEMIES HURT#"
lb_immune:      db "IMMUNITY#"
lb_clock:       db "MINUTES#"
lb_guard:       db "GUARDIANS#"
lb_keep:        db "KEEP ITEMS#"
lb_poison:      db "POISON#"
lb_blade:       db "BLADE COSTS#"
lb_enemies:     db "EVERY ENEMY#"
lb_fixes:       db "BUG FIXES#"
lb_classic:     db "CLASSIC MODE#"
lb_save:        db "SAVE AND GO BACK#"

