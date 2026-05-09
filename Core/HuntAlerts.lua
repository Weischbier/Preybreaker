-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

ns.HuntAlerts = ns.HuntAlerts or {}

local HuntAlerts = ns.HuntAlerts

local function Add(alerts, severity, title, detail)
    alerts[#alerts + 1] = {
        severity = severity,
        title = title,
        detail = detail,
    }
end

function HuntAlerts:BuildAlerts(roster, weeklyState, liveHunts)
    roster = type(roster) == "table" and roster or {}
    weeklyState = type(weeklyState) == "table" and weeklyState or {}
    liveHunts = type(liveHunts) == "table" and liveHunts or {}

    local alerts = {}
    local staleCount = 0
    local activeCount = 0
    for _, character in ipairs(roster) do
        if character.stale then staleCount = staleCount + 1 end
        if character.lastSnapshot and character.lastSnapshot.active then activeCount = activeCount + 1 end
    end

    if #roster == 0 then
        Add(alerts, "info", "Roster empty", "Log into a character once to seed account planning data.")
    end
    if staleCount > 0 then
        Add(alerts, "warning", "Stale characters", string.format("%d character profiles need a fresh weekly scan.", staleCount))
    end
    if weeklyState.liveListFresh == false then
        Add(alerts, "warning", "Weekly list stale", "Open the Adventure Map or run /pb huntrescan to rebuild live hunts.")
    end
    if activeCount > 0 then
        Add(alerts, "info", "Active hunts", string.format("%d character profiles have active hunt context.", activeCount))
    end

    local cappedCount = 0
    for _, hunt in ipairs(liveHunts) do
        local preview = hunt.rewardPreview or (ns.HuntPlanner and ns.HuntPlanner.GetRewardPreview and ns.HuntPlanner:GetRewardPreview(hunt)) or nil
        if preview and preview.status == "capped" then
            cappedCount = cappedCount + 1
        end
    end
    if cappedCount > 0 then
        Add(alerts, "warning", "Reward cap warning", string.format("%d live hunts may hit a capped preferred reward.", cappedCount))
    end

    if #alerts == 0 then
        Add(alerts, "ok", "Command Center ready", "Roster, live hunts, and weekly state look current.")
    end

    return alerts
end
