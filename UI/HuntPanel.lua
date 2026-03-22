-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Clean-room hunt list panel. This module is intentionally self-contained and
-- only depends on the HuntList controller plus the standard WoW UI APIs.

local ADDON_NAME, ns = ...

local Constants = ns.Constants
local HuntList = ns.HuntList

ns.HuntPanel = ns.HuntPanel or {}

local HuntPanel = ns.HuntPanel

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local PANEL_NAME = "PreybreakerHuntPanel"
local MAP_OVERLAY_NAME = "PreybreakerHuntMapOverlay"
local LOADING_FRAME_NAME = "PreybreakerHuntLoadingFrame"
local ROW_HEIGHT = 78
local ROW_SPACING = 8
local PANEL_WIDTH = 396
local PANEL_HEIGHT = 574
local ATTACHED_WIDTH = 316
local HEADER_HEIGHT = 64
local FILTER_BUTTON_HEIGHT = 24
local REWARD_ICON_SIZE = 17
local MAX_REWARD_ICONS = 5
local missionHooksApplied = false

local DIFF_COLORS = {
    All = { 0.45, 0.88, 0.80 },
    Nightmare = { 0.95, 0.42, 0.40 },
    Hard = { 0.95, 0.72, 0.31 },
    Normal = { 0.49, 0.85, 0.54 },
}

local THEME = {
    panelBackground = { 0.02, 0.04, 0.03, 0.98 },
    panelBorder = { 0.30, 0.63, 0.49, 0.96 },
    headerBackground = { 0.06, 0.10, 0.08, 0.98 },
    bodyBackground = { 0.04, 0.07, 0.06, 0.98 },
    bodyBorder = { 0.17, 0.28, 0.23, 0.94 },
    rowBackground = { 0.07, 0.11, 0.09, 0.96 },
    rowBorder = { 0.19, 0.30, 0.25, 0.92 },
    chipBackground = { 0.10, 0.16, 0.13, 0.96 },
    chipBorder = { 0.27, 0.42, 0.35, 0.95 },
    cardBackground = { 0.06, 0.10, 0.08, 0.96 },
    cardBorder = { 0.28, 0.56, 0.45, 0.90 },
    mutedText = { 0.72, 0.81, 0.76 },
    accentText = { 0.88, 0.97, 0.93 },
}

local function SafeCall(func, ...)
    return ns.Util and ns.Util.SafeCall and ns.Util.SafeCall(func, ...) or nil
end

local function SetTextColor(fontString, color, alpha)
    if fontString then
        fontString:SetTextColor(color[1], color[2], color[3], alpha or 1)
    end
end

local function ApplyBackdrop(frame, background, border)
    if not frame or type(frame.SetBackdrop) ~= "function" then
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = {
            left = 3,
            right = 3,
            top = 3,
            bottom = 3,
        },
    })
    frame:SetBackdropColor(background[1], background[2], background[3], background[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function EnsurePulseAlpha(target, key, fromAlpha, toAlpha, duration)
    if not target then
        return nil
    end

    local pulseKey = key or "_pulseAnim"
    if target[pulseKey] then
        return target[pulseKey]
    end

    local group = target:CreateAnimationGroup()
    group:SetLooping("BOUNCE")

    local alpha = group:CreateAnimation("Alpha")
    alpha:SetFromAlpha(fromAlpha or 0)
    alpha:SetToAlpha(toAlpha or 1)
    alpha:SetDuration(duration or 0.85)

    target[pulseKey] = group
    return group
end

local function EnsureIntroAnim(frame)
    if not frame then
        return nil
    end

    if frame._introAnim then
        return frame._introAnim
    end

    local group = frame:CreateAnimationGroup()
    local alpha = group:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0.17)
    frame._introAnim = group
    return group
end

local function PlayIntro(frame)
    local intro = EnsureIntroAnim(frame)
    if not intro then
        return
    end

    frame:SetAlpha(0)
    intro:Stop()
    intro:Play()
end

local function EnsureFlashAnim(frame)
    if not frame then
        return nil
    end

    if frame._flashAnim then
        return frame._flashAnim
    end

    local group = frame:CreateAnimationGroup()
    local out = group:CreateAnimation("Alpha")
    out:SetFromAlpha(1)
    out:SetToAlpha(0.3)
    out:SetDuration(0.07)

    local inn = group:CreateAnimation("Alpha")
    inn:SetFromAlpha(0.3)
    inn:SetToAlpha(1)
    inn:SetDuration(0.11)
    inn:SetOrder(2)

    frame._flashAnim = group
    return group
end

local function FlashFrame(frame)
    local flash = EnsureFlashAnim(frame)
    if not flash then
        return
    end

    flash:Stop()
    flash:Play()
end

local function EnsureProgressShimmer(card)
    if not card or not card.ProgressFill then
        return nil
    end

    if card._progressShimmer then
        return card._progressShimmer
    end

    local group = card.ProgressFill:CreateAnimationGroup()
    group:SetLooping("BOUNCE")

    local alpha = group:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.55)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0.72)

    card._progressShimmer = group
    return group
end

local function SetProgressShimmer(card, enabled)
    local shimmer = EnsureProgressShimmer(card)
    if not shimmer then
        return
    end

    if enabled then
        if not shimmer:IsPlaying() then
            shimmer:Play()
        end
    else
        shimmer:Stop()
        if card.ProgressFill then
            card.ProgressFill:SetAlpha(1)
        end
    end
end

local function GetRemnantQuantity()
    local hunt = Constants and Constants.Hunt
    if not hunt or type(hunt.RemnantCurrencyID) ~= "number" then
        return 0
    end

    if type(C_CurrencyInfo) ~= "table" or type(C_CurrencyInfo.GetCurrencyInfo) ~= "function" then
        return 0
    end

    local info = SafeCall(C_CurrencyInfo.GetCurrencyInfo, hunt.RemnantCurrencyID)
    if type(info) ~= "table" then
        return 0
    end

    return info.quantity or info.totalEarned or 0
