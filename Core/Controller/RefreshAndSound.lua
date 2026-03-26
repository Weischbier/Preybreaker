-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
local Preybreaker = ns.Controller

-- Frame reference compat alias (see Constants.FrameRef).
local FR = ns.Constants and ns.Constants.FrameRef or {}
local MISSION_FRAME_NAME = FR.MissionFrame or "CovenantMissionFrame"

local function ShouldPlayHuntSounds()
    return ns.Settings
        and ns.Settings:ShouldPlaySoundOnPhaseChange()
        and type(PlaySoundFile) == "function"
end

local function PlayConfiguredSound(soundPath)
    if type(soundPath) ~= "string" or soundPath == "" then
        return
    end

    PlaySoundFile(soundPath, "Master")
end

-- ResolveSoundPath: legacy fallback for static Media.Sounds paths.
-- Prefer ResolveThemedSoundPath for all new sound cue resolution.
local function ResolveSoundPath(sounds, ...)
    if type(sounds) ~= "table" then
        return nil
    end

    for index = 1, select("#", ...) do
        local key = select(index, ...)
        local value = key and sounds[key] or nil
        if type(value) == "string" and value ~= "" then
            return value
        end
    end

    return nil
end

local function ResolveSessionQuestID(snapshot)
    if type(snapshot) ~= "table" then
        return nil
    end

    local questID = snapshot.questID or snapshot.activeQuestID or snapshot.worldQuestID
    if type(questID) ~= "number" then
        return nil
    end

    return questID
end

local function IsHuntSessionActive(snapshot)
    local questID = ResolveSessionQuestID(snapshot)
    if not questID then
        return false
    end

    if ns.Util and type(ns.Util.IsRelevantPreyQuest) == "function" then
        return ns.Util.IsRelevantPreyQuest(questID)
    end

    return true
end

local function GetNowSeconds()
    if type(GetTimePreciseSec) == "function" then
        return GetTimePreciseSec()
    end

    if type(GetTime) == "function" then
        return GetTime()
    end

    return 0
end

local function IsPlayerDeadOrGhostSafe()
    if type(UnitIsDeadOrGhost) == "function" then
        return UnitIsDeadOrGhost("player") == true
    end

    if type(UnitIsDead) == "function" then
        return UnitIsDead("player") == true
    end

    return false
end

function Preybreaker:GetSoundState()
    if not self.soundState then
        self.soundState = {
            preyNameMatches = {},
            relevantQuestIDs = {},
            preyCandidateGUIDs = {},
            preyCandidateNPCIDs = {},
            recentHostileGUIDs = {},
            recentHostileNames = {},
            recentAbandonedQuestIDs = {},
            lastTrapContextAt = nil,
            lastTrapContextName = nil,
            lastTrapContextSource = nil,
            ambushCandidateWindowEndsAt = nil,
            lastAmbushSource = nil,
            lastAmbushAt = nil,
            lastKilledGUID = nil,
            lastPreyKilledAt = nil,
            lastAnySoundAt = nil,
            lastPlayedSoundPath = nil,
            lastPreyCombatAt = nil,
            lastHuntStartAt = nil,
            lastHuntEndAt = nil,
            lastStageProgressAt = nil,
            lastSpellRiposteAt = nil,
            lastInteractionAt = nil,
            lastDeathCueAt = nil,
            cachedMatchQuestID = nil,
            activeSoundTheme = nil,
            soundVariantPools = nil,
            lastPlayedVariantByKey = {},
            deathCueArmed = false,
        }
    end

    return self.soundState
end

local PREY_STATE = Enum and Enum.PreyHuntProgressState
local PREY_STATE_COLD = (PREY_STATE and PREY_STATE.Cold) or 0
local PREY_STATE_WARM = (PREY_STATE and PREY_STATE.Warm) or 1
local PREY_STATE_HOT = (PREY_STATE and PREY_STATE.Hot) or 2
local PREY_STATE_FINAL = (PREY_STATE and PREY_STATE.Final) or 3
local RECENT_HOSTILE_EXPIRY_SECONDS = 8
local AMBUSH_CANDIDATE_WINDOW_SECONDS = 2
local AMBUSH_PREY_CAPTURE_WINDOW_SECONDS = 15
local TRAP_CONTEXT_WINDOW_SECONDS = 4
local ABANDON_SUPPRESSION_SECONDS = 15
local DEFAULT_SOUND_THEME = "AmongUs"
local GENERIC_SOUND_THEME = "Generic"
local RANDOM_SOUND_THEME = "Random"
local BONUS_VARIANT_CHANCE = 0.05
local SOUND_PATH_ROOT = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\"
local MAX_MAP_PARENT_DEPTH = 16
local IsLikelyTrapUnitName
local AmbushMessageCache = {}
local SOUND_KEY_ALIASES = {
    hunt_start = { "hunt_start", "harandir_enter" },
    hunt_end = { "hunt_end" },
    ambush = { "ambush" },
    riposte = { "riposte" },
    interaction = { "interaction" },
    progress = { "progress", "interaction" },
    prey_combat = { "prey_combat", "ambush" },
    kill = { "kill" },
    death = { "death" },
}
local KNOWN_TRAP_NAME_FRAGMENTS = {
    ["thorny trap"] = true,
}
local ROGUE_AMBUSH_SPELL_ID = 8676
local AMBUSH_CHAT_BY_LOCALE = {
    enUS = { "Ambush!" },
    deDE = { "Hinterhalt!" },
    esES = { "¡Emboscada!" },
    esMX = { "¡Emboscada!" },
    frFR = { "C’est une embuscade !", "C'est une embuscade !" },
    itIT = { "Imboscata!" },
    koKR = { "기습이다!" },
    ptBR = { "Emboscada!" },
    ruRU = { "Нападение!" },
    zhCN = { "有埋伏！", "有埋伏!" },
    zhTW = { "突襲！", "突襲!" },
}

local ExtractNPCIDFromGUID = ns.Util.ExtractNPCIDFromGUID

local function IsHostileUnitToken(unitToken)
    if type(unitToken) ~= "string" then
        return false
    end

    if type(UnitExists) == "function" and not UnitExists(unitToken) then
        return false
    end

    if type(UnitIsPlayer) == "function" and UnitIsPlayer(unitToken) then
        return false
    end

    if type(UnitCanAttack) == "function" and UnitCanAttack("player", unitToken) then
        return true
    end

    if type(UnitReaction) == "function" then
        local reaction = UnitReaction(unitToken, "player")
        if type(reaction) == "number" and reaction <= 4 then
            return true
        end
    end

    return false
