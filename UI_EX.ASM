; ============================================
; ENHANCED USER INTERFACE
; Ecstasy meter, badge display, sensual HUD
; ============================================
.include "gaudensex.inc"

.segment "BANK_UI"
.org $C000

; ============================================
; DRAW ENHANCED HUD
; ============================================
draw_hud_ex:
    ; Draw background bar
    lda #COLOR_PASTEL_EBONY
    jsr draw_hud_background

    ; Draw health
    jsr draw_health_bar

    ; Draw weapon
    jsr draw_weapon_display

    ; Draw score
    jsr draw_score

    ; Draw ecstasy meter
    jsr draw_ecstasy_meter

    ; Draw achievement badges
    jsr draw_active_badges

    ; Draw coin counter
    jsr draw_coin_counter

    rts

; ============================================
; E CSTASY METER
; ============================================
draw_ecstasy_meter:
    ; Position
    lda #140
    sta meter_x
    lda #5
    sta meter_y

    ; Background
    lda #COLOR_PASTEL_EBONY
    sta draw_color
    lda #32
    sta draw_width
    lda #6
    sta draw_height
    jsr draw_rect_filled

    ; Meter fill
    lda ecstasy_meter
    lsr
    lsr  ; /4 (0-25)
    sta meter_fill

    lda #COLOR_PASTEL_LAVENDER
    sta draw_color

    lda meter_fill
    beq @draw_outline
    sta draw_width

    lda #32
    sec
    sbc draw_width
    clc
    adc meter_x
    sta draw_x

    lda meter_y
    sta draw_y
    lda #6
    sta draw_height

    jsr draw_rect_filled

@draw_outline:
    ; Outline
    lda #COLOR_WHITE
    sta draw_color
    lda meter_x
    sta draw_x
    lda meter_y
    sta draw_y
    lda #32
    sta draw_width
    lda #6
    sta draw_height
    jsr draw_rect_outline

    ; "ECSTASY" text
    lda #<str_ecstasy
    sta text_ptr
    lda #>str_ecstasy
    sta text_ptr+1

    lda meter_x
    clc
    adc #2
    sta text_x
    lda meter_y
    sta text_y
    lda #COLOR_WHITE
    sta text_color

    jsr draw_text_small

    ; Flash when full
    lda ecstasy_meter
    cmp ecstasy_max
    bcc @done

    lda frame_counter
    and #$08
    beq @done

    ; Flash effect
    lda #COLOR_PASTEL_GOLD
    sta draw_color
    jsr draw_rect_outline

@done:
    rts

; ============================================
; WEAPON DISPLAY
; ============================================
draw_weapon_display:
    ; Background
    lda #5
    sta draw_x
    lda #5
    sta draw_y
    lda #40
    sta draw_width
    lda #20
    sta draw_height

    lda #COLOR_PASTEL_EBONY
    sta draw_color
    jsr draw_rect_filled

    ; Weapon icon
    lda current_weapon
    asl
    asl
    asl  ; *8
    clc
    adc #<weapon_icons
    sta sprite_ptr
    lda #>weapon_icons
    adc #0
    sta sprite_ptr+1

    lda #10
    sta sprite_x
    lda #8
    sta sprite_y

    jsr draw_sprite_16x16

    ; Weapon name
    lda current_weapon
    asl
    tax
    lda weapon_name_table,x
    sta text_ptr
    lda weapon_name_table+1,x
    sta text_ptr+1

    lda #30
    sta text_x
    lda #8
    sta text_y
    lda #COLOR_PASTEL_CYAN
    sta text_color

    jsr draw_text_small

    ; Weapon level
    lda weapon_level
    clc
    adc #'0'
    sta level_char

    lda #<str_level
    sta text_ptr
    lda #>str_level
    sta text_ptr+1

    lda #30
    sta text_x
    lda #16
    sta text_y
    lda #COLOR_PASTEL_GOLD
    sta text_color

    jsr draw_text_small

    rts

; ============================================
; ACHIEVEMENT BADGE DISPLAY
; ============================================
draw_active_badges:
    ; Show recently unlocked badges
    lda badge_display_timer
    beq @done

    ; Position
    lda #SCREEN_WIDTH - 40
    sta badge_x

    ; Draw up to 3 badges
    ldx #0
    ldy #0

@badge_loop:
    cpx #3
    beq @done

    lda recent_badges,x
    beq @next_badge

    ; Get badge sprite
    phx
    txa
    asl
    asl
    asl  ; *8 for offset
    clc
    adc #<badge_mini_sprites
    sta sprite_ptr
    lda #>badge_mini_sprites
    adc #0
    sta sprite_ptr+1

    lda badge_x
    sta sprite_x
    lda #5
    clc
    adc badge_y_offset,x
    sta sprite_y

    jsr draw_sprite_8x8

    plx

@next_badge:
    inx
    bra @badge_loop

@done:
    rts

badge_y_offset: .byte 0, 10, 20

; ============================================
; SENSUAL HEALTH BAR
; ============================================
draw_health_bar:
    ; Heart-based health display
    lda #5
    sta heart_x
    lda #SCREEN_HEIGHT - 15
    sta heart_y

    ldx #0
