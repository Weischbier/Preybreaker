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

local PIN_POOL_NAME = "AdventureMap_QuestOfferPinTemplate"
local FILTER_ALL = "All"
local FILTER_NIGHTMARE = "Nightmare"
local FILTER_HARD = "Hard"
local FILTER_NORMAL = "Normal"
local SCAN_SAMPLE_INTERVAL_SECONDS = 0.16
local SCAN_MIN_SAMPLE_SECONDS = 0.32
local SCAN_TIMEOUT_SECONDS = 2.25
local SCAN_STABLE_FINGERPRINT_READS = 1
local WARMUP_POLL_SECONDS = 0.10
local WARMUP_STABLE_READS = 3
local WARMUP_TIMEOUT_SECONDS = 4
local WARMUP_MAX_EMPTY_ATTEMPTS = 3

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

local function NormalizeFilter(filterValue)
    if type(filterValue) ~= "string" then
        return FILTER_ALL
    end

    if FILTER_TO_DB[filterValue] then
        return filterValue
    end

    return DB_TO_FILTER[strlower(filterValue)] or FILTER_ALL
end

local function BuildZoneOrderLookup()
    local lookup = {}
    local zones = Constants and Constants.Hunt and Constants.Hunt.Zones or nil
    if type(zones) ~= "table" then
        return lookup
    end

    for index, zoneName in ipairs(zones) do
        lookup[zoneName] = index
    end

    return lookup
end

local function GetQuestChoiceDialog()
    if _G.AdventureMapQuestChoiceDialog then
        return _G.AdventureMapQuestChoiceDialog
    end

    if type(C_AddOns) == "table" and type(C_AddOns.LoadAddOn) == "function" then
        Util.SafeCall(C_AddOns.LoadAddOn, "Blizzard_AdventureMap")
    end

    return _G.AdventureMapQuestChoiceDialog
end

local function GetPinPool()
    local missionFrame = _G.CovenantMissionFrame
    local mapTab = missionFrame and missionFrame.MapTab or nil
    local pools = mapTab and mapTab.pinPools or nil
    if type(pools) ~= "table" then
        return nil
    end

    return pools[PIN_POOL_NAME]
end

local function ParseDifficulty(descriptionText)
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

local function ResolveZoneByCoords(normalizedX, normalizedY)
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

local function BuildRewardEntry(choiceIndex)
    local questInfoType = "choice"
    local lootType = type(GetQuestItemInfoLootType) == "function" and GetQuestItemInfoLootType(questInfoType, choiceIndex) or nil
    local name, texture, quantity, _, _, itemID = nil, nil, nil, nil, nil, nil

    if type(GetQuestItemInfo) == "function" then
        name, texture, quantity, _, _, itemID = GetQuestItemInfo(questInfoType, choiceIndex)
    end

    local currencyInfo = nil
    if type(C_QuestOffer) == "table" and type(C_QuestOffer.GetQuestRewardCurrencyInfo) == "function" then
        currencyInfo = Util.SafeCall(C_QuestOffer.GetQuestRewardCurrencyInfo, questInfoType, choiceIndex)
    end

    if type(currencyInfo) == "table" and currencyInfo.currencyID then
        return {
            rewardIndex = choiceIndex,
            questInfoType = questInfoType,
            tooltipType = "currency",
            currencyID = currencyInfo.currencyID,
            name = currencyInfo.name or name,
            texture = currencyInfo.texture or texture or "Interface\\Icons\\INV_Misc_QuestionMark",
            count = (currencyInfo.quantity and currencyInfo.quantity > 1) and currencyInfo.quantity or nil,
            lootType = lootType,
        }
    end

    if not name or name == "" then
        return nil
    end

    return {
        rewardIndex = choiceIndex,
        questInfoType = questInfoType,
        tooltipType = "item",
        itemID = itemID,
        name = name,
        texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        count = (quantity and quantity > 1) and quantity or nil,
        lootType = lootType,
    }
end

local function SnapshotChoiceRewards()
    local rewards = {}
    local numChoices = type(GetNumQuestChoices) == "function" and GetNumQuestChoices() or 0
    for choiceIndex = 1, numChoices do
        local entry = BuildRewardEntry(choiceIndex)
        if entry then
            rewards[#rewards + 1] = entry
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
            scanning = false,
            warming = false,
            stabilizeTicker = nil,
            warmupTicker = nil,
            cancelWarmup = nil,
        }
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
    local pool = GetPinPool()
    if not pool or type(pool.EnumerateActive) ~= "function" then
        return nil
    end

    for pin in pool:EnumerateActive() do
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

function HuntList:HasAnyHunts()
    return #self:GetState().hunts > 0
end

