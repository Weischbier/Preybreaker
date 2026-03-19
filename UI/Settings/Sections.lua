-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Constants = ns.Constants
local Settings = ns.Settings
local L = ns.L
local SP = ns._SP

local ApplyBackdrop = SP.ApplyBackdrop
local BACKDROP_TEMPLATE = SP.BACKDROP_TEMPLATE
local PANEL_NAME = SP.PANEL_NAME
local MODE_OPTIONS = SP.MODE_OPTIONS

function SP.CreateSections(frame)
    local panel = Constants.SettingsPanel
    local contentWidth = panel.Width - (panel.Padding * 2) - panel.SidebarWidth - 18

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.18)
    divider:SetPoint("TOPLEFT", frame.sidebar.Frame, "TOPRIGHT", 9, 0)
    divider:SetPoint("BOTTOMLEFT", frame.sidebar.Frame, "BOTTOMRIGHT", 9, 0)

    local contentHost = CreateFrame("Frame", nil, frame, BACKDROP_TEMPLATE)
    contentHost:SetPoint("TOPLEFT", frame.sidebar.Frame, "TOPRIGHT", 18, 0)
    contentHost:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -panel.Padding, panel.Padding)
    ApplyBackdrop(contentHost, { 0.05, 0.04, 0.03, 0.58 }, panel.BorderSoftColor)

    local scrollFrame = CreateFrame("ScrollFrame", PANEL_NAME .. "ScrollFrame", contentHost, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 4, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -28, 6)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(contentWidth - 32)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

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
                    options = MODE_OPTIONS,
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
                    minValue = -80,
                    maxValue = 80,
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
                    minValue = -80,
                    maxValue = 80,
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
    }
end

function SP.UpdatePreviewStageChips(preview, progressState)
    for _, chip in ipairs(preview.StageChips) do
        SP.UpdateStageChip(chip, chip.state == progressState)
    end
end
