-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Constants = ns.Constants
local Settings = ns.Settings
local L = ns.L

local SP = ns._SP

local SetTextColor = SP.SetTextColor
local ApplyBackdrop = SP.ApplyBackdrop
local GetPreviewSnapshot = SP.GetPreviewSnapshot
local GetDisplayModeSummary = SP.GetDisplayModeSummary
local GetReadoutSummary = SP.GetReadoutSummary
local GetQuestHelperSummary = SP.GetQuestHelperSummary
local GetPreviewNote = SP.GetPreviewNote
local ApplyPreviewWidgetTexture = SP.ApplyPreviewWidgetTexture
local UpdateBadgeAnchor = SP.UpdateBadgeAnchor
local UpdatePreviewProgress = SP.UpdatePreviewProgress
local UpdatePreviewStageChips = SP.UpdatePreviewStageChips
local PANEL_NAME = SP.PANEL_NAME
local BACKDROP_TEMPLATE = SP.BACKDROP_TEMPLATE

local function ApplyPreviewTextStyles(preview)
    local textStyle = ns.TextStyle
    if not textStyle or not preview then
        return
    end

    if preview.Progress and preview.Progress.ValueText then
        textStyle:ApplyValue(preview.Progress.ValueText)
    end
    if preview.BarProgress and preview.BarProgress.ValueText then
        textStyle:ApplyValue(preview.BarProgress.ValueText)
    end
    if preview.OrbProgress and preview.OrbProgress.ValueText then
        textStyle:ApplyValue(preview.OrbProgress.ValueText)
    end
    if preview.BadgeText then
        textStyle:ApplyStage(preview.BadgeText)
    end
    if preview.TextDisplay then
        textStyle:ApplyValue(preview.TextDisplay)
    end
end

ns.SettingsPanel = {}

function ns.SettingsPanel:RefreshSummary(snapshot, live)
    if not self.summary then
        return
    end

    local panel = Constants.SettingsPanel
    local summary = self.summary
    local statusText
    local statusColor

    if not Settings:IsEnabled() then
        statusText = L["DISABLED"]
        statusColor = panel.MutedColor
        summary.StatusText:SetText(L["Preybreaker is turned off. Your current layout stays saved."])
    elseif live and snapshot and snapshot.active and snapshot.progressState ~= nil then
        local stageLabel = Constants.StageLabelByState[snapshot.progressState] or L["ACTIVE"]
        statusText = string.format("%s %d%%", stageLabel, snapshot.percent or 0)
        statusColor = Constants.ColorByState[snapshot.progressState] or panel.AccentColor
        summary.StatusText:SetText(L["Live prey hunt detected. The preview mirrors the current tracker state."])
    else
        statusText = L["SAMPLE"]
        statusColor = panel.AccentColor
        summary.StatusText:SetText(L["No prey hunt is active right now, so the preview shows a sample state."])
    end

    ApplyBackdrop(
        summary.StatusPill,
        { statusColor[1], statusColor[2], statusColor[3], 0.20 },
        { statusColor[1], statusColor[2], statusColor[3], 0.95 }
    )
    summary.StatusPill.Text:SetText(statusText)
    SetTextColor(summary.StatusPill.Text, panel.TitleColor)

    summary.StyleValue:SetText(GetDisplayModeSummary(Settings:GetDisplayMode()))
    summary.PlacementValue:SetText(L["Attached"])
    summary.WidgetValue:SetText(Settings:ShouldHideBlizzardWidget() and L["Overlay only"] or L["Show both"])
    summary.ReadoutValue:SetText(GetReadoutSummary())
    summary.QuestValue:SetText(GetQuestHelperSummary())

    summary:ResizeToFit()
end

function ns.SettingsPanel:RefreshControls()
    if not self.controls then
        return
    end

    for _, control in ipairs(self.controls) do
        control:Refresh()
    end

    local previewSnapshot, live = GetPreviewSnapshot()
    self:RefreshSummary(previewSnapshot, live)
end

