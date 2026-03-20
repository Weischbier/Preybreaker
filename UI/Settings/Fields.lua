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
local ApplyAccentLineColor = SP.ApplyAccentLineColor
local ApplyHighlightColor = SP.ApplyHighlightColor
local HideSliderTemplateLabels = SP.HideSliderTemplateLabels
local ResolveValue = SP.ResolveValue

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

    local card = CreateFrame("Frame", nil, parent, "PreybreakerSectionCardTemplate")
    ApplyCardBackdrop(card)

    card.Title:SetText(titleText)
    SetTextColor(card.Title, panel.TitleColor)

    card.Description:SetText(descriptionText)
    SetTextColor(card.Description, panel.BodyColor)

    ApplyAccentLineColor(card.AccentLine)

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

    local row = CreateFrame("Button", nil, parent, "PreybreakerToggleRowTemplate")
    row:SetHeight(panel.RowHeight)
    ApplyInsetBackdrop(row)

    row.AccentBar:SetColorTexture(panel.AccentColor[1], panel.AccentColor[2], panel.AccentColor[3], 0.40)
    ApplyHighlightColor(row.Highlight)

    row.Title:SetText(spec.title)

    local checkbox = row.Checkbox

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
        row.StateText:SetText(enabled and (checked and L["On"] or L["Off"]) or L["Unavailable"])
        SetTextColor(row.StateText, enabled and (checked and panel.PositiveColor or panel.MutedColor) or panel.MutedColor)
        SetFieldAvailability(
            row,
            enabled,
            ResolveValue(spec.description),
            ResolveValue(spec.disabledDescription),
            row.StateText:GetText()
        )
    end

    return row
end

local CHOICE_BUTTON_MIN_WIDTH = 72
local CHOICE_BUTTON_PADDING = 24

local function CreateModeButton(parent, option, onClick)
    local panel = Constants.SettingsPanel

    local button = CreateFrame("Button", nil, parent, "PreybreakerChoiceButtonTemplate")
    ApplyInsetBackdrop(button)
    ApplyHighlightColor(button.Highlight, 0.08)

    button.Text:SetText(option.label)
    local textWidth = button.Text:GetStringWidth() or 0
    button:SetWidth(math.max(CHOICE_BUTTON_MIN_WIDTH, textWidth + CHOICE_BUTTON_PADDING))

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

    local row = CreateFrame("Frame", nil, parent, "PreybreakerChoiceRowTemplate")
    row:SetHeight(panel.ChoiceRowHeight)
    ApplyInsetBackdrop(row)

    row.Title:SetText(spec.title)

    local options = ResolveValue(spec.options) or {}
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

    row.Buttons = buttons

    function row:Refresh()
        local enabled = not spec.isAvailable or spec.isAvailable()
        local selectedValue = spec.get()
        for _, button in ipairs(buttons) do
            if enabled then
                if button.SetEnabled then
                    button:SetEnabled(true)
                elseif button.Enable then
                    button:Enable()
                end
            else
                if button.SetEnabled then
                    button:SetEnabled(false)
                elseif button.Disable then
                    button:Disable()
                end
            end
            UpdateModeButton(button, enabled and button.value == selectedValue)
        end

        SetFieldAvailability(row, enabled, ResolveValue(spec.description), ResolveValue(spec.disabledDescription))
    end

    return row
end

local function CreateSliderRow(parent, spec)
    local panel = Constants.SettingsPanel

    local row = CreateFrame("Frame", nil, parent, "PreybreakerSliderRowTemplate")
    row:SetHeight(panel.SliderRowHeight)
    ApplyInsetBackdrop(row)

    row.Title:SetText(spec.title)
    SetTextColor(row.ValueText, panel.AccentColor)

    local slider = row.Slider
    HideSliderTemplateLabels(slider)

    slider:SetScript("OnValueChanged", function(self, currentValue)
        if self.suspendUpdates then
            return
        end

        spec.set(currentValue)
        ns.SettingsPanel:CommitChange(spec.reason or ("settings:" .. spec.key))
    end)

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

        row.ValueText:SetText(spec.formatter(currentValue))
        SetTextColor(row.ValueText, enabled and panel.AccentColor or panel.MutedColor)
        SetFieldAvailability(row, enabled, ResolveValue(spec.description), ResolveValue(spec.disabledDescription))
    end

    return row
end

local function CreateDropdownRow(parent, spec)
    local panel = Constants.SettingsPanel

    local row = CreateFrame("Frame", nil, parent, "PreybreakerDropdownRowTemplate")
    row:SetHeight(panel.DropdownRowHeight)
    ApplyInsetBackdrop(row)

    row.Title:SetText(spec.title)

    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown.menuPoint = "BOTTOMLEFT"
    dropdown.menuRelativePoint = "TOPLEFT"
    dropdown:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 12, 10)
    dropdown:SetWidth(280)
    row.Dropdown = dropdown

    row:SetScript("OnSizeChanged", function(self, width)
        dropdown:SetWidth(math.max(140, width - 24))
    end)

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

    local row = CreateFrame("Frame", nil, parent, "PreybreakerActionRowTemplate")
    row:SetHeight(panel.ActionRowHeight)
    ApplyInsetBackdrop(row)

    row.Title:SetText(spec.title)

    local button = row.Button
    button:SetText(spec.buttonText)
    if spec.buttonWidth then
        button:SetWidth(spec.buttonWidth)
    end
    button:SetScript("OnClick", function()
        spec.onClick()
    end)

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
