; ============================================
; TEMPTATION ARSENAL WEAPON SYSTEM
; ============================================
.include "gaudensex.inc"

.segment "BANK_GAME"
.org $C000

; ============================================
; WEAPON STATE
; ============================================
weapon_state:
current_weapon:     .byte WEAPON_BASIC
weapon_level:       .byte 0
weapon_cooldown:    .byte 0
weapon_energy:      .byte 0
ecstasy_meter:      .byte 0
ecstasy_max:        .byte PLAYER_ECSTASY_MAX

; Unlocked weapons (bitmask)
unlocked_weapons:   .byte %00000001  ; Basic always unlocked

; Weapon evolution tracking
kill_counter:       .word 0
last_weapon_kills:  .word 0

; ============================================
; FIRE CURRENT WEAPON
; ============================================
fire_weapon:
    lda weapon_cooldown
    beq @can_fire
    rts

@can_fire:
    ; Set cooldown based on weapon
    lda current_weapon
    asl
    tax
    lda weapon_cooldowns,x
    sta weapon_cooldown

    ; Fire based on weapon
    lda current_weapon
    asl
    tax
    lda weapon_fire_table,x
    sta zp_temp1
    lda weapon_fire_table+1,x
    sta zp_temp1+1

    jmp (zp_temp1)

weapon_fire_table:
    .word fire_basic
    .word fire_spread
    .word fire_laser
    .word fire_rapid
    .word fire_whip
    .word fire_chain
    .word fire_kiss
    .word fire_eclipse
    .word fire_symphony
    .word fire_ecstasy

; ============================================
; WEAPON 4: WHIP (Curving shots)
; ============================================
fire_whip:
    ; Fire 3 curving bullets
    ldx #0
@whip_loop:
    txa
    pha

    ; Find bullet slot
    jsr find_player_bullet_slot
    bcc @no_slot_whip

    ; Setup whip bullet
    lda #BULLET_WHIP
    sta bullet_type,y

    ; Position
    lda player_x
    clc
    adc #12
    sta bullet_x,y
    lda player_x+1
    adc #0
    sta bullet_x+1,y

    lda player_y
    clc
    adc whip_offsets,x
    sta bullet_y,y

    ; Initial velocity
    lda #3
    sta bullet_vx,y

    ; Curve amount based on position
    txa
    asl
    sec
    sbc #2
    sta bullet_vy,y

    ; Curve timer
    lda #30
    sta bullet_data,y

    ; Color
    lda #COLOR_PASTEL_PURPLE
    sta bullet_color,y

@no_slot_whip:
    pla
    tax
    inx
    cpx #3
    bne @whip_loop

    PLAY_SOUND SOUND_WHIP
    rts

whip_offsets: .byte -4, 0, 4

update_whip_bullet:
    ; Input: Y = bullet index
    ; Apply curve over time
    lda bullet_data,y
    beq @no_curve

    dec bullet_data,y

    ; Change vertical velocity
    lda bullet_vy,y
    bmi @curve_up

    ; Curve down
    inc bullet_vy,y
    bra @apply_curve

@curve_up:
    dec bullet_vy,y

@apply_curve:
@no_curve:
    ; Update position
    lda bullet_x,y
    clc
    adc bullet_vx,y
    sta bullet_x,y
    lda bullet_x+1,y
    adc #0
    sta bullet_x+1,y

    lda bullet_y,y
    clc
    adc bullet_vy,y
    sta bullet_y,y

    rts

; ============================================
; WEAPON 5: CHAIN (Lightning chaining)
; ============================================
fire_chain:
    ; Fire main chain bullet
    jsr find_player_bullet_slot
    bcc @no_chain

    lda #BULLET_CHAIN
    sta bullet_type,y

    ; Position
    lda player_x
    clc
    adc #12
    sta bullet_x,y
    lda player_x+1
    adc #0
    sta bullet_x+1,y
    lda player_y
    sta bullet_y,y

    ; Chain properties
    lda #0
    sta bullet_data,y    ; Chain length
    lda #COLOR_PASTEL_CRIMSON
    sta bullet_color,y

    PLAY_SOUND SOUND_CHAIN

@no_chain:
    rts

update_chain_bullet:
    ; Chain to nearby enemies
    lda bullet_data,y
    cmp #CHAIN_MAX_LINKS
    bcs @no_more_chains

    ; Check for enemies in range
    ldx #0
