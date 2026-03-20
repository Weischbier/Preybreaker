-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...
local Preybreaker = ns.Controller

local function HookPreyHuntIconFrame()
    local mixin = _G.UIWidgetTemplatePreyHuntProgressMixin
    if not mixin or ns.OverlayView.preyHuntIconHooked then
        return
    end

    hooksecurefunc(mixin, "Setup", function(self)
        ns.OverlayView.preyHuntIconFrame = self
        -- Blizzard's Setup calls AnimIn -> ResetAnimState -> SetAlpha(1) + Show().
        -- We must re-hide AFTER that sequence completes, which is here in the post-hook.
        if ns.Settings and ns.Settings:ShouldHideBlizzardWidget() and ns.Settings:IsEnabled() then
            if ns.OverlayView and type(ns.OverlayView.HideStandaloneWidgetFrame) == "function" then
                ns.OverlayView:HideStandaloneWidgetFrame(self)
            elseif type(self.Hide) == "function" then
                self:Hide()
            elseif type(self.SetAlpha) == "function" then
                self:SetAlpha(0)
            end
        end
    end)
    ns.OverlayView.preyHuntIconHooked = true
end

function Preybreaker:Bootstrap(event, detail)
    self:UpdateBootstrapState(event, detail)

    if event == "ADDON_LOADED" and detail == ADDON_NAME then
        if ns.Settings then
            ns.Settings:Initialize()
        end
        if ns.HuntPanel and type(ns.HuntPanel.Ensure) == "function" then
            ns.HuntPanel:Ensure()
        end
    end

    if event == "ADDON_LOADED" and (detail == "Blizzard_UIWidgets" or detail == ADDON_NAME) then
        HookPreyHuntIconFrame()
    end

    ns.Debug:Log(
        "bootstrap",
        ns.Debug:KV("event", event),
        ns.Debug:KV("detail", detail),
        ns.Debug:KV("state", self:GetBootstrapSummary())
    )

    if event == "ADDON_LOADED" and detail == ADDON_NAME and not self:GetBootstrapState().widgetsReady then
        ns.Debug:Log("bootstrap", ns.Debug:KV("waitingFor", "Blizzard_UIWidgets"))
    end

    local state = self:GetBootstrapState()
    if state.addonLoaded and state.widgetsReady then
        self:UnregisterEvent("ADDON_LOADED")
    end

    local reason = event
    if detail ~= nil then
        reason = string.format("%s:%s", event, tostring(detail))
    end

    self:Refresh(reason)
end

