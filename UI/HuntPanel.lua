-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Hunt list panel. XML owns stable frame structure (HuntPanel.xml).
-- Lua owns behavior, state, controller logic, data binding, and runtime colors.

local ADDON_NAME, ns = ...

local Constants = ns.Constants
local HuntList = ns.HuntList
local L = ns.L

ns.HuntPanel = ns.HuntPanel or {}

local HuntPanel = ns.HuntPanel

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local missionHooksApplied = false

-- Frame reference compat aliases (see Constants.FrameRef).
local FR = Constants and Constants.FrameRef or {}
local MISSION_FRAME_NAME = FR.MissionFrame or "CovenantMissionFrame"
local QUEST_CHOICE_DIALOG_NAME = FR.QuestChoiceDialog or "AdventureMapQuestChoiceDialog"
local ADVENTURE_MAP_ADDON = FR.AdventureMapAddon or "Blizzard_AdventureMap"

-- Layout metrics from Constants; fallback to safe defaults.
local HP = Constants and Constants.HuntPanel or {}
local PANEL_WIDTH = HP.PanelWidth or 396
local PANEL_HEIGHT = HP.PanelHeight or 574
local ATTACHED_WIDTH = HP.AttachedWidth or 316
local HEADER_HEIGHT = HP.HeaderHeight or 64
local ROW_HEIGHT = HP.RowHeight or 78
local ROW_SPACING = HP.RowSpacing or 8
local FILTER_BUTTON_HEIGHT = HP.FilterButtonHeight or 24
local REWARD_ICON_SIZE = HP.RewardIconSize or 17
local MAX_REWARD_ICONS = HP.MaxRewardIcons or 5
local X_OFFSET = HP.XOffset or 8
local SCROLL_STEP = ROW_HEIGHT + ROW_SPACING
local ACHIEVEMENT_ICON_FALLBACK_ATLAS = "QuestPortraitIcon-SandboxQuest"

-- Difficulty colors (functional, not theme).
local DIFF_COLORS = {
    All = { 0.86, 0.66, 0.28 },
    Nightmare = { 0.93, 0.21, 0.18 },
    Hard = { 0.97, 0.50, 0.12 },
    Normal = { 0.95, 0.78, 0.25 },
}

---------------------------------------------------------------------------
-- Shared palette — derived from Constants.SettingsPanel so both Settings
-- and HuntPanel share one visual identity.
---------------------------------------------------------------------------
local function SP()
    return Constants and Constants.SettingsPanel or {}
end