@enemy_loop:
    lda enemy_active,x
    beq @next_enemy

    ; Distance check
    lda enemy_x,x
    sec
    sbc bullet_x,y
    sta temp1
    lda enemy_x+1,x
    sbc bullet_x+1,y
    bne @next_enemy

    lda temp1
    bmi @next_enemy
    cmp #CHAIN_RANGE
    bcs @next_enemy

    lda enemy_y,x
    sec
    sbc bullet_y,y
    bmi @next_enemy
    cmp #CHAIN_RANGE
    bcs @next_enemy

    ; Chain hit!
    jsr chain_to_enemy
    inc bullet_data,y

    ; Create chain visual
    jsr create_chain_effect

    ; Damage enemy
    lda #CHAIN_DAMAGE
    sta enemy_hp,x

    ; Achievement: Chain master
    lda bullet_data,y
    cmp #8
    bcc @next_enemy

    lda #ACH_CHAIN_MASTER
    CHECK_ACHIEVEMENT

    bra @no_more_chains

@next_enemy:
    inx
    cpx #MAX_ENEMIES
    bne @enemy_loop

@no_more_chains:
    ; Move bullet
    lda bullet_x,y
    clc
    adc #3
    sta bullet_x,y
    lda bullet_x+1,y
    adc #0
    sta bullet_x+1,y

    rts

; ============================================
; WEAPON 8: SYMPHONY (Musical notes)
; ============================================
fire_symphony:
    ; Fire musical notes in scale
    ldx note_index

    ; Find bullet slot
    jsr find_player_bullet_slot
    bcc @no_note

    lda #BULLET_NOTE
    sta bullet_type,y

    ; Position
    lda player_x
    clc
    adc #12
    sta bullet_x,y
    lda player_x+1
    adc #0
    sta bullet_x+1,y

    lda player_y
    sta bullet_y,y

    ; Note type
    txa
    sta bullet_data,y

    ; Color based on note
    lda note_colors,x
    sta bullet_color,y

    ; Play corresponding sound
    txa
    clc
    adc #NOTE_C4
    jsr play_note_sound

    ; Next note
    inc note_index
    lda note_index
    cmp #7
    bcc @no_reset
    lda #0
    sta note_index

@no_reset:
@no_note:
    rts

note_colors:
    .byte COLOR_PASTEL_RED     ; C
    .byte COLOR_PASTEL_ORANGE  ; D
    .byte COLOR_PASTEL_YELLOW  ; E
    .byte COLOR_PASTEL_GREEN   ; F
    .byte COLOR_PASTEL_CYAN    ; G
    .byte COLOR_PASTEL_BLUE    ; A
    .byte COLOR_PASTEL_PURPLE  ; B

; ============================================
; ECSTASY SYSTEM (Ultimate weapon)
; ============================================
update_ecstasy_meter:
    ; Increase meter for good play
    lda current_combo
    cmp #10
    bcc @no_combo_bonus

    ; Combo bonus
    lda ecstasy_meter
    clc
    adc #2
    cmp ecstasy_max
    bcc @save_meter
    lda ecstasy_max
    bra @save_meter

@no_combo_bonus:
    ; Slow regen
    lda frame_counter
    and #$3F  ; Every 64 frames
    bne @done

    inc ecstasy_meter
    lda ecstasy_meter
    cmp ecstasy_max
    bcc @save_meter
    lda ecstasy_max

@save_meter:
    sta ecstasy_meter

@done:
    rts

fire_ecstasy:
    ; Requires full ecstasy meter
    lda ecstasy_meter
    cmp ecstasy_max
    beq @can_ecstasy
    rts

@can_ecstasy:
    ; Reset meter
    lda #0
    sta ecstasy_meter

    ; Activate ecstasy mode
    lda #ECSTASY_DURATION
    sta ecstasy_timer

    ; Screen effect
    lda #EFFECT_ECSTASY
    jsr add_screen_effect

    ; Music change
    lda #MUSIC_ECSTASY
    jsr play_music

    ; Achievement
    inc ecstasy_used
    lda ecstasy_used
    cmp #10
    bcc @fire_pulse

    lda #ACH_ECSTASY_MASTER
    CHECK_ACHIEVEMENT

