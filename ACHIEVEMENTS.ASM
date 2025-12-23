; ============================================
; ACHIEVEMENT SYSTEM
; ============================================
.include "gaudensex.inc"

.segment "BANK_UI"
.org $A000

; ============================================
; ACHIEVEMENT DATA
; ============================================
achievement_data:
; Format: ID, Type, ProgressMax, TitlePtr, DescPtr, BadgeSpritePtr

; 0: First Play
.byte ACH_FIRST_PLAY, ACH_TYPE_BRONZE
.word 1
.word str_title_first_play
.word str_desc_first_play
.word badge_first_play

; 1: First Kill
.byte ACH_FIRST_KILL, ACH_TYPE_BRONZE
.word 1
.word str_title_first_kill
.word str_desc_first_kill
.word badge_first_kill

; 2: No Miss Clear
.byte ACH_NO_MISS, ACH_TYPE_SILVER
.word 1
.word str_title_no_miss
.word str_desc_no_miss
.word badge_no_miss

; 3: Combo Master
.byte ACH_COMBO_MASTER, ACH_TYPE_SILVER
.word 50
.word str_title_combo_master
.word str_desc_combo_master
.word badge_combo_master

; 4: Perfect Boss
.byte ACH_PERFECT_BOSS, ACH_TYPE_GOLD
.word 5
.word str_title_perfect_boss
.word str_desc_perfect_boss
.word badge_perfect_boss

; 5: Speedrunner
.byte ACH_SPEEDRUNNER, ACH_TYPE_GOLD
.word 1
.word str_title_speedrunner
.word str_desc_speedrunner
.word badge_speedrunner

; 6: Crimson Master
.byte ACH_CRIMSON_MASTER, ACH_TYPE_PLATINUM
.word 1
.word str_title_crimson_master
.word str_desc_crimson_master
.word badge_crimson_master

; 7: Eternal Dancer
.byte ACH_ETERNAL_DANCER, ACH_TYPE_SECRET
.word 1
.word str_title_eternal_dancer
.word str_desc_eternal_dancer
.word badge_eternal_dancer

; ... Continue for all 32 achievements

achievement_data_end:

; ============================================
; INITIALIZE ACHIEVEMENTS
; ============================================
init_achievements:
    ; Load from save
    BANK_SWITCH BANK_UI

    ; Copy achievement state from save RAM
    ldx #31
@load_loop:
    lda SAVE_RAM + $100,x  ; Achievement unlock flags
    sta achievement_unlocked,x
    dex
    bpl @load_loop

    ; Load progress
    ldx #63
@progress_loop:
    lda SAVE_RAM + $140,x  ; Achievement progress
    sta achievement_progress,x
    dex
    bpl @progress_loop

    rts

; ============================================
; CHECK ACHIEVEMENT
; ============================================
; Input: A = achievement ID
check_achievement:
    pha
    phx
    phy

    ; Check if already unlocked
    tax
    lda achievement_unlocked,x
    bne @already_unlocked

    ; Get achievement data pointer
    txa
    jsr get_achievement_ptr
    sta zp_temp1
    sty zp_temp1+1

    ; Check progress
    ldy #2  ; Progress max low byte
    lda (zp_temp1),y
    sta zp_temp2
    iny
    lda (zp_temp1),y
    sta zp_temp2+1

    ; Compare with current progress
    txa
    asl
    tay
    lda achievement_progress,y
    cmp zp_temp2
    lda achievement_progress+1,y
    sbc zp_temp2+1
    bcc @not_complete

    ; Achievement complete!
    lda #$01
    sta achievement_unlocked,x

    ; Save to RAM
    lda achievement_unlocked,x
    sta SAVE_RAM + $100,x

    ; Show notification
    txa
    jsr show_achievement_notification

    ; Play sound
    PLAY_SOUND SOUND_ACHIEVEMENT

@not_complete:
@already_unlocked:
    ply
    plx
    pla
    rts

