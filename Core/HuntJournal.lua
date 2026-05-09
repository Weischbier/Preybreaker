-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Character-scoped hunt completion history. Runtime hunt scans remain
-- live-first; this module only owns long-lived history and weekly markers.

local _, ns = ...

ns.HuntJournal = ns.HuntJournal or {}

local HuntJournal = ns.HuntJournal

local MAX_HISTORY_ENTRIES = 300
local SECONDS_PER_DAY = 86400
local WEDNESDAY_WDAY = 4 -- Lua date("*t").wday: Sunday=1

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

local function DateTable(timestamp)
    if type(date) == "function" then
        return date("*t", timestamp)
    end
    if os and type(os.date) == "function" then
        return os.date("*t", timestamp)
    end
    return nil
end

local function FormatWeekKey(timestamp)
    local current = DateTable(timestamp or GetNow())
    if type(current) ~= "table" then
        return "unknown"
    end

    local daysSinceReset = (current.wday - WEDNESDAY_WDAY) % 7
    local resetStart = (timestamp or GetNow()) - (daysSinceReset * SECONDS_PER_DAY)
    local resetDate = DateTable(resetStart)
    if type(resetDate) ~= "table" then
        return "unknown"
    end

    return string.format("%04d-W%03d", resetDate.year or 0, resetDate.yday or 0)
end

local function GetHistory()
    if not (ns.Settings and type(ns.Settings.GetHuntHistory) == "function") then
        return nil
    end

    return ns.Settings:GetHuntHistory()
end

local function GetWeeklyState()
    if not (ns.Settings and type(ns.Settings.GetWeeklyState) == "function") then
        return nil
    end

    return ns.Settings:GetWeeklyState()
end

local function NormalizeDifficulty(value)
    if type(value) ~= "string" then
        return nil
    end

    local lower = value:lower()
    if lower == "nightmare" then return "Nightmare" end
    if lower == "hard" then return "Hard" end
    if lower == "normal" then return "Normal" end
    return value
end

local function BuildCompletionKey(questID, weekKey)
    return string.format("%s:%s", tostring(weekKey or "unknown"), tostring(questID or "unknown"))
end

local function CopyRewardContext(context)
    if type(context) ~= "table" then
        return nil
    end

    return {
        rewardType = context.rewardType,
        rewardName = context.rewardName or (context.reward and context.reward.name) or nil,
        rewardIndex = context.rewardIndex or (context.reward and context.reward.rewardIndex) or nil,
        source = context.source,
        reason = context.reason,
        autoSelected = context.autoSelected == true,
    }
end

local function ResolveSnapshot(snapshotOrQuestID)
    if type(snapshotOrQuestID) == "table" then
        return snapshotOrQuestID
    end

    local questID = tonumber(snapshotOrQuestID)
    if not questID then
        return nil
    end

    local hunt = ns.HuntList and ns.HuntList.GetHuntByQuestID and ns.HuntList:GetHuntByQuestID(questID) or nil
    if type(hunt) == "table" then
        return hunt
    end

    return { questID = questID }
end

local function SortNewestFirst(history)
    table.sort(history, function(left, right)
        return (left.completedAt or 0) > (right.completedAt or 0)
    end)
end

function HuntJournal:GetCurrentWeekKey(timestamp)
    return FormatWeekKey(timestamp)
end

function HuntJournal:UpdateWeeklyState(source, timestamp)
    local state = GetWeeklyState()
    if type(state) ~= "table" then
        return nil
    end

    local now = timestamp or GetNow()
    local weekKey = self:GetCurrentWeekKey(now)
    if state.currentWeekKey ~= weekKey then
        state.previousWeekKey = state.currentWeekKey
        state.currentWeekKey = weekKey
        state.resetDetectedAt = now
        state.liveListFresh = false
    end

    state.lastResetCheckAt = now
    state.lastResetSource = source or "unknown"
    return state
end

function HuntJournal:MarkLiveListFresh(huntCount, source, timestamp)
    local state = self:UpdateWeeklyState(source or "liveScan", timestamp)
    if type(state) ~= "table" then
        return nil
    end

    state.liveListFresh = true
    state.lastScanWeekKey = state.currentWeekKey
    state.lastLiveScanAt = timestamp or GetNow()
    state.lastLiveCount = tonumber(huntCount) or 0
    return state
end

