; ============================================================
; GnG Enhanced — Title Screen "ENHANCED" Text Patch
; ============================================================
; Adds "ENHANCED" below the logo on the title screen using
; the existing BG3 font tiles. Hooks the enable_nmi call
; during title screen init (screen still off = safe VRAM).
;
; BG3 config on title screen:
;   BG3SC    = $18  → tilemap at VRAM $1800, 32×32
;   BG34NBA  = $05  → tiles at VRAM $5000
;   BGMODE   = $09  → Mode 1, BG3 priority
;   Buffer   = $7F9000 (2048 bytes, mirrored by NMI DMA)
;
; Font encoding (custom sequential):
;   A=$0A B=$0B C=$0C D=$0D E=$0E ... N=$17 ... H=$11
;
; Tilemap word = palette 7, priority 0 → $1C00 | tile
; ============================================================

asar 1.81
lorom

incsrc "../config.asm"

if !title_text_enabled

; ----------------------------------------------------------
; Hook: $0493D1 — title screen init, just before enable_nmi
; Original: JSL $01833A (4 bytes)
; At this point forced blank is active, VRAM is writable.
; ----------------------------------------------------------

org $0493D1
    jsl TitleEnhanced

; ----------------------------------------------------------
; Subroutine — write "ENHANCED" to BG3 tilemap
; Placed in bank $01 free space ($01FDB6+)
; ----------------------------------------------------------

org $01FDB6

TitleEnhanced:
    php

    ; Set VRAM increment: +1 word on high-byte ($2119) write
    sep #$20
    lda #$80
    sta $2115                ; VMAIN

    ; VRAM word address: row 13, col 12 of tilemap at $1800
    ; = $1800 + (13 × 32) + 12 = $19AC
    rep #$20
    lda #$19AC
    sta $2116                ; VMADDL/H

    ; Write 8 tilemap entries to VRAM + RAM buffer simultaneously
    ; Palette 7, priority 1 = $3C00 | tile  (priority 1 = in front of BG1)
    ; Buffer byte offset = (13×32 + 12) × 2 = $0358
    ; Buffer address = $7F9000 + $0358 = $7F9358

    lda #$3C0E               ; E  (tile $0E, palette 7, priority 1)
    sta $2118
    sta $7F9358

    lda #$3C17               ; N  (tile $17)
    sta $2118
    sta $7F935A

    lda #$3C11               ; H  (tile $11)
    sta $2118
    sta $7F935C

    lda #$3C0A               ; A  (tile $0A)
    sta $2118
    sta $7F935E

    lda #$3C17               ; N  (tile $17)
    sta $2118
    sta $7F9360

    lda #$3C0C               ; C  (tile $0C)
    sta $2118
    sta $7F9362

    lda #$3C0E               ; E  (tile $0E)
    sta $2118
    sta $7F9364

    lda #$3C0D               ; D  (tile $0D)
    sta $2118
    sta $7F9366

    plp
    jsl $01833A              ; original: enable_nmi
    rtl

warnpc $01FF00

endif
