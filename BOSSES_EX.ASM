; ============================================
; SIN ARCHON BOSS SYSTEM
; ============================================
.include "gaudensex.inc"

.segment "BANK_BOSS"
.org $8000

; ============================================
; BOSS STATE STRUCTURE
; ============================================
boss_state:
boss_active:        .byte 0
boss_id:            .byte 0
boss_hp:            .word 0
boss_max_hp:        .word 0
boss_phase:         .byte 0
boss_timer:         .byte 0
boss_pattern:       .byte 0
boss_x:             .word 0
boss_y:             .byte 0
boss_frame:         .byte 0
boss_invulnerable:  .byte 0
boss_attack_timer:  .byte 0
boss_rage:          .byte 0

; Pattern data (64 bytes per boss)
boss_pattern_data:  .res 512

; ============================================
; INITIALIZE BOSS
; ============================================
; Input: A = boss ID
init_boss:
    sta boss_id
    lda #1
    sta boss_active

    ; Load boss data based on ID
    asl
    tax
    lda boss_table,x
    sta zp_temp1
    lda boss_table+1,x
    sta zp_temp1+1

    ; Initialize from data
    ldy #0
    lda (zp_temp1),y
    sta boss_max_hp
    sta boss_hp
    iny
    lda (zp_temp1),y
    sta boss_max_hp+1
    sta boss_hp+1
    iny

    ; Initial position
    lda (zp_temp1),y
    sta boss_x
    iny
    lda (zp_temp1),y
    sta boss_x+1
    iny
    lda (zp_temp1),y
    sta boss_y

    ; Phase 0
    lda #0
    sta boss_phase
    sta boss_rage

    ; Load phase data
    jsr load_boss_phase

    ; Play boss entrance
    PLAY_SOUND SOUND_BOSS_HIT

    ; Achievement: Boss encounter
    lda boss_id
    clc
    adc #ACH_FIRST_BOSS
    CHECK_ACHIEVEMENT

    rts

; ============================================
; UPDATE BOSS AI
; ============================================
update_boss_ai:
    lda boss_active
    bne @boss_active
    rts

@boss_active:
    ; Update timer
    inc boss_timer

    ; Update frame animation
    lda boss_timer
    and #$03
    bne @no_frame_update
    inc boss_frame

@no_frame_update:
    ; Check phase transitions
    lda boss_hp+1
    bne @check_phase2
    lda boss_hp
    cmp boss_phase_thresholds
    bcs @check_phase2

    ; Phase transition!
    inc boss_phase
    jsr boss_phase_transition

@check_phase2:
    ; Execute current pattern
    lda boss_phase
    asl
    tax
    lda boss_pattern_table,x
    sta zp_temp1
    lda boss_pattern_table+1,x
    sta zp_temp1+1

    jmp (zp_temp1)

; ============================================
; BOSS 1: LUST ARCHON "SERAPHINA"
; ============================================
boss_lust_pattern0:  ; Phase 1: Seductive Approach
    lda boss_timer
    and #$1f
    bne @no_movement

    ; Gentle sway
    lda boss_timer
    lsr
    lsr
    lsr
    and #$07
    tax
    lda sine_table,x
    lsr
    clc
    adc #80
    sta boss_y

@no_movement:
    ; Heart pattern
    lda boss_timer
    and #$3f
    cmp #$20
    bne @no_heart

    jsr boss_shoot_hearts

@no_heart:
    ; Telegraphed attack
    lda boss_timer
    cmp #$80
    bcc @done

    lda #BOSS_ATTACK_SWEEP
    jsr boss_execute_attack

@done:
    rts

boss_lust_pattern1:  ; Phase 2: Passionate Embrace
    ; Fast horizontal movement
    lda boss_timer
    and #$0f
    bne @no_move_x

    inc boss_x
    bne @no_carry
    inc boss_x+1

@no_carry:
@no_move_x:
    ; Grappling tendrils
    lda boss_timer
    and #$1f
    cmp #$10
    bne @no_tendrils

    jsr boss_shoot_tendrils

@no_tendrils:
    ; Close-range burst
    lda boss_timer
    cmp #$60
    bcc @done

    lda #BOSS_ATTACK_BURST
    jsr boss_execute_attack

@done:
    rts

boss_lust_pattern2:  ; Phase 3: Ecstatic Release
    ; Chaotic movement
    jsr random
    and #$03
    beq @no_move

    dec a
    beq @move_up

    dec a
    beq @move_down

    ; Move left/right
    jsr random
    and #$01
    beq @move_left

    inc boss_x
    bne @move_done
    inc boss_x+1
    jmp @move_done

@move_left:
    lda boss_x
    bne @no_borrow
    dec boss_x+1
