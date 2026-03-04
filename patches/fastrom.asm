; ============================================================
; GnG Enhanced — FastROM Patch
; ============================================================
; Converts the ROM from SlowROM (2.68 MHz) to FastROM (3.58 MHz)
; for a ~33% CPU speed boost. Significantly reduces slowdown in
; enemy-heavy scenes.
;
; Apply AFTER air_control.asm and throw_cancel.asm:
;   asar patches/fastrom.asm rom/gng_enhanced.sfc
;
; How it works:
;   1. Changes the ROM header map mode from $20 (SlowLoROM)
;      to $30 (FastLoROM).
;   2. Patches the NMI handler to set $420D = $01 (enable fast
;      ROM access) and redirect execution to bank $80 (the fast
;      mirror of bank $00).
;   3. Redirects the main game logic JSL from bank $01 to bank
;      $81 (fast mirror), so Arthur's state machine, physics,
;      collision, and enemy processing all run at full speed.
;
; The SNES mirrors banks $00-$7F at $80-$FF. Code at $80:xxxx
; is identical to $00:xxxx but accessed at FastROM speed when
; $420D bit 0 is set. JSR calls stay in the current bank, so
; once we JML into bank $80/$81, all subroutine calls within
; those banks also run fast.
; ============================================================

asar 1.81
lorom

incsrc "../config.asm"

if !fastrom_enabled

; ============================================================
; STEP 1: ROM header — declare FastROM
; ============================================================
; Map mode byte at $00:FFD5 (file offset $7FD5):
;   $20 = SlowLoROM (original)
;   $30 = FastLoROM (patched)

org $00FFD5
    db $30

; ============================================================
; STEP 2: NMI trampoline — redirect to fast bank
; ============================================================
; The NMI handler at $00:81F7 runs every frame and drives all
; game logic. We replace the first 4 bytes with a JML to our
; trampoline in bank $81's free space (fast mirror of bank $01).
;
; Original NMI entry at $00:81F7 (file offset $01F7):
;   C2 30     REP #$30       ; 16-bit A, X, Y
;   48        PHA            ; save A
;   8B        PHB            ; save program bank
;   0B        PHD            ; ← continues here at $81FB
;   DA        PHX
;   5A        PHY
;   ...
;
; We replace the first 4 bytes (REP #$30 / PHA / PHB) with:
;   JML $81FDA0              ; jump to our trampoline (fast bank)

org $0081F7
    jml $81FDA0              ; 4 bytes: 5C A0 FD 81 (fast mirror of bank $01)

; ============================================================
; STEP 3: Bank $01 → $81 redirect for main game logic
; ============================================================
; The NMI handler at $00:820D calls the main game logic via:
;   JSL $018343
;
; Bank $01 contains Arthur's state machine, physics, collision,
; enemy AI — the heaviest CPU work. Redirecting to bank $81
; (fast mirror) makes all this code run at FastROM speed.
;
; Original: 22 43 83 01  (JSL $018343)
; Patched:  22 43 83 81  (JSL $818343)
;
; We only need to change the bank byte (4th byte of JSL).

org $008210                  ; bank byte of the JSL at $820D
    db $81

; ============================================================
; STEP 4: NMI trampoline subroutine
; ============================================================
; Placed at $01:FDA0 (accessed via $81:FDA0 in fast bank).
; This runs every NMI (every frame):
;   1. Executes the 3 original instructions we replaced
;   2. Enables FastROM via $420D
;   3. JML back to the NMI handler in bank $80 (fast)
;
; After the final JML, the entire NMI handler runs from bank
; $80. All JSR calls stay in bank $80 (fast). The JSL to bank
; $81 at $820D then runs game logic from bank $81 (also fast).

org $01FDA0

FastNMI:
    rep #$30                 ; original: 16-bit A, X, Y
    pha                      ; original: save A on stack
    phb                      ; original: save program bank

    ; Enable FastROM access speed
    sep #$20                 ; 8-bit A for register write
    lda #$01
    sta $420D                ; MEMSEL: enable fast ROM access
    rep #$20                 ; restore 16-bit A

    ; Continue NMI handler in fast bank $80
    jml $8081FB              ; → PHD at $80:81FB (fast mirror)

; Safety: ensure we haven't overflowed into bank $01 end
warnpc $01FDB6

endif

; ============================================================
; END OF PATCH
; ============================================================