@heart_loop:
    cpx player_hp
    bcs @empty_heart

    ; Full heart
    lda #<heart_full_sprite
    sta sprite_ptr
    lda #>heart_full_sprite
    sta sprite_ptr+1
    bra @draw_heart

@empty_heart:
    ; Empty heart
    lda #<heart_empty_sprite
    sta sprite_ptr
    lda #>heart_empty_sprite
    sta sprite_ptr+1

@draw_heart:
    lda heart_x
    sta sprite_x
    lda heart_y
    sta sprite_y

    phx
    jsr draw_sprite_8x8
    plx

    ; Next heart
    lda heart_x
    clc
    adc #10
    sta heart_x

    inx
    cpx #PLAYER_MAX_HP
    bne @heart_loop

    ; Pulse effect when damaged
    lda player_invincible
    beq @done

    lda frame_counter
    and #$04
    beq @done

    ; Flash hearts
    lda #COLOR_PASTEL_CRIMSON
    sta flash_color
    jsr flash_hearts

@done:
    rts

; ============================================
; COIN COUNTER
; ============================================
draw_coin_counter:
    ; Draw coin icon
    lda #<coin_sprite
    sta sprite_ptr
    lda #>coin_sprite
    sta sprite_ptr+1

    lda #SCREEN_WIDTH - 50
    sta sprite_x
    lda #SCREEN_HEIGHT - 15
    sta sprite_y

    jsr draw_sprite_8x8

    ; Draw coin count
    lda coins
    jsr convert_bcd
    sta coin_bcd

    lda #<str_coin_count
    sta text_ptr
    lda #>str_coin_count
    sta text_ptr+1

    lda #SCREEN_WIDTH - 40
    sta text_x
    lda #SCREEN_HEIGHT - 14
    sta text_y
    lda #COLOR_PASTEL_GOLD
    sta text_color

    jsr draw_text_small

    rts

; ============================================
; TITLE SCREEN (Enhanced)
; ============================================
draw_title_screen:
    ; Animated background
    jsr draw_title_background

    ; Title logo
    lda #<title_logo
    sta sprite_ptr
    lda #>title_logo
    sta sprite_ptr+1

    lda #(SCREEN_WIDTH/2 - 64)
    sta sprite_x
    lda #20
    sta sprite_y

    jsr draw_sprite_128x32

    ; "INSERT COIN" animation
    lda frame_counter
    and #$1F
    cmp #$10
    bcs @coin_hidden

    ; Draw INSERT COIN
    lda #<str_insert_coin
    sta text_ptr
    lda #>str_insert_coin
    sta text_ptr+1

    lda #(SCREEN_WIDTH/2 - 40)
    sta text_x
    lda #70
    sta text_y
    lda #COLOR_PASTEL_GOLD
    sta text_color

    jsr draw_text

@coin_hidden:
    ; Draw coin count
    lda coins
    beq @no_coins

    lda #<str_coin_count_title
    sta text_ptr
    lda #>str_coin_count_title
    sta text_ptr+1

    lda #(SCREEN_WIDTH/2 - 30)
    sta text_x
    lda #80
    sta text_y
    lda #COLOR_PASTEL_CYAN
    sta text_color

    jsr draw_text

@no_coins:
    ; Animated particles
    jsr draw_title_particles

    ; Copyright
    lda #<str_copyright
    sta text_ptr
    lda #>str_copyright
    sta text_ptr+1

    lda #(SCREEN_WIDTH/2 - 60)
    sta text_x
    lda #SCREEN_HEIGHT - 10
    sta text_y
    lda #COLOR_PASTEL_LAVENDER
    sta text_color

    jsr draw_text_small

    rts

; ============================================
; DATA
; ============================================
str_ecstasy:    .byte "ECSTASY",0
str_level:      .byte "LV "
level_char:     .byte "0",0
str_coin_count: .byte "X"
coin_bcd:       .byte "00",0
str_insert_coin: .byte "INSERT COIN",0
str_coin_count_title: .byte "COINS: "
coins_bcd_title: .byte "00",0
str_copyright:  .byte "(C) 2024 GAUDENS MACHINA EX",0

; Heart sprites
heart_full_sprite:
.byte %00111100
.byte %01111110
.byte %11111111
.byte %11111111
.byte %11111111
.byte %01111110
.byte %00111100
.byte %00000000

heart_empty_sprite:
.byte %00111100
.byte %01000010
.byte %10000001
.byte %10000001
.byte %10000001
.byte %01000010
.byte %00111100
.byte %00000000

coin_sprite:
.byte %00111100
.byte %01111110
.byte %11111111
.byte %11111111
.byte %11111111
.byte %01111110
.byte %00111100
.byte %00000000

; Weapon icons (16x16 each)
weapon_icons:
; Basic
.byte %00000000, %00011000, %00000000
.byte %00000000, %00111100, %00000000
.byte %00000000, %01111110, %00000000
; ... etc for all weapons

; Recent badges
recent_badges: .res 3
badge_display_timer: .byte 0

; UI positions
meter_x: .byte 0
meter_y: .byte 0
meter_fill: .byte 0
heart_x: .byte 0
heart_y: .byte 0
badge_x: .byte 0
