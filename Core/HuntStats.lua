-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

ns.HuntStats = ns.HuntStats or {}

local HuntStats = ns.HuntStats

local function Increment(bucket, key)
    key = key or "Unknown"
    bucket[key] = (bucket[key] or 0) + 1
end

local function GetEntries(range)
    if ns.HuntJournal and type(ns.HuntJournal.GetEntries) == "function" then
        return ns.HuntJournal:GetEntries(range or "all")
    end

    return {}
end

function HuntStats:GetSummary(range)
    local entries = GetEntries(range)
    local summary = {
        total = #entries,
        byDifficulty = {},
        byZone = {},
        byReward = {},
        currentWeek = 0,
        recent = {},
    }

    local currentWeek = ns.HuntJournal and ns.HuntJournal.GetCurrentWeekKey and ns.HuntJournal:GetCurrentWeekKey() or nil

    for index, entry in ipairs(entries) do
        Increment(summary.byDifficulty, entry.difficulty)
        Increment(summary.byZone, entry.zone)

        local rewardType = entry.reward and entry.reward.rewardType or nil
        Increment(summary.byReward, rewardType or "unknown")

        if currentWeek and entry.weekKey == currentWeek then
            summary.currentWeek = summary.currentWeek + 1
        end

        if index <= 5 then
            summary.recent[#summary.recent + 1] = entry
        end
    end

    return summary
end

function HuntStats:BuildSummaryLines(range)
    local summary = self:GetSummary(range)
    local lines = {
        string.format("Total completions: %d", summary.total or 0),
        string.format("This week: %d", summary.currentWeek or 0),
    }

    local function AddBucket(title, bucket)
        lines[#lines + 1] = title .. ":"
        local hasEntries = false
        for key, count in pairs(bucket or {}) do
            hasEntries = true
            lines[#lines + 1] = string.format("- %s: %d", tostring(key), count)
        end
        if not hasEntries then
            lines[#lines + 1] = "- none"
        end
    end

    AddBucket("Difficulty", summary.byDifficulty)
    AddBucket("Reward", summary.byReward)
    return lines
end
