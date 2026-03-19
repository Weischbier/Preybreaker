-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

local Constants = ns.Constants
local Settings = ns.Settings
local Util = ns.Util
local L = ns.L
local SP = ns._SP

local SetTextColor = SP.SetTextColor
local ApplyBackdrop = SP.ApplyBackdrop
local ApplyCardBackdrop = SP.ApplyCardBackdrop
local ApplyInsetBackdrop = SP.ApplyInsetBackdrop
local ApplyPreviewWidgetTexture = SP.ApplyPreviewWidgetTexture
local CreateActionButton = SP.CreateActionButton
local BACKDROP_TEMPLATE = SP.BACKDROP_TEMPLATE
local SAMPLE_STATE = SP.SAMPLE_STATE
local ORDERED_STATES = SP.ORDERED_STATES

function SP.CreateHeader(frame)
    local panel = Constants.SettingsPanel

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", panel.Padding, -panel.Padding)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -panel.Padding, -panel.Padding)
    header:SetHeight(panel.HeaderHeight)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    local shade = header:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(true)
    shade:SetColorTexture(0.17, 0.11, 0.06, 0.90)

    local glow = header:CreateTexture(nil, "ARTWORK")
    glow:SetPoint("TOPLEFT")
    glow:SetPoint("TOPRIGHT")
    glow:SetHeight(24)
    glow:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.09)

    local accent = header:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("BOTTOMLEFT")
    accent:SetPoint("BOTTOMRIGHT")
    accent:SetHeight(2)
    accent:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.82)

    local icon = header:CreateTexture(nil, "OVERLAY")
    icon:SetSize(40, 40)
    icon:SetPoint("LEFT", header, "LEFT", 4, 0)
    icon:SetTexture(Constants.Media.AddonIcon)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -4)
    title:SetText(ADDON_NAME)
    SetTextColor(title, panel.TitleColor)

    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetPoint("RIGHT", header, "RIGHT", -32, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(L["Shape the prey tracker around your HUD with a live preview and clear sections."])
    SetTextColor(subtitle, panel.BodyColor)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    frame.Header = header
end

local function CreateLabelValueRow(parent, anchor, labelText)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
    label:SetText(labelText)
    SetTextColor(label, Constants.SettingsPanel.MutedColor)

    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("LEFT", label, "RIGHT", 10, 0)
    value:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
    value:SetJustifyH("RIGHT")
    SetTextColor(value, Constants.SettingsPanel.TitleColor)

    return {
        Label = label,
        Value = value,
    }
end

local function CreateStatusPill(parent)
    local pill = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    pill:SetSize(112, 24)
    ApplyInsetBackdrop(pill)

    pill.Text = pill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pill.Text:SetPoint("CENTER")
    pill.Text:SetJustifyH("CENTER")

    return pill
end

function SP.CreateSummaryCard(parent)
    local panel = Constants.SettingsPanel
    local card = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    card:SetHeight(panel.SummaryCardHeight)
    ApplyCardBackdrop(card)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -12)
    title:SetText(L["Current setup"])
    SetTextColor(title, panel.TitleColor)

    local pill = CreateStatusPill(card)
    pill:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -10)

    local statusText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    statusText:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    statusText:SetJustifyH("LEFT")
    statusText:SetJustifyV("TOP")
    statusText:SetWordWrap(true)
    SetTextColor(statusText, panel.BodyColor)

    local displayRow = CreateLabelValueRow(card, statusText, L["Style"])
    local placementRow = CreateLabelValueRow(card, displayRow.Label, L["Placement"])
    local widgetRow = CreateLabelValueRow(card, placementRow.Label, L["Blizzard UI"])
    local readoutRow = CreateLabelValueRow(card, widgetRow.Label, L["Readout"])
    local questRow = CreateLabelValueRow(card, readoutRow.Label, L["Quest help"])

    local note = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 14, 12)
    note:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    note:SetJustifyH("LEFT")
    note:SetText(L["Live state shows up here as soon as a prey hunt starts."])
    SetTextColor(note, panel.MutedColor)

    card.StatusPill = pill
    card.StatusText = statusText
    card.DisplayRow = displayRow
    card.PlacementRow = placementRow
    card.WidgetRow = widgetRow
    card.ReadoutRow = readoutRow
    card.QuestRow = questRow
    card.Note = note

    return card