function HuntJournal:RecordRewardSelection(questID, rewardContext)
    questID = tonumber(questID)
    if not questID then
        return false
    end

    local charDB = ns.Settings and ns.Settings.GetCharDB and ns.Settings:GetCharDB() or nil
    if type(charDB) ~= "table" then
        return false
    end

    if type(charDB.huntRewardSelections) ~= "table" then
        charDB.huntRewardSelections = {}
    end

    charDB.huntRewardSelections[questID] = CopyRewardContext(rewardContext) or { source = "unknown" }
    return true
end

function HuntJournal:PopRewardSelection(questID)
    questID = tonumber(questID)
    if not questID then
        return nil
    end

    local charDB = ns.Settings and ns.Settings.GetCharDB and ns.Settings:GetCharDB() or nil
    local selections = type(charDB) == "table" and charDB.huntRewardSelections or nil
    if type(selections) ~= "table" then
        return nil
    end

    local selection = selections[questID]
    selections[questID] = nil
    return selection
end

function HuntJournal:RecordCompletion(snapshotOrQuestID, rewardContext)
    local snapshot = ResolveSnapshot(snapshotOrQuestID)
    local questID = snapshot and tonumber(snapshot.questID or snapshot.activeQuestID or snapshot.worldQuestID) or nil
    if not questID then
        return false
    end

    local history = GetHistory()
    if type(history) ~= "table" then
        return false
    end

    local now = GetNow()
    local weekKey = self:GetCurrentWeekKey(now)
    local completionKey = BuildCompletionKey(questID, weekKey)
    local storedReward = self:PopRewardSelection(questID)
    local reward = CopyRewardContext(rewardContext) or storedReward
    local entry = nil

    for _, existing in ipairs(history) do
        if existing.completionKey == completionKey then
            entry = existing
            break
        end
    end

    if not entry then
        entry = {}
        history[#history + 1] = entry
    end

    entry.completionKey = completionKey
    entry.questID = questID
    entry.name = snapshot.name or snapshot.title or string.format("Quest %d", questID)
    entry.difficulty = NormalizeDifficulty(snapshot.difficulty) or "Normal"
    entry.zone = snapshot.zone
    entry.completedAt = now
    entry.completedDate = FormatDate(now)
    entry.weekKey = weekKey
    entry.status = "completed"
    entry.reward = reward

    SortNewestFirst(history)
    self:Prune(MAX_HISTORY_ENTRIES)
    self:UpdateWeeklyState("completion", now)
    return true, entry
end

function HuntJournal:Prune(maxEntries)
    local history = GetHistory()
    if type(history) ~= "table" then
        return 0
    end

    maxEntries = tonumber(maxEntries) or MAX_HISTORY_ENTRIES
    SortNewestFirst(history)

    local removed = 0
    for index = #history, maxEntries + 1, -1 do
        table.remove(history, index)
        removed = removed + 1
    end

    return removed
end

function HuntJournal:GetEntries(filter)
    local history = GetHistory()
    if type(history) ~= "table" then
        return {}
    end

    local filterType = type(filter) == "string" and filter or (type(filter) == "table" and filter.type or "all")
    local zone = type(filter) == "table" and filter.zone or nil
    local rewardType = type(filter) == "table" and filter.rewardType or nil
    local currentWeek = self:GetCurrentWeekKey()
    local entries = {}

    for _, entry in ipairs(history) do
        local include = true
        local difficulty = entry.difficulty and entry.difficulty:lower() or nil
        if filterType == "week" then
            include = entry.weekKey == currentWeek
        elseif filterType == "nightmare" or filterType == "hard" or filterType == "normal" then
            include = difficulty == filterType
        elseif filterType == "reward" then
            include = entry.reward ~= nil
        end

        if include and zone and entry.zone ~= zone then
            include = false
        end
        if include and rewardType and (not entry.reward or entry.reward.rewardType ~= rewardType) then
            include = false
        end

        if include then
            entries[#entries + 1] = entry
        end
    end

    SortNewestFirst(entries)
    return entries
end

function HuntJournal:GetRecentByQuestID(questID)
    questID = tonumber(questID)
    if not questID then
        return nil
    end

    for _, entry in ipairs(self:GetEntries("all")) do
        if entry.questID == questID then
            return entry
        end
    end

    return nil
end

function HuntJournal:HasCompletedQuest(questID)
    return self:GetRecentByQuestID(questID) ~= nil
end

function HuntJournal:GetHuntFlags(hunt)
    local questID = hunt and hunt.questID or nil
    local recent = self:GetRecentByQuestID(questID)
    local completed = recent ~= nil
    local achievementRelevant = hunt and hunt.achievement and hunt.achievement.isIncomplete == true or false
    return {
        completed = completed,
        neverCompleted = not completed,
        recent = recent,
        achievementRelevant = achievementRelevant,
    }
end
