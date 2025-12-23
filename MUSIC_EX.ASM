; ============================================
; NEO DEEP HOUSE MUSIC ENGINE
; 6-channel tracker with effects
; ============================================
.include "gaudensex.inc"

.segment "BANK_MUSIC"
.org $8000

; ============================================
; MUSIC ENGINE STATE
; ============================================
music_state:
music_playing:      .byte 0
music_track:        .byte 0
music_position:     .byte 0
music_tempo:        .byte 0
music_timer:        .byte 0
music_speed:        .byte 0
music_pattern:      .byte 0
music_row:          .byte 0

; Channel states (6 channels)
channel_note:       .res 6
channel_instrument: .res 6
channel_volume:     .res 6
channel_effect:     .res 6
channel_param:      .res 6

; Instruments (16 instruments)
instruments:        .res 16 * 8  ; 8 bytes each

; Pattern data
pattern_ptr:        .word 0
pattern_length:     .byte 0

; ============================================
; INITIALIZE MUSIC ENGINE
; ============================================
init_music:
    ; Reset state
    lda #0
    sta music_playing
    sta music_position

    ; Default tempo (125 BPM)
    lda #125
    sta music_tempo

    ; Default speed (6 ticks/row)
    lda #6
    sta music_speed

    ; Initialize instruments
    jsr init_instruments

    ; Initialize sound chip
    lda #$9F  ; Channel 1 volume max
    sta SOUND_CH1+3
    lda #$BF  ; Channel 2
    sta SOUND_CH2+3
    lda #$DF  ; Channel 3
    sta SOUND_CH3+3
    lda #$FF  ; Channel 4 (noise)
    sta SOUND_CH4+3
    lda #$FF  ; Channel 5 (extra)
    sta SOUND_CH5+3
    lda #$FF  ; Channel 6 (extra)
    sta SOUND_CH6+3

    rts

; ============================================
; PLAY MUSIC
; ============================================
; Input: A = track ID
play_music:
    pha
    phx
    phy

    ; Stop current music
    jsr stop_music

    ; Set track
    sta music_track

    ; Load track data
    asl
    tax
    lda track_table,x
    sta zp_temp1
    lda track_table+1,x
    sta zp_temp1+1

    ; Initialize track
    ldy #0
    lda (zp_temp1),y    ; Speed
    sta music_speed
    iny
    lda (zp_temp1),y    ; Pattern count
    sta pattern_count
    iny

    ; Pattern pointer table
    lda (zp_temp1),y
    sta pattern_table
    iny
    lda (zp_temp1),y
    sta pattern_table+1

    ; Start at pattern 0, row 0
    lda #0
    sta music_pattern
    sta music_row
    sta music_timer

    ; Play
    lda #1
    sta music_playing

    ; Start playback timer
    lda music_speed
    sta music_timer

    ply
    plx
    pla
    rts

; ============================================
; UPDATE MUSIC (Called each frame)
; ============================================
update_music:
    lda music_playing
    bne @music_active
    rts

@music_active:
    ; Decrement timer
    dec music_timer
    bne @no_row

    ; Reset timer
    lda music_speed
    sta music_timer

    ; Process row
    jsr process_music_row

    ; Next row
    inc music_row
    lda music_row
    cmp #64  ; Rows per pattern
    bcc @no_pattern

    ; Next pattern
    lda #0
    sta music_row
    inc music_pattern

    ; Check pattern count
    lda music_pattern
    cmp pattern_count
    bcc @no_pattern

    ; Loop track
    lda #0
    sta music_pattern

@no_pattern:
@no_row:
    ; Update channel effects
    jsr update_effects

    rts

; ============================================
; PROCESS MUSIC ROW
; ============================================
process_music_row:
    ; Get pattern data pointer
    lda music_pattern
    asl
    tay
    lda (pattern_table),y
    sta pattern_ptr
    iny
    lda (pattern_table),y
    sta pattern_ptr+1

    ; Calculate row offset (64 rows * 6 channels * 4 bytes)
    lda music_row
    sta zp_temp2

    ; Multiply by 24 (6*4)
    asl  ; *2
    asl  ; *4
    asl  ; *8
    sta zp_temp3
    asl  ; *16
    clc
    adc zp_temp3  ; *24

    ; Add to pattern pointer
    clc
    adc pattern_ptr
    sta zp_temp1
    lda pattern_ptr+1
    adc #0
    sta zp_temp1+1

    ; Process 6 channels
    ldx #0
@channel_loop:
    txa
    asl
    asl  ; *4 per channel
    tay

    ; Note
    lda (zp_temp1),y
    cmp #NOTE_OFF
    beq @note_off

    cmp #NOTE_NONE
    beq @no_note_change

    ; Play note
    sta channel_note,x
    jsr play_channel_note
    jmp @process_volume

@note_off:
    ; Stop note
    lda #0
    sta channel_volume,x
    jmp @process_instrument

@no_note_change:
@process_volume:
    ; Volume
    iny
    lda (zp_temp1),y
    cmp #$FF
    beq @no_volume_change
    sta channel_volume,x

