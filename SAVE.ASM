; ============================================
; BATTERY-BACKED SAVE SYSTEM
; ============================================
.include "gaudensex.inc"

.segment "BANK_GAME"
.org $E000

; ============================================
; SAVE DATA STRUCTURE
; ============================================
.struct SaveData
    magic       .byte 4    ; "GMEX"
    version     .byte
    checksum    .byte
    slot_used   .byte
    player_name .byte 8
    play_time   .word 3    ; 24-bit seconds
    score       .word 3
    coins       .word
    zone        .byte
    weapon      .byte
    weapon_level .byte
    unlocked_weapons .byte
    unlocked_ships .byte
    achievements .byte 4   ; 32 bits
    achievement_progress .byte 64  ; 32 * 2 bytes
    settings    .byte
    replay_data .byte 256  ; Compressed input log
    reserved    .byte 64
.endstruct

SAVE_SIZE = .sizeof(SaveData)
SAVE_SLOTS = 3

; ============================================
; INITIALIZE SAVE SYSTEM
; ============================================
init_save:
    ; Enable save RAM
    lda #SAVE_ENABLE
    sta SAVE_CONTROL

    ; Check for valid save data
    jsr check_save_data

    ; If no valid save, initialize
    lda save_valid
    bne @load_existing

    jsr init_new_save

@load_existing:
    ; Load first valid slot
    ldx #0
@find_slot:
    lda SAVE_RAM + SaveData::slot_used,x
    bne @slot_found

    inx
    cpx #SAVE_SLOTS
    bne @find_slot

    ; No slots used
    jsr init_new_save
    bra @done

@slot_found:
    ; Load slot X
    txa
    jsr load_save_slot

@done:
    rts

; ============================================
; CHECK SAVE DATA VALIDITY
; ============================================
check_save_data:
    lda #0
    sta save_valid

    ; Check magic number
    ldx #0
@check_magic:
    lda SAVE_RAM,x
    cmp magic_number,x
    bne @not_valid

    inx
    cpx #4
    bne @check_magic

    ; Check checksum
    jsr calculate_checksum
    lda checksum_temp
    cmp SAVE_RAM + SaveData::checksum
    bne @not_valid

    ; Valid save
    lda #1
    sta save_valid

@not_valid:
    rts

magic_number: .byte "GMEX"

; ============================================
; INITIALIZE NEW SAVE
; ============================================
init_new_save:
    ; Find empty slot
    ldx #0
@find_empty:
    lda SAVE_RAM + SaveData::slot_used,x
    beq @slot_empty

    inx
    cpx #SAVE_SLOTS
    bne @find_empty

    ; Overwrite first slot
    ldx #0

@slot_empty:
    ; Clear save data
    lda #0
    ldy #SAVE_SIZE-1
@clear_loop:
    sta SAVE_RAM,y
    dey
    bpl @clear_loop

    ; Set magic number
    ldy #0
@set_magic:
    lda magic_number,y
    sta SAVE_RAM,y
    iny
    cpy #4
    bne @set_magic

    ; Set version
    lda #SAVE_VERSION
    sta SAVE_RAM + SaveData::version

    ; Mark slot used
    lda #1
    sta SAVE_RAM + SaveData::slot_used

    ; Set default player name
    ldy #0
@set_name:
    lda default_name,y
    sta SAVE_RAM + SaveData::player_name,y
    iny
    cpy #8
    bne @set_name

    ; Initial unlocked weapons (Basic only)
    lda #%00000001
    sta SAVE_RAM + SaveData::unlocked_weapons

    ; Calculate checksum
    jsr calculate_checksum
    lda checksum_temp
    sta SAVE_RAM + SaveData::checksum

    ; Load this slot
    txa
    jsr load_save_slot

    rts

default_name: .byte "PLAYER1",0

; ============================================
; LOAD SAVE SLOT
; ============================================
; Input: A = slot number (0-2)
load_save_slot:
    pha
    phx
    phy

    ; Calculate slot offset
    sta current_slot
    lda #SAVE_SIZE
    sta multiplier
    jsr multiply
    lda product
    sta save_offset
    lda product+1
    sta save_offset+1

    ; Copy to RAM
    ldy #SAVE_SIZE-1
@copy_loop:
    lda SAVE_RAM,y
    sta save_buffer,y
    dey
    bpl @copy_loop

    ; Update game state
    jsr apply_save_data

    ply
    plx
    pla
    rts

; ============================================
; SAVE CURRENT GAME
; ============================================
save_game:
    pha
    phx
    phy

    ; Update save buffer from game state
    jsr update_save_buffer

    ; Calculate checksum
    jsr calculate_checksum_buffer
    lda checksum_temp
    sta save_buffer + SaveData::checksum

    ; Write to save RAM
    ldy #SAVE_SIZE-1
