; ============================================
; SECRETS, CHEAT CODES & EASTER EGGS
; ============================================
.include "gaudensex.inc"

.segment "BANK_GAME"
.org $F000

; ============================================
; CHEAT CODE SYSTEM
; ============================================
cheat_input_buffer: .res 16
cheat_input_index:  .byte 0
active_cheats:      .byte 0

; Cheat code definitions
.struct CheatCode
    sequence   .byte 8    ; Input sequence
    effect     .word      ; Function to call
    name       .word      ; Cheat name
.endstruct

cheat_codes:
; Konami code
.byte BUTTON_UP, BUTTON_UP, BUTTON_DOWN, BUTTON_DOWN
.byte BUTTON_LEFT, BUTTON_RIGHT, BUTTON_LEFT, BUTTON_RIGHT
.byte BUTTON_B, BUTTON_A
.word cheat_konami
.word str_konami_name

; All weapons
.byte BUTTON_UP, BUTTON_LEFT, BUTTON_DOWN, BUTTON_RIGHT
.byte BUTTON_A, BUTTON_A, BUTTON_B, BUTTON_B
.word cheat_all_weapons
.word str_all_weapons_name

; Infinite lives
.byte BUTTON_A, BUTTON_B, BUTTON_A, BUTTON_B
.byte BUTTON_UP, BUTTON_DOWN, BUTTON_UP, BUTTON_DOWN
.word cheat_infinite_lives
.word str_infinite_lives_name

; Adult filter toggle
.byte BUTTON_LEFT, BUTTON_RIGHT, BUTTON_LEFT, BUTTON_RIGHT
.byte BUTTON_UP, BUTTON_DOWN, BUTTON_B, BUTTON_A
.word cheat_adult_filter
.word str_adult_filter_name

; Debug mode
.byte BUTTON_B, BUTTON_B, BUTTON_A, BUTTON_A
.byte BUTTON_DOWN, BUTTON_UP, BUTTON_DOWN, BUTTON_UP
.word cheat_debug_mode
.word str_debug_name

cheat_count = 5

; ============================================
; CHECK CHEAT INPUT
; ============================================
check_cheat_input:
    ; Read current input
    lda joystick_state
    and #$0F  ; Only directions
    beq @no_input

    ; Store in buffer
    ldx cheat_input_index
    sta cheat_input_buffer,x

    ; Check against all cheat codes
    ldy #0
@check_cheat_loop:
    ; Get cheat sequence pointer
    tya
    lda #.sizeof(CheatCode)
    sta multiplier
    sty multiplicand
    jsr multiply

    lda product
    clc
    adc #<cheat_codes
    sta cheat_ptr
    lda product+1
    adc #>cheat_codes
    sta cheat_ptr+1

    ; Check sequence
    ldx #0
@check_sequence:
    lda (cheat_ptr),y
    cmp cheat_input_buffer,x
    bne @next_cheat

    iny
    inx
    cpx #8
    bne @check_sequence

    ; Cheat activated!
    tya
    jsr activate_cheat

    ; Clear buffer
    lda #0
    sta cheat_input_index
    rts

@next_cheat:
    iny
    cpy #cheat_count
    bne @check_cheat_loop

    ; No cheat matched
    inc cheat_input_index
    lda cheat_input_index
    cmp #16
    bcc @no_input

    ; Buffer full, clear it
    lda #0
    sta cheat_input_index

@no_input:
    rts

; ============================================
; ACTIVATE CHEAT
; ============================================
; Input: A = cheat index
activate_cheat:
    pha
    phx
    phy

    ; Get cheat data
    tay
    lda #.sizeof(CheatCode)
    sta multiplier
    sty multiplicand
    jsr multiply

    lda product
    clc
    adc #<cheat_codes
    sta cheat_ptr
    lda product+1
    adc #>cheat_codes
    sta cheat_ptr+1

    ; Set cheat active flag
    lda #1
    ldx cheat_index
    sta active_cheats,x

    ; Call effect
    ldy #8  ; Effect pointer offset
    lda (cheat_ptr),y
    sta effect_ptr
    iny
    lda (cheat_ptr),y
    sta effect_ptr+1

    jsr call_effect

    ; Show cheat name
    ldy #10 ; Name pointer offset
    lda (cheat_ptr),y
    sta text_ptr
    iny
    lda (cheat_ptr),y
    sta text_ptr+1

    lda #60
    sta cheat_message_timer

    ; Play sound
    PLAY_SOUND SOUND_CHEAT

    ; Achievement: First cheat
    lda #ACH_FIRST_CHEAT
    CHECK_ACHIEVEMENT

    ply
    plx
    pla
    rts

call_effect:
    jmp (effect_ptr)

; ============================================
; CHEAT EFFECTS
; ============================================
cheat_konami:
    ; Unlock everything
    lda #$FF
    sta unlocked_weapons
    sta unlocked_ships

    ; Max ecstasy
    lda ecstasy_max
    sta ecstasy_meter

    ; All achievements viewable
    lda #CHEAT_KONAMI
    sta active_cheats

    ; Special visual effect
    lda #EFFECT_KONAMI
    jsr add_screen_effect

    rts

cheat_all_weapons:
    ; Unlock all weapons
    lda #$FF
    sta unlocked_weapons

    ; Set to best weapon
    lda #WEAPON_ECSTASY
    sta current_weapon

    ; Visual effect
    jsr weapon_evolution_effect

    rts

cheat_infinite_lives:
    ; Infinite lives
    lda #99
    sta player_hp

    ; Can't die
    lda #CHEAT_INVINCIBLE
    sta active_cheats

    ; Golden player
    lda #COLOR_PASTEL_GOLD
    sta player_color

    rts

