-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local DB_NAME = "PreybreakerDB"
local CHAR_DB_NAME = "PreybreakerCharDB"
local DISPLAY_MODE_RADIAL = "radial"
local DISPLAY_MODE_ORBS = "orbs"
local DISPLAY_MODE_BAR = "bar"
local DISPLAY_MODE_TEXT = "text"
local PLACEMENT_MODE_ATTACHED = "attached"
local PLACEMENT_MODE_DETACHED = "detached"
local DISPLAY_MODES = {
    DISPLAY_MODE_RADIAL,
    DISPLAY_MODE_ORBS,
    DISPLAY_MODE_BAR,
    DISPLAY_MODE_TEXT,
}
local DISPLAY_SETTING_KEYS = {
    hideBlizzardWidget = {
        [DISPLAY_MODE_RADIAL] = "radialHideBlizzardWidget",
        [DISPLAY_MODE_ORBS] = "orbHideBlizzardWidget",
        [DISPLAY_MODE_BAR] = "barHideBlizzardWidget",
        [DISPLAY_MODE_TEXT] = "textHideBlizzardWidget",
    },
    showValueText = {
        [DISPLAY_MODE_RADIAL] = "radialShowValueText",
        [DISPLAY_MODE_ORBS] = "orbShowValueText",
        [DISPLAY_MODE_BAR] = "barShowValueText",
        [DISPLAY_MODE_TEXT] = "textShowValueText",
    },
    showStageBadge = {
        [DISPLAY_MODE_RADIAL] = "radialShowStageBadge",
        [DISPLAY_MODE_ORBS] = "orbShowStageBadge",
        [DISPLAY_MODE_BAR] = "barShowStageBadge",
        [DISPLAY_MODE_TEXT] = "textShowStageBadge",
    },
    scale = {
        [DISPLAY_MODE_RADIAL] = "radialScale",
        [DISPLAY_MODE_ORBS] = "orbScale",
        [DISPLAY_MODE_BAR] = "barScale",
        [DISPLAY_MODE_TEXT] = "textScale",
    },
    placementMode = {
        [DISPLAY_MODE_RADIAL] = "radialPlacementMode",
        [DISPLAY_MODE_ORBS] = "orbPlacementMode",
        [DISPLAY_MODE_BAR] = "barPlacementMode",
        [DISPLAY_MODE_TEXT] = "textPlacementMode",
    },
    lockDetachedPosition = {
        [DISPLAY_MODE_RADIAL] = "radialLockDetachedPosition",
        [DISPLAY_MODE_ORBS] = "orbLockDetachedPosition",
        [DISPLAY_MODE_BAR] = "barLockDetachedPosition",
        [DISPLAY_MODE_TEXT] = "textLockDetachedPosition",
    },
}
local LEGACY_DISPLAY_SETTING_KEYS = {
    "hideBlizzardWidget",
    "showValueText",
    "showStageBadge",
    "scale",
}
local SCHEMA_VERSION = 2
local DEFAULT_SCALE = 1
local DEFAULT_TEXT_FONT_VALUE = (ns.TextStyle and ns.TextStyle:GetDefaultFontValue()) or "builtin:standard"
local DEFAULTS = {
    schemaVersion = SCHEMA_VERSION,
    enabled = true,
    displayMode = DISPLAY_MODE_RADIAL,
    radialHideBlizzardWidget = false,
    orbHideBlizzardWidget = false,
    barHideBlizzardWidget = false,
    radialShowValueText = true,
    orbShowValueText = true,
    barShowValueText = true,
    radialShowStageBadge = true,
    orbShowStageBadge = true,
    barShowStageBadge = true,
    radialScale = DEFAULT_SCALE,
    orbScale = DEFAULT_SCALE,
    barScale = DEFAULT_SCALE,
    radialPlacementMode = PLACEMENT_MODE_ATTACHED,
    orbPlacementMode = PLACEMENT_MODE_ATTACHED,
    barPlacementMode = PLACEMENT_MODE_ATTACHED,
    radialLockDetachedPosition = true,
    orbLockDetachedPosition = true,
    barLockDetachedPosition = true,
    radialOffsetX = 0,
    radialOffsetY = 0,
    orbOffsetX = 0,
    orbOffsetY = 0,
    barOffsetX = 0,
    barOffsetY = 0,
    radialDetachedX = 0,
    radialDetachedY = 0,
    orbDetachedX = 0,
    orbDetachedY = 0,
    barDetachedX = 0,
    barDetachedY = 0,
    textHideBlizzardWidget = false,
    textShowValueText = true,
    textShowStageBadge = true,
    textScale = DEFAULT_SCALE,
    textPlacementMode = PLACEMENT_MODE_ATTACHED,
    textLockDetachedPosition = true,
    textOffsetX = 0,
    textOffsetY = 0,
    textDetachedX = 0,
    textDetachedY = 0,
    autoWatchPreyQuest = false,
    autoSuperTrackPreyQuest = false,
    playSoundOnPhaseChange = false,
    snapToGrid = false,
    gridSize = 8,
    useCharacterProfile = false,
    textFontFace = DEFAULT_TEXT_FONT_VALUE,
    textOutlineMode = "default",
    textShadowMode = "default",
    valueTextScale = 1,
    stageTextScale = 1,
    coldColorR = nil,
    coldColorG = nil,
    coldColorB = nil,
    warmColorR = nil,
    warmColorG = nil,
    warmColorB = nil,
    hotColorR = nil,
    hotColorG = nil,
    hotColorB = nil,
    finalColorR = nil,
    finalColorG = nil,
    finalColorB = nil,
}

