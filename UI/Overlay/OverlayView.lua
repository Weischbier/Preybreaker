-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- OverlayView: rendering and anchoring subsystem.
-- Widget-hiding methods are contributed by WidgetHiding.lua (loaded first).

local _, ns = ...

local Constants = ns.Constants
local Util = ns.Util
local OverlayResolver = ns.OverlayResolver
local AnchorResolver = ns.AnchorResolver

local IsSameOrDescendant = OverlayResolver.IsSameOrDescendant
local IsAnchorTargetUsable = AnchorResolver.IsAnchorTargetUsable
local IsFrameObject = AnchorResolver.IsFrameObject
local ResolveBestAnchorTarget = AnchorResolver.ResolveBestAnchorTarget
local ResolveHostFrame = AnchorResolver.ResolveHostFrame

ns.OverlayView = ns.OverlayView or {}

local OVERLAY_NAME = "PreybreakerOverlayFrame"
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local STAGE_BADGE_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local function GetSettings()
    return ns.Settings
end

local function ShouldShowValueText()
    local settings = GetSettings()
    return not settings or settings:ShouldShowValueText()
end

local function ShouldShowStageBadge()
    local settings = GetSettings()
    return not settings or settings:ShouldShowStageBadge()
end

local function GetOverlayScale()
    local settings = GetSettings()
    return settings and settings:GetScale() or 1
end

local function GetDisplayMode()
    local settings = GetSettings()
    return settings and settings:GetDisplayMode() or Constants.DisplayMode.Radial
end

local function ShouldHideBlizzardWidget()
    local settings = GetSettings()
    return settings and settings:ShouldHideBlizzardWidget() or false
end

local function ShouldShowTrackerTooltip()
    local settings = GetSettings()
    return settings and settings:ShouldShowTrackerTooltip() or false
end

local function ShouldShowContextLine()
    local settings = GetSettings()
    return settings and settings:ShouldShowTrackerContextLine() or false
end

local function GetAnchorOffsetX()
    local settings = GetSettings()
    return settings and settings:GetOffsetX() or 0
end

local function GetAnchorOffsetY()
    local settings = GetSettings()
    return settings and settings:GetOffsetY() or 0
end

local function ResolveOverlayStrata(host)
    return OverlayResolver.ResolveOverlayStrata(host, Constants.Layout.FrameStrata)
end

local function OpenPreyQuestMap()
    if type(OpenWorldMap) ~= "function" then
        return
    end

    local snapshot = ns.OverlayView.currentSnapshot or (ns.Controller and ns.Controller.lastSnapshot) or nil
    local questID = snapshot and (snapshot.questID or snapshot.worldQuestID or snapshot.activeQuestID) or nil
    local mapID = snapshot and snapshot.mapID or nil
    if not questID then
        local context = Util.BuildPreyQuestContext()
        questID = context.trackedQuestID or context.worldQuestID or context.activeQuestID
        mapID = context.mapID
    end

    if questID then
        mapID = Util.GetQuestMapID(questID) or mapID
        if mapID then
            OpenWorldMap(mapID)
            if EventRegistry and type(EventRegistry.TriggerEvent) == "function" then
                EventRegistry:TriggerEvent("MapCanvas.PingQuestID", questID)
            end
            return
        end
    end

    if type(C_Map) == "table" and type(C_Map.GetBestMapForUnit) == "function" then
        local mapID = Util.SafeCall(C_Map.GetBestMapForUnit, "player")
        if mapID then
            OpenWorldMap(mapID)
        end
    end
end

local function ResolveSnapshotQuestID(snapshot)
    if type(snapshot) ~= "table" then
        return nil
    end

    local questID = snapshot.questID or snapshot.worldQuestID or snapshot.activeQuestID
    return type(questID) == "number" and questID or nil
end

local function BuildHuntContext(snapshot)
    local questID = ResolveSnapshotQuestID(snapshot)
    local hunt = questID and ns.HuntList and ns.HuntList.GetHuntByQuestID and ns.HuntList:GetHuntByQuestID(questID) or nil
    local recent = questID and ns.HuntJournal and ns.HuntJournal.GetRecentByQuestID and ns.HuntJournal:GetRecentByQuestID(questID) or nil
    local rewardPreview = hunt and ns.HuntPlanner and ns.HuntPlanner.GetRewardPreview and ns.HuntPlanner:GetRewardPreview(hunt) or nil

    return {
        questID = questID,
        hunt = hunt,
        recent = recent,
        rewardPreview = rewardPreview,
    }
end

