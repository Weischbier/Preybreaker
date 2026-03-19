-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

ns.Util = {}

local function SafeTableCall(namespace, methodName, ...)
    if type(namespace) ~= "table" then
        return nil
    end

    return ns.Util.SafeCall(namespace[methodName], ...)
end

function ns.Util.SafeCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end

    local ok, result = pcall(func, ...)
    if ok then
        return result
    end

    if ns.Debug and type(ns.Debug.Log) == "function" and type(ns.Debug.KV) == "function" then
        ns.Debug:Log("error", ns.Debug:KV("source", "SafeCall"), ns.Debug:KV("err", tostring(result)))
    end

    return nil
end

function ns.Util.Clamp01(value)
    value = tonumber(value) or 0
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

function ns.Util.RoundNearest(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

function ns.Util.RoundPercent(progress)
    return math.floor((ns.Util.Clamp01(progress) * 100) + 0.5)
end

function ns.Util.GetActivePreyQuestID()
    return SafeTableCall(C_QuestLog, "GetActivePreyQuest")
end

function ns.Util.IsQuestComplete(questID)
    if not questID then
        return false
    end

    return SafeTableCall(C_QuestLog, "IsComplete", questID) == true
end

function ns.Util.IsWorldQuest(questID)
    if not questID then
        return false
    end

    return SafeTableCall(C_QuestLog, "IsWorldQuest", questID) == true
end

function ns.Util.IsQuestActive(questID)
    if not questID then
        return false
    end

    return SafeTableCall(C_QuestLog, "IsOnQuest", questID) == true
end

function ns.Util.IsTaskQuestActive(questID)
    if not questID then
        return false
    end

    return SafeTableCall(C_TaskQuest, "IsActive", questID) == true
end

function ns.Util.GetQuestTagInfo(questID)
    if not questID then
        return nil
    end

    return SafeTableCall(C_QuestLog, "GetQuestTagInfo", questID)
end

function ns.Util.GetQuestMapID(questID)
    if not questID then
        return nil
    end

    if type(GetQuestUiMapID) == "function" then
        local mapID = ns.Util.SafeCall(GetQuestUiMapID, questID, true)
        if mapID then
            return mapID
        end
    end

    return SafeTableCall(C_TaskQuest, "GetQuestZoneID", questID)
end

local function GetPreyWorldQuestType()
    return Enum and Enum.QuestTagType and Enum.QuestTagType.Prey or nil
end

function ns.Util.IsPreyWorldQuest(questID)
    local preyWorldQuestType = GetPreyWorldQuestType()
    if not preyWorldQuestType or not ns.Util.IsWorldQuest(questID) then
        return false
    end

    local tagInfo = ns.Util.GetQuestTagInfo(questID)
    return type(tagInfo) == "table" and tagInfo.worldQuestType == preyWorldQuestType
end

local function AppendQuestIDs(questIDs, seen, entries)
    if type(entries) ~= "table" then
        return
    end

    for _, info in ipairs(entries) do
        local questID = type(info) == "table" and info.questID or nil
        if questID and not seen[questID] then
            seen[questID] = true
            questIDs[#questIDs + 1] = questID
        end
    end
end

local function FindPreyWorldQuestOnMap(mapID)
    if not mapID then
        return nil
    end

    local questIDs = {}
    local seen = {}
    AppendQuestIDs(questIDs, seen, SafeTableCall(C_QuestLog, "GetQuestsOnMap", mapID))
    AppendQuestIDs(questIDs, seen, SafeTableCall(C_TaskQuest, "GetQuestsOnMap", mapID))

    local fallbackQuestID = nil
    for _, questID in ipairs(questIDs) do
        if ns.Util.IsPreyWorldQuest(questID) and not ns.Util.IsQuestComplete(questID) then
            if ns.Util.IsTaskQuestActive(questID) then
                return questID
            end

            fallbackQuestID = fallbackQuestID or questID
        end
    end

    return fallbackQuestID
end

function ns.Util.BuildPreyQuestContext()
    local activeQuestID = ns.Util.GetActivePreyQuestID()
    if not activeQuestID then
        return {
            activeQuestID = nil,
            worldQuestID = nil,
            trackedQuestID = nil,
            mapID = nil,
        }
    end

    local mapID = ns.Util.GetQuestMapID(activeQuestID)
    local worldQuestID = FindPreyWorldQuestOnMap(mapID)
    if worldQuestID then
        mapID = ns.Util.GetQuestMapID(worldQuestID) or mapID
    end

    local trackedQuestID = worldQuestID
    if not trackedQuestID and not ns.Util.IsQuestComplete(activeQuestID) then
        trackedQuestID = activeQuestID
    end

    return {
        activeQuestID = activeQuestID,
        worldQuestID = worldQuestID,
        trackedQuestID = trackedQuestID,
        mapID = mapID,
    }
end

function ns.Util.IsRelevantPreyQuest(questID)
    if not questID then
        return false
    end

    local context = ns.Util.BuildPreyQuestContext()
    return questID == context.activeQuestID
        or questID == context.worldQuestID
        or questID == context.trackedQuestID
end

function ns.Util.Print(message)
    local text = string.format("|cffd7b552%s|r %s", ADDON_NAME, tostring(message or ""))
    local chatFrame = _G.DEFAULT_CHAT_FRAME
    if chatFrame and type(chatFrame.AddMessage) == "function" then
        chatFrame:AddMessage(text)
        return
    end

    if type(print) == "function" then
        print(text)
    end
end
