-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local L = ns.L

local TextStyle = {}
ns.TextStyle = TextStyle

local BUILTIN_PREFIX = "builtin:"
local LSM_PREFIX = "lsm:"
local DEFAULT_FONT_VALUE = BUILTIN_PREFIX .. "standard"

local BUILTIN_FONTS = {
    {
        key = "standard",
        label = "Friz Quadrata",
        resolver = function()
            return STANDARD_TEXT_FONT
        end,
    },
    {
        key = "unit",
        label = "Arial Narrow",
        resolver = function()
            return UNIT_NAME_FONT
        end,
    },
    {
        key = "damage",
        label = "Skurri",
        resolver = function()
            return DAMAGE_TEXT_FONT
        end,
    },
}

local BUILTIN_FONT_KEYS = {}
for _, fontSpec in ipairs(BUILTIN_FONTS) do
    BUILTIN_FONT_KEYS[fontSpec.key] = true
end

local function GetLibSharedMedia()
    if type(LibStub) == "table" and type(LibStub.GetLibrary) == "function" then
        return LibStub:GetLibrary("LibSharedMedia-3.0", true)
    end

    if type(LibStub) == "function" then
        local ok, library = pcall(LibStub, "LibSharedMedia-3.0", true)
        if ok then
            return library
        end
    end

    return nil
end

local function GetBuiltinFontPath(fontKey)
    for _, fontSpec in ipairs(BUILTIN_FONTS) do
        if fontSpec.key == fontKey then
            local path = fontSpec.resolver and fontSpec.resolver() or nil
            if type(path) == "string" and path ~= "" then
                return path
            end
        end
    end

    return nil
end

local function ResolveOutlineFlags(mode, baseFlags)
    local monochrome = type(baseFlags) == "string" and string.find(baseFlags, "MONOCHROME", 1, true) ~= nil
    local suffix = monochrome and ",MONOCHROME" or ""

    if mode == "outline" then
        return "OUTLINE" .. suffix
    end
    if mode == "thick" then
        return "THICKOUTLINE" .. suffix
    end
    if mode == "none" then
        return monochrome and "MONOCHROME" or ""
    end

    return baseFlags or ""
end

local function CaptureDefaults(fontString)
    if not fontString or fontString._preybreakerTextDefaultsCaptured then
        return
    end

    local fontPath, fontSize, fontFlags = fontString:GetFont()
    fontString._preybreakerBaseFontPath = fontPath
    fontString._preybreakerBaseFontSize = fontSize or 12
    fontString._preybreakerBaseFontFlags = fontFlags or ""

    if type(fontString.GetShadowOffset) == "function" then
        local shadowX, shadowY = fontString:GetShadowOffset()
        fontString._preybreakerBaseShadowX = shadowX or 0
        fontString._preybreakerBaseShadowY = shadowY or 0
    end

    if type(fontString.GetShadowColor) == "function" then
        local r, g, b, a = fontString:GetShadowColor()
        fontString._preybreakerBaseShadowR = r or 0
        fontString._preybreakerBaseShadowG = g or 0
        fontString._preybreakerBaseShadowB = b or 0
        fontString._preybreakerBaseShadowA = a or 0
    end

    fontString._preybreakerTextDefaultsCaptured = true
end

local function ApplyShadowMode(fontString, mode)
    if type(fontString.SetShadowColor) ~= "function" or type(fontString.SetShadowOffset) ~= "function" then
        return
    end

    if mode == "off" then
        fontString:SetShadowColor(0, 0, 0, 0)
        fontString:SetShadowOffset(0, 0)
        return
    end

    if mode == "on" then
        fontString:SetShadowColor(0, 0, 0, 1)
        fontString:SetShadowOffset(1, -1)
        return
    end

    fontString:SetShadowColor(
        fontString._preybreakerBaseShadowR or 0,
        fontString._preybreakerBaseShadowG or 0,
        fontString._preybreakerBaseShadowB or 0,
        fontString._preybreakerBaseShadowA or 0
    )
    fontString:SetShadowOffset(
        fontString._preybreakerBaseShadowX or 0,
        fontString._preybreakerBaseShadowY or 0
    )
end

function TextStyle:GetDefaultFontValue()
    return DEFAULT_FONT_VALUE
end

