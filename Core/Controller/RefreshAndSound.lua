-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
local Preybreaker = ns.Controller

local FR = ns.Constants and ns.Constants.FrameRef or {}
local MISSION_FRAME_NAME = FR.MissionFrame or "CovenantMissionFrame"

local function ResolveSessionQuestID(snapshot)
    if type(snapshot) ~= "table" then
        return nil
    end

    local questID = snapshot.questID or snapshot.activeQuestID or snapshot.worldQuestID
    if type(questID) ~= "number" then
        return nil
    end

    return questID
end

local function IsHuntSessionActive(snapshot)
    local questID = ResolveSessionQuestID(snapshot)
    if not questID then
        return false
    end

    if ns.Util and type(ns.Util.IsRelevantPreyQuest) == "function" then
        return ns.Util.IsRelevantPreyQuest(questID)
    end

    return true
end

local function IsPlayerDeadOrGhostSafe()
    if type(UnitIsDeadOrGhost) == "function" then
        return UnitIsDeadOrGhost("player") == true
    end

    if type(UnitIsDead) == "function" then
        return UnitIsDead("player") == true
    end

    return false
end

function Preybreaker:ShouldPreserveSnapshotWhileDead(previousSnapshot, snapshot)
    if type(previousSnapshot) ~= "table" or type(snapshot) ~= "table" then
        return false
    end

    if previousSnapshot.active ~= true or snapshot.active == true then
        return false
    end

    if not IsHuntSessionActive(previousSnapshot) then
        return false
    end

    if not IsPlayerDeadOrGhostSafe() then
        return false
    end

    local previousQuestID = previousSnapshot.questID or previousSnapshot.activeQuestID or previousSnapshot.worldQuestID
    local newQuestID = snapshot.questID or snapshot.activeQuestID or snapshot.worldQuestID
    if type(newQuestID) == "number" and type(previousQuestID) == "number" and newQuestID ~= previousQuestID then
        return false
    end

    return true
end

function Preybreaker:BuildDeathPreservedSnapshot(previousSnapshot, snapshot)
    if not self:ShouldPreserveSnapshotWhileDead(previousSnapshot, snapshot) then
        return snapshot
    end

    return {
        active = true,
        widgetID = snapshot.widgetID or previousSnapshot.widgetID,
        questID = previousSnapshot.questID,
        activeQuestID = previousSnapshot.activeQuestID,
        worldQuestID = previousSnapshot.worldQuestID,
        mapID = previousSnapshot.mapID,
        progressState = previousSnapshot.progressState,
        progress = previousSnapshot.progress,
        percent = previousSnapshot.percent,
        preservedWhileDead = true,
    }
end

function Preybreaker:Refresh(reason, ...)
    if ns.Util and ns.Util.InvalidatePreyQuestContextCache then
        ns.Util.InvalidatePreyQuestContextCache()
    end

    if reason and type(reason) == "string" and reason:sub(1, 8) == "settings" then
        if ns.OverlayView and ns.OverlayView.MarkTextStyleDirty then
            ns.OverlayView:MarkTextStyleDirty()
        end
    end

    local enabled = not ns.Settings or ns.Settings:IsEnabled()
    local snapshot = enabled and ns.DataSource.BuildSnapshot() or self:BuildInactiveSnapshot()

    local previousSnapshot = self.lastSnapshot
    if previousSnapshot and enabled then
        snapshot = self:BuildDeathPreservedSnapshot(previousSnapshot, snapshot)
    end

    self.activeWidgetID = enabled and snapshot.widgetID or nil
    self.lastSnapshot = snapshot

    if ns.Debug:IsEnabled() then
        ns.Debug:Log(
            "refresh",
            ns.Debug:KV("reason", reason or "manual"),
            ns.Debug:KV("enabled", enabled),
            ns.Debug:KV("active", snapshot.active),
            ns.Debug:KV("widgetID", snapshot.widgetID),
            ns.Debug:KV("progressState", snapshot.progressState),
            ns.Debug:KV("percent", snapshot.percent),
            ns.Debug:KV("preservedWhileDead", snapshot.preservedWhileDead == true),
            ns.Debug:KV("bootstrap", self:GetBootstrapSummary())
        )
    end

    if ns.QuestTracking then
        ns.QuestTracking:Sync(snapshot, reason)
    end

    ns.OverlayView:Render(snapshot)
    if ns.SettingsPanel and ns.SettingsPanel.frame and ns.SettingsPanel.frame:IsShown() then
        ns.SettingsPanel:RefreshControls()
        ns.SettingsPanel:RefreshPreview(snapshot)
    end
    if ns.HuntPanel and ns.HuntPanel.frame and ns.HuntPanel.frame:IsShown() then
        if ns.Settings and not ns.Settings:IsHuntPanelEnabled() then
            ns.HuntPanel:Hide()
        else
            if ns.Debug:IsEnabled() then
                ns.Debug:Log("hunts", ns.Debug:KV("action", "controllerRefresh"), ns.Debug:KV("detail", "panelRefresh"), ns.Debug:KV("extra", nil))
            end
            ns.HuntPanel:Refresh()
        end
    elseif ns.HuntPanel and _G[MISSION_FRAME_NAME] and _G[MISSION_FRAME_NAME]:IsShown() then
        if ns.Debug:IsEnabled() then
            ns.Debug:Log("hunts", ns.Debug:KV("action", "controllerRefresh"), ns.Debug:KV("detail", "showAttachedFallback"), ns.Debug:KV("extra", string.format("panelFrame=%s,panelShown=%s", tostring(ns.HuntPanel.frame ~= nil), tostring(ns.HuntPanel.frame and ns.HuntPanel.frame:IsShown()))))
        end
        ns.HuntPanel:ShowAttached()
    else
        if ns.Debug:IsEnabled() then
            ns.Debug:Log("hunts", ns.Debug:KV("action", "controllerRefresh"), ns.Debug:KV("detail", "skip"), ns.Debug:KV("extra", string.format("huntPanel=%s,panelFrame=%s,missionFrame=%s,missionShown=%s", tostring(ns.HuntPanel ~= nil), tostring(ns.HuntPanel and ns.HuntPanel.frame ~= nil), tostring(_G[MISSION_FRAME_NAME] ~= nil), tostring(_G[MISSION_FRAME_NAME] and _G[MISSION_FRAME_NAME]:IsShown()))))
        end
    end
end