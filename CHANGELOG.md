# Changelog

All notable changes to this project will be documented in this file.

## [v1.1.3] - 2026-03-20

### Changed

- Reorganized controller code into a new `Core/Controller/` module layout to reduce file size and improve ownership boundaries.
- Split the former monolithic `Preybreaker.lua` into focused modules:
  - `Core/Controller/RefreshAndSound.lua` for snapshot refresh and sound/combat matching logic.
  - `Core/Controller/Bootstrap.lua` for startup/bootstrap and widget hook flow.
  - `Core/Controller/EventRouter.lua` for event dispatch and event registration.
- Reduced `Preybreaker.lua` to a thin controller initialization/base helper module.
- Updated `.toc` load order so controller modules initialize in deterministic sequence after base controller creation.

## [v1.1.2] - 2026-03-20

### Fixed

- Fixed another `ADDON_ACTION_FORBIDDEN` on startup by removing top-level `COMBAT_LOG_EVENT_UNFILTERED` registration and deferring it until after `PLAYER_ENTERING_WORLD` while out of combat, with retry on `PLAYER_REGEN_ENABLED`.

## [v1.1.1] - 2026-03-20

### Changed

- Improved prey target name matching by extracting the prey name from quest title format (`Prey: <prey name> (<difficulty>)`) in addition to existing normalized title candidates.

### Fixed

- Fixed `ADDON_ACTION_FORBIDDEN` caused by runtime optional sound-event registration; sound-related events are now statically registered and filtered in handlers instead of calling `RegisterEvent`/`UnregisterEvent` during refresh.

## [v1.1.0] - 2026-03-20

### Added

- Added `Settings` and `Changelog` tabs plus packaged in-game changelog data.
- Added deterministic regression coverage for reward selection, gossip automation, hunt dedupe/sort/filter logic, and quick-eval hunt availability.

### Changed

- Updated saved-variable schema to `5` with persisted settings tab, hunt-panel mode/filter, and standalone offset keys.
- Reworked hunt difficulty/random matching to locale pattern packs with learned-ID and ordered fallbacks.

### Fixed

- Fixed prey quest reward auto-selection for delayed reward payloads and capped-currency semantics, including `QUEST_ITEM_UPDATE` retry handling.
- Fixed random hunt auto-pickup with DialogueUI by hardening automation across `GOSSIP_SHOW`, `GOSSIP_CONFIRM`, `QUEST_DETAIL`, `QUEST_ACCEPTED`, `QUEST_FINISHED`, and `GOSSIP_CLOSED`.
- Fixed confirmation-required gossip flows by always using confirmed option selection and explicit `GOSSIP_CONFIRM` handling.
- Fixed changelog-tab scroll text overlap after deep scrolling.
- Fixed reward preference matching by prioritizing reward/currency IDs over localized names.
- Fixed hunt purchase scope so non-prey and non-target NPC interactions remain excluded.
- Fixed hunt audio wiring so cue playback is event-driven and language-agnostic, using prey stage transitions plus GUID/NPC-ID combat tracking (`hunt_start` on hunt entry, `ambush` on the prey ambush transition, `riposte` on Riposte cast, `kill` on tracked prey kill, and `hunt_end` on prey quest turn-in).


## [v1.0.0] - 2026-03-20

### Added

- Added locale support for `deDE`, `esES`, `esMX`, `frFR`, `itIT`, `koKR`, `ptBR`, `ruRU`, `zhCN`, and `zhTW` so the settings panel, preview, and compartment tooltip localize per client.
- Added saved-variable schema versioning and a guarded migration path for older offset and per-display setting layouts.
- Added tracker text-style settings for font face, outline, shadow, and separate number/badge sizing, with automatic LibSharedMedia font discovery when that library is installed.
- Added account-vs-character profile seeding so first-time character profiles inherit the current account layout instead of defaulting to stock values.

### Changed