@no_borrow:
    dec boss_x

@move_up:
    lda boss_y
    cmp #40
    bcc @move_done
    dec boss_y
    jmp @move_done

@move_down:
    lda boss_y
    cmp #120
    bcs @move_done
    inc boss_y

@move_done:
@no_move:
    ; Screen-filling patterns
    lda boss_timer
    and #$0f
    bne @no_pattern

    lda boss_pattern
    jsr boss_execute_pattern
    inc boss_pattern
    lda boss_pattern
    cmp #8
    bcc @no_pattern
    lda #0
    sta boss_pattern

@no_pattern:
    ; Vulnerability windows on beat
    lda boss_timer
    and #$7f
    cmp #$40
    bcs @vulnerable

    ; Invulnerable
    lda #1
    sta boss_invulnerable
    rts

@vulnerable:
    ; Vulnerable - flash
    lda #0
    sta boss_invulnerable

    lda boss_timer
    and #$08
    beq @no_flash

    ; Flash effect
    lda #EFFECT_FLASH_WHITE
    jsr add_screen_effect

@no_flash:
    rts

boss_shoot_hearts:
    ; Shoot 3 heart projectiles
    ldx #0
@heart_loop:
    txa
    pha

    ; Find bullet slot
    jsr find_boss_bullet_slot
    bcc @no_slot

    ; Setup heart bullet
    lda #BULLET_HEART
    sta bullet_type,y

    ; Position from boss
    lda boss_x
    sta bullet_x,y
    lda boss_x+1
    sta bullet_x+1,y

    lda boss_y
    clc
    adc heart_offsets,x
    sta bullet_y,y

    ; Velocity based on player position
    jsr calculate_aim_at_player
    sta bullet_vx,y
    txa
    sta bullet_vy,y

    ; Heart color
    lda #COLOR_PASTEL_CRIMSON
    sta bullet_color,y

@no_slot:
    pla
    tax
    inx
    cpx #3
    bne @heart_loop

    ; Achievement check: Heart Unbroken
    lda boss_phase
    bne @done

    inc heart_attack_count
    lda heart_attack_count
    cmp #10
    bcc @done

    lda #ACH_HEART_UNBROKEN
    CHECK_ACHIEVEMENT

@done:
    rts

heart_offsets:
    .byte -8, 0, 8

; ============================================
; BOSS 5: PRIDE MONARCH "AURELIUS"
; ============================================
boss_pride_pattern0: ; Phase 1: Solo - Perfect Patterns
    ; Perfect symmetrical movement
    lda boss_timer
    and #$3f
    tax
    lda sine_table,x
    lsr
    lsr
    clc
    adc #60
    sta boss_y

    ; Mirror bullet patterns
    lda boss_timer
    and #$1f
    bne @no_mirror

    jsr boss_shoot_mirror

@no_mirror:
    rts

boss_pride_pattern4: ; Phase 5: Octo-Final - 8 Bosses
    ; This is the ultimate challenge
    ; We simulate 8 bosses with mirrored patterns

    lda boss_timer
    and #$07
    tax

    ; Update virtual boss position
    lda virtual_boss_x,x
    sta temp_boss_x
    lda virtual_boss_y,x
    sta temp_boss_y

    ; Shoot from this position
    jsr boss_shoot_from_virtual

    ; Rotate virtual bosses
    lda boss_timer
    and #$01
    beq @no_rotate

    ; Circular rotation
    ldx #0
@rotate_loop:
    lda virtual_boss_angle,x
    clc
    adc #1
    and #$3f
    sta virtual_boss_angle,x

    ; Update position from angle
    tay
    lda circle_x,y
    clc
    adc #80
    sta virtual_boss_x,x

    lda circle_y,y
    clc
    adc #60
    sta virtual_boss_y,x

    inx
    cpx #8
    bne @rotate_loop

@no_rotate:
    rts

; ============================================
; BOSS COLLISION DETECTION
; ============================================
check_boss_collisions:
    ; Check player bullets vs boss
    ldx #0
@bullet_loop:
    lda bullet_active,x
    beq @next_bullet

    lda bullet_owner,x
    bne @next_bullet  ; Only player bullets

    ; Check if boss is vulnerable
    lda boss_invulnerable
    bne @next_bullet

    ; Bounding box check
    lda bullet_x,x
    sec
    sbc boss_x
    sta temp1
    lda bullet_x+1,x
    sbc boss_x+1
    bne @next_bullet  ; Different high byte

    lda temp1
    bmi @next_bullet
    cmp #BOSS_WIDTH
    bcs @next_bullet

    lda bullet_y,x
    sec
    sbc boss_y
    bmi @next_bullet
    cmp #BOSS_HEIGHT
    bcs @next_bullet

    ; Hit!
    jsr boss_take_damage

    ; Remove bullet
    lda #0
    sta bullet_active,x