end

local function IsUnitTargetOrMouseover(unitToken)
    if type(unitToken) ~= "string" or type(UnitIsUnit) ~= "function" then
        return false
    end

    return UnitIsUnit(unitToken, "target") or UnitIsUnit(unitToken, "mouseover")
end

local function IsUnitDead(unitToken)
    if type(unitToken) ~= "string" then
        return false
    end

    if type(UnitExists) == "function" and not UnitExists(unitToken) then
        return false
    end

    if type(UnitIsDeadOrGhost) == "function" and UnitIsDeadOrGhost(unitToken) then
        return true
    end

    if type(UnitIsDead) == "function" and UnitIsDead(unitToken) then
        return true
    end

    return false
end

function Preybreaker:ResetPreyCombatCandidates()
    local state = self:GetSoundState()
    state.preyCandidateGUIDs = {}
    state.preyCandidateNPCIDs = {}
    state.recentHostileGUIDs = {}
    state.recentHostileNames = {}
    state.recentAbandonedQuestIDs = {}
    state.lastTrapContextAt = nil
    state.lastTrapContextName = nil
    state.lastTrapContextSource = nil
    state.ambushCandidateWindowEndsAt = nil
    state.lastAmbushSource = nil
    state.lastAmbushAt = nil
    state.lastKilledGUID = nil
    state.lastPreyKilledAt = nil
    state.lastAnySoundAt = nil
    state.lastPreyCombatAt = nil
    state.lastDeathCueAt = nil
    state.deathCueArmed = false
end

function Preybreaker:PromotePreyCombatCandidate(guid)
    if type(guid) ~= "string" then
        return
    end

    local state = self:GetSoundState()
    state.preyCandidateGUIDs[guid] = true

    local npcID = ExtractNPCIDFromGUID(guid)
    if npcID then
        state.preyCandidateNPCIDs[npcID] = true
    end
end

function Preybreaker:RememberRecentHostileGUID(guid, name)
    if type(guid) ~= "string" then
        return
    end

    local state = self:GetSoundState()
    local names = state.recentHostileNames
    local now = GetNowSeconds()

    for knownGUID, seenAt in pairs(state.recentHostileGUIDs) do
        if type(seenAt) ~= "number" or (now - seenAt) > RECENT_HOSTILE_EXPIRY_SECONDS then
            state.recentHostileGUIDs[knownGUID] = nil
            names[knownGUID] = nil
        end
    end

    state.recentHostileGUIDs[guid] = now
    names[guid] = type(name) == "string" and name or nil
end

function Preybreaker:RememberRecentHostileUnit(unitToken)
    if not IsHostileUnitToken(unitToken) or type(UnitGUID) ~= "function" then
        return
    end

    local guid = UnitGUID(unitToken)
    if type(guid) == "string" then
        local name = type(UnitName) == "function" and UnitName(unitToken) or nil
        self:RememberRecentHostileGUID(guid, name)
    end
end

function Preybreaker:ArmAmbushCandidateWindow(seconds)
    if type(seconds) ~= "number" or seconds <= 0 then
        return
    end

    self:GetSoundState().ambushCandidateWindowEndsAt = GetNowSeconds() + seconds
end

function Preybreaker:IsAmbushCandidateWindowActive()
    local state = self:GetSoundState()
    local windowEndsAt = state.ambushCandidateWindowEndsAt
    if type(windowEndsAt) ~= "number" then
        return false
    end

    if GetNowSeconds() > windowEndsAt then
        state.ambushCandidateWindowEndsAt = nil
        return false
    end

    return true
end

function Preybreaker:PromoteUnitPreyCandidateIfHostile(unitToken)
    if type(unitToken) ~= "string" or type(UnitGUID) ~= "function" then
        return false
    end

    if not IsHostileUnitToken(unitToken) then
        return false
    end

    local guid = UnitGUID(unitToken)
    if type(guid) ~= "string" then
        return false
    end

    self:PromotePreyCombatCandidate(guid)
    return true
end

function Preybreaker:RememberTrapContext(name, source)
    if not IsLikelyTrapUnitName(name) then
        return false
    end

    local state = self:GetSoundState()
    state.lastTrapContextAt = GetNowSeconds()
    state.lastTrapContextName = name
    state.lastTrapContextSource = source
    return true
end

function Preybreaker:RememberTrapContextFromUnit(unitToken)
    if type(unitToken) ~= "string" or type(UnitName) ~= "function" then
        return false
    end

    if type(UnitExists) == "function" and not UnitExists(unitToken) then
        return false
    end

    return self:RememberTrapContext(UnitName(unitToken), unitToken)
end

function Preybreaker:HasRecentTrapContext(maxAgeSeconds)
    local state = self:GetSoundState()
    local seenAt = state.lastTrapContextAt
    if type(seenAt) ~= "number" then
        return false
    end

    local threshold = type(maxAgeSeconds) == "number" and maxAgeSeconds or TRAP_CONTEXT_WINDOW_SECONDS
    if threshold <= 0 then
        return true
    end

    if (GetNowSeconds() - seenAt) > threshold then
        state.lastTrapContextAt = nil
        state.lastTrapContextName = nil
        state.lastTrapContextSource = nil
        return false
    end

    return true
end

function Preybreaker:PromoteRecentHostileCandidate(maxAgeSeconds)
    local state = self:GetSoundState()
    local recent = state.recentHostileGUIDs
    local names = state.recentHostileNames
    if type(recent) ~= "table" then
        return
    end

    local now = GetNowSeconds()
    local newestGUID
    local newestAt

    for guid, seenAt in pairs(recent) do
        local age = now - (seenAt or 0)
        if type(seenAt) ~= "number" or age > RECENT_HOSTILE_EXPIRY_SECONDS then
            recent[guid] = nil
            names[guid] = nil
        elseif age <= maxAgeSeconds and (not newestAt or seenAt > newestAt) then
            local name = names[guid]
            if type(name) == "string" and self:IsLikelyPreyTargetName(name) then
                newestGUID = guid
                newestAt = seenAt
            end
        end
    end

    if newestGUID then
        self:PromotePreyCombatCandidate(newestGUID)
    end
end

local GLOBAL_SOUND_COOLDOWN_SECONDS = 0.4

