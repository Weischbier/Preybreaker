-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local L = ns.L

local function OpenSettings()
    if ns.SettingsPanel then
        ns.SettingsPanel:Open()
    end
end

local function PrintHelp()
    ns.Util.Print(L["Commands: /pb, /pb settings, /pb toggle, /pb refresh, /pb hunts, /pb reset, /pb debug, /pb diag, /pb mapdump"])
end

SLASH_PREYBREAKER1 = "/preybreaker"
SLASH_PREYBREAKER2 = "/pb"

SlashCmdList.PREYBREAKER = function(message)
    local command = strlower(strtrim(message or ""))

    if command == "" or command == "config" or command == "options" or command == "settings" then
        OpenSettings()
        return
    end

    if command == "toggle" and ns.Settings then
        local enabled = ns.Settings:ToggleEnabled()
        if ns.Controller then
            ns.Controller:Refresh(enabled and "slash:enabled" or "slash:disabled")
        end

        ns.Util.Print(enabled and L["Tracker enabled."] or L["Tracker disabled."])
        return
    end

    if command == "refresh" and ns.Controller then
        ns.Controller:Refresh("slash:refresh")
        ns.Util.Print(L["Refreshed prey widget state."])
        return
    end

    if command == "debug" or command == "debug on" or command == "debug off" then
        local enableDebug = command == "debug on"
        if command == "debug" then
            enableDebug = not (ns.Debug and ns.Debug:IsEnabled())
        end

        if ns.Debug then
            ns.Debug:SetEnabled(enableDebug)
        end
        if ns.Controller then
            ns.Controller:Refresh(enableDebug and "slash:debug-on" or "slash:debug-off")
        end

        ns.Util.Print(enableDebug and L["Debug tracing enabled."] or L["Debug tracing disabled."])
        return
    end

    if command == "reset" and ns.Settings then
        ns.Settings:ResetToDefaults()
        if ns.Controller then
            ns.Controller:Refresh("slash:reset")
        elseif ns.SettingsPanel then
            ns.SettingsPanel:RefreshControls()
            ns.SettingsPanel:RefreshPreview()
        end

        ns.Util.Print(L["Settings reset to defaults."])
        return
    end

    if command == "hunts" or command == "hunt" or command == "panel" then
        if ns.Settings and not ns.Settings:IsHuntPanelEnabled() then
            ns.Util.Print(L["Hunt panel disabled."])
            return
        end
        if ns.HuntPanel then
            ns.HuntPanel:ShowStandalone()
        end
        return
    end

    if command == "diagnostic" or command == "diag" then
        if ns.HuntList then
            ns.Util.Print(L["=== Prey Hunt Badge Diagnostic ==="])
            ns.HuntList:RefreshFromPins()

            local previousFilter = ns.HuntList.GetDifficultyFilter and ns.HuntList:GetDifficultyFilter() or nil
            if ns.HuntList.SetDifficultyFilter then
                ns.HuntList:SetDifficultyFilter("All")
            end

            local hunts = ns.HuntList:GetFilteredSortedHunts() or {}

            if previousFilter and ns.HuntList.SetDifficultyFilter then
                ns.HuntList:SetDifficultyFilter(previousFilter)
            end

            if #hunts == 0 then
                ns.Util.Print(L["No active hunt pins found."])
                return
            end

            for _, hunt in ipairs(hunts) do
                ns.Util.Print(string.format(
                    "%s [%s, %s]: %s (%s)",
                    hunt.name or L["Unknown prey"],
                    hunt.difficulty or L["Unknown difficulty"],
                    hunt.zone or L["Unknown zone"],
                    hunt.achievement and L["show icon"] or L["hide icon"],
                    hunt.achievement and hunt.achievement.source or L["none"]
                ))
            end
        end
        return
    end

    if command == "mapdump" or command == "dump" then
        if ns.HuntList and type(ns.HuntList.GetMapQuestDumpLines) == "function" then
            local lines = ns.HuntList:GetMapQuestDumpLines()
            for _, line in ipairs(lines or {}) do
                ns.Util.Print(line)
            end
        end
        return
    end

    PrintHelp()
end