@no_volume_change:
@process_instrument:
    ; Instrument
    iny
    lda (zp_temp1),y
    cmp #$FF
    beq @no_instrument_change
    sta channel_instrument,x

@no_instrument_change:
@process_effect:
    ; Effect
    iny
    lda (zp_temp1),y
    sta channel_effect,x
    iny
    lda (zp_temp1),y
    sta channel_param,x

    ; Next channel
    inx
    cpx #6
    bne @channel_loop

    rts

; ============================================
; PLAY CHANNEL NOTE
; ============================================
; Input: X = channel, channel_note[x] = note
play_channel_note:
    ; Get note frequency
    lda channel_note,x
    asl
    tay

    ; Get instrument
    lda channel_instrument,x
    asl
    asl
    asl  ; *8
    sta zp_temp2

    ; Apply instrument to frequency
    lda note_freq_table,y
    clc
    adc zp_temp2
    sta freq_low

    lda note_freq_table+1,y
    adc #0
    sta freq_high

    ; Set frequency on sound chip
    txa
    asl
    tay

    lda freq_low
    sta SOUND_BASE,y
    lda freq_high
    sta SOUND_BASE+1,y

    ; Set volume
    lda channel_volume,x
    ora #$90  ; Volume + enable
    sta SOUND_BASE+3,y

    rts

; ============================================
; UPDATE EFFECTS
; ============================================
update_effects:
    ldx #0
@effect_loop:
    lda channel_effect,x
    beq @next_channel

    ; Process effect
    asl
    tay
    lda effect_table,y
    sta zp_temp1
    lda effect_table+1,y
    sta zp_temp1+1

    ; Call effect handler
    txa
    pha
    jsr call_effect
    pla
    tax

@next_channel:
    inx
    cpx #6
    bne @effect_loop

    rts

call_effect:
    jmp (zp_temp1)

; ============================================
; EFFECT HANDLERS
; ============================================
effect_arpeggio:
    ; Channel in X, param in channel_param[x]
    lda effect_timer
    and #$03
    beq @change_note

    rts

@change_note:
    lda channel_param,x
    and #$0f
    tay
    lda arpeggio_notes,y
    clc
    adc channel_note,x
    jsr set_channel_note

    rts

effect_slide_up:
    ; Slide note up
    lda channel_note,x
    clc
    adc channel_param,x
    jsr set_channel_note
    rts

effect_vibrato:
    ; Vibrato effect
    lda effect_timer
    and #$07
    tay
    lda sine_table,y
    lsr
    lsr
    lsr
    clc
    adc channel_note,x
    jsr set_channel_note
    rts

effect_filter_sweep:
    ; Filter sweep (channel 6 only)
    cpx #5
    bne @done

    lda channel_param,x
    sta SOUND_CH6+2

@done:
    rts

; ============================================
; DEEP HOUSE TRACK: "CRIMSON DESIRE"
; ============================================
track_crimson_desire:
    .byte 6          ; Speed (6 = 125 BPM)
    .byte 4          ; Pattern count

    ; Pattern pointers
    .word pattern_crimson_0
    .word pattern_crimson_1
    .word pattern_crimson_2
    .word pattern_crimson_3

; Pattern 0: Intro
pattern_crimson_0:
; Ch1: Bass (808-style)
.byte C2, VOL_MAX, INST_BASS_808, EFX_NONE, 0
.byte 0,  VOL_MAX, 0,           EFX_NONE, 0
.byte 0,  VOL_MAX, 0,           EFX_NONE, 0
.byte 0,  VOL_MAX, 0,           EFX_NONE, 0
.byte G2, VOL_MAX, INST_BASS_808, EFX_NONE, 0
.byte 0,  VOL_MAX, 0,           EFX_NONE, 0
.byte 0,  VOL_MAX, 0,           EFX_NONE, 0
.byte 0,  VOL_MAX, 0,           EFX_NONE, 0

; Ch2: Rhodes chords
.byte 0,  VOL_OFF, 0,           EFX_NONE, 0
.byte C4, VOL_HALF, INST_RHODES, EFX_VIBRATO, $04
.byte 0,  VOL_HALF, 0,          EFX_NONE, 0
.byte 0,  VOL_HALF, 0,          EFX_NONE, 0
.byte 0,  VOL_OFF, 0,           EFX_NONE, 0
.byte G4, VOL_HALF, INST_RHODES, EFX_VIBRATO, $04
.byte 0,  VOL_HALF, 0,          EFX_NONE, 0
.byte 0,  VOL_HALF, 0,          EFX_NONE, 0

; Ch3: Pluck arpeggio
.byte C5, VOL_MAX, INST_PLUCK,  EFX_ARPEGGIO, $12
.byte E5, VOL_MAX, INST_PLUCK,  EFX_ARPEGGIO, $12
.byte G5, VOL_MAX, INST_PLUCK,  EFX_ARPEGGIO, $12
.byte C6, VOL_MAX, INST_PLUCK,  EFX_ARPEGGIO, $12
.byte G5, VOL_MAX, INST_PLUCK,  EFX_ARPEGGIO, $12
.byte E5, VOL_MAX, INST_PLUCK,  EFX_ARPEGGIO, $12
.byte C5, VOL_MAX, INST_PLUCK,  EFX_ARPEGGIO, $12
.byte 0,  VOL_OFF, 0,           EFX_NONE, 0