end

local function GetQuestChoiceDialog()
    if _G.AdventureMapQuestChoiceDialog then
        return _G.AdventureMapQuestChoiceDialog
    end

    if type(C_AddOns) == "table" and type(C_AddOns.LoadAddOn) == "function" then
        SafeCall(C_AddOns.LoadAddOn, "Blizzard_AdventureMap")
    end

    return _G.AdventureMapQuestChoiceDialog
end

local function EnsureHiddenAnchor()
    if HuntPanel.hiddenAnchor then
        return HuntPanel.hiddenAnchor
    end

    local anchor = CreateFrame("Frame", nil, UIParent)
    anchor:SetSize(1, 1)
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    anchor:Hide()
    HuntPanel.hiddenAnchor = anchor
    return anchor
end

local function IsQuestButtonEnabled(hunt)
    return hunt and hunt.available == true
end

local function BuildQuestChoiceAnchor(panel, hunt, anchorRegion)
    if hunt and hunt.pin then
        return hunt.pin
    end

    if anchorRegion then
        return anchorRegion
    end

    if panel and panel.frame then
        return panel.frame
    end

    return EnsureHiddenAnchor()
end

local function OpenQuestChoice(hunt, anchorRegion, autoAccept)
    if not hunt then
        return false
    end

    local dialog = GetQuestChoiceDialog()
    if not dialog or type(dialog.ShowWithQuest) ~= "function" then
        return false
    end

    local parent = _G.CovenantMissionFrame or UIParent
    local livePin = hunt.pin or (HuntList and HuntList.FindPin and HuntList:FindPin(hunt.questID)) or nil
    if not livePin then
        return false
    end

    local anchor = BuildQuestChoiceAnchor(HuntPanel, { pin = livePin }, anchorRegion)
    dialog:SetParent(parent)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetAlpha(1)
    dialog:ShowWithQuest(parent, anchor, hunt.questID)

    if autoAccept and type(dialog.AcceptQuest) == "function" then
        dialog:AcceptQuest()
    end

    return true
end

local function CreateText(parent, layer, template, point, x, y)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY", template or "GameFontNormal")
    if point then
        fs:SetPoint(point, x or 0, y or 0)
    end
    return fs
end

local function CreateFilterButton(parent, value, label)
    local button = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    button:SetHeight(FILTER_BUTTON_HEIGHT)
    ApplyBackdrop(button, THEME.chipBackground, THEME.chipBorder)

    button.Label = CreateText(button, "OVERLAY", "GameFontHighlightSmall", "CENTER", 0, 0)
    button.Label:SetJustifyH("LEFT")
    button.Label:SetText(label)
    button.value = value

    button.Underscore = button:CreateTexture(nil, "ARTWORK")
    button.Underscore:SetHeight(2)
    button.Underscore:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 4, 2)
    button.Underscore:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 2)
    button.Underscore:SetColorTexture(0.38, 0.76, 0.66, 0)

    button:SetScript("OnClick", function()
        if HuntList then
            HuntList:SetDifficultyFilter(value)
        end
        HuntPanel:Refresh()
    end)

    return button
end

local function UpdateFilterButton(button, selected)
    local color = DIFF_COLORS[button.value] or DIFF_COLORS.All
    if selected then
        ApplyBackdrop(button, { color[1] * 0.22, color[2] * 0.22, color[3] * 0.22, 0.97 }, { color[1], color[2], color[3], 0.98 })
        SetTextColor(button.Label, { 1, 1, 1 })
        if button.Underscore then
            button.Underscore:SetColorTexture(color[1], color[2], color[3], 0.95)
        end
        FlashFrame(button)
        return
    end

    ApplyBackdrop(button, THEME.chipBackground, THEME.chipBorder)
    SetTextColor(button.Label, THEME.mutedText)
    if button.Underscore then
        button.Underscore:SetColorTexture(0.38, 0.76, 0.66, 0)
    end
end

local function UpdateFilterButtons(frame)
    if not frame or not frame.FilterButtons then
        return
    end

    local selected = HuntList and HuntList:GetDifficultyFilter() or "All"
    for _, button in ipairs(frame.FilterButtons) do
        UpdateFilterButton(button, button.value == selected)
    end
end

local function CreateRewardButton(parent, index)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(REWARD_ICON_SIZE, REWARD_ICON_SIZE)
    button:SetFrameLevel(parent:GetFrameLevel() + 4)

    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetAllPoints()
    button.Border = button:CreateTexture(nil, "OVERLAY")
    button.Border:SetAllPoints()
    button.Border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    button.Border:SetAlpha(0.64)
    button.Index = index
    button:Hide()

    return button
end