local function GetContextLineText(snapshot)
    local context = BuildHuntContext(snapshot)
    local hunt = context.hunt
    if hunt and hunt.name then
        return string.format("%s | %s", hunt.name, hunt.zone or "Unknown zone")
    end
    if context.questID then
        return string.format("Quest %d", context.questID)
    end
    return nil
end

local function ShowTrackerTooltip(owner)
    if not owner or not GameTooltip or not ShouldShowTrackerTooltip() then
        return
    end

    local snapshot = ns.OverlayView.currentSnapshot or (ns.Controller and ns.Controller.lastSnapshot) or nil
    if not snapshot or not snapshot.active then
        return
    end

    local context = BuildHuntContext(snapshot)
    local hunt = context.hunt
    local stageLabel = Constants.StageLabelByState[snapshot.progressState] or "ACTIVE"

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(hunt and hunt.name or "Prey Hunt", 1, 1, 1)
    GameTooltip:AddLine(string.format("%s %d%%", stageLabel, snapshot.percent or 0), 1, 0.82, 0.18)

    if hunt then
        GameTooltip:AddLine(string.format("%s | %s", hunt.difficulty or "Unknown difficulty", hunt.zone or "Unknown zone"), 0.85, 0.82, 0.72, true)
    elseif context.questID then
        GameTooltip:AddLine(string.format("Quest %d", context.questID), 0.85, 0.82, 0.72, true)
    end

    if context.rewardPreview and context.rewardPreview.reason then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(context.rewardPreview.reason, 0.95, 0.76, 0.25, true)
    end

    if hunt and hunt.achievement and hunt.achievement.isIncomplete then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(hunt.achievement.markerText or "Achievement progress available.", 0.82, 0.90, 0.63, true)
    end

    if context.recent and context.recent.completedDate then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Last completed: " .. context.recent.completedDate, 0.65, 0.85, 1, true)
    end

    if ns.OverlayView:ShouldHandleFinalClick() then
        GameTooltip:AddLine(" ")
        if type(InCombatLockdown) == "function" and InCombatLockdown() then
            GameTooltip:AddLine("Map click is blocked in combat.", 1, 0.25, 0.2, true)
        else
            GameTooltip:AddLine("Left-click: open objective map.", 0.65, 0.85, 1, true)
        end
    end

    GameTooltip:Show()
end

local function ApplyStageBadgeStyle(frame)
    if not frame or type(frame.SetBackdrop) ~= "function" then
        return
    end

    frame:SetBackdrop(STAGE_BADGE_BACKDROP)
    frame:SetBackdropColor(0.08, 0.06, 0.04, 0.92)
    frame:SetBackdropBorderColor(0.84, 0.64, 0.28, 0.90)
end

local function CreateStageBadge(parent, relativeTo)
    local layout = Constants.Layout

    local badge = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    badge:SetSize(layout.StageBadgeWidth, layout.StageBadgeHeight)
    badge:SetPoint("TOP", relativeTo, "BOTTOM", layout.StageBadgeOffsetX, layout.StageBadgeOffsetY)
    badge:SetFrameLevel(parent:GetFrameLevel() + 2)
    ApplyStageBadgeStyle(badge)

    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetJustifyH("CENTER")
    text:SetPoint("CENTER", badge, "CENTER", 0, 0)
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(1, -1)

    return badge, text
end

local function UpdateStageBadgeAnchor(badge, progress, valueText, showValueText)
    badge:ClearAllPoints()
    if showValueText then
        badge:SetPoint("TOP", valueText, "BOTTOM", Constants.Layout.StageBadgeOffsetX, Constants.Layout.StageBadgeOffsetY)
        return
    end

    badge:SetPoint("TOP", progress, "BOTTOM", Constants.Layout.StageBadgeOffsetX, Constants.Layout.StageBadgeCompactOffsetY)
end

local function UpdateActiveProgress(progressFrame, displayMode, snapshot, color)
    if displayMode ~= Constants.DisplayMode.Orbs and progressFrame.SetSwipeColor then
        progressFrame:SetSwipeColor(color[1], color[2], color[3], 0.97)
    end

    if displayMode == Constants.DisplayMode.Orbs and type(progressFrame.SetStageState) == "function" then
        progressFrame:SetStageState(snapshot.progressState)
    end

    progressFrame:SetPercentage(snapshot.progress)
end

