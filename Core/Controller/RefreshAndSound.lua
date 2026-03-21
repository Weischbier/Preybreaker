-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
local Preybreaker = ns.Controller

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
            lastTrapContextAt = nil,
            lastTrapContextName = nil,
            lastTrapContextSource = nil,
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
local IsLikelyTrapUnitName
local AmbushMessageCache = {}
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

local function IsCreatureLikeGUID(guidType)
    return guidType == "Creature" or guidType == "Vehicle" or guidType == "Pet"
end

local function ExtractNPCIDFromGUID(guid)
    if type(guid) ~= "string" then
        return nil
    end

    local guidType, npcID
    if type(strsplit) == "function" then
        guidType, _, _, _, _, npcID = strsplit("-", guid)
    else
        local fields = {}
        for field in guid:gmatch("[^-]+") do
            fields[#fields + 1] = field
            if #fields >= 6 then
                break
            end
        end
        guidType = fields[1]
        npcID = fields[6]
    end

    if not IsCreatureLikeGUID(guidType) then
        return nil
    end

    npcID = tonumber(npcID)
    if not npcID or npcID <= 0 then
        return nil
    end

    return npcID
end

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

local function PlaySoundCue(controller, soundPath, throttleKey, throttleSeconds)
    if not ShouldPlayHuntSounds() then
        return false
    end

    if type(soundPath) ~= "string" or soundPath == "" then
        return false
    end

    if throttleKey and throttleSeconds and throttleSeconds > 0 then
        local state = controller:GetSoundState()
        local now = GetNowSeconds()
        local previous = state[throttleKey] or 0
        if (now - previous) < throttleSeconds then
            return false
        end
        state[throttleKey] = now
    end

    PlayConfiguredSound(soundPath)
    return true
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

    local spellName = type(GetSpellInfo) == "function" and GetSpellInfo(ROGUE_AMBUSH_SPELL_ID) or nil
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

    local spellName = type(GetSpellInfo) == "function" and GetSpellInfo(ROGUE_AMBUSH_SPELL_ID) or ""
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

function Preybreaker:GetResolvedSoundPaths()
    local sounds = ns.Constants and ns.Constants.Media and ns.Constants.Media.Sounds
    return {
        huntStart = ResolveSoundPath(sounds, "HuntStart"),
        huntEnd = ResolveSoundPath(sounds, "HuntEnd"),
        ambush = ResolveSoundPath(sounds, "Ambush", "ColdToWarm", "PhaseChange"),
        riposte = ResolveSoundPath(sounds, "Riposte", "WarmToHot", "PhaseChange"),
        finalPhase = ResolveSoundPath(sounds, "FinalPhase"),
        interaction = ResolveSoundPath(sounds, "Interaction", "PhaseChange"),
        kill = ResolveSoundPath(sounds, "Kill"),
    }
end

function Preybreaker:RefreshSoundContext(snapshot)
    local state = self:GetSoundState()
    local matchSet, relevantQuestIDs = BuildQuestTitleMatchSet(snapshot)
    state.preyNameMatches = matchSet
    state.relevantQuestIDs = relevantQuestIDs
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
    self:PromoteUnitPreyCandidateIfLikely(unitToken)

    if self:IsAmbushCandidateWindowActive() and IsUnitTargetOrMouseover(unitToken) then
        self:PromoteUnitPreyCandidateIfHostile(unitToken)
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
    PlaySoundCue(self, sounds.kill, "lastPreyKilledAt", 0.25)
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

    self:PromoteUnitPreyCandidateIfLikely("target")
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
    local played = PlaySoundCue(self, sounds.ambush, "lastAmbushAt", 6)
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
        PlaySoundCue(self, sounds.huntStart, "lastHuntStartAt", 0.75)
        return
    end

    if previousSessionActive and not newSessionActive then
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
        PlaySoundCue(self, sounds.interaction, "lastStageProgressAt", 0.75)
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
    PlaySoundCue(self, sounds.huntEnd, "lastHuntEndAt", 0.75)
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
        PlaySoundCue(self, sounds.riposte, "lastSpellRiposteAt", 0.25)
        return
    end

    if INTERACTION_SPELL_IDS[spellID] then
        self:RememberTrapContextFromUnit("target")
        self:RememberTrapContextFromUnit("mouseover")
        if self:HasRecentTrapContext(TRAP_CONTEXT_WINDOW_SECONDS) then
            PlaySoundCue(self, sounds.interaction, "lastInteractionAt", 0.25)
        end
    end
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

    if ns.QuestTracking then
        ns.QuestTracking:Sync(snapshot, reason)
    end

    ns.OverlayView:Render(snapshot)
    if ns.SettingsPanel and ns.SettingsPanel.frame and ns.SettingsPanel.frame:IsShown() then
        ns.SettingsPanel:RefreshControls()
        ns.SettingsPanel:RefreshPreview(snapshot)
    end
    if ns.HuntPanel and ns.HuntPanel.frame and ns.HuntPanel.frame:IsShown() then
        ns.HuntPanel:Refresh()
    end
end

