-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

local L = ns.L

local function GetController()
    return ns.Controller
end

local function GetSnapshot()
    local controller = GetController()
    if controller and controller.lastSnapshot then
        return controller.lastSnapshot
    end

    if ns.DataSource and ns.Settings and ns.Settings:IsEnabled() then
        return ns.DataSource.BuildSnapshot()
    end

    return { active = false }
end

local function GetStatusLine()
    if not ns.Settings or not ns.Settings:IsEnabled() then
        return L["Status: disabled"]
    end

    local snapshot = GetSnapshot()
    if snapshot and snapshot.active and snapshot.progressState ~= nil then
        local label = ns.Constants.StageLabelByState[snapshot.progressState] or "UNKNOWN"
        return string.format(L["Status: %s (%d%%)"], label, snapshot.percent or 0)
    end

    return L["Status: idle"]
end

function _G.Preybreaker_OnAddonCompartmentClick(addonName, buttonName)
    if addonName ~= ADDON_NAME or not ns.Settings then
        return
    end

    if buttonName == "LeftButton" and IsShiftKeyDown() and ns.SettingsPanel then
        ns.SettingsPanel:Open()
        return
    end

    -- Shift + Right-click: open hunt panel standalone
    if buttonName == "RightButton" and IsShiftKeyDown() then
        if ns.Settings and not ns.Settings:IsHuntPanelEnabled() then
            ns.Util.Print(L["Hunt panel disabled."])
            return
        end
        if ns.HuntPanel then
            ns.HuntPanel:ShowStandalone()
        end
        return
    end

    local controller = GetController()
    if buttonName == "RightButton" then
        if not ns.Settings:IsEnabled() then
            ns.Util.Print(L["Tracker disabled."])
            return
        end
        if controller then
            controller:Refresh("compartment:refresh")
        end
        ns.Util.Print(L["Refreshed prey widget state."])
        return
    end

    local enabled = ns.Settings:ToggleEnabled()
    if controller then
        controller:Refresh(enabled and "compartment:enabled" or "compartment:disabled")
    end

    if enabled then
        ns.Util.Print(L["Tracker enabled."])
    else
        ns.Util.Print(L["Tracker disabled."])
    end
end

function _G.Preybreaker_OnAddonCompartmentEnter(addonName, menuButtonFrame)
    if addonName ~= ADDON_NAME or not GameTooltip or not menuButtonFrame then
        return
    end

    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Preybreaker")
    GameTooltip:AddLine(L["Compact prey-hunt tracker anchored to the Blizzard widget."], 0.85, 0.82, 0.72, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(GetStatusLine(), 1, 0.82, 0.25)
    GameTooltip:AddLine(L["Left-click: Enable or disable the tracker"], 0.65, 0.85, 1, true)
    GameTooltip:AddLine(L["Shift-left-click: Open settings"], 0.65, 0.85, 1, true)
    GameTooltip:AddLine(L["Right-click: Force a tracker refresh"], 0.65, 0.85, 1, true)
    GameTooltip:AddLine(L["Shift-right-click: Open hunt panel"], 0.65, 0.85, 1, true)
    GameTooltip:Show()
end

function _G.Preybreaker_OnAddonCompartmentLeave(addonName)
    if addonName ~= ADDON_NAME or not GameTooltip then
        return
    end

    GameTooltip:Hide()
end
