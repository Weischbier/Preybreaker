-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- OverlayView: widget-hiding subsystem.
-- Adds Blizzard widget suppression and restoration methods to ns.OverlayView.
-- Loaded before OverlayView.lua, which owns rendering and anchoring.

local _, ns = ...

ns.OverlayView = ns.OverlayView or {}

local Util = ns.Util
local OverlayResolver = ns.OverlayResolver
local AnchorResolver = ns.AnchorResolver
local WidgetVis = ns.WidgetVisibility

local IsOverlayFrame = AnchorResolver.IsOverlayFrame
local IsFrameObject = AnchorResolver.IsFrameObject
local SafeCollectObjects = AnchorResolver.SafeCollectObjects
local IsLikelyAttachedWidgetVisual = AnchorResolver.IsLikelyAttachedWidgetVisual
local GetFrameWidgetID = AnchorResolver.GetFrameWidgetID
local NameHasVisualHint = OverlayResolver.NameHasVisualHint
local IsSquareishObject = OverlayResolver.IsSquareishObject
local CancelFrameEffect = WidgetVis.CancelFrameEffect
local RestoreFrameEffect = WidgetVis.RestoreFrameEffect

local function ShouldHideBlizzardWidget()
    local settings = ns.Settings
    return settings and settings:ShouldHideBlizzardWidget() or false
end

local function GetVisibilityStore(self)
    if not self.hiddenWidgetAlphaByObject then
        self.hiddenWidgetAlphaByObject = setmetatable({}, { __mode = "k" })
    end

    return self.hiddenWidgetAlphaByObject
end

local function GetAnimationVisibilityStore(self)
    if not self.hiddenWidgetAnimationByGroup then
        self.hiddenWidgetAnimationByGroup = setmetatable({}, { __mode = "k" })
    end

    return self.hiddenWidgetAnimationByGroup
end

local function GetEffectVisibilityStore(self)
    if not self.hiddenWidgetEffectByFrame then
        self.hiddenWidgetEffectByFrame = setmetatable({}, { __mode = "k" })
    end

    return self.hiddenWidgetEffectByFrame
end

local function GetShownVisibilityStore(self)
    if not self.hiddenWidgetShownStateByFrame then
        self.hiddenWidgetShownStateByFrame = setmetatable({}, { __mode = "k" })
    end

    return self.hiddenWidgetShownStateByFrame
end

local function GetWidgetVisibilityParent(widgetFrame, resolution)
    if not widgetFrame or type(widgetFrame.GetParent) ~= "function" then
        return nil
    end

    local parent = widgetFrame:GetParent()
    if not IsFrameObject(parent) or parent == UIParent then
        return nil
    end

    return parent
end

local function IsExplicitWidgetOwner(frame, resolution)
    if not IsFrameObject(frame) then
        return false
    end

    local activeWidgetID = resolution and resolution.activeWidgetID or nil
    return activeWidgetID and GetFrameWidgetID(frame) == activeWidgetID or false
end

local function IsHeuristicWidgetVisual(frame, widgetFrame)
    return IsFrameObject(frame)
        and NameHasVisualHint(frame)
        and IsLikelyAttachedWidgetVisual(frame, widgetFrame)
end

local function ShouldSuppressParentFrame(parent, widgetFrame, resolution)
    if not parent or parent == widgetFrame or IsOverlayFrame(parent) then
        return false
    end

    return IsExplicitWidgetOwner(parent, resolution) or IsHeuristicWidgetVisual(parent, widgetFrame)
end

local function IsLikelySiblingIconFrame(child, widgetFrame)
    if not IsFrameObject(child) or not IsFrameObject(widgetFrame) then
        return false
    end

    if not IsSquareishObject(child) then
        return false
    end

    return IsLikelyAttachedWidgetVisual(child, widgetFrame)
end

