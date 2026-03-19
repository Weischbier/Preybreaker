-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Constants = ns.Constants
local L = ns.L
local SP = ns._SP

local SetTextColor = SP.SetTextColor
local ApplyBackdrop = SP.ApplyBackdrop
local ApplyCardBackdrop = SP.ApplyCardBackdrop
local ApplyInsetBackdrop = SP.ApplyInsetBackdrop
local AddFieldHighlight = SP.AddFieldHighlight
local CreateAccentLine = SP.CreateAccentLine
local CreateActionButton = SP.CreateActionButton
local ResolveValue = SP.ResolveValue
local BACKDROP_TEMPLATE = SP.BACKDROP_TEMPLATE
local PANEL_NAME = SP.PANEL_NAME

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

function SP.CreateSectionCard(parent, titleText, descriptionText)
    local panel = Constants.SettingsPanel
    local card = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    ApplyCardBackdrop(card)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", panel.ContentInset, -14)
    title:SetText(titleText)
    SetTextColor(title, panel.TitleColor)

    local description = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    description:SetPoint("RIGHT", card, "RIGHT", -panel.ContentInset, 0)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)
    description:SetText(descriptionText)
    SetTextColor(description, panel.BodyColor)

    CreateAccentLine(card, description, 0.22)

    card.Title = title
    card.Description = description
    return card
end

local function SetFieldAvailability(row, enabled, descriptionText, disabledDescription, stateText)
    local panel = Constants.SettingsPanel

    if row.Title then
        SetTextColor(row.Title, enabled and panel.TitleColor or panel.MutedColor)
    end
    if row.Description then
        row.Description:SetText(enabled and descriptionText or (disabledDescription or descriptionText))
        SetTextColor(row.Description, enabled and panel.BodyColor or panel.MutedColor)
    end
    if row.StateText then
        row.StateText:SetText(stateText or "")
    end
end

local function CreateToggleRow(parent, spec)
    local panel = Constants.SettingsPanel
    local row = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    row:SetHeight(panel.RowHeight)
    row:RegisterForClicks("LeftButtonUp")
    ApplyInsetBackdrop(row)
    AddFieldHighlight(row)

    local accent = row:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", row, "TOPLEFT", 3, -3)
    accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 3, 3)
    accent:SetWidth(2)
    accent:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.40)

    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    checkbox:SetPoint("LEFT", row, "LEFT", 8, 0)

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", row, "TOPLEFT", 40, -9)
    title:SetPoint("RIGHT", row, "RIGHT", -62, 0)
    title:SetJustifyH("LEFT")
    title:SetText(spec.title)

    local description = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    description:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -62, 10)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)

    local stateText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    stateText:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    stateText:SetJustifyH("RIGHT")

    checkbox:SetScript("OnClick", function(self)
        if not self:IsEnabled() then
            return
        end

        spec.set(self:GetChecked())
        ns.SettingsPanel:CommitChange(spec.reason or ("settings:" .. spec.key))
    end)

    row:SetScript("OnClick", function()
        if checkbox:IsEnabled() then
            checkbox:Click()
        end
    end)

    row.Checkbox = checkbox
    row.Title = title
    row.Description = description
    row.StateText = stateText

    function row:Refresh()
        local enabled = not spec.isAvailable or spec.isAvailable()
        local checked = spec.get() == true

        if enabled then
            checkbox:Enable()
            row:Enable()
        else
            checkbox:Disable()
            row:Disable()
        end

        checkbox:SetChecked(enabled and checked or false)
        stateText:SetText(enabled and (checked and L["On"] or L["Off"]) or L["Unavailable"])
        SetTextColor(stateText, enabled and (checked and panel.PositiveColor or panel.MutedColor) or panel.MutedColor)
        SetFieldAvailability(
            row,
            enabled,
            ResolveValue(spec.description),
            ResolveValue(spec.disabledDescription),
            stateText:GetText()
        )
    end

    return row
end

