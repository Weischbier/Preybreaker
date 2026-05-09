-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Account Command Center. Dashboard-first advisory UI for account-local hunt
-- planning. It never drives quest accept/turn-in flows.

local _, ns = ...

local Constants = ns.Constants
local L = ns.L

ns.HuntCommandCenter = ns.HuntCommandCenter or {}

local HuntCommandCenter = ns.HuntCommandCenter

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local FRAME_NAME = "PreybreakerHuntCommandCenter"
local PANEL_WIDTH = 720
local PANEL_HEIGHT = 620
local TAB_HEIGHT = 26
local CARD_HEIGHT = 78
local CARD_SPACING = 8

local TABS = {
    { key = "overview", label = L["Overview"] },
    { key = "roster", label = L["Roster"] },
    { key = "goals", label = L["Goals"] },
    { key = "rewards", label = L["Rewards"] },
    { key = "timeline", label = L["Timeline"] },
    { key = "diagnostics", label = L["Diagnostics"] },
}

local FILTER_ORDER = { "all", "stale", "active", "goals" }
local SORT_ORDER = { "priority", "name", "recent" }
local FILTER_LABEL = {
    all = L["Filter: All"],
    stale = L["Filter: Stale"],
    active = L["Filter: Active"],
    goals = L["Filter: Goals"],
}
local SORT_LABEL = {
    priority = L["Sort: Priority"],
    name = L["Sort: Name"],
    recent = L["Sort: Recent"],
}

local DEFAULT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function SP()
    return Constants and Constants.SettingsPanel or {}
end

local function SetTextColor(fontString, color, alpha)
    if fontString then
        fontString:SetTextColor(color[1], color[2], color[3], alpha or 1)
    end
end

