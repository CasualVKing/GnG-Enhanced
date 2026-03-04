; ============================================================
; GnG Enhanced — Air Control Patch
; ============================================================
; Adds horizontal air control to Arthur's jump in
; Super Ghouls 'n Ghosts (USA).
;
; Apply with: asar patches/air_control.asm rom/gng_enhanced.sfc
;
; How it works:
;   The original game sets Arthur's horizontal velocity once at
;   jump start (via set_speed_xyg) and never modifies it while
;   airborne. This patch injects a subroutine into the airborne
;   frame loop that reads the d-pad and applies acceleration or
;   deceleration to Arthur's horizontal speed each frame.
;
;   Speed is stored as unsigned magnitude in obj.speed_x (3 bytes)
;   with obj.direction (0=right, 1=left) determining the sign.
;   The position update routine (update_pos_x) adds or subtracts
;   speed based on direction. Our code modifies speed magnitude
;   and flips direction when Arthur reverses.
; ============================================================

asar 1.81
lorom

incsrc "../config.asm"

; ============================================================
; RAM Addresses (from disassembly ram_map.asm)
; ============================================================

; Controller input — game reads these from hardware each frame
; Upper byte of p1_button_hold has d-pad bits
!p1_hold_hi       = $02B8      ; Right=$01, Left=$02, Down=$04, Up=$08

; Jump state tracking
!jump_state       = $14BC      ; 0=first jump, 1=double jump, 2=dbl+shot

; ============================================================
; Object struct field offsets (direct page relative)
; ============================================================
; During Arthur's coroutine, the 65816 direct page register (D)
; is set to Arthur's object base ($043C). All obj.* fields are
; accessed via 8-bit direct page offsets.

!obj_direction    = $11        ; 0=right, 1=left (determines movement sign)
!obj_facing       = $12        ; 0=right, 1=left (determines sprite flip)
!obj_speed_x      = $16        ; 3 bytes: +0=fractional, +1=integer, +2=sign
!obj_speed_x_sign = $18        ; sign byte (always $00 for our purposes)

; ============================================================
; D-pad button masks (upper byte of joypad)
; ============================================================

!btn_right        = $01
!btn_left         = $02

; ============================================================
; ROM addresses (bank 01)
; ============================================================

; arthur_cap_fall_speed: applies gravity to speed_y, updates
; position, and caps terminal velocity. Called every airborne frame.
!cap_fall_speed   = $DD45

; ============================================================
; STEP 1: Patch the injection point
; ============================================================
; The airborne loop at $01CF53 runs every frame while Arthur is
; in the air. The instruction sequence is:
;
;   $CF53: lda.w double_jump_state / bne +
;   $CF58: jsr $D2D4              ; update facing from d-pad
;   $CF5B: jsr $DE63              ; frozen check
;   $CF5E: jsr $DD45              ; arthur_cap_fall_speed ← REPLACE
;   $CF61: jsr $D8F1              ; ceiling collision
;   $CF64: jsr $D91C              ; wall collision
;   $CF67: jsr $D97E              ; ground collision
;
; We replace the 3-byte JSR at $CF5E with a JSR to our hook.
; Our hook modifies speed_x, then tail-calls arthur_cap_fall_speed.
; When cap_fall_speed does RTS, it returns to $CF61 (the address
; the original JSR pushed), so collision checks run unchanged.

org $01CF5E
    jsr AirControlHook


; ============================================================
; STEP 2: Air control subroutine
; ============================================================
; Placed at $01FD00 — free space near end of bank 01.
; The US ROM has padding ($FF bytes) in this region.
;
; Entry: A=8-bit, direct page = Arthur object base
; Exit:  tail-calls arthur_cap_fall_speed (same register state)

org $01FD00

AirControlHook:
    ; ----------------------------------------
    ; Read d-pad left/right
    ; ----------------------------------------
    lda.w !p1_hold_hi         ; load d-pad upper byte
    and #!btn_right|!btn_left ; isolate L/R bits ($03)
    beq .no_input             ; no L/R pressed → friction or maintain
    cmp #$03
    beq .no_input             ; both pressed → treat as no input

    ; ----------------------------------------
    ; Convert button to direction
    ;   Right ($01) >> 1 = $00 = direction right
    ;   Left  ($02) >> 1 = $01 = direction left
    ; ----------------------------------------
    lsr a                     ; $01→$00, $02→$01
    pha                       ; save desired direction on stack

    ; Update sprite facing to match input direction
    sta.b !obj_facing

    ; ----------------------------------------
    ; Compare desired direction vs current movement
    ; ----------------------------------------
    cmp.b !obj_direction
    beq .accelerate           ; same direction → speed up

    ; ----------------------------------------
    ; OPPOSITE DIRECTION: Decelerate, possibly flip
    ; ----------------------------------------
    rep #$20                  ; 16-bit accumulator
    lda.b !obj_speed_x        ; load speed magnitude (frac:int as 16-bit)
    sec
    sbc.w #!air_accel+!air_turn_boost  ; subtract with extra turn boost
    bcs .store_pull_done      ; no underflow → store (still moving in old dir)

    ; Speed crossed zero — flip direction
    eor #$FFFF                ; negate the underflow result
    inc a                     ; two's complement → positive magnitude
    sta.b !obj_speed_x        ; store new speed in new direction
    sep #$20                  ; back to 8-bit

    pla                       ; pull desired direction
    sta.b !obj_direction      ; flip movement direction
    bra .finish

    ; ----------------------------------------
    ; SAME DIRECTION: Accelerate
    ; ----------------------------------------
.accelerate:
    rep #$20                  ; 16-bit accumulator
    lda.b !obj_speed_x        ; load current speed
    clc
    adc.w #!air_accel         ; add acceleration
    cmp.w #!air_max_speed     ; check max speed
    bcc .store_pull_done      ; under max → store
    lda.w #!air_max_speed     ; clamp to max

.store_pull_done:
    sta.b !obj_speed_x        ; store speed
    sep #$20                  ; back to 8-bit
    pla                       ; clean up stack (desired direction)
    bra .finish

    ; ----------------------------------------
    ; NO INPUT: Apply friction or maintain momentum
    ; ----------------------------------------
.no_input:
if !enable_friction
    rep #$20                  ; 16-bit accumulator
    lda.b !obj_speed_x        ; load current speed
    beq .no_input_done        ; already zero → skip

    sec
    sbc.w #!air_decel         ; subtract friction
    bcs +                     ; no underflow → store
    lda.w #$0000              ; clamp to zero
+:  sta.b !obj_speed_x

.no_input_done:
    sep #$20                  ; back to 8-bit
endif

    ; ----------------------------------------
    ; FINISH: Clear sign byte, tail-call original
    ; ----------------------------------------
.finish:
    stz.b !obj_speed_x_sign   ; keep sign byte at $00 (magnitude is unsigned)
    jmp !cap_fall_speed        ; tail-call arthur_cap_fall_speed → RTS returns to caller

; Safety: ensure we haven't overflowed into important data
warnpc $01FDB6

; ============================================================
; END OF PATCH
; ============================================================
