#!/bin/bash
set -e

echo "============================================"
echo " GnG Enhanced — Build Script"
echo "============================================"

# Check for clean ROM
if [ ! -f "rom/clean.sfc" ]; then
    echo "ERROR: rom/clean.sfc not found."
    echo "Place your clean Super Ghouls 'n Ghosts (USA) ROM at rom/clean.sfc"
    exit 1
fi

# Check for asar
ASAR="tools/asar"
if [ -f "tools/asar.exe" ]; then
    ASAR="tools/asar.exe"
elif ! command -v asar &>/dev/null && [ ! -f "$ASAR" ]; then
    echo "ERROR: asar not found in tools/ or PATH."
    echo "Download from https://github.com/RPGHacker/asar/releases"
    exit 1
fi

# Copy clean ROM
echo ""
echo "[1/5] Copying clean ROM..."
cp rom/clean.sfc rom/gng_enhanced.sfc

# Apply patches
echo "[2/5] Applying air control patch..."
$ASAR patches/air_control.asm rom/gng_enhanced.sfc

echo "[3/5] Applying throw cancel patch..."
$ASAR patches/throw_cancel.asm rom/gng_enhanced.sfc

echo "[4/5] Applying title text patch..."
$ASAR patches/title_text.asm rom/gng_enhanced.sfc

echo "[5/5] Applying FastROM patch..."
$ASAR patches/fastrom.asm rom/gng_enhanced.sfc

echo ""
echo "============================================"
echo " SUCCESS! Patched ROM: rom/gng_enhanced.sfc"
echo "============================================"
echo ""

# Optional: launch emulator
if [ -n "$GNG_EMULATOR" ]; then
    echo "Launching emulator..."
    "$GNG_EMULATOR" rom/gng_enhanced.sfc &
else
    echo "Tip: Set GNG_EMULATOR env var to auto-launch your emulator."
fi
