# Mari0 on PS4

Mari0 runs on PS4 homebrew on top of **LÖVE for PS4**, a separate project and repository
(`love-ps4`) that ports the LÖVE 11.4 engine using the OpenOrbis toolchain. This repo only
contains the game side:

- `../ps4.lua` is the platform layer: DualShock 4 controls, right-stick aiming, L2/R2 portals,
  menu navigation and the 1080p letterbox.
- `build-pkg.sh` packs the game into `mari0.love` and builds a PS4 `.pkg` with love-ps4.
- `icon0.png` is the home screen icon.

## Status

| Part | State |
|---|---|
| Controller layer | Done. Tested in desktop LÖVE with a simulated DualShock 4: aim, both portals, trigger re-arming, walking, pause. |
| LÖVE runtime for PS4 | Builds and packages (love-ps4 repo) |
| Mari0 `.pkg` | Builds (`IV0000-MARI00006_00-MARI000000000000.pkg`) |
| Running on a real PS4 | **Not tested yet** |

## Controls (DualShock 4)

| Input | In game | In menus |
|---|---|---|
| Left stick / D-pad | Move, climb, enter pipes | Navigate (holding repeats) |
| **Right stick** | **Aim the portal gun** (360°; letting go keeps the last angle) | |
| **L2** | **Blue portal** (portal 1) | |
| **R2** | **Orange portal** (portal 2) | |
| Cross | Jump | Confirm |
| Square | Run / fireball | |
| Circle | Use (buttons, cubes) | Back (disabled on the title screen) |
| Triangle | Reset portals | |
| Options | Pause | Confirm; in the pause menu, resume |
| Touchpad click | Pause | |

The Share and PS buttons belong to the system. Triggers fire when pulled past 50%. Each one
must come back under 30% before it fires again, so one squeeze gives one portal. L2 and R2 are
independent, so you can hold one and fire the other. The gun's usual 0.2s cooldown still applies.

Tuning values are at the top of `ps4.lua`: `ps4.buttons`, `ps4.triggers`, the deadzones and the
menu repeat rates.

In console mode:
- Every player N uses pad N, and mouse aiming is off.
- The optional post-processing shader effects are skipped. They would all go through the
  PS4's runtime shader compiler at startup.
- Saves go to `/data/love/mari0`.

On PC, players 2–4 default to the same pad layout.

## Building the PS4 package

On Ubuntu/WSL, with `love-ps4` checked out next to this repo (`../love-ps4`):

```bash
sudo ../love-ps4/platform/ps4/setup-toolchain.sh   # once
ps4/build-pkg.sh
```

The package is written to `build/ps4/`. The first run builds the LÖVE runtime, which takes a few
minutes; after that only the game is repacked. Set `LOVE_PS4` if love-ps4 is somewhere else.

The PS4 needs the Piglet shader compiler modules for LÖVE's graphics. See "Shader compiler
modules" in love-ps4's `platform/ps4/README.md`. Put them in `love-ps4/platform/ps4/modules/`
before running `build-pkg.sh` to bundle them.

## Testing on PC first

```bash
love . --ps4
```

This runs console mode in a 1280×720 window with a DS4 on USB or Bluetooth: letterboxing, pad
controls, no mouse.
