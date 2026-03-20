-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

local Preybreaker = CreateFrame("Frame", "PreybreakerController")
ns.Controller = Preybreaker

local function BuildInactiveSnapshot()
    return {
        active = false,
        widgetID = nil,
        questID = nil,
        activeQuestID = nil,
        worldQuestID = nil,
        mapID = nil,
        progressState = nil,
        progress = 0,
        percent = 0,
    }
end

local function AreWidgetAPIsAvailable()
    return type(C_UIWidgetManager) == "table"
        and type(C_UIWidgetManager.GetPowerBarWidgetSetID) == "function"
        and type(C_UIWidgetManager.GetAllWidgetsBySetID) == "function"
        and type(C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo) == "function"
end

local function GetWidgetUpdateID(widgetInfo)
    if type(widgetInfo) ~= "table" then
        return nil
    end

    return widgetInfo.widgetID
end

local function ShouldRefreshFromWidgetUpdate(widgetInfo)
    if type(widgetInfo) ~= "table" then
        return true
    end
    if widgetInfo.widgetType == ns.Constants.WidgetTypePrey then
        return true
    end

    return widgetInfo.widgetID ~= nil and widgetInfo.widgetID == Preybreaker.activeWidgetID
end

function Preybreaker:GetBootstrapState()
    if not self.bootstrapState then
        self.bootstrapState = {
            addonLoaded = false,
            widgetsAddonLoaded = false,
            widgetsReady = AreWidgetAPIsAvailable(),
            worldEntered = false,
        }
    end

    return self.bootstrapState
end

function Preybreaker:GetBootstrapSummary()
    local state = self:GetBootstrapState()
    return string.format(
        "addon=%s,widgets=%s,world=%s",
        state.addonLoaded and "1" or "0",
        state.widgetsReady and "1" or "0",
        state.worldEntered and "1" or "0"
    )
end

function Preybreaker:UpdateBootstrapState(event, arg1)
    local state = self:GetBootstrapState()

    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            state.addonLoaded = true
        elseif arg1 == "Blizzard_UIWidgets" then
            state.widgetsAddonLoaded = true
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        state.worldEntered = true
    end

    state.widgetsReady = state.widgetsAddonLoaded == true or AreWidgetAPIsAvailable()
    return state
end

local function ShouldPlayHuntSounds()
    return ns.Settings
        and ns.Settings:ShouldPlaySoundOnPhaseChange()
        and type(PlaySoundFile) == "function"
end

local function PlayConfiguredSound(soundPath)
    if type(soundPath) ~= "string" or soundPath == "" then
        return
    end

    PlaySoundFile(soundPath, "Master")
end

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

local function ResolveStageTransitionSound(sounds, previousState, newState)
    if type(sounds) ~= "table" then
        return nil
    end

    if previousState == nil or newState == nil or previousState == newState then
        return nil
    end

    local preyState = Enum and Enum.PreyHuntProgressState
    local coldState = (preyState and preyState.Cold) or 0
    local warmState = (preyState and preyState.Warm) or 1
    local hotState = (preyState and preyState.Hot) or 2
    local finalState = (preyState and preyState.Final) or 3

    if previousState == coldState and newState == warmState then
        return sounds.ColdToWarm or sounds.PhaseChange
    end

    if previousState == warmState and newState == hotState then
        return sounds.WarmToHot or sounds.PhaseChange
    end

    if newState == finalState then
        return sounds.HotToFinal or sounds.FinalPhase or sounds.PhaseChange
    end

    return sounds.PhaseChange
end

