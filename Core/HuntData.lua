-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Static prey-target quest flag IDs plus achievement helpers.
-- Quest IDs sourced from the existing addon data set and the Plumber
-- reference addon. They were not re-verified in-game in this environment.
--
-- API sources checked:
--   warcraft.wiki.gg  GetAchievementInfo,
--                     GetAchievementNumCriteria,
--                     GetAchievementCriteriaInfo,
--                     C_QuestLog.IsQuestFlaggedCompleted,
--                     C_MajorFactions.GetCurrentRenownLevel.
--   BlizzardInterfaceCode APIDocumentationGenerated/QuestLogDocumentation.lua.
--
-- Full bestiary achievement IDs verified against live Retail sources:
--   42701 Prey: Normal Mode III
--   42702 Prey: Hard Mode III
--   42703 Prey: Nightmare Mode III

local _, ns = ...

local Util = ns.Util

ns.HuntData = {}

local bestiaryAchievementStatus = nil
local bestiaryAchievementStatusDirty = true
local bestiaryCriteriaStatus = nil
local bestiaryCriteriaStatusDirty = true

local FullBestiaryAchievementIDs = {
    Normal = 42701,
    Hard = 42702,
    Nightmare = 42703,
}

-- ---------------------------------------------------------------------------
-- Prey target flag quest IDs by difficulty.
-- Each quest flag is marked complete when a specific prey is killed on that
-- difficulty. The achievement progress tracks unique completions.
-- ---------------------------------------------------------------------------
local PreyTargetQuests = {
    Normal = {},
    Hard = {},
    Nightmare = {},
}

local function AddQuestsByPattern(tbl, fromID, step, count)
    local n = #tbl
    local questID = fromID - step
    for _ = 1, count do
        questID = questID + step
        n = n + 1
        tbl[n] = questID
    end
end

-- Normal: 30 consecutive IDs 91095–91124
AddQuestsByPattern(PreyTargetQuests.Normal, 91095, 1, 30)

-- Hard: 16 even IDs 91210–91240 then 14 consecutive 91242–91255
AddQuestsByPattern(PreyTargetQuests.Hard, 91210, 2, 16)
AddQuestsByPattern(PreyTargetQuests.Hard, 91242, 1, 14)

-- Nightmare: 16 odd IDs 91211–91241 then 14 consecutive 91256–91269
AddQuestsByPattern(PreyTargetQuests.Nightmare, 91211, 2, 16)
AddQuestsByPattern(PreyTargetQuests.Nightmare, 91256, 1, 14)

ns.HuntData.PreyTargetQuests = PreyTargetQuests

-- Prey world quest IDs (the active trackable quests on the map).
-- Sourced from C_QuestLine.GetQuestLineQuests(5954) via Plumber.
ns.HuntData.PreyWorldQuests = {
    91458, 91523, 91590, 91591, 91592, 91594,
    91595, 91596, 91207, 91601, 91602, 91604,
}

-- Difficulty display order.
ns.HuntData.DifficultyOrder = { "Normal", "Hard", "Nightmare" }

-- ---------------------------------------------------------------------------
-- Renown gating
-- ---------------------------------------------------------------------------
local function GetRenownLevel()
    local hunt = ns.Constants and ns.Constants.Hunt
    if not hunt or not hunt.RenownFactionID then
        return 0
    end

    if type(C_MajorFactions) ~= "table" or type(C_MajorFactions.GetCurrentRenownLevel) ~= "function" then
        return 0
    end

    return Util.SafeCall(C_MajorFactions.GetCurrentRenownLevel, hunt.RenownFactionID) or 0
end

function ns.HuntData:GetUnlockedDifficulties()
    local hunt = ns.Constants and ns.Constants.Hunt
    if not hunt then
        return { "Normal" }
    end

    local level = GetRenownLevel()
    if level >= (hunt.RenownNightmareThreshold or 4) then
        return { "Normal", "Hard", "Nightmare" }
    elseif level >= (hunt.RenownHardThreshold or 1) then
        return { "Normal", "Hard" }
    end

    return { "Normal" }
end

function ns.HuntData:IsDifficultyUnlocked(difficulty)
    for _, d in ipairs(self:GetUnlockedDifficulties()) do
        if d == difficulty then
            return true
        end
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Bestiary and achievement queries
-- ---------------------------------------------------------------------------
local function IsQuestFlaggedCompleted(questID)
    if type(C_QuestLog) ~= "table" or type(C_QuestLog.IsQuestFlaggedCompleted) ~= "function" then
        return false
    end

    return Util.SafeCall(C_QuestLog.IsQuestFlaggedCompleted, questID) == true
end

local function GetQuestName(questID)
    if type(C_QuestLog) ~= "table" or type(C_QuestLog.GetTitleForQuestID) ~= "function" then
        return nil
    end

    return Util.SafeCall(C_QuestLog.GetTitleForQuestID, questID)
end