local function PlaySoundCue(controller, soundPath, throttleKey, throttleSeconds)
    if not ShouldPlayHuntSounds() then
        return false
    end

    if type(soundPath) ~= "string" or soundPath == "" then
        return false
    end

    local state = controller:GetSoundState()
    local now = GetNowSeconds()

    -- Global cooldown: only one sound cue per short window.
    local lastAnySoundAt = state.lastAnySoundAt or 0
    if (now - lastAnySoundAt) < GLOBAL_SOUND_COOLDOWN_SECONDS then
        return false
    end

    if throttleKey and throttleSeconds and throttleSeconds > 0 then
        local previous = state[throttleKey] or 0
        if (now - previous) < throttleSeconds then
            return false
        end
        state[throttleKey] = now
    end

    state.lastAnySoundAt = now
    PlayConfiguredSound(soundPath)
    return true
end

local function BuildPackSoundPath(packName, fileName)
    if type(packName) ~= "string" or packName == "" or type(fileName) ~= "string" or fileName == "" then
        return nil
    end

    return SOUND_PATH_ROOT .. packName .. "\\" .. fileName
end

local function ParseCatalogSoundKey(fileName)
    if type(fileName) ~= "string" then
        return nil, false
    end

    local stem = fileName:gsub("%.ogg$", "")
    if stem == "" then
        return nil, false
    end

    local baseBonus = stem:match("^(.-)_bonus%d+$")
    if baseBonus and baseBonus ~= "" then
        return string.lower(baseBonus), true
    end

    local numberedBase = stem:match("^(.-)%d+$")
    if numberedBase and numberedBase ~= "" then
        return string.lower(numberedBase), false
    end

    return string.lower(stem), false
end