cheat_adult_filter:
    ; Toggle adult content
    lda adult_filter
    eor #$01
    sta adult_filter

    ; Change palette
    jsr update_palette_for_filter

    ; Message
    lda adult_filter
    beq @filter_off

    lda #<str_filter_on
    sta text_ptr
    lda #>str_filter_on
    sta text_ptr+1
    bra @show_message

@filter_off:
    lda #<str_filter_off
    sta text_ptr
    lda #>str_filter_off
    sta text_ptr+1

@show_message:
    lda #60
    sta cheat_message_timer

    rts

cheat_debug_mode:
    ; Enable debug features
    lda #CHEAT_DEBUG
    sta active_cheats

    ; Show hitboxes
    lda #1
    sta show_hitboxes

    ; Show FPS counter
    lda #1
    sta show_fps

    ; God mode
    lda #1
    sta god_mode

    rts

; ============================================
; EASTER EGGS
; ============================================
check_easter_eggs:
    ; Check for special conditions

    ; 1. Play for exactly 6:66
    lda play_time+1
    cmp #6
    bne @check_2
    lda play_time
    cmp #66
    bne @check_2

    ; Devil's time easter egg
    jsr easter_devil_time

@check_2:
    ; 2. Score with all 6s
    lda score+2
    and #$0F
    cmp #6
    bne @check_3

    lda score+1
    and #$F0
    cmp #$60
    bne @check_3

    ; 666 score
    jsr easter_devil_score

@check_3:
    ; 3. Kill count 777
    lda kill_count+1
    bne @check_4
    lda kill_count
    cmp #$07
    bne @check_4

    ; Lucky 7
    jsr easter_lucky_7

@check_4:
    ; 4. No movement challenge
    lda player_movement_count
    bne @done

    ; Stationary master
    jsr easter_stationary

@done:
    rts

easter_devil_time:
    ; Play creepy music
    lda #MUSIC_DEVIL
    jsr play_music

    ; Visual effect
    lda #EFFECT_DEVIL
    jsr add_screen_effect

    ; Achievement
    lda #ACH_DEVIL_TIME
    CHECK_ACHIEVEMENT

    rts

easter_lucky_7:
    ; Bonus lives
    lda player_hp
    clc
    adc #7
    cmp #99
    bcc @not_max
    lda #99

@not_max:
    sta player_hp

    ; 77777 points
    lda #$77
    sta bonus_score
    lda #$07
    sta bonus_score+1
    ADD_SCORE bonus_score

    ; Achievement
    lda #ACH_LUCKY_7
    CHECK_ACHIEVEMENT

    rts

; ============================================
; SECRET ROOMS
; ============================================
check_secret_room:
    ; Check if player is in secret room position
    lda player_x+1
    cmp #$01
    bne @no_secret

    lda player_x
    cmp #$23
    bne @no_secret

    lda player_y
    cmp #$45
    bne @no_secret

    ; Secret room coordinates (x=123, y=69)
    jsr enter_secret_room

@no_secret:
    rts

enter_secret_room:
    ; Change to secret room
    lda #ZONE_SECRET
    sta current_zone

    ; Special music
    lda #MUSIC_SECRET
    jsr play_music

    ; Visual effect
    lda #EFFECT_SECRET
    jsr add_screen_effect

    ; Achievement
    lda #ACH_SECRET_ROOM
    CHECK_ACHIEVEMENT

    ; Developer message
    lda #<str_dev_message
    sta text_ptr
    lda #>str_dev_message
    sta text_ptr+1

    lda #120
    sta secret_message_timer

    rts

; ============================================
; HIDDEN ENDINGS
; ============================================
check_hidden_ending:
    ; Check conditions for hidden ending

    ; 1. All achievements
    ldx #0
    lda #0
@check_all_achievements:
    ora achievement_unlocked,x
    inx
    cpx #4
    bne @check_all_achievements

    cmp #$FF
    bne @check_2

    ; All achievements unlocked
    jsur ending_true

@check_2:
    ; 2. No damage run
    lda total_damage_taken
    bne @check_3

    ; Perfect run
    jsur ending_perfect

@check_3:
    ; 3. Speedrun
    lda play_time+1
    bne @done
    lda play_time
    cmp #1800  ; 30 minutes
    bcs @done

    ; Speedrun ending
    jsur ending_speedrun

@done:
    rts

ending_true:
    ; True ending
    lda #ENDING_TRUE
    sta ending_type

    ; Special credits
    jsr show_true_credits

    ; Unlock secret character
    lda #SHIP_SECRET
    sta unlocked_ships

    rts

; ============================================
; DATA
; ============================================
str_konami_name:        .byte "KONAMI CODE",0
str_all_weapons_name:   .byte "ALL WEAPONS",0
str_infinite_lives_name: .byte "INFINITE LIVES",0
str_adult_filter_name:  .byte "ADULT FILTER",0
str_debug_name:         .byte "DEBUG MODE",0

str_filter_on:          .byte "ADULT FILTER: ON",0
str_filter_off:         .byte "ADULT FILTER: OFF",0

str_dev_message:        .byte "YOU FOUND THE SECRET!",0

; Cheat flags
CHEAT_KONAMI    = %00000001
CHEAT_INVINCIBLE = %00000010
CHEAT_DEBUG     = %00000100

; Variables
cheat_ptr:      .word 0
effect_ptr:     .word 0
cheat_index:    .byte 0
cheat_message_timer: .byte 0
secret_message_timer: .byte 0

adult_filter:   .byte 0
show_hitboxes:  .byte 0
show_fps:       .byte 0
god_mode:       .byte 0

player_movement_count: .word 0
total_damage_taken: .word 0
ending_type:    .byte 0

bonus_score:    .word 0
