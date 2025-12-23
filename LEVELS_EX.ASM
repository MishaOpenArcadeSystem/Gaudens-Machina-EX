; ============================================
; 8-ZONE LEVEL SYSTEM WITH GIMMICKS
; ============================================
.include "gaudensex.inc"

.segment "BANK_LEVELS"
.org $8000

; ============================================
; ZONE DATA STRUCTURE
; ============================================
.struct ZoneData
    bg_color     .byte
    fg_color     .byte
    parallax_speed .byte
    music        .byte
    enemy_table  .word
    powerup_rate .byte
    gimmick      .byte
    gimmick_param .byte
.endstruct

; ============================================
; ZONE 1: GARDEN OF INNOCENCE
; ============================================
zone1_data:
    .byte COLOR_PASTEL_PINK      ; Background
    .byte COLOR_PASTEL_GREEN     ; Foreground
    .byte 1                      ; Slow parallax
    .byte MUSIC_ZONE1            ; Uplifting
    .word zone1_enemies
    .byte 20                     ; 20% powerup rate
    .byte GIMMICK_NONE
    .byte 0

zone1_enemies:
    ; Wave 1
    .byte ENEMY_BIGHEAD, 200, 40, PATTERN_FLOAT
    .byte ENEMY_BIGHEAD, 220, 80, PATTERN_FLOAT
    .byte ENEMY_FLOATY,  240, 60, PATTERN_SINE
    .byte $FF

    ; Wave 2
    .byte ENEMY_TOASTER, 300, 50, PATTERN_HORIZONTAL
    .byte ENEMY_TOASTER, 320, 70, PATTERN_HORIZONTAL
    .byte $FF

    ; Wave 3 (first mini-boss)
    .byte ENEMY_TEMPTER, 400, 60, PATTERN_BOSS_MINOR
    .byte $FF

; ============================================
; ZONE 4: ALTAR OF DESIRE
; ============================================
zone4_data:
    .byte COLOR_PASTEL_CRIMSON   ; Red background
    .byte COLOR_PASTEL_GOLD      ; Gold details
    .byte 2                      ; Medium parallax
    .byte MUSIC_ZONE4            ; Deep house
    .word zone4_enemies
    .byte 30                     ; 30% powerup rate
    .byte GIMMICK_HEARTBEAT
    .byte 122                    ; BPM

zone4_enemies:
    ; Introduction to adult enemies
    .byte ENEMY_SUCCUBUS, 150, 40, PATTERN_SEDUCE
    .byte ENEMY_SUCCUBUS, 180, 80, PATTERN_SEDUCE
    .byte ENEMY_INCUBUS,  210, 60, PATTERN_CHARGE
    .byte $FF

    ; Wave with gimmick
    .byte ENEMY_SIREN,   250, 50, PATTERN_SING
    .byte ENEMY_SIREN,   280, 70, PATTERN_SING
    .byte ENEMY_HARPY,   310, 40, PATTERN_SWARM
    .byte ENEMY_HARPY,   310, 80, PATTERN_SWARM
    .byte $FF

; ============================================
; ZONE 8: EPILOGUE - DAWN
; ============================================
zone8_data:
    .byte COLOR_PASTEL_CHAMPAGNE ; Champagne sky
    .byte COLOR_PASTEL_CYAN      ; Cyan details
    .byte 0                      ; No parallax (calm)
    .byte MUSIC_ZONE8            ; Calm resolution
    .word zone8_enemies
    .byte 50                     ; High powerup rate
    .byte GIMMICK_CALM
    .byte 0

zone8_enemies:
    ; Reflective enemies
    .byte ENEMY_VOYEUR, 100, 50, PATTERN_MIRROR
    .byte ENEMY_VOYEUR, 130, 70, PATTERN_MIRROR
    .byte $FF

    ; Final wave before credits
    .byte ENEMY_ECSTATIC, 200, 60, PATTERN_FINAL
    .byte $FF

; ============================================
; SECRET ZONE: ETERNAL DANCE CHAMBER
; ============================================
zone_secret_data:
    .byte COLOR_PASTEL_LAVENDER  ; Purple
    .byte COLOR_PASTEL_SAPPHIRE  ; Blue
    .byte 3                      ; Fast parallax
    .byte MUSIC_ETERNAL          ; Eternal dance track
    .word zone_secret_enemies
    .byte 100                    ; Always powerups
    .byte GIMMICK_ENDLESS
    .byte 0

