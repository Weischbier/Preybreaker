-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
-- Portions adapted from Peterodox's Plumber: https://github.com/Peterodox/Plumber

local _, ns = ...

local Constants = ns.Constants

local LERP_SPEED = 8
local LERP_EPSILON = 0.002

-- Radial progress rendering adapted from Plumber.
local RadialProgressBarMixin = {}

function RadialProgressBarMixin:ApplyPercentage(percentage)
    local seconds = 100

    if percentage >= 1 then
        percentage = 1
    elseif percentage <= 0 then
        percentage = 0
    else
        -- Match Plumber's endpoint compensation so the fill cap lands cleanly.
        percentage = self.visualOffset * (1 - percentage) + (1 - self.visualOffset) * percentage
    end

    if type(self.Pause) == "function" then
        self:Pause()
    end

    self:SetCooldown(GetTime() - (seconds * percentage), seconds)

    if type(self.SetDrawEdge) == "function" then
        self:SetDrawEdge(percentage > 0)
    end
end

function RadialProgressBarMixin:SetPercentage(percentage)
    if percentage >= 1 then
        percentage = 1
    elseif percentage <= 0 then
        percentage = 0
    end

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

function RadialProgressBarMixin:SnapToPercentage(percentage)
    if percentage >= 1 then
        percentage = 1
    elseif percentage <= 0 then
        percentage = 0
    end

    self._targetPercentage = percentage
    self._animatedPercentage = percentage
    self:SetScript("OnUpdate", nil)
    self:ApplyPercentage(percentage)
end

function RadialProgressBarMixin:OnAnimationUpdate(elapsed)
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

function RadialProgressBarMixin:SetValue(currentValue, maxValue)
    if not currentValue or not maxValue or maxValue == 0 then
        currentValue = 0
        maxValue = 1
    end

    self:SetPercentage(currentValue / maxValue)
end

function RadialProgressBarMixin:ShowNumber(showNumber)
    if showNumber then
        if self.showNumber ~= true then
            self.showNumber = true

            if self.ValueText then
                self.ValueText:Show()
            end

            self.visualOffset = 0.07
            self.Border:SetTexCoord(0, 80 / 256, 80 / 256, 160 / 256)

            if self.BorderHighlight then
                self.BorderHighlight:SetTexCoord(0, 80 / 256, 80 / 256, 160 / 256)
            end

            self:SetSwipeTexCoord(80 / 256, 160 / 256, 80 / 256, 160 / 256)
        end

        return
    end

    if self.showNumber ~= false then
        self.showNumber = false

        if self.ValueText then
            self.ValueText:Hide()
        end

        self.visualOffset = 0.01
        self.Border:SetTexCoord(0, 80 / 256, 0, 80 / 256)

        if self.BorderHighlight then
            self.BorderHighlight:SetTexCoord(0, 80 / 256, 0, 80 / 256)
        end

        self:SetSwipeTexCoord(80 / 256, 160 / 256, 0, 80 / 256)
    end
end

function RadialProgressBarMixin:SetSwipeTexCoord(l, r, t, b)
    if type(self.SetTexCoordRange) == "function" then
        self:SetTexCoordRange({ x = l, y = t }, { x = r, y = b })
    end
end

local function CreateValueText(parent)
    local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOutline")
    valueText:SetJustifyH("CENTER")
    valueText:SetPoint("CENTER", parent, "BOTTOM", 2, 14)
    valueText:SetTextColor(1, 0.82, 0, 1)

    local font, size, flags = valueText:GetFont()
    if font and size then
        local adjustedSize = math.max(1, size + Constants.Layout.ValueTextFontDelta)
        valueText:SetFont(font, adjustedSize, flags)
    end

    return valueText
end

function ns.CreateRadialProgressBar(parent, createValueText)
    local frame = CreateFrame("Cooldown", nil, parent, "PreybreakerRadialProgressBarTemplate")
    local texturePath = Constants.Media.RadialProgress

    Mixin(frame, RadialProgressBarMixin)

    frame.Border:SetTexture(texturePath)

    if frame.BorderHighlight then
        frame.BorderHighlight:SetTexture(texturePath)
        frame.BorderHighlight:SetVertexColor(1, 1, 1, 1)
    end

    if type(frame.SetSwipeTexture) == "function" then
        frame:SetSwipeTexture(texturePath)
    end

    if type(frame.SetDrawSwipe) == "function" then
        frame:SetDrawSwipe(true)
    end

    if createValueText then
        frame.ValueText = CreateValueText(frame)
    end

    frame:ShowNumber(createValueText == true)
    frame.noCooldownCount = true

    return frame
end
