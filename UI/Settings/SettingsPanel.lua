-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Constants = ns.Constants
local Settings = ns.Settings
local L = ns.L

local SP = ns._SP

local SetTextColor = SP.SetTextColor
local ApplyBackdrop = SP.ApplyBackdrop
local GetPreviewSnapshot = SP.GetPreviewSnapshot
local GetDisplayModeSummary = SP.GetDisplayModeSummary
local GetReadoutSummary = SP.GetReadoutSummary
local GetQuestHelperSummary = SP.GetQuestHelperSummary
local GetPreviewNote = SP.GetPreviewNote
local ApplyPreviewWidgetTexture = SP.ApplyPreviewWidgetTexture
local UpdateBadgeAnchor = SP.UpdateBadgeAnchor
local UpdatePreviewProgress = SP.UpdatePreviewProgress
local UpdatePreviewStageChips = SP.UpdatePreviewStageChips
local PANEL_NAME = SP.PANEL_NAME
local BACKDROP_TEMPLATE = SP.BACKDROP_TEMPLATE

local function ApplyPreviewTextStyles(preview)
    local textStyle = ns.TextStyle
    if not textStyle or not preview then
        return
    end

    if preview.Progress and preview.Progress.ValueText then
        textStyle:ApplyValue(preview.Progress.ValueText)
    end
    if preview.BarProgress and preview.BarProgress.ValueText then
        textStyle:ApplyValue(preview.BarProgress.ValueText)
    end
    if preview.OrbProgress and preview.OrbProgress.ValueText then
        textStyle:ApplyValue(preview.OrbProgress.ValueText)
    end
    if preview.BadgeText then
        textStyle:ApplyStage(preview.BadgeText)
    end
    if preview.TextDisplay then
        textStyle:ApplyValue(preview.TextDisplay)
    end
end

local TAB_SETTINGS = "settings"
local TAB_CHANGELOG = "changelog"
local TAB_SOCIAL = "social"
local TAB_ROADMAP = "roadmap"
local SETTINGS_TAB_KEY = "settingsTab"

local function IsValidTab(tabKey)
    return tabKey == TAB_SETTINGS or tabKey == TAB_CHANGELOG or tabKey == TAB_SOCIAL or tabKey == TAB_ROADMAP
end

local function NormalizeTab(tabKey)
    if IsValidTab(tabKey) then
        return tabKey
    end

    return TAB_SETTINGS
end

local function GetStoredTab()
    local settings = ns.Settings
    if not settings then
        return TAB_SETTINGS
    end

    if type(settings.GetValue) == "function" then
        local value = settings:GetValue(SETTINGS_TAB_KEY)
        if IsValidTab(value) then
            return value
        end
    end

    local db = type(settings.GetDB) == "function" and settings:GetDB() or nil
    if type(db) == "table" and IsValidTab(db[SETTINGS_TAB_KEY]) then
        return db[SETTINGS_TAB_KEY]
    end

    return TAB_SETTINGS
end

local function SetStoredTab(tabKey)
    local settings = ns.Settings
    if not settings then
        return
    end

    tabKey = NormalizeTab(tabKey)

    if type(settings.SetValue) == "function" then
        local value = settings:SetValue(SETTINGS_TAB_KEY, tabKey)
        if value ~= nil then
            return
        end
    end

    local db = type(settings.GetDB) == "function" and settings:GetDB() or nil
    if type(db) == "table" then
        db[SETTINGS_TAB_KEY] = tabKey
    end
end

ns.SettingsPanel = {}