local function SetupRewardTooltip(button)
    button:SetScript("OnEnter", function(self)
        local reward = self.reward
        if not reward or not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if reward.tooltipType == "currency" and type(GameTooltip.SetQuestCurrency) == "function" then
            GameTooltip:SetQuestCurrency(reward.questInfoType, reward.rewardIndex)
        elseif type(GameTooltip.SetQuestItem) == "function" then
            GameTooltip:SetQuestItem(reward.questInfoType, reward.rewardIndex, false)
        else
            GameTooltip:SetText(reward.name or "")
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
end

local function UpdateRewardButton(button, reward)
    button.reward = reward
    if not reward then
        button:Hide()
        return
    end

    button:SetID(reward.rewardIndex or 0)
    button.type = reward.tooltipType or "item"
    button.Icon:SetTexture(reward.texture or reward.icon)
    button:Show()
end

local function CreateHuntRow(parent)
    local row = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    row:SetSize(PANEL_WIDTH - 34, ROW_HEIGHT)
    row:SetFrameLevel(parent:GetFrameLevel() + 1)
    ApplyBackdrop(row, THEME.rowBackground, THEME.rowBorder)

    row.Pulse = row:CreateTexture(nil, "BACKGROUND")
    row.Pulse:SetAllPoints()
    row.Pulse:SetColorTexture(0.42, 0.84, 0.74, 0)
    row.Pulse:SetAlpha(0)
    EnsurePulseAlpha(row.Pulse, "_activePulseAnim", 0.05, 0.15, 0.85)

    row.Highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.Highlight:SetAllPoints()
    row.Highlight:SetColorTexture(0.52, 0.90, 0.72, 0.08)

    row.SideBand = row:CreateTexture(nil, "ARTWORK")
    row.SideBand:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.SideBand:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.SideBand:SetWidth(4)
    row.SideBand:SetColorTexture(0.38, 0.76, 0.66, 0.88)

    row.Scanline = row:CreateTexture(nil, "ARTWORK")
    row.Scanline:SetHeight(1)
    row.Scanline:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -7)
    row.Scanline:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -7)
    row.Scanline:SetColorTexture(0.24, 0.40, 0.33, 0.55)

    row.DifficultyPill = CreateFrame("Frame", nil, row, BACKDROP_TEMPLATE)
    row.DifficultyPill:SetSize(78, 16)
    row.DifficultyPill:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -10)
    ApplyBackdrop(row.DifficultyPill, { 0.10, 0.13, 0.15, 0.94 }, { 0.28, 0.34, 0.38, 0.90 })

    row.Difficulty = CreateText(row.DifficultyPill, "OVERLAY", "GameFontHighlightSmall", "CENTER", 0, 0)
    row.Difficulty:SetJustifyH("CENTER")

    row.StatusFrame = CreateFrame("Frame", nil, row, BACKDROP_TEMPLATE)
    row.StatusFrame:SetSize(96, 16)
    row.StatusFrame:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -10)
    ApplyBackdrop(row.StatusFrame, { 0.09, 0.12, 0.10, 0.92 }, { 0.24, 0.30, 0.27, 0.92 })

    row.Status = CreateText(row.StatusFrame, "OVERLAY", "GameFontNormalSmall", "CENTER", 0, 0)
    row.Status:SetJustifyH("CENTER")

    row.Title = CreateText(row, "OVERLAY", "GameFontHighlight", "TOPLEFT", 10, -30)
    row.Title:SetPoint("TOPRIGHT", row, "TOPRIGHT", -70, -30)
    row.Title:SetJustifyH("LEFT")
    row.Title:SetWordWrap(false)

    row.Zone = CreateText(row, "OVERLAY", "GameFontDisableSmall")
    row.Zone:SetPoint("TOPLEFT", row.Title, "BOTTOMLEFT", 0, -1)
    row.Zone:SetPoint("TOPRIGHT", row, "TOPRIGHT", -70, -42)
    row.Zone:SetJustifyH("LEFT")
    row.Zone:SetWordWrap(false)

    row.FooterRule = row:CreateTexture(nil, "ARTWORK")
    row.FooterRule:SetHeight(1)
    row.FooterRule:SetPoint("LEFT", row, "LEFT", 8, 0)
    row.FooterRule:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.FooterRule:SetPoint("BOTTOM", row, "BOTTOM", 0, 22)
    row.FooterRule:SetColorTexture(0.22, 0.34, 0.2, 0.50)

    row.RewardLabel = CreateText(row, "OVERLAY", "GameFontDisableSmall")
    row.RewardLabel:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 6)
    row.RewardLabel:SetWidth(132)
    row.RewardLabel:SetJustifyH("LEFT")

    row.RewardShelf = CreateFrame("Frame", nil, row)
    row.RewardShelf:SetSize(106, 18)
    row.RewardShelf:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 104, 6)

    row.Rewards = {}
    for i = 1, MAX_REWARD_ICONS do
        local reward = CreateRewardButton(row.RewardShelf, i)
        reward:SetPoint("LEFT", row.RewardShelf, "LEFT", (i - 1) * (REWARD_ICON_SIZE + 4), 0)
        SetupRewardTooltip(reward)
        row.Rewards[i] = reward
    end

    row.AcceptButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.AcceptButton:SetSize(58, 18)
    row.AcceptButton:SetPoint("RIGHT", row, "RIGHT", -8, -7)
    row.AcceptButton:SetText("Open")
    row.AcceptButton:SetScript("OnClick", function()
        if row.hunt then
            OpenQuestChoice(row.hunt, row, true)
        end
    end)

    row:SetScript("OnClick", function(self)
        if self.hunt then
            OpenQuestChoice(self.hunt, self, false)
        end
    end)
    row:SetScript("OnEnter", function(self)
        self.Highlight:SetColorTexture(0.52, 0.90, 0.72, 0.16)
    end)
    row:SetScript("OnLeave", function(self)
        self.Highlight:SetColorTexture(0.52, 0.90, 0.72, 0.08)
    end)

    return row
end

local function LayoutHuntRow(row, width)
    if not row then
        return
    end

    local compact = type(width) == "number" and width < 290
    local statusWidth = compact and 86 or 96
    local iconSize = compact and 16 or REWARD_ICON_SIZE
    local gap = compact and 2 or 3
    local shelfWidth = (iconSize * MAX_REWARD_ICONS) + (gap * (MAX_REWARD_ICONS - 1))

    row.StatusFrame:ClearAllPoints()
    row.StatusFrame:SetSize(statusWidth, 16)
    row.StatusFrame:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -10)

    row.AcceptButton:ClearAllPoints()
    row.AcceptButton:SetPoint("RIGHT", row, "RIGHT", -8, -7)

    row.RewardShelf:ClearAllPoints()
    row.RewardShelf:SetSize(shelfWidth, iconSize)
    row.RewardShelf:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 104, 6)

    row.RewardLabel:SetWidth(math.max(52, math.floor((width or 0) - shelfWidth - 176)))

    local rightPad = compact and 66 or 74
    row.Title:SetPoint("TOPRIGHT", row, "TOPRIGHT", -rightPad, -30)
    row.Zone:SetPoint("TOPRIGHT", row, "TOPRIGHT", -rightPad, -42)

    for index = 1, MAX_REWARD_ICONS do
        local reward = row.Rewards[index]
        reward:SetSize(iconSize, iconSize)
        reward:ClearAllPoints()
        reward:SetPoint("LEFT", row.RewardShelf, "LEFT", (index - 1) * (iconSize + gap), 0)
    end
