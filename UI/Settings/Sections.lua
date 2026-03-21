-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Constants = ns.Constants
local Settings = ns.Settings
local L = ns.L
local SP = ns._SP

local ApplyBackdrop = SP.ApplyBackdrop
local ApplyCardBackdrop = SP.ApplyCardBackdrop
local ApplyInsetBackdrop = SP.ApplyInsetBackdrop
local ApplyAccentLineColor = SP.ApplyAccentLineColor
local ApplyHighlightColor = SP.ApplyHighlightColor
local HideSliderTemplateLabels = SP.HideSliderTemplateLabels
local ResolveValue = SP.ResolveValue
local SetTextColor = SP.SetTextColor

local RELEASE_SECTION_ORDER = { "Added", "Changed", "Fixed", "Removed" }
local SOCIAL_LINKS = {
    {
        title = "GitHub Repository",
        url = "https://github.com/Weischbier/Preybreaker",
    },
    {
        title = "GitHub Issues",
        url = "https://github.com/Weischbier/Preybreaker/issues",
    },
    {
        title = "CurseForge",
        url = "https://www.curseforge.com/wow/addons/preybreaker",
    },
    {
        title = "Wago Addons",
        url = "https://addons.wago.io/addons/preybreaker",
    },
}

local function SetEnabledState(widget, enabled)
    if not widget then
        return
    end

    if widget.SetEnabled then
        widget:SetEnabled(enabled)
    elseif enabled and widget.Enable then
        widget:Enable()
    elseif not enabled and widget.Disable then
        widget:Disable()
    end
end

local function GetChoiceLabel(options, value)
    for _, option in ipairs(options or {}) do
        if option.value == value then
            return option.label
        end
    end

    return nil
end

local function GetContentWidth()
    local panel = Constants.SettingsPanel
    return panel.Width - (panel.Padding * 2) - panel.SidebarWidth - 18
end

local function CreateContentHost(parent)
    local panel = Constants.SettingsPanel

    local contentHost = CreateFrame("Frame", nil, parent, SP.BACKDROP_TEMPLATE)
    contentHost:SetAllPoints(parent)
    ApplyBackdrop(contentHost, { 0.05, 0.04, 0.03, 0.58 }, panel.BorderSoftColor)

    return contentHost
end

local function CreateScrollFrame(parent, nameSuffix)
    local scrollFrame = CreateFrame("ScrollFrame", nameSuffix and (SP.PANEL_NAME .. nameSuffix) or nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 6)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(math.max(1, GetContentWidth() - 40))
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    local function UpdateScrollChildWidth()
        local viewportWidth = scrollFrame:GetWidth() or 0
        if viewportWidth <= 0 then
            return
        end

        local scrollbar = scrollFrame.ScrollBar
        local scrollbarWidth = 0
        if scrollbar and scrollbar.IsShown and scrollbar:IsShown() and scrollbar.GetWidth then
            scrollbarWidth = scrollbar:GetWidth() or 0
        end

        -- Keep a small right gutter so card borders never collide with the scroll bar.
        local contentPadding = 8
        scrollChild:SetWidth(math.max(1, viewportWidth - scrollbarWidth - contentPadding))
    end

    if scrollFrame.HookScript then
        scrollFrame:HookScript("OnSizeChanged", UpdateScrollChildWidth)
        scrollFrame:HookScript("OnShow", UpdateScrollChildWidth)
    else
        scrollFrame:SetScript("OnSizeChanged", UpdateScrollChildWidth)
        scrollFrame:SetScript("OnShow", UpdateScrollChildWidth)
    end
    if scrollFrame.ScrollBar and scrollFrame.ScrollBar.HookScript then
        scrollFrame.ScrollBar:HookScript("OnShow", UpdateScrollChildWidth)
        scrollFrame.ScrollBar:HookScript("OnHide", UpdateScrollChildWidth)
    end

    UpdateScrollChildWidth()

    return scrollFrame, scrollChild
end

