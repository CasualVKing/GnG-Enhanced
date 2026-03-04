# GnG Enhanced

Quality-of-life patches for **Super Ghouls 'n Ghosts** (SNES).

## Features

- **Air Control** — Mario-style horizontal movement during jumps and double jumps. Configurable acceleration, max speed, and friction.
- **Throw Cancel** — Cancel the throw animation with a jump after a short delay, reducing commitment to attacks.
- **FastROM** — Converts the ROM from SlowROM to FastROM, boosting CPU clock from 2.68 MHz to 3.58 MHz (~33% faster). Significantly reduces slowdown in busy scenes.
- **Title Screen Text** — Displays "ENHANCED" below the logo on the title screen.

All features are individually toggleable in `config.asm`.

## Setup

1. **Download asar** from [github.com/RPGHacker/asar/releases](https://github.com/RPGHacker/asar/releases) and place `asar.exe` in the `tools/` folder
2. **Supply your own ROM** — place a clean Super Ghouls 'n Ghosts (USA) `.sfc` ROM at `rom/clean.sfc`
3. **Run the build script:**
   ```
   build.bat
   ```
4. The patched ROM is output to `rom/gng_enhanced.sfc` — open it in your emulator

## Configuration

All parameters are in `config.asm`. Edit values, re-run `build.bat`, and test.

### Air Control

| Parameter | Default | Description |
|-----------|---------|-------------|
| `air_accel` | `$0028` | Horizontal acceleration per frame |
| `air_decel` | `$0018` | Friction when no direction held |
| `air_max_speed` | `$0160` | Max horizontal airborne speed |
| `air_turn_boost` | `$0010` | Extra decel when pressing opposite direction |
| `enable_friction` | `1` | Slow to stop when releasing d-pad (0 = ice physics) |

### Throw Cancel

| Parameter | Default | Description |
|-----------|---------|-------------|
| `throw_cancel_enabled` | `1` | Enable/disable throw cancel |
| `throw_cancel_cooldown` | `$08` | Cooldown threshold — lower = more delay before cancel allowed |

### Feature Toggles

| Parameter | Default | Description |
|-----------|---------|-------------|
| `fastrom_enabled` | `1` | Enable FastROM speed boost |
| `title_text_enabled` | `1` | Show "ENHANCED" on title screen |

## Legal

This project contains no copyrighted material. You must supply your own legally obtained ROM. The patch files modify game behavior but contain no game assets or code from the original ROM.

## Credits

- **FredYeye** — [Super Ghouls 'n Ghosts Disassembly](https://github.com/FredYeye/Super-Ghouls-n-Ghosts-Disassembly) (invaluable reference)
- **RPGHacker** — [asar](https://github.com/RPGHacker/asar) assembler
