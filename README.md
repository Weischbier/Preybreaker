# Preybreaker

Preybreaker gives the Prey Hunt tracker a cleaner, easier-to-read home on your screen.

Instead of relying on the default prey icon alone, Preybreaker lets you keep the hunt state visible in a style that actually fits your UI: a ring, a row of stage orbs, or a compact bar. It stays focused on the hunt itself, updates as the prey heats up, and gets out of the way when the hunt is over.

## What Preybreaker Does

- Shows the active prey state in a clear tracker that is easy to read during combat and movement.
- Lets you choose between three looks: a ring, a four-stage orb strip, or a compact bar.
- Keeps the tracker attached to the Blizzard prey icon by default, or lets you turn it into a floating element and place it anywhere.
- Can hide the Blizzard prey icon entirely so only the Preybreaker tracker remains on screen during the hunt.
- Shows a progress number and optional stage badge so you can read the hunt state at a glance.
- Keeps separate positioning and layout choices for each display style, so ring, orbs, and bar can each be tuned differently.
- Can automatically add the active prey quest to your watch list and keep it focused while the hunt is active.
- Gives you a live preview in the settings window so you can adjust the tracker without guesswork.

## Why It Helps

Prey Hunt is one of those activities where a small UI detail matters a lot. You want to know the current state quickly, without hunting around the screen or trying to read a tiny icon while moving.

Preybreaker keeps that information visible in a form that matches the rest of your UI:

- Ring if you want something compact and centered around the icon.
- Orbs if you want the four hunt stages to read instantly.
- Bar if you prefer a clean horizontal tracker.

If you want a minimal screen, you can keep only the Preybreaker tracker visible. If you want the default prey icon to stay, you can build around it instead.

## Settings

Open the settings with `/pb`, `/pb settings`, or by shift-left-clicking the addon compartment icon.

From there you can:

- switch between ring, orb, and bar styles
- resize the current style
- attach the tracker to the Blizzard prey icon or float it freely
- move the tracker with sliders or by dragging it when floating mode is unlocked
- hide the Blizzard prey icon while a hunt is active
- turn the number and stage badge on or off
- enable quest watch and quest focus helpers
- preview every change before going back to the game

## Installation

1. Place this folder at `Interface/AddOns/Preybreaker`.
2. Make sure the addon file is `Interface/AddOns/Preybreaker/Preybreaker.toc`.
3. Start the game or reload your UI.
4. Enable `Preybreaker` from the addon list if needed.

## License

- Source code is distributed under `GPL-3.0-only`. See `LICENSE`.
- The radial progress implementation is adapted in part from [Plumber](https://github.com/Peterodox/Plumber), which is also GPLv3.
- See `LICENSE-NOTES.md` for attribution details and packaged art notes.

## Special Thanks

Special thanks to [Peterodox](https://github.com/Peterodox) for the inspiration and upstream Plumber work that informed Preybreaker's radial progress approach.
