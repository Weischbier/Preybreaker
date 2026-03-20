-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Static prey-target quest flag IDs and bestiary helpers.
-- Quest IDs sourced from the existing addon data set and the Plumber
-- reference addon. They were not re-verified in-game in this environment.
--
-- API sources checked:
--   warcraft.wiki.gg  C_QuestLog.IsQuestFlaggedCompleted,
--                     C_QuestLog.GetTitleForQuestID,
--                     C_MajorFactions.GetCurrentRenownLevel.

local _, ns = ...

local Util = ns.Util

ns.HuntData = {}

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
-- Bestiary queries
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