local SCALE_MIN = 0.50
local SCALE_MAX = 2.00
local SCALE_STEP = 0.05
local TEXT_SCALE_MIN = 0.75
local TEXT_SCALE_MAX = 1.75
local TEXT_SCALE_STEP = 0.05
local OFFSET_MIN = -40
local OFFSET_MAX = 40
local DETACHED_COORD_MIN = -2400
local DETACHED_COORD_MAX = 2400

ns.Settings = {}

local function ClampNumber(value, minValue, maxValue, defaultValue)
    value = tonumber(value)
    if not value then
        return defaultValue
    end
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function SanitizeBoolean(value, defaultValue)
    if type(value) ~= "boolean" then
        return defaultValue
    end
    return value
end

local function SanitizeDisplayMode(value)
    if value == DISPLAY_MODE_ORBS then
        return DISPLAY_MODE_ORBS
    end

    if value == DISPLAY_MODE_BAR then
        return DISPLAY_MODE_BAR
    end

    if value == DISPLAY_MODE_TEXT then
        return DISPLAY_MODE_TEXT
    end

    return DISPLAY_MODE_RADIAL
end

local GRID_SIZE_MIN = 4
local GRID_SIZE_MAX = 64

local function SanitizeColorComponent(value)
    local n = tonumber(value)
    if not n then
        return nil
    end
    if n < 0 then return 0 end
    if n > 1 then return 1 end
    return n
end

local function SanitizePlacementMode(value)
    if value == PLACEMENT_MODE_DETACHED then
        return PLACEMENT_MODE_DETACHED
    end

    return PLACEMENT_MODE_ATTACHED
end

local function SanitizeScale(value)
    local clamped = ClampNumber(value, SCALE_MIN, SCALE_MAX, DEFAULT_SCALE)
    local steps = ns.Util.RoundNearest((clamped - SCALE_MIN) / SCALE_STEP)
    local snapped = SCALE_MIN + (steps * SCALE_STEP)
    return ClampNumber(snapped, SCALE_MIN, SCALE_MAX, DEFAULT_SCALE)
end

local function SanitizeOffset(value)
    return ns.Util.RoundNearest(ClampNumber(value, OFFSET_MIN, OFFSET_MAX, 0))