- Moved more settings-panel, preview, and compartment text through `L[...]` so the addon no longer relies on English strings at runtime.
- Removed free-floating placement, grid controls, and per-display-mode color customization so the tracker stays widget-attached with simple X/Y offsets only.
- Centralized prey quest resolution so the data source, map click handling, auto-watch, supertracking, and auto-turn-in all use the same shared prey quest context.
- Changed prey quest tracking to prefer the real prey world quest in the prey zone instead of the questgiver stage quest whenever that world quest is present.
- Replaced the fixed-language ambush text path with locale-independent quest, task, and widget refresh signals.
- Widened placement offset range to ±200 for more flexible tracker positioning.
- Simplified prey quest focus cleanup to clear the waypoint instead of attempting to restore the previous quest focus.
- Consolidated widget-visibility effect handling into the main widget-hiding module.

### Fixed

- Fixed the final prey stage so the tracker stays active and the quest helper logic follows the zone world quest even after the earlier stage quest completes.
- Fixed the overlay map click in final stage so it opens and pings the correct prey world quest instead of the wrong questgiver quest.
- Fixed the normal quest watch call to match the current Retail `C_QuestLog.AddQuestWatch(questID)` signature.
- Fixed overlay-only widget suppression to stay idempotent across widget refreshes instead of restoring Blizzard prey visuals before hiding them again.
- Fixed overlay-only mode so the final prey stage keeps Blizzard's click-through world-map behavior even when the stock prey icon is hidden.
- Fixed the settings preview atlas mapping so `Hot` now uses the same final-stage prey icon art as current Retail.
- Fixed the bar fill artifact by replacing the moving fill atlas with a clean tintable fill texture while keeping the Blizzard-style frame art.
- Fixed default anchor positioning so zero offset now means centered on the resolved parent instead of carrying hidden built-in X/Y shifts.
- Fixed ring and bar reset behavior so both progress modes snap back to zero immediately when the prey hunt disappears instead of easing out from stale state.
- Fixed phase-change sounds to fire only on real in-session stage transitions, which suppresses login and reload noise while keeping Warm/Hot/Final cues intact.
- Fixed settings summary card using dynamic height so text rows never overlap regardless of string length or localization.

### Removed

- Removed the ambush probe debug module from the shipping addon.

## [v0.1.10] - 2026-03-17

### Added

- Added per-display detached placement with lockable saved positions, reset support, and live drag support for the overlay when unlocked.
- Added optional auto-watch and auto-supertrack settings for the active prey world quest.

### Changed

- Expanded the settings panel with detached-placement controls and prey quest tracking toggles.

## [v0.1.9] - 2026-03-15

### Fixed

- Changed overlay anchoring to follow the resolved Blizzard host frame strata instead of forcing the tracker to stay at `HIGH`, which keeps Preybreaker behind unrelated UI like the map and panels while still rendering above the prey widget.

### Changed

- Clarified the bar-mode limitation: Blizzard only exposes prey hunt progress as the four `Cold`/`Warm`/`Hot`/`Final` states, so the bar intentionally steps `0 -> 34 -> 67 -> 100`.

## [v0.1.8] - 2026-03-14

### Fixed

- Canceled and restored Blizzard's final-stage prey scripted model-scene effect in overlay-only mode so the animated blob no longer lingers after the widget frame hides.
- Removed the broad exploratory suppression paths added during debugging and kept the production hide path focused on widget-owned frames, textures, animations, and scripted effects.

### Added

- Added `/pb debug` to toggle runtime debug tracing without editing source files.

## [v0.1.7] - 2026-03-14

### Changed

- Reworked `Orbs` into a four-stage dot-orb strip that always shows every prey stage and fades unreached stages until they are earned.
- Replaced the display-mode button row in settings with a dropdown selector.
- Expanded per-display persistence so widget hiding, percent text, stage badge visibility, and scale now stay independent for ring, orb, and bar.
- Tightened the Blizzard-style bar footprint, art fit, and background opacity to sit closer to the live widget.

### Fixed

