local function wipe(tableRef)
    for key in pairs(tableRef) do
        tableRef[key] = nil
    end
    return tableRef
end

_G.wipe = _G.wipe or wipe
_G.strlower = _G.strlower or string.lower

if not _G.strsplit then
    function _G.strsplit(delimiter, input)
        if type(input) ~= "string" then
            return nil
        end

        local fields = {}
        local pattern = string.format("([^%s]+)", delimiter)
        for field in string.gmatch(input, pattern) do
            fields[#fields + 1] = field
        end

        return unpack(fields)
    end
end

local function safeCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end
    local ok, a, b, c, d, e = pcall(func, ...)
    if not ok then
        return nil
    end
    return a, b, c, d, e
end

local function newNamespace()
    return {
        Util = {
            SafeCall = safeCall,
            IsWorldQuest = function() return false end,
            IsRelevantPreyQuest = function() return false end,
            IsQuestComplete = function() return false end,
            IsQuestActive = function() return true end,
            IsTaskQuestActive = function() return false end,
            BuildPreyQuestContext = function() return { trackedQuestID = nil } end,
            InvalidatePreyQuestContextCache = function() end,
            TextContainsAny = function(text, patterns)
                if type(text) ~= "string" then return false end
                local lower = text:lower()
                for _, pattern in ipairs(patterns or {}) do
                    if text:find(pattern, 1, true) then return true end
                    if lower:find(pattern:lower(), 1, true) then return true end
                end
                return false
            end,
            ExtractNPCIDFromGUID = function(guid)
                if type(guid) ~= "string" then return nil end
                local npcID = guid:match("Creature%-.-%-.-%-.-%-.-%-(%d+)%-")
                return npcID and tonumber(npcID) or nil
            end,
            GetLocalizedSpellName = function(spellID)
                if type(_G.GetSpellInfo) == "function" then return _G.GetSpellInfo(spellID) end
                return nil
            end,
        },
        Debug = {
            Log = function() end,
            KV = function(_, _, value) return tostring(value) end,
        },
        Constants = {
            Hunt = {
                RewardPatterns = {
                    dawncrest = { "dawncrest", "crest" },
                    remnant = { "remnant", "anguish" },
                    gold = { "gold", "coin" },
                    marl = { "marl", "voidlight" },
                },
                DawncrestCurrencyIDs = { 3391, 3341 },
                DifficultyPatterns = {
                    normal = { "normal" },
                    hard = { "hard" },
                    nightmare = { "nightmare" },
                },
                RandomPatterns = { "random" },
                RemnantCurrencyID = 3392,
                Cost = 50,
                AstalorNpcID = 253513,
                Zones = { "Eversong Woods", "Zul'Aman", "Harandar", "Voidstorm" },
            },
        },
        Settings = {},
    }
end

local function loadModule(path, ns)
    local chunk, err = loadfile(path)
    if not chunk then
        error(err)
    end
    chunk("Preybreaker", ns)
end

local failures = {}

local function expectEqual(label, left, right)
    if left ~= right then
        failures[#failures + 1] = string.format("%s: expected %s, got %s", label, tostring(right), tostring(left))
    end
end

local function expectTrue(label, value)
    if value ~= true then
        failures[#failures + 1] = string.format("%s: expected true, got %s", label, tostring(value))
    end
end

local function expectNotNil(label, value)
    if value == nil then
        failures[#failures + 1] = string.format("%s: expected non-nil value", label)
    end
end

local function expectNil(label, value)
    if value ~= nil then
        failures[#failures + 1] = string.format("%s: expected nil, got %s", label, tostring(value))
    end
end

local function runQuestTrackingResolverTests()
    local ns = newNamespace()
    loadModule("Core/QuestTracking.lua", ns)

    local tracking = ns.QuestTracking
    expectNotNil("questTracking module", tracking)

    local choicesBasic = {
        { index = 1, itemName = "Remnant of Anguish" },
        { index = 2, itemName = "Gold Cache" },
    }
    expectEqual(
        "resolver chooses preferred remnant",
        tracking:ResolvePreferredRewardChoice(choicesBasic, "remnant", "gold"),
        1
    )

    local dawncrestCapped = {
        { index = 1, itemName = "Hero Dawncrest", currencyID = 3391, isCapped = true },
        { index = 2, itemName = "Gold Cache" },
    }
    expectEqual(
        "resolver falls back when dawncrest capped",
        tracking:ResolvePreferredRewardChoice(dawncrestCapped, "dawncrest", "gold"),
        2
    )

    local noFallback = {
        { index = 1, itemName = "Hero Dawncrest", currencyID = 3391, isCapped = true },
    }
    expectEqual(
        "resolver keeps preferred when fallback unavailable",
        tracking:ResolvePreferredRewardChoice(noFallback, "dawncrest", "gold"),
        1
    )
end

local function runHuntPurchaseStateMachineTests()
    local ns = newNamespace()
    ns.Settings = {
        ShouldAutoPurchaseRandomHunt = function() return true end,
        GetRandomHuntDifficulty = function() return "nightmare" end,
        GetRemnantThreshold = function() return 0 end,
    }

    local selectedAvailableQuest = nil
    local selectedOptionID = nil
    local selectedOptionConfirmed = nil
    local acknowledgedAutoAccept = 0
    local acceptedQuest = 0

    _G.UnitGUID = function()
        return "Creature-0-0-0-0-253513-0000000000"
    end
    _G.C_CurrencyInfo = {
        GetCurrencyInfo = function()
            return { quantity = 500 }
        end,
    }
    _G.C_GossipInfo = {
        GetAvailableQuests = function()
            return {
                { questID = 94001, title = "Nightmare Random Hunt" },
            }
        end,
        SelectAvailableQuest = function(questID)
            selectedAvailableQuest = questID
        end,
        GetOptions = function()
            return {
                { gossipOptionID = 77, name = "Nightmare random prey hunt" },
            }
        end,
        SelectOption = function(optionID, _, confirmed)
            selectedOptionID = optionID
            selectedOptionConfirmed = confirmed
        end,
    }
    _G.QuestGetAutoAccept = function()
        return true
    end
    _G.AcknowledgeAutoAcceptQuest = function()
        acknowledgedAutoAccept = acknowledgedAutoAccept + 1
    end
    _G.AcceptQuest = function()
        acceptedQuest = acceptedQuest + 1
    end

    loadModule("Core/HuntPurchase.lua", ns)
    local purchase = ns.HuntPurchase
    expectNotNil("huntPurchase module", purchase)

    purchase:HandleGossipShow()
    expectEqual("available quest path selects questID", selectedAvailableQuest, 94001)
    expectEqual("available quest path skips option selection", selectedOptionID, nil)

    purchase:HandleQuestDetail()
    expectEqual("quest detail auto-accept path", acknowledgedAutoAccept, 1)

    purchase:ResetState("test")
    _G.C_GossipInfo.GetAvailableQuests = function()
        return {}
    end
    selectedOptionID = nil
    selectedOptionConfirmed = nil
    purchase:HandleGossipShow()
    expectEqual("option path selected gossip option", selectedOptionID, 77)
    expectEqual("option path uses confirmed select", selectedOptionConfirmed, true)

    purchase:BeginState("nightmare")
    _G.QuestGetAutoAccept = function()
        return false
    end
    purchase:HandleQuestDetail()
    expectEqual("quest detail accept fallback path", acceptedQuest, 1)

    -- DialogueUI-style flow can lose UnitGUID("npc"), so matching options/quests
    -- should still allow automation when the text path is strong enough.
    _G.UnitGUID = function()
        return nil
    end
    _G.C_GossipInfo.GetAvailableQuests = function()
        return {
            { questID = 94002, title = "Nightmare Random Hunt" },
        }
    end
    selectedAvailableQuest = nil
    purchase:HandleGossipShow()
    expectEqual("dialogueUI path selects available quest without npc guid", selectedAvailableQuest, 94002)

    -- Weak fallbacks must not trigger when npc guid is unavailable.
    _G.C_GossipInfo.GetAvailableQuests = function()
        return {
            { questID = 95000, title = "Unrelated quest" },
        }
    end
    _G.C_GossipInfo.GetOptions = function()
        return {
            { orderIndex = 1, name = "Option One" },
        }
    end
    selectedAvailableQuest = nil
    purchase:HandleGossipShow()
    expectEqual("dialogueUI weak fallback does not auto-select", selectedAvailableQuest, nil)

    -- Option path without QUEST_DETAIL should still try accept on GOSSIP_CLOSED
    -- when quest-offer context exists (DialogueUI-style flow).
    _G.UnitGUID = function()
        return nil
    end
    _G.C_GossipInfo.GetAvailableQuests = function()
        return {}
    end
    _G.C_GossipInfo.GetOptions = function()
        return {
            { gossipOptionID = 99, name = "Random Hunt" },
            { gossipOptionID = 100, name = "Normal" },
        }
    end
    local fallbackAcceptCalls = 0
    _G.GetQuestID = function()
        return 94003
    end
    _G.GetTitleText = function()
        return "Random Hunt Offer"
    end
    _G.AcceptQuest = function()
        fallbackAcceptCalls = fallbackAcceptCalls + 1
    end

    purchase:HandleGossipShow()
    purchase:HandleGossipClosed(false)
    expectEqual("gossipClosed accept fallback invoked", fallbackAcceptCalls, 1)

    -- Confirmation-required gossip should be handled explicitly.
    selectedOptionID = nil
    selectedOptionConfirmed = nil
    _G.UnitGUID = function()
        return "Creature-0-0-0-0-253513-0000000000"
    end
    _G.C_GossipInfo.GetOptions = function()
        return {
            { gossipOptionID = 200, name = "Random Hunt Normal" },
        }
    end
    purchase:HandleGossipShow()
    purchase:HandleGossipConfirm(200, "Confirm purchase", 50)
    expectEqual("gossip confirm path selects option id", selectedOptionID, 200)
    expectEqual("gossip confirm path uses confirmed flag", selectedOptionConfirmed, true)
end

local function makePinPool(pins)
    return {
        EnumerateActive = function()
            local index = 0
            return function()
                index = index + 1
                return pins[index]
            end
        end,
    }
end

local function runHuntListDedupeSortFilterTests()
    local ns = newNamespace()
    ns.Settings = {
        GetHuntPanelFilter = function()
            return "all"
        end,
        SetHuntPanelFilter = function()
        end,
    }

    local inProgressQuestIDs = {
        [2] = true,
    }
    _G.C_QuestLog = {
        IsOnQuest = function(questID)
            return inProgressQuestIDs[questID] == true
        end,
    }
    local function MockGetAchievementInfo(achievementID)
        if achievementID == 42701 then
            return 42701, "Prey: Normal Mode III", 10, false, nil, nil, nil, "Normal prey achievement.", nil, 134414, nil, false, false, nil, false
        elseif achievementID == 42702 then
            return 42702, "Prey: Hard Mode III", 10, true, nil, nil, nil, "Hard prey achievement.", nil, 134414, nil, false, true, nil, false
        elseif achievementID == 42703 then
            return 42703, "Prey: Nightmare Mode III", 10, false, nil, nil, nil, "Nightmare prey achievement.", nil, 134400, nil, false, false, nil, false
        end

        return nil
    end
    local function MockGetAchievementNumCriteria(achievementID)
        if achievementID == 42701 then
            return 2
        elseif achievementID == 42702 then
            return 1
        elseif achievementID == 42703 then
            return 2
        end

        return 0
    end
    local function MockGetAchievementCriteriaInfo(achievementID, criteriaIndex)
        if achievementID == 42701 then
            if criteriaIndex == 1 then
                return "Thornspeaker Edgath", nil, true
            elseif criteriaIndex == 2 then
                return "Lamyne of the Undercroft", nil, false
            end
        elseif achievementID == 42702 then
            if criteriaIndex == 1 then
                return "Zadu, Fist of Nalorakk", nil, true
            end
        elseif achievementID == 42703 then
            if criteriaIndex == 1 then
                return "Knight-Errant Bloodshatter", nil, false
            elseif criteriaIndex == 2 then
                return "The Wing of Akil'zon", nil, true
            end
        end

        return nil, nil, false
    end
    _G.GetAchievementInfo = MockGetAchievementInfo
    _G.GetAchievementNumCriteria = MockGetAchievementNumCriteria
    _G.GetAchievementCriteriaInfo = MockGetAchievementCriteriaInfo
    _G.C_AddOns = {
        LoadAddOn = function()
        end,
    }

    local pins = {
        { questID = 1, title = "Knight-Errant Bloodshatter", description = "Difficulty: Nightmare", normalizedX = 0.20, normalizedY = 0.20 },
        { questID = 2, title = "The Wing of Akil'zon", description = "Difficulty: Nightmare", normalizedX = 0.80, normalizedY = 0.40 },
        { questID = 3, title = "Zadu, Fist of Nalorakk", description = "Difficulty: Hard", normalizedX = 0.45, normalizedY = 0.60 },
        { questID = 4, title = "Thornspeaker Edgath", description = "Difficulty: Normal", normalizedX = 0.45, normalizedY = 0.20 },
        { questID = 5, title = "Lieutenant Blazewing", description = "Difficulty: Nightmare", normalizedX = 0.23, normalizedY = 0.22 },
    }
    _G.CovenantMissionFrame = {
        IsShown = function()
            return true
        end,
        MapTab = {
            pinPools = {
                ["AdventureMap_QuestOfferPinTemplate"] = makePinPool(pins),
            },
        },
    }

    loadModule("Core/HuntData.lua", ns)
    loadModule("Core/HuntList.lua", ns)
    local huntList = ns.HuntList
    expectNotNil("huntList module", huntList)

    huntList:RefreshFromPins()
    local state = huntList:GetState()
    expectEqual("dedupe by difficulty+zone", #state.hunts, 4)

    huntList:SetDifficultyFilter("All")
    local allHunts = huntList:GetFilteredSortedHunts()
    expectEqual("sorted hunt count", #allHunts, 4)
    expectEqual("sorted #1 questID", allHunts[1] and allHunts[1].questID, 1)
    expectEqual("sorted #2 questID", allHunts[2] and allHunts[2].questID, 3)
    expectEqual("sorted #3 questID", allHunts[3] and allHunts[3].questID, 2)
    expectEqual("sorted #4 questID", allHunts[4] and allHunts[4].questID, 4)

    local huntsByQuestID = {}
    for _, hunt in ipairs(allHunts) do
        huntsByQuestID[hunt.questID] = hunt
    end

    expectNotNil("quest 1 present", huntsByQuestID[1])
    expectNotNil("quest 2 present", huntsByQuestID[2])
    expectNotNil("quest 3 present", huntsByQuestID[3])
    expectNotNil("quest 4 present", huntsByQuestID[4])
    expectTrue("inProgress state propagated", huntsByQuestID[2] and huntsByQuestID[2].inProgress == true)
    expectEqual("nightmare hunt shows badge when its achievement criterion is incomplete", huntsByQuestID[1] and huntsByQuestID[1].achievement and huntsByQuestID[1].achievement.isIncomplete, true)
    expectEqual("criteria source is reported on the hunt", huntsByQuestID[1] and huntsByQuestID[1].achievement and huntsByQuestID[1].achievement.source, "achievementCriteria")
    expectNil("completed nightmare criterion hides the badge", huntsByQuestID[2] and huntsByQuestID[2].achievement)
    expectNil("completed hard achievement hides the badge", huntsByQuestID[3] and huntsByQuestID[3].achievement)
    expectNil("completed normal criterion hides the badge", huntsByQuestID[4] and huntsByQuestID[4].achievement)

    huntList:SetDifficultyFilter("Nightmare")
    local nightmareOnly = huntList:GetFilteredSortedHunts()
    expectEqual("nightmare filter count", #nightmareOnly, 2)

    local nightmareQuestIDs = {}
    for _, hunt in ipairs(nightmareOnly) do
        nightmareQuestIDs[hunt.questID] = true
    end

    expectTrue("nightmare filter includes quest 1", nightmareQuestIDs[1] == true)
    expectTrue("nightmare filter includes quest 2", nightmareQuestIDs[2] == true)
end

local function runHuntDataAchievementMatchTests()
    local ns = newNamespace()

    local function MockGetAchievementInfo(achievementID)
        if achievementID == 42701 then
            return 42701, "Prey: Normal Mode III", 10, false, nil, nil, nil, "Defeat all of the following Prey targets on Normal difficulty.", nil, 134414, nil, false, false, nil, false
        elseif achievementID == 42702 then
            return 42702, "Prey: Hard Mode III", 10, true, nil, nil, nil, "Defeat all of the following Prey targets on Hard difficulty.", nil, 134414, nil, false, true, nil, false
        elseif achievementID == 42703 then
            return 42703, "Prey: Nightmare Mode III", 10, false, nil, nil, nil, "Defeat all of the following Prey targets on Nightmare difficulty.", nil, 134400, nil, false, false, nil, false
        end

        return nil
    end
    _G.GetAchievementInfo = MockGetAchievementInfo
    _G.GetAchievementNumCriteria = function(achievementID)
        if achievementID == 42701 then
            return 1
        elseif achievementID == 42702 then
            return 1
        elseif achievementID == 42703 then
            return 2
        end

        return 0
    end
    _G.GetAchievementCriteriaInfo = function(achievementID, criteriaIndex)
        if achievementID == 42701 and criteriaIndex == 1 then
            return "Thornspeaker Edgath", nil, true
        elseif achievementID == 42702 and criteriaIndex == 1 then
            return "Zadu, Fist of Nalorakk", nil, true
        elseif achievementID == 42703 then
            if criteriaIndex == 1 then
                return "Razorclaw", nil, false
            elseif criteriaIndex == 2 then
                return "The Wing of Akil'zon", nil, true
            end
        end

        return nil, nil, false
    end
    _G.C_QuestLog = {
        IsQuestFlaggedCompleted = function()
            return false
        end,
    }
    _G.C_MajorFactions = {
        GetCurrentRenownLevel = function()
            return 10
        end,
    }

    loadModule("Core/HuntData.lua", ns)

    local status = ns.HuntData:GetHuntAchievementStatus("Prey: Razorclaw (Nightmare)", "Nightmare")
    expectNotNil("hunt data returns badge while nightmare criterion is unearned", status)
    expectEqual("hunt data keeps nightmare achievement id", status and status.achievementID, 42703)
    expectEqual("hunt data keeps nightmare achievement name", status and status.name, "Prey: Nightmare Mode III")
    expectEqual("hunt data marks unfinished nightmare criterion", status and status.isIncomplete, true)
    expectEqual("hunt data reports criteria source", status and status.source, "achievementCriteria")

    local sameDifficultyDifferentName = ns.HuntData:GetHuntAchievementStatus("Anything Else", "Nightmare")
    expectNil("hunt data hides badge when no matching criterion is found", sameDifficultyDifferentName)

    local completedCriterion = ns.HuntData:GetHuntAchievementStatus("The Wing of Akil'zon", "Nightmare")
    expectNil("hunt data hides badge after matching completed criterion", completedCriterion)

    local earnedDifficulty = ns.HuntData:GetHuntAchievementStatus("Hard Hunt", "Hard")
    expectNil("hunt data hides badge after hard achievement earned", earnedDifficulty)
end

local function runEventRouterAchievementCacheInvalidationTests()
    local ns = newNamespace()
    local registeredEvents = {}
    local refreshEvents = {}
    local invalidationCount = 0
    local removedQuestID = nil
    local dirtyReason = nil
    local journalRecordedQuestID = nil

    ns.Debug = {
        IsEnabled = function()
            return false
        end,
        Log = function()
        end,
        KV = function(_, _, value)
            return tostring(value)
        end,
    }
    ns.Controller = {
        SetScript = function(self, scriptName, handler)
            if scriptName == "OnEvent" then
                self.onEvent = handler
            end
        end,
        RegisterEvent = function(_, eventName)
            registeredEvents[eventName] = true
        end,
        Refresh = function(_, eventName)
            refreshEvents[#refreshEvents + 1] = eventName
        end,
    }
    ns.OverlayView = {
        HandleCombatEnd = function()
        end,
    }
    ns.HuntData = {
        InvalidateAchievementCache = function()
            invalidationCount = invalidationCount + 1
        end,
    }
    ns.HuntList = {
        GetHuntByQuestID = function(_, questID)
            if questID == 91458 then
                return { questID = 91458, name = "Tracked Hunt", difficulty = "Nightmare", zone = "Voidstorm" }
            end
            return nil
        end,
        RemoveByQuestID = function(_, questID)
            removedQuestID = questID
        end,
        MarkLiveSnapshotDirty = function(_, reason)
            dirtyReason = reason
        end,
    }
    ns.HuntJournal = {
        RecordCompletion = function(_, snapshot)
            journalRecordedQuestID = snapshot and snapshot.questID or nil
        end,
    }

    loadModule("Core/Controller/EventRouter.lua", ns)

    expectTrue("event router registers CRITERIA_UPDATE", registeredEvents["CRITERIA_UPDATE"] == true)
    expectTrue("event router registers ACHIEVEMENT_EARNED", registeredEvents["ACHIEVEMENT_EARNED"] == true)
    expectTrue("event router registers QUEST_LOG_CRITERIA_UPDATE", registeredEvents["QUEST_LOG_CRITERIA_UPDATE"] == true)

    ns.Controller.onEvent(ns.Controller, "CRITERIA_UPDATE")
    ns.Controller.onEvent(ns.Controller, "ACHIEVEMENT_EARNED", 42703)
    ns.Controller.onEvent(ns.Controller, "QUEST_LOG_CRITERIA_UPDATE")
    ns.Controller.onEvent(ns.Controller, "QUEST_TURNED_IN", 91458)
    ns.Controller.onEvent(ns.Controller, "ADVENTURE_MAP_QUEST_UPDATE")

    expectEqual("achievement cache invalidated for criteria and turn-in events", invalidationCount, 4)
    expectEqual("quest turn-in records journal completion before removal", journalRecordedQuestID, 91458)
    expectEqual("hunt list entry still removed on quest turn-in", removedQuestID, 91458)
    expectEqual("adventure map update marks live hunt list dirty", dirtyReason, "ADVENTURE_MAP_QUEST_UPDATE")
    expectEqual("criteria update still refreshes after invalidation", refreshEvents[1], "CRITERIA_UPDATE")
    expectEqual("achievement earned still refreshes after invalidation", refreshEvents[2], "ACHIEVEMENT_EARNED")
    expectEqual("quest criteria update still refreshes after invalidation", refreshEvents[3], "QUEST_LOG_CRITERIA_UPDATE")
    expectEqual("quest turn-in still refreshes after invalidation", refreshEvents[4], "QUEST_TURNED_IN")
end

local function runLocalePatternDifficultyTests()
    local ns = newNamespace()
    ns.Settings = {
        GetHuntPanelFilter = function()
            return "all"
        end,
        SetHuntPanelFilter = function()
        end,
    }
    ns.Constants.Hunt.DifficultyPatterns = {
        normal = { "normal" },
        hard = { "schwer" },
        nightmare = { "Alptraum" },
    }

    _G.C_QuestLog = {
        IsOnQuest = function()
            return false
        end,
    }

    _G.CovenantMissionFrame = {
        IsShown = function()
            return true
        end,
        MapTab = {
            pinPools = {
                ["AdventureMap_QuestOfferPinTemplate"] = makePinPool({
                    { questID = 11, title = "Jagd", description = "Alptraumjagd", normalizedX = 0.2, normalizedY = 0.2 },
                }),
            },
        },
    }

    loadModule("Core/HuntList.lua", ns)
    ns.HuntList:RefreshFromPins()
    local hunts = ns.HuntList:GetFilteredSortedHunts()
    expectEqual("locale difficulty pattern mapping", hunts[1] and hunts[1].difficulty, "Nightmare")
end

local function runHuntListQuickEvaluateTests()
    local ns = newNamespace()
    ns.Settings = {
        GetHuntPanelFilter = function()
            return "all"
        end,
        SetHuntPanelFilter = function()
        end,
    }

    _G.C_QuestLog = {
        IsOnQuest = function()
            return false
        end,
        GetActivePreyQuest = function()
            return nil
        end,
    }

    loadModule("Core/HuntList.lua", ns)

    _G.CovenantMissionFrame = nil
    local hasHunts, count, source = ns.HuntList:QuickEvaluateAvailability()
    expectEqual("quick eval map hidden status", hasHunts, nil)
    expectEqual("quick eval map hidden count", count, 0)
    expectEqual("quick eval map hidden source", source, "mapHidden")

    _G.CovenantMissionFrame = {
        IsShown = function()
            return true
        end,
        MapTab = {
            pinPools = {
                ["AdventureMap_QuestOfferPinTemplate"] = makePinPool({}),
            },
        },
    }
    hasHunts, count, source = ns.HuntList:QuickEvaluateAvailability()
    expectEqual("quick eval empty map status", hasHunts, nil)
    expectEqual("quick eval empty map count", count, 0)
    expectEqual("quick eval empty map source", source, "awaitingPins")

    _G.CovenantMissionFrame.MapTab.pinPools["AdventureMap_QuestOfferPinTemplate"] = makePinPool({
        { questID = 12, title = "Normal Hunt", description = "Normal", normalizedX = 0.2, normalizedY = 0.2 },
    })
    hasHunts, count, source = ns.HuntList:QuickEvaluateAvailability()
    expectEqual("quick eval pin snapshot status", hasHunts, true)
    expectEqual("quick eval pin snapshot count", count, 1)
    expectEqual("quick eval pin snapshot source", source, "pinSnapshot")
end

local function runHuntListLiveFirstCacheTests()
    local ns = newNamespace()
    local charCache = {
        [90001] = {
            questID = 90001,
            name = "Stale Hunt",
            description = "Normal",
            difficulty = "Normal",
            zone = "Eversong Woods",
            rewards = {
                { rewardIndex = 1, tooltipType = "text", name = "Old Reward", texture = "old" },
            },
        },
    }

    ns.Settings = {
        GetHuntPanelFilter = function()
            return "all"
        end,
        SetHuntPanelFilter = function()
        end,
        GetCharacterHuntQuestCache = function()
            return charCache
        end,
    }

    _G.C_QuestLog = {
        IsOnQuest = function()
            return false
        end,
        GetActivePreyQuest = function()
            return nil
        end,
    }
    _G.C_Timer = nil
    _G.CovenantMissionFrame = {
        IsShown = function()
            return true
        end,
        MapTab = {
            pinPools = {
                ["AdventureMap_QuestOfferPinTemplate"] = makePinPool({
                    { questID = 12, title = "Fresh Normal Hunt", description = "Normal", normalizedX = 0.2, normalizedY = 0.2 },
                }),
            },
        },
    }

    loadModule("Core/HuntList.lua", ns)
    local state = ns.HuntList:GetState()
    expectEqual("cached stale hunt loads as warm start", state.hunts[1] and state.hunts[1].questID, 90001)

    ns.HuntList:BeginStabilizedScan()
    state = ns.HuntList:GetState()
    expectEqual("live scan replaces stale cache count", #state.hunts, 1)
    expectEqual("live scan replaces stale cache quest", state.hunts[1] and state.hunts[1].questID, 12)
    expectNil("stale saved cache entry pruned", charCache[90001])
    expectNotNil("fresh live hunt persisted to cache", charCache[12])
    expectTrue("live snapshot marked ready", ns.HuntList:HasLiveHuntSnapshot() == true)

    ns.HuntList:HandleMissingLivePin(12, "test")
    expectNil("missing live pin removes runtime row", state.questIndex[12])
    expectNil("missing live pin removes saved cache entry", charCache[12])
    expectEqual("missing live pin dirties live snapshot", state.liveSnapshotDirty, true)
end

local function runHuntOSDataTests()
    local ns = newNamespace()
    ns.TextStyle = {
        GetDefaultFontValue = function() return "builtin:standard" end,
        SanitizeFontValue = function(_, value)
            if type(value) == "string" and value ~= "" then return value end
            return "builtin:standard"
        end,
    }

    _G.C_QuestLog = _G.C_QuestLog or {}
    _G.C_TaskQuest = _G.C_TaskQuest or {}
    _G.C_Map = _G.C_Map or {}
    _G.PreybreakerDB = {
        schemaVersion = 7,
        preferredHuntReward = "remnant",
        fallbackHuntReward = "gold",
        plannerPreferences = { focus = "achievement", preferredDifficulty = "nightmare", rewardGoal = "preferred" },
    }
    _G.PreybreakerCharDB = {
        schemaVersion = 7,
    }

    loadModule("Core/Util.lua", ns)
    loadModule("Core/Settings.lua", ns)
    loadModule("Core/HuntJournal.lua", ns)
    loadModule("Core/HuntPlanner.lua", ns)
    loadModule("Core/HuntStats.lua", ns)
    loadModule("Core/HuntDiagnostics.lua", ns)

    ns.Settings:Initialize()

    local snapshot = {
        questID = 501,
        name = "Nightmare Gap",
        difficulty = "Nightmare",
        zone = "Voidstorm",
    }
    ns.HuntJournal:RecordRewardSelection(501, {
        rewardType = "remnant",
        rewardName = "Remnant of Anguish",
        rewardIndex = 2,
        source = "test",
    })
    local recorded, entry = ns.HuntJournal:RecordCompletion(snapshot)
    expectTrue("journal records completion", recorded == true)
    expectEqual("journal stores quest id", entry and entry.questID, 501)
    expectEqual("journal stores reward selection", entry and entry.reward and entry.reward.rewardType, "remnant")

    ns.HuntJournal:RecordCompletion(snapshot)
    expectEqual("journal dedupes same weekly completion", #ns.Settings:GetHuntHistory(), 1)
    expectNotNil("journal recent lookup returns entry", ns.HuntJournal:GetRecentByQuestID(501))

    local preferredPreview = ns.HuntPlanner:GetRewardPreview({
        rewards = {
            { rewardIndex = 1, name = "Gold Cache" },
            { rewardIndex = 2, name = "Remnant of Anguish" },
        },
    })
    expectEqual("planner picks preferred reward", preferredPreview.selectedRewardType, "remnant")
    expectEqual("planner preferred status", preferredPreview.status, "preferred")

    local fallbackPreview = ns.HuntPlanner:GetRewardPreview({
        rewards = {
            { rewardIndex = 1, name = "Remnant of Anguish", isCapped = true },
            { rewardIndex = 2, name = "Gold Cache" },
        },
    })
    expectEqual("planner falls back when preferred capped", fallbackPreview.selectedRewardType, "gold")
    expectEqual("planner fallback status", fallbackPreview.status, "fallback")

    local recommendations = ns.HuntPlanner:GetRecommendations({
        {
            questID = 601,
            name = "Achievement Hunt",
            difficulty = "Nightmare",
            zone = "Voidstorm",
            achievement = { isIncomplete = true },
            rewards = { { rewardIndex = 1, name = "Gold Cache" } },
        },
        {
            questID = 602,
            name = "Normal Hunt",
            difficulty = "Normal",
            zone = "Eversong Woods",
            rewards = { { rewardIndex = 1, name = "Gold Cache" } },
        },
    }, ns.HuntJournal:GetEntries("all"), ns.Settings:GetPlannerPreferences())
    expectEqual("planner focus filters to achievement hunt", #recommendations, 1)
    expectEqual("planner prioritizes achievement gap", recommendations[1] and recommendations[1].questID, 601)

    local weekly = ns.HuntJournal:MarkLiveListFresh(4, "test")
    expectEqual("weekly live list marked fresh", weekly and weekly.liveListFresh, true)
    expectEqual("weekly live count stored", weekly and weekly.lastLiveCount, 4)

    for questID = 700, 1005 do
        ns.HuntJournal:RecordCompletion({
            questID = questID,
            name = "Pruned Hunt " .. tostring(questID),
            difficulty = "Normal",
            zone = "Harandar",
        })
    end
    expectEqual("journal pruning keeps max entries", #ns.Settings:GetHuntHistory(), 300)

    local summary = ns.HuntStats:GetSummary("all")
    expectEqual("stats total follows journal", summary.total, 300)
    expectTrue("stats has difficulty bucket", (summary.byDifficulty.Normal or 0) > 0)

    ns.HuntList = {
        GetDiagnosticsSnapshot = function()
            return {
                huntCount = 4,
                cacheCount = 4,
                cacheVersion = 2,
                liveSnapshotReady = true,
                liveSnapshotDirty = false,
                huntsSource = "live",
            }
        end,
    }
    local report = ns.HuntDiagnostics:BuildReport()
    expectTrue("diagnostics report has lines", type(report.lines) == "table" and #report.lines > 0)
end

local function runCommandCenterDataTests()
    local ns = newNamespace()
    ns.TextStyle = {
        GetDefaultFontValue = function() return "builtin:standard" end,
        SanitizeFontValue = function(_, value)
            if type(value) == "string" and value ~= "" then return value end
            return "builtin:standard"
        end,
    }

    local oldUnitFullName = _G.UnitFullName
    local oldUnitName = _G.UnitName
    local oldUnitGUID = _G.UnitGUID
    local oldGetRealmName = _G.GetRealmName

    _G.UnitFullName = function() return "Aelwyn", "MoonGuard" end
    _G.UnitName = function() return "Aelwyn", "MoonGuard" end
    _G.UnitGUID = function() return "Player-1-0001" end
    _G.GetRealmName = function() return "MoonGuard" end

    _G.C_QuestLog = _G.C_QuestLog or {}
    _G.C_TaskQuest = _G.C_TaskQuest or {}
    _G.C_Map = _G.C_Map or {}
    _G.PreybreakerDB = {
        schemaVersion = 7,
        preferredHuntReward = "remnant",
        fallbackHuntReward = "gold",
        goalPreferences = {
            focus = "alts",
            preferredDifficulty = "hard",
            rewardGoal = "remnant",
            achievementWeight = 90,
            rewardWeight = 55,
            difficultyWeight = 12,
            altStaleWeight = 80,
            timeBudgetMinutes = 30,
        },
        dashboardState = { tab = "goals", sort = "name", filter = "stale" },
    }
    _G.PreybreakerCharDB = {
        schemaVersion = 7,
        weeklyState = { currentWeekKey = "legacy-week", liveListFresh = false },
        huntHistory = {
            {
                questID = 501,
                name = "Legacy Hunt",
                difficulty = "Nightmare",
                zone = "Voidstorm",
                completedAt = 1000,
                completedDate = "2026-05-01",
                weekKey = "legacy-week",
                reward = { rewardType = "gold", rewardName = "Gold" },
            },
        },
    }

    loadModule("Core/Util.lua", ns)
    loadModule("Core/Settings.lua", ns)
    loadModule("Core/HuntJournal.lua", ns)
    loadModule("Core/HuntPlanner.lua", ns)
    loadModule("Core/HuntStats.lua", ns)
    loadModule("Core/HuntRoster.lua", ns)
    loadModule("Core/HuntGoalEngine.lua", ns)
    loadModule("Core/HuntAlerts.lua", ns)
    loadModule("Core/HuntDiagnostics.lua", ns)

    ns.Settings:Initialize()
    local accountDB = ns.Settings:GetAccountDB()
    expectEqual("v8 account schema version set", accountDB.schemaVersion, 8)
    expectEqual("v8 command data version set", accountDB.commandCenterVersion, 8)
    expectEqual("v8 dashboard tab preserved", ns.Settings:GetCommandCenterTab(), "goals")
    expectEqual("v8 goal focus preserved", ns.Settings:GetGoalPreferences().focus, "alts")
    expectNotNil("v8 weekly stale character store", ns.Settings:GetWeeklyGoals().staleCharacters)

    local current = ns.HuntRoster:UpdateCurrentCharacter({ active = true, questID = 501, percent = 42 })
    expectEqual("roster current key uses realm and name", current and current.key, "MoonGuard:Aelwyn")
    expectEqual("roster stores current guid", current and current.guid, "Player-1-0001")
    expectEqual("roster stores active quest snapshot", current and current.activeHunt and current.activeHunt.questID, 501)
    expectEqual("roster history count follows journal", current and current.historyTotal, 1)
    ns.HuntRoster:UpdateCurrentCharacter({ active = true, questID = 501, percent = 43 })
    expectEqual("roster dedupes same character key", #ns.HuntRoster:GetCharacters(), 1)

    _G.UnitFullName = function() return "NoGuid", "MoonGuard" end
    _G.UnitName = function() return "NoGuid", "MoonGuard" end
    _G.UnitGUID = function() return nil end
    local second = ns.HuntRoster:UpdateCurrentCharacter({ active = false })
    expectEqual("roster falls back to realm:name without guid", second and second.key, "MoonGuard:NoGuid")
    expectEqual("roster keeps two character profiles", #ns.HuntRoster:GetCharacters(), 2)

    local rosterStore = ns.Settings:GetAccountRoster()
    rosterStore["OldRealm:Oldalt"] = {
        key = "OldRealm:Oldalt",
        name = "Oldalt",
        realm = "OldRealm",
        weekKey = "expired-week",
        lastSeenAt = 1,
        lastSnapshot = { active = true },
        completedThisWeek = 0,
    }
    local characters = ns.HuntRoster:GetCharacters()
    local staleOld = nil
    for _, character in ipairs(characters) do
        if character.key == "OldRealm:Oldalt" then
            staleOld = character
        end
    end
    expectTrue("roster marks old weekly character stale", staleOld and staleOld.stale == true)
    expectTrue("weekly goals track stale character key", ns.Settings:GetWeeklyGoals().staleCharacters["OldRealm:Oldalt"] == true)

    local liveHunts = {
        {
            questID = 601,
            name = "Achievement Hunt",
            difficulty = "Nightmare",
            zone = "Voidstorm",
            achievement = { isIncomplete = true },
            rewards = { { rewardIndex = 1, name = "Gold Cache" } },
        },
        {
            questID = 602,
            name = "Reward Hunt",
            difficulty = "Hard",
            zone = "Harandar",
            rewards = {
                { rewardIndex = 1, name = "Remnant of Anguish", isCapped = true },
                { rewardIndex = 2, name = "Gold Cache" },
            },
        },
    }
    local preferences = {
        focus = "achievements",
        preferredDifficulty = "nightmare",
        rewardGoal = "preferred",
        achievementWeight = 100,
        rewardWeight = 20,
        difficultyWeight = 10,
        altStaleWeight = 60,
    }
    local plan = ns.HuntGoalEngine:GetWeeklyPlan(characters, liveHunts, preferences)
    expectEqual("goal engine prioritizes achievement gap", plan[1] and plan[1].id, "hunt:601")

    local rewardGoal = nil
    for _, goal in ipairs(plan) do
        if goal.id == "hunt:602" then
            rewardGoal = goal
        end
    end
    expectEqual("goal engine sees capped preferred fallback", rewardGoal and rewardGoal.rewardPreview and rewardGoal.rewardPreview.status, "fallback")

    ns.HuntGoalEngine:SetPinned("hunt:602", true)
    plan = ns.HuntGoalEngine:GetWeeklyPlan(characters, liveHunts, preferences)
    expectEqual("goal engine keeps pinned goal first", plan[1] and plan[1].id, "hunt:602")
    expectTrue("goal engine marks pinned goal", plan[1] and plan[1].pinned == true)

    ns.HuntGoalEngine:SetIgnored("hunt:602", true)
    plan = ns.HuntGoalEngine:GetWeeklyPlan(characters, liveHunts, preferences)
    local ignoredStillVisible = false
    for _, goal in ipairs(plan) do
        if goal.id == "hunt:602" then
            ignoredStillVisible = true
        end
    end
    expectTrue("goal engine hides ignored goals", ignoredStillVisible == false)

    local alerts = ns.HuntAlerts:BuildAlerts(characters, { liveListFresh = false }, liveHunts)
    expectTrue("alerts include account status", #alerts >= 2)

    local report = ns.HuntDiagnostics:BuildReport()
    expectEqual("diagnostics exposes roster count", report.roster and report.roster.characterCount, #ns.HuntRoster:GetCharacters())
    expectEqual("diagnostics exposes v8 command data version", accountDB.commandCenterVersion, 8)

    _G.UnitFullName = oldUnitFullName
    _G.UnitName = oldUnitName
    _G.UnitGUID = oldUnitGUID
    _G.GetRealmName = oldGetRealmName
end

local function runSettingsAndMigrationTests()
    local ns = newNamespace()
    -- Settings references ns.TextStyle for font sanitization.
    ns.TextStyle = {
        GetDefaultFontValue = function() return "builtin:standard" end,
        SanitizeFontValue = function(_, value)
            if type(value) == "string" and value ~= "" then return value end
            return "builtin:standard"
        end,
    }

    -- Settings sanitizers call ns.Util.RoundNearest; load Util first.
    _G.C_QuestLog = _G.C_QuestLog or {}
    _G.C_TaskQuest = _G.C_TaskQuest or {}
    _G.C_Map = _G.C_Map or {}
    loadModule("Core/Util.lua", ns)
    loadModule("Core/Settings.lua", ns)
    local Settings = ns.Settings
    expectNotNil("settings module", Settings)

    -- Test v1 -> v8 migration: legacy offsets + orb seeding.
    _G.PreybreakerDB = {
        schemaVersion = 1,
        offsetX = 42,
        offsetY = -17,
    }
    _G.PreybreakerCharDB = {}

    Settings:Initialize()
    local db = Settings:GetDB()
    expectEqual("v1 radialOffsetX migrated", db.radialOffsetX, 42)
    expectEqual("v1 radialOffsetY migrated", db.radialOffsetY, -17)
    expectEqual("v1 barOffsetX migrated", db.barOffsetX, 42)
    expectEqual("v1 barOffsetY migrated", db.barOffsetY, -17)
    expectEqual("v1 orbOffsetX seeded from radial", db.orbOffsetX, 42)
    expectEqual("v1 orbOffsetY seeded from radial", db.orbOffsetY, -17)
    expectNil("v1 legacy offsetX removed", db.offsetX)
    expectNil("v1 legacy offsetY removed", db.offsetY)
    expectEqual("schema version upgraded", db.schemaVersion, 8)

    -- Test v2 -> v8 migration: per-mode flattening.
    _G.PreybreakerDB = {
        schemaVersion = 2,
        displayMode = "bar",
        barHideBlizzardWidget = true,
        barShowValueText = false,
    }
    _G.PreybreakerCharDB = {}

    Settings:Initialize()
    db = Settings:GetDB()
    expectEqual("v2 flattened hideBlizzardWidget from bar", db.hideBlizzardWidget, true)
    expectEqual("v2 flattened showValueText from bar", db.showValueText, false)

    -- Test v5 -> v8 migration: stale hunt cache reset.
    _G.PreybreakerDB = { schemaVersion = 5 }
    _G.PreybreakerCharDB = {
        schemaVersion = 5,
        huntCacheVersion = 1,
        huntQuestCache = {
            [90001] = { questID = 90001, name = "Stale Hunt" },
        },
    }

    Settings:Initialize()
    local migratedCache = Settings:GetCharacterHuntQuestCache()
    expectNil("v8 stale hunt cache cleared", next(migratedCache))
    expectEqual("v8 hunt cache version set", Settings:GetCharDB().huntCacheVersion, 2)

    -- Test v6 -> v8 migration: Hunt OS settings are sanitized and stores are created lazily.
    _G.PreybreakerDB = {
        schemaVersion = 6,
        minimap = { shown = "yes", locked = true, angle = 999 },
        plannerPreferences = { focus = "achievement", preferredDifficulty = "mythic", rewardGoal = "gold" },
    }
    _G.PreybreakerCharDB = {
        schemaVersion = 6,
    }

    Settings:Initialize()
    db = Settings:GetDB()
    expectEqual("v8 schema version set", db.schemaVersion, 8)
    expectEqual("v8 minimap shown sanitized", db.minimap.shown, false)
    expectEqual("v8 minimap lock preserved", db.minimap.locked, true)
    expectEqual("v8 minimap angle clamped", db.minimap.angle, 360)
    expectEqual("v8 planner focus preserved", db.plannerPreferences.focus, "achievement")
    expectEqual("v8 planner difficulty sanitized", db.plannerPreferences.preferredDifficulty, "nightmare")
    expectEqual("v8 console tab accepts stats", Settings:SetHuntConsoleTab("stats"), "stats")
    expectEqual("v8 console tab rejects invalid value", Settings:SetHuntConsoleTab("invalid"), "available")
    expectEqual("v8 planner focus accepts reward", Settings:SetPlannerFocus("reward"), "reward")
    expectNotNil("v8 hunt history store available", Settings:GetHuntHistory())
    expectNotNil("v8 weekly state store available", Settings:GetWeeklyState())
    expectNotNil("v8 account roster store available", Settings:GetAccountRoster())
    expectNotNil("v8 weekly goals store available", Settings:GetWeeklyGoals())
    expectEqual("v8 command tab accepts goals", Settings:SetCommandCenterTab("goals"), "goals")
    expectEqual("v8 command tab rejects invalid value", Settings:SetCommandCenterTab("invalid"), "overview")

    -- Test sanitizer clamping: scale out of range.
    _G.PreybreakerDB = {
        schemaVersion = 5,
        scale = 999,
    }
    _G.PreybreakerCharDB = {}

    Settings:Initialize()
    db = Settings:GetDB()
    expectEqual("scale clamped to max", db.scale, 2)

    -- Test sanitizer clamping: offset out of range.
    _G.PreybreakerDB = {
        schemaVersion = 5,
        radialOffsetX = -500,
    }
    _G.PreybreakerCharDB = {}

    Settings:Initialize()
    db = Settings:GetDB()
    expectEqual("offset clamped to min", db.radialOffsetX, -200)

    -- Test sanitizer: invalid type coercion.
    _G.PreybreakerDB = {
        schemaVersion = 5,
        enabled = "yes",
        displayMode = 42,
    }
    _G.PreybreakerCharDB = {}

    Settings:Initialize()
    db = Settings:GetDB()
    expectEqual("boolean sanitizer coerces string to default", db.enabled, true)
    expectEqual("displayMode sanitizer coerces number to default", db.displayMode, "radial")

    -- Test profile seeding: account -> char.
    _G.PreybreakerDB = {
        schemaVersion = 5,
        scale = 1.5,
        displayMode = "bar",
    }
    _G.PreybreakerCharDB = {
        schemaVersion = 5,
        useCharacterProfile = true,
    }

    Settings:Initialize()
    local charDB = Settings.charDB
    -- Character profile should have its own defaults, independent of account.
    expectEqual("char profile gets schema version", charDB.schemaVersion, 8)

    -- Test reset-to-defaults preserves schema.
    _G.PreybreakerDB = { schemaVersion = 5 }
    _G.PreybreakerCharDB = {}
    Settings:Initialize()
    db = Settings:GetDB()
    expectEqual("fresh db gets correct defaults for enabled", db.enabled, true)
    expectEqual("fresh db gets correct defaults for displayMode", db.displayMode, "radial")
    expectEqual("fresh db gets correct defaults for showValueText", db.showValueText, true)
    expectEqual("fresh db gets correct defaults for showStageBadge", db.showStageBadge, true)
end

runQuestTrackingResolverTests()
runHuntPurchaseStateMachineTests()
runHuntListDedupeSortFilterTests()
runHuntDataAchievementMatchTests()
runEventRouterAchievementCacheInvalidationTests()
runLocalePatternDifficultyTests()
runHuntListQuickEvaluateTests()
runHuntListLiveFirstCacheTests()
runHuntOSDataTests()
runCommandCenterDataTests()
runSettingsAndMigrationTests()

if #failures > 0 then
    io.stderr:write("Deterministic tests failed:\n")
    for _, failure in ipairs(failures) do
        io.stderr:write(" - " .. failure .. "\n")
    end
    os.exit(1)
end

print("Deterministic tests passed.")
