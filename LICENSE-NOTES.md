# License Notes

This file clarifies the practical licensing boundaries in this repository. It is intended as project documentation, not legal advice.

## Source Code

- Unless a file states otherwise, Preybreaker source code is intended to be distributed under `GPL-3.0-only`.
- The full GPL text is included in `LICENSE`.

## Upstream Attribution

- `UI/Progress/RadialProgress.lua` and `UI/Progress/RadialProgress.xml` are adapted in part from [Plumber](https://github.com/Peterodox/Plumber) by [Peterodox](https://github.com/Peterodox).
- Plumber is published on GitHub with a GPLv3 license.
- That attribution should be preserved in derivative work and future refactors of the radial progress implementation.

## Packaged Art Assets

- `Media/Assets/Preybreaker-Icon.tga`
- `Media/Assets/ProgressBar-Radial-WarWithin.tga`
- `Media/Assets/uiwowlabsactionbar.blp`

These packaged art assets have been reviewed and approved for inclusion in Preybreaker distributions.

Unless an asset's source terms explicitly say otherwise, treat the repository's GPL notice as applying to the source code in this repository, not as an automatic relicensing statement for bundled art files.

## World Of Warcraft Add-On Policy

Preybreaker must still comply with Blizzard's WoW User Interface Add-On Development Policy regardless of the repository's software license.

## Known GPL Caveat

The FSF GPL FAQ treats some plug-ins for nonfree host applications as part of a single combined program unless they are clearly separate works or distributed with an explicit exception. I cannot determine conclusively from repo-local evidence whether Blizzard's addon loading model lands on that line for GPL purposes.

Because Preybreaker includes code adapted from Plumber, you should not assume you can add a broad proprietary-host exception to all of the affected files without reviewing upstream permissions first.