; Ch4: Drums
.byte KICK, VOL_MAX, INST_KICK, EFX_NONE, 0
.byte HIHAT,VOL_HALF,INST_HIHAT,EFX_NONE, 0
.byte SNARE,VOL_MAX, INST_SNARE,EFX_NONE, 0
.byte HIHAT,VOL_HALF,INST_HIHAT,EFX_NONE, 0
.byte KICK, VOL_MAX, INST_KICK, EFX_NONE, 0
.byte HIHAT,VOL_HALF,INST_HIHAT,EFX_NONE, 0
.byte SNARE,VOL_MAX, INST_SNARE,EFX_NONE, 0
.byte HIHAT,VOL_HALF,INST_HIHAT,EFX_NONE, 0

; Ch5: Pad (enters later)
.byte 0,  VOL_OFF, 0,           EFX_NONE, 0
; ... 64 rows total

; ============================================
; DYNAMIC MUSIC SYSTEM
; ============================================
update_dynamic_music:
    ; React to gameplay

    ; Intensity based on enemy count
    lda enemy_count
    sta music_intensity

    ; Change arrangement based on intensity
    lda music_intensity
    cmp #15
    bcs @high_intensity
    cmp #5
    bcs @medium_intensity

    ; Low intensity
    lda #ARRANGEMENT_MINIMAL
    sta current_arrangement
    bra @check_player

@medium_intensity:
    lda #ARRANGEMENT_NORMAL
    sta current_arrangement
    bra @check_player

@high_intensity:
    lda #ARRANGEMENT_INTENSE
    sta current_arrangement

@check_player:
    ; Check player health
    lda player_hp
    cmp #2
    bcs @check_ecstasy

    ; Low health - add tension
    lda channel_volume+5  ; Channel 6
    cmp #VOL_HALF
    bcs @set_tension

    lda #VOL_HALF
    sta channel_volume+5
    lda #INST_TENSION
    sta channel_instrument+5
    lda #NOTE_A3
    sta channel_note+5

@set_tension:
@check_ecstasy:
    ; Ecstasy meter affects filter
    lda player_ecstasy
    lsr
    lsr  ; /4
    sta filter_cutoff
    lda filter_cutoff
    ora #$80  ; Enable filter
    sta SOUND_CH6+2

    ; Boss phase changes
    lda boss_active
    beq @done

    lda boss_phase
    asl
    tax
    lda boss_music_table,x
    sta music_track
    jsr play_music

@done:
    rts

; ============================================
; DATA TABLES
; ============================================
track_table:
    .word track_title
    .word track_zone1
    .word track_zone2
    .word track_zone3
    .word track_zone4
    .word track_zone5
    .word track_zone6
    .word track_zone7
    .word track_zone8
    .word track_boss
    .word track_boss_final
    .word track_crimson_desire
    .word track_eternal_dance

note_freq_table:
; C2 to B6
.word $0D5D,$0C9C,$0BE7,$0B3C,$0A9B,$0A02,$0973,$08EB
.word $086B,$07F2,$0780,$0714,$06AE,$064E,$05F4,$059E
.word $054D,$0501,$04B9,$0475,$0435,$03F9,$03C0,$038A
.word $0357,$0327,$02FA,$02CF,$02A7,$0281,$025D,$023B
.word $021B,$01FC,$01E0,$01C5,$01AC,$0194,$017D,$0168
.word $0153,$0140,$012E,$011D,$010D,$00FE,$00F0,$00E2
.word $00D6,$00CA,$00BE,$00B4,$00AA,$00A0,$0097,$008F
.word $0087,$0080,$0079,$0072,$006C,$0066,$0060,$005B

effect_table:
    .word effect_none
    .word effect_arpeggio
    .word effect_slide_up
    .word effect_slide_down
    .word effect_vibrato
    .word effect_filter_sweep
    .word effect_delay
    .word effect_reverb

arpeggio_notes:
    .byte 0,4,7,12,7,4,0,0
    .byte 0,3,7,12,7,3,0,0
    .byte 0,5,7,12,7,5,0,0

; Constants
NOTE_OFF     = $FE
NOTE_NONE    = $FF
VOL_OFF      = $00
VOL_HALF     = $0F
VOL_MAX      = $1F

INST_BASS_808 = 0
INST_RHODES   = 1
INST_PLUCK    = 2
INST_KICK     = 3
INST_SNARE    = 4
INST_HIHAT    = 5
INST_PAD      = 6
INST_LEAD     = 7
INST_TENSION  = 8

EFX_NONE      = 0
EFX_ARPEGGIO  = 1
EFX_SLIDE_UP  = 2
EFX_SLIDE_DOWN = 3
EFX_VIBRATO   = 4
EFX_FILTER    = 5
EFX_DELAY     = 6
EFX_REVERB    = 7

; Note values
C2 = 0
CS2 = 1
D2 = 2
; ... up to B6

KICK  = 60
SNARE = 61
HIHAT = 62