local function ShouldSuppressSiblingVisual(child, widgetFrame, resolution)
    if not IsFrameObject(child) or child == widgetFrame or IsOverlayFrame(child) then
        return false
    end

    if IsExplicitWidgetOwner(child, resolution) then
        return true
    end

    if IsHeuristicWidgetVisual(child, widgetFrame) then
        return true
    end

    return IsLikelySiblingIconFrame(child, widgetFrame)
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
        ns.Debug:Log(
            "visibility",
            ns.Debug:KV("retry", "paused"),
            ns.Debug:KV("reason", reason or "widgetFrameMissing"),
            ns.Debug:KV("widgetID", widgetID),
            "resume=nextEvent"
        )
        self.visibilityRetryCount = nil
        self.visibilityRetryWidgetID = nil
        return
    end

    self.visibilityRetryPending = true
    self.visibilityRetryCount = retryCount

    ns.Debug:Log(
        "visibility",
        ns.Debug:KV("retry", retryCount),
        ns.Debug:KV("reason", reason or "widgetFrameMissing"),
        ns.Debug:KV("widgetID", widgetID)
    )

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
    local shouldRestoreVisibility = restoreVisibility == true

    local alphaStore = self.hiddenWidgetAlphaByObject
    if alphaStore then
        for object, alpha in pairs(alphaStore) do
            if type(object.SetAlpha) == "function" then
                object:SetAlpha(alpha or 1)
            end
            alphaStore[object] = nil
        end
    end

    local shownStore = self.hiddenWidgetShownStateByFrame
    if shownStore then
        for frame, wasShown in pairs(shownStore) do
            if shouldRestoreVisibility and wasShown and type(frame.Show) == "function" then
                Util.SafeCall(frame.Show, frame)
            end
            shownStore[frame] = nil
        end
    end

    local effectStore = self.hiddenWidgetEffectByFrame
    if effectStore then
        for frame in pairs(effectStore) do
            if shouldRestoreVisibility and RestoreFrameEffect(frame) then
                ns.Debug:Log(
                    "visibility",
                    "restore=scriptedEffect",
                    ns.Debug:KV("object", ns.Debug:DescribeObject(frame)),
                    ns.Debug:KV("effectID", frame.scriptedAnimationEffectID),
                    ns.Debug:KV("modelSceneLayer", frame.modelSceneLayer)
                )
            end
            effectStore[frame] = nil
        end
    end

    local animationStore = self.hiddenWidgetAnimationByGroup
    if not animationStore then
        return
    end

    for animationGroup, wasPlaying in pairs(animationStore) do
        if shouldRestoreVisibility and wasPlaying and type(animationGroup.Play) == "function" then
            Util.SafeCall(animationGroup.Play, animationGroup)
        end
        animationStore[animationGroup] = nil
    end
end

function ns.OverlayView:HideStandaloneWidgetFrame(frame)
    if not IsFrameObject(frame) then
        return
    end

    -- Blizzard can attach prey effects to the shared widget container model scene
    -- while keeping the controller on the frame. Cancel that first so overlay-only
    -- mode hides the final-stage blob along with the regular frame art.
    local effectStore = GetEffectVisibilityStore(self)
    if effectStore[frame] == nil and CancelFrameEffect(frame) then
        effectStore[frame] = true
        ns.Debug:Log(
            "visibility",
            "suppress=scriptedEffect",
            ns.Debug:KV("object", ns.Debug:DescribeObject(frame)),
            ns.Debug:KV("effectID", frame.scriptedAnimationEffectID),
            ns.Debug:KV("modelSceneLayer", frame.modelSceneLayer)
        )
    end

    local shownStore = GetShownVisibilityStore(self)
    if shownStore[frame] == nil then
        shownStore[frame] = type(frame.IsShown) == "function" and frame:IsShown() == true or false
    end

    if type(frame.Hide) == "function" then
        Util.SafeCall(frame.Hide, frame)
    end

    if type(frame.SetAlpha) == "function" then
        local alphaStore = GetVisibilityStore(self)
        if alphaStore[frame] == nil then
            alphaStore[frame] = type(frame.GetAlpha) == "function" and frame:GetAlpha() or 1
        end
        frame:SetAlpha(0)
    end