; ============================================
; INCREMENT ACHIEVEMENT PROGRESS
; ============================================
; Input: A = achievement ID, X = amount
inc_achievement_progress:
    pha
    phx
    phy

    ; Get progress pointer
    tay
    tya
    asl
    tay

    ; Add amount
    clc
    txa
    adc achievement_progress,y
    sta achievement_progress,y
    lda #$00
    adc achievement_progress+1,y
    sta achievement_progress+1,y

    ; Save to RAM
    tya
    lsr
    tax
    lda achievement_unlocked,x
    sta SAVE_RAM + $100,x

    tya
    pha
    lda achievement_progress,y
    sta SAVE_RAM + $140,y
    iny
    lda achievement_progress,y
    sta SAVE_RAM + $140,y

    pla
    tay
    lda achievement_progress,y
    sta SAVE_RAM + $140,y
    iny
    lda achievement_progress,y
    sta SAVE_RAM + $140,y

    ; Check achievement
    tya
    lsr
    jsr check_achievement

    ply
    plx
    pla
    rts

; ============================================
; SHOW ACHIEVEMENT NOTIFICATION
; ============================================
; Input: A = achievement ID
show_achievement_notification:
    pha
    phx
    phy

    ; Set achievement display
    sta notification_achievement

    ; Start timer
    lda #NOTIFICATION_TIME
    sta notification_timer

    ; Set display mode
    lda zp_game_mode
    sta previous_game_mode
    lda #MODE_ACHIEVEMENT
    sta zp_game_mode

    ; Get achievement data
    lda notification_achievement
    jsr get_achievement_ptr
    sta zp_temp1
    sty zp_temp1+1

    ; Get badge sprite
    ldy #5
    lda (zp_temp1),y
    sta badge_sprite_ptr
    iny
    lda (zp_temp1),y
    sta badge_sprite_ptr+1

    ; Get title
    ldy #3
    lda (zp_temp1),y
    sta title_ptr
    iny
    lda (zp_temp1),y
    sta title_ptr+1

    ; Create particle effect based on type
    ldy #1
    lda (zp_temp1),y  ; Type
    tax
    lda achievement_colors,x
    sta particle_color

    ; Center screen effect
    lda #SCREEN_WIDTH/2
    sta particle_x
    lda #SCREEN_HEIGHT/2
    sta particle_y

    lda #PARTICLE_CONFETTI
    sta particle_type
    lda #24
    sta particle_count
    jsr create_particles

    ply
    plx
    pla
    rts

; ============================================
; GET ACHIEVEMENT POINTER
; ============================================
; Input: A = achievement ID
; Output: A/Y = pointer to data
get_achievement_ptr:
    ; Each entry is 7 bytes
    sta zp_temp3
    asl
    asl
    asl
    sec
    sbc zp_temp3  ; *7
    clc
    adc #<achievement_data
    tay
    lda #>achievement_data
    adc #$00
    rts

; ============================================
; UPDATE ACHIEVEMENT MODE
; ============================================
update_achievement:
    ; Decrement timer
    dec notification_timer
    bne @still_showing

    ; Timer expired, return to previous mode
    lda previous_game_mode
    sta zp_game_mode

@still_showing:
    ; Pulse effect
    lda notification_timer
    and #$03
    bne @done

    ; Toggle pulse
    lda notification_pulse
    eor #$01
    sta notification_pulse

@done:
    rts

; ============================================
; RENDER ACHIEVEMENT NOTIFICATION
; ============================================
render_achievement:
    ; Draw background overlay
    lda #COLOR_PASTEL_EBONY
    jsr fill_screen_semi

    ; Draw badge (32x32 centered)
    lda badge_sprite_ptr
    sta zp_temp1
    lda badge_sprite_ptr+1
    sta zp_temp1+1

    lda #(SCREEN_WIDTH/2 - 16)
    sta sprite_x
    lda #(SCREEN_HEIGHT/2 - 32)
    sta sprite_y

    jsr draw_sprite_32x32

    ; Draw title
    lda title_ptr
    sta zp_temp1
    lda title_ptr+1
    sta zp_temp1+1

    lda #(SCREEN_WIDTH/2 - 40)
    sta text_x
    lda #(SCREEN_HEIGHT/2 + 20)
    sta text_y
    lda #COLOR_PASTEL_GOLD
    sta text_color

    jsr draw_text

    ; Draw "ACHIEVEMENT UNLOCKED!"
    lda #<str_achievement_unlocked
    sta zp_temp1
    lda #>str_achievement_unlocked
    sta zp_temp1+1

    lda #(SCREEN_WIDTH/2 - 60)
    sta text_x
    lda #(SCREEN_HEIGHT/2 - 40)
    sta text_y
    lda #COLOR_PASTEL_CRIMSON
    sta text_color

    jsr draw_text

    ; Pulse effect
    lda notification_pulse
    beq @no_pulse

    ; Draw sparkle effect
    jsr draw_sparkle_effect