function ns.SettingsPanel:RefreshSummary(snapshot, live)
    if not self.summary then
        return
    end

    local panel = Constants.SettingsPanel
    local summary = self.summary
    local statusText
    local statusColor

    if not Settings:IsEnabled() then
        statusText = L["DISABLED"]
        statusColor = panel.MutedColor
        summary.StatusText:SetText(L["Preybreaker is turned off. Your current layout stays saved."])
    elseif live and snapshot and snapshot.active and snapshot.progressState ~= nil then
        local stageLabel = Constants.StageLabelByState[snapshot.progressState] or L["ACTIVE"]
        statusText = string.format("%s %d%%", stageLabel, snapshot.percent or 0)
        statusColor = Constants.ColorByState[snapshot.progressState] or panel.AccentColor
        summary.StatusText:SetText(L["Live prey hunt detected. The preview mirrors the current tracker state."])
    else
        statusText = L["SAMPLE"]
        statusColor = panel.AccentColor
        summary.StatusText:SetText(L["No prey hunt is active right now, so the preview shows a sample state."])
    end

    ApplyBackdrop(
        summary.StatusPill,
        { statusColor[1], statusColor[2], statusColor[3], 0.20 },
        { statusColor[1], statusColor[2], statusColor[3], 0.95 }
    )
    summary.StatusPill.Text:SetText(statusText)
    SetTextColor(summary.StatusPill.Text, panel.TitleColor)

    summary.StyleValue:SetText(GetDisplayModeSummary(Settings:GetDisplayMode()))
    summary.PlacementValue:SetText(L["Attached"])
    summary.WidgetValue:SetText(Settings:ShouldHideBlizzardWidget() and L["Overlay only"] or L["Show both"])
    summary.ReadoutValue:SetText(GetReadoutSummary())
    summary.QuestValue:SetText(GetQuestHelperSummary())

    summary:ResizeToFit()
end

function ns.SettingsPanel:RefreshControls()
    if not self.controls then
        return
    end

    for _, control in ipairs(self.controls) do
        control:Refresh()
    end

    local previewSnapshot, live = GetPreviewSnapshot()
    self:RefreshSummary(previewSnapshot, live)
end

