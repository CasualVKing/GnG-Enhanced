; ============================================================
; GnG Enhanced — Air Control Configuration
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