local function ApplyOverlayTextStyles(view, force)
    if not force and not view._textStyleDirty then
        return
    end

    local textStyle = ns.TextStyle
    if not textStyle then
        return
    end

    if view.progress and view.progress.ValueText then
        textStyle:ApplyValue(view.progress.ValueText)
    end
    if view.barProgress and view.barProgress.ValueText then
        textStyle:ApplyValue(view.barProgress.ValueText)
    end
    if view.orbProgress and view.orbProgress.ValueText then
        textStyle:ApplyValue(view.orbProgress.ValueText)
    end
    if view.stageText then
        textStyle:ApplyStage(view.stageText)
    end
    if view.textDisplay then
        textStyle:ApplyValue(view.textDisplay)
    end

    view._textStyleDirty = false
end

local function ResetInactiveVisuals(view)
    if view.progress and type(view.progress.SnapToPercentage) == "function" then
        view.progress:SnapToPercentage(0)
    end
    if view.barProgress and type(view.barProgress.SnapToPercentage) == "function" then
        view.barProgress:SnapToPercentage(0)
    end
    if view.orbProgress then
        local defaultState = (Constants.OrderedStates and Constants.OrderedStates[1]) or 0
        if type(view.orbProgress.SetStageState) == "function" then
            view.orbProgress:SetStageState(defaultState)
        end
        if type(view.orbProgress.SetPercentage) == "function" then
            view.orbProgress:SetPercentage(0)
        end
    end
end

function ns.OverlayView:Create()
    if self.frame then
        return self.frame
    end

    local overlay = CreateFrame("Frame", OVERLAY_NAME, UIParent)
    overlay:SetSize(math.max(Constants.Layout.RingSize, Constants.Layout.BarWidth), Constants.Layout.RingSize)
    overlay:SetFrameStrata(Constants.Layout.FrameStrata)
    overlay:SetIgnoreParentAlpha(true)
    overlay:EnableMouse(false)
    overlay:SetMovable(false)
    overlay:SetClampedToScreen(true)
    overlay:SetScript("OnMouseUp", function(_, button)
        ns.OverlayView:HandleMouseUp(button)
    end)
    overlay:SetScript("OnEnter", function(self)
        ShowTrackerTooltip(self)
    end)
    overlay:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    overlay:Hide()

    local progress = ns.CreateRadialProgressBar(overlay, true)
    progress:SetSize(Constants.Layout.ProgressSize, Constants.Layout.ProgressSize)
    progress:SetPoint("CENTER")
    progress.ValueText:ClearAllPoints()
    progress.ValueText:SetPoint(
        "CENTER",
        progress,
        "BOTTOM",
        Constants.Layout.ValueTextOffsetX,
        Constants.Layout.ValueTextOffsetY
    )
    progress.ValueText:SetText("0")

    local barProgress = ns.CreateBarProgress(overlay, true)
    barProgress:SetPoint("TOP", overlay, "TOP", 0, 0)
    barProgress.ValueText:SetText("0")
    barProgress:Hide()

    local orbProgress = ns.CreateOrbProgress(overlay, true)
    orbProgress:SetPoint("CENTER")
    orbProgress.ValueText:SetText("0")
    orbProgress:Hide()

    local stageBadge, stageText = CreateStageBadge(overlay, progress.ValueText)
    UpdateStageBadgeAnchor(stageBadge, progress, progress.ValueText, true)

    local contextText = overlay:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    contextText:SetJustifyH("CENTER")
    contextText:SetWidth(Constants.Layout.BarWidth or Constants.Layout.RingSize)
    contextText:SetText("")
    contextText:Hide()

    if progress.SetSwipeColor then
        progress:SetSwipeColor(0.82, 0.82, 0.86, 0.97)
    end
    if barProgress.SetSwipeColor then
        barProgress:SetSwipeColor(0.82, 0.82, 0.86, 0.97)
    end

    self.frame = overlay
    self.progress = progress
    self.orbProgress = orbProgress
    self.barProgress = barProgress
    self.stageBadge = stageBadge
    self.stageText = stageText
    self.contextText = contextText

    ApplyOverlayTextStyles(self, true)

    self:Anchor()
    return overlay
end

function ns.OverlayView:MarkTextStyleDirty()
    self._textStyleDirty = true
end

function ns.OverlayView:GetActiveProgress()
    local displayMode = GetDisplayMode()
    if displayMode == Constants.DisplayMode.Bar then
        return self.barProgress
    end
    if displayMode == Constants.DisplayMode.Orbs then
        return self.orbProgress
    end

    return self.progress -- Radial is default, text mode doesn't use progress widgets
end

function ns.OverlayView:ShouldHandleFinalClick()
    local finalState = (Enum and Enum.PreyHuntProgressState and Enum.PreyHuntProgressState.Final) or 3
    local snapshot = self.currentSnapshot or (ns.Controller and ns.Controller.lastSnapshot) or nil
    return snapshot
        and snapshot.active
        and snapshot.progressState == finalState
        and ShouldHideBlizzardWidget()
        or false
