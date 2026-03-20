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
    _G.C_AddOns = {
        LoadAddOn = function()
        end,
    }

    local pins = {
        { questID = 1, title = "A Nightmare Hunt", description = "Nightmare", normalizedX = 0.20, normalizedY = 0.20 },
        { questID = 2, title = "B Nightmare Hunt", description = "Nightmare", normalizedX = 0.80, normalizedY = 0.40 },
        { questID = 3, title = "Hard Hunt", description = "Hard", normalizedX = 0.45, normalizedY = 0.60 },
        { questID = 4, title = "Normal Hunt", description = "Normal", normalizedX = 0.45, normalizedY = 0.20 },
        { questID = 5, title = "Duplicate Nightmare", description = "Nightmare", normalizedX = 0.23, normalizedY = 0.22 },
    }
    _G.CovenantMissionFrame = {
        MapTab = {
            pinPools = {
                ["AdventureMap_QuestOfferPinTemplate"] = makePinPool(pins),
            },
        },
    }

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
    expectEqual("sorted #2 questID", allHunts[2] and allHunts[2].questID, 2)
    expectEqual("sorted #3 questID", allHunts[3] and allHunts[3].questID, 3)
    expectEqual("sorted #4 questID", allHunts[4] and allHunts[4].questID, 4)
    expectTrue("inProgress state propagated", allHunts[2] and allHunts[2].inProgress == true)

    huntList:SetDifficultyFilter("Nightmare")
    local nightmareOnly = huntList:GetFilteredSortedHunts()
    expectEqual("nightmare filter count", #nightmareOnly, 2)
    expectEqual("nightmare filter #1", nightmareOnly[1] and nightmareOnly[1].questID, 1)
    expectEqual("nightmare filter #2", nightmareOnly[2] and nightmareOnly[2].questID, 2)
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
        nightmare = { "albtraum" },
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
                    { questID = 11, title = "Jagd", description = "Albtraumjagd", normalizedX = 0.2, normalizedY = 0.2 },
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
    expectEqual("quick eval empty map status", hasHunts, false)
    expectEqual("quick eval empty map count", count, 0)
    expectEqual("quick eval empty map source", source, "emptyMap")

    _G.CovenantMissionFrame.MapTab.pinPools["AdventureMap_QuestOfferPinTemplate"] = makePinPool({
        { questID = 12, title = "Normal Hunt", description = "Normal", normalizedX = 0.2, normalizedY = 0.2 },
    })
    hasHunts, count, source = ns.HuntList:QuickEvaluateAvailability()
    expectEqual("quick eval pin snapshot status", hasHunts, true)
    expectEqual("quick eval pin snapshot count", count, 1)
    expectEqual("quick eval pin snapshot source", source, "pinSnapshot")
end

runQuestTrackingResolverTests()
runHuntPurchaseStateMachineTests()
runHuntListDedupeSortFilterTests()
runLocalePatternDifficultyTests()
runHuntListQuickEvaluateTests()

if #failures > 0 then
    io.stderr:write("Deterministic tests failed:\n")
    for _, failure in ipairs(failures) do
        io.stderr:write(" - " .. failure .. "\n")
    end
    os.exit(1)
end

print("Deterministic tests passed.")
