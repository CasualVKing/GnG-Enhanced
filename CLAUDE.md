# CLAUDE.md — GnG Enhanced

## What This Is

ASM patches for Super Ghouls 'n Ghosts (SNES) that add Mario-style air control to Arthur's jumps. Uses the [FredYeye disassembly](https://github.com/FredYeye/Super-Ghouls-n-Ghosts-Disassembly) as reference. Patches are applied with [asar](https://github.com/RPGHacker/asar).

## Build Commands

```bash
# Windows — patch ROM and launch emulator
build.bat

# Bash/WSL
./build.sh
```

Requires:
- `tools/asar.exe` (download from asar releases)
- `rom/clean.sfc` (user-supplied US ROM)

## Architecture

This is a pure ASM patch project — no compiled language, no build system beyond asar.

### File Layout

```
patches/air_control.asm    # Main patch — injection point + air control subroutine
config.asm                 # All tunable parameters (acceleration, max speed, friction)
build.bat / build.sh       # One-click: copy clean ROM → asar patch → launch emulator
rom/                       # (gitignored) clean.sfc + gng_enhanced.sfc
tools/                     # (gitignored) asar.exe, flips.exe
```

### How the Patch Works

The original game sets Arthur's horizontal velocity once at jump start (`set_speed_xyg`) and never modifies it during the airborne loop. Our patch injects a `JSR AirControlUpdate` into the airborne loop (bank01 `.CF53` region) that reads the d-pad and applies acceleration to `obj.speed_x` each frame.

### Key ROM Addresses (bank01.asm)

| Address | Label | Role |
|---------|-------|------|
| `$01CF02` | `.arthur_jump` | Jump entry point |
| `$01CF53` | Airborne loop | **Our injection point** |
| `$01DD46` | `arthur_cap_fall_speed` | Position update + gravity |

### Key RAM Addresses

| Address | Label | Role |
|---------|-------|------|
| `$02B8` | `p1_button_hold+1` | D-pad: R=$01, L=$02, D=$04, U=$08 |
| `$0454` | Arthur `obj.speed_x` | 3-byte horizontal velocity (sub, mid, hi) |
| `$044E` | Arthur `obj.direction` | Movement direction |
| `$044F` | Arthur `obj.facing` | Sprite facing direction |
| `$14BC` | `jump_state` | 0=first jump, 1=double jump |

### Speed Format

Speeds are 24-bit (3 bytes): `high.mid.sub`. High byte is the sign/integer part, mid is the fractional "pixel" part, sub is sub-pixel. Normal walk speed is ~$01.40.00. The `config.asm` values are 16-bit (mid.sub) for the acceleration/max-speed parameters.

### Iteration Workflow

1. Edit `config.asm` or `patches/air_control.asm`
2. Run `build.bat`
3. Test in BizHawk
4. Repeat

## Legal

No copyrighted ROM data is stored in this repo. Users supply their own ROM. Patches are distributed as ASM source or BPS files.