local function CreateModeButton(parent, option, onClick)
    local panel = Constants.SettingsPanel
    local button = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    button:SetSize(panel.ChoiceButtonWidth, panel.ChoiceButtonHeight)
    ApplyInsetBackdrop(button)
    AddFieldHighlight(button, 0.08)

    button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.Text:SetPoint("CENTER")
    button.Text:SetText(option.label)
    button.value = option.value
    button:SetScript("OnClick", function()
        onClick(option.value)
    end)

    return button
end

local function UpdateModeButton(button, isSelected)
    local panel = Constants.SettingsPanel
    if isSelected then
        ApplyBackdrop(
            button,
            { panel.AccentSoftColor[1], panel.AccentSoftColor[2], panel.AccentSoftColor[3], 0.78 },
            panel.BorderColor
        )
        SetTextColor(button.Text, panel.TitleColor)
        return
    end

    ApplyInsetBackdrop(button)
    SetTextColor(button.Text, panel.BodyColor)
end

local function CreateChoiceRow(parent, spec)
    local panel = Constants.SettingsPanel
    local row = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    row:SetHeight(panel.ChoiceRowHeight)
    ApplyInsetBackdrop(row)
    local options = ResolveValue(spec.options) or {}

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -10)
    title:SetText(spec.title)

    local description = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    description:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)

    local buttons = {}
    local previousButton = nil
    for _, option in ipairs(options) do
        local button = CreateModeButton(row, option, function(value)
            spec.set(value)
            ns.SettingsPanel:CommitChange(spec.reason or ("settings:" .. spec.key))
        end)
        if previousButton then
            button:SetPoint("BOTTOMLEFT", previousButton, "BOTTOMRIGHT", 8, 0)
        else
            button:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 12, 12)
        end
        buttons[#buttons + 1] = button
        previousButton = button
    end

    row.Title = title
    row.Description = description
    row.Buttons = buttons

    function row:Refresh()
        local selectedValue = spec.get()
        for _, button in ipairs(buttons) do
            if button.SetEnabled then
                button:SetEnabled(true)
            elseif button.Enable then
                button:Enable()
            end
            UpdateModeButton(button, button.value == selectedValue)
        end

        SetFieldAvailability(row, true, ResolveValue(spec.description), nil)
    end

    return row
end

local function CreateSliderRow(parent, spec)
    local panel = Constants.SettingsPanel
    local sliderName = PANEL_NAME .. spec.key .. "Slider"
    local row = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    row:SetHeight(panel.SliderRowHeight)
    ApplyInsetBackdrop(row)

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -10)
    title:SetText(spec.title)

    local valueText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -10)
    valueText:SetJustifyH("RIGHT")
    SetTextColor(valueText, panel.AccentColor)

    local description = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    description:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)

    local slider = CreateFrame("Slider", sliderName, row, "OptionsSliderTemplate")
    slider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 4)
    slider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -14, 4)

    local sliderText = _G[sliderName .. "Text"]
    local sliderLow = _G[sliderName .. "Low"]
    local sliderHigh = _G[sliderName .. "High"]
    if sliderText then
        sliderText:SetText("")
    end
    if sliderLow then
        sliderLow:SetText("")
    end
    if sliderHigh then
        sliderHigh:SetText("")
    end

    slider:SetScript("OnValueChanged", function(self, currentValue)
        if self.suspendUpdates then
            return
        end

        spec.set(currentValue)
        ns.SettingsPanel:CommitChange(spec.reason or ("settings:" .. spec.key))
    end)

    row.Title = title
    row.Description = description
    row.Slider = slider
    row.ValueText = valueText

    function row:Refresh()
        local enabled = not spec.isAvailable or spec.isAvailable()
        local bounds = spec.getBounds and spec.getBounds() or nil
        local minValue = bounds and bounds.min or spec.minValue
        local maxValue = bounds and bounds.max or spec.maxValue
        local stepValue = bounds and bounds.step or spec.step
        local currentValue = spec.get()

        slider.suspendUpdates = true
        slider:SetMinMaxValues(minValue, maxValue)
        slider:SetValueStep(stepValue)
        if type(slider.SetObeyStepOnDrag) == "function" then
            slider:SetObeyStepOnDrag(true)
        end
        slider:SetValue(currentValue)
        slider.suspendUpdates = nil

        SetEnabledState(slider, enabled)

        valueText:SetText(spec.formatter(currentValue))
        SetTextColor(valueText, enabled and panel.AccentColor or panel.MutedColor)
        SetFieldAvailability(row, enabled, ResolveValue(spec.description), ResolveValue(spec.disabledDescription))
    end

    return row
