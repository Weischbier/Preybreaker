-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- OverlayView: widget-hiding subsystem.
-- Suppresses the Blizzard prey widget and its icon when overlay-only mode is active.
-- Loaded before OverlayView.lua, which owns rendering and anchoring.

local _, ns = ...

ns.OverlayView = ns.OverlayView or {}

local Util = ns.Util

local function BuildFrameEffectInfo(frame)
    local effectID = frame and frame.scriptedAnimationEffectID or nil
    local modelSceneLayer = frame and frame.modelSceneLayer or nil
    if not effectID or effectID == 0 or modelSceneLayer == nil then
        return nil
    end

    if Enum and Enum.UIWidgetModelSceneLayer and modelSceneLayer == Enum.UIWidgetModelSceneLayer.None then
        return nil
    end

    return {
        scriptedAnimationEffectID = effectID,
        modelSceneLayer = modelSceneLayer,
    }
end

local function CancelFrameEffect(frame)
    local effectController = frame and frame.effectController or nil
    if not effectController or type(effectController.CancelEffect) ~= "function" then
        return false
    end

    Util.SafeCall(effectController.CancelEffect, effectController)
    frame.effectController = nil
    return true
end

local function RestoreFrameEffect(frame)
    if not frame or frame.effectController or not frame.widgetContainer then
        return false
    end

    local effectInfo = BuildFrameEffectInfo(frame)
    if not effectInfo then
        return false
    end

    if type(frame.ApplyEffects) == "function" then
        Util.SafeCall(frame.ApplyEffects, frame, effectInfo)
        return frame.effectController ~= nil
    end

    if type(frame.ApplyEffectToFrame) == "function" then
        Util.SafeCall(frame.ApplyEffectToFrame, frame, effectInfo, frame.widgetContainer, frame)
        return frame.effectController ~= nil
    end

    return false
end

local function ShouldHideBlizzardWidget()
    local settings = ns.Settings
    return settings and settings:ShouldHideBlizzardWidget() or false
end

local function IsFrameUsable(frame)
    return frame
        and type(frame.GetObjectType) == "function"
        and frame:GetObjectType() == "Frame"
        and type(frame.Hide) == "function"
end

local function GetHiddenStore(self)
    if not self._hiddenFrames then
        self._hiddenFrames = setmetatable({}, { __mode = "k" })
    end
    return self._hiddenFrames
end

local function GetEffectStore(self)
    if not self._hiddenEffects then
        self._hiddenEffects = setmetatable({}, { __mode = "k" })
    end
    return self._hiddenEffects
end

local function HideFrame(self, frame)
    if not frame or type(frame.SetAlpha) ~= "function" then
        return
    end

    local store = GetHiddenStore(self)
    if store[frame] == nil then
        store[frame] = {
            alpha = type(frame.GetAlpha) == "function" and frame:GetAlpha() or 1,
            shown = type(frame.IsShown) == "function" and frame:IsShown() == true or false,
        }
    end

    if type(frame.Hide) == "function" then
        Util.SafeCall(frame.Hide, frame)
    end
    frame:SetAlpha(0)
end

local function CancelEffect(self, frame)
    if not frame then
        return
    end

    local effectStore = GetEffectStore(self)
    if effectStore[frame] == nil and CancelFrameEffect(frame) then
        effectStore[frame] = true
    end
end

function ns.OverlayView:ResetWidgetVisibilityRetry()
    self.visibilityRetryPending = nil
    self.visibilityRetryCount = nil
    self.visibilityRetryWidgetID = nil
end

function ns.OverlayView:ScheduleWidgetVisibilityRetry(reason, resolution)
    if self.visibilityRetryPending then
        return
    end

    local controller = ns.Controller
    local widgetID = resolution and resolution.activeWidgetID or (controller and controller.activeWidgetID) or nil
    if not widgetID then
        return
    end

    if self.visibilityRetryWidgetID ~= widgetID then
        self.visibilityRetryWidgetID = widgetID
        self.visibilityRetryCount = 0
    end

    local retryCount = (self.visibilityRetryCount or 0) + 1
    if retryCount > 5 then
        self.visibilityRetryCount = nil
        self.visibilityRetryWidgetID = nil
        return
    end

    self.visibilityRetryPending = true
    self.visibilityRetryCount = retryCount

    if not (type(C_Timer) == "table" and type(C_Timer.After) == "function") then
        self.visibilityRetryPending = nil
        return
    end

    C_Timer.After(0.20, function()
        self.visibilityRetryPending = nil

        local activeController = ns.Controller
        local activeSnapshot = activeController and activeController.lastSnapshot or nil
        if not activeController
            or not activeSnapshot
            or not activeSnapshot.active
            or not ShouldHideBlizzardWidget()
            or not (ns.Settings and ns.Settings:IsEnabled())
        then
            self:ResetWidgetVisibilityRetry()
            return
        end

        activeController:Refresh("widgetVisibilityRetry")
    end)
