# Changelog

All notable changes to this project will be documented in this file.

## [v1.2.7] - 2026-04-08

### Added

- Added a hunt-cache reset slash command (`/pb huntrescan`, with aliases `/pb rescanhunts` and `/pb clearhuntcache`) that clears cached hunt rows and reward snapshots, then immediately starts a fresh stabilized hunt scan.

### Changed

- Removed the addon's sound subsystem, sound settings, and sound event routing so Preybreaker no longer plays hunt audio cues.
- Reworked hunt-panel open gating to use live prey quest context and live map state instead of an English-only Astalor subzone whitelist.
- Added a dedicated HuntList cache-reset path used by slash commands to cancel active warmup/scan work, clear runtime hunt state, clear character cache entries, and force the next hunt evaluation to come from a live scan.
- Made the settings sidebar quick-action buttons locale-safe by dynamically sizing translated labels and stacking the buttons vertically when needed instead of clipping text.
- Migrated HuntPanel UI runtime text from hardcoded English literals to locale keys (title, subtitle, filter labels, status strings, summary line, loading labels, reward labels, and mode button labels).

### Fixed

- Fixed hunt list visibility on non-English clients by dropping the locale-fragile `Astalor's Sanctum` panel whitelist.
- Fixed secret-string and secret-table-index runtime errors from `Core/Controller/RefreshAndSound.lua` by removing the sound-only prey combat tracking path that was reading restricted values.
- Fixed German quick-action button label clipping/overlap in the settings panel.
- Fixed HuntPanel text staying English on non-English clients by wiring HuntPanel runtime strings through the locale table and adding locale entries across all shipped locale files.

## [v1.2.6] - 2026-04-08

### Changed

- Removed the addon's sound subsystem, sound settings, and sound event routing so Preybreaker no longer plays hunt audio cues.
- Reworked hunt-panel open gating to use live prey quest context and live map state instead of an English-only Astalor subzone whitelist.

### Fixed

- Fixed hunt list visibility on non-English clients by dropping the locale-fragile `Astalor's Sanctum` panel whitelist.
- Fixed secret-string and secret-table-index runtime errors from `Core/Controller/RefreshAndSound.lua` by removing the sound-only prey combat tracking path that was reading restricted values.

## [v1.2.5] - 2026-04-07

### Changed

- Tightened hunt panel visibility gating so the panel only opens and stays visible in Astalor's Sanctum (`ASTALORS_SANCTUM` global-string subzone).

### Fixed

- Fixed hunt panel appearing on the Midnight non-prey Adventure table by enforcing Astalor's Sanctum as a hard whitelist at open-time and refresh-time.

## [v1.2.4] - 2026-04-07

### Added

- Added character-scoped hunt quest cache persistence (`PreybreakerCharDB.huntQuestCache`) so known prey map entries and warmed reward snapshots restore faster between panel opens and reloads.

### Changed

- Updated hunt panel data flow to prefer cached hunt entries before running stabilized pin scans, reducing repeated Adventure Map scan passes when hunt data is already known for the character.

### Fixed

- Fixed Midnight dual-table map interaction blocking by hard-skipping prey pin scanning and reward warmup on the non-prey Adventure table subzone (`SANCTUM_OF_LIGHT` / Sanctum of Light).
- Fixed stale cached hunt quest entries by removing character-cache rows when a tracked hunt quest is removed or completed.

## [v1.2.3] - 2026-03-28

### Added

- Added `/pb diag` and `/pb mapdump` commands to inspect prey badge decisions and raw Adventure Map hunt pin data in game.

### Changed

- Reworked prey hunt achievement badges to use direct Retail Prey achievement and criteria completion checks instead of map-text or quest-completion heuristics.
- Added achievement-cache invalidation on achievement and criteria update events so hunt badge state refreshes without requiring a reload.

### Fixed

- Fixed completed prey targets still showing the hunt achievement badge when their corresponding Prey achievement criterion was already complete.
- Fixed hunt rows and achievement tooltips to fail closed when a hunt title does not match a verified achievement criterion, avoiding false-positive badges.
- Fixed new badge diagnostic and tooltip strings across all shipped locales instead of leaving English fallback text in non-enUS clients.

## [v1.2.2] - 2026-03-27

### Fixed

