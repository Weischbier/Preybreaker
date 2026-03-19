-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Constants = ns.Constants
local Layout = Constants.Layout
local AtlasNames = Constants.Media.WidgetStatusBarAtlas

local ApplyAtlas = ns.AtlasUtil.ApplyAtlas

local LERP_SPEED = 8
local LERP_EPSILON = 0.002

local BarProgressBarMixin = {}

local function CreateValueText(parent)
    local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOutline")
    valueText:SetJustifyH("CENTER")
    valueText:SetPoint("CENTER", parent, "CENTER", 0, 0)
    valueText:SetTextColor(1, 0.82, 0, 1)

    local font, size, flags = valueText:GetFont()
    if font and size then
        valueText:SetFont(font, math.max(1, size + Layout.ValueTextFontDelta), flags)
    end

    return valueText
end

local function CreateSlice(parent, atlasName, drawLayer, subLevel)
    local texture = parent:CreateTexture(nil, drawLayer, nil, subLevel or 0)
    ApplyAtlas(texture, atlasName)
    return texture
end

function BarProgressBarMixin:UpdateMetrics()
    self.fillWidth = math.max(0, self:GetWidth() - (Layout.BarFillInsetX * 2))
end

function BarProgressBarMixin:ApplyPercentage(percentage)
    percentage = ns.Util.Clamp01(percentage)

    if self.fillWidth <= 0 or percentage <= 0 then
        self.Fill:Hide()
        self.Fill:SetWidth(0.001)
        self.Spark:Hide()
        return
    end

    local texWidth = math.max(1, math.floor((self.fillWidth * percentage) + 0.5))

    self.Fill:Show()
    self.Fill:SetWidth(texWidth)

    if percentage >= 1 then
        self.Spark:Hide()
        return
    end

    self.Spark:ClearAllPoints()
    self.Spark:SetPoint("CENTER", self.Fill, "RIGHT", 0, 0)
    self.Spark:Show()
end

function BarProgressBarMixin:SetPercentage(percentage)
    percentage = ns.Util.Clamp01(percentage)
    self.percentage = percentage
    self._targetPercentage = percentage

    if self._animatedPercentage == nil then
        self._animatedPercentage = percentage
        self:ApplyPercentage(percentage)
        return
    end

    if math.abs(self._animatedPercentage - percentage) < LERP_EPSILON then
        self._animatedPercentage = percentage
        self:ApplyPercentage(percentage)
        self:SetScript("OnUpdate", nil)
        return
    end

    self:SetScript("OnUpdate", self.OnAnimationUpdate)
end

function BarProgressBarMixin:SnapToPercentage(percentage)
    percentage = ns.Util.Clamp01(percentage)
    self.percentage = percentage
    self._targetPercentage = percentage
    self._animatedPercentage = percentage
    self:SetScript("OnUpdate", nil)
    self:ApplyPercentage(percentage)
end

function BarProgressBarMixin:OnAnimationUpdate(elapsed)
    local target = self._targetPercentage or 0
    local current = self._animatedPercentage or 0
    local delta = target - current

    if math.abs(delta) < LERP_EPSILON then
        self._animatedPercentage = target
        self:ApplyPercentage(target)
        self:SetScript("OnUpdate", nil)
        return
    end

    local step = delta * math.min(1, elapsed * LERP_SPEED)
    self._animatedPercentage = current + step
    self:ApplyPercentage(self._animatedPercentage)
end

function BarProgressBarMixin:SetValue(currentValue, maxValue)
    if not currentValue or not maxValue or maxValue == 0 then
        currentValue = 0
        maxValue = 1
    end

    self:SetPercentage(currentValue / maxValue)
end

function BarProgressBarMixin:ShowNumber(showNumber)
    if not self.ValueText then
        return
    end

    if showNumber then
        self.ValueText:Show()
        return
    end

    self.ValueText:Hide()
end

function BarProgressBarMixin:SetSwipeColor(r, g, b, a)
    a = a or 1
    self.Fill:SetVertexColor(r or 1, g or 1, b or 1, a)
    self.Spark:SetVertexColor(r or 1, g or 1, b or 1, math.min(1, a + 0.12))
end

function BarProgressBarMixin:SetBackgroundAlpha(alpha)
    alpha = alpha or 1
    self.BackgroundLeft:SetVertexColor(1, 1, 1, alpha)
    self.BackgroundCenter:SetVertexColor(1, 1, 1, alpha)
    self.BackgroundRight:SetVertexColor(1, 1, 1, alpha)
end

function ns.CreateBarProgress(parent, createValueText)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(Layout.BarWidth, Layout.BarHeight)
    Mixin(frame, BarProgressBarMixin)

    frame.BackgroundLeft = CreateSlice(frame, AtlasNames.BackgroundLeft, "BACKGROUND", 0)
    frame.BackgroundRight = CreateSlice(frame, AtlasNames.BackgroundRight, "BACKGROUND", 0)
    frame.BackgroundCenter = CreateSlice(frame, AtlasNames.BackgroundCenter, "BACKGROUND", 0)

    frame.BorderLeft = CreateSlice(frame, AtlasNames.BorderLeft, "ARTWORK", 1)
    frame.BorderRight = CreateSlice(frame, AtlasNames.BorderRight, "ARTWORK", 1)
    frame.BorderCenter = CreateSlice(frame, AtlasNames.BorderCenter, "ARTWORK", 1)

    frame.BackgroundLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", Layout.BarBackgroundInsetX, -Layout.BarBackgroundInsetY)
    frame.BackgroundLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", Layout.BarBackgroundInsetX, Layout.BarBackgroundInsetY)
    frame.BackgroundRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -Layout.BarBackgroundInsetX, -Layout.BarBackgroundInsetY)
    frame.BackgroundRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -Layout.BarBackgroundInsetX, Layout.BarBackgroundInsetY)
    frame.BackgroundCenter:SetPoint("TOPLEFT", frame.BackgroundLeft, "TOPRIGHT", 0, 0)
    frame.BackgroundCenter:SetPoint("BOTTOMRIGHT", frame.BackgroundRight, "BOTTOMLEFT", 0, 0)

    frame.BorderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.BorderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.BorderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.BorderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.BorderCenter:SetPoint("TOPLEFT", frame.BorderLeft, "TOPRIGHT", 0, 0)
    frame.BorderCenter:SetPoint("BOTTOMRIGHT", frame.BorderRight, "BOTTOMLEFT", 0, 0)

    frame.Fill = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.Fill:SetColorTexture(1, 1, 1, 1)
    frame.Fill:SetPoint("TOPLEFT", frame, "TOPLEFT", Layout.BarFillInsetX, -Layout.BarFillInsetY)
    frame.Fill:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", Layout.BarFillInsetX, Layout.BarFillInsetY)

    frame.Spark = CreateSlice(frame, AtlasNames.Spark, "OVERLAY", 2)
    frame.Spark:Hide()

    if createValueText then
        frame.ValueText = CreateValueText(frame)
    end

    frame:SetScript("OnSizeChanged", function(self)
        self:UpdateMetrics()
        self:ApplyPercentage(self._animatedPercentage or self.percentage or 0)
    end)

    frame:UpdateMetrics()
    frame:SetBackgroundAlpha(Layout.BarBackgroundAlpha)
    frame:ShowNumber(createValueText == true)
    frame:SetSwipeColor(0.82, 0.82, 0.86, 0.97)
    frame:SnapToPercentage(0)
    return frame
end
