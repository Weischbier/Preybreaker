-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Clean-room hunt-list subsystem:
-- - reads live prey hunts from AdventureMap pins
-- - stabilizes pin discovery before commit
-- - dedupes and sorts hunt entries
-- - warms quest-choice rewards asynchronously with retry for transient empties

local _, ns = ...

local Util = ns.Util
local Constants = ns.Constants

ns.HuntList = ns.HuntList or {}

local HuntList = ns.HuntList

-- Frame reference compat aliases (see Constants.FrameRef).
local FR = Constants and Constants.FrameRef or {}
local MISSION_FRAME_NAME = FR.MissionFrame or "CovenantMissionFrame"
local QUEST_CHOICE_DIALOG_NAME = FR.QuestChoiceDialog or "AdventureMapQuestChoiceDialog"
local ADVENTURE_MAP_ADDON = FR.AdventureMapAddon or "Blizzard_AdventureMap"

local PIN_POOL_NAME = "AdventureMap_QuestOfferPinTemplate"
local FILTER_ALL = "All"
local FILTER_NIGHTMARE = "Nightmare"
local FILTER_HARD = "Hard"
local FILTER_NORMAL = "Normal"
local PIN_POLL_SECONDS = 0.15
local PIN_STABLE_READS = 3
local PIN_MAX_WAIT_SECONDS = 6.0
local WARMUP_POLL_SECONDS = 0.10
local WARMUP_STABLE_READS = 3
local WARMUP_TIMEOUT_SECONDS = 4.0
local WARMUP_MAX_EMPTY_ATTEMPTS = 3
local WARMUP_PASS_COOLDOWN_SECONDS = 0.9
local BLOCKED_SUBZONE_GLOBAL_KEYS = {
    "SANCTUM_OF_LIGHT",
}
local BLOCKED_SUBZONE_FALLBACKS = {
    ["Sanctum of Light"] = true,
}

local ParseDifficulty
local ResolveZoneByCoords

local FILTER_TO_DB = {
    [FILTER_ALL] = "all",
    [FILTER_NIGHTMARE] = "nightmare",
    [FILTER_HARD] = "hard",
    [FILTER_NORMAL] = "normal",
}

local DB_TO_FILTER = {
    all = FILTER_ALL,
    nightmare = FILTER_NIGHTMARE,
    hard = FILTER_HARD,
    normal = FILTER_NORMAL,
}

local DIFFICULTY_ORDER = {
    [FILTER_NIGHTMARE] = 1,
    [FILTER_HARD] = 2,
    [FILTER_NORMAL] = 3,
}

local function LogHunts(action, detail, extra)
    if not (ns.Debug and type(ns.Debug.Log) == "function" and type(ns.Debug.KV) == "function") then
        return
    end

    ns.Debug:Log(
        "hunts",
        ns.Debug:KV("action", action),
        ns.Debug:KV("detail", detail),
        ns.Debug:KV("extra", extra)
    )
end

local function GetCurrentSubZoneText()
    if type(GetSubZoneText) ~= "function" then
        return nil
    end

    local subZoneText = Util.SafeCall(GetSubZoneText)
    if type(subZoneText) ~= "string" or subZoneText == "" then
        return nil
    end

    return subZoneText
end

local function IsBlockedSubZone(subZoneText)
    if type(subZoneText) ~= "string" or subZoneText == "" then
        return false, nil
    end

    for _, globalKey in ipairs(BLOCKED_SUBZONE_GLOBAL_KEYS) do
        local globalText = _G and _G[globalKey] or nil
        if type(globalText) == "string" and globalText ~= "" and subZoneText == globalText then
            return true, globalKey
        end
    end

    if BLOCKED_SUBZONE_FALLBACKS[subZoneText] then
        return true, "fallback"
    end

    return false, nil
end

local function HasRelevantPreyQuestContext()
    if Util and type(Util.BuildPreyQuestContext) == "function" then
        local context = Util.BuildPreyQuestContext()
        if type(context) == "table" then
            local questID = context.trackedQuestID or context.activeQuestID or context.worldQuestID
            if type(questID) == "number" and questID > 0 then
                return true, questID
            end
        end
    end

    if type(C_QuestLog) == "table" and type(C_QuestLog.GetActivePreyQuest) == "function" then
        local activeQuestID = Util.SafeCall(C_QuestLog.GetActivePreyQuest)
        if type(activeQuestID) == "number" and activeQuestID > 0 then
            return true, activeQuestID
        end
    end

    return false, nil
end

local function GetCharacterHuntQuestCache()
    if not (ns.Settings and type(ns.Settings.GetCharacterHuntQuestCache) == "function") then
        return nil
    end

    local cache = ns.Settings:GetCharacterHuntQuestCache()
    if type(cache) ~= "table" then
        return nil
    end

    return cache
