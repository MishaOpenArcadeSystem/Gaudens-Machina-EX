; ============================================
; GAUDENS MACHINA EX - Constants & Macros
; ============================================

; Hardware addresses
VGA_BASE        = $C000
VGA_CONTROL     = $C800
VGA_PALETTE     = $CC00

SOUND_BASE      = $B000
SOUND_CONTROL   = $B100
SOUND_CH1       = $B000
SOUND_CH2       = $B001
SOUND_CH3       = $B002
SOUND_CH4       = $B003
SOUND_CH5       = $B004  ; EX: Extra channels
SOUND_CH6       = $B005

JOYSTICK_PORT   = $A000
JOYSTICK_BUTTONS = $A001
JOYSTICK_DDR    = $A002

BANK_SELECT     = $9000
SAVE_CONTROL    = $9100
SAVE_RAM        = $6000  ; Battery-backed

IRQ_CONTROL     = $9200
IRQ_ACK         = $01

; Game modes
MODE_TITLE      = 0
MODE_PLAYING    = 1
MODE_BOSS       = 2
MODE_SHOP       = 3
MODE_ACHIEVEMENT = 4
MODE_ENDING     = 5
MODE_CREDITS    = 6

; Banks
BANK_GAME       = 0
BANK_GRAPHICS   = 1
BANK_MUSIC      = 2
BANK_LEVELS     = 3
BANK_BOSS       = 4
BANK_UI         = 5

; Button masks
BUTTON_UP       = %00000001
BUTTON_DOWN     = %00000010
BUTTON_LEFT     = %00000100
BUTTON_RIGHT    = %00001000
BUTTON_A        = %00010000  ; Fire
BUTTON_B        = %00100000  ; Bomb/Ability
BUTTON_START    = %01000000
BUTTON_COIN     = %10000000

; Zone IDs
ZONE_GARDEN     = 0  ; Garden of Innocence
ZONE_CHAMBER    = 1  ; Chamber of Whispers
ZONE_MIRRORS    = 2  ; Hall of Mirrors
ZONE_ALTAR      = 3  ; Altar of Desire
ZONE_NEXUS      = 4  ; Nexus of Ecstasy
ZONE_SANCTUM    = 5  ; Sanctum of Secrets
ZONE_THRONE     = 6  ; Throne of Pride
ZONE_DAWN       = 7  ; Epilogue: Dawn
ZONE_ETERNAL    = 8  ; Secret: Chamber of Eternal Dance
ZONE_COUNT      = 9

; Boss IDs
BOSS_LUST       = 0  ; Seraphina
BOSS_GLUTTONY   = 1  ; Voracius
BOSS_PRIDE      = 2  ; Aurelius
BOSS_ENVY       = 3  ; Invidia
BOSS_WRATH      = 4  ; Iracundia
BOSS_SLOTH      = 5  ; Acedia
BOSS_GREED      = 6  ; Avaritia
BOSS_ARCHON     = 7  ; The Grand Archon
BOSS_ETERNAL    = 8  ; The Composer

; Achievement IDs (0-31)
ACH_FIRST_PLAY      = 0
ACH_FIRST_KILL      = 1
ACH_NO_MISS         = 2
ACH_COMBO_MASTER    = 3
ACH_PERFECT_BOSS    = 4
ACH_SPEEDRUNNER     = 5
ACH_CRIMSON_MASTER  = 6
ACH_ETERNAL_DANCER  = 7
ACH_PASTEL_COLLECTOR = 8
ACH_ECSTASY_MASTER  = 9
ACH_HEART_UNBROKEN  = 10
ACH_UNTOUCHED       = 11
ACH_PERFECT_SYMPHONY = 12
ACH_EGO_DEATH       = 13
ACH_EVOLVED_WEAPON  = 14
ACH_SINFUL_COMPLETE = 15
ACH_NEO_SEXCELLENT  = 16
ACH_ARCADE_MASTER   = 17
ACH_COIN_HOARDER    = 18
ACH_BADGE_COLLECTOR = 19
ACH_SECRET_DANCER   = 20
ACH_CHROMATIC_SAGE  = 21
ACH_TEMPTATION_LORD = 22
ACH_SERAPH_SLAYER   = 23
ACH_ARCHON_BANISHER = 24
ACH_ETERNAL_ECSTASY = 25
ACH_PURE_PERFECTION = 26
ACH_NEO_LEGEND      = 27
ACH_TRUE_ENDING     = 28
ACH_ALL_ACHIEVEMENTS = 29
ACH_GAUDENS_GOD     = 30
ACH_ULTIMATE_SIN    = 31  ; Secret ultimate

; Weapon IDs
WEAPON_BASIC    = 0  ; Default shot
WEAPON_SPREAD   = 1  ; 3-way spread
WEAPON_LASER    = 2  ; Piercing laser
WEAPON_RAPID    = 3  ; Rapid fire
WEAPON_WHIP     = 4  ; Curving shots
WEAPON_CHAIN    = 5  ; Chaining lightning
WEAPON_KISS     = 6  ; Heart missiles
WEAPON_ECLIPSE  = 7  ; Black holes
WEAPON_SYMPHONY = 8  ; Musical notes
WEAPON_ECSTASY  = 9  ; Ultimate weapon

; Enemy types
ENEMY_BIGHEAD   = 0  ; Classic
ENEMY_TOASTER   = 1  ; Classic
ENEMY_SUCCUBUS  = 2  ; EX: Curvy drone
ENEMY_INCUBUS   = 3  ; EX: Angular fighter
ENEMY_SIREN     = 4  ; EX: Singer
ENEMY_HARPY     = 5  ; EX: Swarm
ENEMY_TEMPTER   = 6  ; EX: Slow but tough
ENEMY_SEDUCER   = 7  ; EX: Fast, evasive
ENEMY_VOYEUR    = 8  ; EX: Spawns copies
ENEMY_ECSTATIC  = 9  ; EX: Death explosion

