; ============================================================
; GnG Enhanced — Throw Cancel Patch
; ============================================================
; Allows Arthur to cancel his throw animation with a jump
; after a configurable delay (based on weapon_cooldown timer).
;
; Apply AFTER air_control.asm:
;   asar patches/throw_cancel.asm rom/gng_enhanced.sfc
;
; How it works:
;   The walk loop at $01CE2F checks is_shooting ($14B1) and
;   branches to a restricted handler that skips the jump check.
;   We replace that LDA with a JSR to our hook, which checks
;   whether the cancel window is open (weapon_cooldown has
;   dropped enough) and if jump is pressed. If so, we clear
;   is_shooting and return Z=1 so the walk loop proceeds
;   normally — including the jump check at JSR $D1C5, which
;   detects the jump press and transitions to jump state.
; ============================================================

asar 1.81
lorom

incsrc "../config.asm"

; ============================================================
; RAM Addresses
; ============================================================

!is_shooting      = $14B1      ; 0=not throwing, 1=mid-throw animation
!weapon_cooldown  = $14EC      ; frames until next weapon fire ($0C for lance)
!jump_press       = $02C2      ; 1=jump button pressed this frame

; ============================================================
; STEP 1: Patch the walk loop's is_shooting check
; ============================================================
; Original bytes at $01CE2F:
;   AD B1 14    LDA $14B1       (is_shooting)
;   D0 34       BNE +$34        (branch to restricted handler at $CE68)
;
; We replace the 3-byte LDA with a JSR to our hook.
; The BNE at $01CE32 remains — our hook sets the Z flag:
;   Z=1 (A=0) → BNE not taken → normal walk flow (includes jump check)
;   Z=0 (A≠0) → BNE taken → restricted handler (no jump)

if !throw_cancel_enabled

org $01CE2F
    jsr ThrowCancelCheck       ; replaces: lda.w $14B1

; ============================================================
; STEP 2: Throw cancel subroutine
; ============================================================
; Placed at $01FD80 — free space after air_control.asm code.
;
; Entry: A=8-bit, direct page = Arthur object base ($043C)
; Exit:  Z flag controls caller's BNE branch

org $01FD80

ThrowCancelCheck:
    ; ----------------------------------------
    ; Check if Arthur is throwing
    ; ----------------------------------------
    lda.w !is_shooting
    beq .done                     ; not shooting → Z=1 → normal walk

    ; ----------------------------------------
    ; Check cancel window (enough frames elapsed?)
    ; ----------------------------------------
    lda.w !weapon_cooldown
    cmp #!throw_cancel_cooldown
    bcs .no_cancel                ; cooldown still high → too early

    ; ----------------------------------------
    ; Check jump input
    ; ----------------------------------------
    lda.w !jump_press
    beq .no_cancel                ; jump not pressed

    ; ----------------------------------------
    ; CANCEL: clear throw, allow jump
    ; ----------------------------------------
    stz.w !is_shooting            ; clear throw flag
    lda #$FF
    sta.b $3D                     ; invalidate sprite cache (DP-relative)
    lda #$00                      ; A=0, Z=1 → caller's BNE not taken
.done:
    rts

.no_cancel:
    lda.w !is_shooting            ; reload non-zero → Z=0 → BNE taken
    rts

; Safety: ensure we haven't overflowed
warnpc $01FDB6

endif

; ============================================================
; END OF PATCH
; ============================================================