- Fixed 5 Russian lines in ruRU locale Hunt panel section that were not translated.
- Fixed German deDE locale: corrected imperative voice for Quest help section description, added missing comma after "es sei denn", changed idle status from "bereit" to "inaktiv", corrected Nightmare difficulty pattern casing.
- Fixed esES and esMX locales: replaced incorrect "Adjunto" (email attachment) with "Anclado" (anchored) for the Attached label and all "adjunta/adjunto" preview note variants, replaced "Audio y respuesta" with "Audio y retroalimentación" for the feedback section title.
- Fixed esES locale: replaced "TEMPLADO" with "TIBIO" for the WARM stage label and its description string.
- Fixed frFR locale: replaced "Compléter" with "Rendre" for quest auto turn-in description to match standard WoW French terminology.
- Fixed itIT locale: replaced "Disattivo" with "Inattivo" for the Off, Number off, and Badge off state labels.
- Fixed koKR locale: corrected grammar from "않는 한" to "않은 한" in auto-complete quest description.
- Fixed zhTW locale: replaced "精巧" (exquisite) with "緊湊型" (compact) in compartment tooltip description.
- Corrected "Pokemon" display value to "Pokémon" across the English baseline and all 10 locale files.

## [v1.2.1] - 2026-03-26

### Added

- New "Enable hunt panel" toggle in the settings UI under a dedicated "Hunt panel" section, allowing users to completely disable the hunt list panel.
- Hunt panel gate checks in the Adventure Map hook, standalone panel, `/pb hunt` slash command, and compartment shift-right-click entry points.
- Combat lockdown guards across all widget hiding, overlay click, LoadAddOn, and quest dialog paths to prevent `ADDON_ACTION_FORBIDDEN` errors during combat.
- `PLAYER_REGEN_ENABLED` listener that defers pending widget-hide operations until combat ends.
- `InCombatLockdown()` guard on the Bootstrap prey-icon post-hook, overlay map-click handler, `GetQuestChoiceDialog` `LoadAddOn` calls (HuntList and HuntPanel), and `OpenQuestChoice` dialog manipulation.
- Combat-lockdown guard on the widget-visibility retry timer to avoid taint from deferred `C_Timer.After` callbacks.
- Frame-reference compatibility wrappers (`ns.Constants.FrameRef`) in Constants.lua, abstracting `CovenantMissionFrame`, `AdventureMapQuestChoiceDialog`, and `Blizzard_AdventureMap` behind a single resolution layer for forward compatibility.
- Settings and migration regression tests: sanitizer boundary validation, v1-to-v5 offset migration, v2-to-v5 per-mode flattening, profile seeding, and reset-to-defaults coverage.
- Per-dispatch prey quest context cache (`ns.Util.GetCachedPreyQuestContext` / `InvalidatePreyQuestContextCache`) to eliminate redundant `BuildPreyQuestContext` round-trips within a single event cycle.
- Dirty-flag mechanism for overlay text styles (`_textStyleDirty`) so `ApplyOverlayTextStyles` skips redundant font introspection when settings haven't changed.
- Cached `GetResolvedSoundPaths` result on `soundState` invalidated only on theme change, eliminating per-cue table allocation.
- Reusable tables in `PickSoundVariantPath` to avoid throwaway `candidates` and `recentlyPlayed` allocations.
- Stable `BuildZoneOrderLookup` cache in HuntList, rebuilt only when zone data changes.

### Changed

- Consolidated HuntPanel's independent event frame: the controller now notifies the panel on all relevant events, eliminating the second event-processing pathway and preventing redundant refreshes.
- Wrapped `UISpecialFrames` insertion in `pcall` to isolate taint propagation from the global table.
- Moved inline orb-offset seeding (Settings.lua L350-354) into `MigrateLegacyOffsets` for consistency.

### Fixed

- Fixed potential `ADDON_ACTION_FORBIDDEN` from widget `Hide()`/`SetAlpha(0)` calls during combat lockdown (critical audit finding C-1).
- Fixed overlay left-click (`OpenWorldMap` via `ShowUIPanel`) causing taint errors when clicked during combat.
- Fixed `C_AddOns.LoadAddOn("Blizzard_AdventureMap")` calls risking taint when triggered during combat via gossip or warmup paths.
- Fixed `AdventureMapQuestChoiceDialog` manipulation (`SetParent`, `SetFrameStrata`, `ShowWithQuest`) causing potential taint when invoked during combat.

