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
            return questID == 91458
        end,
        RemoveByQuestID = function(_, questID)
            removedQuestID = questID
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

    expectEqual("achievement cache invalidated for criteria and turn-in events", invalidationCount, 4)
    expectEqual("hunt list entry still removed on quest turn-in", removedQuestID, 91458)
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

local function runRefreshAndSoundRoutingTests()
    local ns = newNamespace()
    ns.Controller = {}
    local selectedSoundTheme = "AmongUs"
    local deathSoundsEnabled = true
    ns.Settings = {
        ShouldPlaySoundOnPhaseChange = function()
            return true
        end,
        GetSoundTheme = function()
            return selectedSoundTheme
        end,
        ShouldPlayDeathSounds = function()
            return deathSoundsEnabled
        end,
        IsEnabled = function()
            return true
        end,
    }
    ns.Util.IsRelevantPreyQuest = function(questID)
        return questID == 91458
    end
    ns.Constants.Media = {
        Sounds = {
            HuntStart = "hunt_start.ogg",
            HuntEnd = "hunt_end.ogg",
            Ambush = "ambush.ogg",
            Riposte = "riposte.ogg",
            Kill = "kill.ogg",
            Interaction = "interaction.ogg",
            FinalPhase = "final_phase.ogg",
        },
        SoundCatalog = {
            AmongUs = {
                "ambush.ogg",
                "hunt_end.ogg",
                "hunt_start.ogg",
            },
            Generic = {
                "interaction.ogg",
                "kill.ogg",
                "riposte.ogg",
            },
            Pokemon = {
                "ambush.ogg",
                "ambush_bonus1.ogg",
                "progress.ogg",
                "progress2.ogg",
                "progress3.ogg",
            },
            Random = {
                "random1.ogg",
                "random2.ogg",
            },
        },
        DeathSounds = {
            "loser1.ogg",
            "loser2.ogg",
        },
    }

    local capturedSounds = {}
    local now = 100
    local units = {}
    local mapParents = {}
    local function soundPath(pack, fileName)
        return "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\" .. pack .. "\\" .. fileName
    end

    local previousGlobals = {
        Enum = _G.Enum,
        C_QuestLog = _G.C_QuestLog,
        GetLocale = _G.GetLocale,
        GetSpellInfo = _G.GetSpellInfo,
        PlaySoundFile = _G.PlaySoundFile,
        GetTimePreciseSec = _G.GetTimePreciseSec,
        UnitExists = _G.UnitExists,
        UnitIsPlayer = _G.UnitIsPlayer,
        UnitCanAttack = _G.UnitCanAttack,
        UnitReaction = _G.UnitReaction,
        UnitGUID = _G.UnitGUID,
        UnitName = _G.UnitName,
        UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost,
        UnitIsDead = _G.UnitIsDead,
        C_Map = _G.C_Map,
        MathRandom = math.random,
    }

    _G.Enum = {
        PreyHuntProgressState = {
            Cold = 0,
            Warm = 1,
            Hot = 2,
            Final = 3,
        },
    }
    _G.C_QuestLog = {
        GetTitleForQuestID = function(questID)
            if questID == 91458 then
                return "Prey: Razorclaw (Nightmare)"
            end
            return nil
        end,
        IsQuestFlaggedCompleted = function()
            return false
        end,
    }
    _G.PlaySoundFile = function(path)
        capturedSounds[#capturedSounds + 1] = path
    end
    _G.GetLocale = function()
        return "enUS"
    end
    _G.GetSpellInfo = function(spellID)
        if spellID == 8676 then
            return "Ambush"
        end
        return nil
    end
    _G.GetTimePreciseSec = function()
        return now
    end
    _G.UnitExists = function(unitToken)
        return units[unitToken] ~= nil
    end
    _G.UnitIsPlayer = function(unitToken)
        local unit = units[unitToken]
        return unit and unit.isPlayer == true or false
    end
    _G.UnitCanAttack = function(_, unitToken)
        local unit = units[unitToken]
        return unit and unit.hostile == true or false
    end
    _G.UnitReaction = function(unitToken)
        local unit = units[unitToken]
        return unit and unit.reaction or nil
    end
    _G.UnitGUID = function(unitToken)
        local unit = units[unitToken]
        return unit and unit.guid or nil
    end
    _G.UnitName = function(unitToken)
        local unit = units[unitToken]
        return unit and unit.name or nil
    end
    _G.UnitIsDeadOrGhost = function(unitToken)
        local unit = units[unitToken]
        return unit and unit.dead == true or false
    end
    _G.UnitIsDead = _G.UnitIsDeadOrGhost
    _G.C_Map = {
        GetBestMapForUnit = function(unitToken)
            local unit = units[unitToken]
            return unit and unit.mapID or nil
        end,
        GetMapInfo = function(mapID)
            local parentMapID = mapParents[mapID]
            if type(parentMapID) ~= "number" then
                return nil
            end
            return { parentMapID = parentMapID }
        end,
    }

    loadModule("Core/Controller/RefreshAndSound.lua", ns)
    local controller = ns.Controller
    expectNotNil("refreshAndSound transition handler exists", controller.HandleSnapshotSoundTransitions)
    expectNil("sound registration dead-state method removed", controller.RefreshSoundEventRegistrations)

    local function resetHarness(progressState)
        wipe(capturedSounds)
        wipe(units)
        controller.soundState = nil
        controller.lastSnapshot = {
            questID = 91458,
            progressState = progressState or 0,
        }
        controller:RefreshSoundContext(controller.lastSnapshot)
    end

    -- Cold->Warm should not promote unrelated hostiles as prey candidates.
    resetHarness(0)
    now = 100
    units.nameplate1 = {
        guid = "Creature-0-0-0-0-11111-0000000001",
        name = "Bandit Marauder",
        hostile = true,
        reaction = 3,
    }
    units.target = {
        guid = "Creature-0-0-0-0-22222-0000000002",
        name = "Bandit Marauder",
        hostile = true,
        reaction = 3,
    }
    controller:HandleNameplateUnitAddedForSounds("nameplate1")
    controller:HandleSnapshotSoundTransitions(
        { questID = 91458, progressState = 0 },
        { questID = 91458, progressState = 1 }
    )
    local state = controller:GetSoundState()
    expectNil("cold->warm blocks unrelated recent hostile promotion", state.preyCandidateGUIDs["Creature-0-0-0-0-11111-0000000001"])
    expectNil("cold->warm blocks unrelated target promotion", state.preyCandidateGUIDs["Creature-0-0-0-0-22222-0000000002"])
    expectEqual("cold->warm emits stage progress cue", capturedSounds[1], soundPath("Generic", "interaction.ogg"))

    -- Cold->Warm should promote a recent hostile only when prey name matches.
    resetHarness(0)
    now = 200
    units.nameplate2 = {
        guid = "Creature-0-0-0-0-33333-0000000003",
        name = "Razorclaw",
        hostile = true,
        reaction = 3,
    }
    units.target = {
        guid = "Creature-0-0-0-0-44444-0000000004",
        name = "Bandit Marauder",
        hostile = true,
        reaction = 3,
    }
    controller:HandleNameplateUnitAddedForSounds("nameplate2")
    controller:HandleSnapshotSoundTransitions(
        { questID = 91458, progressState = 0 },
        { questID = 91458, progressState = 1 }
    )
    state = controller:GetSoundState()
    expectTrue(
        "cold->warm promotes matching recent hostile",
        state.preyCandidateGUIDs["Creature-0-0-0-0-33333-0000000003"] == true
    )
    expectNil("cold->warm still rejects unrelated target", state.preyCandidateGUIDs["Creature-0-0-0-0-44444-0000000004"])
    expectEqual("prey name match stays exact, not substring", controller:IsLikelyPreyTargetName("Razor"), false)

    -- Stage transition emits short stage cue; spell riposte remains separate.
    resetHarness(1)
    now = 300
    controller:HandleSnapshotSoundTransitions(
        { questID = 91458, progressState = 1 },
        { questID = 91458, progressState = 2 }
    )
    controller.lastSnapshot = { questID = 91458, progressState = 2 }
    controller:HandleUnitSpellcastSound("player", 1260432)
    expectEqual("warm->hot emits stage progress cue", capturedSounds[1], soundPath("Generic", "interaction.ogg"))
    expectEqual("spell riposte cue still plays", capturedSounds[2], soundPath("Generic", "riposte.ogg"))

    -- Ambush chat cue should fire when localized message matches and hunt is active.
    resetHarness(0)
    now = 320
    controller:HandleAmbushChatMessageForSounds("Ambush!", "CHAT_MSG_SYSTEM")
    expectEqual("chat ambush cue in enUS", capturedSounds[1], soundPath("AmongUs", "ambush.ogg"))

    resetHarness(0)
    now = 321
    _G.GetLocale = function()
        return "deDE"
    end
    _G.GetSpellInfo = function(spellID)
        if spellID == 8676 then
            return "Hinterhalt"
        end
        return nil
    end
    controller:HandleAmbushChatMessageForSounds("Hinterhalt!", "CHAT_MSG_MONSTER_EMOTE")
    expectEqual("chat ambush cue in deDE", capturedSounds[1], soundPath("AmongUs", "ambush.ogg"))

    resetHarness(2)
    now = 322
    controller:HandleAmbushChatMessageForSounds("Hinterhalt!", "CHAT_MSG_MONSTER_EMOTE")
    expectNil("chat ambush ignored after warm stage", capturedSounds[1])

    resetHarness(0)
    now = 323
    controller:HandleAmbushChatMessageForSounds("Random warning", "CHAT_MSG_SYSTEM")
    expectNil("non-ambush chat does not trigger cue", capturedSounds[1])

    -- Numbered variants should randomize within the selected sound theme.
    selectedSoundTheme = "Pokemon"
    resetHarness(1)
    now = 323.2
    math.random = function(maxValue)
        if maxValue then
            return 2
        end
        return 0.99
    end
    controller:HandleSnapshotSoundTransitions(
        { questID = 91458, progressState = 1 },
        { questID = 91458, progressState = 2 }
    )
    expectEqual("pokemon numbered progress variant selected", capturedSounds[1], soundPath("Pokemon", "progress2.ogg"))

    -- Bonus variants should be rare and never exposed as a setting.
    resetHarness(0)
    now = 323.4
    math.random = function(maxValue)
        if maxValue then
            return 1
        end
        return 0.01
    end
    controller:HandleAmbushChatMessageForSounds("Ambush!", "CHAT_MSG_SYSTEM")
    expectEqual("bonus ambush variant selected on low roll", capturedSounds[1], soundPath("Pokemon", "ambush_bonus1.ogg"))

    resetHarness(0)
    now = 323.6
    math.random = function(maxValue)
        if maxValue then
            return 1
        end
        return 0.99
    end
    controller:HandleAmbushChatMessageForSounds("Ambush!", "CHAT_MSG_SYSTEM")
    expectEqual("regular ambush variant selected on high roll", capturedSounds[1], soundPath("Pokemon", "ambush.ogg"))

    -- Random theme falls back to random pool when an event key has no direct clip.
    selectedSoundTheme = "Random"
    resetHarness(2)
    now = 323.8
    math.random = function(maxValue)
        if maxValue then
            return 2
        end
        return 0.99
    end
    controller:HandleQuestTurnedInSound(91458)
    expectEqual("random theme fallback clip selected", capturedSounds[1], soundPath("Random", "random2.ogg"))

    selectedSoundTheme = "AmongUs"
    math.random = previousGlobals.MathRandom

    -- Ambush prey kill should still play kill cue even when prey name differs from quest title.
    resetHarness(0)
    now = 324
    local ambushPreyGUID = "Creature-0-0-0-0-77777-0000000007"
    units.target = {
        guid = ambushPreyGUID,
        name = "Nightstalker Ambusher",
        hostile = true,
        reaction = 3,
    }
    controller:HandleAmbushChatMessageForSounds("Ambush!", "CHAT_MSG_SYSTEM")
    controller:HandlePlayerTargetChangedForSounds()
    units.nameplateAmbush = {
        guid = ambushPreyGUID,
        name = "Nightstalker Ambusher",
        hostile = true,
        reaction = 3,
        dead = true,
    }
    controller:HandleNameplateUnitRemovedForSounds("nameplateAmbush")
    expectEqual("ambush cue still plays for ambush event", capturedSounds[1], soundPath("AmongUs", "ambush.ogg"))
    expectEqual("ambush prey kill plays kill cue", capturedSounds[2], soundPath("Generic", "kill.ogg"))

    -- Death clips only play while dead in the active hunt zone.
    resetHarness(2)
    now = 324.5
    math.random = function(maxValue)
        if maxValue then
            return 1
        end
        return 0.99
    end
    units.player = { dead = true, mapID = 2472 }
    mapParents[2472] = 0
    controller.lastSnapshot.mapID = 2472
    controller:HandlePlayerDeathForSounds()
    expectEqual("death cue plays in active hunt zone", capturedSounds[1], soundPath("Death", "loser1.ogg"))
    controller:HandlePlayerDeathForSounds()
    expectEqual("death cue is armed until revive", #capturedSounds, 1)
    controller:HandlePlayerRevivedForSounds()
    controller:HandlePlayerDeathForSounds()
    expectEqual("death cue can play again after revive", #capturedSounds, 2)

    resetHarness(2)
    now = 324.7
    units.player = { dead = true, mapID = 9999 }
    mapParents[9999] = 0
    controller.lastSnapshot.mapID = 2472
    controller:HandlePlayerDeathForSounds()
    expectNil("death cue blocked outside hunt zone", capturedSounds[1])

    resetHarness(2)
    now = 324.9
    units.player = { dead = true, mapID = 3000 }
    mapParents[3000] = 2472
    mapParents[2472] = 0
    controller.lastSnapshot.mapID = 2472
    controller:HandlePlayerDeathForSounds()
    expectEqual("death cue allowed in child map of hunt zone", capturedSounds[1], soundPath("Death", "loser1.ogg"))

    resetHarness(2)
    now = 325.1
    deathSoundsEnabled = false
    units.player = { dead = true, mapID = 2472 }
    controller.lastSnapshot.mapID = 2472
    controller:HandlePlayerDeathForSounds()
    expectNil("death cue respects setting toggle", capturedSounds[1])
    deathSoundsEnabled = true
    math.random = previousGlobals.MathRandom

    -- Death during active hunt should preserve last known snapshot values.
    local previousSnapshot = {
        active = true,
        widgetID = 9001,
        questID = 91458,
        activeQuestID = 91458,
        worldQuestID = nil,
        mapID = 2472,
        progressState = 2,
        progress = 0.67,
        percent = 67,
    }
    local inactiveSnapshot = {
        active = false,
        widgetID = nil,
        questID = nil,
        activeQuestID = nil,
        worldQuestID = nil,
        mapID = nil,
        progressState = nil,
        progress = 0,
        percent = 0,
    }
    units.player = { dead = true }
    expectTrue(
        "death snapshot preservation gate",
        controller:ShouldPreserveSnapshotWhileDead(previousSnapshot, inactiveSnapshot) == true
    )
    local preservedSnapshot = controller:BuildDeathPreservedSnapshot(previousSnapshot, inactiveSnapshot)
    expectTrue("death preservation marks snapshot", preservedSnapshot.preservedWhileDead == true)
    expectEqual("death preservation keeps stage", preservedSnapshot.progressState, 2)
    expectEqual("death preservation keeps percent", preservedSnapshot.percent, 67)
    units.player = { dead = false }
    expectEqual(
        "snapshot not preserved when player alive",
        controller:ShouldPreserveSnapshotWhileDead(previousSnapshot, inactiveSnapshot),
        false
    )

    _G.GetLocale = function()
        return "enUS"
    end
    _G.GetSpellInfo = function(spellID)
        if spellID == 8676 then
            return "Ambush"
        end
        return nil
    end

    -- QUEST_REMOVED abandon should suppress immediate hunt-end cue.
    resetHarness(2)
    now = 340
    controller:HandleQuestRemovedForSounds(91458)
    controller:HandleQuestTurnedInSound(91458)
    expectNil("abandon suppresses immediate hunt-end cue", capturedSounds[1])
    now = now + 20
    controller:HandleQuestTurnedInSound(91458)
    expectEqual("suppression expires for later legitimate turn-in", capturedSounds[1], soundPath("AmongUs", "hunt_end.ogg"))

    -- QUEST_REMOVED for completed quest should not suppress hunt-end.
    resetHarness(2)
    now = 350
    _G.C_QuestLog.IsQuestFlaggedCompleted = function(questID)
        return questID == 91458
    end
    controller:HandleQuestRemovedForSounds(91458)
    controller:HandleQuestTurnedInSound(91458)
    expectEqual("completed quest removal does not suppress hunt-end", capturedSounds[1], soundPath("AmongUs", "hunt_end.ogg"))
    _G.C_QuestLog.IsQuestFlaggedCompleted = function()
        return false
    end

    -- Interaction cue requires recent trap context.
    resetHarness(2)
    now = 350
    controller:HandleUnitSpellcastSound("player", 1242005)
    expectNil("interaction cue blocked without trap context", capturedSounds[1])
    units.mouseover = {
        guid = "Creature-0-0-0-0-66666-0000000006",
        name = "Thorny Trap",
        hostile = false,
        reaction = 4,
    }
    controller:HandleMouseoverChangedForSounds()
    controller:HandleUnitSpellcastSound("player", 1242005)
    expectEqual("interaction cue allowed with trap context", capturedSounds[1], soundPath("Generic", "interaction.ogg"))
    units.mouseover = nil
    now = now + 5
    controller:HandleUnitSpellcastSound("player", 1242005)
    expectEqual("interaction cue not replayed after context expires", #capturedSounds, 1)

    -- Hot->Final emits short stage cue; confirmed prey death still emits kill cue.
    resetHarness(2)
    now = 400
    local preyGUID = "Creature-0-0-0-0-55555-0000000005"
    controller:PromotePreyCombatCandidate(preyGUID)
    controller:HandleSnapshotSoundTransitions(
        { questID = 91458, progressState = 2 },
        { questID = 91458, progressState = 3 }
    )
    controller.lastSnapshot = { questID = 91458, progressState = 3 }
    controller:RefreshSoundContext(controller.lastSnapshot)
    units.nameplate3 = {
        guid = preyGUID,
        name = "Razorclaw",
        hostile = true,
        reaction = 3,
        dead = true,
    }
    controller:HandleNameplateUnitRemovedForSounds("nameplate3")
    expectEqual("hot->final emits stage progress cue", capturedSounds[1], soundPath("Generic", "interaction.ogg"))
    expectEqual("confirmed prey death uses kill cue", capturedSounds[2], soundPath("Generic", "kill.ogg"))

    _G.Enum = previousGlobals.Enum
    _G.C_QuestLog = previousGlobals.C_QuestLog
    _G.GetLocale = previousGlobals.GetLocale
    _G.GetSpellInfo = previousGlobals.GetSpellInfo
    _G.PlaySoundFile = previousGlobals.PlaySoundFile
    _G.GetTimePreciseSec = previousGlobals.GetTimePreciseSec
    _G.UnitExists = previousGlobals.UnitExists
    _G.UnitIsPlayer = previousGlobals.UnitIsPlayer
    _G.UnitCanAttack = previousGlobals.UnitCanAttack
    _G.UnitReaction = previousGlobals.UnitReaction
    _G.UnitGUID = previousGlobals.UnitGUID
    _G.UnitName = previousGlobals.UnitName
    _G.UnitIsDeadOrGhost = previousGlobals.UnitIsDeadOrGhost
    _G.UnitIsDead = previousGlobals.UnitIsDead
    _G.C_Map = previousGlobals.C_Map
    math.random = previousGlobals.MathRandom
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

    -- Test v1 -> v5 migration: legacy offsets + orb seeding.
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
    expectEqual("schema version upgraded", db.schemaVersion, 5)

    -- Test v2 -> v5 migration: per-mode flattening.
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
    expectEqual("char profile gets schema version", charDB.schemaVersion, 5)

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
runSettingsAndMigrationTests()

if #failures > 0 then
    io.stderr:write("Deterministic tests failed:\n")
    for _, failure in ipairs(failures) do
        io.stderr:write(" - " .. failure .. "\n")
    end
    os.exit(1)
end

print("Deterministic tests passed.")