end

local function CreateDropdownRow(parent, spec)
    local panel = Constants.SettingsPanel
    local row = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    row:SetHeight(panel.DropdownRowHeight)
    ApplyInsetBackdrop(row)

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -10)
    title:SetText(spec.title)

    local description = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    description:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)

    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown.menuPoint = "BOTTOMLEFT"
    dropdown.menuRelativePoint = "TOPLEFT"
    dropdown:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 12, 10)
    dropdown:SetWidth(280)

    row:SetScript("OnSizeChanged", function(self, width)
        dropdown:SetWidth(math.max(140, width - 24))
    end)

    row.Title = title
    row.Description = description
    row.Dropdown = dropdown

    function row:Refresh()
        local enabled = not spec.isAvailable or spec.isAvailable()
        local options = ResolveValue(spec.options) or {}
        local currentValue = spec.get()
        local selectedLabel = GetChoiceLabel(options, currentValue) or ResolveValue(spec.placeholder) or spec.title

        dropdown:SetDefaultText(selectedLabel)
        dropdown:SetupMenu(function(_, rootDescription)
            local function IsSelected(value)
                return spec.get() == value
            end

            local function SetSelected(value)
                spec.set(value)
                ns.SettingsPanel:CommitChange(spec.reason or ("settings:" .. spec.key))
            end

            for _, option in ipairs(options) do
                rootDescription:CreateRadio(option.label, IsSelected, SetSelected, option.value)
            end
        end)

        SetEnabledState(dropdown, enabled)
        SetFieldAvailability(row, enabled, ResolveValue(spec.description), ResolveValue(spec.disabledDescription))
    end

    return row
end

local function CreateActionRow(parent, spec)
    local panel = Constants.SettingsPanel
    local row = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    row:SetHeight(panel.ActionRowHeight)
    ApplyInsetBackdrop(row)

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -10)
    title:SetText(spec.title)

    local description = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    description:SetPoint("LEFT", row, "LEFT", 12, 0)
    description:SetPoint("RIGHT", row, "RIGHT", -124, 0)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)

    local button = CreateActionButton(row, spec.buttonText, spec.buttonWidth or 108, function()
        spec.onClick()
    end)
    button:SetPoint("RIGHT", row, "RIGHT", -12, 0)

    row.Title = title
    row.Description = description
    row.Button = button

    function row:Refresh()
        local enabled = not spec.isAvailable or spec.isAvailable()

        SetEnabledState(button, enabled)

        SetFieldAvailability(row, enabled, ResolveValue(spec.description), ResolveValue(spec.disabledDescription))
    end

    return row
end

SP.FIELD_BUILDERS = {
    toggle = CreateToggleRow,
    choice = CreateChoiceRow,
    slider = CreateSliderRow,
    dropdown = CreateDropdownRow,
    action = CreateActionRow,
}

function SP.CreateSection(parent, sectionSpec, controls)
    local panel = Constants.SettingsPanel
    local card = SP.CreateSectionCard(parent, sectionSpec.title, sectionSpec.description)
    local currentY = -(panel.SectionHeaderHeight + 14)

    for _, fieldSpec in ipairs(sectionSpec.fields) do
        local builder = SP.FIELD_BUILDERS[fieldSpec.type]
        if builder then
            local row = builder(card, fieldSpec)
            row:SetPoint("TOPLEFT", card, "TOPLEFT", panel.ContentInset, currentY)
            row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -panel.ContentInset, currentY)
            currentY = currentY - row:GetHeight() - 8
            controls[#controls + 1] = row
        end
    end

    card:SetHeight(math.abs(currentY) + panel.ContentInset - 8)
    return card
end
