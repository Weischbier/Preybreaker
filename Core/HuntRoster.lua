-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Account-local roster for Hunt Command Center. Offline character records are
-- planning context only; they are never treated as live map data.

local _, ns = ...

ns.HuntRoster = ns.HuntRoster or {}

local HuntRoster = ns.HuntRoster

local STALE_AFTER_SECONDS = 7 * 86400
local MAX_RECENT_COMPLETIONS = 12

local function GetNow()
    if type(time) == "function" then
        return time()
    end
    if os and type(os.time) == "function" then
        return os.time()
    end
    return 0
end

local function FormatDate(timestamp)
    if type(date) == "function" then
        return date("%Y-%m-%d %H:%M", timestamp or GetNow())
    end
    if os and type(os.date) == "function" then
        return os.date("%Y-%m-%d %H:%M", timestamp or GetNow())
    end
    return tostring(timestamp or GetNow())
end

local function SafeCall(func, ...)
    if ns.Util and type(ns.Util.SafeCall) == "function" then
        return ns.Util.SafeCall(func, ...)
    end
    if type(func) ~= "function" then
        return nil
    end
    local ok, value, value2 = pcall(func, ...)
    if ok then
        return value, value2
    end
    return nil
end

local function GetPlayerIdentity()
    local name, realm
    if type(UnitFullName) == "function" then
        name, realm = SafeCall(UnitFullName, "player")
    end
    if (not name or name == "") and type(UnitName) == "function" then
        local unitName, unitRealm = SafeCall(UnitName, "player")
        name = unitName or name
        realm = realm or unitRealm
    end
    if not realm or realm == "" then
        realm = type(GetRealmName) == "function" and SafeCall(GetRealmName) or "Unknown Realm"
    end
    if not realm or realm == "" then
        realm = "Unknown Realm"
    end
    if not name or name == "" then
        name = "Unknown"
    end

    return {
        name = name,
        realm = realm,
        key = string.format("%s:%s", realm, name),
        guid = type(UnitGUID) == "function" and SafeCall(UnitGUID, "player") or nil,
    }
end

local function CopySnapshot(snapshot)
    if type(snapshot) ~= "table" then
        return { active = false }
    end

    return {
        active = snapshot.active == true,
        questID = snapshot.questID or snapshot.activeQuestID or snapshot.worldQuestID,
        activeQuestID = snapshot.activeQuestID,
        worldQuestID = snapshot.worldQuestID,
        progressState = snapshot.progressState,
        progress = snapshot.progress,
        percent = snapshot.percent,
        mapID = snapshot.mapID,
    }
end

local function CopyRecentCompletions()
    if not (ns.HuntJournal and type(ns.HuntJournal.GetEntries) == "function") then
        return {}
    end

    local entries = ns.HuntJournal:GetEntries("all")
    local copy = {}
    for index, entry in ipairs(entries or {}) do
        if index > MAX_RECENT_COMPLETIONS then
            break
        end
        copy[#copy + 1] = {
            questID = entry.questID,
            name = entry.name,
            difficulty = entry.difficulty,
            zone = entry.zone,
            completedAt = entry.completedAt,
            completedDate = entry.completedDate,
            weekKey = entry.weekKey,
            reward = entry.reward,
        }
    end
    return copy
end

local function GetCurrentWeekKey()
    if ns.HuntJournal and type(ns.HuntJournal.GetCurrentWeekKey) == "function" then
        return ns.HuntJournal:GetCurrentWeekKey()
    end
    return "unknown"
end

local function CountCurrentWeekCompletions()
    if ns.HuntJournal and type(ns.HuntJournal.GetEntries) == "function" then
        return #(ns.HuntJournal:GetEntries("week") or {})
    end
    return 0
end

local function CountHistory()
    if ns.HuntJournal and type(ns.HuntJournal.GetEntries) == "function" then
        return #(ns.HuntJournal:GetEntries("all") or {})
    end
    return 0
end

local function GetActiveHunt(snapshot)
    local questID = snapshot and snapshot.questID or nil
    if not questID then
        return nil
    end
    if ns.HuntList and type(ns.HuntList.GetHuntByQuestID) == "function" then
        local hunt = ns.HuntList:GetHuntByQuestID(questID)
        if type(hunt) == "table" then
            return {
                questID = hunt.questID,
                name = hunt.name,
                difficulty = hunt.difficulty,
                zone = hunt.zone,
            }
        end
    end
    return { questID = questID }
end