end

local function GetRowCountHint(hunts)
    local inProgress = 0
    local available = 0

    for _, hunt in ipairs(hunts or {}) do
        if hunt.inProgress then
            inProgress = inProgress + 1
        else
            available = available + 1
        end
    end

    return inProgress, available
end

local function GetRewardSummaryText(hunt)
    if not hunt then
        return "Rewards pending"
    end

    if hunt.rewardState == "retrying" then
        return "Syncing rewards"
    end

    if hunt.rewardState == "empty" then
        return "No reward choices"
    end

    if not hunt.rewards then
        return "Rewards pending"
    end

    if #hunt.rewards == 0 then
        return "No reward choices"
    end

    return string.format("%d reward choices", #hunt.rewards)
end

local function GetAnguishText()
    return string.format("Anguish: %d", GetRemnantQuantity())
end

local function UpdateLoadingCard(frame, done, total, text)
    if not frame then
        return
    end

    local hasProgress = type(done) == "number" and type(total) == "number" and total > 0
    local fill = frame.ProgressFill
    local width = frame.ProgressTrack:GetWidth() or 1

    if hasProgress then
        local fraction = math.max(0, math.min(1, done / total))
        fill:SetWidth(math.max(1, math.floor(width * fraction)))
        frame.ProgressText:SetText(string.format("%d / %d", done, total))
        SetProgressShimmer(frame, true)
    else
        fill:SetWidth(1)
        frame.ProgressText:SetText("")
        SetProgressShimmer(frame, false)
    end

    frame.StatusText:SetText(text or "")
end

local function CreateLoadingCard(parent, name)
    local frame = CreateFrame("Frame", name, parent, BACKDROP_TEMPLATE)
    frame:SetSize(286, 96)
    ApplyBackdrop(frame, THEME.cardBackground, THEME.cardBorder)

    frame.Title = CreateText(frame, "OVERLAY", "GameFontHighlight")
    frame.Title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -10)
    frame.Title:SetText("Hunt Sync")
    SetTextColor(frame.Title, THEME.accentText)

    frame.StatusText = CreateText(frame, "OVERLAY", "GameFontNormalSmall")
    frame.StatusText:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -8)
    frame.StatusText:SetWidth(262)
    frame.StatusText:SetJustifyH("LEFT")
    SetTextColor(frame.StatusText, THEME.mutedText)

    frame.ProgressTrack = frame:CreateTexture(nil, "ARTWORK")
    frame.ProgressTrack:SetSize(262, 8)
    frame.ProgressTrack:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 14)
    frame.ProgressTrack:SetColorTexture(0.07, 0.10, 0.12, 1)

    frame.ProgressFill = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.ProgressFill:SetSize(1, 8)
    frame.ProgressFill:SetPoint("LEFT", frame.ProgressTrack, "LEFT", 0, 0)
    frame.ProgressFill:SetColorTexture(0.34, 0.82, 0.86, 1)

    frame.ProgressText = CreateText(frame, "OVERLAY", "GameFontHighlightSmall")
    frame.ProgressText:SetPoint("TOP", frame.ProgressTrack, "BOTTOM", 0, -6)
    SetTextColor(frame.ProgressText, THEME.accentText)

    return frame
end

local function CreateMapOverlay()
    if HuntPanel.mapOverlay then
        return HuntPanel.mapOverlay
    end

    local overlay = CreateFrame("Frame", MAP_OVERLAY_NAME, UIParent)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel(220)
    overlay:Hide()

    overlay.Background = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.Background:SetAllPoints()
    overlay.Background:SetColorTexture(0.02, 0.08, 0.12, 0.64)

    overlay.Card = CreateLoadingCard(overlay, nil)
    overlay.Card:SetPoint("CENTER", overlay, "CENTER", 0, 0)

    HuntPanel.mapOverlay = overlay
    return overlay
end

local function AnchorMapOverlay()
    local overlay = HuntPanel.mapOverlay
    if not overlay then
        return
    end

    local missionFrame = _G.CovenantMissionFrame
    if missionFrame and missionFrame:IsShown() then
        overlay:SetParent(UIParent)
        overlay:ClearAllPoints()
        overlay:SetPoint("TOPLEFT", missionFrame, "TOPLEFT", 0, 0)
        overlay:SetPoint("BOTTOMRIGHT", missionFrame, "BOTTOMRIGHT", 0, 0)
        return
    end

    overlay:Hide()
end

local function LayoutFilterButtons(frame)
    local bar = frame and frame.FilterBar
    local buttons = frame and frame.FilterButtons
    if not bar or not buttons then
        return
    end

    local width = bar:GetWidth() or (frame:GetWidth() - 20)
    local gap = 4
    local buttonWidth = math.max(56, math.floor((width - (gap * 3)) / 4))
    for index, button in ipairs(buttons) do
        button:ClearAllPoints()
        button:SetSize(buttonWidth, FILTER_BUTTON_HEIGHT)
        if index == 1 then
            button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        else
            button:SetPoint("LEFT", buttons[index - 1], "RIGHT", gap, 0)
        end
    end
end

