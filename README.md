# Mari0 for PS4

Play **Mari0** on your PlayStation 4.

Mari0 is the fan game by Maurice Guégan (Stabyourself.net) that combines Super Mario Bros. with
Portal's portal gun. This is a port to PS4 homebrew, with controls made for the DualShock 4 and
local multiplayer for up to 4 players.

Ported to PS4 by **ShiroKlein**. It runs natively on
[LÖVE for PS4](https://github.com/iHaiDeeZ/love-ps4), the game engine port that comes with it.

## What you need

- A PS4 with homebrew enabled (GoldHEN or similar) so you can install `.pkg` files.
- Two system files, `libScePigletv2VSH.sprx` and `libSceShaccVSH.sprx`, from the 4.74 devkit
  firmware. The game needs them to draw anything. They belong to Sony, so they can't be included
  here; they're the same files RetroArch for PS4 uses.
- A way to copy files to the console, for example GoldHEN's FTP server.

## Installing

1. On the console, create the folder `/data/love/modules/` and copy both `.sprx` files into it.
2. Download the `.pkg` from the [Releases](https://github.com/iHaiDeeZ/mari0-ps4/releases) page.
3. Install it with GoldHEN's Package Installer.
4. Start **Mari0 (By ShiroKlein)** from the home screen.

## Controls

| Button | In game | In menus |
|---|---|---|
| Left stick / D-pad | Move, climb, enter pipes | Move the selection |
| Right stick | Aim the portal gun | |
| L2 | Blue portal | |
| R2 | Orange portal | |
| Cross | Jump | Confirm |
| Square | Run / fireball | |
| Circle | Use (buttons, cubes) | Back |
| Triangle | Reset your portals | |
| Options | Pause | Confirm, or resume from the pause menu |

One squeeze of a trigger fires one portal. The portal gun keeps pointing where you last aimed it.

## Multiplayer

Up to 4 players can play together, each with their own controller.

1. Turn on the extra controllers and sign each one in to a user or a guest (the PS4 asks when you
   turn a controller on). You can do this while the game is running.
2. On the title menu, press left or right on "player game" to choose the number of players.
3. Player 1 uses the first controller, player 2 the second, and so on.

## Saves and problems

- Saves and settings are stored in `/data/love/mari0/`.
- If the game goes straight back to the home screen, check that both `.sprx` files are in
  `/data/love/modules/` with exactly those names.
- For anything else, look at `/data/love/log.txt`, and include it when reporting a problem.

## For developers

The PS4-specific code is in [`ps4.lua`](ps4.lua). Building the package and testing on PC are
explained in [`ps4/README.md`](ps4/README.md).

## Credits and license

- **Mari0** by Maurice Guégan / [Stabyourself.net](https://stabyourself.net), MIT License,
  Copyright © 2006-2023 Maurice Guégan. The original source is at
  [Stabyourself/mari0](https://github.com/Stabyourself/mari0).
- **PS4 port** by **ShiroKlein**.
- Runs on [LÖVE](https://love2d.org), ported to PS4 as [LÖVE for PS4](https://github.com/iHaiDeeZ/love-ps4).

Mari0 is a fan game and isn't affiliated with Nintendo or Valve.