local function BuildRawHuntsFromPins()
    local pool = GetPinPool()
    if not pool or type(pool.EnumerateActive) ~= "function" then
        return {}
    end

    local hunts = {}
    for pin in pool:EnumerateActive() do
        local questID = pin and pin.questID or nil
        local title = pin and pin.title or nil
        if questID and type(title) == "string" and title ~= "" then
            hunts[#hunts + 1] = {
                questID = questID,
                name = title,
                difficulty = ParseDifficulty(pin.description),
                zone = ResolveZoneByCoords(pin.normalizedX, pin.normalizedY),
            }
        end
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

local function BuildScanFingerprint(hunts)
    if type(hunts) ~= "table" or #hunts == 0 then
        return ""
    end

    local tokens = {}
    for _, hunt in ipairs(hunts) do
        tokens[#tokens + 1] = string.format(
            "%s:%s:%s:%s",
            tostring(hunt.questID or 0),
            tostring(hunt.difficulty or ""),
            tostring(hunt.zone or ""),
            tostring(hunt.name or "")
        )
    end

    table.sort(tokens)
    return table.concat(tokens, "|")
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
    end

    LogHunts(sourceTag or "refreshPins", #state.hunts, cacheWarm and "cacheWarm" or "cacheReset")
    return cacheWarm, #state.hunts
end

function HuntList:RefreshFromPins()
    local refreshed = DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins())
    local cacheWarm = self:ApplyRefreshedHunts(refreshed, "refreshPins")
    return cacheWarm
end

function HuntList:QuickEvaluateAvailability()
    if self:HasAnyHunts() then
        return true, #self:GetState().hunts, "cached"
    end

    local missionFrame = _G.CovenantMissionFrame
    if not (missionFrame and missionFrame:IsShown()) then
        return nil, 0, "mapHidden"
    end

    local refreshed = DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins())
    if #refreshed > 0 then
        return true, #refreshed, "pinSnapshot"
    end

    if type(C_QuestLog) == "table" and type(C_QuestLog.GetActivePreyQuest) == "function" then
        local activeQuestID = Util.SafeCall(C_QuestLog.GetActivePreyQuest)
        if type(activeQuestID) == "number" and activeQuestID > 0 then
            return true, 1, "activePreyQuest"
        end
    end

    return false, 0, "emptyMap"
end

function HuntList:GetFilteredSortedHunts()
    local state = self:GetState()
    local zoneOrder = BuildZoneOrderLookup()
    local output = {}
    for _, hunt in ipairs(state.hunts) do
        if state.filter == FILTER_ALL or hunt.difficulty == state.filter then
            local inProgress = IsQuestInProgress(hunt.questID)
            local rewards = state.rewardCache[hunt.questID]
            output[#output + 1] = {
                questID = hunt.questID,
                name = hunt.name,
                difficulty = hunt.difficulty,
                zone = hunt.zone,
                inProgress = inProgress,
                available = not inProgress,
                rewardState = ResolveHuntRewardState(state, hunt.questID),
                rewards = rewards,
                pin = self:FindPin(hunt.questID),
            }
        end
    end

    table.sort(output, function(left, right)
        local leftDiff = DIFFICULTY_ORDER[left.difficulty] or 99
        local rightDiff = DIFFICULTY_ORDER[right.difficulty] or 99
        if leftDiff ~= rightDiff then
            return leftDiff < rightDiff
        end

        local leftZone = zoneOrder[left.zone] or 99
        local rightZone = zoneOrder[right.zone] or 99
        if leftZone ~= rightZone then
            return leftZone < rightZone
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
    if state.warmupTicker then
        state.warmupTicker:Cancel()
        state.warmupTicker = nil
    end
    if state.cancelWarmup then
        state.cancelWarmup()
        state.cancelWarmup = nil
    end

    state.scanning = false
    state.warming = false
end

function HuntList:BeginStabilizedScan(onReady)
    local state = self:GetState()
    if state.stabilizeTicker then
        state.stabilizeTicker:Cancel()
        state.stabilizeTicker = nil
    end

    state.scanning = true

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

    local missionFrame = _G.CovenantMissionFrame
    if not (missionFrame and missionFrame:IsShown()) then
        local cacheWarm, huntCount = self:ApplyRefreshedHunts(
            DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins()),
            "scanMapHidden"
        )
        Finish(cacheWarm, huntCount, "mapHidden")
        return
    end

    local elapsed = 0
    local previousFingerprint = nil
    local stableReads = 0
    local bestSnapshot = {}
    local bestCount = -1

    state.stabilizeTicker = C_Timer.NewTicker(SCAN_SAMPLE_INTERVAL_SECONDS, function()
        if not (missionFrame and missionFrame:IsShown()) then
            local cacheWarm, huntCount = self:ApplyRefreshedHunts(bestSnapshot, "scanMapClosed")
            Finish(cacheWarm, huntCount, "mapClosed")
            return
        end

        elapsed = elapsed + SCAN_SAMPLE_INTERVAL_SECONDS
        local snapshot = DedupeHuntsByDifficultyAndZone(BuildRawHuntsFromPins())
        local snapshotCount = #snapshot
        local fingerprint = BuildScanFingerprint(snapshot)

        if snapshotCount > bestCount then
            bestCount = snapshotCount
            bestSnapshot = snapshot
        end

        if fingerprint ~= "" and fingerprint == previousFingerprint then
            stableReads = stableReads + 1
        else
            previousFingerprint = fingerprint
            stableReads = 0
        end

        local sampledEnough = elapsed >= SCAN_MIN_SAMPLE_SECONDS
        local stableSnapshot = sampledEnough and stableReads >= SCAN_STABLE_FINGERPRINT_READS
        local timedOut = elapsed >= SCAN_TIMEOUT_SECONDS
        if stableSnapshot or timedOut then
            local finalSnapshot = snapshotCount >= bestCount and snapshot or bestSnapshot
            local cacheWarm, huntCount = self:ApplyRefreshedHunts(
                finalSnapshot,
                stableSnapshot and "scanStableSnapshot" or "scanTimeoutSnapshot"
            )
            Finish(cacheWarm, huntCount, stableSnapshot and "stableSnapshot" or "timeout")
        end
    end)
