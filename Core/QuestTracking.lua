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

local function GetSettings()
    return ns.Settings
end

local function GetActivePreyQuestID()
    return Util.GetActivePreyQuestID()
end

local function IsQuestComplete(questID)
    return Util.IsQuestComplete(questID)
end

local function IsWorldQuest(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.IsWorldQuest) ~= "function" then
        return false
    end

    return Util.SafeCall(C_QuestLog.IsWorldQuest, questID) == true
end

local function GetQuestWatchType(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.GetQuestWatchType) ~= "function" then
        return nil
    end

    return Util.SafeCall(C_QuestLog.GetQuestWatchType, questID)
end

local function AddWorldQuestWatch(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.AddWorldQuestWatch) ~= "function" then
        return false
    end

    local manualWatchType = Enum and Enum.QuestWatchType and Enum.QuestWatchType.Manual or 1
    return Util.SafeCall(C_QuestLog.AddWorldQuestWatch, questID, manualWatchType) == true
end

local function RemoveWorldQuestWatch(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.RemoveWorldQuestWatch) ~= "function" then
        return false
    end

    return Util.SafeCall(C_QuestLog.RemoveWorldQuestWatch, questID) == true
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
            previousSuperTrackedQuestID = nil,
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
        RemoveWorldQuestWatch(questID)
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
        local restoreQuestID = state.previousSuperTrackedQuestID
        if restoreQuestID and restoreQuestID > 0 and restoreQuestID ~= questID then
            SetSuperTrackedQuestID(restoreQuestID)
        else
            SetSuperTrackedQuestID(0)
        end
    end

    state.ownedSuperTrackedQuestID = nil
    state.previousSuperTrackedQuestID = nil
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
end

function ns.QuestTracking:ApplyAutoWatch(questID)
    local state = self:GetState()
    if not questID or state.ownedWatchQuestID == questID or GetQuestWatchType(questID) ~= nil then
        return
    end

    if AddWorldQuestWatch(questID) then
        state.ownedWatchQuestID = questID
        LogTracking("applyWatch", questID, "manual")
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

    state.previousSuperTrackedQuestID = currentSuperTrackedQuestID or 0
    if SetSuperTrackedQuestID(questID) then
        state.ownedSuperTrackedQuestID = questID
        LogTracking("applySuperTrack", questID, state.previousSuperTrackedQuestID)
    end
end

function ns.QuestTracking:ResolveTrackableQuestID(snapshot)
    local questID = GetActivePreyQuestID()
    if not questID or IsQuestComplete(questID) or not IsWorldQuest(questID) then
        return nil
    end

    return questID
end

function ns.QuestTracking:Sync(snapshot, reason)
    local settings = GetSettings()
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
