-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- NOTE: Sanitizer functions reference ns.Util which loads after this file.
-- They are never called at load time; only from Initialize() onwards.

local _, ns = ...

local DB_NAME = "PreybreakerDB"
local CHAR_DB_NAME = "PreybreakerCharDB"
local DISPLAY_MODE_RADIAL = "radial"
local DISPLAY_MODE_ORBS = "orbs"
local DISPLAY_MODE_BAR = "bar"
local DISPLAY_MODE_TEXT = "text"
-- Schema version history:
-- v1: original layout with offsetX/offsetY
-- v2: per-mode offsets, MigrateLegacyOffsets
-- v3: flattened per-mode settings, MigrateV2PerModeSettings
-- v4, v5: additive only — new defaults, no migration needed
local SCHEMA_VERSION = 5
local DEFAULT_SCALE = 1
local DEFAULT_TEXT_FONT_VALUE = (ns.TextStyle and ns.TextStyle:GetDefaultFontValue()) or "builtin:standard"
local DEFAULTS = {
    schemaVersion = SCHEMA_VERSION,
    enabled = true,
    displayMode = DISPLAY_MODE_RADIAL,
    hideBlizzardWidget = false,
    showValueText = true,
    showStageBadge = true,
    scale = DEFAULT_SCALE,
    radialOffsetX = 0,
    radialOffsetY = 0,
    orbOffsetX = 0,
    orbOffsetY = 0,
    barOffsetX = 0,
    barOffsetY = 0,
    textOffsetX = 0,
    textOffsetY = 0,
    autoWatchPreyQuest = false,
    autoSuperTrackPreyQuest = false,
    autoTurnInPreyQuest = false,
    useCharacterProfile = false,
    textFontFace = DEFAULT_TEXT_FONT_VALUE,
    textOutlineMode = "default",
    textShadowMode = "default",
    valueTextScale = 1,
    stageTextScale = 1,
    autoPurchaseRandomHunt = false,
    randomHuntDifficulty = "normal",
    remnantThreshold = 0,
    autoSelectHuntReward = false,
    preferredHuntReward = "remnant",
    fallbackHuntReward = "gold",
    settingsTab = "settings",
    enableHuntPanel = true,
    huntPanelStandalone = false,
    huntPanelFilter = "all",
    huntPanelOffsetX = 0,
    huntPanelOffsetY = 0,
}

local SCALE_MIN = 0.50
local SCALE_MAX = 2.00
local SCALE_STEP = 0.05
local TEXT_SCALE_MIN = 0.75
local TEXT_SCALE_MAX = 1.75
local TEXT_SCALE_STEP = 0.05
local OFFSET_MIN = -200
local OFFSET_MAX = 200
local PANEL_OFFSET_MIN = -1200
local PANEL_OFFSET_MAX = 1200

local THRESHOLD_MIN = 0
local THRESHOLD_MAX = 2500
local THRESHOLD_STEP = 50

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

local function SanitizeScale(value)
    local clamped = ClampNumber(value, SCALE_MIN, SCALE_MAX, DEFAULT_SCALE)
    local steps = ns.Util.RoundNearest((clamped - SCALE_MIN) / SCALE_STEP)
    local snapped = SCALE_MIN + (steps * SCALE_STEP)
    return ClampNumber(snapped, SCALE_MIN, SCALE_MAX, DEFAULT_SCALE)
end

local function SanitizeOffset(value)
    return ns.Util.RoundNearest(ClampNumber(value, OFFSET_MIN, OFFSET_MAX, 0))
end

local function SanitizePanelOffset(value)
    return ns.Util.RoundNearest(ClampNumber(value, PANEL_OFFSET_MIN, PANEL_OFFSET_MAX, 0))
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

local function SanitizeRemnantThreshold(value)
    local clamped = ClampNumber(value, THRESHOLD_MIN, THRESHOLD_MAX, 0)
    local steps = ns.Util.RoundNearest((clamped - THRESHOLD_MIN) / THRESHOLD_STEP)
    local snapped = THRESHOLD_MIN + (steps * THRESHOLD_STEP)
    return ClampNumber(snapped, THRESHOLD_MIN, THRESHOLD_MAX, 0)
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

