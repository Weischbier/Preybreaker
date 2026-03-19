-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Constants = ns.Constants
local Layout = Constants.Layout
local AtlasNames = Constants.Media.WidgetOrbAtlas

local OrbProgressMixin = {}

local OrderedStates = Constants.OrderedStates
local StageIndexByState = {}
for index, state in ipairs(OrderedStates) do
    StageIndexByState[state] = index
end

local DEFAULT_STAGE_STATE = OrderedStates[1] or 0

local GetAtlasInfo = ns.AtlasUtil.GetAtlasInfo
local ApplyAtlas = ns.AtlasUtil.ApplyAtlas

local function CreateValueText(parent)
    local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOutline")
    valueText:SetJustifyH("CENTER")
    valueText:SetPoint("CENTER", parent, "BOTTOM", Layout.OrbValueTextOffsetX, Layout.OrbValueTextOffsetY)
    valueText:SetTextColor(1, 0.82, 0, 1)

    local font, size, flags = valueText:GetFont()
    if font and size then
        valueText:SetFont(font, math.max(1, size + Layout.ValueTextFontDelta), flags)
    end

    return valueText
end

local function GetOrbSize(progressState)
    local sizeByState = Layout.OrbSizeByState
    return sizeByState[progressState] or sizeByState[DEFAULT_STAGE_STATE] or sizeByState[0] or 12
end

local function GetGlowSize(orbSize)
    return math.max(orbSize, math.floor((orbSize * Layout.OrbGlowScale) + 0.5))
end

local function CreateStageOrb(parent, progressState)
    local orb = {
        state = progressState,
    }

    orb.Glow = parent:CreateTexture(nil, "ARTWORK", nil, 0)
    orb.Glow:SetBlendMode("ADD")
    ApplyAtlas(orb.Glow, AtlasNames.Glow)

    orb.Fill = parent:CreateTexture(nil, "OVERLAY", nil, 1)
    ApplyAtlas(orb.Fill, AtlasNames.Fill)
    return orb
end

local function LayoutStageOrbs(frame)
    local spacing = Layout.OrbSpacing or 0
    local totalWidth = 0
    local maxGlowSize = 0

    for index, orb in ipairs(frame.StageOrbs) do
        local orbSize = GetOrbSize(orb.state)
        totalWidth = totalWidth + orbSize
        if index < #frame.StageOrbs then
            totalWidth = totalWidth + spacing
        end

        maxGlowSize = math.max(maxGlowSize, GetGlowSize(orbSize))
    end

    frame:SetSize(
        math.max(Layout.OrbFrameWidth or totalWidth, totalWidth),
        math.max(Layout.OrbFrameHeight or maxGlowSize, maxGlowSize)
    )

    local xOffset = -(totalWidth * 0.5)
    for _, orb in ipairs(frame.StageOrbs) do
        local orbSize = GetOrbSize(orb.state)
        local glowSize = GetGlowSize(orbSize)
        local orbCenterX = xOffset + (orbSize * 0.5)

        orb.Fill:ClearAllPoints()
        orb.Glow:ClearAllPoints()
        orb.Fill:SetPoint("CENTER", frame, "CENTER", orbCenterX, 0)
        orb.Glow:SetPoint("CENTER", frame, "CENTER", orbCenterX, 0)
        orb.Fill:SetSize(orbSize, orbSize)
        orb.Glow:SetSize(glowSize, glowSize)

        xOffset = xOffset + orbSize + spacing
    end
end

local function ApplyStageVisual(orb, reached)
    local color = Constants.ColorByState[orb.state] or Constants.ColorByState[DEFAULT_STAGE_STATE] or { 1, 1, 1 }
    local fillAlpha = reached and 1 or (Layout.OrbInactiveAlpha or 0.28)
    local glowAlpha = reached and (Layout.OrbGlowAlpha or 0.22) or (Layout.OrbInactiveGlowAlpha or 0.08)

    orb.Fill:SetVertexColor(color[1], color[2], color[3], fillAlpha)
    orb.Glow:SetVertexColor(color[1], color[2], color[3], glowAlpha)
end

function OrbProgressMixin:SetStageState(progressState)
    self.progressState = progressState

    local reachedIndex = StageIndexByState[progressState] or 0
    for index, orb in ipairs(self.StageOrbs) do
        ApplyStageVisual(orb, index <= reachedIndex)
    end
end

function OrbProgressMixin:SetPercentage(percentage)
    -- The orb stays stage-driven; keep percentage only for shared progress-bar API compatibility.
    self.percentage = ns.Util.Clamp01(percentage)
end

function OrbProgressMixin:SetValue(currentValue, maxValue)
    if not currentValue or not maxValue or maxValue == 0 then
        currentValue = 0
        maxValue = 1
    end

    self:SetPercentage(currentValue / maxValue)
end

function OrbProgressMixin:ShowNumber(showNumber)
    if not self.ValueText then
        return
    end

    if showNumber then
        self.ValueText:Show()
        return
    end

    self.ValueText:Hide()
end

function ns.CreateOrbProgress(parent, createValueText)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(Layout.OrbFrameWidth or 96, Layout.OrbFrameHeight or 80)
    Mixin(frame, OrbProgressMixin)

    frame.StageOrbs = {}
    for _, progressState in ipairs(OrderedStates) do
        frame.StageOrbs[#frame.StageOrbs + 1] = CreateStageOrb(frame, progressState)
    end

    LayoutStageOrbs(frame)

    if createValueText then
        frame.ValueText = CreateValueText(frame)
    end

    frame:ShowNumber(createValueText == true)
    frame:SetStageState(DEFAULT_STAGE_STATE)
    frame:SetPercentage(0)
    return frame
end