end

function ns.OverlayView:UpdateInteractivity()
    if not self.frame then
        return
    end

    local mouseEnabled = self:ShouldHandleFinalClick() or ShouldShowTrackerTooltip()
    self.frame:SetMovable(false)
    self.frame:SetClampedToScreen(true)
    self.frame:EnableMouse(mouseEnabled)
end

function ns.OverlayView:HandleMouseUp(button)
    if button ~= "LeftButton" then
        return
    end

    if not self:ShouldHandleFinalClick() then
        return
    end

    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return
    end

    OpenPreyQuestMap()
end

function ns.OverlayView:Anchor()
    if not self.frame then
        return nil
    end

    local resolution = ResolveBestAnchorTarget()
    local target = resolution.target
    local kind = resolution.kind
    local displayMode = GetDisplayMode()
    local hideWidget = ShouldHideBlizzardWidget()

    if not IsAnchorTargetUsable(target) then
        target = UIParent
        kind = "fallback"
        resolution.target = target
    end

    local host = ResolveHostFrame(target)
    if not IsFrameObject(host) or IsSameOrDescendant(host, self.frame) then
        host = UIParent
        target = UIParent
        kind = "fallback"
        resolution.target = target
    end

    self.frame:ClearAllPoints()
    if self.frame:GetParent() ~= UIParent then
        self.frame:SetParent(UIParent)
    end

    self:UpdateInteractivity()

    self.frame:SetFrameStrata(ResolveOverlayStrata(host))

    local hostLevel = (host and type(host.GetFrameLevel) == "function" and host:GetFrameLevel()) or 0
    self.frame:SetFrameLevel(hostLevel + Constants.Layout.FrameLevelOffset)

    if target == UIParent or kind == "fallback" then
        self.frame:SetFrameStrata(Constants.Layout.FrameStrata)
        self.frame:SetPoint(
            "TOP",
            UIParent,
            "TOP",
            Constants.Anchor.OffsetX + GetAnchorOffsetX(),
            Constants.Anchor.FallbackY + Constants.Anchor.OffsetY + GetAnchorOffsetY()
        )
    else
        local anchorPoint = Constants.Anchor.Point
        local relativePoint = Constants.Anchor.RelativePoint
        local anchorTarget = target
        local offsetX = Constants.Anchor.OffsetX
        local offsetY = Constants.Anchor.OffsetY

        if displayMode == Constants.DisplayMode.Bar and kind ~= "container" then
            anchorPoint = "TOP"
            relativePoint = hideWidget and "CENTER" or "BOTTOM"
            anchorTarget = (hideWidget and resolution.widgetFrame) or target
            offsetY = offsetY + (hideWidget and math.floor(Constants.Layout.BarHeight * 0.5) or Constants.Layout.BarVisibleOffsetY)
        elseif kind == "container" then
            offsetX = offsetX + Constants.Anchor.ContainerFallbackOffsetX
            offsetY = offsetY + Constants.Anchor.ContainerFallbackOffsetY
        end

        offsetX = offsetX + GetAnchorOffsetX()
        offsetY = offsetY + GetAnchorOffsetY()
        self.frame:SetPoint(anchorPoint, anchorTarget, relativePoint, offsetX, offsetY)
    end

    ns.Debug:Log(
        "anchor",
        ns.Debug:KV("container", ns.Debug:DescribeObject(resolution.container)),
        ns.Debug:KV("widgetSource", resolution.widgetFrameSource),
        ns.Debug:KV("widget", ns.Debug:DescribeObject(resolution.widgetFrame)),
        ns.Debug:KV("targetKind", kind),
        ns.Debug:KV("target", ns.Debug:DescribeObject(target)),
        ns.Debug:KV("host", ns.Debug:DescribeObject(host)),
        ns.Debug:KV("hostStrata", host and host:GetFrameStrata() or nil),
        ns.Debug:KV("overlayStrata", self.frame:GetFrameStrata()),
        ns.Debug:KV("overlayLevel", self.frame:GetFrameLevel()),
        ns.Debug:KV("displayMode", displayMode),
        ns.Debug:KV("hideWidget", hideWidget),
        ns.Debug:KV("widgetID", resolution.activeWidgetID)
    )

    return resolution
end

function ns.OverlayView:GetEffectiveColor(state)
    if ns.Settings then
        return ns.Settings:GetEffectiveColor(state)
    end
    return Constants.ColorByState[state] or { 1, 1, 1 }
end