@next_bullet:
    inx
    cpx #MAX_BULLETS
    bne @bullet_loop

    ; Check player vs boss
    lda player_invincible
    bne @done

    lda player_x
    sec
    sbc boss_x
    sta temp1
    lda player_x+1
    sbc boss_x+1
    bne @done

    lda temp1
    bmi @done
    cmp #BOSS_WIDTH
    bcs @done

    lda player_y
    sec
    sbc boss_y
    bmi @done
    cmp #BOSS_HEIGHT
    bcs @done

    ; Player hit!
    jsr player_take_damage

@done:
    rts

boss_take_damage:
    ; Decrease HP
    lda boss_hp
    sec
    sbc #1
    sta boss_hp
    lda boss_hp+1
    sbc #0
    sta boss_hp+1

    ; Flash boss
    lda #BOSS_FLASH_TIME
    sta boss_invulnerable

    ; Hit effect
    PLAY_SOUND SOUND_BOSS_HIT

    ; Particle effect
    lda boss_x
    clc
    adc #BOSS_WIDTH/2
    sta particle_x
    lda boss_y
    clc
    adc #BOSS_HEIGHT/2
    sta particle_y
    lda #COLOR_PASTEL_CRIMSON
    sta particle_color
    lda #PARTICLE_STAR
    sta particle_type
    lda #8
    sta particle_count
    jsr create_particles

    ; Rage mode at low HP
    lda boss_hp+1
    bne @check_rage
    lda boss_hp
    cmp #BOSS_RAGE_HP
    bcs @check_rage

    lda #1
    sta boss_rage

@check_rage:
    rts

; ============================================
; BOSS PHASE TRANSITION
; ============================================
boss_phase_transition:
    ; Screen effect
    lda #EFFECT_SCREEN_SHAKE
    jsr add_screen_effect

    ; Color flash
    lda boss_phase
    asl
    tax
    lda phase_colors,x
    sta flash_color
    lda #FLASH_TIME
    sta flash_timer

    ; Load new phase data
    jsr load_boss_phase

    ; Change music
    lda boss_phase
    clc
    adc #MUSIC_BOSS_PHASE1
    jsr play_music

    ; Announcement text
    lda boss_phase
    asl
    tax
    lda phase_texts,x
    sta text_ptr
    lda phase_texts+1,x
    sta text_ptr+1

    lda #60
    sta text_timer

    ; Achievement: Phase transition without damage
    lda player_damage_taken
    bne @done

    lda #ACH_PERFECT_PHASE
    CHECK_ACHIEVEMENT

@done:
    rts

; ============================================
; BOSS DATA TABLES
; ============================================
boss_table:
    .word boss_lust_data
    .word boss_gluttony_data
    .word boss_pride_data
    .word boss_envy_data
    .word boss_wrath_data
    .word boss_sloth_data
    .word boss_greed_data
    .word boss_archon_data

boss_lust_data:
    .word 1000       ; HP
    .word 120        ; X position
    .byte 80         ; Y position
    .byte 3          ; Phases
    .word lust_phase_thresholds
    .word lust_pattern_table

lust_phase_thresholds:
    .word 600, 300

lust_pattern_table:
    .word boss_lust_pattern0
    .word boss_lust_pattern1
    .word boss_lust_pattern2

; Other boss data would follow...

phase_colors:
    .word COLOR_PASTEL_LAVENDER
    .word COLOR_PASTEL_CRIMSON
    .word COLOR_PASTEL_GOLD

phase_texts:
    .word str_phase1
    .word str_phase2
    .word str_phase3

str_phase1: .byte "Seductive Approach",0
str_phase2: .byte "Passionate Embrace",0
str_phase3: .byte "Ecstatic Release!",0

; Virtual boss data for Pride Monarch
virtual_boss_x:    .res 8
virtual_boss_y:    .res 8
virtual_boss_angle: .res 8

circle_x: .byte 0,3,6,9,12,15,17,19,21,23,24,25,26,26,26,25
          .byte 24,23,21,19,17,15,12,9,6,3,0,-3,-6,-9,-12,-15
          .byte -17,-19,-21,-23,-24,-25,-26,-26,-26,-25,-24,-23
          .byte -21,-19,-17,-15,-12,-9,-6,-3

circle_y: .byte 26,26,25,24,23,21,19,17,15,12,9,6,3,0,-3,-6
          .byte -9,-12,-15,-17,-19,-21,-23,-24,-25,-26,-26,-26
          .byte -25,-24,-23,-21,-19,-17,-15,-12,-9,-6,-3,0,3,6
          .byte 9,12,15,17,19,21,23,24,25
