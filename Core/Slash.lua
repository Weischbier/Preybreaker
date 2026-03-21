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
    ns.Util.Print("Commands: /pb, /pb settings, /pb toggle, /pb refresh, /pb reset, /pb debug")
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

    PrintHelp()
end