local function AddWrappedLine(parent, text, fontObject, color, offsetX, currentY, contentWidth)
    local line = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormalSmall")
    local insetX = offsetX or 0
    local width = contentWidth or parent:GetWidth() or 0
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", insetX, currentY)
    line:SetWidth(math.max(32, width - insetX - 4))
    line:SetJustifyH("LEFT")
    line:SetJustifyV("TOP")
    line:SetWordWrap(true)
    line:SetText(text)
    SetTextColor(line, color)

    local lineHeight = line:GetStringHeight() or 10
    return line, currentY - lineHeight - 4
end

local function GetChangelogSource()
    local source = ns.ChangelogData
    if type(source) == "table" then
        if type(source.GetVisibleReleases) == "function" then
            return source:GetVisibleReleases()
        end
        if type(source.Releases) == "table" then
            return source.Releases
        end
    end

    return {}
end

local function GetRoadmapSource()
    local source = ns.RoadmapData
    if type(source) ~= "table" then
        return {}, {}
    end

    local knownIssues = type(source.KnownIssues) == "table" and source.KnownIssues or {}
    local plannedFeatures = type(source.PlannedFeatures) == "table" and source.PlannedFeatures or {}
    return knownIssues, plannedFeatures
end

local function GetReleaseTitle(release)
    if type(release) ~= "table" then
        return "Changelog"
    end

    return release.title or release.version or release.name or "Changelog"
end

local function GetReleaseDescription(release)
    if type(release) ~= "table" then
        return ""
    end

    if release.description then
        return release.description
    end
    if release.date then
        return release.date
    end

    return ""
end

local function BuildReleaseCard(parent, release)
    local panel = Constants.SettingsPanel
    local parentWidth = parent and parent:GetWidth() or 0
    if not parentWidth or parentWidth <= 0 then
        parentWidth = math.max(260, GetContentWidth() - 32)
    end

    local card = SP.CreateSectionCard(parent, GetReleaseTitle(release), GetReleaseDescription(release))
    card:SetWidth(parentWidth)
    local content = CreateFrame("Frame", nil, card)
    content:SetPoint("TOPLEFT", card.AccentLine, "BOTTOMLEFT", 0, -12)
    content:SetPoint("TOPRIGHT", card.AccentLine, "BOTTOMRIGHT", 0, -12)
    content:SetWidth(math.max(32, parentWidth - 32))

    local currentY = 0
    local contentWidth = content:GetWidth() or math.max(32, parentWidth - 32)
    local sections = type(release) == "table" and release.sections or nil

    for _, sectionName in ipairs(RELEASE_SECTION_ORDER) do
        local entries = sections and sections[sectionName] or nil
        if type(entries) == "table" and #entries > 0 then
            local header
            header, currentY = AddWrappedLine(content, sectionName, "GameFontHighlightSmall", panel.AccentColor, 0, currentY, contentWidth)
            SetTextColor(header, panel.AccentColor)

            for _, entry in ipairs(entries) do
                local bulletText = "- " .. tostring(entry)
                local line
                line, currentY = AddWrappedLine(content, bulletText, "GameFontNormalSmall", panel.BodyColor, 10, currentY, contentWidth)
                SetTextColor(line, panel.BodyColor)
            end

            currentY = currentY - 4
        end
    end

    local contentHeight = math.max(0, math.abs(currentY))
    content:SetHeight(contentHeight)

    local titleHeight = card.Title:GetStringHeight() or 14
    local descriptionHeight = card.Description:GetStringHeight() or 10
    local headerHeight = 14 + titleHeight + 4 + descriptionHeight + 12
    card:SetHeight(math.max(headerHeight + contentHeight + 18, 96))

    return card
end

local function ClearCards(page)
    if not page or not page.Cards then
        return
    end

    for _, card in ipairs(page.Cards) do
        card:Hide()
        card:SetParent(nil)
    end

    wipe(page.Cards)
end

local function GetCardBuildWidth(page)
    if not page or not page.ScrollChild or type(page.ScrollChild.GetWidth) ~= "function" then
        return 0
    end

    return math.floor((page.ScrollChild:GetWidth() or 0) + 0.5)
end

