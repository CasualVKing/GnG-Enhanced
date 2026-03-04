; ============================================================
; GnG Enhanced — Configuration
; ============================================================
; Tweak these values and re-run build.bat to test.
;
; Speed format: 16-bit value where high byte = integer pixels,
; low byte = fractional (sub-pixel). $0100 = 1.0 pixels/frame.
;
; For reference, Arthur's directional jump launch speed is
; $011E (~1.12 px/frame) and his walk speed is similar.
; ============================================================

; Horizontal acceleration per frame when pressing L/R in air
!air_accel        = $0028       ; ~0.156 px/frame (~7 frames to full speed from rest)

; Friction per frame when NO direction is held (decelerate toward zero)
!air_decel        = $0018       ; ~0.094 px/frame (gentle slide to stop)

; Maximum horizontal airborne speed (magnitude, 16-bit)
!air_max_speed    = $0160       ; ~1.375 px/frame (slightly above jump launch speed)

; Extra deceleration when pressing the OPPOSITE direction (sharper turnarounds)
!air_turn_boost   = $0010       ; ~0.063 px/frame (added to air_accel when reversing)

; 1 = apply friction when no direction held, 0 = maintain momentum (ice physics)
!enable_friction  = 1

; ============================================================
; Throw Cancel Configuration
; ============================================================
; Allow canceling the throw animation with a jump after a delay.
; Uses weapon_cooldown ($14EC) as the timer — lance sets it to
; $0C (12) at throw start, decrementing each frame.
;
; throw_cancel_cooldown: cancel allowed when weapon_cooldown
; drops to this value or below. Lower = more delay before cancel.
;   $0A = ~2 frame delay (very fast cancel)
;   $08 = ~4 frame delay (default — tight but not instant)
;   $06 = ~6 frame delay (noticeable commitment)
;   $04 = ~8 frame delay (heavy commitment)

; 1 = throw cancel enabled, 0 = disabled (original behavior)
!throw_cancel_enabled   = 1

; Cooldown threshold for cancel window (see table above)
!throw_cancel_cooldown  = $08

; ============================================================
; FastROM Configuration
; ============================================================
; The original ROM runs in SlowROM mode (CPU @ 2.68 MHz).
; FastROM boosts ROM access speed to 3.58 MHz (~33% faster).
; This significantly reduces slowdown in enemy-heavy scenes.

; 1 = enable FastROM (recommended), 0 = original SlowROM speed
!fastrom_enabled        = 1

; ============================================================
; Title Screen Configuration
; ============================================================
; Adds "ENHANCED" text below the logo on the title screen
; using a BG3 overlay with custom 2bpp font tiles.

; 1 = show "ENHANCED" on title screen, 0 = original title screen
!title_text_enabled     = 1