@no_pulse:
    rts

; ============================================
; ACHIEVEMENT TRACKING FUNCTIONS
; ============================================

track_kill:
    ; Increment kill counters
    inc kill_count
    lda kill_count
    cmp #1
    bne @not_first

    ; First kill achievement
    lda #ACH_FIRST_KILL
    ldx #1
    jsr inc_achievement_progress

@not_first:
    ; Combo tracking
    inc current_combo
    lda current_combo
    cmp combo_best
    bcc @check_combo_achievement
    sta combo_best

@check_combo_achievement:
    cmp #50
    bcc @track_enemy_type

    ; Combo master achievement
    lda #ACH_COMBO_MASTER
    ldx #1
    jsr inc_achievement_progress

@track_enemy_type:
    ; Track specific enemy kills
    lda last_killed_type
    cmp #ENEMY_SUCCUBUS
    bne @track_boss

    ; Succubus slayer
    inc succubus_kills

@track_boss:
    rts

track_boss_perfect:
    ; Called when boss defeated without taking damage
    lda #ACH_PERFECT_BOSS
    ldx #1
    jsr inc_achievement_progress
    rts

track_coin_insert:
    inc total_coins
    lda total_coins
    cmp #100
    bcc @done

    ; Coin hoarder achievement
    lda #ACH_COIN_HOARDER
    ldx #1
    jsr inc_achievement_progress

@done:
    rts

track_weapon_evolution:
    ; Weapon evolved
    lda #ACH_EVOLVED_WEAPON
    ldx #1
    jsr inc_achievement_progress
    rts

track_ecstasy_burst:
    ; Used ecstasy burst
    lda ecstasy_burst_count
    cmp #10
    bcc @done

    ; Ecstasy master achievement
    lda #ACH_ECSTASY_MASTER
    ldx #1
    jsr inc_achievement_progress

@done:
    rts

; ============================================
; ACHIEVEMENT GALLERY
; ============================================
show_achievement_gallery:
    ; Set up gallery mode
    lda #MODE_GALLERY
    sta zp_game_mode

    ; Calculate page
    lda #0
    sta gallery_page

    ; Draw gallery
    jsr draw_gallery

    rts

draw_gallery:
    ; Draw background
    lda #COLOR_PASTEL_EBONY
    jsr fill_screen

    ; Draw title
    lda #<str_gallery_title
    sta zp_temp1
    lda #>str_gallery_title
    sta zp_temp1+1

    lda #20
    sta text_x
    lda #10
    sta text_y
    lda #COLOR_PASTEL_GOLD
    sta text_color
    jsr draw_text

    ; Calculate achievements per page (8)
    lda gallery_page
    asl
    asl
    asl  ; *8
    sta zp_temp2  ; Starting achievement

    ; Draw 8 achievements
    lda #0
    sta zp_temp3  ; Counter

@gallery_loop:
    lda zp_temp3
    cmp #8
    beq @draw_page_info

    ; Calculate achievement ID
    clc
    adc zp_temp2
    cmp #32
    bcs @draw_page_info

    ; Check if unlocked
    tax
    lda achievement_unlocked,x
    beq @draw_locked

    ; Draw unlocked achievement
    txa
    jsr draw_gallery_achievement
    jmp @next

@draw_locked:
    ; Draw locked slot
    jsr draw_gallery_locked