## [v1.2.0] - 2026-03-22

### Added

- Hunt panel: new panel that docks next to the Adventure Map showing all your hunts with difficulty colors, reward slots, status, and one-click quest opening. Also works as a standalone draggable panel (`/pb hunt`).
- Hunt filters: filter by All / Nightmare / Hard / Normal with instant refresh.
- Hunt summary bar: shows filter state, active count, ready count, and current Anguish at a glance.
- Loading overlays for both the docked and standalone panel while scans settle.
- Reward warmup: quest reward data now loads in the background so choices are ready before you finish.
- Roadmap tab in settings showing known issues and planned features.
- Updated all 10 locale files with the latest translation strings.

### Changed

- Replaced the old board-style hunt prototype with a compact list layout.
- Hunt panel auto-shows when you open the Adventure Map and hides when you close it.
- Smoother transitions: entry fades, filter flash feedback, active-hunt pulse, and a shimmer bar while loading.

### Fixed

- Pin scanning now waits for 3 consecutive stable pin counts before snapshotting, so late-loading pins no longer get missed.
- Reward warmup processes one quest at a time with proper timeouts instead of blasting them all at once.
- Fixed the loading bar sometimes rendering at zero width during early layout.
- Fixed hunt panel not appearing when the Adventure Map was already open on panel load.

## [v1.1.6] - 2026-03-22

### Added

- Added `prey_combat` sound cue that plays when a likely prey target is first spotted or targeted during Warm or higher hunt stages, using dedicated prey_combat sound files from Pokemon and Predator themes with fallback to ambush sounds.
- Added hunt-end sound on snapshot session-end when the previous quest was completion-flagged, not only on explicit quest turn-in.

### Changed

- Added a 0.4-second global sound cooldown to prevent multiple cues from stacking on the same gameplay moment (e.g., simultaneous ambush + progress + prey_combat during Cold→Warm transition).
- Rewrote sound variant selection to track both per-key and global last-played paths, preventing the same sound file from repeating across consecutive plays even when accessed through different alias chains.
- Consolidated duplicate helper functions (`TextContainsAny`, `ExtractNPCIDFromGUID`) into shared `Util` module.
- Added `GetLocalizedSpellName` compatibility wrapper that prefers `C_Spell.GetSpellName` with `GetSpellInfo` fallback.
- Refactored `SafeCall` to fixed-arity return to avoid temporary table allocation.
- Cached quest match set in `RefreshSoundContext` to skip rebuilding when the active quest ID has not changed.

### Fixed

- Fixed double-play sound bug where different cue types could all fire simultaneously for the same gameplay event due to independent per-key throttling.
- Fixed sound variant selection repeating the same file multiple times in a row by excluding both per-key and globally last-played paths from candidates.
- Capped reward auto-selection retry count at 10 to prevent unbounded retries if the quest UI never settles.
- Removed duplicate locale key for "Outline" in base locale table.
- Consolidated sound-state field initialization so all throttle keys and session fields are explicitly set in `GetSoundState`, preventing nil-access edge cases.
- Fixed global sound cooldown (`lastAnySoundAt`) persisting across hunt session resets, which could block `hunt_start` after rapid session transitions.
- Fixed `lastPreyCombatAt` and `lastDeathCueAt` throttle keys not being cleared on hunt session reset, causing stale cooldowns to carry over.

## [v1.1.5] - 2026-03-21

### Changed

- Restored stage-progression audio to the prior short single cue (`interaction.ogg`) for in-session prey stage transitions (`Cold->Warm`, `Warm->Hot`, and `Hot->Final`).

### Fixed

- Fixed ambush prey defeats not playing `kill.ogg` when the ambush target name did not match quest-title prey-name extraction by adding an ambush capture window that promotes the active hostile target/mouseover as a prey candidate.

## [v1.1.4] - 2026-03-20

### Fixed

- Fixed repeated `ADDON_ACTION_FORBIDDEN` errors caused by `RegisterEvent()` calls for combat-log wiring during bootstrap.
- Removed combat-log event registration from the controller flow and eliminated runtime event registration toggling entirely.

### Changed

- Switched prey kill cue detection to `NAME_PLATE_UNIT_REMOVED` with prey candidate matching plus dead-state checks, so kill sounds still fire without combat-log event subscription.

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
