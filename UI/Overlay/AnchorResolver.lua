-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Util = ns.Util

ns.AnchorResolver = {}

local OVERLAY_NAME = "PreybreakerOverlayFrame"

local function IsOverlayFrame(frame)
    local overlay = ns.OverlayView and ns.OverlayView.frame
    if frame and overlay and frame == overlay then
        return true
    end

    return frame and type(frame.GetName) == "function" and frame:GetName() == OVERLAY_NAME
end

local function IsAnchorTargetUsable(target)
    return target
        and not IsOverlayFrame(target)
        and type(target.GetObjectType) == "function"
        and type(target.GetCenter) == "function"
end

local function IsFrameObject(frame)
    return IsAnchorTargetUsable(frame) and frame:GetObjectType() == "Frame"
end

local function GetFrameWidgetID(frame)
    if not frame then
        return nil
    end

    if frame.widgetID ~= nil then
        return frame.widgetID
    end

    if type(frame.GetWidgetID) == "function" then
        return Util.SafeCall(frame.GetWidgetID, frame)
    end

    return nil
end

local function WasHiddenByOverlay(frame)
    local overlay = ns.OverlayView
    local store = overlay and overlay._hiddenFrames or nil
    return store and store[frame] ~= nil or false
end

local function FindChildByWidgetID(parent, widgetID)
    if not parent or not widgetID or type(parent.GetChildren) ~= "function" then
        return nil
    end

    local children = { parent:GetChildren() }
    for _, child in ipairs(children) do
        if IsFrameObject(child)
            and type(child.IsShown) == "function"
            and (child:IsShown() or WasHiddenByOverlay(child))
            and GetFrameWidgetID(child) == widgetID
        then
            return child
        end
    end

    return nil
end

local function ResolveWidgetFrame(container)
    if not IsFrameObject(container) then
        return nil, nil
    end

    local activeWidgetID = ns.Controller and ns.Controller.activeWidgetID
    if not activeWidgetID then
        return nil, nil
    end

    local maps = {
        { value = container.widgetFrames, source = "widgetFrames" },
        { value = container.widgetIdToWidgetFrameMap, source = "widgetIdToWidgetFrameMap" },
    }
    for _, entry in ipairs(maps) do
        if type(entry.value) == "table" then
            local candidate = entry.value[activeWidgetID]
            if IsFrameObject(candidate) then
                return candidate, entry.source
            end
        end
    end

    local child = FindChildByWidgetID(container, activeWidgetID)
    if child then
        return child, "children"
    end

    return nil, nil
end

local function ResolveHostFrame(target)
    if IsFrameObject(target) then
        return target
    end

    if target and type(target.GetParent) == "function" then
        local parent = target:GetParent()
        if IsFrameObject(parent) then
            return parent
        end
    end

    return UIParent
end

function ns.AnchorResolver.ResolveBestAnchorTarget()
    local resolution = {
        activeWidgetID = ns.Controller and ns.Controller.activeWidgetID or nil,
        container = _G.UIWidgetPowerBarContainerFrame,
        widgetFrame = nil,
        widgetFrameSource = nil,
        target = UIParent,
        kind = "fallback",
    }

    if not IsFrameObject(resolution.container) then
        return resolution
    end

    local widgetFrame, widgetFrameSource = ResolveWidgetFrame(resolution.container)
    resolution.widgetFrame = widgetFrame
    resolution.widgetFrameSource = widgetFrameSource

    if widgetFrame then
        resolution.target = widgetFrame
        resolution.kind = "widget"
        return resolution
    end

    resolution.target = resolution.container
    resolution.kind = "container"
    return resolution
end

ns.AnchorResolver.ResolveHostFrame = ResolveHostFrame
ns.AnchorResolver.IsOverlayFrame = IsOverlayFrame
ns.AnchorResolver.IsAnchorTargetUsable = IsAnchorTargetUsable
ns.AnchorResolver.IsFrameObject = IsFrameObject
ns.AnchorResolver.GetFrameWidgetID = GetFrameWidgetID
