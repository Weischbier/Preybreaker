# Changelog

All notable changes to this project will be documented in this file.

This project publishes tagged releases on GitHub. Changes are grouped under `Unreleased` and versioned release sections.

## [Unreleased]

## [v1.0.0.@project-abbreviated-hash@] - 2026-03-19

### Added

- Added locale-pack files for `deDE`, `esES`, `esMX`, `frFR`, `itIT`, `koKR`, `ptBR`, `ruRU`, `zhCN`, and `zhTW`, and wired them into the Retail TOC so the expanded settings, preview, and compartment copy can localize per client.
- Added explicit saved-variable schema versioning and a guarded migration path for older offset and per-display setting layouts.
- Added tracker text-style settings for font face, outline, shadow, and separate number/badge sizing, with automatic LibSharedMedia font discovery when that library is installed and consistent application across the live tracker and preview.
- Added account-vs-character profile seeding so first-time character profiles inherit the current account layout instead of dropping straight to defaults.

### Changed

- Promoted release versioning to the `v1.0.0.<github-revision>` format for packaged builds by switching the release metadata to the packager's `@project-abbreviated-hash@` substitution token.
- Rewrote the README to focus on the addon's purpose and feature set in more natural user-facing language while keeping license and thanks information intact.
- Split locale bootstrap from per-language translations and moved more settings-panel, preview, and compartment text through `L[...]` so runtime copy no longer relies on English strings.
- Removed free-floating placement and grid controls so the tracker stays widget-attached with simple X/Y offsets only.
- Centralized prey quest resolution so the data source, map click handling, auto-watch, supertracking, and auto-turn-in all use the same shared prey quest context.
- Changed prey quest tracking to prefer the real prey world quest in the prey zone instead of the questgiver stage quest whenever that world quest is present.
- Replaced the fixed-language ambush text path with locale-independent quest, task, and widget refresh signals.

### Fixed

- Fixed the final prey stage so the tracker stays active and the quest helper logic follows the zone world quest even after the earlier stage quest completes.
- Fixed the overlay map click in final stage so it opens and pings the correct prey world quest instead of the wrong questgiver quest.
- Fixed the normal quest watch call to match the current Retail `C_QuestLog.AddQuestWatch(questID)` signature.
- Fixed overlay-only widget suppression to stay idempotent across widget refreshes instead of restoring Blizzard prey visuals before hiding them again.
- Fixed overlay-only mode so the final prey stage keeps Blizzard's click-through world-map behavior even when the stock prey icon is hidden.
- Fixed the settings preview atlas mapping so `Hot` now uses the same final-stage prey icon art as current Retail.
- Fixed the bar fill artifact by replacing the moving fill atlas with a clean tintable fill texture while keeping the Blizzard-style frame art.
- Fixed default anchor positioning so zero offset now means centered on the resolved parent instead of carrying hidden built-in X/Y shifts.
- Fixed the placement sliders so horizontal and vertical offsets now expose the intended `-80` to `80` range.
- Fixed the missing `DescribeDrawLayer` resolver export that could crash overlay anchoring during debug logging.
- Fixed ring and bar reset behavior so both progress modes snap back to zero immediately when the prey hunt disappears instead of easing out from stale state.
- Fixed phase-change sounds to fire only on real in-session stage transitions, which suppresses login and reload noise while keeping Warm/Hot/Final cues intact.

### Removed

- Removed the fixed-language ambush probe module from the shipping addon.
- Removed repository-only screenshot assets, the release setup note, and the duplicate development TOC so the repo stays focused on addon sources and support files.

## [v0.1.10] - 2026-03-17

### Added

- Added per-display detached placement with lockable saved positions, reset support, and live drag support for the overlay when unlocked.
- Added optional auto-watch and auto-supertrack settings for the active prey world quest.

### Changed

- Expanded the settings panel with detached-placement controls and prey quest tracking toggles.
- Updated addon notes and README copy to reflect optional detached placement and quest tracking helpers.

## [v0.1.9] - 2026-03-15

### Fixed

- Changed overlay anchoring to follow the resolved Blizzard host frame strata instead of forcing the tracker to stay at `HIGH`, which keeps Preybreaker behind unrelated UI like the map and panels while still rendering above the prey widget.
- Added archive export rules so repo-only metadata such as `.gitignore` does not ship in future source downloads.

### Changed

- Clarified the README's bar-mode limitation: Blizzard only exposes prey hunt progress as the four `Cold`/`Warm`/`Hot`/`Final` states, so the bar intentionally steps `0 -> 34 -> 67 -> 100`.

## [v0.1.8] - 2026-03-14

### Fixed

- Canceled and restored Blizzard's final-stage prey scripted model-scene effect in overlay-only mode so the animated blob no longer lingers after the widget frame hides.
- Removed the broad exploratory suppression paths added during debugging and kept the production hide path focused on widget-owned frames, textures, animations, and scripted effects.

### Added

- Added explicit `visibility` debug tracing for scripted effect suppression and restoration.
- Added `/pb debug` to toggle runtime debug tracing without editing source files.

## [v0.1.7] - 2026-03-14

### Changed

- Reworked `Orbs` into a four-stage dot-orb strip that always shows every prey stage and fades unreached stages until they are earned.
- Swapped the orb atlases to Blizzard's `common-radiobutton-dot` and `common-roundhighlight` entries verified with `TextureAtlasViewer`.
- Replaced the display-mode button row in settings with a dropdown selector.
- Expanded per-display persistence so widget hiding, percent text, stage badge visibility, and scale now stay independent for ring, orb, and bar.
- Tightened the Blizzard-style bar footprint, art fit, and background opacity to sit closer to the live widget.