end

local function SanitizeDetachedCoordinate(value)
    return ns.Util.RoundNearest(ClampNumber(value, DETACHED_COORD_MIN, DETACHED_COORD_MAX, 0))
end

local function SanitizeChoice(value, allowedValues, defaultValue)
    if type(value) ~= "string" then
        return defaultValue
    end

    for _, allowedValue in ipairs(allowedValues) do
        if value == allowedValue then
            return value
        end
    end

    return defaultValue
end

local function SanitizeTextScale(value)
    local clamped = ClampNumber(value, TEXT_SCALE_MIN, TEXT_SCALE_MAX, 1)
    local steps = ns.Util.RoundNearest((clamped - TEXT_SCALE_MIN) / TEXT_SCALE_STEP)
    local snapped = TEXT_SCALE_MIN + (steps * TEXT_SCALE_STEP)
    return ClampNumber(snapped, TEXT_SCALE_MIN, TEXT_SCALE_MAX, 1)
end

local function GetOffsetKey(axisSuffix, mode)
    local resolvedMode = SanitizeDisplayMode(mode)
    if resolvedMode == DISPLAY_MODE_BAR then
        return "barOffset" .. axisSuffix
    end
    if resolvedMode == DISPLAY_MODE_ORBS then
        return "orbOffset" .. axisSuffix
    end
    if resolvedMode == DISPLAY_MODE_TEXT then
        return "textOffset" .. axisSuffix
    end

    return "radialOffset" .. axisSuffix
end

local function GetDetachedKey(axisSuffix, mode)
    local resolvedMode = SanitizeDisplayMode(mode)
    if resolvedMode == DISPLAY_MODE_BAR then
        return "barDetached" .. axisSuffix
    end
    if resolvedMode == DISPLAY_MODE_ORBS then
        return "orbDetached" .. axisSuffix
    end
    if resolvedMode == DISPLAY_MODE_TEXT then
        return "textDetached" .. axisSuffix
    end

    return "radialDetached" .. axisSuffix
end

local function GetDisplaySettingKey(settingName, mode)
    local keyMap = DISPLAY_SETTING_KEYS[settingName]
    if not keyMap then
        return nil
    end

    return keyMap[SanitizeDisplayMode(mode)]
end

local DISPLAY_SETTING_SANITIZERS = {
    hideBlizzardWidget = function(value)
        return SanitizeBoolean(value, false)
    end,
    showValueText = function(value)
        return SanitizeBoolean(value, true)
    end,
    showStageBadge = function(value)
        return SanitizeBoolean(value, true)
    end,
    scale = SanitizeScale,
    placementMode = SanitizePlacementMode,
    lockDetachedPosition = function(value)
        return SanitizeBoolean(value, true)
    end,
}