; Power-up types
POWERUP_SPREAD  = 0
POWERUP_LASER   = 1
POWERUP_RAPID   = 2
POWERUP_SHIELD  = 3
POWERUP_BOMB    = 4
POWERUP_LIFE    = 5
POWERUP_ECSTASY = 6  ; EX: Fills ecstasy meter
POWERUP_TRANSFORM = 7  ; EX: Weapon evolution

; Colors (8-bit RGB, 3-3-2)
COLOR_BLACK         = %00000000
COLOR_PASTEL_PINK   = %11101110
COLOR_PASTEL_BLUE   = %10111111
COLOR_PASTEL_YELLOW = %11111010
COLOR_PASTEL_GREEN  = %10111010
COLOR_PASTEL_PURPLE = %11010111
COLOR_PASTEL_CYAN   = %01111110
COLOR_PASTEL_CRIMSON = %11100011  ; EX
COLOR_PASTEL_LAVENDER = %11010111 ; EX
COLOR_PASTEL_GOLD   = %11111010   ; EX
COLOR_PASTEL_TEAL   = %00111110   ; EX
COLOR_PASTEL_CHAMPAGNE = %11111101 ; EX
COLOR_PASTEL_EBONY  = %00010001   ; EX
COLOR_PASTEL_ROSE   = %11101110   ; EX
COLOR_PASTEL_SAPPHIRE = %01001111 ; EX
COLOR_WHITE        = %11111111

; Screen dimensions
SCREEN_WIDTH    = 160
SCREEN_HEIGHT   = 100
BUFFER_SIZE     = SCREEN_WIDTH * SCREEN_HEIGHT / 4

; Limits
MAX_ENEMIES     = 24    ; Increased from 16
MAX_BULLETS     = 64    ; Increased from 32
MAX_POWERUPS    = 12    ; Increased from 8
MAX_PARTICLES   = 48    ; New: Particle system
MAX_EFFECTS     = 16    ; New: Visual effects

; Player constants
PLAYER_START_X  = 32
PLAYER_START_Y  = 50
PLAYER_MAX_HP   = 5
PLAYER_SPEED    = 2
PLAYER_ECSTASY_MAX = 100

; Boss constants
BOSS_PHASE_COUNT = 3
BOSS_PATTERN_COUNT = 8

; Sound IDs
SOUND_SHOOT     = 0
SOUND_EXPLODE   = 1
SOUND_POWERUP   = 2
SOUND_HIT       = 3
SOUND_COIN      = 4
SOUND_ECSTASY   = 5
SOUND_TRANSFORM = 6
SOUND_ACHIEVEMENT = 7
SOUND_BOSS_HIT  = 8
SOUND_BOSS_DEATH = 9
SOUND_MENU      = 10

; Music IDs
MUSIC_TITLE     = 0
MUSIC_ZONE1     = 1
MUSIC_ZONE2     = 2
MUSIC_ZONE3     = 3
MUSIC_ZONE4     = 4
MUSIC_ZONE5     = 5
MUSIC_ZONE6     = 6
MUSIC_ZONE7     = 7
MUSIC_ZONE8     = 8
MUSIC_BOSS      = 9
MUSIC_BOSS_FINAL = 10
MUSIC_SHOP      = 11
MUSIC_ENDING    = 12
MUSIC_ETERNAL   = 13
MUSIC_CREDITS   = 14

; Achievement types
ACH_TYPE_BRONZE   = 0
ACH_TYPE_SILVER   = 1
ACH_TYPE_GOLD     = 2
ACH_TYPE_PLATINUM = 3
ACH_TYPE_SECRET   = 4

; Macros
.macro BANK_SWITCH bank
    lda #bank
    sta BANK_SELECT
.endmacro

.macro ADD_SCORE value
    ; Add 24-bit value to score
    clc
    lda score
    adc #<value
    sta score
    lda score+1
    adc #>value
    sta score+1
    lda score+2
    adc #0
    sta score+2
.endmacro

.macro DRAW_SPRITE id, x, y
    ; Queue sprite for drawing
    lda #id
    sta sprite_queue_id
    lda x
    sta sprite_queue_x
    lda y
    sta sprite_queue_y
    jsr queue_sprite
.endmacro

.macro PARTICLE_EFFECT type, x, y, color, count
    ; Create particle effect
    lda #type
    sta particle_type
    lda x
    sta particle_x
    lda y
    sta particle_y
    lda color
    sta particle_color
    lda count
    sta particle_count
    jsr create_particles
.endmacro

.macro CHECK_ACHIEVEMENT id
    ; Check and unlock achievement
    lda #id
    jsr check_achievement
.endmacro

.macro PLAY_SOUND id
    ; Play sound effect
    lda #id
    jsr play_sound
.endmacro

; Achievement structure (5 bytes each)
.struct Achievement
    id      .byte
    type    .byte
    progress_max .word
    unlocked .byte
.endstruct

; Enemy structure
.struct Enemy
    active  .byte
    x       .word
    y       .byte
    type    .byte
    hp      .byte
    pattern .byte
    timer   .byte
    data    .byte  ; Extra data
.endstruct

; Boss phase structure
.struct BossPhase
    hp      .word
    pattern .byte
    sprite  .word
    music   .byte
    attack  .byte
.endstruct