end

local function SuppressAnimationGroups(ctx, object)
    local groups = SafeCollectObjects(object, "GetAnimationGroups")
    if not groups then
        return
    end

    for _, group in ipairs(groups) do
        if group then
            if ctx.animationStore[group] == nil then
                ctx.animationStore[group] = Util.SafeCall(group.IsPlaying, group) == true
            end
            if type(group.Stop) == "function" then
                Util.SafeCall(group.Stop, group)
            end
        end
    end
end

local function SuppressObjectTree(ctx, object, depth)
    if not object or ctx.visited[object] or depth > 8 or IsOverlayFrame(object) then
        return
    end

    ctx.visited[object] = true
    SuppressAnimationGroups(ctx, object)

    if IsFrameObject(object) then
        ctx.view:HideStandaloneWidgetFrame(object)
    elseif type(object.SetAlpha) == "function" then
        if ctx.alphaStore[object] == nil then
            ctx.alphaStore[object] = type(object.GetAlpha) == "function" and object:GetAlpha() or 1
        end
        object:SetAlpha(0)
    end

    local regions = SafeCollectObjects(object, "GetRegions")
    if regions then
        for _, region in ipairs(regions) do
            SuppressObjectTree(ctx, region, depth + 1)
        end
    end

    local children = SafeCollectObjects(object, "GetChildren")
    if children then
        for _, child in ipairs(children) do
            SuppressObjectTree(ctx, child, depth + 1)
        end
    end
end

local function SuppressParentVisuals(ctx, parent)
    if not parent or ctx.visited[parent] then
        return
    end

    if ShouldSuppressParentFrame(parent, ctx.widgetFrame, ctx.resolution) then
        SuppressObjectTree(ctx, parent, 0)
        return
    end

    ctx.visited[parent] = true

    local children = SafeCollectObjects(parent, "GetChildren")
    if not children then
        return
    end

    for _, child in ipairs(children) do
        if ShouldSuppressSiblingVisual(child, ctx.widgetFrame, ctx.resolution) then
            SuppressObjectTree(ctx, child, 1)
        end
    end
end

function ns.OverlayView:HideWidgetFrame(widgetFrame, resolution)
    if not IsFrameObject(widgetFrame) then
        return
    end

    local ctx = {
        view = self,
        widgetFrame = widgetFrame,
        resolution = resolution,
        alphaStore = GetVisibilityStore(self),
        animationStore = GetAnimationVisibilityStore(self),
        visited = {},
    }

    SuppressObjectTree(ctx, widgetFrame, 0)
    SuppressParentVisuals(ctx, GetWidgetVisibilityParent(widgetFrame, resolution))

    -- The anchor target (icon texture) may live outside the widget frame tree
    -- (e.g. a sibling in the container). Suppress it and its host explicitly.
    local anchorTarget = resolution and resolution.target
    if anchorTarget and not ctx.visited[anchorTarget] and type(anchorTarget.SetAlpha) == "function" then
        SuppressObjectTree(ctx, anchorTarget, 0)
        if type(anchorTarget.GetParent) == "function" then
            local anchorHost = anchorTarget:GetParent()
            if anchorHost and not ctx.visited[anchorHost] and anchorHost ~= widgetFrame then
                SuppressObjectTree(ctx, anchorHost, 0)
            end
        end
    end

    -- The prey hunt icon is a separate widget type (UIWidgetTemplatePreyHuntProgress)
    -- living in its own container, independent of the status bar widget. A hook on
    -- the Blizzard mixin captures a direct reference when Setup() fires.
    local preyIconFrame = ns.OverlayView.preyHuntIconFrame
    if preyIconFrame and not ctx.visited[preyIconFrame] and IsFrameObject(preyIconFrame) then
        SuppressObjectTree(ctx, preyIconFrame, 0)
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
        and IsFrameObject(widgetFrame)
        and type(widgetFrame.SetAlpha) == "function"

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