local function LayoutPanelGeometry(frame)
    if not frame or not frame.Body then
        return
    end

    local width = frame:GetWidth() or PANEL_WIDTH
    frame.Body:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -(HEADER_HEIGHT + 4))
    frame.Body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)

    frame.FilterBar:SetPoint("TOPLEFT", frame.Body, "TOPLEFT", 8, -8)
    frame.FilterBar:SetPoint("TOPRIGHT", frame.Body, "TOPRIGHT", -8, -8)
    frame.FilterBar:SetHeight(FILTER_BUTTON_HEIGHT)

    frame.Summary:SetPoint("TOPLEFT", frame.FilterBar, "BOTTOMLEFT", 0, -7)
    frame.Summary:SetPoint("TOPRIGHT", frame.FilterBar, "BOTTOMRIGHT", 0, -7)

    frame.ScrollFrame:SetPoint("TOPLEFT", frame.Summary, "BOTTOMLEFT", 0, -8)
    frame.ScrollFrame:SetPoint("BOTTOMRIGHT", frame.Body, "BOTTOMRIGHT", -8, 8)

    local scrollWidth = math.max(1, width - 44)
    if frame.ScrollChild then
        frame.ScrollChild:SetSize(scrollWidth, 1)
    end

    LayoutFilterButtons(frame)
end