local SANITIZERS = {
    schemaVersion = function(value)
        return SCHEMA_VERSION
    end,
    enabled = function(value)
        return SanitizeBoolean(value, DEFAULTS.enabled)
    end,
    displayMode = SanitizeDisplayMode,
    radialOffsetX = SanitizeOffset,
    radialOffsetY = SanitizeOffset,
    orbOffsetX = SanitizeOffset,
    orbOffsetY = SanitizeOffset,
    barOffsetX = SanitizeOffset,
    barOffsetY = SanitizeOffset,
    radialDetachedX = SanitizeDetachedCoordinate,
    radialDetachedY = SanitizeDetachedCoordinate,
    orbDetachedX = SanitizeDetachedCoordinate,
    orbDetachedY = SanitizeDetachedCoordinate,
    barDetachedX = SanitizeDetachedCoordinate,
    barDetachedY = SanitizeDetachedCoordinate,
    textOffsetX = SanitizeOffset,
    textOffsetY = SanitizeOffset,
    textDetachedX = SanitizeDetachedCoordinate,
    textDetachedY = SanitizeDetachedCoordinate,
    autoWatchPreyQuest = function(value)
        return SanitizeBoolean(value, false)
    end,
    autoSuperTrackPreyQuest = function(value)
        return SanitizeBoolean(value, false)
    end,
    playSoundOnPhaseChange = function(value)
        return SanitizeBoolean(value, false)
    end,
    snapToGrid = function(value)
        return SanitizeBoolean(value, false)
    end,
    gridSize = function(value)
        return ClampNumber(value, GRID_SIZE_MIN, GRID_SIZE_MAX, 8)
    end,
    useCharacterProfile = function(value)
        return SanitizeBoolean(value, false)
    end,
    textFontFace = function(value)
        if ns.TextStyle and type(ns.TextStyle.SanitizeFontValue) == "function" then
            return ns.TextStyle:SanitizeFontValue(value)
        end
        return DEFAULT_TEXT_FONT_VALUE
    end,
    textOutlineMode = function(value)
        return SanitizeChoice(value, { "default", "none", "outline", "thick" }, "default")
    end,
    textShadowMode = function(value)
        return SanitizeChoice(value, { "default", "on", "off" }, "default")
    end,
    valueTextScale = SanitizeTextScale,
    stageTextScale = SanitizeTextScale,
    coldColorR = SanitizeColorComponent,
    coldColorG = SanitizeColorComponent,
    coldColorB = SanitizeColorComponent,
    warmColorR = SanitizeColorComponent,
    warmColorG = SanitizeColorComponent,
    warmColorB = SanitizeColorComponent,
    hotColorR = SanitizeColorComponent,
    hotColorG = SanitizeColorComponent,
    hotColorB = SanitizeColorComponent,
    finalColorR = SanitizeColorComponent,
    finalColorG = SanitizeColorComponent,
    finalColorB = SanitizeColorComponent,
}

for settingName, keyMap in pairs(DISPLAY_SETTING_KEYS) do
    local sanitizer = DISPLAY_SETTING_SANITIZERS[settingName]
    for _, mode in ipairs(DISPLAY_MODES) do
        SANITIZERS[keyMap[mode]] = sanitizer
    end
end

local function MigrateLegacyOffsets(db)
    local hasLegacyX = db.offsetX ~= nil
    local hasLegacyY = db.offsetY ~= nil
    if not hasLegacyX and not hasLegacyY then
        return
    end

    local legacyOffsetX = SanitizeOffset(db.offsetX)
    local legacyOffsetY = SanitizeOffset(db.offsetY)

    if db.radialOffsetX == nil and hasLegacyX then
        db.radialOffsetX = legacyOffsetX
    end
    if db.radialOffsetY == nil and hasLegacyY then
        db.radialOffsetY = legacyOffsetY
    end
    if db.barOffsetX == nil and hasLegacyX then
        db.barOffsetX = legacyOffsetX
    end
    if db.barOffsetY == nil and hasLegacyY then
        db.barOffsetY = legacyOffsetY
    end

    db.offsetX = nil
    db.offsetY = nil
end

local function ApplyDefaults(db)
    local existingVersion = tonumber(db.schemaVersion) or 1

    -- v1 -> v2 migrations: legacy offset and per-display-mode key splits.
    if existingVersion < 2 then
        MigrateLegacyOffsets(db)
        for settingName, keyMap in pairs(DISPLAY_SETTING_KEYS) do
            local legacyValue = db[settingName]
            if legacyValue ~= nil then
                local sanitizer = DISPLAY_SETTING_SANITIZERS[settingName]
                local sanitized = sanitizer and sanitizer(legacyValue) or legacyValue
                for _, mode in ipairs(DISPLAY_MODES) do
                    local key = keyMap[mode]
                    if db[key] == nil then
                        db[key] = sanitized
                    end
                end
                db[settingName] = nil
            end
        end

        if db.orbOffsetX == nil and db.radialOffsetX ~= nil then
            db.orbOffsetX = SanitizeOffset(db.radialOffsetX)
        end
        if db.orbOffsetY == nil and db.radialOffsetY ~= nil then
            db.orbOffsetY = SanitizeOffset(db.radialOffsetY)
        end
    end

    for key, defaultValue in pairs(DEFAULTS) do
        local sanitizer = SANITIZERS[key]
        if sanitizer then
            db[key] = sanitizer(db[key])
        else
            db[key] = db[key] == nil and defaultValue or db[key]
        end
    end

    db.schemaVersion = SCHEMA_VERSION
