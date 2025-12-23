; ============================================
; GAUDENS MACHINA EX - Main Game File
; Neo6502 @ 5.25MHz with bank switching
; ============================================
.include "gaudensex.inc"

.org $8000  ; Bank 0 Start

; ============================================
; GLOBAL VARIABLES (Zero Page)
; ============================================
zp_game_mode      = $00   ; Current game mode
zp_frame_counter  = $01   ; 2 bytes
zp_player_state   = $03   ; Player state flags
zp_bank_select    = $04   ; Current ROM bank
zp_temp1          = $05   ; Temporary
zp_temp2          = $06   ; Temporary
zp_temp3          = $07   ; Temporary

; ============================================
; RESET VECTOR
; ============================================
reset:
    sei                     ; Disable interrupts
    cld                     ; Clear decimal

    ; Initialize stack
    ldx #$ff
    txs

    ; Clear zero page
    lda #$00
    ldx #$00
@clear_zp:
    sta $00,x
    inx
    bne @clear_zp

    ; Initialize hardware
    jsr init_hardware

    ; Initialize game systems
    jsr init_game

    ; Show title screen
    jsr show_title

    cli                     ; Enable interrupts

; ============================================
; MAIN GAME LOOP
; ============================================
main_loop:
    ; Wait for vertical blank
    jsr wait_vblank

    ; Process input
    jsr read_input

    ; Update game state
    jsr update_game

    ; Render frame
    jsr render_frame

    ; Update sound
    jsr update_sound

    ; Increment frame counter
    inc zp_frame_counter
    bne @no_overflow
    inc zp_frame_counter+1

@no_overflow:
    jmp main_loop

; ============================================
; UPDATE GAME (Mode dispatcher)
; ============================================
update_game:
    lda zp_game_mode
    asl                     ; *2 for jump table
    tax
    lda game_mode_table,x
    sta zp_temp1
    lda game_mode_table+1,x
    sta zp_temp2
    jmp (zp_temp1)

game_mode_table:
    .word update_title      ; MODE_TITLE = 0
    .word update_playing    ; MODE_PLAYING = 1
    .word update_boss       ; MODE_BOSS = 2
    .word update_shop       ; MODE_SHOP = 3
    .word update_achievement ; MODE_ACHIEVEMENT = 4
    .word update_ending     ; MODE_ENDING = 5

; ============================================
; RENDER FRAME (Mode dispatcher)
; ============================================
render_frame:
    ; Clear back buffer
    jsr clear_buffer

    ; Render based on mode
    lda zp_game_mode
    asl
    tax
    lda render_table,x
    sta zp_temp1
    lda render_table+1,x
    sta zp_temp2
    jmp (zp_temp1)

render_table:
    .word render_title
    .word render_playing
    .word render_boss
    .word render_shop
    .word render_achievement
    .word render_ending

; ============================================
; HARDWARE INITIALIZATION
; ============================================
init_hardware:
    ; Initialize VGA
    lda #VGA_MODE_640x480
    sta VGA_CONTROL

    ; Initialize sound
    lda #SOUND_INIT
    sta SOUND_CONTROL

    ; Initialize joystick
    lda #$ff
    sta JOYSTICK_DDR

    ; Initialize bank switching
    lda #BANK_GAME
    sta BANK_SELECT

    ; Enable battery RAM
    lda #SAVE_ENABLE
    sta SAVE_CONTROL

    rts

; ============================================
; GAME INITIALIZATION
; ============================================
init_game:
    ; Load save data
    jsr load_save

    ; Initialize player
    jsr init_player

    ; Initialize achievement system
    jsr init_achievements

    ; Initialize weapon system
    jsr init_weapons

    ; Initialize particle system
    jsr init_particles

    ; Initialize music
    jsr init_music

    ; Start title music
    lda #MUSIC_TITLE
    jsr play_music

    rts

; ============================================
; TITLE SCREEN
; ============================================
show_title:
    ; Set title screen mode
    lda #MODE_TITLE
    sta zp_game_mode

    ; Draw title screen
    jsr draw_title_screen

    ; Animate title
    lda #$00
    sta title_animation_frame

    rts

update_title:
    ; Animate title elements
    inc title_animation_frame
    lda title_animation_frame
    and #$0f
    sta title_pulse

    ; Check for coin insert
    lda JOYSTICK_BUTTONS
    and #BUTTON_COIN
    beq @check_start

    ; Coin inserted
    jsr add_coin
    jsr play_coin_sound