local function CreatePanelFrame()
    if HuntPanel.frame then
        return HuntPanel.frame
    end

    local frame = CreateFrame("Frame", PANEL_NAME, UIParent, BACKDROP_TEMPLATE)
    frame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()
    ApplyBackdrop(frame, THEME.panelBackground, THEME.panelBorder)

    frame.HeaderBand = frame:CreateTexture(nil, "ARTWORK")
    frame.HeaderBand:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    frame.HeaderBand:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    frame.HeaderBand:SetHeight(HEADER_HEIGHT)
    frame.HeaderBand:SetColorTexture(THEME.headerBackground[1], THEME.headerBackground[2], THEME.headerBackground[3], THEME.headerBackground[4])

    frame.HeaderGlow = frame:CreateTexture(nil, "ARTWORK", nil, -1)
    frame.HeaderGlow:SetPoint("TOPLEFT", frame.HeaderBand, "TOPLEFT", 0, 0)
    frame.HeaderGlow:SetPoint("BOTTOMRIGHT", frame.HeaderBand, "BOTTOMRIGHT", 0, 0)
    frame.HeaderGlow:SetColorTexture(0.15, 0.33, 0.25, 0.28)

    frame.HeaderLine = frame:CreateTexture(nil, "ARTWORK")
    frame.HeaderLine:SetPoint("TOPLEFT", frame.HeaderBand, "BOTTOMLEFT", 0, -1)
    frame.HeaderLine:SetPoint("TOPRIGHT", frame.HeaderBand, "BOTTOMRIGHT", 0, -1)
    frame.HeaderLine:SetHeight(1)
    frame.HeaderLine:SetColorTexture(0.44, 0.88, 0.72, 0.74)

    frame:SetScript("OnDragStart", function()
        if HuntPanel.mode ~= "standalone" then
            return
        end
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        HuntPanel:SaveStandaloneOffset()
    end)

    frame.Title = CreateText(frame, "OVERLAY", "GameFontNormalLarge")
    frame.Title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12)
    frame.Title:SetText("TACTICAL HUNT CONSOLE")
    SetTextColor(frame.Title, THEME.accentText)

    frame.Subtitle = CreateText(frame, "OVERLAY", "GameFontDisableSmall")
    frame.Subtitle:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -4)
    frame.Subtitle:SetText("Live prey routing, reward telemetry, and one-click quest access")
    SetTextColor(frame.Subtitle, THEME.mutedText)

    frame.AnguishText = CreateText(frame, "OVERLAY", "GameFontHighlightSmall")
    frame.AnguishText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -116, -15)
    SetTextColor(frame.AnguishText, THEME.accentText)

    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    frame.CloseButton:SetScript("OnClick", function()
        HuntPanel:Hide()
    end)

    frame.ModeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.ModeButton:SetSize(94, 20)
    frame.ModeButton:SetPoint("TOPRIGHT", frame.CloseButton, "TOPLEFT", -8, -1)
    frame.ModeButton:SetText("Detach")
    frame.ModeButton:SetScript("OnClick", function()
        HuntPanel:ToggleStandalone()
    end)

    frame.Body = CreateFrame("Frame", nil, frame, BACKDROP_TEMPLATE)
    ApplyBackdrop(frame.Body, THEME.bodyBackground, THEME.bodyBorder)

    frame.FilterBar = CreateFrame("Frame", nil, frame.Body)

    frame.FilterButtons = {}
    local filterOrder = { "All", "Nightmare", "Hard", "Normal" }
    for _, filter in ipairs(filterOrder) do
        local button = CreateFilterButton(frame.FilterBar, filter, filter)
        frame.FilterButtons[#frame.FilterButtons + 1] = button
    end

    frame.Summary = CreateText(frame.Body, "OVERLAY", "GameFontHighlightSmall")
    frame.Summary:SetJustifyH("LEFT")
    SetTextColor(frame.Summary, THEME.accentText)

    frame.ScrollFrame = CreateFrame("ScrollFrame", nil, frame.Body, "UIPanelScrollFrameTemplate")

    frame.ScrollChild = CreateFrame("Frame", nil, frame.ScrollFrame)
    frame.ScrollChild:SetSize(PANEL_WIDTH - 44, 1)
    frame.ScrollFrame:SetScrollChild(frame.ScrollChild)

    frame.EmptyIcon = frame.ScrollChild:CreateTexture(nil, "ARTWORK")
    frame.EmptyIcon:SetSize(42, 42)
    frame.EmptyIcon:SetPoint("CENTER", frame.ScrollChild, "CENTER", 0, -16)
    frame.EmptyIcon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastSoothe")
    frame.EmptyIcon:SetAlpha(0.45)
    frame.EmptyIcon:Hide()

    frame.EmptyState = CreateText(frame.ScrollChild, "OVERLAY", "GameFontDisableLarge")
    frame.EmptyState:SetPoint("TOP", frame.EmptyIcon, "BOTTOM", 0, -8)
    frame.EmptyState:SetText("No hunt signals detected.")
    SetTextColor(frame.EmptyState, THEME.mutedText)
    frame.EmptyState:Hide()

    frame.LoadingOverlay = CreateFrame("Frame", nil, frame)
    frame.LoadingOverlay:SetAllPoints()
    frame.LoadingOverlay:Hide()
    frame.LoadingOverlay.Background = frame.LoadingOverlay:CreateTexture(nil, "BACKGROUND")
    frame.LoadingOverlay.Background:SetAllPoints()
    frame.LoadingOverlay.Background:SetColorTexture(0.01, 0.03, 0.02, 0.74)
    frame.LoadingOverlay.Card = CreateLoadingCard(frame.LoadingOverlay, LOADING_FRAME_NAME)
    frame.LoadingOverlay.Card:SetPoint("CENTER", frame.LoadingOverlay, "CENTER", 0, 0)

    frame._layoutDirty = true
    frame.mode = HuntPanel.mode or "attached"

    HuntPanel.rows = {}
    HuntPanel.frame = frame
    return frame
end

local function EnsureEventFrame()
    if HuntPanel.eventFrame then
        return HuntPanel.eventFrame
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
    eventFrame:RegisterEvent("QUEST_ACCEPTED")
    eventFrame:RegisterEvent("QUEST_REMOVED")
    eventFrame:RegisterEvent("QUEST_FINISHED")
    eventFrame:RegisterEvent("ADVENTURE_MAP_QUEST_UPDATE")
    eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    eventFrame:RegisterEvent("GOSSIP_SHOW")
    eventFrame:RegisterEvent("GOSSIP_CLOSED")
    eventFrame:SetScript("OnEvent", function(_, event)
        if not HuntPanel.frame or not HuntPanel.frame:IsShown() then
            return
        end

        if event == "CURRENCY_DISPLAY_UPDATE" then
            HuntPanel:UpdateSummary()
            return
        end

        HuntPanel:Refresh()
    end)

    HuntPanel.eventFrame = eventFrame
    return eventFrame
end

local function ApplyMissionFrameHooks()
    if missionHooksApplied then
        return
    end

    hooksecurefunc("ShowUIPanel", function(frame)
        if not frame or frame:GetName() ~= "CovenantMissionFrame" then
            return
        end

        if HuntPanel.frame and HuntPanel.frame:IsShown() and HuntPanel.mode == "standalone" then
            return
        end

        HuntPanel:ShowAttached()
    end)

    hooksecurefunc("HideUIPanel", function(frame)
        if not frame or frame:GetName() ~= "CovenantMissionFrame" then
            return
        end

        HuntPanel:HideAttached()
    end)

    missionHooksApplied = true
end

local function UpdateRowState(row, hunt)
    local color = DIFF_COLORS[hunt.difficulty] or DIFF_COLORS.All
    row.hunt = hunt
    ApplyBackdrop(row.DifficultyPill, { color[1], color[2], color[3], 0.28 }, { color[1], color[2], color[3], 0.98 })
    if row.SideBand then
        row.SideBand:SetColorTexture(color[1], color[2], color[3], 0.80)
    end
    row.Title:SetText(hunt.name or ("Quest " .. tostring(hunt.questID)))
    row.Difficulty:SetText(hunt.difficulty or "Normal")
    SetTextColor(row.Difficulty, { 1, 1, 1 })
    row.Zone:SetText(hunt.zone or "Unknown zone")
    SetTextColor(row.Zone, THEME.mutedText)

    local statusText
    if hunt.inProgress then
        statusText = "Tracking"
    elseif hunt.rewardState == "retrying" then
        statusText = "Syncing"
    elseif hunt.rewardState == "ready" then
        statusText = GetRewardSummaryText(hunt)
    else
        statusText = "Loading"
    end
    row.Status:SetText(statusText)
    if hunt.inProgress then
        SetTextColor(row.Status, { 0.74, 0.92, 0.82 })
        ApplyBackdrop(row.StatusFrame, { 0.08, 0.16, 0.12, 0.96 }, { 0.34, 0.62, 0.49, 0.96 })
        if row.Pulse then
            row.Pulse:SetColorTexture(color[1], color[2], color[3], 0.10)
            if row.Pulse._activePulseAnim and not row.Pulse._activePulseAnim:IsPlaying() then
                row.Pulse._activePulseAnim:Play()
            end
        end
    elseif hunt.available then
        SetTextColor(row.Status, { 0.78, 0.94, 0.80 })
        ApplyBackdrop(row.StatusFrame, { 0.09, 0.14, 0.10, 0.96 }, { 0.34, 0.58, 0.38, 0.96 })
        if row.Pulse then
            row.Pulse:SetColorTexture(color[1], color[2], color[3], 0.02)
            if row.Pulse._activePulseAnim then
                row.Pulse._activePulseAnim:Stop()
            end
            row.Pulse:SetAlpha(1)
        end
    else
        SetTextColor(row.Status, THEME.mutedText)
        ApplyBackdrop(row.StatusFrame, { 0.09, 0.12, 0.10, 0.92 }, { 0.24, 0.30, 0.27, 0.92 })
        if row.Pulse then
            row.Pulse:SetColorTexture(color[1], color[2], color[3], 0.01)
            if row.Pulse._activePulseAnim then
                row.Pulse._activePulseAnim:Stop()
            end
            row.Pulse:SetAlpha(1)
        end
    end
    if hunt.rewardState == "ready" and hunt.rewards and #hunt.rewards > 0 then
        row.RewardShelf:Show()
        row.RewardLabel:Hide()
    else
        row.RewardShelf:Hide()
        row.RewardLabel:SetText(GetRewardSummaryText(hunt))
        row.RewardLabel:Show()
    end

    for index = 1, MAX_REWARD_ICONS do
        local button = row.Rewards[index]
        local reward = hunt.rewards and hunt.rewards[index] or nil
        UpdateRewardButton(button, reward)
    end

    row.AcceptButton:SetShown(IsQuestButtonEnabled(hunt) and HuntPanel.mode ~= "standalone")
    row.AcceptButton:SetEnabled(IsQuestButtonEnabled(hunt))
end

local function AcquireRows(parent, count)
    HuntPanel.rows = HuntPanel.rows or {}
    for index = #HuntPanel.rows + 1, count do
        local row = CreateHuntRow(parent)
        HuntPanel.rows[index] = row
    end

    return HuntPanel.rows
end

local function LayoutRows(frame, hunts)
    local scrollChild = frame.ScrollChild
    if scrollChild and frame then
        local bodyWidth = frame.Body and frame.Body:GetWidth() or frame:GetWidth()
        scrollChild:SetWidth(math.max(1, (bodyWidth or frame:GetWidth() or PANEL_WIDTH) - 24))
    end

    local rows = AcquireRows(scrollChild, math.max(1, #hunts))
    local y = 0

    for index, hunt in ipairs(hunts) do
        local row = rows[index]
        row:SetParent(scrollChild)
        row:SetSize(scrollChild:GetWidth(), ROW_HEIGHT)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -y)
        LayoutHuntRow(row, scrollChild:GetWidth())
        UpdateRowState(row, hunt)
        row:Show()

        if row._displayQuestID ~= hunt.questID then
            row._displayQuestID = hunt.questID
            if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
                row:SetAlpha(0)
                C_Timer.After((index - 1) * 0.016, function()
                    if row:IsShown() then
                        PlayIntro(row)
                    end
                end)
            end
        end

        y = y + ROW_HEIGHT + ROW_SPACING
    end

    for index = #hunts + 1, #rows do
        rows[index]:Hide()
        rows[index].hunt = nil
    end

    scrollChild:SetHeight(math.max(1, y))
    local showEmpty = #hunts == 0
    frame.EmptyState:SetShown(showEmpty)
    if frame.EmptyIcon then
        frame.EmptyIcon:SetShown(showEmpty)
        if showEmpty then
            local pulse = EnsurePulseAlpha(frame.EmptyIcon, "_emptyPulseAnim", 0.32, 0.58, 1.1)
            if pulse and not pulse:IsPlaying() then
                pulse:Play()
            end
        elseif frame.EmptyIcon._emptyPulseAnim then
            frame.EmptyIcon._emptyPulseAnim:Stop()
            frame.EmptyIcon:SetAlpha(0.45)
        end
    end
end

function HuntPanel:Ensure()
    CreateMapOverlay()
    EnsureEventFrame()
    ApplyMissionFrameHooks()
    return CreatePanelFrame()
end

function HuntPanel:Anchor()
    local frame = self:Ensure()
    frame:ClearAllPoints()

    if self.mode == "attached" and _G.CovenantMissionFrame and _G.CovenantMissionFrame:IsShown() then
        frame:SetSize(ATTACHED_WIDTH, _G.CovenantMissionFrame:GetHeight() or PANEL_HEIGHT)
        frame:SetPoint("TOPRIGHT", _G.CovenantMissionFrame, "TOPLEFT", -8, 0)
    else
        frame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
        local offsetX = ns.Settings and ns.Settings.GetHuntPanelOffsetX and ns.Settings:GetHuntPanelOffsetX() or 0
        local offsetY = ns.Settings and ns.Settings.GetHuntPanelOffsetY and ns.Settings:GetHuntPanelOffsetY() or 0
        frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    end

    frame.mode = self.mode
    LayoutPanelGeometry(frame)
    self:AnchorMapOverlay()
end

function HuntPanel:AnchorMapOverlay()
    AnchorMapOverlay()
end

function HuntPanel:UpdateSummary()
    local frame = self.frame
    if not frame then
        return
    end

    local hunts = HuntList and HuntList:GetFilteredSortedHunts() or {}
    local inProgress, available = GetRowCountHint(hunts)
    local filter = HuntList and HuntList:GetDifficultyFilter() or "All"
    local anguishText = GetAnguishText()
    frame.Summary:SetText(string.format("Band %s  |  Active %d  |  Ready %d", filter, inProgress, available))
    if frame.AnguishText then
        frame.AnguishText:SetText(anguishText)
    end
end

function HuntPanel:UpdateLoading(done, total, text)
    local frame = self.frame
    if not frame then
        return
    end

    if not frame:IsShown() then
        if self.mapOverlay then
            self.mapOverlay:Hide()
        end
        frame.LoadingOverlay:Hide()
        return
    end

    local isAttached = self.mode == "attached" and _G.CovenantMissionFrame and _G.CovenantMissionFrame:IsShown()
    local showProgress = HuntList and (HuntList:IsWarmupActive() or HuntList:IsScanActive())

    if isAttached then
        local overlay = self.mapOverlay
        if overlay then
            if showProgress then
                overlay.Card:Show()
                UpdateLoadingCard(overlay.Card, done, total, text or (HuntList:IsWarmupActive() and "Synchronizing hunt deck" or "Stabilizing hunt signals"))
                overlay:Show()
            else
                overlay:Hide()
            end
        end
    end

    if showProgress then
        frame.LoadingOverlay:Show()
        UpdateLoadingCard(frame.LoadingOverlay.Card, done, total, text or (HuntList:IsWarmupActive() and "Synchronizing hunt deck" or "Stabilizing hunt signals"))
    else
        frame.LoadingOverlay:Hide()
    end
end

function HuntPanel:RequestWarmup()
    if not HuntList or HuntList:IsWarmupActive() or HuntList:IsScanActive() then
        return
    end

    local state = (HuntList and HuntList.GetState) and HuntList:GetState() or nil
    local needsWarm = false
    local hunts = state and state.hunts or {}
    local rewardCache = state and state.rewardCache or {}
    for _, hunt in ipairs(hunts) do
        if rewardCache[hunt.questID] == nil then
            needsWarm = true
            break
        end
    end

    if not needsWarm then
        return
    end

    HuntList:WarmRewardCacheAsync(function(done, total, hunt)
        local text = hunt and hunt.name and ("Syncing " .. hunt.name) or "Syncing reward matrix"
        self:UpdateLoading(done, total, text)
    end, function()
        self:Refresh()
    end)
end

function HuntPanel:QuickEvaluateBeforeOpen()
    if not (HuntList and type(HuntList.QuickEvaluateAvailability) == "function") then
        return true
    end

    local hasHunts, count, source = HuntList:QuickEvaluateAvailability()
    if hasHunts == false then
        if ns.Debug and type(ns.Debug.Log) == "function" and type(ns.Debug.KV) == "function" then
            ns.Debug:Log(
                "hunts",
                ns.Debug:KV("action", "quickEval"),
                ns.Debug:KV("detail", "noHunts"),
                ns.Debug:KV("extra", (source or "unknown") .. ":" .. tostring(count or 0))
            )
        end
        return false
    end

    return true
end

function HuntPanel:Refresh()
    local frame = self:Ensure()
    if not frame:IsShown() then
        return
    end

    self:Anchor()

    if HuntList and not HuntList:IsScanActive() then
        HuntList:RefreshFromPins()
    end

    local hunts = HuntList and HuntList:GetFilteredSortedHunts() or {}
    LayoutRows(frame, hunts)
    UpdateFilterButtons(frame)
    frame.ModeButton:SetText(self.mode == "attached" and "Detach" or "Dock")
    self:UpdateSummary()
    self:UpdateLoading(nil, nil, nil)

    if HuntList and HuntList:IsScanActive() then
        self:UpdateLoading(nil, nil, "Stabilizing map pins")
        return
    end

    self:RequestWarmup()
end

function HuntPanel:ShowAttached()
    if not self:QuickEvaluateBeforeOpen() then
        if ns.Settings and ns.Settings.SetHuntPanelStandalone then
            ns.Settings:SetHuntPanelStandalone(false)
        end
        self.mode = "attached"
        return false
    end

    self.mode = "attached"
    if ns.Settings and ns.Settings.SetHuntPanelStandalone then
        ns.Settings:SetHuntPanelStandalone(false)
    end
    local frame = self:Ensure()
    self:Anchor()
    frame:Show()
    PlayIntro(frame)
    if HuntList then
        HuntList:BeginStabilizedScan(function()
            if HuntPanel.frame and HuntPanel.frame:IsShown() then
                HuntPanel:Refresh()
            end
        end)
    end
    self:Refresh()
    return true
end

function HuntPanel:ShowStandalone()
    if not self:QuickEvaluateBeforeOpen() then
        if ns.Settings and ns.Settings.SetHuntPanelStandalone then
            ns.Settings:SetHuntPanelStandalone(false)
        end
        self.mode = "attached"
        if self.frame then
            self.frame:Hide()
        end
        return false
    end

    self.mode = "standalone"
    if ns.Settings and ns.Settings.SetHuntPanelStandalone then
        ns.Settings:SetHuntPanelStandalone(true)
    end
    local frame = self:Ensure()
    self:Anchor()
    frame:Show()
    PlayIntro(frame)
    if HuntList then
        HuntList:BeginStabilizedScan(function()
            if HuntPanel.frame and HuntPanel.frame:IsShown() then
                HuntPanel:Refresh()
            end
        end)
    end
    self:Refresh()
    return true
end

function HuntPanel:HideAttached()
    if self.mode == "attached" then
        self:Hide()
    end
end

function HuntPanel:Hide()
    if self.mode == "standalone" and ns.Settings and ns.Settings.SetHuntPanelStandalone then
        ns.Settings:SetHuntPanelStandalone(false)
    end

    if HuntList and HuntList.CancelWarmup then
        HuntList:CancelWarmup()
    end

    if self.frame then
        self.frame:Hide()
        self.frame.LoadingOverlay:Hide()
    end

    if self.mapOverlay then
        self.mapOverlay:Hide()
    end
end

function HuntPanel:ToggleStandalone()
    local frame = self:Ensure()
    local isShown = frame:IsShown()

    if isShown and self.mode == "standalone" then
        self:Hide()
        self.mode = "attached"
        return false
    end

    return self:ShowStandalone() == true
end

function HuntPanel:SaveStandaloneOffset()
    if not (self.frame and self.mode == "standalone" and ns.Settings) then
        return
    end

    local centerX, centerY = self.frame:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()
    if not centerX or not centerY or not parentCenterX or not parentCenterY then
        return
    end

    local round = (ns.Util and ns.Util.RoundNearest) or math.floor
    local offsetX = round(centerX - parentCenterX)
    local offsetY = round(centerY - parentCenterY)

    if ns.Settings.SetHuntPanelOffsetX then
        ns.Settings:SetHuntPanelOffsetX(offsetX)
    end
    if ns.Settings.SetHuntPanelOffsetY then
        ns.Settings:SetHuntPanelOffsetY(offsetY)
    end
end

function HuntPanel:OpenQuestChoice(hunt, anchorRegion, autoAccept)
    return OpenQuestChoice(hunt, anchorRegion, autoAccept == true)
end

function HuntPanel:OpenQuestChoiceByQuestID(questID, anchorRegion, autoAccept)
    if not questID or not HuntList then
        return false
    end

    local hunt = HuntList:GetHuntByQuestID(questID)
    if not hunt then
        return false
    end

    return OpenQuestChoice(hunt, anchorRegion, autoAccept == true)
end

function HuntPanel:RefreshLoading()
    self:UpdateLoading(nil, nil, nil)
end