local DEFAULT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
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
    frame:SetBackdrop(DEFAULT_BACKDROP)
    frame:SetBackdropColor(background[1], background[2], background[3], background[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function ApplyDialogBackdrop(frame)
    local p = SP()
    ApplyBackdrop(frame, p.SurfaceColor or { 0.08, 0.06, 0.05, 0.96 }, p.BorderColor or { 0.66, 0.49, 0.21, 1 })
end

local function ApplyCardBackdrop(frame)
    local p = SP()
    ApplyBackdrop(frame, p.SurfaceRaisedColor or { 0.11, 0.08, 0.06, 0.98 }, p.BorderSoftColor or { 0.66, 0.49, 0.21, 0.34 })
end

local function ApplyInsetBackdrop(frame)
    local p = SP()
    ApplyBackdrop(frame, p.SurfaceInsetColor or { 0.12, 0.09, 0.07, 0.84 }, p.BorderSoftColor or { 0.66, 0.49, 0.21, 0.34 })
end

---------------------------------------------------------------------------
-- Accent button styling (used for AcceptButton, ModeButton)
---------------------------------------------------------------------------
local function ApplyAccentButtonStyle(button, label)
    if not button then return end
    local p = SP()
    local ac = p.AccentColor or { 0.86, 0.66, 0.28 }
    local tc = p.TitleColor or { 0.94, 0.86, 0.72 }
    ApplyBackdrop(button, { ac[1], ac[2], ac[3], 0.18 }, { ac[1], ac[2], ac[3], 0.70 })
    if button.Label then
        button.Label:SetText(label or "")
        SetTextColor(button.Label, tc)
    end
    if button.Highlight then
        button.Highlight:SetColorTexture(ac[1], ac[2], ac[3], 0.18)
    end
    -- Pressed visual: darken backdrop + shift label down
    button:HookScript("OnMouseDown", function(self)
        ApplyBackdrop(self, { ac[1] * 0.6, ac[2] * 0.6, ac[3] * 0.6, 0.32 }, { ac[1], ac[2], ac[3], 0.85 })
        if self.Label then self.Label:AdjustPointsOffset(0, -1) end
    end)
    button:HookScript("OnMouseUp", function(self)
        ApplyBackdrop(self, { ac[1], ac[2], ac[3], 0.18 }, { ac[1], ac[2], ac[3], 0.70 })
        if self.Label then self.Label:AdjustPointsOffset(0, 1) end
    end)
end

---------------------------------------------------------------------------
-- Animations
---------------------------------------------------------------------------
local function EnsurePulseAlpha(target, key, fromAlpha, toAlpha, duration)
    if not target then return nil end
    local pulseKey = key or "_pulseAnim"
    if target[pulseKey] then return target[pulseKey] end

    local group = target:CreateAnimationGroup()
    group:SetLooping("BOUNCE")
    local a = group:CreateAnimation("Alpha")
    a:SetFromAlpha(fromAlpha or 0)
    a:SetToAlpha(toAlpha or 1)
    a:SetDuration(duration or 0.85)
    target[pulseKey] = group
    return group
end

local function EnsureIntroAnim(frame)
    if not frame then return nil end
    if frame._introAnim then return frame._introAnim end

    local group = frame:CreateAnimationGroup()
    group:SetToFinalAlpha(true)
    local a = group:CreateAnimation("Alpha")
    a:SetFromAlpha(0)
    a:SetToAlpha(1)
    a:SetDuration(0.17)
    frame._introAnim = group
    return group
end

local function PlayIntro(frame)
    local intro = EnsureIntroAnim(frame)
    if not intro then return end
    frame:SetAlpha(0)
    intro:Stop()
    intro:Play()
end

local function EnsureFlashAnim(frame)
    if not frame then return nil end
    if frame._flashAnim then return frame._flashAnim end

    local group = frame:CreateAnimationGroup()
    local out = group:CreateAnimation("Alpha")
    out:SetFromAlpha(1); out:SetToAlpha(0.3); out:SetDuration(0.07)
    local inn = group:CreateAnimation("Alpha")
    inn:SetFromAlpha(0.3); inn:SetToAlpha(1); inn:SetDuration(0.11); inn:SetOrder(2)
    frame._flashAnim = group
    return group
end

local function FlashFrame(frame)
    local flash = EnsureFlashAnim(frame)
    if not flash then return end
    flash:Stop(); flash:Play()
end

local function EnsureProgressShimmer(card)
    if not card or not card.ProgressFill then return nil end
    if card._progressShimmer then return card._progressShimmer end

    local group = card.ProgressFill:CreateAnimationGroup()
    group:SetLooping("BOUNCE")
    local a = group:CreateAnimation("Alpha")
    a:SetFromAlpha(0.55); a:SetToAlpha(1); a:SetDuration(0.72)
    card._progressShimmer = group
    return group
end

local function SetProgressShimmer(card, enabled)
    local shimmer = EnsureProgressShimmer(card)
    if not shimmer then return end
    if enabled then
        if not shimmer:IsPlaying() then shimmer:Play() end
    else
        shimmer:Stop()
        if card.ProgressFill then card.ProgressFill:SetAlpha(1) end
    end
end

---------------------------------------------------------------------------
-- Debug / data helpers
---------------------------------------------------------------------------
local function LogHuntPanel(action, detail, extra)
    if not (ns.Debug and type(ns.Debug.Log) == "function" and type(ns.Debug.KV) == "function") then
        return
    end
    ns.Debug:Log("hunts", ns.Debug:KV("action", action), ns.Debug:KV("detail", detail), ns.Debug:KV("extra", extra))
end

local function GetRemnantQuantity()
    local hunt = Constants and Constants.Hunt
    if not hunt or type(hunt.RemnantCurrencyID) ~= "number" then return 0 end
    if type(C_CurrencyInfo) ~= "table" or type(C_CurrencyInfo.GetCurrencyInfo) ~= "function" then return 0 end
    local info = SafeCall(C_CurrencyInfo.GetCurrencyInfo, hunt.RemnantCurrencyID)
    if type(info) ~= "table" then return 0 end
    return info.quantity or info.totalEarned or 0
end

local function GetRemnantIconID()
    local hunt = Constants and Constants.Hunt
    if not hunt or type(hunt.RemnantCurrencyID) ~= "number" then return nil end
    if type(C_CurrencyInfo) ~= "table" or type(C_CurrencyInfo.GetCurrencyInfo) ~= "function" then return nil end
    local info = SafeCall(C_CurrencyInfo.GetCurrencyInfo, hunt.RemnantCurrencyID)
    if type(info) ~= "table" then return nil end
    return info.iconFileID
end

local function GetQuestChoiceDialog()
    if _G[QUEST_CHOICE_DIALOG_NAME] then
        return _G[QUEST_CHOICE_DIALOG_NAME]
    end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return nil
    end
    if type(C_AddOns) == "table" and type(C_AddOns.LoadAddOn) == "function" then
        SafeCall(C_AddOns.LoadAddOn, ADVENTURE_MAP_ADDON)
    end
    return _G[QUEST_CHOICE_DIALOG_NAME]
end

local function EnsureHiddenAnchor()
    if HuntPanel.hiddenAnchor then return HuntPanel.hiddenAnchor end
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
    if hunt and hunt.pin then return hunt.pin end
    if anchorRegion then return anchorRegion end
    if panel and panel.frame then return panel.frame end
    return EnsureHiddenAnchor()
end

local function OpenQuestChoice(hunt, anchorRegion, autoAccept)
    if not hunt then return false end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then return false end
    local dialog = GetQuestChoiceDialog()
    if not dialog or type(dialog.ShowWithQuest) ~= "function" then return false end

    local parent = _G[MISSION_FRAME_NAME] or UIParent
    local livePin = hunt.pin or (HuntList and HuntList.FindPin and HuntList:FindPin(hunt.questID)) or nil
    if not livePin then return false end

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

---------------------------------------------------------------------------
-- Small widget factories
---------------------------------------------------------------------------
local function CreateText(parent, layer, template, point, x, y)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY", template or "GameFontNormal")
    if point then fs:SetPoint(point, x or 0, y or 0) end
    return fs
end

---------------------------------------------------------------------------
-- Filter button (created from XML template)
---------------------------------------------------------------------------
local function CreateFilterButton(parent, value, label)
    local button = CreateFrame("Button", nil, parent, "PreybreakerHuntFilterButtonTemplate")
    ApplyInsetBackdrop(button)
    button.Label:SetText(label)
    button.value = value
    button.Underscore:SetColorTexture(0, 0, 0, 0)

    -- Highlight color for hover (auto-shown by HIGHLIGHT layer)
    local color = DIFF_COLORS[value] or (SP().AccentColor or { 0.86, 0.66, 0.28 })
    if button.Highlight then
        button.Highlight:SetColorTexture(color[1], color[2], color[3], 0.12)
    end

    -- Pressed visual: shift label down
    button:SetScript("OnMouseDown", function(self)
        if self.Label then self.Label:AdjustPointsOffset(0, -1) end
    end)
    button:SetScript("OnMouseUp", function(self)
        if self.Label then self.Label:AdjustPointsOffset(0, 1) end
    end)

    button:SetScript("OnClick", function()
        if HuntList then HuntList:SetDifficultyFilter(value) end
        HuntPanel:Refresh()
    end)
    return button
end

local function UpdateFilterButton(button, selected)
    local p = SP()
    local color = DIFF_COLORS[button.value] or (p.AccentColor or { 0.86, 0.66, 0.28 })
    -- Update highlight color for current difficulty color
    if button.Highlight then
        button.Highlight:SetColorTexture(color[1], color[2], color[3], 0.12)
    end
    if selected then
        ApplyBackdrop(button, { color[1], color[2], color[3], 0.22 }, { color[1], color[2], color[3], 0.95 })
        SetTextColor(button.Label, p.TitleColor or { 0.94, 0.86, 0.72 })
        if button.Underscore then
            button.Underscore:SetColorTexture(color[1], color[2], color[3], 0.95)
        end
        FlashFrame(button)
        return
    end

    ApplyInsetBackdrop(button)
    SetTextColor(button.Label, p.MutedColor or { 0.58, 0.54, 0.49 })
    if button.Underscore then
        button.Underscore:SetColorTexture(0, 0, 0, 0)
    end
end

local function UpdateFilterButtons(frame)
    if not frame or not frame.FilterButtons then return end
    local selected = HuntList and HuntList:GetDifficultyFilter() or "All"
    for _, button in ipairs(frame.FilterButtons) do
        UpdateFilterButton(button, button.value == selected)
    end
end

---------------------------------------------------------------------------
-- Reward buttons
---------------------------------------------------------------------------
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
        if not reward or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        -- Rewards from SnapshotDialogPoolRewards have tooltipType="text" with
        -- only a name string. Using SetQuestItem/SetQuestCurrency requires a
        -- live quest choice dialog which is not open at tooltip time; those
        -- calls also need well-formed enum args that we do not have.
        -- Fall through to SetText for all reward types.
        if reward.name and reward.name ~= "" then
            GameTooltip:SetText(reward.name, 1, 1, 1)
            if reward.count then
                GameTooltip:AddLine(string.format("Quantity: %s", reward.count), 0.8, 0.8, 0.8)
            end
        else
            GameTooltip:SetText("Unknown reward")
        end

        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

local function UpdateRewardButton(button, reward)
    button.reward = reward
    if not reward then button:Hide(); return end
    button:SetID(reward.rewardIndex or 0)
    button.type = reward.tooltipType or "item"
    button.Icon:SetTexture(reward.texture or reward.icon)
    button:Show()
end

local function ShowAchievementTooltip(owner, hunt)
    if not owner or not hunt or not hunt.achievement or not GameTooltip then
        return
    end

    local achievement = hunt.achievement
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(hunt.name or L["Unknown prey"], 1, 1, 1)

    if hunt.difficulty and hunt.difficulty ~= "" then
        GameTooltip:AddLine(string.format(L["Difficulty: %s"], hunt.difficulty), 1, 0.82, 0.18)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(achievement.markerText or L["This Prey target is a requirement for an unearned achievement."], 1, 0.82, 0.18, true)

    if achievement.name and achievement.name ~= "" then
        GameTooltip:AddLine(achievement.name, 1, 1, 1, true)
    end

    if achievement.description and achievement.description ~= "" then
        GameTooltip:AddLine(achievement.description, 0.82, 0.90, 0.63, true)
    end

    GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Hunt row (created from XML template)
---------------------------------------------------------------------------
local function CreateHuntRow(parent)
    local row = CreateFrame("Button", nil, parent, "PreybreakerHuntRowTemplate")
    row:SetSize(parent:GetWidth(), ROW_HEIGHT)
    row:SetFrameLevel(parent:GetFrameLevel() + 1)

    local p = SP()
    ApplyCardBackdrop(row)

    -- Apply colors to XML-defined textures
    row.Pulse:SetColorTexture(0, 0, 0, 0)
    EnsurePulseAlpha(row.Pulse, "_activePulseAnim", 0.05, 0.15, 0.85)

    local ac = p.AccentColor or { 0.86, 0.66, 0.28 }
    row.Highlight:SetColorTexture(ac[1], ac[2], ac[3], 0.06)
    row.SideBand:SetColorTexture(ac[1], ac[2], ac[3], 0.80)
    row.Scanline:SetColorTexture(ac[1], ac[2], ac[3], 0.12)
    row.FooterRule:SetColorTexture(ac[1], ac[2], ac[3], 0.10)

    -- Map XML parentKeys to the names Lua expects
    row.Difficulty = row.DifficultyPill.Text
    row.Status = row.StatusFrame.Text
    ApplyInsetBackdrop(row.DifficultyPill)
    ApplyInsetBackdrop(row.StatusFrame)

    if not row.AchievementIcon then
        row.AchievementIcon = row:CreateTexture(nil, "OVERLAY")
        row.AchievementIcon:SetSize(14, 14)
    end
    row.AchievementIcon:SetAtlas(ACHIEVEMENT_ICON_FALLBACK_ATLAS)
    row.AchievementIcon:SetVertexColor(1, 1, 1, 1)
    row.AchievementIcon:Hide()

    if not row.AchievementTooltipHitbox then
        local hitbox = CreateFrame("Frame", nil, row)
        hitbox:SetSize(14, 14)
        hitbox:SetFrameStrata(row:GetFrameStrata())
        hitbox:SetFrameLevel(row:GetFrameLevel() + 8)
        hitbox:EnableMouse(true)
        hitbox:Hide()
        hitbox:SetScript("OnEnter", function(self)
            local parentRow = self:GetParent()
            if not parentRow or not parentRow.hunt then
                return
            end
            ShowAchievementTooltip(self, parentRow.hunt)
        end)
        hitbox:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
        -- Preserve the normal row click behavior when clicking directly on the icon.
        hitbox:SetScript("OnMouseUp", function(self, button)
            local parentRow = self:GetParent()
            if not parentRow then
                return
            end
            local onClick = parentRow:GetScript("OnClick")
            if onClick then
                onClick(parentRow, button)
            end
        end)
        row.AchievementTooltipHitbox = hitbox
    end

    -- Accept button (modern accent style)
    ApplyAccentButtonStyle(row.AcceptButton, "Accept")

    -- Reward shelf
    row.Rewards = {}
    for i = 1, MAX_REWARD_ICONS do
        local reward = CreateRewardButton(row.RewardShelf, i)
        reward:SetPoint("LEFT", row.RewardShelf, "LEFT", (i - 1) * (REWARD_ICON_SIZE + 4), 0)
        SetupRewardTooltip(reward)
        row.Rewards[i] = reward
    end

    -- Accept button script
    row.AcceptButton:SetScript("OnClick", function()
        if row.hunt then OpenQuestChoice(row.hunt, row, true) end
    end)

    row:SetScript("OnClick", function(self)
        if self.hunt then OpenQuestChoice(self.hunt, self, false) end
    end)
    row:SetScript("OnEnter", function(self)
        self.Highlight:SetColorTexture(ac[1], ac[2], ac[3], 0.14)
    end)
    row:SetScript("OnLeave", function(self)
        self.Highlight:SetColorTexture(ac[1], ac[2], ac[3], 0.06)
    end)

    return row
end

local function LayoutHuntRow(row, width)
    if not row then return end
    row._layoutWidth = width
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

    for index = 1, MAX_REWARD_ICONS do
        local reward = row.Rewards[index]
        reward:SetSize(iconSize, iconSize)
        reward:ClearAllPoints()
        reward:SetPoint("LEFT", row.RewardShelf, "LEFT", (index - 1) * (iconSize + gap), 0)
    end

    local rightPad = compact and 66 or 74
    row.Title:ClearAllPoints()
    if row.AchievementIcon and row.AchievementIcon:IsShown() then
        row.AchievementIcon:ClearAllPoints()
        row.AchievementIcon:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -30)
        if row.AchievementTooltipHitbox then
            row.AchievementTooltipHitbox:ClearAllPoints()
            row.AchievementTooltipHitbox:SetPoint("TOPLEFT", row.AchievementIcon, "TOPLEFT", 0, 0)
            row.AchievementTooltipHitbox:Show()
        end
        row.Title:SetPoint("TOPLEFT", row.AchievementIcon, "TOPRIGHT", 4, 0)
    else
        if row.AchievementTooltipHitbox then
            row.AchievementTooltipHitbox:Hide()
        end
        row.Title:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -30)
    end
    row.Title:SetPoint("TOPRIGHT", row, "TOPRIGHT", -rightPad, -30)
    row.Zone:ClearAllPoints()
    row.Zone:SetPoint("TOPLEFT", row.Title, "BOTTOMLEFT", 0, -1)
    row.Zone:SetPoint("TOPRIGHT", row, "TOPRIGHT", -rightPad, 0)
