-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

ns.OverlayResolver = {}

local FRAME_STRATA_PRIORITY = {
    BACKGROUND = 1,
    LOW = 2,
    MEDIUM = 3,
    HIGH = 4,
    DIALOG = 5,
    FULLSCREEN = 6,
    FULLSCREEN_DIALOG = 7,
    TOOLTIP = 8,
}

function ns.OverlayResolver.IsSameOrDescendant(frame, ancestor)
    if not frame or not ancestor or frame == ancestor then
        return frame == ancestor
    end

    local current = frame
    local guard = 0
    while current and guard < 32 do
        if current == ancestor then
            return true
        end
        if type(current.GetParent) ~= "function" then
            break
        end
        current = current:GetParent()
        guard = guard + 1
    end

    return false
end

function ns.OverlayResolver.ResolveOverlayStrata(host, defaultStrata)
    local hostStrata = host and type(host.GetFrameStrata) == "function" and host:GetFrameStrata() or nil

    if FRAME_STRATA_PRIORITY[hostStrata] ~= nil then
        return hostStrata
    end

    return defaultStrata
end