end

function ns.Settings:Initialize()
    local accountDB = _G[DB_NAME]
    if type(accountDB) ~= "table" then
        accountDB = {}
        _G[DB_NAME] = accountDB
    end
    ApplyDefaults(accountDB)
    self.accountDB = accountDB

    local charDB = _G[CHAR_DB_NAME]
    if type(charDB) ~= "table" then
        charDB = {}
        _G[CHAR_DB_NAME] = charDB
    end
    ApplyDefaults(charDB)
    self.charDB = charDB

    if accountDB.useCharacterProfile then
        self.db = charDB
    else
        self.db = accountDB
    end

    return self.db
end

function ns.Settings:GetDB()
    return self.db or self:Initialize()
end

function ns.Settings:GetAccountDB()
    return self.accountDB or _G[DB_NAME]
end

function ns.Settings:GetValue(key)
    local db = self:GetDB()
    if DEFAULTS[key] == nil then
        return nil
    end
    return db[key]
end

function ns.Settings:SetValue(key, value)
    local sanitizer = SANITIZERS[key]
    if not sanitizer then
        return nil
    end

    local db = self:GetDB()
    db[key] = sanitizer(value)
    return db[key]
end

function ns.Settings:ResetToDefaults()
    local db = self:GetDB()
    local preserveCharProfile = self:ShouldUseCharacterProfile()

    for key, defaultValue in pairs(DEFAULTS) do
        db[key] = defaultValue
    end

    db.offsetX = nil
    db.offsetY = nil
    for _, key in ipairs(LEGACY_DISPLAY_SETTING_KEYS) do
        db[key] = nil
    end

    local accountDB = self:GetAccountDB()
    if type(accountDB) == "table" then
        accountDB.useCharacterProfile = preserveCharProfile
    end
end

function ns.Settings:IsEnabled()
    return self:GetValue("enabled") ~= false
end

function ns.Settings:SetEnabled(enabled)
    return self:SetValue("enabled", enabled)
end

function ns.Settings:ToggleEnabled()
    return self:SetEnabled(not self:IsEnabled())
end

function ns.Settings:GetDisplayMode()
    return self:GetValue("displayMode") or DEFAULTS.displayMode
end

function ns.Settings:SetDisplayMode(mode)
    return self:SetValue("displayMode", mode)
end

function ns.Settings:GetDisplaySettingValue(settingName, mode)
    local key = GetDisplaySettingKey(settingName, mode or self:GetDisplayMode())
    if not key then
        return nil
    end

    return self:GetValue(key)
end

function ns.Settings:SetDisplaySettingValue(settingName, value, mode)
    local key = GetDisplaySettingKey(settingName, mode or self:GetDisplayMode())
    if not key then
        return nil
    end

    return self:SetValue(key, value)
end

function ns.Settings:ShouldHideBlizzardWidget(mode)
    return self:GetDisplaySettingValue("hideBlizzardWidget", mode) == true
end

function ns.Settings:SetHideBlizzardWidget(enabled, mode)
    return self:SetDisplaySettingValue("hideBlizzardWidget", enabled, mode)
end

function ns.Settings:ShouldShowValueText(mode)
    return self:GetDisplaySettingValue("showValueText", mode) ~= false
end

function ns.Settings:SetShowValueText(enabled, mode)
    return self:SetDisplaySettingValue("showValueText", enabled, mode)
end