end

local function NormalizeFilter(filterValue)
    if type(filterValue) ~= "string" then
        return FILTER_ALL
    end

    if FILTER_TO_DB[filterValue] then
        return filterValue
    end

    return DB_TO_FILTER[strlower(filterValue)] or FILTER_ALL
end

local _cachedZoneOrderLookup = nil

local function BuildZoneOrderLookup()
    if _cachedZoneOrderLookup then
        return _cachedZoneOrderLookup
    end

    local lookup = {}
    local zones = Constants and Constants.Hunt and Constants.Hunt.Zones or nil
    if type(zones) ~= "table" then
        return lookup
    end

    for index, zoneName in ipairs(zones) do
        lookup[zoneName] = index
    end

    _cachedZoneOrderLookup = lookup
    return lookup
end

local function GetQuestChoiceDialog()
    if _G[QUEST_CHOICE_DIALOG_NAME] then
        return _G[QUEST_CHOICE_DIALOG_NAME]
    end

    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return nil
    end

    if type(C_AddOns) == "table" and type(C_AddOns.LoadAddOn) == "function" then
        Util.SafeCall(C_AddOns.LoadAddOn, ADVENTURE_MAP_ADDON)
    end

    return _G[QUEST_CHOICE_DIALOG_NAME]
end

local function GetPinPool()
    local missionFrame = _G[MISSION_FRAME_NAME]
    local mapTab = missionFrame and missionFrame.MapTab or nil
    return mapTab and mapTab.pinPools and mapTab.pinPools[PIN_POOL_NAME] or nil
end

local function CountPins()
    local pool = GetPinPool()
    if not pool then return 0 end
    local n = 0
    for _ in pool:EnumerateActive() do n = n + 1 end
    return n
end