end

---------------------------------------------------------------------------
-- Text helpers
---------------------------------------------------------------------------
local function GetRowCountHint(hunts)
    local inProgress, available = 0, 0
    for _, hunt in ipairs(hunts or {}) do
        if hunt.inProgress then inProgress = inProgress + 1
        else available = available + 1 end
    end
    return inProgress, available
end

local function GetRewardSummaryText(hunt)
    if not hunt then return "Rewards pending" end
    if hunt.rewardState == "retrying" then return "Syncing rewards" end
    if hunt.rewardState == "empty" then return "No reward choices" end
    if not hunt.rewards then return "Rewards pending" end
    if #hunt.rewards == 0 then return "No reward choices" end
    return string.format("%d reward choices", #hunt.rewards)
end

local function GetAnguishText()
    return tostring(GetRemnantQuantity())
end

---------------------------------------------------------------------------
-- Loading card
---------------------------------------------------------------------------
local function UpdateLoadingCard(frame, done, total, text)
    if not frame then return end
    local hasProgress = type(done) == "number" and type(total) == "number" and total > 0
    local fill = frame.ProgressFill
    local width = frame.ProgressTrack:GetWidth() or 262
    if width <= 1 then width = 262 end

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

local function ApplyLoadingCardColors(card)
    local p = SP()
    ApplyCardBackdrop(card)
    card.Title:SetText("Hunt Sync")
    SetTextColor(card.Title, p.TitleColor or { 0.94, 0.86, 0.72 })
    SetTextColor(card.StatusText, p.MutedColor or { 0.58, 0.54, 0.49 })
    SetTextColor(card.ProgressText, p.AccentColor or { 0.86, 0.66, 0.28 })
    card.ProgressTrack:SetColorTexture(0.07, 0.06, 0.05, 1)
    card.ProgressFill:SetColorTexture((p.AccentColor or { 0.86, 0.66, 0.28 })[1], (p.AccentColor or { 0.86, 0.66, 0.28 })[2], (p.AccentColor or { 0.86, 0.66, 0.28 })[3], 1)
end

local function CreateLoadingCard(parent, name)
    local card = CreateFrame("Frame", name, parent, "PreybreakerHuntLoadingCardTemplate")
    ApplyLoadingCardColors(card)
    return card
end

---------------------------------------------------------------------------
-- Map overlay (XML-defined frame, Lua styles and positions)
---------------------------------------------------------------------------
local function CreateMapOverlay()
    if HuntPanel.mapOverlay then return HuntPanel.mapOverlay end

    local overlay = _G["PreybreakerHuntMapOverlay"]
    if not overlay then
        overlay = CreateFrame("Frame", "PreybreakerHuntMapOverlay", UIParent)
        overlay:SetFrameStrata("DIALOG")
        overlay:SetFrameLevel(220)
        overlay:Hide()
        overlay.Background = overlay:CreateTexture(nil, "BACKGROUND")
        overlay.Background:SetAllPoints()
    end

    local p = SP()
    overlay.Background:SetColorTexture(
        (p.SurfaceColor or { 0.08, 0.06, 0.05, 0.96 })[1],
        (p.SurfaceColor or { 0.08, 0.06, 0.05, 0.96 })[2],
        (p.SurfaceColor or { 0.08, 0.06, 0.05, 0.96 })[3],
        0.64
    )

    overlay.Card = CreateLoadingCard(overlay, nil)
    overlay.Card:SetPoint("CENTER", overlay, "CENTER", 0, 0)
    HuntPanel.mapOverlay = overlay
    return overlay
end

local function AnchorMapOverlay()
    local overlay = HuntPanel.mapOverlay
    if not overlay then return end
    local missionFrame = _G[MISSION_FRAME_NAME]
    if missionFrame and missionFrame:IsShown() then
        overlay:SetParent(UIParent)
        overlay:ClearAllPoints()
        overlay:SetPoint("TOPLEFT", missionFrame, "TOPLEFT", 0, 0)
        overlay:SetPoint("BOTTOMRIGHT", missionFrame, "BOTTOMRIGHT", 0, 0)
        return
    end
    overlay:Hide()
end

---------------------------------------------------------------------------
-- Filter button layout
---------------------------------------------------------------------------
local function LayoutFilterButtons(frame)
    local bar = frame and frame.FilterBar
    local buttons = frame and frame.FilterButtons
    if not bar or not buttons then return end

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

---------------------------------------------------------------------------
-- Slim scroll track
---------------------------------------------------------------------------
local function UpdateScrollTrack(frame)
    local sf = frame and frame.ScrollFrame
    local track = frame and frame.Body and frame.Body.ScrollTrack
    if not sf or not track then return end

    local maxScroll = sf:GetVerticalScrollRange() or 0
    if maxScroll <= 0 then
        track:Hide()
        return
    end

    track:Show()
    local trackHeight = track:GetHeight() or 1
    if trackHeight <= 1 then return end

    local viewRatio = (sf:GetHeight() or 1) / ((sf:GetHeight() or 1) + maxScroll)
    local thumbHeight = math.max(16, math.floor(trackHeight * viewRatio))
    track.Thumb:SetHeight(thumbHeight)

    local scrollPos = sf:GetVerticalScroll() or 0
    local fraction = math.min(1, scrollPos / maxScroll)
    local travel = trackHeight - thumbHeight
    track.Thumb:ClearAllPoints()
    track.Thumb:SetPoint("TOP", track, "TOP", 0, -math.floor(fraction * travel))
end

---------------------------------------------------------------------------
-- Panel geometry
---------------------------------------------------------------------------
local function LayoutPanelGeometry(frame)
    if not frame or not frame.Body then return end
    frame.ScrollFrame:ClearAllPoints()
    frame.ScrollFrame:SetPoint("TOPLEFT", frame.Body.Summary, "BOTTOMLEFT", 0, -8)
    frame.ScrollFrame:SetPoint("BOTTOMRIGHT", frame.Body, "BOTTOMRIGHT", -8, 4)

    local scrollWidth = math.max(1, frame:GetWidth() - 44)
    if frame.ScrollChild then
        frame.ScrollChild:SetSize(scrollWidth, 1)
    end
    LayoutFilterButtons(frame)
    UpdateScrollTrack(frame)
end

---------------------------------------------------------------------------
-- Panel frame setup (from XML-defined PreybreakerHuntPanel)
---------------------------------------------------------------------------
local function SetupPanelFrame()
    if HuntPanel.frame then return HuntPanel.frame end

    local frame = _G["PreybreakerHuntPanel"]
    if not frame then
        -- Fallback: create in Lua if XML wasn't loaded (should not happen in production)
        frame = CreateFrame("Frame", "PreybreakerHuntPanel", UIParent, BACKDROP_TEMPLATE)
        frame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
        frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(200)
        frame:SetClampedToScreen(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:Hide()
    end

    local p = SP()
    local ac = p.AccentColor or { 0.86, 0.66, 0.28 }

    -- Apply SettingsPanel-matching colors
    ApplyDialogBackdrop(frame)

    -- Header band colors
    local surfaceRaised = p.SurfaceRaisedColor or { 0.11, 0.08, 0.06, 0.98 }
    frame.HeaderBand:SetColorTexture(surfaceRaised[1], surfaceRaised[2], surfaceRaised[3], surfaceRaised[4])
    frame.HeaderGlow:SetColorTexture(ac[1], ac[2], ac[3], 0.09)
    frame.HeaderLine:SetColorTexture(ac[1], ac[2], ac[3], 0.82)

    -- Drag scripts
    frame:SetScript("OnDragStart", function()
        if HuntPanel.mode ~= "standalone" then return end
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        HuntPanel:SaveStandaloneOffset()
    end)

    -- Title / subtitle
    frame.Title:SetText("TACTICAL HUNT CONSOLE")
    SetTextColor(frame.Title, p.TitleColor or { 0.94, 0.86, 0.72 })
    frame.Subtitle:SetText("Live prey routing, reward telemetry,\nand one-click quest access")
    SetTextColor(frame.Subtitle, p.MutedColor or { 0.58, 0.54, 0.49 })

    -- Close button
    frame.CloseButton:SetScript("OnClick", function()
        HuntPanel:Hide()
    end)

    -- Body container
    ApplyBackdrop(frame.Body, p.SurfaceColor or { 0.08, 0.06, 0.05, 0.96 }, p.BorderSoftColor or { 0.66, 0.49, 0.21, 0.34 })

    -- Summary text
    frame.Summary = frame.Body.Summary
    SetTextColor(frame.Summary, ac)

    -- Filter buttons
    frame.FilterBar = frame.Body.FilterBar
    frame.FilterButtons = {}
    local filterOrder = { "All", "Nightmare", "Hard", "Normal" }
    for _, filter in ipairs(filterOrder) do
        local button = CreateFilterButton(frame.FilterBar, filter, filter)
        frame.FilterButtons[#frame.FilterButtons + 1] = button
    end

    -- Scroll frame (bare — no UIPanelScrollFrameTemplate)
    frame.ScrollFrame = frame.Body.ScrollFrame
    frame.ScrollChild = CreateFrame("Frame", nil, frame.ScrollFrame)
    frame.ScrollChild:SetSize(PANEL_WIDTH - 44, 1)
    frame.ScrollFrame:SetScrollChild(frame.ScrollChild)

    -- Mouse wheel scrolling
    frame.ScrollFrame:EnableMouseWheel(true)
    frame.ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - delta * SCROLL_STEP))
        self:SetVerticalScroll(newScroll)
        UpdateScrollTrack(frame)
    end)
    frame.ScrollFrame:SetScript("OnVerticalScroll", function()
        UpdateScrollTrack(frame)
    end)

    -- Slim scroll track colors
    local scrollTrack = frame.Body.ScrollTrack
    scrollTrack.Background:SetColorTexture(0.06, 0.05, 0.04, 0.40)
    scrollTrack.Thumb:SetColorTexture(ac[1], ac[2], ac[3], 0.45)
    scrollTrack:Hide()

    -- Footer bar (Anguish icon + text + Mode toggle)
    frame.Footer = frame.Footer
    frame.AnguishIcon = frame.Footer.AnguishIcon
    frame.AnguishText = frame.Footer.AnguishText
    SetTextColor(frame.AnguishText, ac)

    -- Set currency icon (loaded at runtime from currency info)
    local iconID = GetRemnantIconID()
    if iconID then
        frame.AnguishIcon:SetTexture(iconID)
    else
        frame.AnguishIcon:SetTexture("Interface\\Icons\\INV_Misc_DesecrationCrystal")
    end
    frame.AnguishIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.ModeButton = frame.Footer.ModeButton
    ApplyAccentButtonStyle(frame.ModeButton, "Detach")
    frame.ModeButton:SetScript("OnClick", function()
        HuntPanel:ToggleStandalone()
    end)

    -- Empty state
    frame.EmptyIcon = frame.ScrollChild:CreateTexture(nil, "ARTWORK")
    frame.EmptyIcon:SetSize(42, 42)
    frame.EmptyIcon:SetPoint("CENTER", frame.ScrollChild, "CENTER", 0, -16)
    frame.EmptyIcon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastSoothe")
    frame.EmptyIcon:SetAlpha(0.45)
    frame.EmptyIcon:Hide()

    frame.EmptyState = CreateText(frame.ScrollChild, "OVERLAY", "GameFontDisableLarge")
    frame.EmptyState:SetPoint("TOP", frame.EmptyIcon, "BOTTOM", 0, -8)
    frame.EmptyState:SetText("No hunt signals detected.")
    SetTextColor(frame.EmptyState, p.MutedColor or { 0.58, 0.54, 0.49 })
    frame.EmptyState:Hide()

    -- Loading overlay
    frame.LoadingOverlay.Background:SetColorTexture(
        (p.SurfaceColor or { 0.08, 0.06, 0.05 })[1],
        (p.SurfaceColor or { 0.08, 0.06, 0.05 })[2],
        (p.SurfaceColor or { 0.08, 0.06, 0.05 })[3],
        0.74
    )
    frame.LoadingOverlay.Card = CreateLoadingCard(frame.LoadingOverlay, "PreybreakerHuntLoadingFrame")
    frame.LoadingOverlay.Card:SetPoint("CENTER", frame.LoadingOverlay, "CENTER", 0, 0)

    frame._layoutDirty = true
    frame.mode = HuntPanel.mode or "attached"

    HuntPanel.rows = {}
    HuntPanel.frame = frame
    return frame
