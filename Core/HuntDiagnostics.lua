-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

ns.HuntDiagnostics = ns.HuntDiagnostics or {}

local HuntDiagnostics = ns.HuntDiagnostics

local function BoolText(value)
    return value and "yes" or "no"
end

local function GetNowText()
    if type(date) == "function" then
        return date("%Y-%m-%d %H:%M:%S")
    end
    if os and type(os.date) == "function" then
        return os.date("%Y-%m-%d %H:%M:%S")
    end
    return "unknown"
end

local function GetHuntSnapshot()
    if ns.HuntList and type(ns.HuntList.GetDiagnosticsSnapshot) == "function" then
        return ns.HuntList:GetDiagnosticsSnapshot()
    end

    return {}
end

local function GetWeeklyState()
    if ns.Settings and type(ns.Settings.GetWeeklyState) == "function" then
        return ns.Settings:GetWeeklyState()
    end
    return {}
end

function HuntDiagnostics:BuildReport()
    local hunt = GetHuntSnapshot()
    local weekly = GetWeeklyState() or {}
    local rosterSummary = ns.HuntRoster and ns.HuntRoster.GetSummary and ns.HuntRoster:GetSummary() or {}
    local preferences = ns.Settings and ns.Settings.GetGoalPreferences and ns.Settings:GetGoalPreferences() or {}
    local accountDB = ns.Settings and ns.Settings.GetAccountDB and ns.Settings:GetAccountDB() or nil
    local lines = {
        "Preybreaker Hunt OS diagnostics",
        "Generated: " .. GetNowText(),
        string.format("SavedVariables schema: %s", tostring(accountDB and accountDB.schemaVersion or "unknown")),
        string.format("Command data version: %s", tostring(accountDB and accountDB.commandCenterVersion or "unknown")),
        string.format("Live snapshot ready: %s", BoolText(hunt.liveSnapshotReady)),
        string.format("Live snapshot dirty: %s", BoolText(hunt.liveSnapshotDirty)),
        string.format("Hunt source: %s", tostring(hunt.huntsSource or "unknown")),
        string.format("Runtime hunts: %d", tonumber(hunt.huntCount) or 0),
        string.format("Saved cache entries: %d", tonumber(hunt.cacheCount) or 0),
        string.format("Cache version: %s", tostring(hunt.cacheVersion or "unknown")),
        string.format("Scan active: %s", BoolText(hunt.scanning)),
        string.format("Warmup active: %s", BoolText(hunt.warming)),
        string.format("Map visible: %s", BoolText(hunt.mapVisible)),
        string.format("Last live scan: %s", tostring(hunt.lastLiveScanAt or "none")),
        string.format("Weekly key: %s", tostring(weekly.currentWeekKey or "unknown")),
        string.format("Last reset check: %s", tostring(weekly.lastResetCheckAt or "none")),
        string.format("Weekly live list fresh: %s", BoolText(weekly.liveListFresh)),
        string.format("Roster characters: %d", tonumber(rosterSummary.characterCount) or 0),
        string.format("Roster stale characters: %d", tonumber(rosterSummary.staleCount) or 0),
        string.format("Roster active hunts: %d", tonumber(rosterSummary.activeCount) or 0),
        string.format("Goal focus: %s", tostring(preferences.focus or "balanced")),
        string.format("Goal preferred difficulty: %s", tostring(preferences.preferredDifficulty or "nightmare")),
    }

    return {
        generatedAt = GetNowText(),
        hunt = hunt,
        weekly = weekly,
        roster = rosterSummary,
        goalPreferences = preferences,
        lines = lines,
    }
end
