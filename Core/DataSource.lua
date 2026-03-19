-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Constants = ns.Constants
local Util = ns.Util

ns.DataSource = {}

local function IsShown(widgetInfo)
    if type(widgetInfo) ~= "table" then
        return false
    end

    local shownState = widgetInfo.shownState
    if shownState == nil then
        return true
    end

    return shownState == Constants.WidgetShown
end

local function GetActiveQuestID()
    return Util.GetActivePreyQuestID()
end

local function GetPreyWidgetInfo()
    if type(C_UIWidgetManager) ~= "table" then
        return nil, nil
    end

    local getSetID = C_UIWidgetManager.GetPowerBarWidgetSetID
    local getWidgets = C_UIWidgetManager.GetAllWidgetsBySetID
    local getInfo = C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo
    if type(getSetID) ~= "function" or type(getWidgets) ~= "function" or type(getInfo) ~= "function" then
        return nil, nil
    end

    local widgetSetID = Util.SafeCall(getSetID)
    if not widgetSetID then
        return nil, nil
    end

    local widgets = Util.SafeCall(getWidgets, widgetSetID)
    if type(widgets) ~= "table" then
        return nil, nil
    end

    for _, widget in ipairs(widgets) do
        if widget.widgetType == Constants.WidgetTypePrey then
            local info = Util.SafeCall(getInfo, widget.widgetID)
            if IsShown(info) then
                return info, widget.widgetID
            end
        end
    end

    return nil, nil
end

local function IsQuestComplete(questID)
    return Util.IsQuestComplete(questID)
end

local function ResolveProgressState(widgetInfo)
    local progressState = widgetInfo and widgetInfo.progressState or nil
    if Constants.ProgressByState[progressState] == nil then
        return nil
    end

    return progressState
end

function ns.DataSource.BuildSnapshot()
    local questID = GetActiveQuestID()
    local widgetInfo, widgetID = GetPreyWidgetInfo()
    if not questID then
        return { active = false, widgetID = nil, progressState = nil, progress = 0, percent = 0 }
    end

    if IsQuestComplete(questID) then
        return {
            active = false,
            widgetID = widgetID,
            progressState = nil,
            progress = 0,
            percent = 0,
        }
    end

    local progressState = ResolveProgressState(widgetInfo)
    if progressState == nil then
        return {
            active = false,
            widgetID = widgetID,
            progressState = nil,
            progress = 0,
            percent = 0,
        }
    end

    local progress = Constants.ProgressByState[progressState] or 0
    progress = Util.Clamp01(progress)

    return {
        active = true,
        widgetID = widgetID,
        progressState = progressState,
        progress = progress,
        percent = Util.RoundPercent(progress),
    }
end