function Preybreaker:Refresh(reason, ...)
    local enabled = not ns.Settings or ns.Settings:IsEnabled()
    local snapshot = enabled and ns.DataSource.BuildSnapshot() or BuildInactiveSnapshot()
    self.activeWidgetID = enabled and snapshot.widgetID or nil

    local previousSnapshot = self.lastSnapshot
    if previousSnapshot and enabled and ShouldPlayHuntSounds() then
        local sounds = ns.Constants and ns.Constants.Media and ns.Constants.Media.Sounds
        local previousSessionActive = IsHuntSessionActive(previousSnapshot)
        local newSessionActive = IsHuntSessionActive(snapshot)

        if previousSessionActive and not newSessionActive then
            PlayConfiguredSound(sounds and sounds.HuntEnd)
        elseif not previousSessionActive and newSessionActive then
            PlayConfiguredSound(sounds and sounds.HuntStart)
        elseif previousSessionActive and newSessionActive then
            local previousState = previousSnapshot.progressState
            local newState = snapshot.progressState
            local transitionSound = ResolveStageTransitionSound(sounds, previousState, newState)
            PlayConfiguredSound(transitionSound)
        end
    end

    self.lastSnapshot = snapshot

    ns.Debug:Log(
        "refresh",
        ns.Debug:KV("reason", reason or "manual"),
        ns.Debug:KV("enabled", enabled),
        ns.Debug:KV("active", snapshot.active),
        ns.Debug:KV("widgetID", snapshot.widgetID),
        ns.Debug:KV("progressState", snapshot.progressState),
        ns.Debug:KV("percent", snapshot.percent),
        ns.Debug:KV("bootstrap", self:GetBootstrapSummary())
    )

    if ns.QuestTracking then
        ns.QuestTracking:Sync(snapshot, reason)
    end

    ns.OverlayView:Render(snapshot)
    if ns.SettingsPanel and ns.SettingsPanel.frame and ns.SettingsPanel.frame:IsShown() then
        ns.SettingsPanel:RefreshControls()
        ns.SettingsPanel:RefreshPreview(snapshot)
    end
    if ns.HuntPanel and ns.HuntPanel.frame and ns.HuntPanel.frame:IsShown() then
        ns.HuntPanel:Refresh()
    end
end

-- Startup readiness is driven by observed addon/world/widget events rather than a blind timer.
local function HookPreyHuntIconFrame()
    local mixin = _G.UIWidgetTemplatePreyHuntProgressMixin
    if not mixin or ns.OverlayView.preyHuntIconHooked then
        return
    end

    hooksecurefunc(mixin, "Setup", function(self)
        ns.OverlayView.preyHuntIconFrame = self
        -- Blizzard's Setup calls AnimIn -> ResetAnimState -> SetAlpha(1) + Show().
        -- We must re-hide AFTER that sequence completes, which is here in the post-hook.
        if ns.Settings and ns.Settings:ShouldHideBlizzardWidget() and ns.Settings:IsEnabled() then
            if ns.OverlayView and type(ns.OverlayView.HideStandaloneWidgetFrame) == "function" then
                ns.OverlayView:HideStandaloneWidgetFrame(self)
            elseif type(self.Hide) == "function" then
                self:Hide()
            elseif type(self.SetAlpha) == "function" then
                self:SetAlpha(0)
            end
        end
    end)
    ns.OverlayView.preyHuntIconHooked = true
end

function Preybreaker:Bootstrap(event, detail)
    self:UpdateBootstrapState(event, detail)

    if event == "ADDON_LOADED" and detail == ADDON_NAME then
        if ns.Settings then
            ns.Settings:Initialize()
        end
        if ns.HuntPanel and type(ns.HuntPanel.Ensure) == "function" then
            ns.HuntPanel:Ensure()
        end
    end

    if event == "ADDON_LOADED" and (detail == "Blizzard_UIWidgets" or detail == ADDON_NAME) then
        HookPreyHuntIconFrame()
    end

    ns.Debug:Log(
        "bootstrap",
        ns.Debug:KV("event", event),
        ns.Debug:KV("detail", detail),
        ns.Debug:KV("state", self:GetBootstrapSummary())
    )

    if event == "ADDON_LOADED" and detail == ADDON_NAME and not self:GetBootstrapState().widgetsReady then
        ns.Debug:Log("bootstrap", ns.Debug:KV("waitingFor", "Blizzard_UIWidgets"))
    end

    local state = self:GetBootstrapState()
    if state.addonLoaded and state.widgetsReady then
        self:UnregisterEvent("ADDON_LOADED")
    end

    local reason = event
    if detail ~= nil then
        reason = string.format("%s:%s", event, tostring(detail))
    end

    self:Refresh(reason)
end