local function ShouldRebuildCards(page)
    if not page or not page.cardsBuilt then
        return true
    end

    local currentWidth = GetCardBuildWidth(page)
    if currentWidth <= 0 then
        return false
    end

    return math.abs(currentWidth - (page.lastBuildWidth or 0)) >= 2
end

local function MarkCardsBuilt(page)
    if not page then
        return
    end

    page.cardsBuilt = true
    page.lastBuildWidth = GetCardBuildWidth(page)
end

local function BuildChangelogCards(page)
    local panel = Constants.SettingsPanel
    local releases = GetChangelogSource()
    local previousCard = nil
    local totalHeight = 0

    ClearCards(page)

    if #releases == 0 then
        local empty = SP.CreateSectionCard(page.ScrollChild, "Changelog", "No packaged changelog data is available.")
        empty:SetHeight(120)
        empty:SetPoint("TOPLEFT", page.ScrollChild, "TOPLEFT", 0, 0)
        empty:SetPoint("TOPRIGHT", page.ScrollChild, "TOPRIGHT", 0, 0)
        page.Cards[#page.Cards + 1] = empty
        page.ScrollChild:SetHeight(160)
        MarkCardsBuilt(page)
        return
    end

    for index, release in ipairs(releases) do
        local card = BuildReleaseCard(page.ScrollChild, release)
        if previousCard then
            card:SetPoint("TOPLEFT", previousCard, "BOTTOMLEFT", 0, -panel.SectionSpacing)
            card:SetPoint("TOPRIGHT", previousCard, "BOTTOMRIGHT", 0, -panel.SectionSpacing)
            totalHeight = totalHeight + panel.SectionSpacing
        else
            card:SetPoint("TOPLEFT", page.ScrollChild, "TOPLEFT", 0, 0)
            card:SetPoint("TOPRIGHT", page.ScrollChild, "TOPRIGHT", 0, 0)
        end

        totalHeight = totalHeight + card:GetHeight()
        previousCard = card
        page.Cards[index] = card
    end

    page.ScrollChild:SetHeight(math.max(totalHeight + panel.ContentInset, Constants.SettingsPanel.Height - Constants.SettingsPanel.HeaderHeight - (Constants.SettingsPanel.Padding * 2)))
    MarkCardsBuilt(page)
end

local function CreateSocialLinkCard(parent, link)
    local panel = Constants.SettingsPanel
    local card = SP.CreateSectionCard(
        parent,
        link.title,
        L["Select URL text and copy it."]
    )

    local urlBox = CreateFrame("EditBox", nil, card, "InputBoxTemplate")
    urlBox:SetAutoFocus(false)
    urlBox:SetFontObject("GameFontHighlightSmall")
    urlBox:SetHeight(24)
    urlBox:SetText(link.url)
    if type(urlBox.SetTextInsets) == "function" then
        urlBox:SetTextInsets(8, 8, 2, 2)
    end
    urlBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    urlBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    urlBox:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    local selectButton = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    selectButton:SetSize(76, 22)
    selectButton:SetText(L["Select"])
    selectButton:SetScript("OnClick", function()
        urlBox:SetFocus()
        urlBox:HighlightText()
    end)

    urlBox:SetPoint("TOPLEFT", card.Description, "BOTTOMLEFT", 0, -10)
    urlBox:SetPoint("RIGHT", selectButton, "LEFT", -8, 0)
    selectButton:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -(Constants.SettingsPanel.SectionHeaderHeight + 16))

    local titleHeight = card.Title:GetStringHeight() or 14
    local descriptionHeight = card.Description:GetStringHeight() or 10
    local headerHeight = 14 + titleHeight + 4 + descriptionHeight + 12
    card:SetHeight(math.max(headerHeight + 42, 108))

    return card
end

