; ============================================
; SENSUAL PARTICLE SYSTEM
; Heart, ribbon, glitter effects
; ============================================
.include "gaudensex.inc"

.segment "BANK_GAME"
.org $A000

; ============================================
; PARTICLE STRUCTURE (8 bytes each)
; ============================================
.struct Particle
    active  .byte
    type    .byte
    x       .word
    y       .byte
    vx      .byte
    vy      .byte
    life    .byte
    color   .byte
    data    .byte  ; Extra data
.endstruct

; Particle array (48 particles)
particles: .res 48 * .sizeof(Particle)

; ============================================
; INITIALIZE PARTICLE SYSTEM
; ============================================
init_particles:
    ldx #0
    lda #0
@clear_loop:
    sta particles + Particle::active,x
    txa
    clc
    adc #.sizeof(Particle)
    tax
    cmp #48 * .sizeof(Particle)
    bne @clear_loop
    rts

; ============================================
; CREATE PARTICLE EFFECT
; ============================================
; Input: A = type, X = x, Y = y, color in temp
create_particle_effect:
    sta effect_type
    stx effect_x
    sty effect_y

    ; Different effects based on type
    lda effect_type
    asl
    tax
    lda effect_table,x
    sta zp_temp1
    lda effect_table+1,x
    sta zp_temp1+1

    jmp (zp_temp1)

effect_table:
    .word effect_heart_explosion
    .word effect_ribbon_trail
    .word effect_glitter_burst
    .word effect_confetti_rain
    .word effect_kiss_trail
    .word effect_ecstasy_burst

; ============================================
; HEART EXPLOSION (Succubus death)
; ============================================
effect_heart_explosion:
    ; Create 12 heart particles
    lda #12
    sta particle_count

    ldx #0
@create_heart:
    txa
    pha

    ; Find free particle
    jsr find_free_particle
    bcs @no_free

    ; Initialize heart particle
    lda #PARTICLE_HEART
    sta particles + Particle::type,y

    ; Position at effect center
    lda effect_x
    sta particles + Particle::x,y
    lda effect_x+1
    sta particles + Particle::x+1,y
    lda effect_y
    sta particles + Particle::y,y

    ; Random velocity (outward)
    jsr random
    and #$0F
    sec
    sbc #$08
    sta particles + Particle::vx,y

    jsr random
    and #$0F
    sec
    sbc #$08
    sta particles + Particle::vy,y

    ; Life (30-60 frames)
    jsr random
    and #$1F
    clc
    adc #30
    sta particles + Particle::life,y

    ; Color: Crimson to Pink gradient
    txa
    and #$03
    tax
    lda heart_colors,x
    sta particles + Particle::color,y

    ; Heart animation frame
    lda #0
    sta particles + Particle::data,y

@no_free:
    pla
    tax
    inx
    cpx particle_count
    bne @create_heart

    rts

heart_colors:
    .byte COLOR_PASTEL_CRIMSON
    .byte COLOR_PASTEL_ROSE
    .byte COLOR_PASTEL_PINK
    .byte COLOR_PASTEL_LAVENDER

; ============================================
; RIBBON TRAIL (Player movement)
; ============================================
effect_ribbon_trail:
    ; Create trailing ribbon particles
    lda player_moving
    beq @done

    ; Only every 4 frames
    lda frame_counter
    and #$03
    bne @done

    ; Find free particle
    jsr find_free_particle
    bcs @done

    ; Ribbon particle
    lda #PARTICLE_RIBBON
    sta particles + Particle::type,y

    ; Position behind player
    lda player_x
    sec
    sbc #8
    sta particles + Particle::x,y
    lda player_x+1
    sbc #0
    sta particles + Particle::x+1,y

    lda player_y
    clc
    adc #4
    sta particles + Particle::y,y

    ; Slow downward velocity
    lda #0
    sta particles + Particle::vx,y
    lda #1
    sta particles + Particle::vy,y

    ; Long life
    lda #90
    sta particles + Particle::life,y

    ; Color based on weapon
    lda player_weapon
    tax
    lda weapon_colors,x
    sta particles + Particle::color,y

    ; Ribbon length
    lda #8
    sta particles + Particle::data,y

@done:
    rts

; ============================================
; GLITTER BURST (Power-up collection)
; ============================================
effect_glitter_burst:
    lda #16
    sta particle_count

    ldx #0
@create_glitter:
    txa
    pha

    jsr find_free_particle
    bcs @no_glitter

    lda #PARTICLE_GLITTER
    sta particles + Particle::type,y

    lda effect_x
    sta particles + Particle::x,y
    lda effect_x+1
    sta particles + Particle::x+1,y
    lda effect_y
    sta particles + Particle::y,y

    ; Fast random velocities
    jsr random
    and #$07
    sec
    sbc #$04
    sta particles + Particle::vx,y

    jsr random
    and #$07
    sec
    sbc #$04
    sta particles + Particle::vy,y

    ; Short life
    jsr random
    and #$0F
    clc
    adc #10
    sta particles + Particle::life,y

    ; Golden color
    lda #COLOR_PASTEL_GOLD
    sta particles + Particle::color,y

    ; Twinkle speed
    jsr random
    and #$03
    sta particles + Particle::data,y

@no_glitter:
    pla
    tax
    inx
    cpx particle_count
    bne @create_glitter

    rts

; ============================================
; UPDATE ALL PARTICLES
; ============================================
update_particles:
    ldx #0
    ldy #0  ; Particle index