Preybreaker:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME or arg1 == "Blizzard_UIWidgets" then
            self:Bootstrap(event, arg1)
        end

        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        self:Bootstrap(event)
        return
    end

    if event == "QUEST_AUTOCOMPLETE" then
        if ns.QuestTracking then
            ns.QuestTracking:HandleQuestAutoComplete(arg1)
        end
        return
    end

    if event == "QUEST_COMPLETE" then
        if ns.QuestTracking then
            ns.QuestTracking:HandleQuestComplete()
        end
        return
    end

    if event == "QUEST_ITEM_UPDATE" then
        if ns.QuestTracking then
            ns.QuestTracking:HandleQuestItemUpdate()
        end
        return
    end

    if event == "GOSSIP_SHOW" then
        if ns.HuntPurchase then
            ns.HuntPurchase:HandleGossipShow()
        end
        return
    end

    if event == "QUEST_DETAIL" then
        if ns.HuntPurchase then
            ns.HuntPurchase:HandleQuestDetail()
        end
        return
    end

    if event == "GOSSIP_CLOSED" then
        if ns.HuntPurchase then
            ns.HuntPurchase:HandleGossipClosed(arg1)
        end
        return
    end

    if event == "GOSSIP_CONFIRM" then
        if ns.HuntPurchase then
            local optionID, text, cost = arg1, ...
            ns.HuntPurchase:HandleGossipConfirm(optionID, text, cost)
        end
        return
    end

    if event == "QUEST_ACCEPTED" then
        if ns.HuntPurchase then
            local questID = select(1, ...)
            if type(questID) ~= "number" then
                questID = arg1
            end
            ns.HuntPurchase:HandleQuestAccepted(questID)
        end
    end

    if event == "QUEST_FINISHED" then
        if ns.HuntPurchase then
            ns.HuntPurchase:HandleQuestFinished()
        end
    end

    if event == "UPDATE_UI_WIDGET" and not ShouldRefreshFromWidgetUpdate(arg1) then
        ns.Debug:Log(
            "event",
            ns.Debug:KV("event", event),
            ns.Debug:KV("widgetID", GetWidgetUpdateID(arg1)),
            ns.Debug:KV("activeWidgetID", self.activeWidgetID),
            "refresh=skipped"
        )
        return
    end

    ns.Debug:Log(
        "event",
        ns.Debug:KV("event", event),
        ns.Debug:KV("widgetID", GetWidgetUpdateID(arg1))
    )

    self:Refresh(event, arg1, ...)
end)

Preybreaker:RegisterEvent("ADDON_LOADED")
Preybreaker:RegisterEvent("PLAYER_ENTERING_WORLD")
Preybreaker:RegisterEvent("QUEST_ACCEPTED")
Preybreaker:RegisterEvent("QUEST_REMOVED")
Preybreaker:RegisterEvent("QUEST_LOG_UPDATE")
Preybreaker:RegisterEvent("QUEST_LOG_CRITERIA_UPDATE")
Preybreaker:RegisterEvent("QUEST_POI_UPDATE")
Preybreaker:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
Preybreaker:RegisterEvent("SUPER_TRACKING_CHANGED")
Preybreaker:RegisterEvent("TASK_PROGRESS_UPDATE")
Preybreaker:RegisterEvent("UPDATE_ALL_UI_WIDGETS")
Preybreaker:RegisterEvent("UPDATE_UI_WIDGET")
Preybreaker:RegisterEvent("QUEST_AUTOCOMPLETE")
Preybreaker:RegisterEvent("QUEST_COMPLETE")
Preybreaker:RegisterEvent("QUEST_ITEM_UPDATE")
Preybreaker:RegisterEvent("GOSSIP_SHOW")
Preybreaker:RegisterEvent("QUEST_DETAIL")
Preybreaker:RegisterEvent("GOSSIP_CLOSED")
Preybreaker:RegisterEvent("GOSSIP_CONFIRM")
Preybreaker:RegisterEvent("QUEST_FINISHED")
Preybreaker:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

-- Private namespace reference for the test suite. Only exposed when the
-- companion test addon is installed. Not part of the public API.
do
    local getInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
    if type(getInfo) == "function" then
        local ok, name = pcall(getInfo, "PreybreakerTests")
        if ok and name then
            _G._PreybreakerTestNS = ns
        end
    end
end