end

-- Event handling is consolidated in the controller's EventRouter.
-- ADVENTURE_MAP_QUEST_UPDATE, QUEST_TURNED_IN removal, and warmup
-- suppression are handled through the controller → HuntPanel:Refresh() path.

---------------------------------------------------------------------------
-- Mission frame hooks
---------------------------------------------------------------------------
local function ApplyMissionFrameHooks()
    if missionHooksApplied then return end

    hooksecurefunc("ShowUIPanel", function(frame)
        if not frame or frame:GetName() ~= MISSION_FRAME_NAME then return end
        LogHuntPanel("hook:ShowUIPanel", MISSION_FRAME_NAME, string.format(
            "panelExists=%s,panelShown=%s,mode=%s",
            tostring(HuntPanel.frame ~= nil),
            tostring(HuntPanel.frame and HuntPanel.frame:IsShown()),
            tostring(HuntPanel.mode)))

        if HuntPanel.frame and HuntPanel.frame:IsShown() and HuntPanel.mode == "standalone" then
            LogHuntPanel("hook:ShowUIPanel", "skip", "standaloneShown")
            return
        end
        HuntPanel:ShowAttached()
    end)

    hooksecurefunc("HideUIPanel", function(frame)
        if not frame or frame:GetName() ~= MISSION_FRAME_NAME then return end
        HuntPanel:HideAttached()
    end)

    missionHooksApplied = true