end

function SP.CreateStageChip(parent, state, previousChip)
    local chip = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    chip:SetSize(46, 18)
    ApplyInsetBackdrop(chip)

    if previousChip then
        chip:SetPoint("LEFT", previousChip, "RIGHT", 6, 0)
    else
        chip:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 14, 34)
    end

    chip.state = state
    chip.Text = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chip.Text:SetPoint("CENTER")
    chip.Text:SetText(Constants.StageLabelByState[state] or "?")

    return chip
end

function SP.UpdateStageChip(chip, isSelected)
    local panel = Constants.SettingsPanel
    local color = Constants.ColorByState[chip.state] or panel.AccentColor

    if isSelected then
        ApplyBackdrop(chip, { color[1], color[2], color[3], 0.22 }, { color[1], color[2], color[3], 0.95 })
        SetTextColor(chip.Text, panel.TitleColor)
        return
    end

    ApplyInsetBackdrop(chip)
    SetTextColor(chip.Text, panel.MutedColor)
end

function SP.CreatePreviewCard(parent)
    local panel = Constants.SettingsPanel
    local card = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    card:SetHeight(panel.PreviewCardHeight)
    ApplyCardBackdrop(card)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -12)
    title:SetText(L["Preview"])
    SetTextColor(title, panel.TitleColor)

    local host = CreateFrame("Frame", nil, card, BACKDROP_TEMPLATE)
    host:SetSize(96, 112)
    host:SetPoint("TOP", card, "TOP", 0, -46)
    ApplyInsetBackdrop(host)

    local icon = host:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", host, "CENTER", 0, -2)
    ApplyPreviewWidgetTexture(icon, { active = false, progressState = SAMPLE_STATE })

    local hGuide = card:CreateTexture(nil, "BACKGROUND")
    hGuide:SetSize(144, 1)
    hGuide:SetPoint("CENTER", host, "CENTER")
    hGuide:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.10)

    local vGuide = card:CreateTexture(nil, "BACKGROUND")
    vGuide:SetSize(1, 144)
    vGuide:SetPoint("CENTER", host, "CENTER")
    vGuide:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.10)

    local overlay = CreateFrame("Frame", nil, card)
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

    local note = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 14, 12)
    note:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    note:SetJustifyH("CENTER")
    note:SetWordWrap(true)
    SetTextColor(note, panel.MutedColor)

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

    card.Host = host
    card.HostIcon = icon
    card.Overlay = overlay
    card.Progress = progress
    card.OrbProgress = orbProgress
    card.BarProgress = barProgress
    card.Badge = badge
    card.BadgeText = badgeText
    card.TextDisplay = textDisplay
    card.Note = note
    card.StageChips = stageChips

    return card
end

function SP.CreateActionsCard(parent)
    local panel = Constants.SettingsPanel
    local card = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    card:SetHeight(panel.ActionCardHeight)
    ApplyCardBackdrop(card)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -12)
    title:SetText(L["Quick actions"])
    SetTextColor(title, panel.TitleColor)

    local resetButton = CreateActionButton(card, L["Reset all"], 96, function()
        Settings:ResetToDefaults()
        ns.SettingsPanel:CommitChange("settings:reset")
        Util.Print(L["Settings reset to defaults."])
    end)
    resetButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)

    local refreshButton = CreateActionButton(card, L["Refresh now"], 96, function()
        if ns.Controller then
            ns.Controller:Refresh("settings:refresh")
            Util.Print(L["Refreshed prey widget state."])
            return
        end

        ns.SettingsPanel:RefreshPreview()
    end)
    refreshButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)

    local hint = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 14, 12)
    hint:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)
    hint:SetText(L["Open this panel with /pb or by shift-left-clicking the compartment icon."])
    SetTextColor(hint, panel.MutedColor)

    card.ResetButton = resetButton
    card.RefreshButton = refreshButton
    card.Hint = hint

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
