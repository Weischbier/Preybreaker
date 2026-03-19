-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

local Constants = ns.Constants
local Settings = ns.Settings
local Util = ns.Util
local L = ns.L
local SP = ns._SP

local SetTextColor = SP.SetTextColor
local ApplyCardBackdrop = SP.ApplyCardBackdrop
local ApplyInsetBackdrop = SP.ApplyInsetBackdrop
local ApplyAccentLineColor = SP.ApplyAccentLineColor
local ApplyPreviewWidgetTexture = SP.ApplyPreviewWidgetTexture
local SAMPLE_STATE = SP.SAMPLE_STATE
local ORDERED_STATES = SP.ORDERED_STATES

function SP.CreateHeader(frame)
    local panel = Constants.SettingsPanel

    local header = CreateFrame("Frame", nil, frame, "PreybreakerSettingsPanelHeaderTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", panel.Padding, -panel.Padding)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -panel.Padding, -panel.Padding)

    header.Shade:SetColorTexture(0.17, 0.11, 0.06, 0.90)
    header.Glow:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.09)
    header.AccentLine:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.82)
    header.Icon:SetTexture(Constants.Media.AddonIcon)
    header.Title:SetText(ADDON_NAME)
    SetTextColor(header.Title, panel.TitleColor)
    header.Subtitle:SetText(L["Shape the prey tracker around your HUD with a live preview and clear sections."])
    SetTextColor(header.Subtitle, panel.BodyColor)

    header:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    frame.Header = header
end

function SP.CreateSummaryCard(parent)
    local panel = Constants.SettingsPanel

    local card = CreateFrame("Frame", nil, parent, "PreybreakerSummaryCardTemplate")
    card:SetHeight(panel.SummaryCardHeight)
    ApplyCardBackdrop(card)

    SetTextColor(card.Title, panel.TitleColor)
    card.Title:SetText(L["Current setup"])
    SetTextColor(card.StatusText, panel.BodyColor)

    ApplyInsetBackdrop(card.StatusPill)

    card.StyleLabel:SetText(L["Style"])
    SetTextColor(card.StyleLabel, panel.MutedColor)
    SetTextColor(card.StyleValue, panel.TitleColor)

    card.PlacementLabel:SetText(L["Placement"])
    SetTextColor(card.PlacementLabel, panel.MutedColor)
    SetTextColor(card.PlacementValue, panel.TitleColor)

    card.WidgetLabel:SetText(L["Blizzard UI"])
    SetTextColor(card.WidgetLabel, panel.MutedColor)
    SetTextColor(card.WidgetValue, panel.TitleColor)

    card.ReadoutLabel:SetText(L["Readout"])
    SetTextColor(card.ReadoutLabel, panel.MutedColor)
    SetTextColor(card.ReadoutValue, panel.TitleColor)

    card.QuestLabel:SetText(L["Quest help"])
    SetTextColor(card.QuestLabel, panel.MutedColor)
    SetTextColor(card.QuestValue, panel.TitleColor)

    card.Note:SetText(L["Live state shows up here as soon as a prey hunt starts."])
    SetTextColor(card.Note, panel.MutedColor)

    return card
end

function SP.CreateStageChip(parent, state, previousChip)
    local chip = CreateFrame("Frame", nil, parent, "PreybreakerStageChipTemplate")
    ApplyInsetBackdrop(chip)

    if previousChip then
        chip:SetPoint("LEFT", previousChip, "RIGHT", 6, 0)
    else
        chip:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 14, 34)
    end

    chip.state = state
    chip.Text:SetText(Constants.StageLabelByState[state] or "?")

    return chip
end

function SP.UpdateStageChip(chip, isSelected)
    local panel = Constants.SettingsPanel
    local color = Constants.ColorByState[chip.state] or panel.AccentColor

    if isSelected then
        SP.ApplyBackdrop(chip, { color[1], color[2], color[3], 0.22 }, { color[1], color[2], color[3], 0.95 })
        SetTextColor(chip.Text, panel.TitleColor)
        return
    end

    ApplyInsetBackdrop(chip)
    SetTextColor(chip.Text, panel.MutedColor)
end

