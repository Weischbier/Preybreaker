-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

ns.MinimapButton = ns.MinimapButton or {}

local MinimapButton = ns.MinimapButton
local BUTTON_NAME = "PreybreakerMinimapButton"
local BUTTON_SIZE = 32
local DEFAULT_RADIUS = 80

local function IsShiftHeld()
    if type(IsShiftKeyDown) == "function" and IsShiftKeyDown() then return true end
    if type(IsLeftShiftKeyDown) == "function" and IsLeftShiftKeyDown() then return true end
    if type(IsRightShiftKeyDown) == "function" and IsRightShiftKeyDown() then return true end
    return false
end

local function GetAngleRadians(angle)
    return math.rad(tonumber(angle) or 220)
end

local function RunLiveRescan()
    if ns.HuntList and type(ns.HuntList.ResetCachedHuntsForRescan) == "function" then
        ns.HuntList:ResetCachedHuntsForRescan()
        ns.HuntList:BeginStabilizedScan(function()
            if ns.HuntPanel and ns.HuntPanel.frame and ns.HuntPanel.frame:IsShown() then
                ns.HuntPanel:Refresh()
            elseif ns.Controller then
                ns.Controller:Refresh("minimap:huntrescan")
            end
        end, { forceLive = true })
    elseif ns.Controller then
        ns.Controller:Refresh("minimap:huntrescan")
    end
end

local function UpdateTooltip(button)
    if not GameTooltip or not button then
        return
    end

    local L = ns.L
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Preybreaker")
    GameTooltip:AddLine(L["Left-click: Open settings"], 0.65, 0.85, 1, true)
    GameTooltip:AddLine(L["Right-click: Open command center"], 0.65, 0.85, 1, true)
    GameTooltip:AddLine(L["Shift-click: Live hunt rescan"], 0.65, 0.85, 1, true)
    GameTooltip:Show()
end

local function SaveDragPosition(button)
    if not (button and ns.Settings and type(GetCursorPosition) == "function" and Minimap and Minimap.GetCenter) then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    local centerX, centerY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale() or 1
    cursorX = cursorX / scale
    cursorY = cursorY / scale
    local dx = cursorX - centerX
    local dy = cursorY - centerY
    local angle
    if type(math.atan2) == "function" then
        angle = math.deg(math.atan2(dy, dx))
    elseif dx == 0 then
        angle = dy >= 0 and 90 or -90
    else
        angle = math.deg(math.atan(dy / dx))
        if dx < 0 then
            angle = angle + 180
        end
    end
    if angle < 0 then
        angle = angle + 360
    end

    ns.Settings:SetMinimapAngle(angle)
    MinimapButton:UpdatePosition()
end

function MinimapButton:UpdatePosition()
    local button = self.button
    if not (button and Minimap) then
        return
    end

    local angle = ns.Settings and ns.Settings:GetMinimapAngle() or 220
    local radians = GetAngleRadians(angle)
    local x = math.cos(radians) * DEFAULT_RADIUS
    local y = math.sin(radians) * DEFAULT_RADIUS

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton:Ensure()
    if self.button then
        return self.button
    end

    if not Minimap or type(CreateFrame) ~= "function" then
        return nil
    end

    local button = CreateFrame("Button", BUTTON_NAME, Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", button, "CENTER", 1, 1)
    icon:SetTexture(ns.Constants and ns.Constants.Media and ns.Constants.Media.AddonIcon or "Interface\\Icons\\Ability_Hunter_MarkedForDeath")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.Icon = icon

    button:SetScript("OnClick", function(_, mouseButton)
        if IsShiftHeld() then
            RunLiveRescan()
            return
        end

        if mouseButton == "RightButton" then
            if ns.HuntCommandCenter then
                ns.HuntCommandCenter:Open("overview")
            elseif ns.HuntPanel then
                ns.HuntPanel:ShowStandalone()
            end
            return
        end

        if ns.SettingsPanel then
            ns.SettingsPanel:Open()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        if ns.Settings and ns.Settings:IsMinimapLocked() then
            return
        end
        self:SetScript("OnUpdate", SaveDragPosition)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        SaveDragPosition(self)
    end)
    button:SetScript("OnEnter", UpdateTooltip)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    self.button = button
    self:UpdatePosition()
    return button
end

function MinimapButton:Refresh()
    local button = self:Ensure()
    if not button then
        return
    end

    if ns.Settings and ns.Settings:ShouldShowMinimapButton() then
        self:UpdatePosition()
        button:Show()
    else
        button:Hide()
    end
end