end

---------------------------------------------------------------------------
-- Row state update
---------------------------------------------------------------------------
local function UpdateRowState(row, hunt)
    local p = SP()
    local color = DIFF_COLORS[hunt.difficulty] or DIFF_COLORS.All
    row.hunt = hunt
    local hasAchievementProgress = hunt.achievement and hunt.achievement.isIncomplete == true
    local hadAchievementProgress = row.AchievementIcon and row.AchievementIcon:IsShown() or false

    -- Difficulty pill
    ApplyBackdrop(row.DifficultyPill, { color[1], color[2], color[3], 0.22 }, { color[1], color[2], color[3], 0.95 })
    if row.SideBand then
        row.SideBand:SetColorTexture(color[1], color[2], color[3], 0.80)
    end

    row.Title:SetText(hunt.name or ("Quest " .. tostring(hunt.questID)))
    row.Difficulty:SetText(hunt.difficulty or "Normal")
    SetTextColor(row.Difficulty, p.TitleColor or { 0.94, 0.86, 0.72 })
    row.Zone:SetText(hunt.zone or L["Unknown zone"])
    SetTextColor(row.Zone, p.MutedColor or { 0.58, 0.54, 0.49 })
    if row.AchievementIcon then
        if hasAchievementProgress and hunt.achievement.icon then
            row.AchievementIcon:SetTexture(hunt.achievement.icon)
            row.AchievementIcon:SetTexCoord(0, 1, 0, 1)
            row.AchievementIcon:SetVertexColor(1, 1, 1, 1)
        else
            row.AchievementIcon:SetTexture(nil)
            row.AchievementIcon:SetAtlas(ACHIEVEMENT_ICON_FALLBACK_ATLAS)
            row.AchievementIcon:SetVertexColor(1, 1, 1, 1)
        end
        row.AchievementIcon:SetShown(hasAchievementProgress)
    end
    if hadAchievementProgress ~= hasAchievementProgress then
        LayoutHuntRow(row, row._layoutWidth or row:GetWidth())
    end

    -- Status
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
        SetTextColor(row.Status, p.PositiveColor or { 0.82, 0.90, 0.63 })
        ApplyBackdrop(row.StatusFrame, { color[1], color[2], color[3], 0.14 }, { color[1], color[2], color[3], 0.60 })
        if row.Pulse then
            row.Pulse:SetColorTexture(color[1], color[2], color[3], 0.10)
            if row.Pulse._activePulseAnim and not row.Pulse._activePulseAnim:IsPlaying() then
                row.Pulse._activePulseAnim:Play()
            end
        end
    elseif hunt.available then
        SetTextColor(row.Status, p.BodyColor or { 0.77, 0.72, 0.66 })
        ApplyInsetBackdrop(row.StatusFrame)
        if row.Pulse then
            row.Pulse:SetColorTexture(color[1], color[2], color[3], 0.02)
            if row.Pulse._activePulseAnim then row.Pulse._activePulseAnim:Stop() end
            row.Pulse:SetAlpha(1)
        end
    else
        SetTextColor(row.Status, p.MutedColor or { 0.58, 0.54, 0.49 })
        ApplyInsetBackdrop(row.StatusFrame)
        if row.Pulse then
            row.Pulse:SetColorTexture(color[1], color[2], color[3], 0.01)
            if row.Pulse._activePulseAnim then row.Pulse._activePulseAnim:Stop() end
            row.Pulse:SetAlpha(1)
        end
    end

    -- Rewards
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

