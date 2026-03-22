-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Util = ns.Util

ns.QuestTracking = {}

local function LogTracking(action, questID, detail)
    if not (ns.Debug and type(ns.Debug.Log) == "function" and type(ns.Debug.KV) == "function") then
        return
    end

    ns.Debug:Log(
        "tracking",
        ns.Debug:KV("action", action),
        ns.Debug:KV("questID", questID),
        ns.Debug:KV("detail", detail)
    )
end

local function IsWorldQuest(questID)
    return Util.IsWorldQuest(questID)
end

local function GetQuestWatchType(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.GetQuestWatchType) ~= "function" then
        return nil
    end

    return Util.SafeCall(C_QuestLog.GetQuestWatchType, questID)
end

local function GetManualWatchType()
    return Enum and Enum.QuestWatchType and Enum.QuestWatchType.Manual or 1
end

local function AddWorldQuestWatch(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.AddWorldQuestWatch) ~= "function" then
        return false
    end

    return Util.SafeCall(C_QuestLog.AddWorldQuestWatch, questID, GetManualWatchType()) == true
end

local function RemoveWorldQuestWatch(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.RemoveWorldQuestWatch) ~= "function" then
        return false
    end

    return Util.SafeCall(C_QuestLog.RemoveWorldQuestWatch, questID) == true
end

local function AddNormalQuestWatch(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.AddQuestWatch) ~= "function" then
        return false
    end

    return Util.SafeCall(C_QuestLog.AddQuestWatch, questID) == true
end

local function RemoveNormalQuestWatch(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.RemoveQuestWatch) ~= "function" then
        return false
    end

    return Util.SafeCall(C_QuestLog.RemoveQuestWatch, questID) == true
end

local function AddQuestWatch(questID)
    if IsWorldQuest(questID) then
        return AddWorldQuestWatch(questID)
    end

    return AddNormalQuestWatch(questID)
end

local function RemoveQuestWatch(questID)
    if IsWorldQuest(questID) then
        return RemoveWorldQuestWatch(questID)
    end

    return RemoveNormalQuestWatch(questID)
end

local function GetSuperTrackedQuestID()
    if type(C_SuperTrack) ~= "table" or type(C_SuperTrack.GetSuperTrackedQuestID) ~= "function" then
        return nil
    end

    return Util.SafeCall(C_SuperTrack.GetSuperTrackedQuestID)
end

local function SetSuperTrackedQuestID(questID)
    if type(C_SuperTrack) ~= "table" or type(C_SuperTrack.SetSuperTrackedQuestID) ~= "function" then
        return false
    end

    Util.SafeCall(C_SuperTrack.SetSuperTrackedQuestID, questID or 0)
    return GetSuperTrackedQuestID() == (questID or 0)
end

local function SafeGetQuestID()
    if type(GetQuestID) ~= "function" then
        return nil
    end

    return Util.SafeCall(GetQuestID)
end

local function GetQuestRewardChoiceCount()
    if type(GetNumQuestChoices) ~= "function" then
        return 0
    end

    return Util.SafeCall(GetNumQuestChoices) or 0
end

local function SafeGetQuestItemInfoLootType(questInfoType, index)
    if type(GetQuestItemInfoLootType) ~= "function" then
        return nil
    end

    return Util.SafeCall(GetQuestItemInfoLootType, questInfoType, index)
end

local function SafeGetQuestItemInfo(questInfoType, index)
    if type(GetQuestItemInfo) ~= "function" then
        return nil
    end

    return { Util.SafeCall(GetQuestItemInfo, questInfoType, index) }
end

local function SafeGetQuestItemLink(questInfoType, index)
    if type(GetQuestItemLink) ~= "function" then
        return nil
    end

    return Util.SafeCall(GetQuestItemLink, questInfoType, index)
end

local function SafeGetQuestRewardCurrencyInfo(questInfoType, index)
    if type(C_QuestOffer) ~= "table" or type(C_QuestOffer.GetQuestRewardCurrencyInfo) ~= "function" then
        return nil
    end

    return Util.SafeCall(C_QuestOffer.GetQuestRewardCurrencyInfo, questInfoType, index)
end

local TextContainsAny = Util.TextContainsAny

