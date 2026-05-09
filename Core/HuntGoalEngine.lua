-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Account Command Center goal scoring. This is advisory only; it never
-- accepts, turns in, or otherwise automates Blizzard quest UI actions.

local _, ns = ...

ns.HuntGoalEngine = ns.HuntGoalEngine or {}

local HuntGoalEngine = ns.HuntGoalEngine

local DIFFICULTY_SCORE = {
    Nightmare = 30,
    Hard = 20,
    Normal = 10,
}

local function Lower(value)
    return type(value) == "string" and value:lower() or ""
end

local function GetWeeklyGoals()
    if ns.Settings and type(ns.Settings.GetWeeklyGoals) == "function" then
        return ns.Settings:GetWeeklyGoals()
    end
    return { pinned = {}, ignored = {}, completed = {} }
end

local function GetPreferences(preferences)
    if type(preferences) == "table" then
        return preferences
    end
    if ns.Settings and type(ns.Settings.GetGoalPreferences) == "function" then
        return ns.Settings:GetGoalPreferences()
    end
    return {
        focus = "balanced",
        preferredDifficulty = "nightmare",
        rewardGoal = "preferred",
        achievementWeight = 70,
        rewardWeight = 28,
        difficultyWeight = 20,
        altStaleWeight = 35,
        timeBudgetMinutes = 45,
    }
end

local function GetJournalFlags(hunt)
    if ns.HuntJournal and type(ns.HuntJournal.GetHuntFlags) == "function" then
        return ns.HuntJournal:GetHuntFlags(hunt)
    end
    return {
        achievementRelevant = hunt and hunt.achievement and hunt.achievement.isIncomplete == true,
        neverCompleted = true,
    }
end

local function GetRewardPreview(hunt)
    if ns.HuntPlanner and type(ns.HuntPlanner.GetRewardPreview) == "function" then
        return ns.HuntPlanner:GetRewardPreview(hunt)
    end
    return { status = "pending", reason = "Reward choices are not warmed yet." }
end

local function BuildReason(parts)
    if #parts == 0 then
        return "balanced account goal"
    end
    return table.concat(parts, ", ")
end

local function IsPinned(goalID)
    local goals = GetWeeklyGoals()
    return type(goals.pinned) == "table" and goals.pinned[goalID] == true
end

local function IsIgnored(goalID)
    local goals = GetWeeklyGoals()
    return type(goals.ignored) == "table" and goals.ignored[goalID] == true
end

local function IsCompleted(goalID)
    local goals = GetWeeklyGoals()
    return type(goals.completed) == "table" and goals.completed[goalID] == true
end

local function ApplyManualState(goal)
    if not goal or not goal.id then
        return nil
    end
    if IsIgnored(goal.id) then
        return nil
    end
    goal.pinned = IsPinned(goal.id)
    goal.completed = IsCompleted(goal.id)
    if goal.pinned then
        goal.score = (goal.score or 0) + 1000
        goal.reason = "pinned, " .. tostring(goal.reason or "account goal")
    end
    if goal.completed then
        goal.score = (goal.score or 0) - 500
    end
    return goal
end