local function AddVariantEntry(targetByKey, key, soundPath)
    if type(targetByKey) ~= "table" or type(key) ~= "string" or type(soundPath) ~= "string" then
        return
    end

    local bucket = targetByKey[key]
    if type(bucket) ~= "table" then
        bucket = {}
        targetByKey[key] = bucket
    end
    bucket[#bucket + 1] = soundPath
end

local function AddCatalogPackVariants(regularByKey, bonusByKey, catalog, packName)
    if type(catalog) ~= "table" or type(packName) ~= "string" or packName == "" then
        return
    end

    local fileNames = catalog[packName]
    if type(fileNames) ~= "table" then
        return
    end

    for _, fileName in ipairs(fileNames) do
        local key, isBonus = ParseCatalogSoundKey(fileName)
        local soundPath = BuildPackSoundPath(packName, fileName)
        if key and soundPath then
            AddVariantEntry(isBonus and bonusByKey or regularByKey, key, soundPath)
        end
    end
end

local function GetRandomRoll()
    if type(math) ~= "table" or type(math.random) ~= "function" then
        return nil
    end

    local ok, value = pcall(math.random)
    if not ok or type(value) ~= "number" then
        return nil
    end

    return value
end

local function GetRandomIndex(maxCount)
    if type(maxCount) ~= "number" or maxCount <= 1 then
        return 1
    end

    if type(math) == "table" and type(math.random) == "function" then
        local ok, value = pcall(math.random, maxCount)
        if ok and type(value) == "number" then
            value = math.floor(value)
            if value >= 1 and value <= maxCount then
                return value
            end
        end
    end

    return 1
end

local function IsPlayerInSnapshotMap(snapshot)
    if type(snapshot) ~= "table" then
        return false
    end

    local huntMapID = snapshot.mapID
    if type(huntMapID) ~= "number" then
        return false
    end

    if type(C_Map) ~= "table" or type(C_Map.GetBestMapForUnit) ~= "function" then
        return false
    end

    local currentMapID = C_Map.GetBestMapForUnit("player")
    if type(currentMapID) ~= "number" then
        return false
    end

    if currentMapID == huntMapID then
        return true
    end

    if type(C_Map.GetMapInfo) ~= "function" then
        return false
    end

    for _ = 1, MAX_MAP_PARENT_DEPTH do
        local mapInfo = C_Map.GetMapInfo(currentMapID)
        local parentMapID = mapInfo and mapInfo.parentMapID or nil
        if type(parentMapID) ~= "number" or parentMapID <= 0 then
            return false
        end
        if parentMapID == huntMapID then
            return true
        end
        currentMapID = parentMapID
    end

    return false
end

local function TrimString(value)
    if type(value) ~= "string" then
        return nil
    end

    local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

local function NormalizeText(value)
    local trimmed = TrimString(value)
    if not trimmed then
        return nil
    end

    if type(strlower) == "function" then
        return strlower(trimmed)
    end

    return string.lower(trimmed)
end

local function NormalizeAmbushChatMessage(value)
    local trimmed = TrimString(value)
    if not trimmed then
        return nil
    end

    local normalized = trimmed
    normalized = normalized:gsub("\194\160", " ") -- UTF-8 NBSP
    normalized = normalized:gsub("\226\128\153", "'") -- UTF-8 right single quotation mark
    normalized = normalized:gsub("\239\188\129", "!") -- UTF-8 full-width exclamation mark
    normalized = normalized:gsub("%s+", " ")
    return NormalizeText(normalized) or normalized
end

local function AddAmbushToken(tokenSet, token)
    local normalized = NormalizeAmbushChatMessage(token)
    if normalized then
        tokenSet[normalized] = true
    end
end

local function BuildAmbushMessageSetForLocale(locale)
    local tokenSet = {}
    for _, token in ipairs(AMBUSH_CHAT_BY_LOCALE[locale] or {}) do
        AddAmbushToken(tokenSet, token)
    end

    local spellName = ns.Util.GetLocalizedSpellName(ROGUE_AMBUSH_SPELL_ID)
    if type(spellName) == "string" and spellName ~= "" then
        AddAmbushToken(tokenSet, spellName .. "!")
        AddAmbushToken(tokenSet, "¡" .. spellName .. "!")
        AddAmbushToken(tokenSet, spellName .. "！")
    end

    return tokenSet
end

local function GetAmbushMessageSet()
    local locale = type(GetLocale) == "function" and GetLocale() or "enUS"
    if type(locale) ~= "string" or locale == "" then
        locale = "enUS"
    end

    local spellName = ns.Util.GetLocalizedSpellName(ROGUE_AMBUSH_SPELL_ID) or ""
    if type(spellName) ~= "string" then
        spellName = ""
    end

    local cacheKey = locale .. "|" .. spellName
    local cached = AmbushMessageCache[cacheKey]
    if cached then
        return cached
    end

    local tokenSet = BuildAmbushMessageSetForLocale(locale)
    for _, token in ipairs(AMBUSH_CHAT_BY_LOCALE.enUS or {}) do
        AddAmbushToken(tokenSet, token)
    end

    AmbushMessageCache = { [cacheKey] = tokenSet }
    return tokenSet
end

IsLikelyTrapUnitName = function(name)
    local normalizedName = NormalizeText(name)
    if not normalizedName then
        return false
    end

    for fragment in pairs(KNOWN_TRAP_NAME_FRAGMENTS) do
        if normalizedName:find(fragment, 1, true) then
            return true
        end
    end

    return false
end

local function SafeGetQuestTitle(questID)
    if type(questID) ~= "number" then
        return nil
    end

    if type(C_QuestLog) ~= "table" or type(C_QuestLog.GetTitleForQuestID) ~= "function" then
        return nil
    end

    if ns.Util and type(ns.Util.SafeCall) == "function" then
        return ns.Util.SafeCall(C_QuestLog.GetTitleForQuestID, questID)
    end

    return C_QuestLog.GetTitleForQuestID(questID)
end

local function IsQuestCompletionFlagged(questID)
    if type(questID) ~= "number" then
        return false
    end

    if type(C_QuestLog) == "table" and type(C_QuestLog.IsQuestFlaggedCompleted) == "function" then
        if ns.Util and type(ns.Util.SafeCall) == "function" then
            return ns.Util.SafeCall(C_QuestLog.IsQuestFlaggedCompleted, questID) == true
        end

        local ok, result = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
        return ok and result == true
    end

    if type(IsQuestFlaggedCompleted) == "function" then
        if ns.Util and type(ns.Util.SafeCall) == "function" then
            return ns.Util.SafeCall(IsQuestFlaggedCompleted, questID) == true
        end

        local ok, result = pcall(IsQuestFlaggedCompleted, questID)
        return ok and result == true
    end

    return false
end

local function AddNormalizedCandidate(matchSet, candidate)
    local normalized = NormalizeText(candidate)
    if not normalized or #normalized < 4 then
        return
    end

    matchSet[normalized] = true
end

local function ExtractPreyNameFromQuestTitle(title)
    if type(title) ~= "string" or title == "" then
        return nil
    end

    local preyName = title:match(":%s*(.-)%s*%b()%s*$")
    if not preyName then
        preyName = title:match(":%s*(.+)$")
    end

    return TrimString(preyName)
end

local function AddQuestTitleMatches(matchSet, questID)
    local title = SafeGetQuestTitle(questID)
    if type(title) ~= "string" or title == "" then
        return
    end

    AddNormalizedCandidate(matchSet, title)

    local noParentheses = title:gsub("%s*%b()", "")
    AddNormalizedCandidate(matchSet, noParentheses)

    local _, colonEnd = title:find(":%s*")
    if colonEnd then
        local afterColon = title:sub(colonEnd + 1)
        AddNormalizedCandidate(matchSet, afterColon)
        AddNormalizedCandidate(matchSet, afterColon:gsub("%s*%b()", ""))
    end

    AddNormalizedCandidate(matchSet, ExtractPreyNameFromQuestTitle(title))
end

local function BuildQuestTitleMatchSet(snapshot)
    local matchSet = {}
    local relevantQuestIDs = {}

    local function AddQuestID(questID)
        if type(questID) ~= "number" or relevantQuestIDs[questID] then
            return
        end
        relevantQuestIDs[questID] = true
        AddQuestTitleMatches(matchSet, questID)
    end

    if type(snapshot) == "table" then
        AddQuestID(snapshot.questID)
        AddQuestID(snapshot.activeQuestID)
        AddQuestID(snapshot.worldQuestID)
    end

    if not next(relevantQuestIDs) and ns.Util and type(ns.Util.BuildPreyQuestContext) == "function" then
        local context = ns.Util.BuildPreyQuestContext()
        if type(context) == "table" then
            AddQuestID(context.trackedQuestID)
            AddQuestID(context.activeQuestID)
            AddQuestID(context.worldQuestID)
        end
    end

    return matchSet, relevantQuestIDs
end

local KnownPreyQuestLookup

local function BuildKnownPreyQuestLookup()
    local lookup = {}
    if not ns.HuntData then
        return lookup
    end

    for _, questID in ipairs(ns.HuntData.PreyWorldQuests or {}) do
        lookup[questID] = true
    end

    local byDifficulty = ns.HuntData.PreyTargetQuests or {}
    for _, questIDs in pairs(byDifficulty) do
        if type(questIDs) == "table" then
            for _, questID in ipairs(questIDs) do
                lookup[questID] = true
            end
        end
    end

    return lookup
end

local function IsKnownPreyQuestID(questID)
    if type(questID) ~= "number" then
        return false
    end

    if not KnownPreyQuestLookup then
        KnownPreyQuestLookup = BuildKnownPreyQuestLookup()
    end

    return KnownPreyQuestLookup[questID] == true
end

function Preybreaker:GetSelectedSoundTheme()
    local configuredTheme = ns.Settings and type(ns.Settings.GetSoundTheme) == "function" and ns.Settings:GetSoundTheme() or nil
    local media = ns.Constants and ns.Constants.Media or nil
    local catalog = media and media.SoundCatalog or nil

    if type(configuredTheme) == "string" and configuredTheme ~= "" and type(catalog) == "table" and type(catalog[configuredTheme]) == "table" then
        return configuredTheme
    end

    if type(catalog) == "table" and type(catalog[DEFAULT_SOUND_THEME]) == "table" then
        return DEFAULT_SOUND_THEME
    end

    return DEFAULT_SOUND_THEME
end

function Preybreaker:BuildSoundVariantPools(themeName)
    local media = ns.Constants and ns.Constants.Media or nil
    local catalog = media and media.SoundCatalog or nil
    local pools = {
        regular = {},
        bonus = {},
        fallbackRegular = {},
        fallbackBonus = {},
    }

    AddCatalogPackVariants(pools.regular, pools.bonus, catalog, themeName)

    if themeName ~= GENERIC_SOUND_THEME then
        AddCatalogPackVariants(pools.fallbackRegular, pools.fallbackBonus, catalog, GENERIC_SOUND_THEME)
    end

    local deathFiles = media and media.DeathSounds or nil
    if type(deathFiles) == "table" then
        for _, fileName in ipairs(deathFiles) do
            local deathPath = BuildPackSoundPath("Death", fileName)
            if deathPath then
                AddVariantEntry(pools.regular, "death", deathPath)
            end
        end
    end

    return pools
end

function Preybreaker:GetSoundVariantPools()
    local state = self:GetSoundState()
    local selectedTheme = self:GetSelectedSoundTheme()
    if type(state.soundVariantPools) == "table" and state.activeSoundTheme == selectedTheme then
        return state.soundVariantPools
    end

    state.soundVariantPools = self:BuildSoundVariantPools(selectedTheme)
    state.activeSoundTheme = selectedTheme
    state.lastPlayedVariantByKey = {}
    return state.soundVariantPools
end

-- Reusable scratch tables for PickSoundVariantPath to avoid per-call allocations.
local _recentlyPlayed = {}
local _candidates = {}

function Preybreaker:PickSoundVariantPath(variantKey, regularVariants, bonusVariants)
    local regularCount = type(regularVariants) == "table" and #regularVariants or 0
    local bonusCount = type(bonusVariants) == "table" and #bonusVariants or 0
    if regularCount <= 0 and bonusCount <= 0 then
        return nil
    end

    local variants = regularVariants
    if bonusCount > 0 then
        local useBonus = false
        if regularCount <= 0 then
            useBonus = true
        else
            local roll = GetRandomRoll()
            useBonus = type(roll) == "number" and roll <= BONUS_VARIANT_CHANCE
        end

        if useBonus then
            variants = bonusVariants
        end
    end

    if type(variants) ~= "table" or #variants <= 0 then
        variants = regularCount > 0 and regularVariants or bonusVariants
    end

    if type(variants) ~= "table" or #variants <= 0 then
        return nil
    end

    local state = self:GetSoundState()
    if type(state.lastPlayedVariantByKey) ~= "table" then
        state.lastPlayedVariantByKey = {}
    end

    local count = #variants
    if count == 1 then
        state.lastPlayedVariantByKey[variantKey] = variants[1]
        return variants[1]
    end

    -- Build a set of recently played paths to avoid (per-key + global last).
    wipe(_recentlyPlayed)
    local prevForKey = state.lastPlayedVariantByKey[variantKey]
    if prevForKey then
        _recentlyPlayed[prevForKey] = true
    end
    local globalPrev = state.lastPlayedSoundPath
    if globalPrev then
        _recentlyPlayed[globalPrev] = true
    end

    -- Collect candidates that haven't been played recently.
    wipe(_candidates)
    for i = 1, count do
        if not _recentlyPlayed[variants[i]] then
            _candidates[#_candidates + 1] = i
        end
    end

    -- If all variants were recently played, allow any except the per-key last.
    if #_candidates == 0 then
        for i = 1, count do
            if variants[i] ~= prevForKey then
                _candidates[#_candidates + 1] = i
            end
        end
    end

    -- Final fallback: pick any.
    if #_candidates == 0 then
        _candidates[1] = GetRandomIndex(count)
    end

    local picked = _candidates[GetRandomIndex(#_candidates)]
    local pickedPath = variants[picked]
    state.lastPlayedVariantByKey[variantKey] = pickedPath
    state.lastPlayedSoundPath = pickedPath
    return pickedPath
end

function Preybreaker:ResolveThemedSoundPath(soundKey, fallbackPath)
    if type(soundKey) ~= "string" or soundKey == "" then
        return fallbackPath
    end

    local normalizedKey = string.lower(soundKey)
    local aliasList = SOUND_KEY_ALIASES[normalizedKey] or { normalizedKey }
    local pools = self:GetSoundVariantPools()

    for _, alias in ipairs(aliasList) do
        local path = self:PickSoundVariantPath(alias, pools.regular[alias], pools.bonus[alias])
        if type(path) == "string" and path ~= "" then
            return path
        end
    end

    if normalizedKey ~= "death" then
        for _, alias in ipairs(aliasList) do
            local fallbackKey = alias .. "@fallback"
            local path = self:PickSoundVariantPath(fallbackKey, pools.fallbackRegular[alias], pools.fallbackBonus[alias])
            if type(path) == "string" and path ~= "" then
                return path
            end
        end

        if pools and pools.regular and self:GetSelectedSoundTheme() == RANDOM_SOUND_THEME then
            local randomPath = self:PickSoundVariantPath("random", pools.regular.random, pools.bonus.random)
            if type(randomPath) == "string" and randomPath ~= "" then
                return randomPath
            end
        end
    end

    return fallbackPath
end

local function PlayResolvedSoundCue(controller, soundKey, fallbackPath, throttleKey, throttleSeconds)
    local resolvedPath = controller:ResolveThemedSoundPath(soundKey, fallbackPath)
    return PlaySoundCue(controller, resolvedPath, throttleKey, throttleSeconds)
end

function Preybreaker:GetResolvedSoundPaths()
    local state = self:GetSoundState()
    if state.cachedResolvedPaths then
        return state.cachedResolvedPaths
    end

    local sounds = ns.Constants and ns.Constants.Media and ns.Constants.Media.Sounds
    local paths = {
        huntStart = ResolveSoundPath(sounds, "HuntStart"),
        huntEnd = ResolveSoundPath(sounds, "HuntEnd"),
        ambush = ResolveSoundPath(sounds, "Ambush", "ColdToWarm", "PhaseChange"),
        riposte = ResolveSoundPath(sounds, "Riposte", "WarmToHot", "PhaseChange"),
        finalPhase = ResolveSoundPath(sounds, "FinalPhase"),
        progress = ResolveSoundPath(sounds, "Progress", "PhaseChange", "Interaction"),
        interaction = ResolveSoundPath(sounds, "Interaction", "PhaseChange"),
        preyCombat = ResolveSoundPath(sounds, "Ambush", "ColdToWarm", "PhaseChange"),
        kill = ResolveSoundPath(sounds, "Kill"),
        death = ResolveSoundPath(sounds, "Death"),
    }
    state.cachedResolvedPaths = paths
    return paths
end

function Preybreaker:RefreshSoundContext(snapshot)
    local state = self:GetSoundState()
    local newQuestID = ResolveSessionQuestID(snapshot)
    if newQuestID and newQuestID == state.cachedMatchQuestID then
        return
    end
    local matchSet, relevantQuestIDs = BuildQuestTitleMatchSet(snapshot)
    state.preyNameMatches = matchSet
    state.relevantQuestIDs = relevantQuestIDs
    state.cachedMatchQuestID = newQuestID
end

function Preybreaker:IsRelevantQuestForSound(questID)
    if type(questID) ~= "number" then
        return false
    end

    if ns.Util and type(ns.Util.IsRelevantPreyQuest) == "function" and ns.Util.IsRelevantPreyQuest(questID) then
        return true
    end

    if IsKnownPreyQuestID(questID) then
        return true
    end

    local state = self:GetSoundState()
    return state.relevantQuestIDs and state.relevantQuestIDs[questID] == true
end

function Preybreaker:IsLikelyPreyTargetName(name)
    local normalizedName = NormalizeText(name)
    if not normalizedName then
        return false
    end

    local matchSet = self:GetSoundState().preyNameMatches
    if type(matchSet) ~= "table" then
        return false
    end

    if matchSet[normalizedName] then
        return true
    end

    return false
end

function Preybreaker:IsLikelyPreyTarget(guid, name)
    local state = self:GetSoundState()

    if type(guid) == "string" then
        if state.preyCandidateGUIDs[guid] then
            return true
        end

        local npcID = ExtractNPCIDFromGUID(guid)
        if npcID and state.preyCandidateNPCIDs[npcID] then
            return true
        end
    end

    return self:IsLikelyPreyTargetName(name)
end

function Preybreaker:IsConfirmedPreyTarget(guid, name)
    if type(guid) ~= "string" then
        return false
    end

    local state = self:GetSoundState()
    if state.preyCandidateGUIDs[guid] then
        return true
    end

    local npcID = ExtractNPCIDFromGUID(guid)
    if npcID and state.preyCandidateNPCIDs[npcID] then
        return true
    end

    local normalizedName = NormalizeText(name)
    if not normalizedName then
        return false
    end

    return state.preyNameMatches[normalizedName] == true
end

function Preybreaker:PromoteUnitPreyCandidateIfLikely(unitToken)
    if type(unitToken) ~= "string" or type(UnitGUID) ~= "function" then
        return false
    end

    if not IsHostileUnitToken(unitToken) then
        return false
    end

    local guid = UnitGUID(unitToken)
    if type(guid) ~= "string" then
        return false
    end

    local name = type(UnitName) == "function" and UnitName(unitToken) or nil
    if not name or not self:IsLikelyPreyTargetName(name) then
        return false
    end

    self:PromotePreyCombatCandidate(guid)
    return true
end

function Preybreaker:HandleNameplateUnitAddedForSounds(unitToken)
    if not ShouldPlayHuntSounds() or not IsHuntSessionActive(self.lastSnapshot) then
        return
    end

    self:RememberRecentHostileUnit(unitToken)
    self:RememberTrapContextFromUnit(unitToken)
    local promoted = self:PromoteUnitPreyCandidateIfLikely(unitToken)

    if self:IsAmbushCandidateWindowActive() and IsUnitTargetOrMouseover(unitToken) then
        self:PromoteUnitPreyCandidateIfHostile(unitToken)
    end

    -- Fire prey_combat when a likely prey target is first spotted in WARM+ state.
    if promoted then
        local snapshot = self.lastSnapshot
        local progressState = snapshot and snapshot.progressState or nil
        if type(progressState) == "number" and progressState >= PREY_STATE_WARM then
            local sounds = self:GetResolvedSoundPaths()
            PlayResolvedSoundCue(self, "prey_combat", sounds.ambush, "lastPreyCombatAt", 8)
        end
    end
end

function Preybreaker:HandleNameplateUnitRemovedForSounds(unitToken)
    if not ShouldPlayHuntSounds() or not IsHuntSessionActive(self.lastSnapshot) then
        return
    end

    if type(unitToken) ~= "string" or type(UnitGUID) ~= "function" then
        return
    end

    local guid = UnitGUID(unitToken)
    if type(guid) ~= "string" then
        return
    end

    if not IsUnitDead(unitToken) then
        return
    end

    local name = type(UnitName) == "function" and UnitName(unitToken) or nil
    if not self:IsConfirmedPreyTarget(guid, name) then
        return
    end

    local state = self:GetSoundState()
    local now = GetNowSeconds()
    if state.lastKilledGUID == guid and (now - (state.lastPreyKilledAt or 0)) < 4 then
        return
    end
    state.lastKilledGUID = guid

    local sounds = self:GetResolvedSoundPaths()
    PlayResolvedSoundCue(self, "kill", sounds.kill, "lastPreyKilledAt", 0.25)
end

function Preybreaker:HandlePlayerTargetChangedForSounds()
    if not ShouldPlayHuntSounds() or not IsHuntSessionActive(self.lastSnapshot) then
        return
    end

    self:RememberRecentHostileUnit("target")
    self:RememberTrapContextFromUnit("target")

    if self:IsAmbushCandidateWindowActive() then
        self:PromoteUnitPreyCandidateIfHostile("target")
    end

    local snapshot = self.lastSnapshot
    local progressState = snapshot and snapshot.progressState or nil
    if progressState == nil or progressState < PREY_STATE_WARM or type(UnitGUID) ~= "function" then
        return
    end

    local promoted = self:PromoteUnitPreyCandidateIfLikely("target")
    if promoted then
        local sounds = self:GetResolvedSoundPaths()
        PlayResolvedSoundCue(self, "prey_combat", sounds.ambush, "lastPreyCombatAt", 8)
    end
end

function Preybreaker:HandleMouseoverChangedForSounds()
    if not ShouldPlayHuntSounds() or not IsHuntSessionActive(self.lastSnapshot) then
        return
    end

    self:RememberRecentHostileUnit("mouseover")
    self:RememberTrapContextFromUnit("mouseover")
end

function Preybreaker:HandleAmbushChatMessageForSounds(message, sourceEvent)
    if not ShouldPlayHuntSounds() then
        return
    end

    local snapshot = self.lastSnapshot
    if not IsHuntSessionActive(snapshot) then
        return
    end

    local progressState = snapshot and snapshot.progressState or nil
    if type(progressState) == "number" and progressState > PREY_STATE_WARM then
        return
    end

    local normalized = NormalizeAmbushChatMessage(message)
    if not normalized then
        return
    end

    local messageSet = GetAmbushMessageSet()
    if not messageSet[normalized] then
        return
    end

    self:PromoteRecentHostileCandidate(AMBUSH_CANDIDATE_WINDOW_SECONDS)
    self:ArmAmbushCandidateWindow(AMBUSH_PREY_CAPTURE_WINDOW_SECONDS)
    if not self:PromoteUnitPreyCandidateIfLikely("target") then
        self:PromoteUnitPreyCandidateIfHostile("target")
    end
    local sounds = self:GetResolvedSoundPaths()
    local played = PlayResolvedSoundCue(self, "ambush", sounds.ambush, "lastAmbushAt", 6)
    if played and ns.Debug and type(ns.Debug.Log) == "function" then
        ns.Debug:Log("sound", ns.Debug:KV("cue", "ambush"), ns.Debug:KV("source", sourceEvent or "chat"), ns.Debug:KV("message", normalized))
    end
end

function Preybreaker:HandleSnapshotSoundTransitions(previousSnapshot, snapshot)
    local previousSessionActive = IsHuntSessionActive(previousSnapshot)
    local newSessionActive = IsHuntSessionActive(snapshot)
    local sounds = self:GetResolvedSoundPaths()

    if not previousSessionActive and newSessionActive then
        self:ResetPreyCombatCandidates()
        PlayResolvedSoundCue(self, "hunt_start", sounds.huntStart, "lastHuntStartAt", 0.75)
        return
    end

    if previousSessionActive and not newSessionActive then
        -- Fire hunt_end if the previous quest was turned in (completion-flagged).
        local prevQuestID = ResolveSessionQuestID(previousSnapshot)
        if prevQuestID and IsQuestCompletionFlagged(prevQuestID) then
            PlayResolvedSoundCue(self, "hunt_end", sounds.huntEnd, "lastHuntEndAt", 0.75)
        end
        self:ResetPreyCombatCandidates()
        return
    end

    if not (previousSessionActive and newSessionActive) then
        return
    end

    local previousState = previousSnapshot and previousSnapshot.progressState or nil
    local newState = snapshot and snapshot.progressState or nil
    if previousState == PREY_STATE_COLD and newState == PREY_STATE_WARM then
        self:PromoteRecentHostileCandidate(AMBUSH_CANDIDATE_WINDOW_SECONDS)
        self:PromoteUnitPreyCandidateIfLikely("target")
        self:ArmAmbushCandidateWindow(AMBUSH_PREY_CAPTURE_WINDOW_SECONDS)
    end

    if type(previousState) == "number" and type(newState) == "number" and previousState ~= newState then
        PlayResolvedSoundCue(self, "progress", sounds.progress or sounds.interaction, "lastStageProgressAt", 0.75)
    end

end

function Preybreaker:PurgeAbandonedQuestSuppression()
    local state = self:GetSoundState()
    local abandoned = state.recentAbandonedQuestIDs
    if type(abandoned) ~= "table" then
        return
    end

    local now = GetNowSeconds()
    for questID, seenAt in pairs(abandoned) do
        if type(questID) ~= "number" or type(seenAt) ~= "number" or (now - seenAt) > ABANDON_SUPPRESSION_SECONDS then
            abandoned[questID] = nil
        end
    end
end

function Preybreaker:HandleQuestRemovedForSounds(questID)
    if type(questID) ~= "number" then
        return
    end

    local state = self:GetSoundState()
    if type(state.recentAbandonedQuestIDs) ~= "table" then
        state.recentAbandonedQuestIDs = {}
    end

    self:PurgeAbandonedQuestSuppression()

    if IsQuestCompletionFlagged(questID) then
        state.recentAbandonedQuestIDs[questID] = nil
        return
    end

    if self:IsRelevantQuestForSound(questID) then
        state.recentAbandonedQuestIDs[questID] = GetNowSeconds()
    end
end

function Preybreaker:HandleQuestTurnedInSound(questID)
    if not ShouldPlayHuntSounds() or not self:IsRelevantQuestForSound(questID) then
        return
    end

    self:PurgeAbandonedQuestSuppression()
    local state = self:GetSoundState()
    local abandonedAt = state.recentAbandonedQuestIDs and state.recentAbandonedQuestIDs[questID] or nil
    if type(abandonedAt) == "number" and (GetNowSeconds() - abandonedAt) <= ABANDON_SUPPRESSION_SECONDS then
        state.recentAbandonedQuestIDs[questID] = nil
        return
    end

    if state.recentAbandonedQuestIDs then
        state.recentAbandonedQuestIDs[questID] = nil
    end

    local sounds = self:GetResolvedSoundPaths()
    PlayResolvedSoundCue(self, "hunt_end", sounds.huntEnd, "lastHuntEndAt", 0.75)
end

local RIPOSTE_SPELL_IDS = {
    [1260432] = true, -- Riposte
}

local INTERACTION_SPELL_IDS = {
    [1242005] = true, -- Attempting to Disarm Trap
}

function Preybreaker:HandleUnitSpellcastSound(unit, spellID)
    if unit ~= "player" or not ShouldPlayHuntSounds() then
        return
    end

    if not IsHuntSessionActive(self.lastSnapshot) then
        return
    end

    if type(spellID) ~= "number" then
        return
    end

    local sounds = self:GetResolvedSoundPaths()
    if RIPOSTE_SPELL_IDS[spellID] then
        PlayResolvedSoundCue(self, "riposte", sounds.riposte, "lastSpellRiposteAt", 0.25)
        return
    end

    if INTERACTION_SPELL_IDS[spellID] then
        self:RememberTrapContextFromUnit("target")
        self:RememberTrapContextFromUnit("mouseover")
        if self:HasRecentTrapContext(TRAP_CONTEXT_WINDOW_SECONDS) then
            PlayResolvedSoundCue(self, "interaction", sounds.interaction, "lastInteractionAt", 0.25)
        end
    end
end

function Preybreaker:ShouldPlayDeathSound()
    if not ShouldPlayHuntSounds() then
        return false
    end

    if ns.Settings and type(ns.Settings.ShouldPlayDeathSounds) == "function" and not ns.Settings:ShouldPlayDeathSounds() then
        return false
    end

    local snapshot = self.lastSnapshot
    if not IsHuntSessionActive(snapshot) then
        return false
    end

    if not IsPlayerDeadOrGhostSafe() then
        return false
    end

    return IsPlayerInSnapshotMap(snapshot)
end

function Preybreaker:HandlePlayerDeathForSounds()
    if not self:ShouldPlayDeathSound() then
        return
    end

    local state = self:GetSoundState()
    if state.deathCueArmed == true then
        return
    end

    local sounds = self:GetResolvedSoundPaths()
    local played = PlayResolvedSoundCue(self, "death", sounds.death, "lastDeathCueAt", 0.5)
    if played then
        state.deathCueArmed = true
    end
end

function Preybreaker:HandlePlayerRevivedForSounds()
    local state = self:GetSoundState()
    state.deathCueArmed = false
    state.lastDeathCueAt = nil
end

function Preybreaker:ShouldPreserveSnapshotWhileDead(previousSnapshot, snapshot)
    if type(previousSnapshot) ~= "table" or type(snapshot) ~= "table" then
        return false
    end

    if previousSnapshot.active ~= true or snapshot.active == true then
        return false
    end

    if not IsHuntSessionActive(previousSnapshot) then
        return false
    end

    if not IsPlayerDeadOrGhostSafe() then
        return false
    end

    local previousQuestID = previousSnapshot.questID or previousSnapshot.activeQuestID or previousSnapshot.worldQuestID
    local newQuestID = snapshot.questID or snapshot.activeQuestID or snapshot.worldQuestID
    if type(newQuestID) == "number" and type(previousQuestID) == "number" and newQuestID ~= previousQuestID then
        return false
    end

    return true
end

function Preybreaker:BuildDeathPreservedSnapshot(previousSnapshot, snapshot)
    if not self:ShouldPreserveSnapshotWhileDead(previousSnapshot, snapshot) then
        return snapshot
    end

    return {
        active = true,
        widgetID = snapshot.widgetID or previousSnapshot.widgetID,
        questID = previousSnapshot.questID,
        activeQuestID = previousSnapshot.activeQuestID,
        worldQuestID = previousSnapshot.worldQuestID,
        mapID = previousSnapshot.mapID,
        progressState = previousSnapshot.progressState,
        progress = previousSnapshot.progress,
        percent = previousSnapshot.percent,
        preservedWhileDead = true,
    }
end

function Preybreaker:Refresh(reason, ...)
    -- Invalidate per-dispatch caches.
    if ns.Util and ns.Util.InvalidatePreyQuestContextCache then
        ns.Util.InvalidatePreyQuestContextCache()
    end

    -- Mark overlay text styles dirty when triggered by a settings change.
    if reason and type(reason) == "string" and reason:sub(1, 8) == "settings" then
        if ns.OverlayView and ns.OverlayView.MarkTextStyleDirty then
            ns.OverlayView:MarkTextStyleDirty()
        end
    end

    local enabled = not ns.Settings or ns.Settings:IsEnabled()
    local snapshot = enabled and ns.DataSource.BuildSnapshot() or self:BuildInactiveSnapshot()

    local previousSnapshot = self.lastSnapshot
    if previousSnapshot and enabled then
        snapshot = self:BuildDeathPreservedSnapshot(previousSnapshot, snapshot)
    end

    self.activeWidgetID = enabled and snapshot.widgetID or nil

    if previousSnapshot and enabled and ShouldPlayHuntSounds() then
        self:HandleSnapshotSoundTransitions(previousSnapshot, snapshot)
    end

    self:RefreshSoundContext(snapshot)
    self.lastSnapshot = snapshot

    if ns.Debug:IsEnabled() then
        ns.Debug:Log(
            "refresh",
            ns.Debug:KV("reason", reason or "manual"),
            ns.Debug:KV("enabled", enabled),
            ns.Debug:KV("active", snapshot.active),
            ns.Debug:KV("widgetID", snapshot.widgetID),
            ns.Debug:KV("progressState", snapshot.progressState),
            ns.Debug:KV("percent", snapshot.percent),
            ns.Debug:KV("preservedWhileDead", snapshot.preservedWhileDead == true),
            ns.Debug:KV("bootstrap", self:GetBootstrapSummary())
        )
    end

    if ns.QuestTracking then
        ns.QuestTracking:Sync(snapshot, reason)
    end

    ns.OverlayView:Render(snapshot)
    if ns.SettingsPanel and ns.SettingsPanel.frame and ns.SettingsPanel.frame:IsShown() then
        ns.SettingsPanel:RefreshControls()
        ns.SettingsPanel:RefreshPreview(snapshot)
    end
    if ns.HuntPanel and ns.HuntPanel.frame and ns.HuntPanel.frame:IsShown() then
        if ns.Settings and not ns.Settings:IsHuntPanelEnabled() then
            ns.HuntPanel:Hide()
        else
            if ns.Debug:IsEnabled() then
                ns.Debug:Log("hunts", ns.Debug:KV("action", "controllerRefresh"), ns.Debug:KV("detail", "panelRefresh"), ns.Debug:KV("extra", nil))
            end
            ns.HuntPanel:Refresh()
        end
    elseif ns.HuntPanel and _G[MISSION_FRAME_NAME] and _G[MISSION_FRAME_NAME]:IsShown() then
        -- Mission frame is open but hunt panel isn't shown (hook may have missed).
        if ns.Debug:IsEnabled() then
            ns.Debug:Log("hunts", ns.Debug:KV("action", "controllerRefresh"), ns.Debug:KV("detail", "showAttachedFallback"), ns.Debug:KV("extra", string.format("panelFrame=%s,panelShown=%s", tostring(ns.HuntPanel.frame ~= nil), tostring(ns.HuntPanel.frame and ns.HuntPanel.frame:IsShown()))))
        end
        ns.HuntPanel:ShowAttached()
    else
        if ns.Debug:IsEnabled() then
            ns.Debug:Log("hunts", ns.Debug:KV("action", "controllerRefresh"), ns.Debug:KV("detail", "skip"), ns.Debug:KV("extra", string.format("huntPanel=%s,panelFrame=%s,missionFrame=%s,missionShown=%s", tostring(ns.HuntPanel ~= nil), tostring(ns.HuntPanel and ns.HuntPanel.frame ~= nil), tostring(_G[MISSION_FRAME_NAME] ~= nil), tostring(_G[MISSION_FRAME_NAME] and _G[MISSION_FRAME_NAME]:IsShown()))))
        end
    end
end