zone_secret_enemies:
    ; Procedural generation markers
    .byte $FE                    ; Start procedural
    .byte 10                     ; 10 waves
    .byte $FF

; ============================================
; LEVEL GIMMICK SYSTEM
; ============================================
update_level_gimmick:
    lda current_zone
    asl
    tax
    lda zone_table,x
    sta zp_temp1
    lda zone_table+1,x
    sta zp_temp1+1

    ; Get gimmick
    ldy #ZoneData::gimmick
    lda (zp_temp1),y
    beq @no_gimmick

    ; Execute gimmick
    asl
    tax
    lda gimmick_table,x
    sta zp_temp2
    lda gimmick_table+1,x
    sta zp_temp2+1

    jmp (zp_temp2)

@no_gimmick:
    rts

gimmick_table:
    .word gimmick_none
    .word gimmick_heartbeat
    .word gimmick_mirror
    .word gimmick_sensory
    .word gimmick_calm
    .word gimmick_endless

; ============================================
; GIMMICK: HEARTBEAT
; ============================================
gimmick_heartbeat:
    ; Everything pulses to BPM
    lda frame_counter
    and #$3F  ; 64 frames = ~1 sec at 60fps
    cmp #$20
    bcs @off_beat

    ; On beat
    lda #1
    sta on_beat
    bra @spawn_check

@off_beat:
    lda #0
    sta on_beat

@spawn_check:
    ; Spawn enemies on beat
    lda on_beat
    beq @visual_effect

    ; Only spawn every 4 beats
    lda beat_counter
    and #$03
    bne @visual_effect

    jsr spawn_heartbeat_enemy

@visual_effect:
    ; Visual pulse
    lda on_beat
    beq @no_pulse

    ; Screen pulse effect
    lda #EFFECT_PULSE_RED
    jsr add_screen_effect

@no_pulse:
    ; Player bonus for dodging on beat
    lda player_dodged_beat
    beq @done

    ; Increase ecstasy meter
    inc ecstasy_meter
    lda #0
    sta player_dodged_beat

@done:
    rts

spawn_heartbeat_enemy:
    ; Spawn enemy at edge
    jsr find_free_enemy_slot
    bcs @no_slot

    ; Random type
    jsr random
    and #$03
    clc
    adc #ENEMY_SUCCUBUS
    sta enemy_type,x

    ; Position at right edge
    lda scroll_x
    clc
    adc #SCREEN_WIDTH + 16
    sta enemy_x,x
    lda scroll_x+1
    adc #0
    sta enemy_x+1,x

    ; Random Y
    jsr random
    and #$3F
    clc
    adc #20
    sta enemy_y,x

    ; Heartbeat pattern
    lda #PATTERN_HEARTBEAT
    sta enemy_pattern,x

@no_slot:
    rts

; ============================================
; GIMMICK: MIRROR WORLD
; ============================================
gimmick_mirror:
    ; Mirror enemies and bullets
    lda frame_counter
    and #$01
    bne @no_mirror_update

    ; Create mirror of each enemy
    ldx #0
@enemy_loop:
    lda enemy_active,x
    beq @next_enemy

    ; Check if already mirrored
    lda enemy_data,x
    and #MIRROR_FLAG
    bne @next_enemy

    ; Create mirror
    jsr create_mirror_enemy

@next_enemy:
    inx
    cpx #MAX_ENEMIES
    bne @enemy_loop

@no_mirror_update:
    ; Mirror player bullets
    lda frame_counter
    and #$03
    bne @done

    ldx #0
@bullet_loop:
    lda bullet_active,x
    beq @next_bullet

    lda bullet_owner,x
    bne @next_bullet  ; Player only

    ; Check if mirrored
    lda bullet_data,x
    and #MIRROR_FLAG
    bne @next_bullet

    ; Create mirror bullet
    jsr create_mirror_bullet

@next_bullet:
    inx
    cpx #MAX_BULLETS
    bne @bullet_loop

@done:
    rts

