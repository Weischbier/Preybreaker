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
    local logs = {}
    local ns = {
        Util = {
            SafeCall = safeCall,
            IsRelevantPreyQuest = function(questID)
                return questID == 94001
            end,
            IsWorldQuest = function() return false end,
            IsQuestComplete = function() return false end,
            IsQuestActive = function() return true end,
            IsTaskQuestActive = function() return false end,
            BuildPreyQuestContext = function()
                return {
                    activeQuestID = 94001,
                    worldQuestID = 94001,
                    trackedQuestID = 94001,
                }
            end,
        },
        Debug = {
            IsEnabled = function() return true end,
            KV = function(_, key, value)
                return tostring(key) .. "=" .. tostring(value)
            end,
            Log = function(_, topic, ...)
                local parts = {}
                for i = 1, select("#", ...) do
                    parts[#parts + 1] = tostring(select(i, ...))
                end
                logs[#logs + 1] = string.format("[%s] %s", topic, table.concat(parts, " | "))
            end,
        },
        Constants = {
            Hunt = {
                AstalorNpcID = 253513,
                RemnantCurrencyID = 3392,
                Cost = 50,
                DifficultyPatterns = {
                    normal = { "normal" },
                    hard = { "hard" },
                    nightmare = { "nightmare" },
                },
                RandomPatterns = { "random" },
                RewardPatterns = {
                    dawncrest = { "dawncrest", "crest" },
                    remnant = { "remnant", "anguish" },
                    gold = { "gold", "coin" },
                    marl = { "marl", "voidlight" },
                },
                DawncrestCurrencyIDs = { 3391, 3341 },
                VoidlightMarlCurrencyID = 3316,
            },
        },
    }
    ns.__logs = logs
    return ns
end

local function loadModule(path, ns)
    local chunk = assert(loadfile(path))
    chunk("Preybreaker", ns)
end

local ns = newNamespace()

ns.Settings = {
    ShouldAutoPurchaseRandomHunt = function() return true end,
    GetRandomHuntDifficulty = function() return "nightmare" end,
    GetRemnantThreshold = function() return 0 end,
    ShouldAutoSelectHuntReward = function() return true end,
    GetPreferredHuntReward = function() return "remnant" end,
    GetFallbackHuntReward = function() return "gold" end,
    ShouldAutoTurnInPreyQuest = function() return true end,
}

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
        return { { questID = 94001, title = "Nightmare Random Hunt" } }
    end,
    SelectAvailableQuest = function()
    end,
    GetOptions = function()
        return { { gossipOptionID = 11, name = "Nightmare Random Hunt" } }
    end,
    SelectOption = function()
    end,
}
_G.QuestGetAutoAccept = function()
    return false
end
_G.AcceptQuest = function()
end
_G.AcknowledgeAutoAcceptQuest = function()
end

loadModule("Core/HuntPurchase.lua", ns)
ns.HuntPurchase:HandleGossipShow()
ns.HuntPurchase:HandleQuestDetail()
ns.HuntPurchase:HandleQuestAccepted(94001)
ns.HuntPurchase:HandleQuestFinished()

_G.ShowQuestComplete = function()
end
_G.GetQuestID = function()
    return 94001
end
_G.GetNumQuestChoices = function()
    return 2
end
_G.GetQuestItemInfo = function(_, index)
    if index == 1 then
        return "Remnant of Anguish", "icon1", 1, 1, true, nil
    end
    return "Gold", "icon2", 1, 1, true, nil
end
_G.GetQuestItemInfoLootType = function()
    return 1
end
_G.GetQuestItemLink = function()
    return nil
end
_G.C_QuestOffer = {
    GetQuestRewardCurrencyInfo = function(_, index)
        if index == 1 then
            return { currencyID = 3392, name = "Remnant of Anguish", texture = "icon1", totalRewardAmount = 25 }
        end
        return nil
    end,
}
_G.GetQuestReward = function()
end

loadModule("Core/QuestTracking.lua", ns)
ns.QuestTracking:HandleQuestAutoComplete(94001)
ns.QuestTracking:HandleQuestComplete()
ns.QuestTracking:HandleQuestItemUpdate()

print("Debug trace sample:")
for _, line in ipairs(ns.__logs) do
    print(line)
end