local function GetChoiceLabel(choice)
    if not choice then
        return nil
    end

    if choice.itemLink and choice.itemLink ~= "" then
        return choice.itemLink
    end

    if choice.itemName and choice.itemName ~= "" then
        return choice.itemName
    end

    if choice.currencyName and choice.currencyName ~= "" then
        return choice.currencyName
    end

    return choice.name
end

local function GetChoiceText(choice)
    if not choice then
        return ""
    end

    local parts = {}
    if choice.itemName and choice.itemName ~= "" then
        parts[#parts + 1] = choice.itemName
    end
    if choice.currencyName and choice.currencyName ~= "" and choice.currencyName ~= choice.itemName then
        parts[#parts + 1] = choice.currencyName
    end
    if choice.itemLink and choice.itemLink ~= "" then
        parts[#parts + 1] = choice.itemLink
    end

    if #parts > 0 then
        return table.concat(parts, " ")
    end

    return tostring(choice.name or "")
end

local function IsCurrencyCapped(currencyInfo)
    if type(currencyInfo) ~= "table" then
        return false
    end

    local maxQuantity = tonumber(currencyInfo.maxQuantity) or 0
    if maxQuantity <= 0 then
        return false
    end

    local totalEarned = tonumber(currencyInfo.totalEarned) or 0
    local quantity = tonumber(currencyInfo.quantity) or 0

    if currencyInfo.useTotalEarnedForMaxQty == true then
        return totalEarned >= maxQuantity
    end

    return quantity >= maxQuantity
end

local function IsChoiceTypeLootType(lootType, expected)
    if lootType == nil then
        return false
    end

    if lootType == expected then
        return true
    end

    return tostring(lootType) == tostring(expected)
end

local function BuildRewardChoice(questInfoType, index)
    local lootType = SafeGetQuestItemInfoLootType(questInfoType, index)
    local itemInfo = SafeGetQuestItemInfo(questInfoType, index)
    local currencyInfo = SafeGetQuestRewardCurrencyInfo(questInfoType, index)

    local choice = {
        index = index,
        lootType = lootType,
        isCurrency = IsChoiceTypeLootType(lootType, 1),
        isItem = IsChoiceTypeLootType(lootType, 0),
        name = itemInfo and itemInfo[1] or nil,
        itemName = itemInfo and itemInfo[1] or nil,
        itemTexture = itemInfo and itemInfo[2] or nil,
        itemCount = itemInfo and itemInfo[3] or nil,
        itemQuality = itemInfo and itemInfo[4] or nil,
        itemID = itemInfo and itemInfo[6] or nil,
        questRewardContextFlags = itemInfo and itemInfo[7] or nil,
        itemLink = SafeGetQuestItemLink(questInfoType, index),
        currencyInfo = currencyInfo,
        currencyID = currencyInfo and currencyInfo.currencyID or nil,
        currencyName = currencyInfo and currencyInfo.name or nil,
        currencyTexture = currencyInfo and currencyInfo.texture or nil,
        currencyAmount = currencyInfo and currencyInfo.totalRewardAmount or nil,
    }

    choice.label = GetChoiceLabel(choice)
    choice.text = GetChoiceText(choice)
    choice.isCapped = currencyInfo and IsCurrencyCapped(currencyInfo) or false

    return choice
end

local function BuildRewardChoices(questInfoType, numChoices)
    local choices = {}
    for index = 1, numChoices do
        choices[index] = BuildRewardChoice(questInfoType, index)
    end

    return choices
end

local function GetRewardPatterns(rewardType)
    local hunt = ns.Constants and ns.Constants.Hunt
    if not hunt or not hunt.RewardPatterns then
        return nil
    end

    return hunt.RewardPatterns[rewardType]
end

local function IsCurrencyIDInList(currencyID, list)
    if not currencyID or type(list) ~= "table" then
        return false
    end

    for _, value in ipairs(list) do
        if value == currencyID then
            return true
        end
    end

    return false
end

local function ClassifyChoiceRewardType(choice)
    if type(choice) ~= "table" then
        return nil
    end

    local hunt = ns.Constants and ns.Constants.Hunt or nil
    if not hunt then
        return nil
    end

    local currencyID = choice.currencyID
    if currencyID then
        if IsCurrencyIDInList(currencyID, hunt.DawncrestCurrencyIDs) then
            return "dawncrest"
        end
        if hunt.RemnantCurrencyID and currencyID == hunt.RemnantCurrencyID then
            return "remnant"
        end
        if hunt.VoidlightMarlCurrencyID and currencyID == hunt.VoidlightMarlCurrencyID then
            return "marl"
        end
    end

    local lootType = tonumber(choice.lootType)
    if lootType and lootType == 2 then
        return "gold"
    end

    if not currencyID and (not choice.itemID or choice.itemID == 0) then
        local itemLink = choice.itemLink
        if type(itemLink) ~= "string" or itemLink == "" then
            return "gold"
        end
    end

    return nil
end

local function ChoiceMatchesRewardType(choice, rewardType)
    if not choice then
        return false
    end

    local typedRewardType = ClassifyChoiceRewardType(choice)
    if typedRewardType then
        return typedRewardType == rewardType
    end

    local patterns = GetRewardPatterns(rewardType)
    if not patterns then
        return false
    end

    local text = GetChoiceText(choice)
    return TextContainsAny(text, patterns)
end

local function IsRewardTypeCapped(choices, rewardType)
    if rewardType ~= "dawncrest" then
        return false
    end

    local hunt = ns.Constants and ns.Constants.Hunt
    if not hunt or not hunt.DawncrestCurrencyIDs then
        return false
    end

    for _, choice in ipairs(choices or {}) do
        if choice and choice.currencyID then
            for _, currencyID in ipairs(hunt.DawncrestCurrencyIDs) do
                if choice.currencyID == currencyID and choice.isCapped then
                    return true
                end
            end
        end
    end

    return false
end

local function FindChoiceIndexByRewardType(choices, rewardType)
    local patterns = GetRewardPatterns(rewardType)
    if not patterns then
        return nil
    end

    for _, choice in ipairs(choices or {}) do
        if choice and ChoiceMatchesRewardType(choice, rewardType) then
            return choice.index
        end
    end

    return nil
end

local function ResolveRewardChoiceIndex(choices, preferredReward, fallbackReward)
    local preferredIndex = FindChoiceIndexByRewardType(choices, preferredReward)
    if preferredIndex and not IsRewardTypeCapped(choices, preferredReward) then
        return preferredIndex
    end

    local fallbackIndex = FindChoiceIndexByRewardType(choices, fallbackReward)
    if fallbackIndex then
        return fallbackIndex
    end

    return preferredIndex
end

local function IsRelevantQuestID(questID, state)
    if not questID then
        return false
    end

    if Util.IsRelevantPreyQuest(questID) then
        return true
    end

    if state then
        if questID == state.pendingCompletionQuestID then
            return true
        end
        if questID == state.pendingRewardQuestID then
            return true
        end
    end

    return false
end

function ns.QuestTracking:GetState()
    if not self.state then
        self.state = {
            activeQuestID = nil,
            ownedWatchQuestID = nil,
            ownedSuperTrackedQuestID = nil,
            pendingAutoTurnIn = nil,
            pendingCompletionQuestID = nil,
            pendingRewardQuestID = nil,
            pendingRewardRetryCount = 0,
            lastRelevantQuestID = nil,
        }
    end

    return self.state
end

function ns.QuestTracking:CleanupOwnedWatch(questID, reason)
    local state = self:GetState()
    if not questID or state.ownedWatchQuestID ~= questID then
        return
    end

    if GetQuestWatchType(questID) ~= nil then
        RemoveQuestWatch(questID)
    end

    state.ownedWatchQuestID = nil
    LogTracking("cleanupWatch", questID, reason)
end

function ns.QuestTracking:CleanupOwnedSuperTrack(questID, reason)
    local state = self:GetState()
    if not questID or state.ownedSuperTrackedQuestID ~= questID then
        return
    end

    if GetSuperTrackedQuestID() == questID then
        SetSuperTrackedQuestID(0)
    end

    state.ownedSuperTrackedQuestID = nil
    LogTracking("cleanupSuperTrack", questID, reason)
end

function ns.QuestTracking:CleanupQuest(questID, reason)
    self:CleanupOwnedWatch(questID, reason)
    self:CleanupOwnedSuperTrack(questID, reason)
end

function ns.QuestTracking:CleanupAll(reason)
    local state = self:GetState()
    if state.activeQuestID then
        self:CleanupQuest(state.activeQuestID, reason)
    end

    state.activeQuestID = nil
    state.pendingAutoTurnIn = nil
    state.pendingCompletionQuestID = nil
    state.pendingRewardQuestID = nil
    state.pendingRewardRetryCount = 0
    state.lastRelevantQuestID = nil
end

function ns.QuestTracking:ApplyAutoWatch(questID)
    local state = self:GetState()
    if not questID or state.ownedWatchQuestID == questID or GetQuestWatchType(questID) ~= nil then
        return
    end

    if AddQuestWatch(questID) then
        state.ownedWatchQuestID = questID
        LogTracking("applyWatch", questID, IsWorldQuest(questID) and "world" or "normal")
    end
end

function ns.QuestTracking:ApplyAutoSuperTrack(questID)
    local state = self:GetState()
    if not questID or state.ownedSuperTrackedQuestID == questID then
        return
    end

    local currentSuperTrackedQuestID = GetSuperTrackedQuestID()
    if currentSuperTrackedQuestID == questID then
        return
    end

    if SetSuperTrackedQuestID(questID) then
        state.ownedSuperTrackedQuestID = questID
        LogTracking("applySuperTrack", questID, nil)
    end
end

function ns.QuestTracking:ResolveTrackableQuestID(snapshot)
    local questID = snapshot and snapshot.questID or nil
    if not questID then
        local context = Util.BuildPreyQuestContext()
        questID = context.trackedQuestID
    end

    if not questID or Util.IsQuestComplete(questID) then
        return nil
    end

    if not Util.IsQuestActive(questID) and not Util.IsTaskQuestActive(questID) and not IsWorldQuest(questID) then
        return nil
    end

    return questID
end

function ns.QuestTracking:Sync(snapshot, reason)
    local settings = ns.Settings
    if not settings or not settings:IsEnabled() then
        self:CleanupAll(reason or "trackerDisabled")
        return
    end

    local autoWatch = settings:ShouldAutoWatchPreyQuest()
    local autoSuperTrack = settings:ShouldAutoSuperTrackPreyQuest()
    local questID = self:ResolveTrackableQuestID(snapshot)
    local state = self:GetState()

    if snapshot and snapshot.questID and not state.lastRelevantQuestID then
        state.lastRelevantQuestID = snapshot.questID
    end

    if questID then
        state.lastRelevantQuestID = questID
    end

    if state.activeQuestID and state.activeQuestID ~= questID then
        self:CleanupQuest(state.activeQuestID, "questChanged")
        state.activeQuestID = nil
    end

    if not questID then
        if state.activeQuestID then
            self:CleanupQuest(state.activeQuestID, reason or "inactive")
            state.activeQuestID = nil
        end
        return
    end

    state.activeQuestID = questID

    if autoWatch then
        self:ApplyAutoWatch(questID)
    else
        self:CleanupOwnedWatch(questID, "watchDisabled")
    end

    if autoSuperTrack then
        self:ApplyAutoSuperTrack(questID)
    else
        self:CleanupOwnedSuperTrack(questID, "superTrackDisabled")
    end
end

local function ClearCompletionState(state)
    state.pendingAutoTurnIn = nil
    state.pendingCompletionQuestID = nil
    state.pendingRewardQuestID = nil
    state.pendingRewardRetryCount = 0
end

function ns.QuestTracking:HandleQuestAutoComplete(questID)
    local settings = ns.Settings
    if not settings or not settings:ShouldAutoTurnInPreyQuest() then
        return
    end

    if not Util.IsRelevantPreyQuest(questID) then
        return
    end

    local state = self:GetState()
    state.pendingAutoTurnIn = questID
    state.pendingCompletionQuestID = questID
    state.lastRelevantQuestID = questID
    LogTracking("autoTurnIn:show", questID, "pendingReward")

    if type(ShowQuestComplete) == "function" then
        ShowQuestComplete(questID)
    end
end

function ns.QuestTracking:ResolvePreferredRewardChoice(choices, preferredReward, fallbackReward)
    return ResolveRewardChoiceIndex(choices, preferredReward, fallbackReward)
end

function ns.QuestTracking:BuildQuestRewardChoices(questInfoType, numChoices)
    return BuildRewardChoices(questInfoType or "choice", numChoices or GetQuestRewardChoiceCount())
end

function ns.QuestTracking:ResolveQuestRewardSelection(questInfoType, preferredReward, fallbackReward)
    local choices = self:BuildQuestRewardChoices(questInfoType)
    local rewardIndex = self:ResolvePreferredRewardChoice(choices, preferredReward, fallbackReward)
    if not rewardIndex then
        return nil, choices
    end

    return rewardIndex, choices
end

function ns.QuestTracking:TryResolvePendingRewardSelection(reason)
    local state = self:GetState()
    local settings = ns.Settings
    local questID = state.pendingRewardQuestID or state.pendingCompletionQuestID or state.pendingAutoTurnIn or SafeGetQuestID()
    local currentQuestID = SafeGetQuestID()

    if currentQuestID and questID and currentQuestID ~= questID then
        LogTracking("autoSelect:skip", questID, "questContextMismatch")
        return false
    end

    if not questID or not IsRelevantQuestID(questID, state) then
        return false
    end

    if not settings or not settings:ShouldAutoSelectHuntReward() then
        return false
    end

    local retryCount = state.pendingRewardRetryCount or 0
    if retryCount >= 10 then
        LogTracking("autoSelect:abandon", questID, "retryLimitReached")
        ClearCompletionState(state)
        return false
    end

    local numChoices = GetQuestRewardChoiceCount()
    local choices = self:BuildQuestRewardChoices("choice", numChoices)
    local rewardIndex = self:ResolvePreferredRewardChoice(choices, settings:GetPreferredHuntReward(), settings:GetFallbackHuntReward())

    if rewardIndex then
        LogTracking("autoSelect:reward", questID, rewardIndex)
        if type(GetQuestReward) == "function" then
            Util.SafeCall(GetQuestReward, rewardIndex)
        end
        ClearCompletionState(state)
        return true
    end

    state.pendingRewardQuestID = questID
    state.pendingRewardRetryCount = retryCount + 1
    LogTracking("autoSelect:pending", questID, reason or "questComplete")
    return false
end

function ns.QuestTracking:HandleQuestItemUpdate()
    local state = self:GetState()
    if not state.pendingRewardQuestID then
        return
    end

    local settings = ns.Settings
    if not settings or not settings:ShouldAutoSelectHuntReward() then
        state.pendingRewardQuestID = nil
        state.pendingRewardRetryCount = 0
        return
    end

    self:TryResolvePendingRewardSelection("questItemUpdate")
end

function ns.QuestTracking:HandleQuestComplete()
    local state = self:GetState()
    local settings = ns.Settings

    local currentQuestID = SafeGetQuestID()
    local questID = currentQuestID or state.pendingCompletionQuestID or state.pendingRewardQuestID or state.pendingAutoTurnIn

    if not questID or not IsRelevantQuestID(questID, state) then
        state.pendingAutoTurnIn = nil
        state.pendingCompletionQuestID = nil
        state.pendingRewardQuestID = nil
        state.pendingRewardRetryCount = 0
        state.lastRelevantQuestID = nil
        return
    end

    state.pendingCompletionQuestID = questID
    state.lastRelevantQuestID = questID

    local numChoices = GetQuestRewardChoiceCount()
    local autoSelectEnabled = settings and settings:ShouldAutoSelectHuntReward()
    local isPendingAutoTurnIn = state.pendingAutoTurnIn and questID == state.pendingAutoTurnIn

    if not autoSelectEnabled and state.pendingRewardQuestID then
        state.pendingRewardQuestID = nil
        state.pendingRewardRetryCount = 0
    end

    if autoSelectEnabled and IsRelevantQuestID(questID, state) then
        if self:TryResolvePendingRewardSelection("questComplete") then
            return
        end

        if numChoices == 0 then
            LogTracking("autoSelect:awaiting", questID, "choicesNotReady")
            state.pendingRewardQuestID = questID
            return
        end

        state.pendingRewardQuestID = questID
        LogTracking("autoSelect:awaiting", questID, numChoices)
        return
    end

    if numChoices > 1 then
        if isPendingAutoTurnIn then
            LogTracking("autoTurnIn:skip", questID, "rewardChoice")
        end
        state.pendingAutoTurnIn = nil
        return
    end

    if not isPendingAutoTurnIn then
        return
    end

    local rewardIndex = numChoices == 1 and 1 or 0
    LogTracking("autoTurnIn:complete", questID, rewardIndex)

    if type(GetQuestReward) == "function" then
        Util.SafeCall(GetQuestReward, rewardIndex)
    end

    ClearCompletionState(state)
end
