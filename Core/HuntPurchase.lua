-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Util = ns.Util

ns.HuntPurchase = {}
local LearnedSelection = {
    questIDByDifficulty = {},
    optionIDByDifficulty = {},
}

local function LogHunt(action, detail, extra)
    if not (ns.Debug and type(ns.Debug.Log) == "function" and type(ns.Debug.KV) == "function") then
        return
    end

    ns.Debug:Log(
        "hunt",
        ns.Debug:KV("action", action),
        ns.Debug:KV("detail", detail),
        ns.Debug:KV("extra", extra)
    )
end

local function IsTargetAstalor()
    if type(UnitGUID) ~= "function" then
        return false
    end

    local guid = UnitGUID("npc")
    return Util.ExtractNPCIDFromGUID(guid) == ns.Constants.Hunt.AstalorNpcID
end

local function GetRemnantQuantity()
    if type(C_CurrencyInfo) ~= "table" or type(C_CurrencyInfo.GetCurrencyInfo) ~= "function" then
        return 0
    end

    local info = Util.SafeCall(C_CurrencyInfo.GetCurrencyInfo, ns.Constants.Hunt.RemnantCurrencyID)
    return info and info.quantity or 0
end

local function CanAffordHunt()
    local settings = ns.Settings
    if not settings then
        return false
    end

    local threshold = settings:GetRemnantThreshold()
    return GetRemnantQuantity() >= (threshold + ns.Constants.Hunt.Cost)
end

local TextContainsAny = Util.TextContainsAny

local function GetQuestInfoText(info)
    if type(info) ~= "table" then
        return ""
    end

    return info.title or info.name or info.questName or ""
end

local function GetQuestPatterns(difficulty)
    local hunt = ns.Constants and ns.Constants.Hunt
    if not hunt then
        return nil, nil
    end

    local difficultyPatterns = nil
    if hunt.DifficultyPatterns then
        difficultyPatterns = hunt.DifficultyPatterns[difficulty] or hunt.DifficultyPatterns.normal
    end

    return difficultyPatterns, hunt.RandomPatterns
end

local function ScoreAvailableQuest(info, difficulty)
    if type(info) ~= "table" or not info.questID then
        return nil
    end

    local title = GetQuestInfoText(info)
    local difficultyPatterns, randomPatterns = GetQuestPatterns(difficulty)
    local matchesDifficulty = TextContainsAny(title, difficultyPatterns)
    local matchesRandom = TextContainsAny(title, randomPatterns)

    if matchesDifficulty and matchesRandom then
        return 3
    end
    if matchesDifficulty then
        return 2
    end
    if matchesRandom then
        return 1
    end

    return nil
end

local function ChooseBestAvailableQuest(availableQuests, difficulty)
    local learnedQuestID = LearnedSelection.questIDByDifficulty[difficulty]
    if learnedQuestID then
        for _, info in ipairs(availableQuests or {}) do
            if info.questID == learnedQuestID then
                return info, "learnedQuestID"
            end
        end
    end

    local bestInfo = nil
    local bestScore = 0

    for _, info in ipairs(availableQuests or {}) do
        local score = ScoreAvailableQuest(info, difficulty)
        if score and score > bestScore then
            bestScore = score
            bestInfo = info
        end
    end

    if bestInfo then
        return bestInfo, "patternAvailableQuest"
    end

    if type(availableQuests) == "table" and #availableQuests == 1 then
        return availableQuests[1], "singleAvailableQuest"
    end

    return nil, nil
end

local function SelectGossipOption(option)
    if type(C_GossipInfo) ~= "table" then
        return false
    end

    if option.gossipOptionID and type(C_GossipInfo.SelectOption) == "function" then
        C_GossipInfo.SelectOption(option.gossipOptionID, "", true)
        LogHunt("selectOption", option.gossipOptionID, option.name)
        return true
    end

    if option.orderIndex and type(C_GossipInfo.SelectOptionByIndex) == "function" then
        C_GossipInfo.SelectOptionByIndex(option.orderIndex, "", true)
        LogHunt("selectByIndex", option.orderIndex, option.name)
        return true
    end

    LogHunt("blocked", "noOptionID", option.name)
    return false