@check_start:
    ; Check for start button
    lda JOYSTICK_BUTTONS
    and #BUTTON_START
    beq @done

    ; Start game if coins > 0
    lda coins
    beq @done

    ; Deduct coin and start
    dec coins
    jsr start_game

@done:
    rts

; ============================================
; START GAME
; ============================================
start_game:
    ; Initialize level
    lda #ZONE_GARDEN
    sta current_zone
    jsr init_zone

    ; Set playing mode
    lda #MODE_PLAYING
    sta zp_game_mode

    ; Start level music
    lda #MUSIC_ZONE1
    jsr play_music

    ; Achievement: First play
    lda #ACH_FIRST_PLAY
    jsr check_achievement

    rts

; ============================================
; PLAYING MODE UPDATE
; ============================================
update_playing:
    ; Update player
    jsr update_player

    ; Update enemies
    jsr update_enemies

    ; Update bullets
    jsr update_bullets

    ; Update particles
    jsr update_particles

    ; Update power-ups
    jsr update_powerups

    ; Update scroll
    jsr update_scroll

    ; Check collisions
    jsr check_collisions

    ; Update HUD
    jsr update_hud

    ; Check for zone completion
    lda zone_complete
    beq @done

    ; Zone complete - go to boss
    jsr start_boss_fight

@done:
    rts

; ============================================
; BOSS FIGHT
; ============================================
start_boss_fight:
    ; Switch to boss bank
    lda #BANK_BOSS
    sta BANK_SELECT

    ; Initialize boss
    lda current_zone
    asl
    tax
    lda boss_table,x
    sta boss_id
    jsr init_boss

    ; Change music
    lda #MUSIC_BOSS
    jsr play_music

    ; Set boss mode
    lda #MODE_BOSS
    sta zp_game_mode

    rts

update_boss:
    ; Update player
    jsr update_player

    ; Update boss
    jsr update_boss_ai

    ; Update boss bullets
    jsr update_boss_bullets

    ; Update particles
    jsr update_particles

    ; Check collisions
    jsr check_boss_collisions

    ; Check boss defeat
    lda boss_hp
    bne @done

    ; Boss defeated!
    jsr boss_defeated

@done:
    rts

boss_defeated:
    ; Award score
    lda boss_id
    jsr award_boss_score

    ; Unlock achievements
    lda boss_id
    jsr unlock_boss_achievements

    ; Zone complete
    inc current_zone

    ; Check for game completion
    lda current_zone
    cmp #ZONE_COUNT
    bcc @next_zone

    ; Game complete!
    jsr show_ending
    rts

@next_zone:
    ; Go to next zone
    jsr init_zone
    lda #MODE_PLAYING
    sta zp_game_mode

    ; Change music
    lda current_zone
    clc
    adc #MUSIC_ZONE1
    jsr play_music

    rts

; ============================================
; INTERRUPT VECTORS
; ============================================
.org $fffa
.word nmi_handler    ; NMI vector
.word reset         ; Reset vector
.word irq_handler   ; IRQ vector

; ============================================
; NMI HANDLER (VBlank)
; ============================================
nmi_handler:
    ; Save registers
    pha
    txa
    pha
    tya
    pha

    ; Set vblank flag
    lda #$01
    sta vblank_flag

    ; Restore registers
    pla
    tay
    pla
    tax
    pla

    rti

; ============================================
; IRQ HANDLER (Music timer)
; ============================================
irq_handler:
    ; Save registers
    pha

    ; Update music
    jsr update_music_timer

    ; Clear interrupt
    lda #IRQ_ACK
    sta IRQ_CONTROL

    ; Restore
    pla
    rti

; ============================================
; WAIT FOR VBLANK
; ============================================
wait_vblank:
    lda vblank_flag
    beq wait_vblank

    ; Clear flag
    lda #$00
    sta vblank_flag

    rts

; ============================================
; DATA SECTION
; ============================================
vblank_flag:        .byte 0
title_animation_frame: .byte 0
title_pulse:        .byte 0
coins:              .byte 0
current_zone:       .byte 0
zone_complete:      .byte 0
boss_id:            .byte 0
boss_hp:            .word 0

; Boss table (zone -> boss ID)
boss_table:
    .byte BOSS_LUST       ; Zone 1
    .byte BOSS_GLUTTONY   ; Zone 2
    .byte BOSS_PRIDE      ; Zone 3
    .byte BOSS_ENVY       ; Zone 4
    .byte BOSS_WRATH      ; Zone 5
    .byte BOSS_SLOTH      ; Zone 6
    .byte BOSS_GREED      ; Zone 7
    .byte BOSS_ARCHON     ; Zone 8
