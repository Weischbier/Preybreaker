-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...
local Preybreaker = ns.Controller

Preybreaker:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME or arg1 == "Blizzard_UIWidgets" then
            self:Bootstrap(event, arg1)
        end

        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        self:Bootstrap(event)
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        ns.OverlayView:HandleCombatEnd()
        return
    end

    if event == "CRITERIA_UPDATE" or event == "ACHIEVEMENT_EARNED" or event == "QUEST_LOG_CRITERIA_UPDATE" then
        if ns.HuntData and type(ns.HuntData.InvalidateAchievementCache) == "function" then
            ns.HuntData:InvalidateAchievementCache()
        end
    end

    -- Events below intentionally fall through to Refresh() after running
    -- their specific handler. Do not add `return` statements here.

    if event == "QUEST_TURNED_IN" then
        if ns.HuntData and type(ns.HuntData.InvalidateAchievementCache) == "function" then
            ns.HuntData:InvalidateAchievementCache()
        end
        if ns.HuntList and ns.HuntList.GetHuntByQuestID and ns.HuntList:GetHuntByQuestID(arg1) then
            ns.HuntList:RemoveByQuestID(arg1)
        end
    end

    if event == "QUEST_REMOVED" then
        if ns.HuntList and ns.HuntList.GetHuntByQuestID and ns.HuntList:GetHuntByQuestID(arg1) then
            ns.HuntList:RemoveByQuestID(arg1)
        end
    end

    if event == "QUEST_AUTOCOMPLETE" then
        if ns.QuestTracking then
            ns.QuestTracking:HandleQuestAutoComplete(arg1)
        end
        return
    end

    if event == "QUEST_COMPLETE" then
        if ns.QuestTracking then
            ns.QuestTracking:HandleQuestComplete()
        end
        return
    end

    if event == "QUEST_ITEM_UPDATE" then
        if ns.QuestTracking then
            ns.QuestTracking:HandleQuestItemUpdate()
        end
        return
    end

    if event == "GOSSIP_SHOW" then
        if ns.HuntPurchase then
            ns.HuntPurchase:HandleGossipShow()
        end
        return
    end

    if event == "QUEST_DETAIL" then
        if ns.HuntPurchase then
            ns.HuntPurchase:HandleQuestDetail()
        end
        return
    end

    if event == "GOSSIP_CLOSED" then
        if ns.HuntPurchase then
            ns.HuntPurchase:HandleGossipClosed(arg1)
        end
        return
    end

    if event == "GOSSIP_CONFIRM" then
        if ns.HuntPurchase then
            local optionID, text, cost = arg1, ...
            ns.HuntPurchase:HandleGossipConfirm(optionID, text, cost)
        end
        return
    end

    if event == "QUEST_ACCEPTED" then
        if ns.HuntPurchase then
            local questID = select(1, ...)
            if type(questID) ~= "number" then
                questID = arg1
            end
            ns.HuntPurchase:HandleQuestAccepted(questID)
        end
    end

    if event == "QUEST_FINISHED" then
        if ns.HuntPurchase then
            ns.HuntPurchase:HandleQuestFinished()
        end
    end

    if event == "UPDATE_UI_WIDGET" and not self:ShouldRefreshFromWidgetUpdate(arg1) then
        if ns.Debug:IsEnabled() then
            ns.Debug:Log(
                "event",
                ns.Debug:KV("event", event),
                ns.Debug:KV("widgetID", self:GetWidgetUpdateID(arg1)),
                ns.Debug:KV("activeWidgetID", self.activeWidgetID),
                "refresh=skipped"
            )
        end
        return
    end

    if ns.Debug:IsEnabled() then
        ns.Debug:Log(
            "event",
            ns.Debug:KV("event", event),
            ns.Debug:KV("widgetID", self:GetWidgetUpdateID(arg1))
        )
    end

    self:Refresh(event, arg1, ...)
end)

Preybreaker:RegisterEvent("ADDON_LOADED")
Preybreaker:RegisterEvent("PLAYER_ENTERING_WORLD")
Preybreaker:RegisterEvent("PLAYER_REGEN_ENABLED")
Preybreaker:RegisterEvent("ZONE_CHANGED_NEW_AREA")
Preybreaker:RegisterEvent("CRITERIA_UPDATE")
Preybreaker:RegisterEvent("ACHIEVEMENT_EARNED")
Preybreaker:RegisterEvent("QUEST_ACCEPTED")
Preybreaker:RegisterEvent("QUEST_TURNED_IN")
Preybreaker:RegisterEvent("QUEST_REMOVED")
Preybreaker:RegisterEvent("QUEST_LOG_UPDATE")
Preybreaker:RegisterEvent("QUEST_LOG_CRITERIA_UPDATE")
Preybreaker:RegisterEvent("QUEST_POI_UPDATE")
Preybreaker:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
Preybreaker:RegisterEvent("SUPER_TRACKING_CHANGED")
Preybreaker:RegisterEvent("TASK_PROGRESS_UPDATE")
Preybreaker:RegisterEvent("UPDATE_ALL_UI_WIDGETS")
Preybreaker:RegisterEvent("UPDATE_UI_WIDGET")
Preybreaker:RegisterEvent("QUEST_AUTOCOMPLETE")
Preybreaker:RegisterEvent("QUEST_COMPLETE")
Preybreaker:RegisterEvent("QUEST_ITEM_UPDATE")
Preybreaker:RegisterEvent("GOSSIP_SHOW")
Preybreaker:RegisterEvent("QUEST_DETAIL")
Preybreaker:RegisterEvent("GOSSIP_CLOSED")
Preybreaker:RegisterEvent("GOSSIP_CONFIRM")
Preybreaker:RegisterEvent("QUEST_FINISHED")
Preybreaker:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
Preybreaker:RegisterEvent("ADVENTURE_MAP_QUEST_UPDATE")