@write_loop:
    lda save_buffer,y
    sta (save_offset),y
    dey
    bpl @write_loop

    ; Visual feedback
    jsr show_save_indicator

    ply
    plx
    pla
    rts

; ============================================
; UPDATE SAVE BUFFER
; ============================================
update_save_buffer:
    ; Play time
    lda play_time
    sta save_buffer + SaveData::play_time
    lda play_time+1
    sta save_buffer + SaveData::play_time+1
    lda play_time+2
    sta save_buffer + SaveData::play_time+2

    ; Score
    lda score
    sta save_buffer + SaveData::score
    lda score+1
    sta save_buffer + SaveData::score+1
    lda score+2
    sta save_buffer + SaveData::score+2

    ; Coins
    lda coins
    sta save_buffer + SaveData::coins

    ; Zone
    lda current_zone
    sta save_buffer + SaveData::zone

    ; Weapon
    lda current_weapon
    sta save_buffer + SaveData::weapon

    ; Unlocked weapons
    lda unlocked_weapons
    sta save_buffer + SaveData::unlocked_weapons

    ; Achievements
    ldx #0
@achievements_loop:
    lda achievement_unlocked,x
    sta save_buffer + SaveData::achievements,x
    inx
    cpx #4
    bne @achievements_loop

    ; Achievement progress
    ldx #0
@progress_loop:
    lda achievement_progress,x
    sta save_buffer + SaveData::achievement_progress,x
    inx
    cpx #64
    bne @progress_loop

    ; Replay data (compressed)
    jsr compress_replay_data

    rts

; ============================================
; CALCULATE CHECKSUM
; ============================================
calculate_checksum:
    lda #0
    sta checksum_temp

    ldy #SAVE_SIZE-1
@checksum_loop:
    clc
    adc SAVE_RAM,y
    dey
    bpl @checksum_loop

    eor #$FF
    sta checksum_temp
    rts

calculate_checksum_buffer:
    lda #0
    sta checksum_temp

    ldy #SAVE_SIZE-1
@checksum_loop:
    clc
    adc save_buffer,y
    dey
    bpl @checksum_loop

    eor #$FF
    sta checksum_temp
    rts

; ============================================
; REPLAY SYSTEM
; ============================================
compress_replay_data:
    ; Simple RLE compression
    ldx #0
    ldy #0
    lda #0
    sta run_length
    sta run_value

@compress_loop:
    lda input_buffer,x
    cmp run_value
    beq @same_value

    ; Write run
    lda run_length
    beq @no_write

    sta save_buffer + SaveData::replay_data,y
    iny
    lda run_value
    sta save_buffer + SaveData::replay_data,y
    iny

@no_write:
    ; Start new run
    lda input_buffer,x
    sta run_value
    lda #1
    sta run_length
    bra @next

@same_value:
    inc run_length

@next:
    inx
    cpx #256
    bne @compress_loop

    ; Write final run
    lda run_length
    sta save_buffer + SaveData::replay_data,y
    iny
    lda run_value
    sta save_buffer + SaveData::replay_data,y

    ; Fill rest with 0
    iny
@clear_rest:
    cpy #256
    beq @done
    lda #0
    sta save_buffer + SaveData::replay_data,y
    iny
    bra @clear_rest

@done:
    rts

; ============================================
; SAVE SLOT MANAGEMENT
; ============================================
delete_save_slot:
    ; Input: A = slot number
    pha

    ; Clear slot
    lda #SAVE_SIZE
    sta multiplier
    jsr multiply
    lda product
    sta temp_ptr
    lda product+1
    sta temp_ptr+1

    lda #0
    ldy #SAVE_SIZE-1
@clear_slot:
    sta (temp_ptr),y
    dey
    bpl @clear_slot

    ; If current slot deleted, load first available
    pla
    cmp current_slot
    bne @done

    jsr find_valid_save

@done:
    rts

find_valid_save:
    ldx #0
@find_loop:
    lda SAVE_RAM + SaveData::slot_used,x
    beq @next_slot

    txa
    jsr load_save_slot
    rts

@next_slot:
    inx
    cpx #SAVE_SLOTS
    bne @find_loop

    ; No saves, create new
    jsr init_new_save

    rts

; ============================================
; DATA
; ============================================
SAVE_VERSION = 1

save_valid:     .byte 0
current_slot:   .byte 0
save_offset:    .word 0
save_buffer:    .res SAVE_SIZE

checksum_temp:  .byte 0
run_length:     .byte 0
run_value:      .byte 0

; Multiplication helper
multiplier:     .byte 0
multiplicand:   .byte 0
product:        .word 0

multiply:
    ; multiplier * multiplicand -> product
    lda #0
    sta product
    sta product+1

    ldx multiplier
    beq @done

@add_loop:
    lda product
    clc
    adc multiplicand
    sta product
    lda product+1
    adc #0
    sta product+1

    dex
    bne @add_loop

@done:
    rts

; Input buffer for replay
input_buffer:   .res 256
