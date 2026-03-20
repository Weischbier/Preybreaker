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

function Preybreaker:GetSoundState()
    if not self.soundState then
        self.soundState = {
            preyNameMatches = {},
            relevantQuestIDs = {},
            preyCandidateGUIDs = {},
            preyCandidateNPCIDs = {},
            recentHostileGUIDs = {},
        }
    end

    return self.soundState
end

local PREY_STATE = Enum and Enum.PreyHuntProgressState
local PREY_STATE_COLD = (PREY_STATE and PREY_STATE.Cold) or 0
local PREY_STATE_WARM = (PREY_STATE and PREY_STATE.Warm) or 1
local RECENT_HOSTILE_EXPIRY_SECONDS = 8
local AMBUSH_CANDIDATE_WINDOW_SECONDS = 2

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
    state.lastAmbushSource = nil
    state.lastAmbushAt = nil
    state.lastKilledGUID = nil
    state.lastKillAt = nil
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

function Preybreaker:RememberRecentHostileGUID(guid)
    if type(guid) ~= "string" then
        return
    end

    local state = self:GetSoundState()
    local now = GetNowSeconds()

    for knownGUID, seenAt in pairs(state.recentHostileGUIDs) do
        if type(seenAt) ~= "number" or (now - seenAt) > RECENT_HOSTILE_EXPIRY_SECONDS then
            state.recentHostileGUIDs[knownGUID] = nil
        end
    end

    state.recentHostileGUIDs[guid] = now
end

function Preybreaker:RememberRecentHostileUnit(unitToken)
    if not IsHostileUnitToken(unitToken) or type(UnitGUID) ~= "function" then
        return
    end

    local guid = UnitGUID(unitToken)
    if type(guid) == "string" then
        self:RememberRecentHostileGUID(guid)
    end
end

function Preybreaker:PromoteRecentHostileCandidate(maxAgeSeconds)
    local state = self:GetSoundState()
    local recent = state.recentHostileGUIDs
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
        elseif age <= maxAgeSeconds and (not newestAt or seenAt > newestAt) then
            newestGUID = guid
            newestAt = seenAt
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

    if ns.Util and type(ns.Util.BuildPreyQuestContext) == "function" then
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
        interaction = ResolveSoundPath(sounds, "Interaction", "PhaseChange"),
        kill = ResolveSoundPath(sounds, "Kill", "HotToFinal", "FinalPhase"),
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

    if #normalizedName < 4 then
        return false
    end

    for candidate in pairs(matchSet) do
        if #candidate >= 4 and (candidate:find(normalizedName, 1, true) or normalizedName:find(candidate, 1, true)) then
            return true
        end
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

function Preybreaker:HandleNameplateUnitAddedForSounds(unitToken)
    if not ShouldPlayHuntSounds() or not IsHuntSessionActive(self.lastSnapshot) then
        return
    end

    self:RememberRecentHostileUnit(unitToken)
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
    if not self:IsLikelyPreyTarget(guid, name) then
        return
    end

    local state = self:GetSoundState()
    local now = GetNowSeconds()
    if state.lastKilledGUID == guid and (now - (state.lastKillAt or 0)) < 4 then
        return
    end
    state.lastKilledGUID = guid

    local sounds = self:GetResolvedSoundPaths()
    PlaySoundCue(self, sounds.kill, "lastKillAt", 0.25)
end

function Preybreaker:HandlePlayerTargetChangedForSounds()
    if not ShouldPlayHuntSounds() or not IsHuntSessionActive(self.lastSnapshot) then
        return
    end

    self:RememberRecentHostileUnit("target")

    local snapshot = self.lastSnapshot
    local progressState = snapshot and snapshot.progressState or nil
    if progressState == nil or progressState < PREY_STATE_WARM or type(UnitGUID) ~= "function" then
        return
    end

    local guid = UnitGUID("target")
    if type(guid) == "string" and IsHostileUnitToken("target") then
        self:PromotePreyCombatCandidate(guid)
    end
end

function Preybreaker:RefreshSoundEventRegistrations(snapshot)
    self.soundEventsListening = ShouldPlayHuntSounds() and IsHuntSessionActive(snapshot)
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
        if IsHostileUnitToken("target") and type(UnitGUID) == "function" then
            local targetGUID = UnitGUID("target")
            self:PromotePreyCombatCandidate(targetGUID)
        end
        PlaySoundCue(self, sounds.ambush, "lastAmbushAt", 6)
    end
end

function Preybreaker:HandleQuestTurnedInSound(questID)
    if not ShouldPlayHuntSounds() or not self:IsRelevantQuestForSound(questID) then
        return
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
        PlaySoundCue(self, sounds.riposte, "lastRiposteAt", 0.25)
        return
    end

    if INTERACTION_SPELL_IDS[spellID] then
        PlaySoundCue(self, sounds.interaction, "lastInteractionAt", 0.25)
    end
end

function Preybreaker:Refresh(reason, ...)
    local enabled = not ns.Settings or ns.Settings:IsEnabled()
    local snapshot = enabled and ns.DataSource.BuildSnapshot() or self:BuildInactiveSnapshot()
    self.activeWidgetID = enabled and snapshot.widgetID or nil

    local previousSnapshot = self.lastSnapshot
    if previousSnapshot and enabled and ShouldPlayHuntSounds() then
        self:HandleSnapshotSoundTransitions(previousSnapshot, snapshot)
    end

    self:RefreshSoundContext(snapshot)
    self:RefreshSoundEventRegistrations(snapshot)
    self.lastSnapshot = snapshot

    ns.Debug:Log(
        "refresh",
        ns.Debug:KV("reason", reason or "manual"),
        ns.Debug:KV("enabled", enabled),
        ns.Debug:KV("active", snapshot.active),
        ns.Debug:KV("widgetID", snapshot.widgetID),
        ns.Debug:KV("progressState", snapshot.progressState),
        ns.Debug:KV("percent", snapshot.percent),
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