function ns.SettingsPanel:RefreshPreview(snapshot)
    if not self.preview then
        return
    end

    local previewSnapshot, live = GetPreviewSnapshot(snapshot)
    local color = Settings:GetEffectiveColor(previewSnapshot.progressState)
    local showValueText = Settings:ShouldShowValueText()
    local showStageBadge = Settings:ShouldShowStageBadge()
    local displayMode = Settings:GetDisplayMode()
    local hideWidget = Settings:ShouldHideBlizzardWidget()
    local stageLabel = Constants.StageLabelByState[previewSnapshot.progressState]
    local activeProgress = self.preview.Progress
    if displayMode == Constants.DisplayMode.Bar then
        activeProgress = self.preview.BarProgress
    elseif displayMode == Constants.DisplayMode.Orbs then
        activeProgress = self.preview.OrbProgress
    end

    self:RefreshSummary(previewSnapshot, live)
    ApplyPreviewTextStyles(self.preview)

    ApplyPreviewWidgetTexture(self.preview.HostIcon, previewSnapshot)
    self.preview.HostIcon:SetAlpha(hideWidget and 0.14 or 1)

    self.preview.Overlay:ClearAllPoints()
    self.preview.Overlay:SetScale(Settings:GetScale())
    if displayMode == Constants.DisplayMode.Bar then
        self.preview.Overlay:SetPoint(
            "TOP",
            self.preview.Host,
            hideWidget and "CENTER" or "BOTTOM",
            Constants.Anchor.OffsetX + Settings:GetOffsetX(),
            Constants.Anchor.OffsetY
                + (hideWidget and math.floor(Constants.Layout.BarHeight * 0.5) or Constants.Layout.BarVisibleOffsetY)
                + Settings:GetOffsetY()
        )
    else
        self.preview.Overlay:SetPoint(
            Constants.Anchor.Point,
            self.preview.Host,
            Constants.Anchor.RelativePoint,
            Constants.Anchor.OffsetX + Settings:GetOffsetX(),
            Constants.Anchor.OffsetY + Settings:GetOffsetY()
        )
    end

    self.preview.Note:SetText(GetPreviewNote(live))
    UpdatePreviewStageChips(self.preview, previewSnapshot.progressState)

    if displayMode == Constants.DisplayMode.Text then
        self.preview.Progress:Hide()
        self.preview.OrbProgress:Hide()
        self.preview.BarProgress:Hide()
        self.preview.Badge:Hide()
        self.preview.BadgeText:Hide()

        local displayParts = {}
        if showStageBadge and stageLabel then
            displayParts[#displayParts + 1] = stageLabel
        end
        if showValueText then
            displayParts[#displayParts + 1] = string.format("%d%%", previewSnapshot.percent or 0)
        end
        local displayText = table.concat(displayParts, " ")
        if displayText == "" then
            displayText = string.format("%d%%", previewSnapshot.percent or 0)
        end

        self.preview.TextDisplay:SetText(displayText)
        self.preview.TextDisplay:SetTextColor(color[1], color[2], color[3], 1)
        self.preview.TextDisplay:Show()
        return
    end

    if self.preview.TextDisplay then
        self.preview.TextDisplay:Hide()
    end

    local canShowStageBadge = showStageBadge and displayMode ~= Constants.DisplayMode.Bar
    local valueText = displayMode == Constants.DisplayMode.Bar
        and string.format("%d%%", previewSnapshot.percent or 0)
        or string.format("%d", previewSnapshot.percent or 0)

    self.preview.Progress:SetShown(displayMode == Constants.DisplayMode.Radial)
    self.preview.OrbProgress:SetShown(displayMode == Constants.DisplayMode.Orbs)
    self.preview.BarProgress:SetShown(displayMode == Constants.DisplayMode.Bar)

    activeProgress:ShowNumber(showValueText)
    UpdateBadgeAnchor(self.preview.Badge, activeProgress, activeProgress.ValueText, showValueText)

    activeProgress.ValueText:SetText(valueText)
    UpdatePreviewProgress(activeProgress, displayMode, previewSnapshot, color)

    if canShowStageBadge and stageLabel then
        self.preview.Badge:Show()
        self.preview.BadgeText:Show()
        self.preview.BadgeText:SetText(stageLabel)
        self.preview.BadgeText:SetTextColor(color[1], color[2], color[3], 1)
        return
    end

    self.preview.Badge:Hide()
    self.preview.BadgeText:Hide()
    self.preview.BadgeText:SetText("")
end

function ns.SettingsPanel:CommitChange(reason)
    self:RefreshControls()

    if ns.Controller then
        ns.Controller:Refresh(reason or "settings")
        return
    end

    self:RefreshPreview()
end

function ns.SettingsPanel:Create()
    if self.frame then
        return self.frame
    end

    local panel = Constants.SettingsPanel
    local frame = CreateFrame("Frame", PANEL_NAME, UIParent, BACKDROP_TEMPLATE)
    frame:SetSize(panel.Width, panel.Height)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    SP.ApplyDialogBackdrop(frame)
    SP.AddSpecialFrame(PANEL_NAME)

    SP.CreateHeader(frame)

    local sidebar = SP.CreateSidebar(frame)
    frame.sidebar = sidebar

    local content = SP.CreateSections(frame)

    frame:SetScript("OnShow", function()
        ns.SettingsPanel:RefreshControls()
        ns.SettingsPanel:RefreshPreview()
    end)

    self.frame = frame
    self.summary = sidebar.Summary
    self.preview = sidebar.Preview
    self.actions = sidebar.Actions
    self.controls = content.Controls
    self.content = content

    return frame
end

function ns.SettingsPanel:Open()
    local frame = self:Create()
    frame:Show()
    frame:Raise()
end

function ns.SettingsPanel:Close()
    if self.frame then
        self.frame:Hide()
    end
end