@particle_loop:
    lda particles + Particle::active,y
    beq @next_particle

    ; Update position
    lda particles + Particle::x,y
    clc
    adc particles + Particle::vx,y
    sta particles + Particle::x,y
    lda particles + Particle::x+1,y
    adc #0
    sta particles + Particle::x+1,y

    lda particles + Particle::y,y
    clc
    adc particles + Particle::vy,y
    sta particles + Particle::y,y

    ; Apply gravity to some types
    lda particles + Particle::type,y
    cmp #PARTICLE_RIBBON
    beq @apply_gravity
    cmp #PARTICLE_CONFETTI
    beq @apply_gravity
    bra @no_gravity

@apply_gravity:
    inc particles + Particle::vy,y

@no_gravity:
    ; Decrease life
    dec particles + Particle::life,y
    bne @next_particle

    ; Particle died
    lda #0
    sta particles + Particle::active,y

@next_particle:
    ; Next particle
    tya
    clc
    adc #.sizeof(Particle)
    tay

    inx
    cpx #MAX_PARTICLES
    bne @particle_loop

    rts

; ============================================
; DRAW PARTICLES
; ============================================
draw_particles:
    ldx #0
    ldy #0

@draw_loop:
    lda particles + Particle::active,y
    beq @next_draw

    ; Check if on screen
    lda particles + Particle::x+1,y
    cmp scroll_x+1
    bne @next_draw

    lda particles + Particle::x,y
    sec
    sbc scroll_x
    bmi @next_draw
    cmp #SCREEN_WIDTH
    bcs @next_draw

    sta draw_x

    lda particles + Particle::y,y
    cmp #SCREEN_HEIGHT
    bcs @next_draw

    sta draw_y

    ; Draw based on type
    lda particles + Particle::type,y
    asl
    tax
    lda draw_table,x
    sta zp_temp1
    lda draw_table+1,x
    sta zp_temp1+1

    ; Set color
    lda particles + Particle::color,y
    sta draw_color

    ; Call draw function
    phy
    jsr call_draw
    ply

@next_draw:
    ; Next particle
    tya
    clc
    adc #.sizeof(Particle)
    tay

    ldx #0
    cpy #MAX_PARTICLES * .sizeof(Particle)
    bne @draw_loop

    rts

call_draw:
    jmp (zp_temp1)

draw_table:
    .word draw_heart
    .word draw_ribbon
    .word draw_glitter
    .word draw_confetti
    .word draw_kiss

; ============================================
; DRAW HEART PARTICLE
; ============================================
draw_heart:
    ; Animated heart
    lda particles + Particle::data,y
    lsr
    lsr  ; Frame = data/4
    and #$03
    asl
    asl
    asl  ; *8 for sprite offset

    clc
    adc #<heart_sprites
    sta sprite_ptr
    lda #>heart_sprites
    adc #0
    sta sprite_ptr+1

    lda draw_x
    sta sprite_x
    lda draw_y
    sta sprite_y

    jsr draw_sprite_8x8

    ; Update animation
    inc particles + Particle::data,y

    rts

heart_sprites:
; Frame 0 - Small
.byte %00111100
.byte %01111110
.byte %11111111
.byte %11111111
.byte %11111111
.byte %01111110
.byte %00111100
.byte %00000000

; Frame 1 - Medium
.byte %00111100
.byte %01111110
.byte %11111111
.byte %11111111
.byte %11111111
.byte %01111110
.byte %00111100
.byte %00011000

; Frame 2 - Large
.byte %00011000
.byte %00111100
.byte %01111110
.byte %11111111
.byte %11111111
.byte %01111110
.byte %00111100
.byte %00011000

; Frame 3 - Medium
.byte %00111100
.byte %01111110
.byte %11111111
.byte %11111111
.byte %11111111
.byte %01111110
.byte %00111100
.byte %00000000

; ============================================
; DRAW RIBBON PARTICLE
; ============================================
draw_ribbon:
    ; Ribbon is a vertical line that fades
    lda particles + Particle::life,y
    lsr
    lsr  ; Life/4 = alpha
    sta ribbon_alpha

    lda draw_color
    jsr set_color_transparent

    ; Draw vertical line
    lda draw_x
    sta line_x
    lda draw_y
    sta line_y1

    lda particles + Particle::data,y  ; Length
    clc
    adc draw_y
    sta line_y2

    jsr draw_line

    rts

; ============================================
; FIND FREE PARTICLE SLOT
; ============================================
find_free_particle:
    ldy #0
@search_loop:
    lda particles + Particle::active,y
    beq @found

    tya
    clc
    adc #.sizeof(Particle)
    tay

    cpy #MAX_PARTICLES * .sizeof(Particle)
    bne @search_loop

    sec  ; Not found
    rts

@found:
    lda #1
    sta particles + Particle::active,y
    clc  ; Found
    rts

; ============================================
; PARTICLE TYPES
; ============================================
PARTICLE_HEART    = 0
PARTICLE_RIBBON   = 1
PARTICLE_GLITTER  = 2
PARTICLE_CONFETTI = 3
PARTICLE_KISS     = 4
PARTICLE_ECSTASY  = 5

; Color table for weapons
weapon_colors:
    .byte COLOR_PASTEL_BLUE     ; Basic
    .byte COLOR_PASTEL_GREEN    ; Spread
    .byte COLOR_PASTEL_CYAN     ; Laser
    .byte COLOR_PASTEL_YELLOW   ; Rapid
    .byte COLOR_PASTEL_PURPLE   ; Whip
    .byte COLOR_PASTEL_CRIMSON  ; Chain
    .byte COLOR_PASTEL_ROSE     ; Kiss
    .byte COLOR_PASTEL_EBONY    ; Eclipse
    .byte COLOR_PASTEL_GOLD     ; Symphony
    .byte COLOR_PASTEL_LAVENDER ; Ecstasy