local function BuildSocialCards(page)
    local panel = Constants.SettingsPanel
    local previousCard = nil
    local totalHeight = 0

    ClearCards(page)

    for index, link in ipairs(SOCIAL_LINKS) do
        local card = CreateSocialLinkCard(page.ScrollChild, link)
        if previousCard then
            card:SetPoint("TOPLEFT", previousCard, "BOTTOMLEFT", 0, -panel.SectionSpacing)
            card:SetPoint("TOPRIGHT", previousCard, "BOTTOMRIGHT", 0, -panel.SectionSpacing)
            totalHeight = totalHeight + panel.SectionSpacing
        else
            card:SetPoint("TOPLEFT", page.ScrollChild, "TOPLEFT", 0, 0)
            card:SetPoint("TOPRIGHT", page.ScrollChild, "TOPRIGHT", 0, 0)
        end

        totalHeight = totalHeight + card:GetHeight()
        previousCard = card
        page.Cards[index] = card
    end

    page.ScrollChild:SetHeight(math.max(totalHeight + panel.ContentInset, Constants.SettingsPanel.Height - Constants.SettingsPanel.HeaderHeight - (Constants.SettingsPanel.Padding * 2)))
    MarkCardsBuilt(page)
end

local function BuildBulletListCard(parent, titleText, descriptionText, entries, emptyMessage)
    local panel = Constants.SettingsPanel
    local parentWidth = parent and parent:GetWidth() or 0
    if not parentWidth or parentWidth <= 0 then
        parentWidth = math.max(260, GetContentWidth() - 32)
    end

    local card = SP.CreateSectionCard(parent, titleText, descriptionText)
    card:SetWidth(parentWidth)

    local content = CreateFrame("Frame", nil, card)
    content:SetPoint("TOPLEFT", card.AccentLine, "BOTTOMLEFT", 0, -12)
    content:SetPoint("TOPRIGHT", card.AccentLine, "BOTTOMRIGHT", 0, -12)
    content:SetWidth(math.max(32, parentWidth - 32))

    local currentY = 0
    local contentWidth = content:GetWidth() or math.max(32, parentWidth - 32)
    if type(entries) == "table" and #entries > 0 then
        for _, entry in ipairs(entries) do
            local line
            line, currentY = AddWrappedLine(content, "- " .. tostring(entry), "GameFontNormalSmall", panel.BodyColor, 10, currentY, contentWidth)
            SetTextColor(line, panel.BodyColor)
        end
    else
        local line
        line, currentY = AddWrappedLine(content, "- " .. emptyMessage, "GameFontDisableSmall", panel.MutedColor, 10, currentY, contentWidth)
        SetTextColor(line, panel.MutedColor)
    end

    local contentHeight = math.max(0, math.abs(currentY))
    content:SetHeight(contentHeight)

    local titleHeight = card.Title:GetStringHeight() or 14
    local descriptionHeight = card.Description:GetStringHeight() or 10
    local headerHeight = 14 + titleHeight + 4 + descriptionHeight + 12
    card:SetHeight(math.max(headerHeight + contentHeight + 18, 96))

    return card
end

