-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

local Constants = ns.Constants
local Settings = ns.Settings
local Util = ns.Util
local L = ns.L

local SP = {}
ns._SP = SP

SP.ADDON_NAME = ADDON_NAME
SP.PANEL_NAME = "PreybreakerSettingsPanel"
SP.BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
SP.SAMPLE_STATE = (Enum and Enum.PreyHuntProgressState and Enum.PreyHuntProgressState.Hot) or 2
SP.MODE_OPTIONS = {
    { value = Constants.DisplayMode.Radial, label = L["Ring"] },
    { value = Constants.DisplayMode.Orbs, label = L["Orbs"] },
    { value = Constants.DisplayMode.Bar, label = L["Bar"] },
    { value = Constants.DisplayMode.Text, label = L["Text"] },
}

SP.ORDERED_STATES = Constants.OrderedStates
SP.DEFAULT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = {
        left = 3,
        right = 3,
        top = 3,
        bottom = 3,
    },
}

function SP.SetTextColor(fontString, color, alpha)
    fontString:SetTextColor(color[1], color[2], color[3], alpha or 1)
end

function SP.ApplyBackdrop(frame, backgroundColor, borderColor)
    if type(frame.SetBackdrop) ~= "function" then
        return
    end

    frame:SetBackdrop(SP.DEFAULT_BACKDROP)
    frame:SetBackdropColor(
        backgroundColor[1],
        backgroundColor[2],
        backgroundColor[3],
        backgroundColor[4] or 1
    )
    frame:SetBackdropBorderColor(
        borderColor[1],
        borderColor[2],
        borderColor[3],
        borderColor[4] or 1
    )
end

function SP.ApplyDialogBackdrop(frame)
    local panel = Constants.SettingsPanel
    SP.ApplyBackdrop(frame, panel.SurfaceColor, panel.BorderColor)
end

function SP.ApplyCardBackdrop(frame)
    local panel = Constants.SettingsPanel
    SP.ApplyBackdrop(frame, panel.SurfaceRaisedColor, panel.BorderSoftColor)
end

function SP.ApplyInsetBackdrop(frame)
    local panel = Constants.SettingsPanel
    SP.ApplyBackdrop(frame, panel.SurfaceInsetColor, panel.BorderSoftColor)
end

function SP.AddSpecialFrame(frameName)
    if type(UISpecialFrames) ~= "table" then
        return
    end

    for _, name in ipairs(UISpecialFrames) do
        if name == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

function SP.CreateAccentLine(parent, anchor, alpha)
    local panel = Constants.SettingsPanel
    local accent = parent:CreateTexture(nil, "ARTWORK")
    accent:SetHeight(1)
    accent:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], alpha or 0.28)
    accent:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
    accent:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -1)
    return accent
end

function SP.AddFieldHighlight(frame, alpha)
    local panel = Constants.SettingsPanel
    local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(true)
    highlight:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], alpha or 0.06)
    return highlight
end

function SP.ResolveValue(value)
    if type(value) == "function" then
        return value()
    end

    return value
end

function SP.GetPreviewSnapshot(snapshot)
    if snapshot and snapshot.active then
        return snapshot, true
    end

    local controller = ns.Controller
    if controller and controller.lastSnapshot and controller.lastSnapshot.active then
        return controller.lastSnapshot, true
    end

    local progress = Constants.ProgressByState[SP.SAMPLE_STATE] or 0.67
    return {
        active = true,
        progressState = SP.SAMPLE_STATE,
        progress = progress,
        percent = Util.RoundPercent(progress),
    }, false
end

function SP.GetDisplayModeSummary(displayMode)
    if displayMode == Constants.DisplayMode.Bar then
        return L["Bar"]
    end
    if displayMode == Constants.DisplayMode.Orbs then
        return L["Orb strip"]
    end
    if displayMode == Constants.DisplayMode.Text then
        return L["Text only"]
    end

    return L["Ring"]
end

function SP.GetReadoutSummary()
    local textLabel = Settings:ShouldShowValueText() and L["Number on"] or L["Number off"]
    local badgeLabel = L["Badge off"]
    if Settings:GetDisplayMode() ~= Constants.DisplayMode.Bar and Settings:ShouldShowStageBadge() then
        badgeLabel = L["Badge on"]
    end

    return string.format("%s, %s", textLabel, badgeLabel)
