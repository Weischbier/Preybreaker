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

function ns.QuestTracking:GetState()
    if not self.state then
        self.state = {
            activeQuestID = nil,
            ownedWatchQuestID = nil,
            ownedSuperTrackedQuestID = nil,
            pendingAutoTurnIn = nil,
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

-- Auto-turn-in: complete the prey quest when its auto-complete popup fires.
-- Follows the DialogueUI pattern: QUEST_AUTOCOMPLETE -> ShowQuestComplete -> QUEST_COMPLETE -> GetQuestReward.
-- Only prey-hunt quests are touched; every other quest is ignored.

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
    LogTracking("autoTurnIn:show", questID, "pendingReward")

    if type(ShowQuestComplete) == "function" then
        ShowQuestComplete(questID)
    end
end

function ns.QuestTracking:HandleQuestComplete()
    local state = self:GetState()
    if not state.pendingAutoTurnIn then
        return
    end

    local currentQuestID = type(GetQuestID) == "function" and GetQuestID() or nil
    if not currentQuestID or currentQuestID ~= state.pendingAutoTurnIn then
        state.pendingAutoTurnIn = nil
        return
    end

    local numChoices = type(GetNumQuestChoices) == "function" and GetNumQuestChoices() or 0
    if numChoices > 1 then
        LogTracking("autoTurnIn:skip", currentQuestID, "rewardChoice")
        state.pendingAutoTurnIn = nil
        return
    end

    local rewardIndex = numChoices == 1 and 1 or 0
    LogTracking("autoTurnIn:complete", currentQuestID, rewardIndex)

    if type(GetQuestReward) == "function" then
        GetQuestReward(rewardIndex)
    end

    state.pendingAutoTurnIn = nil
end