end

function ns.OverlayView:RestoreHiddenWidgets(restoreVisibility)
    local store = self._hiddenFrames
    if store then
        for frame, state in pairs(store) do
            if type(frame.SetAlpha) == "function" then
                frame:SetAlpha(state.alpha or 1)
            end
            if restoreVisibility and state.shown and type(frame.Show) == "function" then
                Util.SafeCall(frame.Show, frame)
            end
            store[frame] = nil
        end
    end

    local effectStore = self._hiddenEffects
    if effectStore then
        for frame in pairs(effectStore) do
            if restoreVisibility then
                RestoreFrameEffect(frame)
            end
            effectStore[frame] = nil
        end
    end
end

function ns.OverlayView:HideStandaloneWidgetFrame(frame)
    if not IsFrameUsable(frame) then
        return
    end

    CancelEffect(self, frame)
    HideFrame(self, frame)
end

function ns.OverlayView:HideWidgetFrame(widgetFrame, resolution)
    if not IsFrameUsable(widgetFrame) then
        return
    end

    CancelEffect(self, widgetFrame)
    HideFrame(self, widgetFrame)

    local preyIconFrame = ns.OverlayView.preyHuntIconFrame
    if preyIconFrame and preyIconFrame ~= widgetFrame and IsFrameUsable(preyIconFrame) then
        CancelEffect(self, preyIconFrame)
        HideFrame(self, preyIconFrame)
    end
end

function ns.OverlayView:RestoreHiddenWidget(restoreVisibility)
    self:ResetWidgetVisibilityRetry()
    self:RestoreHiddenWidgets(restoreVisibility)
    self.hiddenWidgetFrame = nil
    self.hiddenWidgetID = nil
end

function ns.OverlayView:ApplyWidgetVisibility(snapshot, resolution)
    local widgetFrame = resolution and resolution.widgetFrame or nil
    local widgetID = resolution and resolution.activeWidgetID or nil
    local shouldHide = snapshot
        and snapshot.active
        and ShouldHideBlizzardWidget()
        and IsFrameUsable(widgetFrame)

    if not shouldHide then
        self:ResetWidgetVisibilityRetry()
        self:RestoreHiddenWidgets(true)
        self.hiddenWidgetFrame = nil
        self.hiddenWidgetID = nil
        return
    end

    self:ResetWidgetVisibilityRetry()
    if self.hiddenWidgetFrame and self.hiddenWidgetFrame ~= widgetFrame then
        self:RestoreHiddenWidgets(false)
        self.hiddenWidgetFrame = nil
        self.hiddenWidgetID = nil
    elseif self.hiddenWidgetID and widgetID and self.hiddenWidgetID ~= widgetID then
        self:RestoreHiddenWidgets(false)
        self.hiddenWidgetFrame = nil
        self.hiddenWidgetID = nil
    end

    self:HideWidgetFrame(widgetFrame, resolution)
    self.hiddenWidgetFrame = widgetFrame
    self.hiddenWidgetID = widgetID
end

function ns.OverlayView:SyncWidgetVisibility(snapshot, resolution)
    if not snapshot or not snapshot.active then
        local shouldRestoreVisibility = not (ns.Settings and ns.Settings:IsEnabled() and ShouldHideBlizzardWidget())
        self:RestoreHiddenWidget(shouldRestoreVisibility)
        return
    end

    if not ShouldHideBlizzardWidget() then
        self:ResetWidgetVisibilityRetry()
        self:RestoreHiddenWidgets(true)
        self.hiddenWidgetFrame = nil
        self.hiddenWidgetID = nil
        return
    end

    if not (resolution and resolution.widgetFrame) then
        self:ScheduleWidgetVisibilityRetry("widgetFrameMissing", resolution)
        return
    end

    self:ApplyWidgetVisibility(snapshot, resolution)
end
