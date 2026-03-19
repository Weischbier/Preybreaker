-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local AmbushProbe = {}
ns.AmbushProbe = AmbushProbe

-- Chat filters are side-effect sensitive and run once per chat frame.
-- The controller owns raw event intake so we can trace the real source once.
local MESSAGE_EVENTS = {
    "CHAT_MSG_SYSTEM",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_MONSTER_SAY",
    "CHAT_MSG_MONSTER_YELL",
    "CHAT_MSG_MONSTER_EMOTE",
    "CHAT_MSG_MONSTER_PARTY",
    "CHAT_MSG_MONSTER_WHISPER",
    "CHAT_MSG_RAID_BOSS_EMOTE",
    "CHAT_MSG_RAID_BOSS_WHISPER",
    "RAID_BOSS_EMOTE",
    "RAID_BOSS_WHISPER",
    "UI_ERROR_MESSAGE",
    "UI_INFO_MESSAGE",
}

local MESSAGE_EVENT_SET = {}
for _, eventName in ipairs(MESSAGE_EVENTS) do
    MESSAGE_EVENT_SET[eventName] = true
end

local function NormalizeText(text)
    if type(text) ~= "string" then
        return nil
    end

    local normalized = text:gsub("[%c\r\n]+", " ")
    normalized = normalized:gsub("%s+", " ")
    normalized = normalized:match("^%s*(.-)%s*$")
    if normalized == "" then
        return nil
    end

    return normalized
end

local function BuildChatDetails(channelName, channelBaseName, channelIndex, lineID)
    local details = {}
    local resolvedChannel = channelBaseName
    if not resolvedChannel or resolvedChannel == "" then
        resolvedChannel = channelName
    end
    if resolvedChannel and resolvedChannel ~= "" then
        details[#details + 1] = ns.Debug:KV("channel", resolvedChannel)
    end
    if channelIndex and channelIndex ~= 0 then
        details[#details + 1] = ns.Debug:KV("index", channelIndex)
    end
    if lineID and lineID ~= 0 then
        details[#details + 1] = ns.Debug:KV("line", lineID)
    end
    return details
end

local function ExtractMessageData(event, ...)
    if event == "UI_ERROR_MESSAGE" or event == "UI_INFO_MESSAGE" then
        local errorType, message = ...
        local details = {}
        if errorType ~= nil then
            details[#details + 1] = ns.Debug:KV("code", errorType)
        end
        return NormalizeText(message), nil, details
    end

    if event == "RAID_BOSS_EMOTE" or event == "RAID_BOSS_WHISPER" then
        local text, source, displayTime, enableWarningSound = ...
        local details = {}
        if displayTime ~= nil then
            details[#details + 1] = ns.Debug:KV("display", displayTime)
        end
        if enableWarningSound ~= nil then
            details[#details + 1] = ns.Debug:KV("warningSound", enableWarningSound)
        end
        return NormalizeText(text), source, details
    end

    local text, source, _languageName, channelName, sourceFallback, _specialFlags, _zoneChannelID, channelIndex, channelBaseName, _languageID, lineID = ...
    if not source or source == "" then
        source = sourceFallback
    end

    return NormalizeText(text), source, BuildChatDetails(channelName, channelBaseName, channelIndex, lineID)
end

function AmbushProbe:IsCandidateEvent(event)
    return MESSAGE_EVENT_SET[event] == true
end

function AmbushProbe:Sync(frame, snapshot)
    local shouldArm = frame ~= nil
        and snapshot ~= nil
        and snapshot.active == true
        and ns.Debug ~= nil
        and ns.Debug:IsEnabled()

    if self.armed == shouldArm then
        return
    end

    self.armed = shouldArm
    for _, eventName in ipairs(MESSAGE_EVENTS) do
        if shouldArm then
            frame:RegisterEvent(eventName)
        else
            frame:UnregisterEvent(eventName)
        end
    end

    ns.Debug:Log(
        "ambush-probe",
        ns.Debug:KV("armed", shouldArm),
        ns.Debug:KV("active", snapshot and snapshot.active or false)
    )
end

function AmbushProbe:HandleEvent(event, ...)
    if not self.armed then
        return
    end

    local text, source, details = ExtractMessageData(event, ...)
    local parts = {
        ns.Debug:KV("event", event),
    }

    if source and source ~= "" then
        parts[#parts + 1] = ns.Debug:KV("source", source)
    end
    for _, detail in ipairs(details) do
        parts[#parts + 1] = detail
    end
    parts[#parts + 1] = ns.Debug:KV("text", text or "<nil>")

    ns.Debug:Log("ambush-probe", table.concat(parts, " | "))
end
