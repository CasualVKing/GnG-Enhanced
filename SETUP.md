# GnG Enhanced — Setup & Testing Guide

## Required Tools

### 1. asar (SNES Assembler)

Download from [github.com/RPGHacker/asar/releases](https://github.com/RPGHacker/asar/releases).

- Grab the latest release (v1.81+)
- Extract `asar.exe` (Windows) into the `tools/` folder in this repo
- Final path should be: `tools/asar.exe`

### 2. Clean ROM

**Super Ghouls 'n Ghosts (USA)** — headerless `.sfc` format.

- File size should be exactly **1,048,576 bytes** (1 MB / 8 Mbit)
- If your ROM is 1,049,088 bytes (1 MB + 512), it has a copier header — rename to `.smc` or strip the header
- Place at: `rom/clean.sfc`

**Why the US version?** The patch addresses (`$01CF5E` injection point, `$01FD00` hook location, RAM addresses for jump state and controller input) are all specific to the US ROM layout. JP and EU versions have different byte offsets.

### 3. Emulator (BizHawk or any SNES emulator)

Any SNES emulator works for testing. BizHawk is already set up from LTTP tools.

**Optional tip:** Set the `GNG_EMULATOR` environment variable to auto-launch after patching:
```
set GNG_EMULATOR=C:\path\to\EmuHawk.exe
```

### 4. Flips (Optional — for BPS patch distribution)

Download from [github.com/Alcaro/Flips](https://github.com/Alcaro/Flips). Only needed once the physics feel right and we want to generate a distributable `.bps` patch file. Not needed during development.

---

## Building & Testing

### First Run

1. Place `asar.exe` in `tools/`
2. Place your clean US ROM at `rom/clean.sfc`
3. Run `build.bat` (Windows) or `./build.sh` (bash/WSL)
4. Open `rom/gng_enhanced.sfc` in your emulator

### Iteration Cycle

The whole point of this setup is fast iteration:

1. Edit `config.asm` (tweak acceleration, max speed, friction, etc.)
2. Run `build.bat`
3. Test in emulator
4. Repeat

Each cycle takes seconds. The build script always starts from a fresh copy of the clean ROM.

---

## What the Patch Does (Technical)

### The Problem

In the original game, Arthur's horizontal velocity is set **once** at the moment he jumps (via `set_speed_xyg` at `$01CF22`). During the entire airborne loop (`$01CF53`–`$01CF89`), the game:

- Applies gravity to vertical speed
- Updates position from speed
- Checks collisions (ceiling, wall, ground)
- Checks for double-jump input

But it **never reads the d-pad for horizontal movement**. Arthur's horizontal trajectory is locked the instant he leaves the ground.

### The Fix

We replace a single 3-byte instruction at `$01CF5E`:

```
Original: jsr $DD45    (arthur_cap_fall_speed)
Patched:  jsr $FD00    (AirControlHook)
```

`AirControlHook` (placed at `$01FD00` in free ROM space) runs every airborne frame:

1. **Reads d-pad** left/right from `p1_button_hold` (`$02B8`)
2. **Compares** desired direction to current movement direction (`obj.direction`)
3. **Same direction** → accelerate (increase speed magnitude, clamped to max)
4. **Opposite direction** → decelerate with turn boost; if speed crosses zero, flip direction
5. **No input** → apply friction (if enabled), decelerating toward zero
6. **Tail-calls** the original `arthur_cap_fall_speed` so gravity, position updates, and fall speed capping all work unchanged

The `rts` from `arthur_cap_fall_speed` returns to the airborne loop at `$01CF61`, where collision checks continue normally.

### Speed System

Super Ghouls 'n Ghosts uses a **magnitude + direction** system:

- `obj.speed_x` = 3 bytes (fractional, integer, sign) — always a positive magnitude
- `obj.direction` = 0 (right) or 1 (left) — determines whether speed is added to or subtracted from position
- `update_pos_x` checks direction: if 0, adds speed to pos; if 1, subtracts

Our patch modifies the speed magnitude and flips the direction flag when Arthur reverses. The sign byte (`speed_x+2`) is always kept at `$00`.

### Key Addresses

| Type | Address | Label | Purpose |
|------|---------|-------|---------|
| ROM | `$01CF5E` | Airborne loop | Injection point (replaces `jsr $DD45`) |
| ROM | `$01FD00` | AirControlHook | Our new subroutine (free space) |
| ROM | `$01DD45` | arthur_cap_fall_speed | Original gravity/position update |
| RAM | `$02B8` | p1_button_hold+1 | D-pad bits: R=$01, L=$02, D=$04, U=$08 |
| RAM | `$0452` | Arthur obj.speed_x | 3-byte horizontal speed (fractional) |
| RAM | `$0453` | Arthur obj.speed_x+1 | Integer part of horizontal speed |
| RAM | `$044D` | Arthur obj.direction | 0=right, 1=left |
| RAM | `$044E` | Arthur obj.facing | 0=right, 1=left (sprite flip) |
| RAM | `$14BC` | jump_state | 0=first jump, 1=double jump |

### Config Parameters

All in `config.asm`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `!air_accel` | `$0028` | Acceleration per frame (~0.156 px/frame) |
| `!air_decel` | `$0018` | Friction per frame (~0.094 px/frame) |
| `!air_max_speed` | `$0160` | Max airborne speed (~1.375 px/frame) |
| `!air_turn_boost` | `$0010` | Extra decel when reversing (~0.063 px/frame) |
| `!enable_friction` | `1` | 1=friction on, 0=maintain momentum |

For reference, Arthur's normal directional jump launch speed is `$011E` (~1.12 px/frame). The default max airborne speed (`$0160`) is slightly above this, allowing air control to reach marginally higher speeds than a normal jump — similar to how Mario can exceed his ground speed with perfect air control.

---

## Troubleshooting

### "PATCH FAILED" — asar reports errors

- **Wrong ROM**: Make sure it's the US version, headerless `.sfc`, exactly 1,048,576 bytes
- **Address conflict at $01FD00**: The free space assumption may be wrong for your ROM dump. Check if bytes at file offset `$FD00`–`$FD80` are `$FF` in your clean ROM. If not, we need to find different free space.

### Game boots but crashes or glitches

- Verify the clean ROM works unpatched first
- The patch only modifies 3 bytes at the injection point + ~80 bytes of new code at `$01FD00`. If these regions overlap with existing code in your ROM dump, addresses need adjustment.

### Air control doesn't feel right

That's expected — tweaking is the whole point! Edit `config.asm`:
- **Too floaty**: Increase `!air_decel`, decrease `!air_max_speed`
- **Too sluggish**: Increase `!air_accel`
- **Turns too slowly**: Increase `!air_turn_boost`
- **Want ice physics**: Set `!enable_friction = 0`

---

## Architecture Reference

Source: [FredYeye/Super-Ghouls-n-Ghosts-Disassembly](https://github.com/FredYeye/Super-Ghouls-n-Ghosts-Disassembly)

### Airborne Loop (original, bank01)

```
$CF53: lda.w double_jump_state / bne +
$CF58: jsr $D2D4          ; update sprite facing from d-pad
$CF5B: jsr $DE63          ; frozen check
$CF5E: jsr $DD45          ; arthur_cap_fall_speed ← PATCHED
$CF61: jsr $D8F1          ; ceiling collision
$CF64: jsr $D91C          ; wall collision
$CF67: jsr $D97E          ; ground/landing check
$CF6A: beq $CF71          ; not landed → continue
$CF6C: brk / jmp $CDBE    ; landed → idle state
$CF71: [double jump check]
$CF87: brk / bra $CF53    ; loop back
```

### Object Struct (65 bytes per object, Arthur = object 0)

```
+$00  active       +$11  direction    +$1E  pos_x (3 bytes)
+$01  timer        +$12  facing       +$21  pos_y (3 bytes)
+$02  state (4b)   +$16  speed_x (3b) +$24  anim_timer
+$06  type         +$19  speed_y (3b)
+$0E  hp           +$1C  gravity
```

Arthur's object base address: `$043C`
