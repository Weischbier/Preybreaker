-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

ns.Util = {}

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
    if type(C_QuestLog) ~= "table" or type(C_QuestLog.GetActivePreyQuest) ~= "function" then
        return nil
    end

    return ns.Util.SafeCall(C_QuestLog.GetActivePreyQuest)
end

function ns.Util.IsQuestComplete(questID)
    if not questID or type(C_QuestLog) ~= "table" or type(C_QuestLog.IsComplete) ~= "function" then
        return false
    end

    return ns.Util.SafeCall(C_QuestLog.IsComplete, questID) == true
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