local SANITIZERS = {
    schemaVersion = function() return SCHEMA_VERSION end,
    enabled = function(value) return SanitizeBoolean(value, DEFAULTS.enabled) end,
    displayMode = SanitizeDisplayMode,
    hideBlizzardWidget = function(value) return SanitizeBoolean(value, false) end,
    showValueText = function(value) return SanitizeBoolean(value, true) end,
    showStageBadge = function(value) return SanitizeBoolean(value, true) end,
    scale = SanitizeScale,
    radialOffsetX = SanitizeOffset,
    radialOffsetY = SanitizeOffset,
    orbOffsetX = SanitizeOffset,
    orbOffsetY = SanitizeOffset,
    barOffsetX = SanitizeOffset,
    barOffsetY = SanitizeOffset,
    textOffsetX = SanitizeOffset,
    textOffsetY = SanitizeOffset,
    autoWatchPreyQuest = function(value) return SanitizeBoolean(value, false) end,
    autoSuperTrackPreyQuest = function(value) return SanitizeBoolean(value, false) end,
    autoTurnInPreyQuest = function(value) return SanitizeBoolean(value, false) end,
    useCharacterProfile = function(value) return SanitizeBoolean(value, false) end,
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
    autoPurchaseRandomHunt = function(value) return SanitizeBoolean(value, false) end,
    randomHuntDifficulty = function(value)
        return SanitizeChoice(value, { "normal", "hard", "nightmare" }, "normal")
    end,
    remnantThreshold = SanitizeRemnantThreshold,
    autoSelectHuntReward = function(value) return SanitizeBoolean(value, false) end,
    preferredHuntReward = function(value)
        return SanitizeChoice(value, { "dawncrest", "remnant", "gold", "marl" }, "remnant")
    end,
    fallbackHuntReward = function(value)
        return SanitizeChoice(value, { "dawncrest", "remnant", "gold", "marl" }, "gold")
    end,
    settingsTab = function(value)
        return SanitizeChoice(value, { "settings", "changelog", "social", "roadmap" }, "settings")
    end,
    enableHuntPanel = function(value) return SanitizeBoolean(value, true) end,
    huntPanelStandalone = function(value)
        return SanitizeBoolean(value, false)
    end,
    huntPanelFilter = function(value)
        return SanitizeChoice(value, { "all", "nightmare", "hard", "normal" }, "all")
    end,
    huntPanelOffsetX = SanitizePanelOffset,
    huntPanelOffsetY = SanitizePanelOffset,
}

-- v2 per-display-mode keys that were flattened in schema version 3.
local V2_MODE_PREFIXES = { "radial", "orb", "bar", "text" }
local V2_FLATTENED_SUFFIXES = {
    "HideBlizzardWidget",
    "ShowValueText",
    "ShowStageBadge",
    "Scale",
}
local V2_FLAT_KEYS = {
    HideBlizzardWidget = "hideBlizzardWidget",
    ShowValueText = "showValueText",
    ShowStageBadge = "showStageBadge",
    Scale = "scale",
}

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

    -- Seed orb offsets from the newly migrated radial offsets.
    if db.orbOffsetX == nil and db.radialOffsetX ~= nil then
        db.orbOffsetX = SanitizeOffset(db.radialOffsetX)
    end
    if db.orbOffsetY == nil and db.radialOffsetY ~= nil then
        db.orbOffsetY = SanitizeOffset(db.radialOffsetY)
    end

    db.offsetX = nil
    db.offsetY = nil
end

local function MigrateV2PerModeSettings(db)
    local sourceMode = SanitizeDisplayMode(db.displayMode)
    local sourcePrefix
    if sourceMode == "orbs" then
        sourcePrefix = "orb"
    elseif sourceMode == "bar" then
        sourcePrefix = "bar"
    elseif sourceMode == "text" then
        sourcePrefix = "text"
    else
        sourcePrefix = "radial"
    end

    for _, suffix in ipairs(V2_FLATTENED_SUFFIXES) do
        local flatKey = V2_FLAT_KEYS[suffix]
        local sourceKey = sourcePrefix .. suffix

        if db[sourceKey] ~= nil and db[flatKey] == nil then
            db[flatKey] = db[sourceKey]
        end

        for _, prefix in ipairs(V2_MODE_PREFIXES) do
            db[prefix .. suffix] = nil
        end
    end
end

local function HasCustomProfileValues(db)
    if type(db) ~= "table" then
        return false
    end

    for key, defaultValue in pairs(DEFAULTS) do
        if key ~= "schemaVersion" and key ~= "useCharacterProfile" and db[key] ~= defaultValue then
            return true
        end
    end

    return false
end

local function CopyProfileValues(sourceDB, destinationDB)
    if type(sourceDB) ~= "table" or type(destinationDB) ~= "table" then
        return
    end

    for key in pairs(DEFAULTS) do
        if key ~= "useCharacterProfile" then
            destinationDB[key] = sourceDB[key]
        end
    end
end

local function ApplyDefaults(db)
    local existingVersion = tonumber(db.schemaVersion) or 1

    if existingVersion < 2 then
        MigrateLegacyOffsets(db)
    end

    if existingVersion < 3 then
        MigrateV2PerModeSettings(db)
    end

    for key, defaultValue in pairs(DEFAULTS) do
        local sanitizer = SANITIZERS[key]
        if sanitizer then
            db[key] = sanitizer(db[key])
        else
            db[key] = db[key] == nil and defaultValue or db[key]
        end
    end

    db.playSoundOnPhaseChange = nil
    db.soundTheme = nil
    db.enableDeathSounds = nil

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

function ns.Settings:GetCharDB()
    return self.charDB or _G[CHAR_DB_NAME]
end

