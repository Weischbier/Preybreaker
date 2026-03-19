-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

local Debug = {}
ns.Debug = Debug

local function IsEnabledFromConstants()
    local settings = ns.Constants and ns.Constants.Debug
    return type(settings) == "table" and settings.Enabled == true
end

local function FormatNumber(value)
    if math.floor(value) == value then
        return tostring(value)
    end

    return string.format("%.3f", value)
end

local function ToString(value)
    local valueType = type(value)
    if value == nil then
        return "nil"
    end
    if valueType == "boolean" then
        return value and "true" or "false"
    end
    if valueType == "number" then
        return FormatNumber(value)
    end

    return tostring(value)
end

local function Emit(message)
    local chatFrame = _G.DEFAULT_CHAT_FRAME
    if chatFrame and type(chatFrame.AddMessage) == "function" then
        chatFrame:AddMessage(message)
        return
    end

    if type(print) == "function" then
        print(message)
    end
end

function Debug:IsEnabled()
    return self.enabled == true or IsEnabledFromConstants()
end

function Debug:SetEnabled(enabled)
    self.enabled = enabled == true
end

function Debug:KV(key, value)
    return tostring(key) .. "=" .. ToString(value)
end

function Debug:DescribeObject(object)
    if object == nil then
        return "nil"
    end

    if type(object.GetObjectType) ~= "function" then
        return ToString(object)
    end

    local objectType = object:GetObjectType()
    local name = type(object.GetName) == "function" and object:GetName() or nil
    if not name or name == "" then
        name = "<unnamed>"
    end

    local widgetID = object.widgetID
    if widgetID ~= nil then
        return string.format("%s<%s>#%s", name, objectType, tostring(widgetID))
    end

    return string.format("%s<%s>", name, objectType)
end

function Debug:Log(topic, ...)
    if not self:IsEnabled() then
        return
    end

    local parts = {}
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value and value ~= "" then
            parts[#parts + 1] = tostring(value)
        end
    end

    local suffix = #parts > 0 and (" " .. table.concat(parts, " | ")) or ""
    Emit(string.format("|cffd7b552%s|r [%s]%s", ADDON_NAME, topic, suffix))
end
