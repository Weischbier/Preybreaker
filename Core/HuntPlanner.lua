-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Hunt OS recommendation and reward-preview layer. It scores live hunts using
-- journal history and current player preferences without changing automation.

local _, ns = ...

ns.HuntPlanner = ns.HuntPlanner or {}

local HuntPlanner = ns.HuntPlanner

local DIFFICULTY_SCORE = {
    Nightmare = 30,
    Hard = 20,
    Normal = 10,
}

local REWARD_LABEL = {
    dawncrest = "Gear upgrade currency",
    remnant = "Remnant of Anguish",
    gold = "Gold",
    marl = "Voidlight Marl",
}

local function Lower(value)
    return type(value) == "string" and value:lower() or ""
end

local function GetRewardPatterns(rewardType)
    local hunt = ns.Constants and ns.Constants.Hunt or nil
    local patterns = hunt and hunt.RewardPatterns or nil
    return type(patterns) == "table" and patterns[rewardType] or nil
end

local function TextContainsAny(text, patterns)
    if ns.Util and type(ns.Util.TextContainsAny) == "function" then
        return ns.Util.TextContainsAny(text, patterns)
    end

    local lower = Lower(text)
    for _, pattern in ipairs(patterns or {}) do
        if lower:find(Lower(pattern), 1, true) then
            return true
        end
    end

    return false
end

local function ClassifyReward(reward)
    if type(reward) ~= "table" then
        return nil
    end

    local text = table.concat({
        tostring(reward.name or ""),
        tostring(reward.itemName or ""),
        tostring(reward.currencyName or ""),
    }, " ")

    for rewardType in pairs(REWARD_LABEL) do
        if TextContainsAny(text, GetRewardPatterns(rewardType)) then
            return rewardType
        end
    end

    return nil
end

local function IsRewardCapped(reward)
    if type(reward) ~= "table" then
        return false
    end

    return reward.isCapped == true or reward.capped == true or reward.currencyCapped == true
end

local function FindRewardByType(rewards, rewardType)
    for _, reward in ipairs(rewards or {}) do
        if ClassifyReward(reward) == rewardType then
            return reward
        end
    end

    return nil
end

local function GetPreferences(preferences)
    if type(preferences) == "table" then
        return preferences
    end
    if ns.Settings and type(ns.Settings.GetPlannerPreferences) == "function" then
        return ns.Settings:GetPlannerPreferences()
    end
    return { focus = "all", preferredDifficulty = "nightmare", rewardGoal = "preferred" }
end

local function GetPreferredReward()
    if ns.Settings and type(ns.Settings.GetPreferredHuntReward) == "function" then
        return ns.Settings:GetPreferredHuntReward()
    end
    return "remnant"
end

local function GetFallbackReward()
    if ns.Settings and type(ns.Settings.GetFallbackHuntReward) == "function" then
        return ns.Settings:GetFallbackHuntReward()
    end
    return "gold"
end

local function GetJournalFlags(hunt, history)
    if ns.HuntJournal and type(ns.HuntJournal.GetHuntFlags) == "function" then
        return ns.HuntJournal:GetHuntFlags(hunt)
    end

    local completed = false
    for _, entry in ipairs(history or {}) do
        if entry.questID == hunt.questID then
            completed = true
            break
        end
    end

    return {
        completed = completed,
        neverCompleted = not completed,
        achievementRelevant = hunt and hunt.achievement and hunt.achievement.isIncomplete == true or false,
    }
end

local function BuildReason(parts)
    if #parts == 0 then
        return "Balanced route"
    end
    return table.concat(parts, ", ")
end

function HuntPlanner:ClassifyReward(reward)
    return ClassifyReward(reward)
end

function HuntPlanner:GetRewardLabel(rewardType)
    return REWARD_LABEL[rewardType] or tostring(rewardType or "Reward")
end