function ns.SettingsPanel:RefreshPreview(snapshot)
    if not self.preview then
        return
    end

    local previewSnapshot, live = GetPreviewSnapshot(snapshot)
    local color = Settings:GetEffectiveColor(previewSnapshot.progressState)
    local showValueText = Settings:ShouldShowValueText()
    local showStageBadge = Settings:ShouldShowStageBadge()
    local displayMode = Settings:GetDisplayMode()
    local hideWidget = Settings:ShouldHideBlizzardWidget()
    local stageLabel = Constants.StageLabelByState[previewSnapshot.progressState]
    local activeProgress = self.preview.Progress
    if displayMode == Constants.DisplayMode.Bar then
        activeProgress = self.preview.BarProgress
    elseif displayMode == Constants.DisplayMode.Orbs then
        activeProgress = self.preview.OrbProgress
    end

    self:RefreshSummary(previewSnapshot, live)
    ApplyPreviewTextStyles(self.preview)

    ApplyPreviewWidgetTexture(self.preview.HostIcon, previewSnapshot)
    self.preview.HostIcon:SetAlpha(hideWidget and 0.14 or 1)

    self.preview.Overlay:ClearAllPoints()
    self.preview.Overlay:SetScale(Settings:GetScale())
    if displayMode == Constants.DisplayMode.Bar then
        self.preview.Overlay:SetPoint(
            "TOP",
            self.preview.Host,
            hideWidget and "CENTER" or "BOTTOM",
            Constants.Anchor.OffsetX + Settings:GetOffsetX(),
            Constants.Anchor.OffsetY
                + (hideWidget and math.floor(Constants.Layout.BarHeight * 0.5) or Constants.Layout.BarVisibleOffsetY)
                + Settings:GetOffsetY()
        )
    else
        self.preview.Overlay:SetPoint(
            Constants.Anchor.Point,
            self.preview.Host,
            Constants.Anchor.RelativePoint,
            Constants.Anchor.OffsetX + Settings:GetOffsetX(),
            Constants.Anchor.OffsetY + Settings:GetOffsetY()
        )
    end

    self.preview.Note:SetText(GetPreviewNote(live))
    UpdatePreviewStageChips(self.preview, previewSnapshot.progressState)

    if displayMode == Constants.DisplayMode.Text then
        self.preview.Progress:Hide()
        self.preview.OrbProgress:Hide()
        self.preview.BarProgress:Hide()
        self.preview.Badge:Hide()
        self.preview.BadgeText:Hide()

        local displayParts = {}
        if showStageBadge and stageLabel then
            displayParts[#displayParts + 1] = stageLabel
        end
        if showValueText then
            displayParts[#displayParts + 1] = string.format("%d%%", previewSnapshot.percent or 0)
        end
        local displayText = table.concat(displayParts, " ")
        if displayText == "" then
            displayText = string.format("%d%%", previewSnapshot.percent or 0)
        end

        self.preview.TextDisplay:SetText(displayText)
        self.preview.TextDisplay:SetTextColor(color[1], color[2], color[3], 1)
        self.preview.TextDisplay:Show()
        return
    end

    if self.preview.TextDisplay then
        self.preview.TextDisplay:Hide()
    end

    local canShowStageBadge = showStageBadge and displayMode ~= Constants.DisplayMode.Bar
    local valueText = displayMode == Constants.DisplayMode.Bar
        and string.format("%d%%", previewSnapshot.percent or 0)
        or string.format("%d", previewSnapshot.percent or 0)

    self.preview.Progress:SetShown(displayMode == Constants.DisplayMode.Radial)
    self.preview.OrbProgress:SetShown(displayMode == Constants.DisplayMode.Orbs)
    self.preview.BarProgress:SetShown(displayMode == Constants.DisplayMode.Bar)

    activeProgress:ShowNumber(showValueText)
    UpdateBadgeAnchor(self.preview.Badge, activeProgress, activeProgress.ValueText, showValueText)

    activeProgress.ValueText:SetText(valueText)
    UpdatePreviewProgress(activeProgress, displayMode, previewSnapshot, color)

    if canShowStageBadge and stageLabel then
        self.preview.Badge:Show()
        self.preview.BadgeText:Show()
        self.preview.BadgeText:SetText(stageLabel)
        self.preview.BadgeText:SetTextColor(color[1], color[2], color[3], 1)
        return
    end

    self.preview.Badge:Hide()
    self.preview.BadgeText:Hide()
    self.preview.BadgeText:SetText("")
end

function ns.SettingsPanel:GetSelectedTab()
    if self.selectedTab then
        return self.selectedTab
    end

    self.selectedTab = NormalizeTab(GetStoredTab())
    return self.selectedTab
end

function ns.SettingsPanel:UpdateTabButtons()
    if not self.tabButtons then
        return
    end

    local selectedTab = self:GetSelectedTab()
    for tabKey, button in pairs(self.tabButtons) do
        SP.UpdateTabButton(button, tabKey == selectedTab)
    end
end

function ns.SettingsPanel:RefreshVisibleTab()
    local selectedTab = self:GetSelectedTab()

    if selectedTab == TAB_SETTINGS then
        self:RefreshControls()
        return
    end

    if selectedTab == TAB_CHANGELOG and self.changelogContent and type(self.changelogContent.Refresh) == "function" then
        self.changelogContent:Refresh()
        return
    end

    if selectedTab == TAB_SOCIAL and self.socialContent and type(self.socialContent.Refresh) == "function" then
        self.socialContent:Refresh()
        return
    end

    if selectedTab == TAB_ROADMAP and self.roadmapContent and type(self.roadmapContent.Refresh) == "function" then
        self.roadmapContent:Refresh()
    end
end

function ns.SettingsPanel:SelectTab(tabKey, persist)
    tabKey = NormalizeTab(tabKey)
    self.selectedTab = tabKey

    if persist ~= false then
        SetStoredTab(tabKey)
    end

    if self.settingsPage then
        self.settingsPage:SetShown(tabKey == TAB_SETTINGS)
    end
    if self.changelogPage then
        self.changelogPage:SetShown(tabKey == TAB_CHANGELOG)
    end
    if self.socialPage then
        self.socialPage:SetShown(tabKey == TAB_SOCIAL)
    end
    if self.roadmapPage then
        self.roadmapPage:SetShown(tabKey == TAB_ROADMAP)
    end

    self:UpdateTabButtons()
    self:RefreshVisibleTab()
end

function ns.SettingsPanel:CommitChange(reason)
    self:RefreshControls()

    if ns.Controller then
        ns.Controller:Refresh(reason or "settings")
        return
    end

    self:RefreshPreview()
end

function ns.SettingsPanel:Create()
    if self.frame then
        return self.frame
    end

    local panel = Constants.SettingsPanel
    local frame = CreateFrame("Frame", PANEL_NAME, UIParent, BACKDROP_TEMPLATE)
    frame:SetSize(panel.Width, panel.Height)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    SP.ApplyDialogBackdrop(frame)
    SP.AddSpecialFrame(PANEL_NAME)

    SP.CreateHeader(frame)

    local sidebar = SP.CreateSidebar(frame)
    frame.sidebar = sidebar

    local contentRoot = CreateFrame("Frame", nil, frame)
    contentRoot:SetPoint("TOPLEFT", sidebar.Frame, "TOPRIGHT", 18, 0)
    contentRoot:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -panel.Padding, panel.Padding)

    local contentHost = CreateFrame("Frame", nil, contentRoot, BACKDROP_TEMPLATE)
    contentHost:SetAllPoints(contentRoot)
    SP.ApplyBackdrop(contentHost, { 0.05, 0.04, 0.03, 0.58 }, panel.BorderSoftColor)

    local tabBar = CreateFrame("Frame", nil, contentRoot)
    tabBar:SetPoint("TOPLEFT", contentRoot, "TOPLEFT", 12, -10)
    tabBar:SetPoint("TOPRIGHT", contentRoot, "TOPRIGHT", -12, -10)
    tabBar:SetHeight(24)

    local tabBarLine = tabBar:CreateTexture(nil, "ARTWORK")
    tabBarLine:SetHeight(1)
    tabBarLine:SetPoint("BOTTOMLEFT", tabBar, "BOTTOMLEFT", 0, -1)
    tabBarLine:SetPoint("BOTTOMRIGHT", tabBar, "BOTTOMRIGHT", 0, -1)
    tabBarLine:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.18)

    local settingsTab = SP.CreateTabButton(tabBar, L["Settings"])
    settingsTab:SetPoint("LEFT", tabBar, "LEFT", 0, 0)
    local changelogTab = SP.CreateTabButton(tabBar, L["Changelog"])
    changelogTab:SetPoint("LEFT", settingsTab, "RIGHT", 8, 0)
    local socialTab = SP.CreateTabButton(tabBar, L["Social"])
    socialTab:SetPoint("LEFT", changelogTab, "RIGHT", 8, 0)
    local roadmapTab = SP.CreateTabButton(tabBar, L["Roadmap"])
    roadmapTab:SetPoint("LEFT", socialTab, "RIGHT", 8, 0)

    local pageHost = CreateFrame("Frame", nil, contentRoot)
    pageHost:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -10)
    pageHost:SetPoint("BOTTOMRIGHT", contentRoot, "BOTTOMRIGHT", -4, 4)

    local settingsPage = CreateFrame("Frame", nil, pageHost)
    settingsPage:SetAllPoints(pageHost)
    local changelogPage = CreateFrame("Frame", nil, pageHost)
    changelogPage:SetAllPoints(pageHost)
    local socialPage = CreateFrame("Frame", nil, pageHost)
    socialPage:SetAllPoints(pageHost)
    local roadmapPage = CreateFrame("Frame", nil, pageHost)
    roadmapPage:SetAllPoints(pageHost)

    self.settingsPage = settingsPage
    self.changelogPage = changelogPage
    self.socialPage = socialPage
    self.roadmapPage = roadmapPage

    local settingsContent = SP.CreateSections(settingsPage)
    local changelogContent = SP.CreateChangelogPage(changelogPage)
    local socialContent = SP.CreateSocialPage(socialPage)
    local roadmapContent = SP.CreateRoadmapPage(roadmapPage)
    self.settingsContent = settingsContent
    self.changelogContent = changelogContent
    self.socialContent = socialContent
    self.roadmapContent = roadmapContent

    self.tabButtons = {
        [TAB_SETTINGS] = settingsTab,
        [TAB_CHANGELOG] = changelogTab,
        [TAB_SOCIAL] = socialTab,
        [TAB_ROADMAP] = roadmapTab,
    }

    settingsTab:SetScript("OnClick", function()
        ns.SettingsPanel:SelectTab(TAB_SETTINGS)
    end)
    changelogTab:SetScript("OnClick", function()
        ns.SettingsPanel:SelectTab(TAB_CHANGELOG)
    end)
    socialTab:SetScript("OnClick", function()
        ns.SettingsPanel:SelectTab(TAB_SOCIAL)
    end)
    roadmapTab:SetScript("OnClick", function()
        ns.SettingsPanel:SelectTab(TAB_ROADMAP)
    end)

    frame:SetScript("OnShow", function()
        ns.SettingsPanel:RefreshPreview()
        ns.SettingsPanel:RefreshVisibleTab()
    end)

    self.frame = frame
    self.summary = sidebar.Summary
    self.preview = sidebar.Preview
    self.actions = sidebar.Actions
    self.controls = settingsContent.Controls
    self.content = settingsContent
    self.contentRoot = contentRoot
    self.contentHost = contentHost
    self:SelectTab(GetStoredTab(), false)

    return frame
end

function ns.SettingsPanel:Open()
    local frame = self:Create()
    frame:Show()
    frame:Raise()
end

function ns.SettingsPanel:Close()
    if self.frame then
        self.frame:Hide()
    end
end