end

function SP.GetQuestHelperSummary()
    local autoWatch = Settings:ShouldAutoWatchPreyQuest()
    local autoSuperTrack = Settings:ShouldAutoSuperTrackPreyQuest()
    if autoWatch and autoSuperTrack then
        return L["Watch + waypoint focus"]
    end
    if autoWatch then
        return L["Watch list only"]
    end
    if autoSuperTrack then
        return L["Waypoint focus only"]
    end

    return L["Off"]
end

function SP.GetPreviewWidgetAtlas(progressState)
    local atlasMap = Constants.Media.PreyWidgetAtlasByState
    return atlasMap and atlasMap[progressState] or "ui-prey-targeticon-inprogress"
end

function SP.ApplyPreviewWidgetTexture(texture, snapshot)
    local progressState = snapshot and snapshot.progressState or SP.SAMPLE_STATE
    local atlasName = SP.GetPreviewWidgetAtlas(progressState)
    local atlasInfo = Constants.Media.PreyWidgetAtlasFallback[atlasName]
    local widgetScale = Constants.SettingsPanel.PreviewWidgetScale or 1

    texture:SetTexture(Constants.Media.PreyWidgetTexture)
    texture:SetVertexColor(1, 1, 1, 1)
    texture:SetTexCoord(0, 1, 0, 1)
    if atlasInfo then
        texture:SetSize(atlasInfo.width * widgetScale, atlasInfo.height * widgetScale)
        texture:SetTexCoord(atlasInfo.left, atlasInfo.right, atlasInfo.top, atlasInfo.bottom)
    end
end

function SP.GetPreviewDetachedOffset(value, limit)
    local scaled = (tonumber(value) or 0) / 12
    if scaled > limit then
        return limit
    end
    if scaled < -limit then
        return -limit
    end

    return scaled
end

function SP.UpdateBadgeAnchor(badge, progress, valueText, showValueText)
    badge:ClearAllPoints()
    if showValueText then
        badge:SetPoint("TOP", valueText, "BOTTOM", Constants.Layout.StageBadgeOffsetX, Constants.Layout.StageBadgeOffsetY)
        return
    end

    badge:SetPoint("TOP", progress, "BOTTOM", Constants.Layout.StageBadgeOffsetX, Constants.Layout.StageBadgeCompactOffsetY)
end

function SP.UpdatePreviewProgress(progressFrame, displayMode, snapshot, color)
    if displayMode ~= Constants.DisplayMode.Orbs and progressFrame and progressFrame.SetSwipeColor then
        progressFrame:SetSwipeColor(color[1], color[2], color[3], 0.97)
    end

    if displayMode == Constants.DisplayMode.Orbs and type(progressFrame.SetStageState) == "function" then
        progressFrame:SetStageState(snapshot.progressState)
    end

    progressFrame:SetPercentage(snapshot.progress or 0)
end

function SP.GetPreviewNote(live)
    if not Settings:IsEnabled() then
        return L["Preview stays available while the tracker is turned off."]
    end

    if Settings:IsDetached() then
        if Settings:IsDetachedPositionLocked() then
            return L["Floating layout locked. Unlock it to drag the live tracker."]
        end

        return L["Floating layout ready. Drag the live tracker when a hunt is active."]
    end

    local displayMode = Settings:GetDisplayMode()
    local hideWidget = Settings:ShouldHideBlizzardWidget()
    if displayMode == Constants.DisplayMode.Text then
        if hideWidget then
            return L["Text view without the Blizzard prey icon."]
        end

        return L["Text view attached to the Blizzard prey icon."]
    end

    if displayMode == Constants.DisplayMode.Bar then
        if hideWidget then
            return L["Bar view without the Blizzard prey icon."]
        end

        return L["Bar view anchored below the Blizzard prey icon."]
    end

    if displayMode == Constants.DisplayMode.Orbs then
        if hideWidget then
            return L["Orb view without the Blizzard prey icon."]
        end

        return L["Orb view attached to the Blizzard prey icon."]
    end

    if hideWidget then
        return live and L["Ring view without the Blizzard prey icon."] or L["Ring sample without the Blizzard prey icon."]
    end

    return live and L["Ring view attached to the Blizzard prey icon."] or L["Ring sample attached to the Blizzard prey icon."]
end

function SP.CreateActionButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end