function SP.CreatePreviewCard(parent)
    local panel = Constants.SettingsPanel

    local card = CreateFrame("Frame", nil, parent, "PreybreakerPreviewCardTemplate")
    card:SetHeight(panel.PreviewCardHeight)
    ApplyCardBackdrop(card)

    SetTextColor(card.Title, panel.TitleColor)
    card.Title:SetText(L["Preview"])

    ApplyInsetBackdrop(card.Host)
    ApplyPreviewWidgetTexture(card.Host.Icon, { active = false, progressState = SAMPLE_STATE })

    card.HGuide:SetPoint("CENTER", card.Host, "CENTER")
    card.HGuide:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.10)
    card.VGuide:SetPoint("CENTER", card.Host, "CENTER")
    card.VGuide:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.10)

    local overlay = card.Overlay
    overlay:SetSize(math.max(Constants.Layout.RingSize, Constants.Layout.BarWidth), Constants.Layout.RingSize)
    overlay:SetFrameLevel(card:GetFrameLevel() + 20)

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

    local barProgress = ns.CreateBarProgress(overlay, true)
    barProgress:SetPoint("TOP", overlay, "TOP", 0, 0)
    barProgress:Hide()

    local orbProgress = ns.CreateOrbProgress(overlay, true)
    orbProgress:SetPoint("CENTER")
    orbProgress:Hide()

    local badge = overlay:CreateTexture(nil, "OVERLAY", nil, 1)
    badge:SetSize(Constants.Layout.StageBadgeWidth, Constants.Layout.StageBadgeHeight)
    badge:SetTexture(Constants.Media.StageBadge)
    badge:SetTexCoord(
        Constants.Media.StageBadgeTexCoord.left,
        Constants.Media.StageBadgeTexCoord.right,
        Constants.Media.StageBadgeTexCoord.top,
        Constants.Media.StageBadgeTexCoord.bottom
    )

    local badgeText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badgeText:SetPoint("CENTER", badge, "CENTER", 0, 0)
    badgeText:SetShadowColor(0, 0, 0, 1)
    badgeText:SetShadowOffset(1, -1)

    SetTextColor(card.Note, panel.MutedColor)

    local stageChips = {}
    local previousChip = nil
    for _, state in ipairs(ORDERED_STATES) do
        local chip = SP.CreateStageChip(card, state, previousChip)
        stageChips[#stageChips + 1] = chip
        previousChip = chip
    end

    local textDisplay = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOutline")
    textDisplay:SetPoint("CENTER")
    textDisplay:SetJustifyH("CENTER")
    textDisplay:Hide()

    card.HostIcon = card.Host.Icon
    card.Progress = progress
    card.OrbProgress = orbProgress
    card.BarProgress = barProgress
    card.Badge = badge
    card.BadgeText = badgeText
    card.TextDisplay = textDisplay
    card.StageChips = stageChips

    return card
end

function SP.CreateActionsCard(parent)
    local panel = Constants.SettingsPanel

    local card = CreateFrame("Frame", nil, parent, "PreybreakerActionsCardTemplate")
    card:SetHeight(panel.ActionCardHeight)
    ApplyCardBackdrop(card)

    SetTextColor(card.Title, panel.TitleColor)
    card.Title:SetText(L["Quick actions"])

    card.ResetButton:SetText(L["Reset all"])
    card.ResetButton:SetScript("OnClick", function()
        Settings:ResetToDefaults()
        ns.SettingsPanel:CommitChange("settings:reset")
        Util.Print(L["Settings reset to defaults."])
    end)

    card.RefreshButton:SetText(L["Refresh now"])
    card.RefreshButton:SetScript("OnClick", function()
        if ns.Controller then
            ns.Controller:Refresh("settings:refresh")
            Util.Print(L["Refreshed prey widget state."])
            return
        end

        ns.SettingsPanel:RefreshPreview()
    end)

    card.Hint:SetText(L["Open this panel with /pb or by shift-left-clicking the compartment icon."])
    SetTextColor(card.Hint, panel.MutedColor)

    return card
end

function SP.CreateSidebar(frame)
    local panel = Constants.SettingsPanel
    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", frame.Header, "BOTTOMLEFT", 0, -panel.Padding)
    sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", panel.Padding, panel.Padding)
    sidebar:SetWidth(panel.SidebarWidth)

    local summaryCard = SP.CreateSummaryCard(sidebar)
    summaryCard:SetPoint("TOPLEFT")
    summaryCard:SetPoint("TOPRIGHT")

    local previewCard = SP.CreatePreviewCard(sidebar)
    previewCard:SetPoint("TOPLEFT", summaryCard, "BOTTOMLEFT", 0, -panel.SectionSpacing)
    previewCard:SetPoint("TOPRIGHT", summaryCard, "BOTTOMRIGHT", 0, -panel.SectionSpacing)

    local actionsCard = SP.CreateActionsCard(sidebar)
    actionsCard:SetPoint("TOPLEFT", previewCard, "BOTTOMLEFT", 0, -panel.SectionSpacing)
    actionsCard:SetPoint("TOPRIGHT", previewCard, "BOTTOMRIGHT", 0, -panel.SectionSpacing)

    return {
        Frame = sidebar,
        Summary = summaryCard,
        Preview = previewCard,
        Actions = actionsCard,
    }
end