local function ApplyBackdrop(frame, background, border)
    if not frame or type(frame.SetBackdrop) ~= "function" then
        return
    end
    frame:SetBackdrop(DEFAULT_BACKDROP)
    frame:SetBackdropColor(background[1], background[2], background[3], background[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function ApplyDialogBackdrop(frame)
    local p = SP()
    ApplyBackdrop(frame, p.SurfaceColor or { 0.08, 0.06, 0.05, 0.96 }, p.BorderColor or { 0.66, 0.49, 0.21, 1 })
end

local function ApplyCardBackdrop(frame)
    local p = SP()
    ApplyBackdrop(frame, p.SurfaceRaisedColor or { 0.11, 0.08, 0.06, 0.98 }, p.BorderSoftColor or { 0.66, 0.49, 0.21, 0.34 })
end

local function ApplyInsetBackdrop(frame)
    local p = SP()
    ApplyBackdrop(frame, p.SurfaceInsetColor or { 0.12, 0.09, 0.07, 0.84 }, p.BorderSoftColor or { 0.66, 0.49, 0.21, 0.34 })
end

local function GetTab()
    if ns.Settings and type(ns.Settings.GetCommandCenterTab) == "function" then
        return ns.Settings:GetCommandCenterTab()
    end
    return "overview"
end

local function SetTab(tabKey)
    if ns.Settings and type(ns.Settings.SetCommandCenterTab) == "function" then
        return ns.Settings:SetCommandCenterTab(tabKey)
    end
    return tabKey or "overview"
end

local function GetDashboardState()
    if ns.Settings and type(ns.Settings.GetDashboardState) == "function" then
        return ns.Settings:GetDashboardState()
    end
    return { tab = "overview", filter = "all", sort = "priority" }
end

local function CycleValue(order, current)
    for index, value in ipairs(order) do
        if value == current then
            return order[(index % #order) + 1]
        end
    end
    return order[1]
end

local function CountMap(map)
    local count = 0
    if type(map) == "table" then
        for _, value in pairs(map) do
            if value ~= nil and value ~= false then
                count = count + 1
            end
        end
    end
    return count
end

local function GetLiveHunts()
    if not (ns.HuntList and type(ns.HuntList.GetFilteredSortedHunts) == "function") then
        return {}
    end
    local previousFilter = ns.HuntList.GetDifficultyFilter and ns.HuntList:GetDifficultyFilter() or nil
    if ns.HuntList.SetDifficultyFilter then
        ns.HuntList:SetDifficultyFilter("All")
    end
    local hunts = ns.HuntList:GetFilteredSortedHunts() or {}
    if previousFilter and ns.HuntList.SetDifficultyFilter then
        ns.HuntList:SetDifficultyFilter(previousFilter)
    end
    return hunts
end

local function GetRoster()
    if ns.HuntRoster and type(ns.HuntRoster.GetCharacters) == "function" then
        return ns.HuntRoster:GetCharacters()
    end
    return {}
end

local function GetWeeklyState()
    if ns.Settings and type(ns.Settings.GetWeeklyState) == "function" then
        return ns.Settings:GetWeeklyState()
    end
    return {}
end

local function GetWeeklyGoals()
    if ns.Settings and type(ns.Settings.GetWeeklyGoals) == "function" then
        return ns.Settings:GetWeeklyGoals()
    end
    return {}
end

local function BuildSummary(roster)
    local summary = {
        characterCount = 0,
        staleCount = 0,
        activeCount = 0,
        weeklyCompletions = 0,
    }
    for _, character in ipairs(roster or {}) do
        summary.characterCount = summary.characterCount + 1
        if character.stale then summary.staleCount = summary.staleCount + 1 end
        if character.lastSnapshot and character.lastSnapshot.active then summary.activeCount = summary.activeCount + 1 end
        summary.weeklyCompletions = summary.weeklyCompletions + (tonumber(character.completedThisWeek) or 0)
    end
    return summary
end

local function BuildPlanIndexes(plan)
    local indexes = {
        goalQuestIDs = {},
        goalCharacterKeys = {},
        goalByQuestID = {},
        staleCharacterKeys = {},
        activeCharacterKeys = {},
    }
    for _, goal in ipairs(plan or {}) do
        if goal.hunt and goal.hunt.questID then
            indexes.goalQuestIDs[goal.hunt.questID] = true
            indexes.goalByQuestID[goal.hunt.questID] = goal
        end
        if goal.character and goal.character.key then
            indexes.goalCharacterKeys[goal.character.key] = true
        end
    end
    return indexes
end

local function MarkRosterIndexes(indexes, roster)
    for _, character in ipairs(roster or {}) do
        if character.key then
            if character.stale then indexes.staleCharacterKeys[character.key] = true end
            if character.lastSnapshot and character.lastSnapshot.active then indexes.activeCharacterKeys[character.key] = true end
        end
    end
end

local function FormatReward(preview)
    if not preview then
        return L["Rewards pending"]
    end
    if preview.selectedLabel then
        return string.format("%s: %s", L["Reward"], preview.selectedLabel)
    end
    return preview.reason or L["Rewards pending"]
end

local function CreateText(parent, template)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    return text
end

local function CreateTabButton(parent, tab)
    local button = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    button:SetHeight(TAB_HEIGHT)
    button.value = tab.key
    ApplyInsetBackdrop(button)

    button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.Text:SetPoint("CENTER")
    button.Text:SetText(tab.label)

    button.Highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.Highlight:SetAllPoints()
    button.Highlight:SetColorTexture(1, 1, 1, 0.06)
    button.Highlight:SetBlendMode("ADD")

    button:SetScript("OnClick", function()
        HuntCommandCenter:SetTab(tab.key)
    end)
    return button
end

local function CreateActionButton(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(96, 20)
    button:Hide()
    return button
end

local function CreateCard(parent)
    local card = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    card:SetHeight(CARD_HEIGHT)
    ApplyCardBackdrop(card)

    card.Title = CreateText(card, "GameFontHighlight")
    card.Title:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
    card.Title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -220, -10)

    card.Detail = CreateText(card, "GameFontNormalSmall")
    card.Detail:SetPoint("TOPLEFT", card.Title, "BOTTOMLEFT", 0, -5)
    card.Detail:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -31)
    card.Detail:SetWordWrap(true)

    card.Meta = CreateText(card, "GameFontDisableSmall")
    card.Meta:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 12, 8)
    card.Meta:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -12, 8)

    card.Action1 = CreateActionButton(card)
    card.Action1:SetPoint("TOPRIGHT", card, "TOPRIGHT", -108, -9)
    card.Action2 = CreateActionButton(card)
    card.Action2:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -9)

    return card