---------------------------------------------------------------------------
-- Row pool and layout
---------------------------------------------------------------------------
local function AcquireRows(parent, count)
    HuntPanel.rows = HuntPanel.rows or {}
    for index = #HuntPanel.rows + 1, count do
        local row = CreateHuntRow(parent)
        HuntPanel.rows[index] = row
    end
    return HuntPanel.rows
end

local ZONE_SEPARATOR_HEIGHT = 22

local function AcquireZoneSeparator(parent, index)
    HuntPanel.zoneSeparators = HuntPanel.zoneSeparators or {}
    local sep = HuntPanel.zoneSeparators[index]
    if not sep then
        sep = CreateFrame("Frame", nil, parent)
        sep:SetHeight(ZONE_SEPARATOR_HEIGHT)

        sep.Line = sep:CreateTexture(nil, "ARTWORK")
        sep.Line:SetHeight(1)
        sep.Line:SetPoint("LEFT", 4, 0)
        sep.Line:SetPoint("RIGHT", -4, 0)
        sep.Line:SetPoint("BOTTOM", 0, 2)

        sep.Label = sep:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sep.Label:SetPoint("BOTTOMLEFT", sep.Line, "TOPLEFT", 0, 2)

        HuntPanel.zoneSeparators[index] = sep
    end
    return sep