@next:
    inc zp_temp3
    jmp @gallery_loop

@draw_page_info:
    ; Draw page number
    lda gallery_page
    clc
    adc #'1'
    sta page_number_str

    lda #<str_page
    sta zp_temp1
    lda #>str_page
    sta zp_temp1+1

    lda #SCREEN_WIDTH - 40
    sta text_x
    lda #SCREEN_HEIGHT - 10
    sta text_y
    lda #COLOR_PASTEL_CYAN
    sta text_color
    jsr draw_text

    rts

draw_gallery_achievement:
    ; Input: A = achievement ID
    pha
    phx
    phy

    ; Get achievement data
    jsr get_achievement_ptr
    sta zp_temp1
    sty zp_temp1+1

    ; Calculate position
    lda zp_temp3
    and #$03  ; 0-3
    asl
    asl
    asl
    asl
    asl      ; *32
    clc
    adc #16
    sta sprite_x

    lda zp_temp3
    lsr
    lsr      ; /4
    asl
    asl
    asl
    asl
    asl      ; *32
    clc
    adc #32
    sta sprite_y

    ; Draw badge
    ldy #5
    lda (zp_temp1),y
    sta badge_ptr
    iny
    lda (zp_temp1),y
    sta badge_ptr+1

    lda badge_ptr
    sta sprite_ptr
    lda badge_ptr+1
    sta sprite_ptr+1

    jsr draw_sprite_16x16

    ; Draw title
    ldy #3
    lda (zp_temp1),y
    sta title_ptr
    iny
    lda (zp_temp1),y
    sta title_ptr+1

    lda sprite_x
    clc
    adc #20
    sta text_x
    lda sprite_y
    clc
    adc #6
    sta text_y

    lda #COLOR_WHITE
    sta text_color

    jsr draw_text_short

    ply
    plx
    pla
    rts

; ============================================
; DATA
; ============================================
notification_achievement: .byte 0
notification_timer:      .byte 0
notification_pulse:      .byte 0
previous_game_mode:      .byte 0

achievement_unlocked:    .res 32
achievement_progress:    .res 64  ; 2 bytes each

; Tracking variables
kill_count:              .word 0
current_combo:           .byte 0
combo_best:              .byte 0
succubus_kills:          .byte 0
total_coins:             .word 0
ecstasy_burst_count:     .byte 0
last_killed_type:        .byte 0

; Gallery
gallery_page:            .byte 0

; Strings
str_achievement_unlocked:
    .byte "ACHIEVEMENT UNLOCKED!",0

str_gallery_title:
    .byte "ACHIEVEMENT GALLERY",0

str_page:
    .byte "PAGE "
page_number_str:
    .byte "1",0

str_title_first_play:
    .byte "First Dance",0
str_desc_first_play:
    .byte "Start your journey",0

str_title_first_kill:
    .byte "First Temptation",0
str_desc_first_kill:
    .byte "Defeat an enemy",0

str_title_no_miss:
    .byte "Untouched",0
str_desc_no_miss:
    .byte "Clear a zone without damage",0

str_title_combo_master:
    .byte "Chain of Ecstasy",0
str_desc_combo_master:
    .byte "50-kill combo",0

str_title_perfect_boss:
    .byte "Flawless Victory",0
str_desc_perfect_boss:
    .byte "Defeat 5 bosses perfectly",0

str_title_speedrunner:
    .byte "Temporal Dancer",0
str_desc_speedrunner:
    .byte "Complete game in <30min",0

str_title_crimson_master:
    .byte "Crimson Passion",0
str_desc_crimson_master:
    .byte "Unlock all crimson weapons",0

str_title_eternal_dancer:
    .byte "Eternal Rhythm",0
str_desc_eternal_dancer:
    .byte "Complete the secret chamber",0

; Achievement colors
achievement_colors:
    .byte COLOR_PASTEL_BRONZE
    .byte COLOR_PASTEL_SILVER
    .byte COLOR_PASTEL_GOLD
    .byte COLOR_PASTEL_PLATINUM
    .byte COLOR_PASTEL_CRIMSON

; Badge sprites would follow here...