function ns.Settings:ShouldShowStageBadge(mode)
    return self:GetDisplaySettingValue("showStageBadge", mode) ~= false
end

function ns.Settings:SetShowStageBadge(enabled, mode)
    return self:SetDisplaySettingValue("showStageBadge", enabled, mode)
end

function ns.Settings:GetScale(mode)
    local key = GetDisplaySettingKey("scale", mode or self:GetDisplayMode())
    return self:GetValue(key) or DEFAULTS[key]
end

function ns.Settings:SetScale(value, mode)
    return self:SetDisplaySettingValue("scale", value, mode)
end

function ns.Settings:GetPlacementMode(mode)
    local key = GetDisplaySettingKey("placementMode", mode or self:GetDisplayMode())
    return self:GetValue(key) or DEFAULTS[key]
end

function ns.Settings:SetPlacementMode(value, mode)
    return self:SetDisplaySettingValue("placementMode", value, mode)
end

function ns.Settings:IsDetached(mode)
    return self:GetPlacementMode(mode) == PLACEMENT_MODE_DETACHED
end

function ns.Settings:SetDetached(enabled, mode)
    return self:SetPlacementMode(enabled and PLACEMENT_MODE_DETACHED or PLACEMENT_MODE_ATTACHED, mode)
end

function ns.Settings:IsDetachedPositionLocked(mode)
    return self:GetDisplaySettingValue("lockDetachedPosition", mode) ~= false
end

function ns.Settings:SetDetachedPositionLocked(locked, mode)
    return self:SetDisplaySettingValue("lockDetachedPosition", locked, mode)
end

function ns.Settings:GetOffsetX(mode)
    local key = GetOffsetKey("X", mode or self:GetDisplayMode())
    return self:GetValue(key) or DEFAULTS[key]
end

function ns.Settings:SetOffsetX(value, mode)
    return self:SetValue(GetOffsetKey("X", mode or self:GetDisplayMode()), value)
end

function ns.Settings:GetOffsetY(mode)
    local key = GetOffsetKey("Y", mode or self:GetDisplayMode())
    return self:GetValue(key) or DEFAULTS[key]
end

function ns.Settings:SetOffsetY(value, mode)
    return self:SetValue(GetOffsetKey("Y", mode or self:GetDisplayMode()), value)
end

function ns.Settings:GetDetachedX(mode)
    local key = GetDetachedKey("X", mode or self:GetDisplayMode())
    return self:GetValue(key) or DEFAULTS[key]
end

function ns.Settings:SetDetachedX(value, mode)
    return self:SetValue(GetDetachedKey("X", mode or self:GetDisplayMode()), value)
end

function ns.Settings:GetDetachedY(mode)
    local key = GetDetachedKey("Y", mode or self:GetDisplayMode())
    return self:GetValue(key) or DEFAULTS[key]
end

function ns.Settings:SetDetachedY(value, mode)
    return self:SetValue(GetDetachedKey("Y", mode or self:GetDisplayMode()), value)
end

function ns.Settings:ResetDetachedPosition(mode)
    self:SetDetachedX(0, mode)
    self:SetDetachedY(0, mode)
end

function ns.Settings:ShouldAutoWatchPreyQuest()
    return self:GetValue("autoWatchPreyQuest") == true
end

function ns.Settings:SetAutoWatchPreyQuest(enabled)
    return self:SetValue("autoWatchPreyQuest", enabled)
end

function ns.Settings:ShouldAutoSuperTrackPreyQuest()
    return self:GetValue("autoSuperTrackPreyQuest") == true
end

function ns.Settings:SetAutoSuperTrackPreyQuest(enabled)
    return self:SetValue("autoSuperTrackPreyQuest", enabled)
end

function ns.Settings:ShouldPlaySoundOnPhaseChange()
    return self:GetValue("playSoundOnPhaseChange") == true
end

function ns.Settings:SetPlaySoundOnPhaseChange(enabled)
    return self:SetValue("playSoundOnPhaseChange", enabled)