function TextStyle:GetFontChoices()
    local choices = {}
    for _, fontSpec in ipairs(BUILTIN_FONTS) do
        choices[#choices + 1] = {
            value = BUILTIN_PREFIX .. fontSpec.key,
            label = L[fontSpec.label],
        }
    end

    local lsm = GetLibSharedMedia()
    if lsm and type(lsm.List) == "function" then
        local names = lsm:List("font")
        if type(names) == "table" then
            local sortedNames = {}
            for _, fontName in ipairs(names) do
                sortedNames[#sortedNames + 1] = fontName
            end

            table.sort(sortedNames)
            for _, fontName in ipairs(sortedNames) do
                choices[#choices + 1] = {
                    value = LSM_PREFIX .. fontName,
                    label = fontName,
                }
            end
        end
    end

    return choices
end

function TextStyle:GetOutlineChoices()
    return {
        { value = "default", label = L["Default"] },
        { value = "none", label = L["None"] },
        { value = "outline", label = L["Outline"] },
        { value = "thick", label = L["Thick outline"] },
    }
end

function TextStyle:GetShadowChoices()
    return {
        { value = "default", label = L["Default"] },
        { value = "on", label = L["On"] },
        { value = "off", label = L["Off"] },
    }
end

function TextStyle:SanitizeFontValue(value)
    if type(value) ~= "string" or value == "" then
        return DEFAULT_FONT_VALUE
    end

    if string.sub(value, 1, #BUILTIN_PREFIX) == BUILTIN_PREFIX then
        local builtinKey = string.sub(value, #BUILTIN_PREFIX + 1)
        if BUILTIN_FONT_KEYS[builtinKey] then
            return value
        end
    end

    if string.sub(value, 1, #LSM_PREFIX) == LSM_PREFIX then
        local fontName = string.sub(value, #LSM_PREFIX + 1)
        local lsm = GetLibSharedMedia()
        if lsm and type(lsm.Fetch) == "function" then
            local resolved = lsm:Fetch("font", fontName, true)
            if type(resolved) == "string" and resolved ~= "" then
                return value
            end
        end
    end

    return DEFAULT_FONT_VALUE
end

function TextStyle:ResolveFontPath(value, fallbackPath)
    local sanitized = self:SanitizeFontValue(value)

    if string.sub(sanitized, 1, #BUILTIN_PREFIX) == BUILTIN_PREFIX then
        local builtinKey = string.sub(sanitized, #BUILTIN_PREFIX + 1)
        return GetBuiltinFontPath(builtinKey) or fallbackPath or GetBuiltinFontPath("standard")
    end

    if string.sub(sanitized, 1, #LSM_PREFIX) == LSM_PREFIX then
        local fontName = string.sub(sanitized, #LSM_PREFIX + 1)
        local lsm = GetLibSharedMedia()
        if lsm and type(lsm.Fetch) == "function" then
            local resolved = lsm:Fetch("font", fontName, true)
            if type(resolved) == "string" and resolved ~= "" then
                return resolved
            end
        end
    end

    return fallbackPath or GetBuiltinFontPath("standard")
end

function TextStyle:Apply(fontString, scale)
    if not fontString or type(fontString.SetFont) ~= "function" or type(fontString.GetFont) ~= "function" then
        return
    end

    CaptureDefaults(fontString)

    local settings = ns.Settings
    local fontValue = settings and settings:GetTextFontFace() or DEFAULT_FONT_VALUE
    local outlineMode = settings and settings:GetTextOutlineMode() or "default"
    local shadowMode = settings and settings:GetTextShadowMode() or "default"

    local fontPath = self:ResolveFontPath(fontValue, fontString._preybreakerBaseFontPath)
    local fontSize = math.max(
        1,
        math.floor(((fontString._preybreakerBaseFontSize or 12) * (tonumber(scale) or 1)) + 0.5)
    )
    local fontFlags = ResolveOutlineFlags(outlineMode, fontString._preybreakerBaseFontFlags)

    fontString:SetFont(fontPath, fontSize, fontFlags)
    ApplyShadowMode(fontString, shadowMode)
end

function TextStyle:ApplyValue(fontString)
    local settings = ns.Settings
    local scale = settings and settings:GetValueTextScale() or 1
    self:Apply(fontString, scale)
end

function TextStyle:ApplyStage(fontString)
    local settings = ns.Settings
    local scale = settings and settings:GetStageTextScale() or 1
    self:Apply(fontString, scale)
end