local function BuildRoadmapCards(page)
    local panel = Constants.SettingsPanel
    local knownIssues, plannedFeatures = GetRoadmapSource()
    local totalHeight = 0

    ClearCards(page)

    local issuesCard = BuildBulletListCard(
        page.ScrollChild,
        L["Known issues"],
        L["Items tracked for upcoming releases."],
        knownIssues,
        L["No known issues currently listed."]
    )
    issuesCard:SetPoint("TOPLEFT", page.ScrollChild, "TOPLEFT", 0, 0)
    issuesCard:SetPoint("TOPRIGHT", page.ScrollChild, "TOPRIGHT", 0, 0)
    totalHeight = totalHeight + issuesCard:GetHeight()
    page.Cards[#page.Cards + 1] = issuesCard

    local plansCard = BuildBulletListCard(
        page.ScrollChild,
        L["Planned features"],
        L["Items tracked for upcoming releases."],
        plannedFeatures,
        L["No planned features currently listed."]
    )
    plansCard:SetPoint("TOPLEFT", issuesCard, "BOTTOMLEFT", 0, -panel.SectionSpacing)
    plansCard:SetPoint("TOPRIGHT", issuesCard, "BOTTOMRIGHT", 0, -panel.SectionSpacing)
    totalHeight = totalHeight + panel.SectionSpacing + plansCard:GetHeight()
    page.Cards[#page.Cards + 1] = plansCard

    page.ScrollChild:SetHeight(math.max(totalHeight + panel.ContentInset, Constants.SettingsPanel.Height - Constants.SettingsPanel.HeaderHeight - (Constants.SettingsPanel.Padding * 2)))
    MarkCardsBuilt(page)
end

function SP.CreateSections(parent)
    local panel = Constants.SettingsPanel
    local contentHost = CreateContentHost(parent)
    local scrollFrame, scrollChild = CreateScrollFrame(contentHost, "SettingsScrollFrame")

    local controls = {}
    local sectionSpecs = {
        {
            title = L["Tracker"],
            description = L["Pick the tracker style and the overall size that feels right on your screen."],
            fields = {
                {
                    type = "toggle",
                    key = "enabled",
                    title = L["Enable tracker"],
                    description = L["Turn Preybreaker on or off without losing your layout."],
                    get = function()
                        return Settings:IsEnabled()
                    end,
                    set = function(value)
                        Settings:SetEnabled(value)
                    end,
                },
                {
                    type = "choice",
                    key = "displayMode",
                    title = L["Display style"],
                    description = L["Choose the shape that best fits your UI."],
                    options = SP.MODE_OPTIONS,
                    get = function()
                        return Settings:GetDisplayMode()
                    end,
                    set = function(value)
                        Settings:SetDisplayMode(value)
                    end,
                },
                {
                    type = "slider",
                    key = "scale",
                    title = L["Display size"],
                    description = L["Make the current style bigger or smaller."],
                    minValue = 0.50,
                    maxValue = 2.00,
                    step = 0.05,
                    formatter = function(value)
                        return string.format("%d%%", math.floor((value * 100) + 0.5))
                    end,
                    get = function()
                        return Settings:GetScale()
                    end,
                    set = function(value)
                        Settings:SetScale(value)
                    end,
                },
            },
        },
        {
            title = L["Placement"],
            description = L["Keep the tracker attached to the prey icon and nudge it into place."],
            fields = {
                {
                    type = "toggle",
                    key = "hideBlizzardWidget",
                    title = L["Hide Blizzard prey icon"],
                    description = L["Show only Preybreaker while the prey hunt is active."],
                    get = function()
                        return Settings:ShouldHideBlizzardWidget()
                    end,
                    set = function(value)
                        Settings:SetHideBlizzardWidget(value)
                    end,
                },
                {
                    type = "slider",
                    key = "offsetX",
                    title = L["Horizontal position"],
                    description = L["Nudge the tracker left or right around the prey icon."],
                    minValue = -200,
                    maxValue = 200,
                    step = 1,
                    formatter = function(value)
                        return string.format("%d", value)
                    end,
                    get = function()
                        return Settings:GetOffsetX()
                    end,
                    set = function(value)
                        Settings:SetOffsetX(value)
                    end,
                },
                {
                    type = "slider",
                    key = "offsetY",
                    title = L["Vertical position"],
                    description = L["Nudge the tracker up or down around the prey icon."],
                    minValue = -200,
                    maxValue = 200,
                    step = 1,
                    formatter = function(value)
                        return string.format("%d", value)
                    end,
                    get = function()
                        return Settings:GetOffsetY()
                    end,
                    set = function(value)
                        Settings:SetOffsetY(value)
                    end,
                },
            },
        },
        {
            title = L["Readout"],
            description = L["Choose which cues appear around the tracker while you hunt."],
            fields = {
                {
                    type = "toggle",
                    key = "showValueText",
                    title = L["Show progress number"],
                    description = L["Show a simple number inside the tracker."],
                    get = function()
                        return Settings:ShouldShowValueText()
                    end,
                    set = function(value)
                        Settings:SetShowValueText(value)
                    end,
                },
                {
                    type = "toggle",
                    key = "showStageBadge",
                    title = L["Show stage badge"],
                    description = L["Display COLD, WARM, HOT, or FINAL below the tracker."],
                    disabledDescription = L["Stage badges are available in ring and orb styles."],
                    isAvailable = function()
                        return Settings:GetDisplayMode() ~= Constants.DisplayMode.Bar
                    end,
                    get = function()
                        return Settings:ShouldShowStageBadge()
                    end,
                    set = function(value)
                        Settings:SetShowStageBadge(value)
                    end,
                },
            },
        },
        {
            title = L["Text style"],
            description = L["Adjust tracker text styling without adding a hard dependency. LibSharedMedia fonts appear automatically when the library is installed."],
            fields = {
                {
                    type = "dropdown",
                    key = "textFontFace",
                    title = L["Font face"],
                    description = L["Choose a Blizzard font by default, or pick a LibSharedMedia font when one is available."],
                    options = function()
                        return ns.TextStyle and ns.TextStyle:GetFontChoices() or {}
                    end,
                    get = function()
                        return Settings:GetTextFontFace()
                    end,
                    set = function(value)
                        Settings:SetTextFontFace(value)
                    end,
                },
                {
                    type = "choice",
                    key = "textOutlineMode",
                    title = L["Outline"],
                    description = L["Override the text outline used by the tracker readouts."],
                    options = function()
                        return ns.TextStyle and ns.TextStyle:GetOutlineChoices() or {}
                    end,
                    get = function()
                        return Settings:GetTextOutlineMode()
                    end,
                    set = function(value)
                        Settings:SetTextOutlineMode(value)
                    end,
                },
                {
                    type = "choice",
                    key = "textShadowMode",
                    title = L["Shadow"],
                    description = L["Override the text shadow used by the tracker readouts."],
                    options = function()
                        return ns.TextStyle and ns.TextStyle:GetShadowChoices() or {}
                    end,
                    get = function()
                        return Settings:GetTextShadowMode()
                    end,
                    set = function(value)
                        Settings:SetTextShadowMode(value)
                    end,
                },
                {
                    type = "slider",
                    key = "valueTextScale",
                    title = L["Number size"],
                    description = L["Scale the progress number and the text-only readout without changing the tracker frame itself."],
                    minValue = 0.75,
                    maxValue = 1.75,
                    step = 0.05,
                    formatter = function(value)
                        return string.format("%d%%", math.floor((value * 100) + 0.5))
                    end,
                    get = function()
                        return Settings:GetValueTextScale()
                    end,
                    set = function(value)
                        Settings:SetValueTextScale(value)
                    end,
                },
                {
                    type = "slider",
                    key = "stageTextScale",
                    title = L["Badge size"],
                    description = L["Scale the stage badge text separately from the main progress number."],
                    minValue = 0.75,
                    maxValue = 1.75,
                    step = 0.05,
                    formatter = function(value)
                        return string.format("%d%%", math.floor((value * 100) + 0.5))
                    end,
                    get = function()
                        return Settings:GetStageTextScale()
                    end,
                    set = function(value)
                        Settings:SetStageTextScale(value)
                    end,
                },
            },
        },
        {
            title = L["Quest help"],
            description = L["Keep the active prey quest easy to spot while the hunt is running."],
            fields = {
                {
                    type = "toggle",
                    key = "autoWatchQuest",
                    title = L["Add prey quest to tracker"],
                    description = L["Automatically place the active prey quest in your watch list."],
                    get = function()
                        return Settings:ShouldAutoWatchPreyQuest()
                    end,
                    set = function(value)
                        Settings:SetAutoWatchPreyQuest(value)
                    end,
                },
                {
                    type = "toggle",
                    key = "autoSuperTrackQuest",
                    title = L["Focus the prey quest"],
                    description = L["Keep the active prey quest selected for your objective arrow."],
                    get = function()
                        return Settings:ShouldAutoSuperTrackPreyQuest()
                    end,
                    set = function(value)
                        Settings:SetAutoSuperTrackPreyQuest(value)
                    end,
                },
                {
                    type = "toggle",
                    key = "autoTurnInQuest",
                    title = L["Auto turn-in prey quest"],
                    description = L["Automatically complete the prey quest when it pops up, unless a reward choice is required."],
                    get = function()
                        return Settings:ShouldAutoTurnInPreyQuest()
                    end,
                    set = function(value)
                        Settings:SetAutoTurnInPreyQuest(value)
                    end,
                },
            },
        },
        {
            title = L["Random hunt"],
            description = L["Automate randomized hunt purchasing from Astalor Bloodsworn."],
            fields = {
                {
                    type = "toggle",
                    key = "autoPurchaseRandomHunt",
                    title = L["Auto-purchase random hunt"],
                    description = L["Automatically request a randomized hunt from Astalor Bloodsworn when you open his gossip window."],
                    get = function()
                        return Settings:ShouldAutoPurchaseRandomHunt()
                    end,
                    set = function(value)
                        Settings:SetAutoPurchaseRandomHunt(value)
                    end,
                },
                {
                    type = "choice",
                    key = "randomHuntDifficulty",
                    title = L["Hunt difficulty"],
                    description = L["Choose which difficulty to purchase when auto-buying a randomized hunt."],
                    options = {
                        { value = "normal", label = L["Normal"] },
                        { value = "hard", label = L["Hard"] },
                        { value = "nightmare", label = L["Nightmare"] },
                    },
                    isAvailable = function()
                        return Settings:ShouldAutoPurchaseRandomHunt()
                    end,
                    get = function()
                        return Settings:GetRandomHuntDifficulty()
                    end,
                    set = function(value)
                        Settings:SetRandomHuntDifficulty(value)
                    end,
                },
                {
                    type = "slider",
                    key = "remnantThreshold",
                    title = L["Remnant reserve"],
                    description = L["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."],
                    minValue = 0,
                    maxValue = 2500,
                    step = 50,
                    formatter = function(value)
                        return string.format("%d", value)
                    end,
                    isAvailable = function()
                        return Settings:ShouldAutoPurchaseRandomHunt()
                    end,
                    get = function()
                        return Settings:GetRemnantThreshold()
                    end,
                    set = function(value)
                        Settings:SetRemnantThreshold(value)
                    end,
                },
            },
        },
        {
            title = L["Hunt rewards"],
            description = L["Automatically choose rewards when completing a prey hunt."],
            fields = {
                {
                    type = "toggle",
                    key = "autoSelectHuntReward",
                    title = L["Auto-select hunt reward"],
                    description = L["Automatically pick a reward when a completed hunt offers multiple choices."],
                    get = function()
                        return Settings:ShouldAutoSelectHuntReward()
                    end,
                    set = function(value)
                        Settings:SetAutoSelectHuntReward(value)
                    end,
                },
                {
                    type = "dropdown",
                    key = "preferredHuntReward",
                    title = L["Preferred reward"],
                    description = L["The reward type to pick first when completing a hunt."],
                    options = function()
                        return {
                            { value = "dawncrest", label = L["Gear upgrade currency"] },
                            { value = "remnant", label = L["Remnant of Anguish"] },
                            { value = "gold", label = L["Gold"] },
                            { value = "marl", label = L["Voidlight Marl"] },
                        }
                    end,
                    isAvailable = function()
                        return Settings:ShouldAutoSelectHuntReward()
                    end,
                    get = function()
                        return Settings:GetPreferredHuntReward()
                    end,
                    set = function(value)
                        Settings:SetPreferredHuntReward(value)
                    end,
                },
                {
                    type = "dropdown",
                    key = "fallbackHuntReward",
                    title = L["Fallback reward"],
                    description = L["The reward to pick if your preferred choice is unavailable or its currency is capped."],
                    options = function()
                        return {
                            { value = "dawncrest", label = L["Gear upgrade currency"] },
                            { value = "remnant", label = L["Remnant of Anguish"] },
                            { value = "gold", label = L["Gold"] },
                            { value = "marl", label = L["Voidlight Marl"] },
                        }
                    end,
                    isAvailable = function()
                        return Settings:ShouldAutoSelectHuntReward()
                    end,
                    get = function()
                        return Settings:GetFallbackHuntReward()
                    end,
                    set = function(value)
                        Settings:SetFallbackHuntReward(value)
                    end,
                },
            },
        },
        {
            title = L["Audio & feedback"],
            description = L["Control sound cues that fire when your hunt phase changes."],
            fields = {
                {
                    type = "toggle",
                    key = "playSoundOnPhaseChange",
                    title = L["Play sound on phase change"],
                    description = L["Hear an audio cue when the prey hunt moves to a new stage."],
                    get = function()
                        return Settings:ShouldPlaySoundOnPhaseChange()
                    end,
                    set = function(value)
                        Settings:SetPlaySoundOnPhaseChange(value)
                    end,
                },
            },
        },
        {
            title = L["Profile"],
            description = L["Choose whether this character uses its own settings or the account-wide defaults."],
            fields = {
                {
                    type = "toggle",
                    key = "useCharacterProfile",
                    title = L["Use character profile"],
                    description = L["Store a separate set of settings for this character."],
                    get = function()
                        return Settings:ShouldUseCharacterProfile()
                    end,
                    set = function(value)
                        Settings:SetUseCharacterProfile(value)
                    end,
                },
            },
        },
    }

    local currentSection
    local contentHeight = 0
    for _, sectionSpec in ipairs(sectionSpecs) do
        local section = SP.CreateSection(scrollChild, sectionSpec, controls)
        if currentSection then
            section:SetPoint("TOPLEFT", currentSection, "BOTTOMLEFT", 0, -panel.SectionSpacing)
            section:SetPoint("TOPRIGHT", currentSection, "BOTTOMRIGHT", 0, -panel.SectionSpacing)
            contentHeight = contentHeight + panel.SectionSpacing
        else
            section:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
            section:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, 0)
        end
        contentHeight = contentHeight + section:GetHeight()
        currentSection = section
    end

    scrollChild:SetHeight(math.max(contentHeight + panel.ContentInset, panel.Height - panel.HeaderHeight - (panel.Padding * 2)))

    return {
        Host = contentHost,
        ScrollFrame = scrollFrame,
        ScrollChild = scrollChild,
        Controls = controls,
        Refresh = function()
            for _, control in ipairs(controls) do
                control:Refresh()
            end
        end,
    }
end

function SP.CreateChangelogPage(parent)
    local panel = Constants.SettingsPanel
    local contentHost = CreateContentHost(parent)
    local scrollFrame, scrollChild = CreateScrollFrame(contentHost, "ChangelogScrollFrame")

    local page = {
        Host = contentHost,
        ScrollFrame = scrollFrame,
        ScrollChild = scrollChild,
        Cards = {},
        cardsBuilt = false,
        lastBuildWidth = 0,
    }

    function page:Refresh(force)
        if force or ShouldRebuildCards(self) then
            BuildChangelogCards(self)
        end
    end

    BuildChangelogCards(page)
    return page
end

function SP.CreateSocialPage(parent)
    local contentHost = CreateContentHost(parent)
    local scrollFrame, scrollChild = CreateScrollFrame(contentHost, "SocialScrollFrame")

    local page = {
        Host = contentHost,
        ScrollFrame = scrollFrame,
        ScrollChild = scrollChild,
        Cards = {},
        cardsBuilt = false,
        lastBuildWidth = 0,
    }

    function page:Refresh(force)
        if force or ShouldRebuildCards(self) then
            BuildSocialCards(self)
        end
    end

    BuildSocialCards(page)
    return page
end

function SP.CreateRoadmapPage(parent)
    local contentHost = CreateContentHost(parent)
    local scrollFrame, scrollChild = CreateScrollFrame(contentHost, "RoadmapScrollFrame")

    local page = {
        Host = contentHost,
        ScrollFrame = scrollFrame,
        ScrollChild = scrollChild,
        Cards = {},
        cardsBuilt = false,
        lastBuildWidth = 0,
    }

    function page:Refresh(force)
        if force or ShouldRebuildCards(self) then
            BuildRoadmapCards(self)
        end
    end

    BuildRoadmapCards(page)
    return page
end

function SP.UpdatePreviewStageChips(preview, progressState)
    for _, chip in ipairs(preview.StageChips) do
        SP.UpdateStageChip(chip, chip.state == progressState)
    end
end