local function BuildLiveHuntGoal(hunt, preferences)
    local flags = GetJournalFlags(hunt)
    local preview = GetRewardPreview(hunt)
    local score = DIFFICULTY_SCORE[hunt.difficulty] or 0
    local reasons = {}

    if hunt.inProgress then
        score = score + 85
        reasons[#reasons + 1] = "active hunt"
    end
    if flags.achievementRelevant then
        score = score + (preferences.achievementWeight or 70)
        reasons[#reasons + 1] = "achievement gap"
    end
    if flags.neverCompleted then
        score = score + 28
        reasons[#reasons + 1] = "never completed"
    end
    if Lower(hunt.difficulty) == preferences.preferredDifficulty then
        score = score + (preferences.difficultyWeight or 20)
        reasons[#reasons + 1] = "preferred difficulty"
    end
    if preview.status == "preferred" then
        score = score + (preferences.rewardWeight or 28)
        reasons[#reasons + 1] = "preferred reward"
    elseif preview.status == "fallback" then
        score = score + math.floor((preferences.rewardWeight or 28) * 0.65)
        reasons[#reasons + 1] = "fallback reward"
    elseif preview.status == "capped" then
        score = score - 15
        reasons[#reasons + 1] = "preferred reward capped"
    end

    if preferences.focus == "achievements" and flags.achievementRelevant then
        score = score + 30
    elseif preferences.focus == "rewards" and (preview.status == "preferred" or preview.status == "fallback") then
        score = score + 25
    elseif preferences.focus == "nightmare" and hunt.difficulty == "Nightmare" then
        score = score + 25
    end

    return ApplyManualState({
        id = "hunt:" .. tostring(hunt.questID or "unknown"),
        type = "hunt",
        title = hunt.name or "Unknown prey",
        detail = string.format("%s | %s", hunt.difficulty or "Unknown difficulty", hunt.zone or "Unknown zone"),
        meta = preview.reason or "Reward preview pending.",
        score = score,
        reason = BuildReason(reasons),
        hunt = hunt,
        rewardPreview = preview,
        journal = flags,
    })
end

local function BuildAltRefreshGoal(character, preferences)
    local score = preferences.altStaleWeight or 35
    local reasons = {}
    if character.stale then
        score = score + 40
        reasons[#reasons + 1] = character.staleReason or "stale character"
    end
    if character.lastSnapshot and character.lastSnapshot.active then
        score = score + 20
        reasons[#reasons + 1] = "active hunt snapshot"
    end
    if preferences.focus == "alts" then
        score = score + 35
    end

    return ApplyManualState({
        id = "refresh:" .. tostring(character.key or "unknown"),
        type = "character",
        title = string.format("Refresh %s", character.name or character.key or "character"),
        detail = string.format("%s | %s", character.realm or "Unknown realm", character.stale and "stale" or "fresh"),
        meta = character.lastSeenDate and ("Last seen " .. character.lastSeenDate) or "No recent roster timestamp.",
        score = score,
        reason = BuildReason(reasons),
        character = character,
    })
end

local function GetLiveHunts()
    if not (ns.HuntList and type(ns.HuntList.GetFilteredSortedHunts) == "function") then
        return {}
    end

    local previousFilter = ns.HuntList.GetDifficultyFilter and ns.HuntList:GetDifficultyFilter() or nil
    if ns.HuntList.SetDifficultyFilter then
        ns.HuntList:SetDifficultyFilter("All")
    end
    local hunts = ns.HuntList:GetFilteredSortedHunts() or {}
    if previousFilter and ns.HuntList.SetDifficultyFilter then
        ns.HuntList:SetDifficultyFilter(previousFilter)
    end
    return hunts
end

function HuntGoalEngine:SetPinned(goalID, pinned)
    local goals = GetWeeklyGoals()
    goals.pinned[goalID] = pinned == true or nil
end

function HuntGoalEngine:SetIgnored(goalID, ignored)
    local goals = GetWeeklyGoals()
    goals.ignored[goalID] = ignored == true or nil
end

function HuntGoalEngine:SetCompleted(goalID, completed)
    local goals = GetWeeklyGoals()
    goals.completed[goalID] = completed == true or nil
end

function HuntGoalEngine:GetWeeklyPlan(roster, liveHunts, preferences)
    preferences = GetPreferences(preferences)
    roster = type(roster) == "table" and roster or {}
    liveHunts = type(liveHunts) == "table" and liveHunts or {}

    local goals = {}
    for _, hunt in ipairs(liveHunts) do
        local goal = BuildLiveHuntGoal(hunt, preferences)
        if goal then
            goals[#goals + 1] = goal
        end
    end

    for _, character in ipairs(roster) do
        if character.stale or preferences.focus == "alts" then
            local goal = BuildAltRefreshGoal(character, preferences)
            if goal then
                goals[#goals + 1] = goal
            end
        end
    end

    table.sort(goals, function(left, right)
        if left.completed ~= right.completed then
            return left.completed ~= true
        end
        if (left.score or 0) ~= (right.score or 0) then
            return (left.score or 0) > (right.score or 0)
        end
        return tostring(left.title or "") < tostring(right.title or "")
    end)

    return goals
end

function HuntGoalEngine:GetNextBestAction(characterKey)
    local roster = ns.HuntRoster and ns.HuntRoster.GetCharacters and ns.HuntRoster:GetCharacters() or {}
    local goals = self:GetWeeklyPlan(roster, GetLiveHunts(), GetPreferences())
    if characterKey then
        for _, goal in ipairs(goals) do
            if goal.character and goal.character.key == characterKey then
                return goal
            end
        end
    end
    return goals[1]
end
