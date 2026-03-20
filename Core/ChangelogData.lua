-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local ChangelogData = {}
ns.ChangelogData = ChangelogData

local RELEASE_HEADER_PATTERN = "^%s*##%s*%[(.-)%]%s*%-%s*(.-)%s*$"
local SECTION_HEADER_PATTERN = "^%s*###%s*(.-)%s*$"
local BULLET_PATTERN = "^%s*%-%s*(.+)%s*$"
local LOWER = (type(strlower) == "function" and strlower) or string.lower
local SECTION_NAME_BY_LOWER = {
    added = "Added",
    changed = "Changed",
    fixed = "Fixed",
    removed = "Removed",
}

local FALLBACK_MARKDOWN = [[
# Changelog

All notable changes to this project will be documented in this file.

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
- Fixed hunt audio wiring so start/end and Cold->Warm->Hot->Final transitions use the packaged hunt cue files with safe fallback handling.

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
- Widened placement offset range to +/-200 for more flexible tracker positioning.
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

- Changed overlay anchoring to follow the resolved Blizzard host frame strata instead of forcing the tracker to stay at HIGH, which keeps Preybreaker behind unrelated UI like the map and panels while still rendering above the prey widget.

### Changed

- Clarified the bar-mode limitation: Blizzard only exposes prey hunt progress as the four Cold/Warm/Hot/Final states, so the bar intentionally steps 0 -> 34 -> 67 -> 100.
]]

local function ReadMarkdownFile()
    if type(io) ~= "table" or type(io.open) ~= "function" then
        return nil
    end

    local candidates = {
        "CHANGELOG.md",
        "./CHANGELOG.md",
        "../CHANGELOG.md",
        "..\\CHANGELOG.md",
    }

    for _, path in ipairs(candidates) do
        local handle = io.open(path, "r")
        if handle then
            local content = handle:read("*a")
            handle:close()
            if type(content) == "string" and content ~= "" then
                return content
            end
        end
    end

    return nil
end

local function GetMarkdownSource()
    local source = ns.ChangelogMarkdown
    if type(source) == "string" and source ~= "" then
        return source
    end

    source = ReadMarkdownFile()
    if type(source) == "string" and source ~= "" then
        return source
    end

    return FALLBACK_MARKDOWN
end

local function NormalizeMarkdown(markdown)
    if type(markdown) ~= "string" then
        return ""
    end

    return markdown:gsub("\r\n", "\n"):gsub("\r", "\n")
end

local function NewRelease(title, description)
    return {
        title = title,
        description = description,
        sections = {},
    }
end

local function NormalizeSectionName(rawName)
    if type(rawName) ~= "string" then
        return nil
    end

    local trimmed = rawName:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end

    return SECTION_NAME_BY_LOWER[LOWER(trimmed)]
end

local function ParseMarkdownChangelog(markdown)
    local releases = {}
    local currentRelease = nil
    local currentSection = nil

    local function CommitRelease()
        if not currentRelease then
            return
        end

        if type(currentRelease.title) == "string" and LOWER(currentRelease.title) == "unreleased" then
            return
        end

        releases[#releases + 1] = currentRelease
    end

    for line in NormalizeMarkdown(markdown):gmatch("[^\n]+") do
        local title, description = line:match(RELEASE_HEADER_PATTERN)
        if title then
            CommitRelease()
            currentRelease = NewRelease(title, description)
            currentSection = nil
        else
            local sectionName = NormalizeSectionName(line:match(SECTION_HEADER_PATTERN))
            if sectionName and currentRelease then
                currentSection = sectionName
                currentRelease.sections[currentSection] = currentRelease.sections[currentSection] or {}
            else
                local bullet = line:match(BULLET_PATTERN)
                if bullet and currentRelease and currentSection then
                    currentRelease.sections[currentSection][#currentRelease.sections[currentSection] + 1] = bullet
                end
            end
        end
    end

    CommitRelease()
    return releases
end

local function LoadReleases()
    return ParseMarkdownChangelog(GetMarkdownSource())
end

function ChangelogData:GetReleases()
    if not self.Releases then
        self.Releases = LoadReleases()
    end

    return self.Releases
end

function ChangelogData:GetVisibleReleases()
    local releases = self:GetReleases()
    local visible = {}

    for index = 1, math.min(4, #releases) do
        visible[#visible + 1] = releases[index]
    end

    return visible
end