function ns.Settings:GetCharacterHuntQuestCache()
    local charDB = self:GetCharDB()
    if type(charDB) ~= "table" then
        return nil
    end

    if type(charDB.huntQuestCache) ~= "table" then
        charDB.huntQuestCache = {}
    end

    return charDB.huntQuestCache
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

function ns.Settings:ShouldHideBlizzardWidget()
    return self:GetValue("hideBlizzardWidget") == true
end

function ns.Settings:SetHideBlizzardWidget(enabled)
    return self:SetValue("hideBlizzardWidget", enabled)
end

function ns.Settings:ShouldShowValueText()
    return self:GetValue("showValueText") ~= false
end

function ns.Settings:SetShowValueText(enabled)
    return self:SetValue("showValueText", enabled)
end

function ns.Settings:ShouldShowStageBadge()
    return self:GetValue("showStageBadge") ~= false
end

function ns.Settings:SetShowStageBadge(enabled)
    return self:SetValue("showStageBadge", enabled)
end

function ns.Settings:GetScale()
    return self:GetValue("scale") or DEFAULT_SCALE
end

function ns.Settings:SetScale(value)
    return self:SetValue("scale", value)
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

function ns.Settings:ShouldAutoTurnInPreyQuest()
    return self:GetValue("autoTurnInPreyQuest") == true
end

function ns.Settings:SetAutoTurnInPreyQuest(enabled)
    return self:SetValue("autoTurnInPreyQuest", enabled)
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

    enabled = SanitizeBoolean(enabled, false)
    accountDB.useCharacterProfile = enabled

    if enabled then
        local charDB = self.charDB or _G[CHAR_DB_NAME]
        if type(charDB) == "table" then
            if charDB._profileSeededFromAccount ~= true then
                if not HasCustomProfileValues(charDB) then
                    CopyProfileValues(accountDB, charDB)
                end
                charDB._profileSeededFromAccount = true
            end

            self.charDB = charDB
            self.db = charDB
        end
    else
        self.db = accountDB
    end
end

function ns.Settings:ShouldAutoPurchaseRandomHunt()
    return self:GetValue("autoPurchaseRandomHunt") == true
end

function ns.Settings:SetAutoPurchaseRandomHunt(enabled)
    return self:SetValue("autoPurchaseRandomHunt", enabled)
end

function ns.Settings:GetRandomHuntDifficulty()
    return self:GetValue("randomHuntDifficulty") or "normal"
end

function ns.Settings:SetRandomHuntDifficulty(value)
    return self:SetValue("randomHuntDifficulty", value)
end

function ns.Settings:GetRemnantThreshold()
    return self:GetValue("remnantThreshold") or 0
end

function ns.Settings:SetRemnantThreshold(value)
    return self:SetValue("remnantThreshold", value)
end

function ns.Settings:ShouldAutoSelectHuntReward()
    return self:GetValue("autoSelectHuntReward") == true
end

function ns.Settings:SetAutoSelectHuntReward(enabled)
    return self:SetValue("autoSelectHuntReward", enabled)
end

function ns.Settings:GetPreferredHuntReward()
    return self:GetValue("preferredHuntReward") or "remnant"
end

function ns.Settings:SetPreferredHuntReward(value)
    return self:SetValue("preferredHuntReward", value)
end

function ns.Settings:GetFallbackHuntReward()
    return self:GetValue("fallbackHuntReward") or "gold"
end

function ns.Settings:SetFallbackHuntReward(value)
    return self:SetValue("fallbackHuntReward", value)
end

function ns.Settings:GetEffectiveColor(state)
    return ns.Constants.ColorByState[state] or { 1, 1, 1 }
end

function ns.Settings:GetSettingsTab()
    return self:GetValue("settingsTab") or "settings"
end

function ns.Settings:SetSettingsTab(value)
    return self:SetValue("settingsTab", value)
end

function ns.Settings:IsHuntPanelEnabled()
    return self:GetValue("enableHuntPanel") ~= false
end

function ns.Settings:SetHuntPanelEnabled(enabled)
    return self:SetValue("enableHuntPanel", enabled)
end

function ns.Settings:IsHuntPanelStandalone()
    return self:GetValue("huntPanelStandalone") == true
end

function ns.Settings:SetHuntPanelStandalone(value)
    return self:SetValue("huntPanelStandalone", value)
end

function ns.Settings:GetHuntPanelFilter()
    return self:GetValue("huntPanelFilter") or "all"
end

function ns.Settings:SetHuntPanelFilter(value)
    return self:SetValue("huntPanelFilter", value)
end

function ns.Settings:GetHuntPanelOffsetX()
    return self:GetValue("huntPanelOffsetX") or 0
end

function ns.Settings:SetHuntPanelOffsetX(value)
    return self:SetValue("huntPanelOffsetX", value)
end

function ns.Settings:GetHuntPanelOffsetY()
    return self:GetValue("huntPanelOffsetY") or 0
end

function ns.Settings:SetHuntPanelOffsetY(value)
    return self:SetValue("huntPanelOffsetY", value)
end