function HuntPlanner:GetRewardPreview(hunt, preferences)
    local preferred = GetPreferredReward()
    local fallback = GetFallbackReward()
    local rewards = hunt and hunt.rewards or nil
    local preview = {
        preferredReward = preferred,
        fallbackReward = fallback,
        preferredLabel = self:GetRewardLabel(preferred),
        fallbackLabel = self:GetRewardLabel(fallback),
        status = "pending",
        reason = "Reward choices are not warmed yet.",
    }

    if type(rewards) ~= "table" or #rewards == 0 then
        return preview
    end

    local preferredReward = FindRewardByType(rewards, preferred)
    if preferredReward and not IsRewardCapped(preferredReward) then
        preview.status = "preferred"
        preview.selectedReward = preferredReward
        preview.selectedRewardType = preferred
        preview.selectedLabel = self:GetRewardLabel(preferred)
        preview.reason = "Preferred reward is available."
        return preview
    end

    local fallbackReward = FindRewardByType(rewards, fallback)
    if fallbackReward then
        preview.status = "fallback"
        preview.selectedReward = fallbackReward
        preview.selectedRewardType = fallback
        preview.selectedLabel = self:GetRewardLabel(fallback)
        preview.cappedPreferred = preferredReward and IsRewardCapped(preferredReward) or false
        preview.reason = preview.cappedPreferred and "Preferred reward is capped; fallback would be used." or "Preferred reward is missing; fallback would be used."
        return preview
    end

    preview.status = preferredReward and "capped" or "unmatched"
    preview.selectedReward = preferredReward or rewards[1]
    preview.selectedRewardType = preferredReward and preferred or ClassifyReward(rewards[1])
    preview.selectedLabel = self:GetRewardLabel(preview.selectedRewardType)
    preview.cappedPreferred = preferredReward and IsRewardCapped(preferredReward) or false
    preview.reason = preview.cappedPreferred and "Preferred reward appears capped and no fallback was found." or "No configured reward preference matched."
    return preview
end

function HuntPlanner:GetRecommendations(liveHunts, history, preferences)
    preferences = GetPreferences(preferences)
    liveHunts = type(liveHunts) == "table" and liveHunts or {}
    history = type(history) == "table" and history or {}

    local focus = preferences.focus or "all"
    local preferredDifficulty = preferences.preferredDifficulty or "nightmare"
    local rewardGoal = preferences.rewardGoal or "preferred"
    local recommendations = {}

    for _, hunt in ipairs(liveHunts) do
        local flags = GetJournalFlags(hunt, history)
        local rewardPreview = self:GetRewardPreview(hunt, preferences)
        local score = DIFFICULTY_SCORE[hunt.difficulty] or 0
        local reasons = {}
        local include = true

        if hunt.inProgress then
            score = score + 80
            reasons[#reasons + 1] = "active"
        end

        if flags.achievementRelevant then
            score = score + 65
            reasons[#reasons + 1] = "achievement gap"
        end

        if flags.neverCompleted then
            score = score + 25
            reasons[#reasons + 1] = "never completed"
        elseif flags.recent then
            score = score + 5
            reasons[#reasons + 1] = "known completion"
        end

        if Lower(hunt.difficulty) == preferredDifficulty then
            score = score + 20
            reasons[#reasons + 1] = "preferred difficulty"
        end

        if rewardPreview.status == "preferred" then
            score = score + 18
            reasons[#reasons + 1] = "preferred reward"
        elseif rewardPreview.status == "fallback" then
            score = score + 10
            reasons[#reasons + 1] = "fallback reward"
        end

        if focus == "nightmare" then
            include = hunt.difficulty == "Nightmare"
        elseif focus == "achievement" then
            include = flags.achievementRelevant == true
        elseif focus == "reward" then
            include = rewardPreview.status == "preferred" or rewardPreview.status == "fallback"
        elseif focus == "active" then
            include = hunt.inProgress == true
        end

        if rewardGoal ~= "preferred" and rewardPreview.selectedRewardType == rewardGoal then
            score = score + 12
        end

        if include then
            recommendations[#recommendations + 1] = {
                hunt = hunt,
                questID = hunt.questID,
                name = hunt.name,
                difficulty = hunt.difficulty,
                zone = hunt.zone,
                score = score,
                reason = BuildReason(reasons),
                rewardPreview = rewardPreview,
                journal = flags,
            }
        end
    end

    table.sort(recommendations, function(left, right)
        if left.score ~= right.score then
            return left.score > right.score
        end
        return (left.name or "") < (right.name or "")
    end)

    return recommendations
end