end

local function HideAllZoneSeparators()
    if not HuntPanel.zoneSeparators then return end
    for _, sep in ipairs(HuntPanel.zoneSeparators) do
        sep:Hide()
    end
end

local function LayoutRows(frame, hunts)
    local scrollChild = frame.ScrollChild
    if scrollChild and frame then
        local bodyWidth = frame.Body and frame.Body:GetWidth() or frame:GetWidth()
        scrollChild:SetWidth(math.max(1, (bodyWidth or frame:GetWidth() or PANEL_WIDTH) - 24))
    end

    local rows = AcquireRows(scrollChild, math.max(1, #hunts))
    local y = 0
    local isAllFilter = HuntList and HuntList:GetDifficultyFilter() == "All"
    local lastZone = nil
    local sepIndex = 0
    local p = SP()
    local mc = p.MutedColor or { 0.58, 0.54, 0.49 }
    local ac = p.AccentColor or { 0.86, 0.66, 0.28 }

    HideAllZoneSeparators()

    for index, hunt in ipairs(hunts) do
        -- Insert zone separator when zone changes in "All" mode
        if isAllFilter and hunt.zone and hunt.zone ~= lastZone then
            sepIndex = sepIndex + 1
            local sep = AcquireZoneSeparator(scrollChild, sepIndex)
            sep:SetParent(scrollChild)
            sep:SetWidth(scrollChild:GetWidth())
            sep:ClearAllPoints()
            sep:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
            sep:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -y)
            sep.Label:SetText(hunt.zone)
            SetTextColor(sep.Label, mc)
            sep.Line:SetColorTexture(ac[1], ac[2], ac[3], 0.25)
            sep:Show()
            y = y + ZONE_SEPARATOR_HEIGHT
            lastZone = hunt.zone
        end

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
                    if row:IsShown() then PlayIntro(row) end
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
    UpdateScrollTrack(frame)
    local showEmpty = #hunts == 0
    frame.EmptyState:SetShown(showEmpty)
    if frame.EmptyIcon then
        frame.EmptyIcon:SetShown(showEmpty)
        if showEmpty then
            local pulse = EnsurePulseAlpha(frame.EmptyIcon, "_emptyPulseAnim", 0.32, 0.58, 1.1)
            if pulse and not pulse:IsPlaying() then pulse:Play() end
        elseif frame.EmptyIcon._emptyPulseAnim then
            frame.EmptyIcon._emptyPulseAnim:Stop()
            frame.EmptyIcon:SetAlpha(0.45)
        end
    end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function HuntPanel:Ensure()
    CreateMapOverlay()
    ApplyMissionFrameHooks()
    return SetupPanelFrame()
end

function HuntPanel:Anchor()
    local frame = self:Ensure()
    frame:ClearAllPoints()

    if self.mode == "attached" and _G[MISSION_FRAME_NAME] and _G[MISSION_FRAME_NAME]:IsShown() then
        frame:SetSize(ATTACHED_WIDTH, _G[MISSION_FRAME_NAME]:GetHeight() or PANEL_HEIGHT)
        frame:SetPoint("TOPRIGHT", _G[MISSION_FRAME_NAME], "TOPLEFT", -X_OFFSET, 0)
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
    if not frame then return end

    local hunts = HuntList and HuntList:GetFilteredSortedHunts() or {}
    local inProgress, available = GetRowCountHint(hunts)
    local filter = HuntList and HuntList:GetDifficultyFilter() or "All"
    frame.Summary:SetText(string.format("Band %s  |  Active %d  |  Ready %d", filter, inProgress, available))
    if frame.AnguishText then
        frame.AnguishText:SetText(GetAnguishText())
    end
    if frame.AnguishIcon then
        local iconID = GetRemnantIconID()
        if iconID then frame.AnguishIcon:SetTexture(iconID) end
    end
end

function HuntPanel:UpdateLoading(done, total, text)
    local frame = self.frame
    if not frame then return end

    if not frame:IsShown() then
        if self.mapOverlay then self.mapOverlay:Hide() end
        frame.LoadingOverlay:Hide()
        self._lastWarmupDone = nil
        self._lastWarmupTotal = nil
        return
    end

    local isAttached = self.mode == "attached" and _G[MISSION_FRAME_NAME] and _G[MISSION_FRAME_NAME]:IsShown()
    local showProgress = HuntList and (HuntList:IsWarmupActive() or HuntList:IsScanActive())

    -- Preserve last known progress when called with nil during active warmup
    if showProgress then
        if done ~= nil then
            self._lastWarmupDone = done
            self._lastWarmupTotal = total
        else
            done = self._lastWarmupDone
            total = self._lastWarmupTotal
        end
    else
        self._lastWarmupDone = nil
        self._lastWarmupTotal = nil
    end

    local visibleHunts = HuntList and HuntList.GetFilteredSortedHunts and HuntList:GetFilteredSortedHunts() or {}
    local blockPanel = showProgress and #visibleHunts == 0

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
    else
        -- Ensure overlay is hidden when not attached
        if self.mapOverlay then self.mapOverlay:Hide() end
    end

    if blockPanel then
        frame.LoadingOverlay:Show()
        UpdateLoadingCard(frame.LoadingOverlay.Card, done, total, text or (HuntList:IsWarmupActive() and "Synchronizing hunt deck" or "Stabilizing hunt signals"))
    else
        frame.LoadingOverlay:Hide()
    end
end

function HuntPanel:RequestWarmup()
    if not HuntList then
        LogHuntPanel("warmupSkip", "noHuntList", nil)
        return
    end

    if HuntList:IsWarmupActive() then
        LogHuntPanel("warmupSkip", "alreadyWarming", nil)
        return
    end

    if HuntList:IsScanActive() then
        LogHuntPanel("warmupSkip", "scanActive", nil)
        return
    end

    local state = (HuntList and HuntList.GetState) and HuntList:GetState() or nil
    local rewardCache = state and state.rewardCache or {}
    local hunts = state and state.hunts or {}

    local cacheWarm = true
    for _, hunt in ipairs(hunts) do
        if hunt.questID and not rewardCache[hunt.questID] then
            cacheWarm = false
            break
        end
    end

    if cacheWarm then
        LogHuntPanel("warmupSkip", "cacheAlreadyWarm", nil)
        return
    end

    LogHuntPanel("warmupStart", string.format("hunts=%d", #hunts), nil)

    HuntList:WarmRewardCacheAsync(function(done, total)
        LogHuntPanel("warmupProgress", string.format("done=%s,total=%s", tostring(done), tostring(total)), nil)

        if HuntPanel.frame and HuntPanel.frame:IsShown() then
            HuntPanel:UpdateLoading(done, total, "Synchronizing hunt deck")
            local currentHunts = HuntList and HuntList:GetFilteredSortedHunts() or {}
            LayoutRows(HuntPanel.frame, currentHunts)
            HuntPanel:UpdateSummary()
        end
    end, function()
        LogHuntPanel("warmupDone", "finished", nil)
        HuntPanel._lastWarmupDone = nil
        HuntPanel._lastWarmupTotal = nil
        if HuntPanel.frame and HuntPanel.frame:IsShown() then
            HuntPanel:Refresh()
        end
    end)
end

function HuntPanel:QuickEvaluateBeforeOpen()
    LogHuntPanel("quickEval", "start", nil)
    if not HuntList or not HuntList.QuickEvaluate then
        LogHuntPanel("quickEval", "noHuntList", nil)
        return true
    end
    local result = HuntList:QuickEvaluate()
    LogHuntPanel("quickEval", "result", tostring(result))
    return result ~= false
end

function HuntPanel:Refresh()
    local frame = self:Ensure()
    if not frame:IsShown() then
        LogHuntPanel("refresh", "skip", "frameNotShown")
        return
    end

    -- During warmup, ShowWithQuest triggers QUEST_LOG_UPDATE on each quest.
    -- Avoid full refresh; the warmup progress callback handles row/summary updates.
    if HuntList and HuntList.IsWarmupActive and HuntList:IsWarmupActive() then
        self:UpdateSummary()
        LogHuntPanel("refresh", "skip", "warmupActive")
        return
    end
    LogHuntPanel("refresh", "begin", string.format("mode=%s", tostring(self.mode)))

    self:Anchor()

    if HuntList and not HuntList:IsScanActive() then
        HuntList:RefreshFromPins()
    end

    local hunts = HuntList and HuntList:GetFilteredSortedHunts() or {}
    LayoutRows(frame, hunts)
    UpdateFilterButtons(frame)
    ApplyAccentButtonStyle(frame.ModeButton, self.mode == "attached" and "Detach" or "Dock")
    self:UpdateSummary()
    self:UpdateLoading(nil, nil, nil)

    if HuntList and HuntList:IsScanActive() then
        self:UpdateLoading(nil, nil, "Stabilizing map pins")
        return
    end

    self:RequestWarmup()
end

function HuntPanel:ShowAttached(skipScan)
    LogHuntPanel("showAttached", "enter", nil)
    if ns.Settings and not ns.Settings:IsHuntPanelEnabled() then
        LogHuntPanel("showAttached", "blocked", "huntPanelDisabled")
        return false
    end
    if not self:QuickEvaluateBeforeOpen() then
        LogHuntPanel("showAttached", "blocked", "quickEvalFailed")
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
    LogHuntPanel("showAttached", "frameShown", string.format(
        "shown=%s,width=%.0f,height=%.0f",
        tostring(frame:IsShown()), frame:GetWidth() or 0, frame:GetHeight() or 0))
    PlayIntro(frame)
    if not skipScan and HuntList then
        HuntList:BeginStabilizedScan(function()
            LogHuntPanel("scanCallback", "fired", string.format(
                "panelShown=%s", tostring(HuntPanel.frame and HuntPanel.frame:IsShown())))
            if HuntPanel.frame and HuntPanel.frame:IsShown() then
                HuntPanel:Refresh()
            end
        end)
    end
    self:Refresh()
    return true
end

function HuntPanel:ShowStandalone()
    if ns.Settings and not ns.Settings:IsHuntPanelEnabled() then
        LogHuntPanel("showStandalone", "blocked", "huntPanelDisabled")
        return false
    end
    if not self:QuickEvaluateBeforeOpen() then
        if ns.Settings and ns.Settings.SetHuntPanelStandalone then
            ns.Settings:SetHuntPanelStandalone(false)
        end
        self.mode = "attached"
        if self.frame then self.frame:Hide() end
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

    self._lastWarmupDone = nil
    self._lastWarmupTotal = nil

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
        -- Dock back: if the mission frame is open, re-attach; otherwise just hide.
        self:Hide()
        self.mode = "attached"
        if _G[MISSION_FRAME_NAME] and _G[MISSION_FRAME_NAME]:IsShown() then
            self:ShowAttached(true) -- skipScan: data is still fresh
        end
        return false
    end

    return self:ShowStandalone() == true
end

function HuntPanel:SaveStandaloneOffset()
    if not (self.frame and self.mode == "standalone" and ns.Settings) then return end

    local centerX, centerY = self.frame:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()
    if not centerX or not centerY or not parentCenterX or not parentCenterY then return end

    local round = (ns.Util and ns.Util.RoundNearest) or math.floor
    local offsetX = round(centerX - parentCenterX)
    local offsetY = round(centerY - parentCenterY)

    if ns.Settings.SetHuntPanelOffsetX then ns.Settings:SetHuntPanelOffsetX(offsetX) end
    if ns.Settings.SetHuntPanelOffsetY then ns.Settings:SetHuntPanelOffsetY(offsetY) end
end

function HuntPanel:OpenQuestChoice(hunt, anchorRegion, autoAccept)
    return OpenQuestChoice(hunt, anchorRegion, autoAccept == true)
end

function HuntPanel:OpenQuestChoiceByQuestID(questID, anchorRegion, autoAccept)
    if not questID or not HuntList then return false end
    local hunt = HuntList:GetHuntByQuestID(questID)
    if not hunt then return false end
    return OpenQuestChoice(hunt, anchorRegion, autoAccept == true)
end

function HuntPanel:RefreshLoading()
    self:UpdateLoading(nil, nil, nil)
end