### Fixed

- Fixed GitHub issue `#1` (`bar representation doesnt respect border`) by fitting the bar art and background inside the border correctly.
- Tightened overlay-only suppression so it only hides prey-owned visuals and attached animations instead of broad shared widget-host surfaces.
- Adjusted the delayed widget-resolution retry burst so the same prey widget ID can recover on later widget or quest events.
- Restored overlay-only widget hiding across reloads and ensured disabling the feature restores the visuals Preybreaker suppressed.
- Switched overlay-only widget suppression to hide the actual Blizzard widget frames instead of relying only on alpha zero.

## [v0.1.6] - 2026-03-14

### Added

- Added a third `Orbs` display mode that grows a stage-colored orb from `Cold` through `Final`.
- Added an initial orb progress renderer for the new `Orbs` display mode.
- Added tracked ignore rules for local Playwright artifact folders.

### Changed

- Updated settings persistence, mode controls, and preview behavior to treat ring, orb, and bar as separate display variants with their own offsets.
- Updated README copy and addon metadata to describe the new orb variant and atlas choice.
- Renamed the multi-mode overlay controller from `RingView` to `OverlayView` to match current responsibilities.

### Removed

- Removed dead namespace exports for the local radial and bar progress mixins.
- Removed the unused `SettingsPanel:Toggle()` entry point.
- Removed tracked `.playwright-cli` session log files from the repository.

## [v0.1.5] - 2026-03-14

### Added

- Added a Blizzard-style bar display mode using the in-game `widgetstatusbar-*` atlases.
- Added an overlay-only option that fades the Blizzard widget when Preybreaker can resolve the live widget frame.
- Added separate persisted horizontal and vertical offsets for ring and bar display modes.
- Added a three-image README preview gallery for ring, bar, and overlay-only bar settings states.

### Changed

- Updated the settings panel preview and controls to cover ring mode, bar mode, overlay-only mode, and per-display offsets.
- Updated README documentation to describe the bar display, ring-only stage badge behavior, and per-display positioning.
- Replaced the transient Discord export screenshot names with stable documentation image names under `docs/images`.

### Fixed

- Fixed settings panel sizing so the added controls, sliders, and footer no longer overlap.
- Fixed bar-mode percent rendering so the readout is centered inside the bar.
- Fixed bar-mode badge handling so the stage badge stays disabled and hidden outside ring mode.
- Fixed shared-offset bleed so switching between ring and bar no longer overwrites the other mode's position.

## [v0.1.4] - 2026-03-14

### Added

- Added original Preybreaker branding assets for the README header and addon icon.
- Added addon-compartment registration with status tooltip text and quick actions for toggling, opening settings, or forcing a refresh.
- Added persistent settings storage for tracker enable state, percent text visibility, stage badge visibility, ring scale, and anchor offsets.
- Added a movable settings panel with live-or-sample preview, reset, and refresh actions.
- Added refreshed README imagery, including the branded icon sheet and settings panel screenshot.

### Changed

- Updated TOC metadata to expose the saved-variable store, addon-compartment handlers, icon texture, and real anchor fallback contract.
- Updated the README and packaged-art notes to match the current addon behavior and approved release assets.
- Refined stage badge placement so it stays aligned whether the percent text is shown or hidden.

### Fixed

- Fixed settings preview clipping and kept preview refreshes in sync with the live tracker state.
- Fixed anchor resolution so the overlay prefers the prey icon, then the widget frame, then the widget container, and only falls back to `UIParent` when required.
- Aligned `SafeCall` error logging with the same debug-enabled contract used by `ns.Debug:Log`.

### Removed

- Removed the unused radial edge asset reference and dropped the orphaned `QueueStatusProgress-Edge` package file.

## [v0.1.3] - 2026-03-14

### Added

- Added a state badge below the percent readout using Blizzard's `uiwowlabsactionbar` art.
- Added README gallery images for the `Cold`, `Warm`, `Hot`, and `Final` tracker states.

### Changed

- Refreshed the README layout so the addon overview, behavior, and screenshots are easier to scan.
- Synced the TOC version to `v0.1.3` before publishing.

### Fixed

- Hid the tracker as soon as the active prey quest ends instead of letting a lingering widget keep it visible.
- Continued tightening the prey ring rendering and state presentation around the Blizzard widget.

## [v0.1.2] - 2026-03-14

### Changed

- Reworked the prey ring radial cooldown to match Plumber's legacy icon-bar template and hosting model more closely.
- Reduced the prey-ring value text size slightly and removed the `%` suffix.

### Fixed

- Restored visible radial fill rendering by matching Plumber's legacy cooldown template, texture slice setup, and direct percentage updates.
- Kept the overlay anchored from `UIParent` while resolving against the Blizzard prey widget so the swipe no longer disappears behind host widget art.
- Continued tightening radial cooldown behavior and state-driven ring updates around the Blizzard prey widget.

## [v0.1.1] - 2026-03-14

### Added

- Added explicit GPL source headers across the addon files.
- Added `LICENSE-NOTES.md` to document Plumber attribution and current licensing caveats.

### Changed

- Updated the README to describe the current prey ring behavior and add special thanks to Peterodox.

## [v0.1.0] - 2026-03-13

### Added

- Introduced the minimal Preybreaker addon shell focused on a single prey progress ring with percent text.
- Added state-driven prey progress resolution using `C_QuestLog.GetActivePreyQuest()` and `C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo()`.
- Added radial cooldown ring rendering adapted from Plumber with addon-packaged ring assets.

### Fixed

- Tightened swipe texture rendering, hollow ring presentation, and simplified radial progress updates for the initial public release.
