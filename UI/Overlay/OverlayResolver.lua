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

local VISUAL_HINT_TOKENS = {
    "anim",
    "glow",
    "pulse",
    "spark",
    "flare",
    "shine",
}

function ns.OverlayResolver.IsSquareishObject(object)
    if not object or type(object.GetSize) ~= "function" then
        return false
    end

    local width, height = object:GetSize()
    if not width or not height or width < 18 or height < 18 or width > 128 or height > 128 then
        return false
    end

    local ratio = math.max(width, height) / math.max(1, math.min(width, height))
    return ratio <= 1.35
end

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

function ns.OverlayResolver.NameHasVisualHint(object)
    if not object or type(object.GetName) ~= "function" then
        return false
    end

    local name = object:GetName()
    if type(name) ~= "string" or name == "" then
        return false
    end

    local lowered = string.lower(name)
    for _, token in ipairs(VISUAL_HINT_TOKENS) do
        if string.find(lowered, token, 1, true) then
            return true
        end
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