function ns.OverlayView:RenderTextOnly(snapshot)
    local showValueText = ShouldShowValueText()
    local showStageBadge = ShouldShowStageBadge()
    local color = self:GetEffectiveColor(snapshot.progressState)
    local stageLabel = Constants.StageLabelByState[snapshot.progressState]
    local valueText = string.format("%d%%", snapshot.percent)

    self.progress:Hide()
    self.orbProgress:Hide()
    self.barProgress:Hide()

    if not self.textDisplay then
        local textFrame = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOutline")
        textFrame:SetPoint("CENTER")
        textFrame:SetJustifyH("CENTER")
        self.textDisplay = textFrame
        ApplyOverlayTextStyles(self, true)
    end

    local displayParts = {}
    if showStageBadge and stageLabel then
        displayParts[#displayParts + 1] = stageLabel
    end
    if showValueText then
        displayParts[#displayParts + 1] = valueText
    end

    local displayText = table.concat(displayParts, " ")
    if displayText == "" then
        displayText = valueText
    end

    self.textDisplay:SetText(displayText)
    self.textDisplay:SetTextColor(color[1], color[2], color[3], 1)
    self.textDisplay:Show()

    self.stageBadge:Hide()
    self.stageText:Hide()
end

function ns.OverlayView:UpdateContextLine(snapshot, anchor)
    if not self.contextText then
        return
    end

    if not ShouldShowContextLine() or not snapshot.active then
        self.contextText:Hide()
        self.contextText:SetText("")
        return
    end

    local text = GetContextLineText(snapshot)
    if not text or text == "" then
        self.contextText:Hide()
        return
    end

    self.contextText:ClearAllPoints()
    self.contextText:SetPoint("TOP", anchor or self.frame, "BOTTOM", 0, -4)
    self.contextText:SetText(text)
    self.contextText:SetTextColor(0.85, 0.82, 0.72, 0.95)
    self.contextText:Show()
end

function ns.OverlayView:Render(snapshot)
    self:Create()
    self.currentSnapshot = snapshot

    if not snapshot.active then
        ApplyOverlayTextStyles(self)
        ResetInactiveVisuals(self)
        self:UpdateContextLine(snapshot)
        local shouldRestoreVisibility = not (ns.Settings and ns.Settings:IsEnabled() and ShouldHideBlizzardWidget())
        self:RestoreHiddenWidget(shouldRestoreVisibility)
        self.frame:Hide()
        return
    end

    local showValueText = ShouldShowValueText()
    local showStageBadge = ShouldShowStageBadge()
    local color = self:GetEffectiveColor(snapshot.progressState)
    local displayMode = GetDisplayMode()

    self.frame:SetScale(GetOverlayScale())
    ApplyOverlayTextStyles(self)

    if displayMode == Constants.DisplayMode.Text then
        self:RenderTextOnly(snapshot)
        local resolution = self:Anchor()
        self:SyncWidgetVisibility(snapshot, resolution)
        self:UpdateContextLine(snapshot, self.textDisplay or self.frame)
        self.frame:Show()
        return
    end

    if self.textDisplay then
        self.textDisplay:Hide()
    end

    local activeProgress = self:GetActiveProgress()
    local canShowStageBadge = showStageBadge and displayMode ~= Constants.DisplayMode.Bar
    local valueText = displayMode == Constants.DisplayMode.Bar and string.format("%d%%", snapshot.percent) or string.format("%d", snapshot.percent)

    self.progress:SetShown(displayMode == Constants.DisplayMode.Radial)
    self.orbProgress:SetShown(displayMode == Constants.DisplayMode.Orbs)
    self.barProgress:SetShown(displayMode == Constants.DisplayMode.Bar)

    activeProgress:ShowNumber(showValueText)
    UpdateStageBadgeAnchor(self.stageBadge, activeProgress, activeProgress.ValueText, showValueText)
    activeProgress.ValueText:SetText(valueText)
    UpdateActiveProgress(activeProgress, displayMode, snapshot, color)

    local stageLabel = Constants.StageLabelByState[snapshot.progressState]
    if canShowStageBadge and stageLabel then
        self.stageBadge:Show()
        self.stageText:Show()
        self.stageText:SetText(stageLabel)
        self.stageText:SetTextColor(color[1], color[2], color[3], 1)
    else
        self.stageBadge:Hide()
        self.stageText:Hide()
        self.stageText:SetText("")
    end

    local resolution = self:Anchor()
    self:SyncWidgetVisibility(snapshot, resolution)
    local contextAnchor = (self.stageBadge and self.stageBadge:IsShown() and self.stageBadge) or activeProgress
    self:UpdateContextLine(snapshot, contextAnchor)
    self.frame:Show()
end