end

local function GetBestGossipOption(options, difficulty)
    local learnedOptionID = LearnedSelection.optionIDByDifficulty[difficulty]
    if learnedOptionID then
        for _, option in ipairs(options or {}) do
            if option.gossipOptionID == learnedOptionID or option.orderIndex == learnedOptionID then
                return option, "learnedOptionID"
            end
        end
    end

    if type(options) == "table" and #options == 1 then
        return options[1], "singleOption"
    end

    local hunt = ns.Constants.Hunt
    local diffPatterns = nil
    if hunt.DifficultyPatterns then
        diffPatterns = hunt.DifficultyPatterns[difficulty] or hunt.DifficultyPatterns.normal
    end
    local randomPatterns = hunt.RandomPatterns

    for _, option in ipairs(options or {}) do
        if TextContainsAny(option.name, diffPatterns) and TextContainsAny(option.name, randomPatterns) then
            return option, "patternDifficultyAndRandom"
        end
    end

    for _, option in ipairs(options or {}) do
        if TextContainsAny(option.name, diffPatterns) then
            return option, "patternDifficulty"
        end
    end

    for _, option in ipairs(options or {}) do
        if TextContainsAny(option.name, randomPatterns) then
            return option, "patternRandom"
        end
    end

    if type(options) == "table" and #options >= 2 then
        local ordered = {}
        for _, option in ipairs(options) do
            ordered[#ordered + 1] = option
        end

        table.sort(ordered, function(left, right)
            local leftOrder = left.orderIndex or left.gossipOptionID or 0
            local rightOrder = right.orderIndex or right.gossipOptionID or 0
            return leftOrder < rightOrder
        end)

        local targetRank = 1
        if difficulty == "hard" then
            targetRank = 2
        elseif difficulty == "nightmare" then
            targetRank = 3
        end

        local selectedIndex = math.max(1, math.min(targetRank, #ordered))
        return ordered[selectedIndex], "orderedFallback"
    end

    return nil, nil
end

local function SafeGetAvailableQuests()
    if type(C_GossipInfo) ~= "table" or type(C_GossipInfo.GetAvailableQuests) ~= "function" then
        return nil
    end

    return Util.SafeCall(C_GossipInfo.GetAvailableQuests)
end

local function SafeGetGossipOptions()
    if type(C_GossipInfo) ~= "table" or type(C_GossipInfo.GetOptions) ~= "function" then
        return nil
    end

    return Util.SafeCall(C_GossipInfo.GetOptions)
end

local function SafeSelectAvailableQuest(questID)
    if type(C_GossipInfo) ~= "table" or type(C_GossipInfo.SelectAvailableQuest) ~= "function" then
        return false
    end

    C_GossipInfo.SelectAvailableQuest(questID)
    return true
end

local function SafeQuestGetAutoAccept()
    if type(QuestGetAutoAccept) ~= "function" then
        return false
    end

    return Util.SafeCall(QuestGetAutoAccept) == true
end

local function SafeAcceptQuest()
    if type(AcceptQuest) ~= "function" then
        return false
    end

    AcceptQuest()
    return true
end

local function SafeAcknowledgeAutoAcceptQuest()
    if type(AcknowledgeAutoAcceptQuest) ~= "function" then
        return false
    end

    AcknowledgeAutoAcceptQuest()
    return true
end

local function IsWeakFallbackMode(mode)
    return mode == "singleAvailableQuest" or mode == "singleOption" or mode == "orderedFallback"
end

local function SafeConfirmGossipOption(optionID, text)
    if type(optionID) ~= "number" then
        return false
    end
    if type(C_GossipInfo) ~= "table" or type(C_GossipInfo.SelectOption) ~= "function" then
        return false
    end

    C_GossipInfo.SelectOption(optionID, text or "", true)
    return true
end

local function GetCurrentQuestOfferID()
    if type(GetQuestID) ~= "function" then
        return nil
    end

    local questID = Util.SafeCall(GetQuestID)
    if type(questID) == "number" and questID > 0 then
        return questID
    end

    return nil
end

local function HasQuestOfferContext()
    local questID = GetCurrentQuestOfferID()
    if questID then
        return true, questID
    end

    if type(GetTitleText) == "function" then
        local title = Util.SafeCall(GetTitleText)
        if type(title) == "string" and title ~= "" then
            return true, nil
        end
    end

    return false, nil
end

function ns.HuntPurchase:GetState()
    if not self.state then
        self.state = {
            active = false,
            phase = "idle",
            targetDifficulty = nil,
            targetQuestID = nil,
            selectedQuestID = nil,
            selectedOptionID = nil,
            awaitingQuestDetail = false,
            awaitingQuestAccept = false,
            selectionMode = nil,
        }
    end

    return self.state
end

function ns.HuntPurchase:ResetState(reason)
    local state = self:GetState()
    if state.active or state.phase ~= "idle" then
        LogHunt("reset", reason or "manual", state.phase)
    end

    state.active = false
    state.phase = "idle"
    state.targetDifficulty = nil
    state.targetQuestID = nil
    state.selectedQuestID = nil
    state.selectedOptionID = nil
    state.awaitingQuestDetail = false
    state.awaitingQuestAccept = false
    state.selectionMode = nil
end

function ns.HuntPurchase:BeginState(difficulty)
    local state = self:GetState()
    state.active = true
    state.phase = "gossip"
    state.targetDifficulty = difficulty
    state.targetQuestID = nil
    state.selectedQuestID = nil
    state.selectedOptionID = nil
    state.awaitingQuestDetail = false
    state.awaitingQuestAccept = false
    state.selectionMode = nil
    LogHunt("begin", difficulty, "gossip")
end

function ns.HuntPurchase:IsAutomationActive()
    local state = self:GetState()
    return state.active == true
end

function ns.HuntPurchase:HandleGossipShow()
    local settings = ns.Settings
    if not settings or not settings:ShouldAutoPurchaseRandomHunt() then
        self:ResetState("disabled")
        return
    end

    if not CanAffordHunt() then
        LogHunt("skip", "insufficientCurrency", GetRemnantQuantity())
        self:ResetState("insufficientCurrency")
        return
    end

    local availableQuests = SafeGetAvailableQuests()
    local options = SafeGetGossipOptions()
    if type(options) ~= "table" then
        options = {}
    end

    local difficulty = settings:GetRandomHuntDifficulty()
    local availableQuest, availableMode = ChooseBestAvailableQuest(availableQuests, difficulty)
    local match, optionMode = GetBestGossipOption(options, difficulty)
    local isTargetNpc = IsTargetAstalor()

    if not isTargetNpc then
        if IsWeakFallbackMode(availableMode) then
            availableQuest = nil
            availableMode = nil
        end
        if IsWeakFallbackMode(optionMode) then
            match = nil
            optionMode = nil
        end
        if not availableQuest and not match then
            self:ResetState("wrongNpc")
            return
        end
        LogHunt("npcFallback", "unitGuidUnavailable", difficulty)
    end

    self:BeginState(difficulty)

    if availableQuest and SafeSelectAvailableQuest(availableQuest.questID) then
        local state = self:GetState()
        state.selectedQuestID = availableQuest.questID
        state.targetQuestID = availableQuest.questID
        state.awaitingQuestDetail = true
        state.selectionMode = availableMode or "availableQuest"
        LogHunt("selectAvailableQuest", availableQuest.questID, GetQuestInfoText(availableQuest))
        return
    end

    if match and SelectGossipOption(match) then
        local state = self:GetState()
        state.awaitingQuestDetail = true
        state.selectionMode = optionMode or "option"
        state.targetQuestID = nil
        state.selectedOptionID = match.gossipOptionID or match.orderIndex
        LogHunt("selectGossipOption", match.gossipOptionID or match.orderIndex, match.name)
        return
    end

    LogHunt("skip", "noMatchingOption", difficulty)
    self:ResetState("noMatch")
end

function ns.HuntPurchase:HandleQuestDetail()
    local state = self:GetState()
    if not state.active then
        return
    end

    state.phase = "quest-detail"
    state.awaitingQuestDetail = false
    state.awaitingQuestAccept = true

    if SafeQuestGetAutoAccept() then
        if SafeAcknowledgeAutoAcceptQuest() then
            LogHunt("questDetail", "acknowledgeAutoAccept", state.targetQuestID or state.selectedQuestID)
            return
        end
    end

    if SafeAcceptQuest() then
        LogHunt("questDetail", "acceptQuest", state.targetQuestID or state.selectedQuestID)
        return
    end

    LogHunt("questDetail", "blocked", state.targetQuestID or state.selectedQuestID)
end

function ns.HuntPurchase:HandleGossipConfirm(gossipOptionID, text, cost)
    local state = self:GetState()
    if not state.active then
        return
    end

    local optionID = tonumber(gossipOptionID) or state.selectedOptionID
    if not optionID then
        LogHunt("gossipConfirm", "missingOptionID", text)
        return
    end

    if not CanAffordHunt() then
        LogHunt("gossipConfirm", "insufficientCurrency", cost)
        self:ResetState("insufficientCurrency")
        return
    end

    if SafeConfirmGossipOption(optionID, text) then
        state.awaitingQuestDetail = true
        state.phase = "gossip"
        state.selectedOptionID = optionID
        LogHunt("gossipConfirm", optionID, cost)
        return
    end

    LogHunt("gossipConfirm", "blocked", optionID)
end

function ns.HuntPurchase:HandleGossipClosed(interactionIsContinuing)
    local state = self:GetState()
    if not state.active then
        return
    end

    if interactionIsContinuing then
        LogHunt("gossipClosed", "continuing", state.phase)
        return
    end

    if state.awaitingQuestDetail then
        local hasOfferContext, questID = HasQuestOfferContext()
        if hasOfferContext then
            state.phase = "quest-detail"
            state.awaitingQuestDetail = false
            state.awaitingQuestAccept = true
            state.targetQuestID = state.targetQuestID or questID

            if SafeQuestGetAutoAccept() and SafeAcknowledgeAutoAcceptQuest() then
                LogHunt("gossipClosed", "acceptFallbackAuto", state.targetQuestID or state.selectedQuestID)
                return
            end

            if SafeAcceptQuest() then
                LogHunt("gossipClosed", "acceptFallback", state.targetQuestID or state.selectedQuestID)
                return
            end

            state.phase = "gossip"
            state.awaitingQuestDetail = true
            state.awaitingQuestAccept = false
            LogHunt("gossipClosed", "acceptFallbackBlocked", state.targetQuestID or state.selectedQuestID)
        end
    end

    if state.awaitingQuestDetail or state.awaitingQuestAccept or state.phase == "quest-detail" or state.phase == "quest-accepted" then
        LogHunt("gossipClosed", "preserveFlow", state.phase)
        return
    end

    self:ResetState("gossipClosed")
end

function ns.HuntPurchase:HandleQuestAccepted(questID)
    local state = self:GetState()
    if not state.active then
        return
    end

    state.phase = "quest-accepted"
    state.awaitingQuestAccept = false
    if questID then
        state.targetQuestID = state.targetQuestID or questID
        if state.targetDifficulty then
            LearnedSelection.questIDByDifficulty[state.targetDifficulty] = questID
        end
    end

    if state.selectedOptionID and state.targetDifficulty then
        LearnedSelection.optionIDByDifficulty[state.targetDifficulty] = state.selectedOptionID
    end

    LogHunt("questAccepted", questID or state.targetQuestID, state.selectionMode)
end

function ns.HuntPurchase:HandleQuestFinished()
    local state = self:GetState()
    if not state.active then
        return
    end

    LogHunt("questFinished", state.targetQuestID or state.selectedQuestID, state.selectionMode)
    self:ResetState("questFinished")
end