end

local function LayoutTabs(frame)
    local tabBar = frame.TabBar
    local buttons = frame.TabButtons
    local gap = 5
    local width = tabBar:GetWidth() or 1
    local buttonWidth = math.max(72, math.floor((width - (gap * (#buttons - 1))) / #buttons))
    for index, button in ipairs(buttons) do
        button:ClearAllPoints()
        button:SetSize(buttonWidth, TAB_HEIGHT)
        if index == 1 then
            button:SetPoint("LEFT", tabBar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", buttons[index - 1], "RIGHT", gap, 0)
        end
    end
end

local function UpdateTabs(frame)
    local selected = GetTab()
    local p = SP()
    local ac = p.AccentColor or { 0.86, 0.66, 0.28 }
    for _, button in ipairs(frame.TabButtons or {}) do
        if button.value == selected then
            ApplyBackdrop(button, { ac[1], ac[2], ac[3], 0.22 }, { ac[1], ac[2], ac[3], 0.95 })
            SetTextColor(button.Text, p.TitleColor or { 0.94, 0.86, 0.72 })
        else
            ApplyInsetBackdrop(button)
            SetTextColor(button.Text, p.MutedColor or { 0.58, 0.54, 0.49 })
        end
    end
end

local function BuildContext(selectedTab)
    local roster = GetRoster()
    local liveHunts = GetLiveHunts()
    local preferences = ns.Settings and ns.Settings.GetGoalPreferences and ns.Settings:GetGoalPreferences() or nil
    local plan = {}
    if ns.HuntGoalEngine and type(ns.HuntGoalEngine.GetWeeklyPlan) == "function" then
        plan = ns.HuntGoalEngine:GetWeeklyPlan(roster, liveHunts, preferences)
    end
    local indexes = BuildPlanIndexes(plan)
    MarkRosterIndexes(indexes, roster)

    local dashboard = GetDashboardState()
    local weeklyGoals = GetWeeklyGoals()
    local weeklyState = GetWeeklyState()
    return {
        tab = selectedTab or GetTab(),
        dashboard = dashboard,
        filter = dashboard.filter or "all",
        sort = dashboard.sort or "priority",
        roster = roster,
        liveHunts = liveHunts,
        preferences = preferences,
        weeklyState = weeklyState,
        weeklyGoals = weeklyGoals,
        ignoredCount = CountMap(weeklyGoals.ignored),
        plan = plan,
        summary = BuildSummary(roster),
        alerts = ns.HuntAlerts and ns.HuntAlerts.BuildAlerts and ns.HuntAlerts:BuildAlerts(roster, weeklyState, liveHunts) or {},
        indexes = indexes,
    }
end

local function SortRoster(roster, sortMode)
    table.sort(roster, function(left, right)
        if sortMode == "name" then
            local leftName = tostring(left.name or left.key or "")
            local rightName = tostring(right.name or right.key or "")
            if leftName ~= rightName then return leftName < rightName end
            return tostring(left.realm or "") < tostring(right.realm or "")
        end
        if sortMode == "priority" then
            if left.stale ~= right.stale then return left.stale == true end
            local leftActive = left.lastSnapshot and left.lastSnapshot.active == true
            local rightActive = right.lastSnapshot and right.lastSnapshot.active == true
            if leftActive ~= rightActive then return leftActive end
        end
        local leftSeen = tonumber(left.lastSeenAt) or 0
        local rightSeen = tonumber(right.lastSeenAt) or 0
        if leftSeen ~= rightSeen then return leftSeen > rightSeen end
        return tostring(left.key or "") < tostring(right.key or "")
    end)
end

local function FilterRoster(context)
    local filtered = {}
    for _, character in ipairs(context.roster or {}) do
        local include = context.filter == "all"
        if context.filter == "stale" then
            include = character.stale == true
        elseif context.filter == "active" then
            include = character.lastSnapshot and character.lastSnapshot.active == true
        elseif context.filter == "goals" then
            include = character.key and context.indexes.goalCharacterKeys[character.key] == true
        end
        if include then
            filtered[#filtered + 1] = character
        end
    end
    SortRoster(filtered, context.sort)
    return filtered
end

local function GoalIsActive(goal)
    return (goal.hunt and goal.hunt.inProgress == true)
        or (goal.character and goal.character.lastSnapshot and goal.character.lastSnapshot.active == true)
end

local function FilterGoals(context)
    local filtered = {}
    for _, goal in ipairs(context.plan or {}) do
        local include = context.filter == "all"
        if context.filter == "stale" then
            include = goal.character and goal.character.stale == true
        elseif context.filter == "active" then
            include = GoalIsActive(goal)
        elseif context.filter == "goals" then
            include = goal.type == "hunt" or goal.pinned == true
        end
        if include then
            filtered[#filtered + 1] = goal
        end
    end
    if context.sort == "name" then
        table.sort(filtered, function(left, right)
            return tostring(left.title or "") < tostring(right.title or "")
        end)
    elseif context.sort == "recent" then
        table.sort(filtered, function(left, right)
            local leftSeen = left.character and tonumber(left.character.lastSeenAt) or 0
            local rightSeen = right.character and tonumber(right.character.lastSeenAt) or 0
            if leftSeen ~= rightSeen then return leftSeen > rightSeen end
            return (left.score or 0) > (right.score or 0)
        end)
    end
    return filtered
end

local function RewardNeedsAttention(hunt)
    local preview = hunt.rewardPreview or (ns.HuntPlanner and ns.HuntPlanner.GetRewardPreview and ns.HuntPlanner:GetRewardPreview(hunt)) or nil
    return preview and (preview.status == "capped" or preview.status == "fallback" or preview.status == "unmatched")
end

local function FilterRewards(context)
    local filtered = {}
    for _, hunt in ipairs(context.liveHunts or {}) do
        local include = context.filter == "all"
        if context.filter == "stale" then
            include = RewardNeedsAttention(hunt)
        elseif context.filter == "active" then
            include = hunt.inProgress == true
        elseif context.filter == "goals" then
            include = context.indexes.goalQuestIDs[hunt.questID] == true
        end
        if include then
            filtered[#filtered + 1] = hunt
        end
    end
    table.sort(filtered, function(left, right)
        if context.sort == "name" then
            return tostring(left.name or "") < tostring(right.name or "")
        end
        if context.sort == "recent" then
            return tostring(left.zone or "") < tostring(right.zone or "")
        end
        local leftGoal = context.indexes.goalByQuestID[left.questID]
        local rightGoal = context.indexes.goalByQuestID[right.questID]
        local leftScore = leftGoal and leftGoal.score or 0
        local rightScore = rightGoal and rightGoal.score or 0
        if leftScore ~= rightScore then return leftScore > rightScore end
        return tostring(left.name or "") < tostring(right.name or "")
    end)
    return filtered
end

local function FilterTimeline(context)
    local history = context.history or {}
    local filtered = {}
    for _, entry in ipairs(history) do
        local include = context.filter == "all"
        if context.filter == "stale" then
            include = context.indexes.staleCharacterKeys[entry.characterKey] == true
        elseif context.filter == "active" then
            include = context.indexes.activeCharacterKeys[entry.characterKey] == true
        elseif context.filter == "goals" then
            include = context.indexes.goalQuestIDs[entry.questID] == true
        end
        if include then
            filtered[#filtered + 1] = entry
        end
    end
    if context.sort == "name" then
        table.sort(filtered, function(left, right)
            return tostring(left.name or "") < tostring(right.name or "")
        end)
    else
        table.sort(filtered, function(left, right)
            return (tonumber(left.completedAt) or 0) > (tonumber(right.completedAt) or 0)
        end)
    end
    return filtered
end

local function BuildOverviewCards(context)
    local summary = context.summary or {}
    local cards = {
        {
            title = L["Account Command Center"],
            detail = string.format(L["%d characters | %d stale | %d live hunts"], summary.characterCount or 0, summary.staleCount or 0, #(context.liveHunts or {})),
            meta = string.format(L["%d weekly completions recorded across roster."], summary.weeklyCompletions or 0),
        },
    }

    local nextGoal = context.plan and context.plan[1] or nil
    if nextGoal then
        cards[#cards + 1] = {
            title = L["Next best action"] .. ": " .. (nextGoal.title or L["Unknown prey"]),
            detail = nextGoal.detail or "",
            meta = string.format("%s | score %d", nextGoal.reason or L["Recommended"], nextGoal.score or 0),
        }
    else
        cards[#cards + 1] = {
            title = L["Next best action"],
            detail = L["Open the Adventure Map or log into alts to seed account planning data."],
            meta = L["Goal Engine has no actionable inputs yet."],
        }
    end

    for index, alert in ipairs(context.alerts or {}) do
        if index > 4 then break end
        cards[#cards + 1] = {
            title = alert.title,
            detail = alert.detail,
            meta = alert.severity,
        }
    end
    return cards
end

local function BuildRosterCards(context)
    local roster = FilterRoster(context)
    local cards = {}
    if #(context.roster or {}) == 0 then
        return {
            {
                title = L["Roster empty"],
                detail = L["The current character will be added after the next tracker refresh."],
                meta = L["Roster data stays local to this account."],
            },
        }
    end
    if #roster == 0 then
        return {
            {
                title = L["All roster entries are hidden"],
                detail = L["Change the Command Center filter to All to show every local character."],
                meta = FILTER_LABEL[context.filter] or context.filter,
            },
        }
    end

    for _, character in ipairs(roster) do
        local active = character.activeHunt and (character.activeHunt.name or ("Quest " .. tostring(character.activeHunt.questID))) or L["No active hunt"]
        cards[#cards + 1] = {
            title = string.format("%s - %s", character.name or "Unknown", character.realm or "Unknown Realm"),
            detail = string.format("%s | %s", active, character.stale and L["Stale"] or L["Fresh"]),
            meta = string.format(L["%d this week | %d total | last seen %s"], character.completedThisWeek or 0, character.historyTotal or 0, character.lastSeenDate or L["Unknown"]),
        }
    end
    return cards
end

local function BuildGoalCards(context)
    local plan = FilterGoals(context)
    local cards = {}
    if context.ignoredCount and context.ignoredCount > 0 then
        cards[#cards + 1] = {
            title = string.format(L["%d ignored goals hidden"], context.ignoredCount),
            detail = L["Clear ignored goals to restore hidden weekly recommendations."],
            meta = L["Pinned goals are preserved."],
            action2 = {
                text = L["Clear ignored"],
                onClick = function()
                    if ns.HuntGoalEngine then
                        ns.HuntGoalEngine:ClearIgnored()
                        HuntCommandCenter:Refresh("clear-ignored")
                    end
                end,
            },
        }
    end
    if #(context.plan or {}) == 0 then
        cards[#cards + 1] = {
            title = context.ignoredCount > 0 and L["All goals are ignored"] or L["No weekly goals yet"],
            detail = context.ignoredCount > 0 and L["Clear ignored goals to restore hidden weekly recommendations."] or L["Open the Adventure Map to seed live hunts, or log into alts to refresh roster state."],
            meta = context.ignoredCount > 0 and L["Pinned goals are preserved."] or L["Goal Engine is advisory only."],
        }
        return cards
    end
    if #plan == 0 then
        cards[#cards + 1] = {
            title = context.ignoredCount > 0 and L["All goals are ignored"] or L["All goals are hidden"],
            detail = context.ignoredCount > 0 and L["Clear ignored goals to restore hidden weekly recommendations."] or L["Change the Command Center filter to All to show every recommendation."],
            meta = FILTER_LABEL[context.filter] or context.filter,
        }
        return cards
    end

    for index, goal in ipairs(plan) do
        if index > 14 then break end
        cards[#cards + 1] = {
            title = string.format("%d. %s", index, goal.title or L["Unknown prey"]),
            detail = goal.detail or "",
            meta = string.format("%s | score %d", goal.reason or L["Recommended"], goal.score or 0),
            action1 = {
                text = goal.pinned and L["Unpin"] or L["Pin"],
                onClick = function()
                    if ns.HuntGoalEngine then
                        ns.HuntGoalEngine:SetPinned(goal.id, not goal.pinned)
                        HuntCommandCenter:Refresh("pin")
                    end
                end,
            },
            action2 = {
                text = L["Ignore"],
                onClick = function()
                    if ns.HuntGoalEngine then
                        ns.HuntGoalEngine:SetIgnored(goal.id, true)
                        HuntCommandCenter:Refresh("ignore")
                    end
                end,
            },
        }
    end
    return cards
end

local function BuildRewardCards(context)
    local liveHunts = FilterRewards(context)
    if #(context.liveHunts or {}) == 0 then
        return {
            {
                title = L["No live rewards yet"],
                detail = L["Open the Adventure Map so reward previews can warm from live hunt dialogs."],
                meta = L["SavedVariables are not used as live reward truth."],
            },
        }
    end
    if #liveHunts == 0 then
        return {
            {
                title = L["All rewards are hidden"],
                detail = L["Change the Command Center filter to All to show every live reward preview."],
                meta = FILTER_LABEL[context.filter] or context.filter,
            },
        }
    end

    local cards = {}
    for _, hunt in ipairs(liveHunts) do
        local preview = hunt.rewardPreview or (ns.HuntPlanner and ns.HuntPlanner.GetRewardPreview and ns.HuntPlanner:GetRewardPreview(hunt)) or nil
        cards[#cards + 1] = {
            title = hunt.name or L["Unknown prey"],
            detail = FormatReward(preview),
            meta = string.format("%s | %s", hunt.difficulty or L["Unknown difficulty"], hunt.zone or L["Unknown zone"]),
        }
    end
    return cards
end

local function BuildTimelineCards(context)
    local history = FilterTimeline(context)
    if #(context.history or {}) == 0 then
        return {
            {
                title = L["No account timeline yet"],
                detail = L["Completed hunts are added from each character's local journal when that character is seen."],
                meta = L["Timeline is account-local."],
            },
        }
    end
    if #history == 0 then
        return {
            {
                title = L["All timeline entries are hidden"],
                detail = L["Change the Command Center filter to All to show account history."],
                meta = FILTER_LABEL[context.filter] or context.filter,
            },
        }
    end

    local cards = {}
    for index, entry in ipairs(history) do
        if index > 18 then break end
        local reward = entry.reward and (entry.reward.rewardName or entry.reward.rewardType) or L["No reward recorded"]
        cards[#cards + 1] = {
            title = entry.name or L["Unknown prey"],
            detail = string.format("%s | %s | %s", entry.characterName or entry.characterKey or L["Unknown"], entry.difficulty or L["Unknown difficulty"], reward),
            meta = entry.completedDate or tostring(entry.completedAt or ""),
        }
    end
    return cards
end

local function BuildDiagnosticsCards(context)
    local report = ns.HuntDiagnostics and ns.HuntDiagnostics.BuildReport and ns.HuntDiagnostics:BuildReport() or { lines = { L["Diagnostics unavailable."] } }
    local cards = {}
    for _, line in ipairs(report.lines or {}) do
        cards[#cards + 1] = {
            title = L["Diagnostics"],
            detail = line,
            meta = report.generatedAt or "",
            height = 62,
        }
    end
    return cards
end

local CARD_BUILDERS = {
    overview = BuildOverviewCards,
    roster = BuildRosterCards,
    goals = BuildGoalCards,
    rewards = BuildRewardCards,
    timeline = BuildTimelineCards,
    diagnostics = BuildDiagnosticsCards,
}

local function AcquireCards(parent, count)
    HuntCommandCenter.cards = HuntCommandCenter.cards or {}
    for index = #HuntCommandCenter.cards + 1, count do
        HuntCommandCenter.cards[index] = CreateCard(parent)
    end
    return HuntCommandCenter.cards
end

local function ApplyCardSpec(card, spec)
    local p = SP()
    card:SetHeight(spec.height or CARD_HEIGHT)
    card.Title:SetText(spec.title or "")
    card.Detail:SetText(spec.detail or "")
    card.Meta:SetText(spec.meta or "")
    SetTextColor(card.Title, spec.titleColor or p.TitleColor or { 0.94, 0.86, 0.72 })
    SetTextColor(card.Detail, spec.detailColor or p.BodyColor or { 0.77, 0.72, 0.66 })
    SetTextColor(card.Meta, spec.metaColor or p.MutedColor or { 0.58, 0.54, 0.49 })

    local function ApplyAction(button, action)
        if action and action.text and action.onClick then
            button:SetText(action.text)
            button:SetScript("OnClick", action.onClick)
            button:Show()
        else
            button:SetScript("OnClick", nil)
            button:Hide()
        end
    end

    ApplyAction(card.Action1, spec.action1)
    ApplyAction(card.Action2, spec.action2)
end

function HuntCommandCenter:LayoutCards(cards)
    local frame = self.frame
    if not frame then return end
    local scrollChild = frame.ScrollChild
    local pool = AcquireCards(scrollChild, math.max(1, #cards))
    local y = 0

    for index, spec in ipairs(cards) do
        local card = pool[index]
        card:SetParent(scrollChild)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
        card:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -y)
        ApplyCardSpec(card, spec)
        card:Show()
        y = y + (spec.height or CARD_HEIGHT) + CARD_SPACING
    end

    for index = #cards + 1, #pool do
        pool[index]:Hide()
    end

    scrollChild:SetHeight(math.max(1, y))
end

function HuntCommandCenter:Ensure()
    if self.frame then
        return self.frame
    end

    local p = SP()
    local frame = CreateFrame("Frame", FRAME_NAME, UIParent, BACKDROP_TEMPLATE)
    frame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:Hide()
    ApplyDialogBackdrop(frame)

    frame.Title = CreateText(frame, "GameFontNormalLarge")
    frame.Title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -14)
    frame.Title:SetText(L["Account Command Center"])
    SetTextColor(frame.Title, p.TitleColor or { 0.94, 0.86, 0.72 })

    frame.Subtitle = CreateText(frame, "GameFontDisableSmall")
    frame.Subtitle:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -5)
    frame.Subtitle:SetPoint("RIGHT", frame, "RIGHT", -42, 0)
    frame.Subtitle:SetText(L["Account-wide hunt planning, goals, roster, rewards, and diagnostics."])
    SetTextColor(frame.Subtitle, p.MutedColor or { 0.58, 0.54, 0.49 })

    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    frame.CloseButton:SetScript("OnClick", function() HuntCommandCenter:Close() end)

    frame.TabBar = CreateFrame("Frame", nil, frame)
    frame.TabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -64)
    frame.TabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -64)
    frame.TabBar:SetHeight(TAB_HEIGHT)
    frame.TabButtons = {}
    for _, tab in ipairs(TABS) do
        frame.TabButtons[#frame.TabButtons + 1] = CreateTabButton(frame.TabBar, tab)
    end

    frame.Content = CreateFrame("Frame", nil, frame, BACKDROP_TEMPLATE)
    frame.Content:SetPoint("TOPLEFT", frame.TabBar, "BOTTOMLEFT", 0, -10)
    frame.Content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 46)
    ApplyBackdrop(frame.Content, p.SurfaceColor or { 0.08, 0.06, 0.05, 0.96 }, p.BorderSoftColor or { 0.66, 0.49, 0.21, 0.34 })

    frame.ScrollFrame = CreateFrame("ScrollFrame", nil, frame.Content, "UIPanelScrollFrameTemplate")
    frame.ScrollFrame:SetPoint("TOPLEFT", frame.Content, "TOPLEFT", 8, -8)
    frame.ScrollFrame:SetPoint("BOTTOMRIGHT", frame.Content, "BOTTOMRIGHT", -28, 8)
    frame.ScrollChild = CreateFrame("Frame", nil, frame.ScrollFrame)
    frame.ScrollChild:SetSize(PANEL_WIDTH - 70, 1)
    frame.ScrollFrame:SetScrollChild(frame.ScrollChild)
    frame.ScrollFrame:SetScript("OnSizeChanged", function(self)
        frame.ScrollChild:SetWidth(math.max(1, (self:GetWidth() or 1) - 8))
    end)

    frame.Footer = CreateFrame("Frame", nil, frame)
    frame.Footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 12)
    frame.Footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 12)
    frame.Footer:SetHeight(24)

    frame.FilterButton = CreateFrame("Button", nil, frame.Footer, "UIPanelButtonTemplate")
    frame.FilterButton:SetSize(124, 22)
    frame.FilterButton:SetPoint("LEFT", frame.Footer, "LEFT", 0, 0)
    frame.FilterButton:SetScript("OnClick", function()
        local current = GetDashboardState().filter or "all"
        HuntCommandCenter:SetFilter(CycleValue(FILTER_ORDER, current))
    end)

    frame.SortButton = CreateFrame("Button", nil, frame.Footer, "UIPanelButtonTemplate")
    frame.SortButton:SetSize(124, 22)
    frame.SortButton:SetPoint("LEFT", frame.FilterButton, "RIGHT", 8, 0)
    frame.SortButton:SetScript("OnClick", function()
        local current = GetDashboardState().sort or "priority"
        HuntCommandCenter:SetSort(CycleValue(SORT_ORDER, current))
    end)

    frame.SettingsButton = CreateFrame("Button", nil, frame.Footer, "UIPanelButtonTemplate")
    frame.SettingsButton:SetSize(90, 22)
    frame.SettingsButton:SetPoint("RIGHT", frame.Footer, "RIGHT", 0, 0)
    frame.SettingsButton:SetText(L["Settings"])
    frame.SettingsButton:SetScript("OnClick", function()
        if ns.SettingsPanel then ns.SettingsPanel:Open() end
    end)

    frame.HuntsButton = CreateFrame("Button", nil, frame.Footer, "UIPanelButtonTemplate")
    frame.HuntsButton:SetSize(90, 22)
    frame.HuntsButton:SetPoint("RIGHT", frame.SettingsButton, "LEFT", -8, 0)
    frame.HuntsButton:SetText(L["Hunts"])
    frame.HuntsButton:SetScript("OnClick", function()
        if ns.HuntPanel then ns.HuntPanel:ShowStandalone() end
    end)

    self.frame = frame
    LayoutTabs(frame)
    return frame
end

function HuntCommandCenter:SetTab(tabKey)
    SetTab(tabKey)
    self:Refresh("tab")
end

function HuntCommandCenter:SetFilter(filter)
    if ns.Settings and type(ns.Settings.SetCommandCenterFilter) == "function" then
        ns.Settings:SetCommandCenterFilter(filter)
    end
    self:Refresh("filter")
end

function HuntCommandCenter:SetSort(sort)
    if ns.Settings and type(ns.Settings.SetCommandCenterSort) == "function" then
        ns.Settings:SetCommandCenterSort(sort)
    end
    self:Refresh("sort")
end

function HuntCommandCenter:Refresh(source)
    local frame = self:Ensure()
    if ns.HuntRoster and type(ns.HuntRoster.UpdateCurrentCharacter) == "function" then
        ns.HuntRoster:UpdateCurrentCharacter(ns.Controller and ns.Controller.lastSnapshot or nil, { preserveWhenEmpty = true })
    end

    LayoutTabs(frame)
    UpdateTabs(frame)
    local tab = GetTab()
    local context = BuildContext(tab)
    if tab == "timeline" and ns.HuntRoster and type(ns.HuntRoster.GetAccountHistory) == "function" then
        context.history = ns.HuntRoster:GetAccountHistory()
    end
    self.lastRefreshSource = source or "manual"
    context.lastRefreshSource = self.lastRefreshSource
    if frame.FilterButton then
        frame.FilterButton:SetText(FILTER_LABEL[context.filter] or tostring(context.filter or "all"))
    end
    if frame.SortButton then
        frame.SortButton:SetText(SORT_LABEL[context.sort] or tostring(context.sort or "priority"))
    end
    local builder = CARD_BUILDERS[tab] or CARD_BUILDERS.overview
    self:LayoutCards(builder(context))
end

function HuntCommandCenter:Open(tabKey)
    if tabKey then
        SetTab(tabKey)
    end
    local frame = self:Ensure()
    self:Refresh("open")
    frame:Show()
    frame:Raise()
    return true
end

function HuntCommandCenter:Close()
    if self.frame then
        self.frame:Hide()
    end
end