- Fixed the bar representation so it respects the border correctly.
- Tightened overlay-only suppression so it only hides prey-owned visuals and attached animations instead of broad shared widget-host surfaces.
- Adjusted the delayed widget-resolution retry burst so the same prey widget ID can recover on later widget or quest events.
- Restored overlay-only widget hiding across reloads and ensured disabling the feature restores the visuals Preybreaker suppressed.
- Switched overlay-only widget suppression to hide the actual Blizzard widget frames instead of relying only on alpha zero.

## [v0.1.6] - 2026-03-14

### Added

- Added a third `Orbs` display mode that grows a stage-colored orb from `Cold` through `Final`.

### Changed

- Updated settings persistence, mode controls, and preview behavior to treat ring, orb, and bar as separate display variants with their own offsets.
- Renamed the multi-mode overlay controller from `RingView` to `OverlayView` to match current responsibilities.

### Removed

- Removed dead namespace exports for the local radial and bar progress mixins.
- Removed the unused `SettingsPanel:Toggle()` entry point.

## [v0.1.5] - 2026-03-14

### Added

- Added a Blizzard-style bar display mode using the in-game `widgetstatusbar-*` atlases.
- Added an overlay-only option that fades the Blizzard widget when Preybreaker can resolve the live widget frame.
- Added separate persisted horizontal and vertical offsets for ring and bar display modes.

### Changed

- Updated the settings panel preview and controls to cover ring mode, bar mode, overlay-only mode, and per-display offsets.

### Fixed

- Fixed settings panel sizing so the added controls, sliders, and footer no longer overlap.
- Fixed bar-mode percent rendering so the readout is centered inside the bar.
- Fixed bar-mode badge handling so the stage badge stays disabled and hidden outside ring mode.
- Fixed shared-offset bleed so switching between ring and bar no longer overwrites the other mode's position.

## [v0.1.4] - 2026-03-14

### Added

- Added addon-compartment registration with status tooltip text and quick actions for toggling, opening settings, or forcing a refresh.
- Added persistent settings storage for tracker enable state, percent text visibility, stage badge visibility, ring scale, and anchor offsets.
- Added a movable settings panel with live-or-sample preview, reset, and refresh actions.

### Changed

- Refined stage badge placement so it stays aligned whether the percent text is shown or hidden.

### Fixed

- Fixed settings preview clipping and kept preview refreshes in sync with the live tracker state.
- Fixed anchor resolution so the overlay prefers the prey icon, then the widget frame, then the widget container, and only falls back to `UIParent` when required.

### Removed

- Removed the unused radial edge asset reference and dropped the orphaned `QueueStatusProgress-Edge` package file.

## [v0.1.3] - 2026-03-14

### Added

- Added a state badge below the percent readout using Blizzard's `uiwowlabsactionbar` art.

### Fixed

- Hid the tracker as soon as the active prey quest ends instead of letting a lingering widget keep it visible.

## [v0.1.2] - 2026-03-14

### Changed

- Reworked the prey ring radial cooldown to match Plumber's legacy icon-bar template and hosting model more closely.
- Reduced the prey-ring value text size slightly and removed the `%` suffix.

### Fixed

- Restored visible radial fill rendering by matching Plumber's legacy cooldown template, texture slice setup, and direct percentage updates.
- Kept the overlay anchored from `UIParent` while resolving against the Blizzard prey widget so the swipe no longer disappears behind host widget art.

## [v0.1.1] - 2026-03-14

### Added

- Added explicit GPL source headers across the addon files.

## [v0.1.0] - 2026-03-13

### Added

- Introduced the minimal Preybreaker addon shell focused on a single prey progress ring with percent text.
- Added state-driven prey progress resolution using `C_QuestLog.GetActivePreyQuest()` and `C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo()`.
- Added radial cooldown ring rendering adapted from Plumber with addon-packaged ring assets.

### Fixed

- Tightened swipe texture rendering, hollow ring presentation, and simplified radial progress updates for the initial public release.