local function CollectActiveQuestPins()
    local pool = GetPinPool()
    if not pool then return {} end

    local pins = {}
    local seen = {}
    for pin in pool:EnumerateActive() do
        if pin and pin.questID and pin.title then
            if not seen[pin.questID] then
                seen[pin.questID] = true
                pins[#pins + 1] = pin
            end
        end
    end
    return pins
end

local function SafePackCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end

    local results = { pcall(func, ...) }
    local ok = table.remove(results, 1)
    if ok then
        results.n = #results
        return results
    end

    LogHunts("safePackCallError", tostring(func), tostring(results[1]))
    return nil
end

local function FormatDumpValue(value)
    local valueType = type(value)
    if value == nil then
        return "nil"
    end

    if valueType == "boolean" then
        return value and "true" or "false"
    end

    if valueType == "number" then
        if value == math.floor(value) then
            return tostring(value)
        end
        return string.format("%.4f", value)
    end

    return tostring(value)
end

local function AppendPackedDump(lines, label, results)
    if not results or type(results) ~= "table" or (results.n or 0) == 0 then
        lines[#lines + 1] = string.format("%s: nil", label)
        return
    end

    local parts = {}
    for index = 1, results.n do
        parts[#parts + 1] = string.format("[%d]=%s", index, FormatDumpValue(results[index]))
    end

    lines[#lines + 1] = string.format("%s: %s", label, table.concat(parts, ", "))
end

local function AppendPinScalarField(lines, label, value)
    if value == nil then
        return
    end

    local valueType = type(value)
    if valueType == "function" or valueType == "table" or valueType == "userdata" then
        return
    end

    lines[#lines + 1] = string.format("%s=%s", label, FormatDumpValue(value))
end

local function HasUnearnedAchievementMarker(descriptionText)
    if type(descriptionText) ~= "string" or descriptionText == "" then
        return false
    end

    local normalized = descriptionText:gsub("\r\n", "\n")
    local firstLine, remainder = normalized:match("^([^\n]*)(.*)$")
    if type(firstLine) ~= "string" then
        return false
    end

    return type(remainder) == "string" and remainder:find("%S") ~= nil
end

function HuntList:GetMapQuestDumpLines()
    local lines = {}
    local missionFrame = _G[MISSION_FRAME_NAME]
    local mapTab = missionFrame and missionFrame.MapTab or nil
    local pins = CollectActiveQuestPins()

    lines[#lines + 1] = "=== Prey Map Quest Dump ==="
    lines[#lines + 1] = string.format("missionFrameShown=%s", FormatDumpValue(missionFrame and missionFrame:IsShown() or false))
    lines[#lines + 1] = string.format("mapTabShown=%s", FormatDumpValue(mapTab and mapTab:IsShown() or false))
    lines[#lines + 1] = string.format("pinPoolActiveCount=%s", FormatDumpValue(CountPins()))
    lines[#lines + 1] = string.format("uniqueQuestPins=%s", FormatDumpValue(#pins))

    if #pins == 0 then
        lines[#lines + 1] = "No active quest pins found."
        return lines
    end

    for index, pin in ipairs(pins) do
        local questID = pin.questID
        lines[#lines + 1] = string.format("-- Pin %d --", index)
        lines[#lines + 1] = string.format("pinName=%s", FormatDumpValue(type(pin.GetName) == "function" and Util.SafeCall(pin.GetName, pin) or nil))
        lines[#lines + 1] = string.format("objectType=%s", FormatDumpValue(type(pin.GetObjectType) == "function" and Util.SafeCall(pin.GetObjectType, pin) or nil))

        AppendPinScalarField(lines, "pin.questID", pin.questID)
        AppendPinScalarField(lines, "pin.title", pin.title)
        AppendPinScalarField(lines, "pin.description", pin.description)
        lines[#lines + 1] = string.format("pin.descriptionHasExtraText=%s", FormatDumpValue(HasUnearnedAchievementMarker(pin.description)))
        AppendPinScalarField(lines, "pin.normalizedX", pin.normalizedX)
        AppendPinScalarField(lines, "pin.normalizedY", pin.normalizedY)
        AppendPinScalarField(lines, "pin.x", pin.x)
        AppendPinScalarField(lines, "pin.y", pin.y)
        AppendPinScalarField(lines, "pin.mapID", pin.mapID)
        AppendPinScalarField(lines, "pin.uiMapID", pin.uiMapID)
        AppendPinScalarField(lines, "pin.atlasName", pin.atlasName)
        AppendPinScalarField(lines, "pin.tagName", pin.tagName)

        if type(C_QuestLog) == "table" then
            lines[#lines + 1] = string.format("C_QuestLog.GetTitleForQuestID=%s", FormatDumpValue(type(C_QuestLog.GetTitleForQuestID) == "function" and Util.SafeCall(C_QuestLog.GetTitleForQuestID, questID) or nil))
            lines[#lines + 1] = string.format("C_QuestLog.IsOnQuest=%s", FormatDumpValue(type(C_QuestLog.IsOnQuest) == "function" and Util.SafeCall(C_QuestLog.IsOnQuest, questID) or nil))
            lines[#lines + 1] = string.format("C_QuestLog.IsQuestFlaggedCompleted=%s", FormatDumpValue(type(C_QuestLog.IsQuestFlaggedCompleted) == "function" and Util.SafeCall(C_QuestLog.IsQuestFlaggedCompleted, questID) or nil))
            AppendPackedDump(lines, "C_QuestLog.GetQuestAdditionalHighlights", type(C_QuestLog.GetQuestAdditionalHighlights) == "function" and SafePackCall(C_QuestLog.GetQuestAdditionalHighlights, questID) or nil)
        end

        if type(C_TaskQuest) == "table" then
            AppendPackedDump(lines, "C_TaskQuest.GetQuestInfoByQuestID", type(C_TaskQuest.GetQuestInfoByQuestID) == "function" and SafePackCall(C_TaskQuest.GetQuestInfoByQuestID, questID) or nil)
        end

        if type(C_AdventureMap) == "table" then
            AppendPackedDump(lines, "C_AdventureMap.GetQuestInfo", type(C_AdventureMap.GetQuestInfo) == "function" and SafePackCall(C_AdventureMap.GetQuestInfo, questID) or nil)
        end

        if ns.HuntData and type(ns.HuntData.GetHuntAchievementStatus) == "function" then
            local huntAchievement = ns.HuntData:GetHuntAchievementStatus(pin.title, ParseDifficulty(pin.description))
            if huntAchievement then
                lines[#lines + 1] = string.format(
                    "HuntData.GetHuntAchievementStatus=show (%s)",
                    FormatDumpValue(huntAchievement.source)
                )
            else
                lines[#lines + 1] = "HuntData.GetHuntAchievementStatus=hide"
            end
        end

        lines[#lines + 1] = string.format("derivedDifficulty=%s", FormatDumpValue(ParseDifficulty(pin.description)))
        lines[#lines + 1] = string.format("derivedZone=%s", FormatDumpValue(ResolveZoneByCoords(pin.normalizedX, pin.normalizedY)))
    end

    return lines
end

ParseDifficulty = function(descriptionText)
    local description = type(descriptionText) == "string" and descriptionText or ""
    local hunt = Constants and Constants.Hunt or nil
    local difficultyPatterns = hunt and hunt.DifficultyPatterns or nil
    local normalPatterns = difficultyPatterns and difficultyPatterns.normal or nil
    local hardPatterns = difficultyPatterns and difficultyPatterns.hard or nil
    local nightmarePatterns = difficultyPatterns and difficultyPatterns.nightmare or nil

    local function ContainsAny(text, patterns)
        if type(text) ~= "string" or type(patterns) ~= "table" then
            return false
        end

        local loweredText = strlower(text)
        for _, pattern in ipairs(patterns) do
            if text:find(pattern, 1, true) then
                return true
            end
            local loweredPattern = strlower(pattern)
            if loweredText:find(loweredPattern, 1, true) then
                return true
            end
        end

        return false
    end

    if ContainsAny(description, nightmarePatterns) then
        return FILTER_NIGHTMARE
    end
    if ContainsAny(description, hardPatterns) then
        return FILTER_HARD
    end
    if ContainsAny(description, normalPatterns) then
        return FILTER_NORMAL
    end

    return FILTER_NORMAL
end

ResolveZoneByCoords = function(normalizedX, normalizedY)
    if type(normalizedX) ~= "number" or type(normalizedY) ~= "number" then
        return nil
    end

    -- Retail prey map quadrants.
    if normalizedX > 0.70 then
        return "Harandar"
    end
    if normalizedX > 0.40 and normalizedY < 0.40 then
        return "Voidstorm"
    end
    if normalizedX > 0.40 and normalizedY > 0.55 then
        return "Zul'Aman"
    end

    return "Eversong Woods"
end

local function IsQuestInProgress(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.IsOnQuest) ~= "function" then
        return false
    end

    return Util.SafeCall(C_QuestLog.IsOnQuest, questID) == true
end

local function ResolveHuntRewardState(state, questID)
    local rewards = state.rewardCache[questID]
    if rewards == nil then
        if (state.attemptCount[questID] or 0) > 0 then
            return "retrying"
        end
        return "pending"
    end

    if #rewards == 0 then
        return "empty"
    end

    return "ready"
end

local function BuildQuestIDSet(hunts)
    local set = {}
    for _, hunt in ipairs(hunts) do
        set[hunt.questID] = true
    end
    return set
end

local function SnapshotRewardEntry(reward)
    if type(reward) ~= "table" then
        return nil
    end

    return {
        rewardIndex = reward.rewardIndex,
        tooltipType = reward.tooltipType,
        name = reward.name,
        texture = reward.texture,
        count = reward.count,
    }
end

local function SnapshotRewards(rewards)
    if type(rewards) ~= "table" then
        return nil
    end

    local copy = {}
    for index, reward in ipairs(rewards) do
        copy[index] = SnapshotRewardEntry(reward)
    end

    return copy
end

local function BuildHuntFromCacheEntry(questID, entry)
    if type(entry) ~= "table" then
        return nil
    end

    local cachedQuestID = tonumber(entry.questID) or tonumber(questID)
    if not cachedQuestID or cachedQuestID <= 0 then
        return nil
    end

    local difficulty = NormalizeFilter(entry.difficulty)
    if difficulty == FILTER_ALL then
        difficulty = FILTER_NORMAL
    end

    return {
        questID = cachedQuestID,
        name = type(entry.name) == "string" and entry.name or "",
        description = type(entry.description) == "string" and entry.description or "",
        difficulty = difficulty,
        zone = type(entry.zone) == "string" and entry.zone or nil,
    }
end

local function PersistHuntCacheEntry(hunt, rewards)
    if type(hunt) ~= "table" or type(hunt.questID) ~= "number" then
        return
    end

    local cache = GetCharacterHuntQuestCache()
    if type(cache) ~= "table" then
        return
    end

    cache[hunt.questID] = {
        questID = hunt.questID,
        name = type(hunt.name) == "string" and hunt.name or "",
        description = type(hunt.description) == "string" and hunt.description or "",
        difficulty = NormalizeFilter(hunt.difficulty),
        zone = hunt.zone,
        rewards = SnapshotRewards(rewards),
    }
end

local function RemoveHuntCacheEntry(questID)
    if type(questID) ~= "number" then
        return
    end

    local cache = GetCharacterHuntQuestCache()
    if type(cache) ~= "table" then
        return
    end

    cache[questID] = nil
end

local function LoadCachedHunts(state)
    if type(state) ~= "table" then
        return
    end

    local cache = GetCharacterHuntQuestCache()
    if type(cache) ~= "table" then
        return
    end

    for questID, entry in pairs(cache) do
        local hunt = BuildHuntFromCacheEntry(questID, entry)
        if hunt and not state.questIndex[hunt.questID] then
            state.hunts[#state.hunts + 1] = hunt
            state.questIndex[hunt.questID] = hunt
            state.rewardCache[hunt.questID] = SnapshotRewards(entry.rewards)
        end
    end
end

local function SnapshotDialogPoolRewards(dialog)
    if not dialog or type(dialog) ~= "table" then
        return {}
    end

    local rewardPool = dialog.rewardPool
    if not rewardPool or type(rewardPool.EnumerateActive) ~= "function" then
        return {}
    end

    local rewards = {}
    local rewardIndex = 0
    for reward in rewardPool:EnumerateActive() do
        rewardIndex = rewardIndex + 1

        local name
        if reward and reward.Name and type(reward.Name.GetText) == "function" then
            name = reward.Name:GetText()
        end

        local texture
        if reward and reward.Icon and type(reward.Icon.GetTexture) == "function" then
            texture = reward.Icon:GetTexture()
        end

        local count
        if reward and reward.Count and type(reward.Count.GetText) == "function" then
            local countText = reward.Count:GetText()
            if countText and countText ~= "" and countText ~= "1" then
                count = countText
            end
        end

        if type(name) == "string" and name ~= "" then
            rewards[#rewards + 1] = {
                rewardIndex = rewardIndex,
                tooltipType = "text",
                name = name,
                texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
                count = count,
            }
        end
    end

    return rewards
end

function HuntList:GetState()
    if not self.state then
        local storedFilter = FILTER_ALL
        if ns.Settings and ns.Settings.GetHuntPanelFilter then
            storedFilter = NormalizeFilter(ns.Settings:GetHuntPanelFilter())
        end

        self.state = {
            hunts = {},
            questIndex = {},
            filter = storedFilter,
            rewardCache = {},
            attemptCount = {},
            nextWarmupAt = 0,
            scanning = false,
            warming = false,
            stabilizeTicker = nil,
            cancelWarmup = nil,
        }

        LoadCachedHunts(self.state)
    end

    return self.state
end

function HuntList:GetDifficultyFilter()
    return self:GetState().filter
end

function HuntList:SetDifficultyFilter(filterValue)
    local state = self:GetState()
    state.filter = NormalizeFilter(filterValue)
    if ns.Settings and ns.Settings.SetHuntPanelFilter then
        ns.Settings:SetHuntPanelFilter(FILTER_TO_DB[state.filter] or "all")
    end
    return state.filter
end

function HuntList:GetFilter()
    return self:GetDifficultyFilter()
end

function HuntList:SetFilter(filterValue)
    return self:SetDifficultyFilter(filterValue)
end

function HuntList:IsScanActive()
    return self:GetState().scanning == true
end

function HuntList:IsWarmupActive()
    return self:GetState().warming == true
end

function HuntList:FindPin(questID)
    for _, pin in ipairs(CollectActiveQuestPins()) do
        if pin and pin.questID == questID then
            return pin
        end
    end

    return nil
end

function HuntList:GetHuntByQuestID(questID)
    local state = self:GetState()
    return state.questIndex[questID]
end

function HuntList:RemoveByQuestID(questID)
    local state = self:GetState()
    if not state.questIndex[questID] then return false end
    state.questIndex[questID] = nil
    state.rewardCache[questID] = nil
    state.attemptCount[questID] = nil
    RemoveHuntCacheEntry(questID)
    for i = #state.hunts, 1, -1 do
        if state.hunts[i].questID == questID then
            table.remove(state.hunts, i)
            break
        end
    end
    LogHunts("removeByQuestID", questID, #state.hunts)
    return true
end

function HuntList:HasAnyHunts()
    return #self:GetState().hunts > 0
end

local function BuildRawHuntsFromPins()
    local hunts = {}
    for _, pin in ipairs(CollectActiveQuestPins()) do
        hunts[#hunts + 1] = {
            questID = pin.questID,
            name = pin.title,
            description = pin.description,
            difficulty = ParseDifficulty(pin.description),
            zone = ResolveZoneByCoords(pin.normalizedX, pin.normalizedY),
        }
    end
    return hunts
end

local function DedupeHuntsByDifficultyAndZone(rawHunts)
    local deduped = {}
    local seen = {}
    for _, hunt in ipairs(rawHunts) do
        local key = string.format("%s:%s", hunt.difficulty or FILTER_NORMAL, hunt.zone or "")
        if not seen[key] then
            seen[key] = true
            deduped[#deduped + 1] = hunt
        end
    end
    return deduped
end

function HuntList:ApplyRefreshedHunts(refreshed, sourceTag)
    local state = self:GetState()
    local refreshedQuestIDs = BuildQuestIDSet(refreshed)

    local cacheWarm = #refreshed == #state.hunts
    if cacheWarm then
        for _, hunt in ipairs(state.hunts) do
            if not refreshedQuestIDs[hunt.questID] then
                cacheWarm = false
                break
            end
        end
    end

    if not cacheWarm then
        wipe(state.rewardCache)
        wipe(state.attemptCount)
    end

    wipe(state.hunts)
    wipe(state.questIndex)
    for _, hunt in ipairs(refreshed) do
        state.hunts[#state.hunts + 1] = hunt
        state.questIndex[hunt.questID] = hunt
        PersistHuntCacheEntry(hunt, state.rewardCache[hunt.questID])
    end

    LogHunts(sourceTag or "refreshPins", #state.hunts, cacheWarm and "cacheWarm" or "cacheReset")
    return cacheWarm, #state.hunts
end

function HuntList:RefreshFromPins()
    if self:HasAnyHunts() then
        LogHunts("refreshPins", "cacheHit", #self:GetState().hunts)
        return true
    end

    local blocked, source, subZoneText = self:IsScanBlockedBySubZone()
    if blocked then
        LogHunts("refreshPins", "blockedSubZone", string.format("source=%s,subZone=%s", tostring(source), tostring(subZoneText)))
        return true
    end

    local refreshed = DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins())
    local cacheWarm = self:ApplyRefreshedHunts(refreshed, "refreshPins")
    return cacheWarm
end

function HuntList:IsScanBlockedBySubZone()
    local subZoneText = GetCurrentSubZoneText()
    local blocked, source = IsBlockedSubZone(subZoneText)
    return blocked, source, subZoneText
end

function HuntList:QuickEvaluateAvailability(options)
    local allowCached = true
    if type(options) == "table" and options.allowCached == false then
        allowCached = false
    end

    local blocked = self:IsScanBlockedBySubZone()
    if blocked then
        return false, 0, "blockedSubZone"
    end

    local hasQuestContext = HasRelevantPreyQuestContext()
    if hasQuestContext then
        return true, 1, "questContext"
    end

    if allowCached and self:HasAnyHunts() then
        return true, #self:GetState().hunts, "cached"
    end

    local missionFrame = _G[MISSION_FRAME_NAME]
    if not (missionFrame and missionFrame:IsShown()) then
        return nil, 0, "mapHidden"
    end

    local refreshed = DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins())
    if #refreshed > 0 then
        return true, #refreshed, "pinSnapshot"
    end

    -- Map-visible empties can be transient while pin pools are still filling.
    -- Return indeterminate so callers can proceed with stabilized scanning.
    return nil, 0, "awaitingPins"
end

function HuntList:GetFilteredSortedHunts()
    local state = self:GetState()
    local zoneOrder = BuildZoneOrderLookup()
    local output = {}
    for _, hunt in ipairs(state.hunts) do
        if state.filter == FILTER_ALL or hunt.difficulty == state.filter then
            local inProgress = IsQuestInProgress(hunt.questID)
            local rewards = state.rewardCache[hunt.questID]
            local achievement = ns.HuntData and ns.HuntData.GetHuntAchievementStatus
                and ns.HuntData:GetHuntAchievementStatus(hunt.name, hunt.difficulty)
                or nil
            output[#output + 1] = {
                questID = hunt.questID,
                name = hunt.name,
                description = hunt.description,
                difficulty = hunt.difficulty,
                zone = hunt.zone,
                inProgress = inProgress,
                available = not inProgress,
                rewardState = ResolveHuntRewardState(state, hunt.questID),
                rewards = rewards,
                pin = self:FindPin(hunt.questID),
                achievement = achievement,
            }
        end
    end

    local isAllFilter = state.filter == FILTER_ALL

    table.sort(output, function(left, right)
        -- In "All" mode, group by zone first so region separators work
        if isAllFilter then
            local leftZone = zoneOrder[left.zone] or 99
            local rightZone = zoneOrder[right.zone] or 99
            if leftZone ~= rightZone then
                return leftZone < rightZone
            end
        end

        local leftDiff = DIFFICULTY_ORDER[left.difficulty] or 99
        local rightDiff = DIFFICULTY_ORDER[right.difficulty] or 99
        if leftDiff ~= rightDiff then
            return leftDiff < rightDiff
        end

        if not isAllFilter then
            local leftZone = zoneOrder[left.zone] or 99
            local rightZone = zoneOrder[right.zone] or 99
            if leftZone ~= rightZone then
                return leftZone < rightZone
            end
        end

        local leftStatus = left.inProgress and 0 or 1
        local rightStatus = right.inProgress and 0 or 1
        if leftStatus ~= rightStatus then
            return leftStatus < rightStatus
        end

        return (left.name or "") < (right.name or "")
    end)

    return output
end

function HuntList:CancelWarmup()
    local state = self:GetState()
    if state.stabilizeTicker then
        state.stabilizeTicker:Cancel()
        state.stabilizeTicker = nil
    end
    if state.cancelWarmup then
        state.cancelWarmup()
        state.cancelWarmup = nil
    end

    state.scanning = false
    state.warming = false
end

function HuntList:ResetCachedHuntsForRescan()
    local state = self:GetState()

    self:CancelWarmup()

    wipe(state.hunts)
    wipe(state.questIndex)
    wipe(state.rewardCache)
    wipe(state.attemptCount)
    state.nextWarmupAt = 0

    local cache = GetCharacterHuntQuestCache()
    if type(cache) == "table" then
        wipe(cache)
    end

    LogHunts("resetCache", "cleared", 0)
end

function HuntList:BeginStabilizedScan(onReady)
    local state = self:GetState()
    if state.stabilizeTicker then
        state.stabilizeTicker:Cancel()
        state.stabilizeTicker = nil
    end

    state.scanning = true

    if self:HasAnyHunts() then
        state.scanning = false
        LogHunts("scanSkip", #state.hunts, "cacheHit")
        if type(onReady) == "function" then
            onReady(true, #state.hunts)
        end
        return
    end

    local blocked, source, subZoneText = self:IsScanBlockedBySubZone()
    if blocked then
        state.scanning = false
        LogHunts("scanSkip", 0, string.format("blockedSubZone:%s:%s", tostring(source), tostring(subZoneText)))
        if type(onReady) == "function" then
            onReady(true, #state.hunts)
        end
        return
    end

    local function Finish(cacheWarm, huntCount, reason)
        if state.stabilizeTicker then
            state.stabilizeTicker:Cancel()
            state.stabilizeTicker = nil
        end

        state.scanning = false
        LogHunts("scanFinish", huntCount or 0, reason or "complete")
        if type(onReady) == "function" then
            onReady(cacheWarm, huntCount)
        end
    end

    if type(C_Timer) ~= "table" or type(C_Timer.NewTicker) ~= "function" then
        local cacheWarm, huntCount = self:ApplyRefreshedHunts(
            DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins()),
            "scanImmediate"
        )
        Finish(cacheWarm, huntCount, "noTicker")
        return
    end

    local missionFrame = _G[MISSION_FRAME_NAME]
    if not (missionFrame and missionFrame:IsShown()) then
        local cacheWarm, huntCount = self:ApplyRefreshedHunts(
            DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins()),
            "scanMapHidden"
        )
        Finish(cacheWarm, huntCount, "mapHidden")
        return
    end

    -- PreyTracker-style pin-count polling:
    -- Poll until the pin pool count is > 0 and identical for PIN_STABLE_READS
    -- consecutive reads, or until PIN_MAX_WAIT_SECONDS elapses.
    -- Only then build the hunt list, so transient title/pin delays are resolved.
    local elapsed = 0
    local lastCount = -1
    local stableN = 0

    state.stabilizeTicker = C_Timer.NewTicker(PIN_POLL_SECONDS, function()
        if not (missionFrame and missionFrame:IsShown()) then
            local cacheWarm, huntCount = self:ApplyRefreshedHunts(
                DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins()),
                "scanMapClosed"
            )
            Finish(cacheWarm, huntCount, "mapClosed")
            return
        end

        elapsed = elapsed + PIN_POLL_SECONDS
        local n = CountPins()

        if n > 0 and n == lastCount then
            stableN = stableN + 1
            if stableN >= PIN_STABLE_READS then
                local snapshot = DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins())
                LogHunts("scanStable", n, string.format("elapsed=%.2f,hunts=%d", elapsed, #snapshot))
                local cacheWarm, huntCount = self:ApplyRefreshedHunts(snapshot, "scanStableSnapshot")
                Finish(cacheWarm, huntCount, "stableSnapshot")
                return
            end
        else
            stableN = 0
            lastCount = n
        end

        if elapsed >= PIN_MAX_WAIT_SECONDS then
            local snapshot = DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins())
            LogHunts("scanTimeout", n, string.format("elapsed=%.2f,hunts=%d", elapsed, #snapshot))
            local cacheWarm, huntCount = self:ApplyRefreshedHunts(snapshot, "scanTimeoutSnapshot")
            Finish(cacheWarm, huntCount, "timeout")
        end
    end)
end

function HuntList:WarmRewardCacheAsync(onProgress, onDone, questIDs)
    local state = self:GetState()

    local blocked, source, subZoneText = self:IsScanBlockedBySubZone()
    if blocked then
        LogHunts("warmupSkip", "blockedSubZone", string.format("source=%s,subZone=%s", tostring(source), tostring(subZoneText)))
        if type(onDone) == "function" then
            onDone()
        end
        return
    end

    if state.warming then
        LogHunts("warmupSkip", "alreadyWarming", nil)
        return
    end

    local dialog = GetQuestChoiceDialog()
    if not (dialog and type(dialog.ShowWithQuest) == "function") then
        LogHunts("warmupSkip", "dialogUnavailable", nil)
        if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
            C_Timer.After(0.4, function() self:WarmRewardCacheAsync(onProgress, onDone, questIDs) end)
        elseif type(onDone) == "function" then
            onDone()
        end
        return
    end

    -- Build queue: only quests not yet cached
    local allowedQuestIDs = nil
    if type(questIDs) == "table" and #questIDs > 0 then
        allowedQuestIDs = {}
        for _, qid in ipairs(questIDs) do
            if type(qid) == "number" and qid > 0 then
                allowedQuestIDs[qid] = true
            end
        end
    end

    local queue = {}
    for _, hunt in ipairs(state.hunts) do
        local qid = hunt.questID
        if allowedQuestIDs and not allowedQuestIDs[qid] then
            -- skip, not in target list
        elseif state.rewardCache[qid] == nil then
            queue[#queue + 1] = hunt
        end
    end

    local total = #state.hunts
    local doneCount = total - #queue

    if #queue == 0 then
        if type(onDone) == "function" then onDone() end
        return
    end

    LogHunts("warmupStart", #queue, string.format("total=%d", total))

    state.warming = true
    local prevAlpha = dialog:GetAlpha()
    local cancelled = false
    local ticker = nil
    local qIdx = 1
    local elapsed = 0
    local lastCount = -1
    local stableN = 0

    state.cancelWarmup = function()
        cancelled = true
        if ticker then ticker:Cancel(); ticker = nil end
        dialog:Hide()
        dialog:SetAlpha(prevAlpha)
        state.cancelWarmup = nil
    end

    local StartNext

    local function CommitAndAdvance(rewards, timedOutEmpty)
        if ticker then ticker:Cancel(); ticker = nil end
        dialog:Hide()
        dialog:SetAlpha(prevAlpha)

        local questID = queue[qIdx].questID
        if timedOutEmpty then
            state.attemptCount[questID] = (state.attemptCount[questID] or 0) + 1
            if state.attemptCount[questID] >= WARMUP_MAX_EMPTY_ATTEMPTS then
                state.rewardCache[questID] = {}
                PersistHuntCacheEntry(queue[qIdx], state.rewardCache[questID])
                LogHunts("warmupCommit", questID, string.format("timedOutEmpty:accepted attempts=%d", state.attemptCount[questID]))
            else
                state.rewardCache[questID] = nil
                LogHunts("warmupCommit", questID, string.format("timedOutEmpty:retry attempts=%d", state.attemptCount[questID]))
            end
        else
            state.rewardCache[questID] = rewards
            state.attemptCount[questID] = nil
            PersistHuntCacheEntry(queue[qIdx], state.rewardCache[questID])
            LogHunts("warmupCommit", questID, string.format("ready rewards=%d", #rewards))
        end

        doneCount = doneCount + 1
        if type(onProgress) == "function" then onProgress(doneCount, total) end

        qIdx = qIdx + 1
        if qIdx > #queue then
            state.warming = false
            state.cancelWarmup = nil
            state.nextWarmupAt = ((type(GetTime) == "function" and GetTime()) or 0) + WARMUP_PASS_COOLDOWN_SECONDS
            LogHunts("warmupFinish", doneCount, string.format("cooldown=%.2f", WARMUP_PASS_COOLDOWN_SECONDS))
            if type(onDone) == "function" then onDone() end
            return
        end

        if type(C_Timer.After) == "function" then
            C_Timer.After(0.05, function()
                if not cancelled then StartNext() end
            end)
        elseif not cancelled then
            StartNext()
        end
    end

    StartNext = function()
        if cancelled then return end
        elapsed = 0
        lastCount = -1
        stableN = 0

        local hunt = queue[qIdx]
        local pin = self:FindPin(hunt.questID)
        if not pin then
            LogHunts("warmupQuest", hunt.questID, "noPin")
            CommitAndAdvance({}, false)
            return
        end

        LogHunts("warmupQuest", hunt.questID, "showWithQuest")
        dialog:SetAlpha(0)
        dialog:Hide()
        dialog:ShowWithQuest(_G[MISSION_FRAME_NAME] or UIParent, pin, hunt.questID)

        ticker = C_Timer.NewTicker(WARMUP_POLL_SECONDS, function()
            if cancelled then return end
            elapsed = elapsed + WARMUP_POLL_SECONDS

            local rewards = SnapshotDialogPoolRewards(dialog)
            local n = #rewards

            if n > 0 and n == lastCount then
                stableN = stableN + 1
                if stableN >= WARMUP_STABLE_READS then
                    LogHunts("warmupQuest", hunt.questID, string.format("complete elapsed=%.2f,rewards=%d,stableReads=%d", elapsed, n, stableN))
                    CommitAndAdvance(rewards, false)
                    return
                end
            else
                stableN = 0
                lastCount = n
            end

            if elapsed >= WARMUP_TIMEOUT_SECONDS then
                LogHunts("warmupQuest", hunt.questID, string.format("timeout elapsed=%.2f,rewards=%d", elapsed, n))
                CommitAndAdvance(rewards, n == 0)
            end
        end)
    end

    if type(onProgress) == "function" then onProgress(doneCount, total) end
    StartNext()
end