create_mirror_enemy:
    ; Create enemy mirrored on Y-axis
    ; Original in X, create mirror in free slot
    txa
    pha

    jsr find_free_enemy_slot
    bcs @no_mirror_slot

    ; Copy enemy but mirror Y
    lda enemy_type,x
    sta enemy_type,y

    lda enemy_x,x
    sta enemy_x,y
    lda enemy_x+1,x
    sta enemy_x+1,y

    ; Mirror Y: 100 - original_y
    lda #100
    sec
    sbc enemy_y,x
    sta enemy_y,y

    lda enemy_pattern,x
    ora #PATTERN_MIRROR
    sta enemy_pattern,y

    ; Set mirrored flag on original
    lda enemy_data,x
    ora #MIRROR_FLAG
    sta enemy_data,x

@no_mirror_slot:
    pla
    tax
    rts

; ============================================
; ENDLESS MODE GIMMICK
; ============================================
gimmick_endless:
    ; Procedural wave generation
    lda enemy_count
    cmp #5
    bcs @no_spawn

    ; Generate new wave
    lda wave_number
    jsr generate_endless_wave

    inc wave_number

@no_spawn:
    ; Increase difficulty over time
    lda wave_timer
    beq @no_timer_update

    dec wave_timer

@no_timer_update:
    ; Every 10 waves, increase intensity
    lda wave_number
    and #$0F
    cmp #10
    bne @done

    inc difficulty_level

    ; Achievement: Endless dancer
    lda wave_number
    cmp #50
    bcc @done

    lda #ACH_ETERNAL_DANCER
    CHECK_ACHIEVEMENT

@done:
    rts

generate_endless_wave:
    ; Generate wave based on wave number
    sta current_wave

    ; Base enemy count
    lsr
    lsr  ; wave/4
    clc
    adc #3
    sta enemy_count

    ; Generate enemies
    ldx #0
@gen_loop:
    cpx enemy_count
    beq @gen_done

    ; Find free slot
    jsr find_free_enemy_slot
    bcs @gen_done

    ; Random type based on wave
    lda current_wave
    lsr
    lsr  ; /4
    clc
    adc #ENEMY_SUCCUBUS
    cmp #ENEMY_COUNT
    bcc @valid_type
    lda #ENEMY_COUNT-1

@valid_type:
    sta enemy_type,y

    ; Position
    lda scroll_x
    clc
    adc #SCREEN_WIDTH + (x * 32)
    sta enemy_x,y
    lda scroll_x+1
    adc #0
    sta enemy_x+1,y

    ; Random Y
    jsr random
    and #$3F
    clc
    adc #20
    sta enemy_y,y

    ; Pattern based on type
    lda enemy_type,y
    asl
    tax
    lda enemy_pattern_table,x
    sta enemy_pattern,y

    inx
    bra @gen_loop

@gen_done:
    ; Set timer for next wave
    lda #180  ; 3 seconds
    sta wave_timer

    rts

; ============================================
; ZONE TABLE
; ============================================
zone_table:
    .word zone1_data
    .word zone2_data
    .word zone3_data
    .word zone4_data
    .word zone5_data
    .word zone6_data
    .word zone7_data
    .word zone8_data
    .word zone_secret_data

; Gimmick IDs
GIMMICK_NONE     = 0
GIMMICK_HEARTBEAT = 1
GIMMICK_MIRROR   = 2
GIMMICK_SENSORY  = 3
GIMMICK_CALM     = 4
GIMMICK_ENDLESS  = 5

; Pattern IDs
PATTERN_FLOAT    = 0
PATTERN_SINE     = 1
PATTERN_HORIZONTAL = 2
PATTERN_BOSS_MINOR = 3
PATTERN_SEDUCE   = 4
PATTERN_CHARGE   = 5
PATTERN_SING     = 6
PATTERN_SWARM    = 7
PATTERN_MIRROR   = 8
PATTERN_FINAL    = 9
PATTERN_HEARTBEAT = 10

; Flags
MIRROR_FLAG = %10000000

; Variables
current_wave:      .byte 0
wave_number:       .byte 0
wave_timer:        .byte 0
difficulty_level:  .byte 0
on_beat:           .byte 0
beat_counter:      .byte 0
player_dodged_beat: .byte 0
