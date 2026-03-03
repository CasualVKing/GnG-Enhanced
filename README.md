# GnG Enhanced

Air control patch for **Super Ghouls 'n Ghosts** (SNES).

Arthur's jumps in the original game use fixed trajectories — once you commit to a jump, you can't change direction. This patch adds Mario-style air control, letting you steer Arthur left and right while airborne.

## Features

- Full horizontal air control during jumps and double jumps
- Configurable acceleration, max speed, and friction
- Air turnaround boost for responsive direction changes
- All other mechanics unchanged (shooting, magic, armor, enemies, collision)

## Setup

1. **Download asar** from [github.com/RPGHacker/asar/releases](https://github.com/RPGHacker/asar/releases) and place `asar.exe` in the `tools/` folder
2. **Supply your own ROM** — place a clean Super Ghouls 'n Ghosts (USA) `.sfc` ROM at `rom/clean.sfc`
3. **Run the build script:**
   ```
   build.bat
   ```
4. The patched ROM is output to `rom/gng_enhanced.sfc` — open it in your emulator

## Tuning

All physics parameters are in `config.asm`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `air_accel` | `$0028` | Horizontal acceleration per frame |
| `air_decel` | `$0018` | Friction when no direction held |
| `air_max_speed` | `$0160` | Max horizontal airborne speed |
| `air_turn_boost` | `$0010` | Extra decel when pressing opposite direction |
| `enable_friction` | `1` | Slow to stop when releasing d-pad (0 = maintain momentum) |

Edit the values, re-run `build.bat`, and test. The cycle takes seconds.

## Legal

This project contains no copyrighted material. You must supply your own legally obtained ROM. The patch files modify game behavior but contain no game assets or code from the original ROM.

## Credits

- **FredYeye** — [Super Ghouls 'n Ghosts Disassembly](https://github.com/FredYeye/Super-Ghouls-n-Ghosts-Disassembly) (invaluable reference)
- **RPGHacker** — [asar](https://github.com/RPGHacker/asar) assembler
