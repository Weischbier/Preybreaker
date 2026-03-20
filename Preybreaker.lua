-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

local Preybreaker = CreateFrame("Frame", "PreybreakerController")
ns.Controller = Preybreaker

local function BuildInactiveSnapshot()
    return {
        active = false,
        widgetID = nil,
        questID = nil,
        activeQuestID = nil,
        worldQuestID = nil,
        mapID = nil,
        progressState = nil,
        progress = 0,
        percent = 0,
    }
end

local function AreWidgetAPIsAvailable()
    return type(C_UIWidgetManager) == "table"
        and type(C_UIWidgetManager.GetPowerBarWidgetSetID) == "function"
        and type(C_UIWidgetManager.GetAllWidgetsBySetID) == "function"
        and type(C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo) == "function"
end

local function GetWidgetUpdateID(widgetInfo)
    if type(widgetInfo) ~= "table" then
        return nil
    end

    return widgetInfo.widgetID
end

local function ShouldRefreshFromWidgetUpdate(widgetInfo)
    if type(widgetInfo) ~= "table" then
        return true
    end
    if widgetInfo.widgetType == ns.Constants.WidgetTypePrey then
        return true
    end

    return widgetInfo.widgetID ~= nil and widgetInfo.widgetID == Preybreaker.activeWidgetID
end

function Preybreaker:GetBootstrapState()
    if not self.bootstrapState then
        self.bootstrapState = {
            addonLoaded = false,
            widgetsAddonLoaded = false,
            widgetsReady = AreWidgetAPIsAvailable(),
            worldEntered = false,
        }
    end

    return self.bootstrapState
end

function Preybreaker:GetBootstrapSummary()
    local state = self:GetBootstrapState()
    return string.format(
        "addon=%s,widgets=%s,world=%s",
        state.addonLoaded and "1" or "0",
        state.widgetsReady and "1" or "0",
        state.worldEntered and "1" or "0"
    )
end

function Preybreaker:UpdateBootstrapState(event, arg1)
    local state = self:GetBootstrapState()

    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            state.addonLoaded = true
        elseif arg1 == "Blizzard_UIWidgets" then
            state.widgetsAddonLoaded = true
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        state.worldEntered = true
    end

    state.widgetsReady = state.widgetsAddonLoaded == true or AreWidgetAPIsAvailable()
    return state
end


function Preybreaker:BuildInactiveSnapshot()
    return BuildInactiveSnapshot()
end

function Preybreaker:GetWidgetUpdateID(widgetInfo)
    return GetWidgetUpdateID(widgetInfo)
end

function Preybreaker:ShouldRefreshFromWidgetUpdate(widgetInfo)
    return ShouldRefreshFromWidgetUpdate(widgetInfo)
end

do
    local getInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
    if type(getInfo) == "function" then
        local ok, name = pcall(getInfo, "PreybreakerTests")
        if ok and name then
            _G._PreybreakerTestNS = ns
        end
    end
end