local function TrimText(text)
    if type(text) ~= "string" then
        return ""
    end

    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function NormalizeAchievementTargetName(text)
    if type(text) ~= "string" then
        return nil
    end

    local normalized = strlower(text)
    normalized = normalized:gsub("^%s*prey:%s*", "")
    normalized = normalized:gsub("%s*%([^)]*%)%s*$", "")
    normalized = normalized:gsub("[%c%p]", " ")
    normalized = normalized:gsub("%s+", " ")
    normalized = TrimText(normalized)

    if normalized == "" then
        return nil
    end

    return normalized
end

local function SafeCallMulti(func, ...)
    if type(func) ~= "function" then
        return nil
    end

    local ok, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15 = pcall(func, ...)
    if ok then
        return r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
    end

    if ns.Debug and type(ns.Debug.Log) == "function" and type(ns.Debug.KV) == "function" then
        ns.Debug:Log("error", ns.Debug:KV("source", "HuntData.SafeCallMulti"), ns.Debug:KV("err", tostring(r1)))
    end

    return nil
end

local function BuildBestiaryAchievementStatus()
    if bestiaryAchievementStatus and not bestiaryAchievementStatusDirty then
        return bestiaryAchievementStatus
    end

    local status = {}
    for difficulty, achievementID in pairs(FullBestiaryAchievementIDs) do
        local id, name, _, completed, _, _, _, description, _, icon, _, _, _, _, isStatistic = SafeCallMulti(GetAchievementInfo, achievementID)
        if id and not isStatistic then
            status[difficulty] = {
                achievementID = id,
                name = name,
                description = description,
                icon = icon,
                completed = completed == true,
            }
        end
    end

    bestiaryAchievementStatus = status
    bestiaryAchievementStatusDirty = false
    return bestiaryAchievementStatus
end

local function BuildBestiaryCriteriaStatus()
    if bestiaryCriteriaStatus and not bestiaryCriteriaStatusDirty then
        return bestiaryCriteriaStatus
    end

    local status = {}
    for difficulty, achievementID in pairs(FullBestiaryAchievementIDs) do
        local criteriaByName = {}
        local numCriteria = type(GetAchievementNumCriteria) == "function"
            and Util.SafeCall(GetAchievementNumCriteria, achievementID)
            or 0

        if type(numCriteria) == "number" and numCriteria > 0 then
            for criteriaIndex = 1, numCriteria do
                local criteriaString, _, completed = SafeCallMulti(GetAchievementCriteriaInfo, achievementID, criteriaIndex)
                local normalizedName = NormalizeAchievementTargetName(criteriaString)
                if normalizedName then
                    criteriaByName[normalizedName] = completed == true
                end
            end
        end

        status[difficulty] = criteriaByName
    end

    bestiaryCriteriaStatus = status
    bestiaryCriteriaStatusDirty = false
    return bestiaryCriteriaStatus
end

function ns.HuntData:InvalidateAchievementCache()
    bestiaryAchievementStatus = nil
    bestiaryAchievementStatusDirty = true
    bestiaryCriteriaStatus = nil
    bestiaryCriteriaStatusDirty = true
end

function ns.HuntData:GetHuntAchievementStatus(huntName, difficulty)
    local achievement = difficulty and BuildBestiaryAchievementStatus()[difficulty] or nil
    if not achievement or achievement.completed then
        return nil
    end

    local normalizedName = NormalizeAchievementTargetName(huntName)
    local criteriaByName = difficulty and BuildBestiaryCriteriaStatus()[difficulty] or nil
    if not normalizedName or not criteriaByName then
        return nil
    end

    local criteriaCompleted = criteriaByName[normalizedName]
    if criteriaCompleted == nil then
        return nil
    end

    if criteriaCompleted == true then
        return nil
    end

    return {
        achievementID = achievement.achievementID,
        name = achievement.name,
        icon = achievement.icon,
        description = achievement.description,
        isIncomplete = true,
        source = "achievementCriteria",
    }
end

function ns.HuntData:GetCompletionCount(difficulty)
    local quests = PreyTargetQuests[difficulty]
    if not quests then
        return 0, 0
    end

    local completed = 0
    for _, questID in ipairs(quests) do
        if IsQuestFlaggedCompleted(questID) then
            completed = completed + 1
        end
    end

    return completed, #quests
end

function ns.HuntData:GetBestiary(difficulty)
    local quests = PreyTargetQuests[difficulty]
    if not quests then
        return {}
    end

    local entries = {}
    for _, questID in ipairs(quests) do
        local name = GetQuestName(questID)
        local completed = IsQuestFlaggedCompleted(questID)
        entries[#entries + 1] = {
            questID = questID,
            name = name,
            completed = completed,
        }
    end

    return entries
end

function ns.HuntData:GetFullBestiary()
    local result = {}
    for _, difficulty in ipairs(self.DifficultyOrder) do
        local completed, total = self:GetCompletionCount(difficulty)
        result[#result + 1] = {
            difficulty = difficulty,
            unlocked = self:IsDifficultyUnlocked(difficulty),
            completed = completed,
            total = total,
            entries = self:GetBestiary(difficulty),
        }
    end

    return result
end