local function IsEntryStale(entry, now, currentWeekKey)
    if type(entry) ~= "table" then
        return true
    end
    if entry.weekKey ~= currentWeekKey then
        return true
    end
    local lastSeenAt = tonumber(entry.lastSeenAt) or 0
    return lastSeenAt <= 0 or ((now or GetNow()) - lastSeenAt) > STALE_AFTER_SECONDS
end

function HuntRoster:GetCurrentCharacterKey()
    return GetPlayerIdentity().key
end

function HuntRoster:UpdateCurrentCharacter(snapshot)
    if not (ns.Settings and type(ns.Settings.GetAccountRoster) == "function") then
        return nil
    end

    local roster = ns.Settings:GetAccountRoster()
    if type(roster) ~= "table" then
        return nil
    end

    local now = GetNow()
    local identity = GetPlayerIdentity()
    local snapshotCopy = CopySnapshot(snapshot)
    local entry = roster[identity.key]
    if type(entry) ~= "table" then
        entry = {}
        roster[identity.key] = entry
    end

    entry.key = identity.key
    entry.name = identity.name
    entry.realm = identity.realm
    entry.guid = identity.guid or entry.guid
    entry.lastLoginAt = entry.lastLoginAt or now
    entry.lastSeenAt = now
    entry.lastSeenDate = FormatDate(now)
    entry.weekKey = GetCurrentWeekKey()
    entry.lastSnapshot = snapshotCopy
    entry.activeHunt = GetActiveHunt(snapshotCopy)
    entry.completedThisWeek = CountCurrentWeekCompletions()
    entry.historyTotal = CountHistory()
    entry.recentCompletions = CopyRecentCompletions()
    entry.stale = false

    return entry
end

function HuntRoster:GetCharacters()
    local roster = ns.Settings and ns.Settings.GetAccountRoster and ns.Settings:GetAccountRoster() or nil
    if type(roster) ~= "table" then
        return {}
    end

    local now = GetNow()
    local currentWeekKey = GetCurrentWeekKey()
    local weeklyGoals = ns.Settings and ns.Settings.GetWeeklyGoals and ns.Settings:GetWeeklyGoals() or nil
    if type(weeklyGoals) == "table" then
        weeklyGoals.resetMarker = currentWeekKey
        if type(weeklyGoals.staleCharacters) ~= "table" then
            weeklyGoals.staleCharacters = {}
        end
    end
    local characters = {}
    for key, entry in pairs(roster) do
        if type(entry) == "table" then
            entry.key = entry.key or key
            entry.stale = IsEntryStale(entry, now, currentWeekKey)
            entry.staleReason = entry.weekKey ~= currentWeekKey and "weekly reset" or (entry.stale and "not seen recently" or nil)
            if type(weeklyGoals) == "table" then
                weeklyGoals.staleCharacters[entry.key] = entry.stale or nil
            end
            characters[#characters + 1] = entry
        end
    end

    table.sort(characters, function(left, right)
        local leftSeen = tonumber(left.lastSeenAt) or 0
        local rightSeen = tonumber(right.lastSeenAt) or 0
        if leftSeen ~= rightSeen then
            return leftSeen > rightSeen
        end
        return tostring(left.key or "") < tostring(right.key or "")
    end)

    return characters
end

function HuntRoster:GetAccountHistory()
    local history = {}
    for _, character in ipairs(self:GetCharacters()) do
        for _, entry in ipairs(character.recentCompletions or {}) do
            history[#history + 1] = {
                characterKey = character.key,
                characterName = character.name,
                realm = character.realm,
                questID = entry.questID,
                name = entry.name,
                difficulty = entry.difficulty,
                zone = entry.zone,
                completedAt = entry.completedAt,
                completedDate = entry.completedDate,
                weekKey = entry.weekKey,
                reward = entry.reward,
            }
        end
    end

    table.sort(history, function(left, right)
        return (tonumber(left.completedAt) or 0) > (tonumber(right.completedAt) or 0)
    end)
    return history
end

function HuntRoster:GetSummary()
    local characters = self:GetCharacters()
    local staleCount = 0
    local activeCount = 0
    local weeklyCompletions = 0
    for _, character in ipairs(characters) do
        if character.stale then staleCount = staleCount + 1 end
        if character.lastSnapshot and character.lastSnapshot.active then activeCount = activeCount + 1 end
        weeklyCompletions = weeklyCompletions + (tonumber(character.completedThisWeek) or 0)
    end

    return {
        characterCount = #characters,
        staleCount = staleCount,
        activeCount = activeCount,
        weeklyCompletions = weeklyCompletions,
    }
end