end

function HuntList:WarmRewardCacheAsync(onProgress, onDone)
    local state = self:GetState()
    if state.warming then
        return
    end

    local dialog = GetQuestChoiceDialog()
    if not (dialog and type(dialog.ShowWithQuest) == "function" and type(C_Timer) == "table" and type(C_Timer.NewTicker) == "function") then
        if type(onDone) == "function" then
            onDone()
        end
        return
    end

    local queue = {}
    for _, hunt in ipairs(state.hunts) do
        if state.rewardCache[hunt.questID] == nil then
            queue[#queue + 1] = hunt.questID
        end
    end

    local total = #state.hunts
    local done = total - #queue
    if type(onProgress) == "function" then
        onProgress(done, total, nil)
    end

    if #queue == 0 then
        if type(onDone) == "function" then
            onDone()
        end
        return
    end

    state.warming = true
    local missionFrame = _G.CovenantMissionFrame or UIParent
    local queueIndex = 1
    local cancelled = false
    local originalAlpha = dialog:GetAlpha() or 1

    local function RestoreDialog()
        dialog:Hide()
        dialog:SetAlpha(originalAlpha)
    end

    local function Finish()
        if state.warmupTicker then
            state.warmupTicker:Cancel()
            state.warmupTicker = nil
        end
        state.cancelWarmup = nil
        state.warming = false
        RestoreDialog()
        if type(onDone) == "function" then
            onDone()
        end
    end

    state.cancelWarmup = function()
        cancelled = true
        if state.warmupTicker then
            state.warmupTicker:Cancel()
            state.warmupTicker = nil
        end
        RestoreDialog()
    end

    local function CommitQuest(questID, rewards, timedOutEmpty)
        if timedOutEmpty then
            local attempts = (state.attemptCount[questID] or 0) + 1
            state.attemptCount[questID] = attempts
            if attempts >= WARMUP_MAX_EMPTY_ATTEMPTS then
                state.rewardCache[questID] = {}
            else
                state.rewardCache[questID] = nil
            end
        else
            state.attemptCount[questID] = nil
            state.rewardCache[questID] = rewards
        end

        done = done + 1
        if type(onProgress) == "function" then
            onProgress(done, total, self:GetHuntByQuestID(questID))
        end
    end

    local function ProcessNext()
        if cancelled then
            Finish()
            return
        end

        local questID = queue[queueIndex]
        if not questID then
            Finish()
            return
        end

        local pin = self:FindPin(questID)
        if not pin then
            CommitQuest(questID, {}, false)
            queueIndex = queueIndex + 1
            ProcessNext()
            return
        end

        dialog:SetAlpha(0)
        dialog:Hide()
        dialog:ShowWithQuest(missionFrame, pin, questID)

        local elapsed = 0
        local previousCount = -1
        local stableReads = 0
        state.warmupTicker = C_Timer.NewTicker(WARMUP_POLL_SECONDS, function(ticker)
            if cancelled then
                ticker:Cancel()
                state.warmupTicker = nil
                Finish()
                return
            end

            elapsed = elapsed + WARMUP_POLL_SECONDS
            local rewards = SnapshotChoiceRewards()
            local rewardCount = #rewards
            if rewardCount > 0 and rewardCount == previousCount then
                stableReads = stableReads + 1
            else
                previousCount = rewardCount
                stableReads = 0
            end

            if stableReads >= WARMUP_STABLE_READS or elapsed >= WARMUP_TIMEOUT_SECONDS then
                ticker:Cancel()
                state.warmupTicker = nil

                local timedOutEmpty = elapsed >= WARMUP_TIMEOUT_SECONDS and rewardCount == 0
                CommitQuest(questID, rewards, timedOutEmpty)
                queueIndex = queueIndex + 1
                if type(C_Timer.After) == "function" then
                    C_Timer.After(0.05, ProcessNext)
                else
                    ProcessNext()
                end
            end
        end)
    end

    ProcessNext()
end