end

function ns.Settings:ShouldSnapToGrid()
    return self:GetValue("snapToGrid") == true
end

function ns.Settings:SetSnapToGrid(enabled)
    return self:SetValue("snapToGrid", enabled)
end

function ns.Settings:GetGridSize()
    return self:GetValue("gridSize") or 8
end

function ns.Settings:SetGridSize(value)
    return self:SetValue("gridSize", value)
end

function ns.Settings:GetTextFontFace()
    return self:GetValue("textFontFace") or DEFAULT_TEXT_FONT_VALUE
end

function ns.Settings:SetTextFontFace(value)
    return self:SetValue("textFontFace", value)
end

function ns.Settings:GetTextOutlineMode()
    return self:GetValue("textOutlineMode") or "default"
end

function ns.Settings:SetTextOutlineMode(value)
    return self:SetValue("textOutlineMode", value)
end

function ns.Settings:GetTextShadowMode()
    return self:GetValue("textShadowMode") or "default"
end

function ns.Settings:SetTextShadowMode(value)
    return self:SetValue("textShadowMode", value)
end

function ns.Settings:GetValueTextScale()
    return self:GetValue("valueTextScale") or 1
end

function ns.Settings:SetValueTextScale(value)
    return self:SetValue("valueTextScale", value)
end

function ns.Settings:GetStageTextScale()
    return self:GetValue("stageTextScale") or 1
end

function ns.Settings:SetStageTextScale(value)
    return self:SetValue("stageTextScale", value)
end

function ns.Settings:ShouldUseCharacterProfile()
    local accountDB = self:GetAccountDB()
    if type(accountDB) ~= "table" then
        return false
    end
    return accountDB.useCharacterProfile == true
end

function ns.Settings:SetUseCharacterProfile(enabled)
    local accountDB = self:GetAccountDB()
    if type(accountDB) ~= "table" then
        return
    end

    accountDB.useCharacterProfile = SanitizeBoolean(enabled, false)

    if enabled then
        self.db = self.charDB or _G[CHAR_DB_NAME]
    else
        self.db = accountDB
    end
end

local COLOR_STATE_KEYS = {
    [0] = "cold",
    [1] = "warm",
    [2] = "hot",
    [3] = "final",
}

-- Re-key by enum name if available.
do
    local preyState = Enum and Enum.PreyHuntProgressState
    if preyState then
        COLOR_STATE_KEYS[preyState.Cold] = "cold"
        COLOR_STATE_KEYS[preyState.Warm] = "warm"
        COLOR_STATE_KEYS[preyState.Hot] = "hot"
        COLOR_STATE_KEYS[preyState.Final] = "final"
    end
end

function ns.Settings:GetPhaseColor(state)
    local prefix = COLOR_STATE_KEYS[state]
    if not prefix then
        return nil
    end

    local db = self:GetDB()
    local r = db[prefix .. "ColorR"]
    local g = db[prefix .. "ColorG"]
    local b = db[prefix .. "ColorB"]

    if r and g and b then
        return { r, g, b }
    end

    return nil
end

function ns.Settings:SetPhaseColor(state, r, g, b)
    local prefix = COLOR_STATE_KEYS[state]
    if not prefix then
        return
    end

    self:SetValue(prefix .. "ColorR", r)
    self:SetValue(prefix .. "ColorG", g)
    self:SetValue(prefix .. "ColorB", b)
end

function ns.Settings:ResetPhaseColor(state)
    local prefix = COLOR_STATE_KEYS[state]
    if not prefix then
        return
    end

    local db = self:GetDB()
    db[prefix .. "ColorR"] = nil
    db[prefix .. "ColorG"] = nil
    db[prefix .. "ColorB"] = nil
end

function ns.Settings:GetEffectiveColor(state)
    return self:GetPhaseColor(state) or ns.Constants.ColorByState[state] or { 1, 1, 1 }
end
