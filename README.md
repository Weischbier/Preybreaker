# Preybreaker

Preybreaker exists for one reason: make Prey Hunt easier to read.

The default hunt widget does the job, but it is easy to lose in the middle of everything else happening on screen. Preybreaker gives that same hunt state a cleaner, more readable presentation so you can tell where the chase stands without hunting for the widget first.

## Purpose

Preybreaker keeps the current Prey Hunt stage visible in a way that fits real gameplay. It is meant for players who want the hunt state to be obvious at a glance, whether they prefer a compact overlay, a cleaner stage readout, or a more minimal UI.

## Features

- Shows the live Prey Hunt state in a clearer overlay that stays tied to the Blizzard widget.
- Supports radial, orb, bar, and text-only display styles.
- Lets you nudge the tracker with simple X/Y offsets while keeping it anchored in place.
- Can hide the Blizzard prey widget and leave only the Preybreaker display on screen.
- Shows optional progress text and stage labels for faster readability.
- Can play a sound when the hunt moves into a new stage.
- Can automatically watch, supertrack, and auto-turn-in the prey quest.
- Can auto-purchase randomized hunts and auto-select hunt rewards based on your configured preferences.
- Supports account-wide settings with optional per-character profiles.
- Uses live widget and quest data so the tracker follows the real hunt state instead of a static guess.

## License

- Source code is distributed under `GPL-3.0-only`. See `LICENSE`.
- The radial progress implementation is adapted in part from [Plumber](https://github.com/Peterodox/Plumber), which is also GPLv3.
- See `LICENSE-NOTES.md` for attribution details and packaged art notes.

## Special Thanks

Special thanks to [Peterodox](https://github.com/Peterodox) for the inspiration and upstream Plumber work that informed Preybreaker's radial progress approach.