@fire_pulse:
    ; Fire ecstasy pulse
    jsr create_ecstasy_pulse

    rts

create_ecstasy_pulse:
    ; Create expanding circle of destruction
    lda #0
    sta pulse_radius

@pulse_loop:
    ; Damage all enemies within radius
    ldx #0
@enemy_check:
    lda enemy_active,x
    beq @next_pulse_enemy

    ; Distance check
    jsr check_enemy_in_radius
    bcc @next_pulse_enemy

    ; Instant kill
    lda #0
    sta enemy_hp,x

    ; Explosion effect
    jsr create_enemy_explosion

@next_pulse_enemy:
    inx
    cpx #MAX_ENEMIES
    bne @enemy_check

    ; Increase radius
    inc pulse_radius
    lda pulse_radius
    cmp #ECSTASY_MAX_RADIUS
    bcc @pulse_loop

    ; Visual effect
    jsr create_pulse_visual

    rts

; ============================================
; WEAPON EVOLUTION SYSTEM
; ============================================
check_weapon_evolution:
    ; Check kill counter for evolution
    lda kill_counter
    sec
    sbc last_weapon_kills
    cmp #EVOLUTION_KILLS
    bcc @no_evolution

    ; Evolve weapon
    lda current_weapon
    cmp #WEAPON_ECSTASY
    beq @no_evolution  ; Already ultimate

    inc current_weapon
    lda kill_counter
    sta last_weapon_kills

    ; Evolution effect
    jsr weapon_evolution_effect

    ; Achievement
    lda #ACH_EVOLVED_WEAPON
    CHECK_ACHIEVEMENT

@no_evolution:
    rts

weapon_evolution_effect:
    ; Screen flash
    lda #EFFECT_FLASH_WHITE
    jsr add_screen_effect

    ; Particle burst
    lda player_x
    sta effect_x
    lda player_y
    sta effect_y
    lda #PARTICLE_GLITTER
    jsr create_particle_effect

    ; Play evolution sound
    PLAY_SOUND SOUND_TRANSFORM

    ; Show weapon name
    lda current_weapon
    asl
    tax
    lda weapon_names,x
    sta text_ptr
    lda weapon_names+1,x
    sta text_ptr+1

    lda #60
    sta text_timer

    rts

; ============================================
; WEAPON DATA
; ============================================
weapon_cooldowns:
    .byte 8   ; Basic
    .byte 10  ; Spread
    .byte 15  ; Laser
    .byte 4   ; Rapid
    .byte 12  ; Whip
    .byte 20  ; Chain
    .byte 25  ; Kiss
    .byte 30  ; Eclipse
    .byte 6   ; Symphony
    .byte 255 ; Ecstasy (special)

weapon_names:
    .word str_weapon_basic
    .word str_weapon_spread
    .word str_weapon_laser
    .word str_weapon_rapid
    .word str_weapon_whip
    .word str_weapon_chain
    .word str_weapon_kiss
    .word str_weapon_eclipse
    .word str_weapon_symphony
    .word str_weapon_ecstasy

str_weapon_basic:    .byte "BASIC PULSE",0
str_weapon_spread:   .byte "TRIPLE SPREAD",0
str_weapon_laser:    .byte "PIERCING LASER",0
str_weapon_rapid:    .byte "RAPID FIRE",0
str_weapon_whip:     .byte "SNAKE WHIP",0
str_weapon_chain:    .byte "LIGHTNING CHAIN",0
str_weapon_kiss:     .byte "CRIMSON KISS",0
str_weapon_eclipse:  .byte "VOID ECLIPSE",0
str_weapon_symphony: .byte "MELODIC SYMPHONY",0
str_weapon_ecstasy:  .byte "ECSTASY BURST",0

; Evolution requirements
EVOLUTION_KILLS = 50
CHAIN_MAX_LINKS = 8
CHAIN_RANGE = 32
CHAIN_DAMAGE = 5
ECSTASY_DURATION = 180  ; 3 seconds at 60fps
ECSTASY_MAX_RADIUS = 64

; Variables
note_index:         .byte 0
ecstasy_timer:      .byte 0
ecstasy_used:       .byte 0
pulse_radius:       .byte 0
text_timer:         .byte 0
text_ptr:           .word 0
