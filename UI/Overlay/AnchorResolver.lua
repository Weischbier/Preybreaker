-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Util = ns.Util
local OverlayResolver = ns.OverlayResolver

local IsSquareishObject = OverlayResolver.IsSquareishObject

ns.AnchorResolver = {}

local OVERLAY_NAME = "PreybreakerOverlayFrame"

local COMMON_ICON_KEYS = {
    "Icon",
    "icon",
    "IconFrame",
    "iconFrame",
    "Texture",
    "texture",
    "SpellIcon",
    "spellIcon",
    "Portrait",
    "portrait",
}

local function IsRegionUsable(region)
    return region and type(region.GetObjectType) == "function" and type(region.GetCenter) == "function"
end

local function IsOverlayFrame(frame)
    local overlay = ns.OverlayView and ns.OverlayView.frame
    if frame and overlay and OverlayResolver.IsSameOrDescendant(frame, overlay) then
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

local function SafeCollectObjects(object, methodName)
    local method = object and object[methodName]
    if type(method) ~= "function" then
        return nil
    end

    local ok, values = pcall(function()
        return { method(object) }
    end)
    if not ok then
        return nil
    end

    return values
end

local function IsLikelyAttachedWidgetVisual(frame, widgetFrame)
    if not IsFrameObject(frame) or not IsFrameObject(widgetFrame) then
        return false
    end

    local frameX, frameY = frame:GetCenter()
    local widgetX, widgetY = widgetFrame:GetCenter()
    if not frameX or not frameY or not widgetX or not widgetY then
        return false
    end

    local frameWidth, frameHeight = frame:GetSize()
    local widgetWidth, widgetHeight = widgetFrame:GetSize()
    if not frameWidth or not frameHeight or not widgetWidth or not widgetHeight then
        return false
    end

    if frameWidth > math.max(256, widgetWidth * 2.5) or frameHeight > math.max(256, widgetHeight * 2.5) then
        return false
    end

    local maxDistanceX = math.max(24, (widgetWidth + frameWidth) * 0.65)
    local maxDistanceY = math.max(24, (widgetHeight + frameHeight) * 0.65)

    return math.abs(frameX - widgetX) <= maxDistanceX and math.abs(frameY - widgetY) <= maxDistanceY
end

local function AddUniqueHost(hosts, frame, source)
    if not IsFrameObject(frame) or type(frame.GetChildren) ~= "function" then
        return
    end

    for _, host in ipairs(hosts) do
        if host.frame == frame then
            return
        end
    end

    hosts[#hosts + 1] = {
        frame = frame,
        source = source,
    }
end

local function GetWidgetHosts(container)
    local hosts = {}
    if not container then
        return hosts
    end

    AddUniqueHost(hosts, container.widgetFrameContainer, "container.widgetFrameContainer")
    AddUniqueHost(hosts, container.WidgetFrameContainer, "container.WidgetFrameContainer")
    AddUniqueHost(hosts, container, "container")

    return hosts
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
    local store = overlay and overlay.hiddenWidgetShownStateByFrame or nil
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

    local widgetCollections = {
        { value = container.widgetFrames, source = "container.widgetFrames" },
        { value = container.widgetIdToWidgetFrameMap, source = "container.widgetIdToWidgetFrameMap" },
        { value = container.widgetIDToWidgetFrameMap, source = "container.widgetIDToWidgetFrameMap" },
    }

    for _, collection in ipairs(widgetCollections) do
        if type(collection.value) == "table" then
            local candidate = collection.value[activeWidgetID]
            if IsFrameObject(candidate) then
                return candidate, collection.source
            end
        end
    end

    local hosts = GetWidgetHosts(container)
    for _, host in ipairs(hosts) do
        local child = FindChildByWidgetID(host.frame, activeWidgetID)
        if child then
            return child, host.source .. ".children.widgetID"
        end
    end

    return nil, nil
end

local function ResolveExplicitIconTarget(widgetFrame)
    if not widgetFrame then
        return nil, nil
    end

    for _, key in ipairs(COMMON_ICON_KEYS) do
        local candidate = widgetFrame[key]
        if IsRegionUsable(candidate) and not IsOverlayFrame(candidate) then
            return candidate, "widget." .. key
        end
    end

    return nil, nil
end

local function ResolveRegionIconTarget(widgetFrame)
    if not widgetFrame or type(widgetFrame.GetRegions) ~= "function" then
        return nil, nil
    end

    local bestRegion
    local bestIndex
    local bestArea

    local regions = { widgetFrame:GetRegions() }
    for i, region in ipairs(regions) do
        if region
            and not IsOverlayFrame(region)
            and region:GetObjectType() == "Texture"
            and type(region.IsShown) == "function"
            and region:IsShown()
            and IsSquareishObject(region)
        then
            local width, height = region:GetSize()
            local area = width * height
            if not bestArea or area > bestArea then
                bestRegion = region
                bestIndex = i
                bestArea = area
            end
        end
    end

    if bestRegion then
        return bestRegion, string.format("widget.regions[%d]", bestIndex)
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

local function DescribeDrawLayer(region)
    if not region or type(region.GetDrawLayer) ~= "function" then
        return nil
    end

    local layer, subLevel = region:GetDrawLayer()
    if not layer then
        return nil
    end

    return string.format("%s:%s", tostring(layer), tostring(subLevel or 0))
end

function ns.AnchorResolver.ResolveBestAnchorTarget()
    local resolution = {
        activeWidgetID = ns.Controller and ns.Controller.activeWidgetID or nil,
        container = _G.UIWidgetPowerBarContainerFrame,
        containerSource = "global.UIWidgetPowerBarContainerFrame",
        widgetFrame = nil,
        widgetFrameSource = nil,
        target = UIParent,
        targetSource = "fallback:missingContainer",
        kind = "fallback",
        fallbackPath = "containerMissing->UIParent",
    }

    if not resolution.container then
        resolution.containerSource = "missing"
        return resolution
    end

    if not IsFrameObject(resolution.container) then
        resolution.targetSource = "fallback:invalidContainer"
        resolution.fallbackPath = "invalidContainer->UIParent"
        return resolution
    end

    local widgetFrame, widgetFrameSource = ResolveWidgetFrame(resolution.container)
    resolution.widgetFrame = widgetFrame
    resolution.widgetFrameSource = widgetFrameSource

    if widgetFrame then
        local iconTarget, iconSource = ResolveExplicitIconTarget(widgetFrame)
        if iconTarget then
            resolution.target = iconTarget
            resolution.targetSource = iconSource
            resolution.kind = "icon"
            resolution.fallbackPath = "none"
            return resolution
        end

        local regionTarget, regionSource = ResolveRegionIconTarget(widgetFrame)
        if regionTarget then
            resolution.target = regionTarget
            resolution.targetSource = regionSource
            resolution.kind = "icon"
            resolution.fallbackPath = "none"
            return resolution
        end

        resolution.target = widgetFrame
        resolution.targetSource = widgetFrameSource or "widget"
        resolution.kind = "widget"
        resolution.fallbackPath = "iconMissing->widgetFrame"
        return resolution
    end

    resolution.target = resolution.container
    resolution.targetSource = resolution.containerSource
    resolution.kind = "container"
    resolution.fallbackPath = "widgetFrameMissing->container"
    return resolution
end

ns.AnchorResolver.ResolveHostFrame = ResolveHostFrame
ns.AnchorResolver.DescribeDrawLayer = DescribeDrawLayer
ns.AnchorResolver.IsOverlayFrame = IsOverlayFrame
ns.AnchorResolver.IsAnchorTargetUsable = IsAnchorTargetUsable
ns.AnchorResolver.IsFrameObject = IsFrameObject
ns.AnchorResolver.SafeCollectObjects = SafeCollectObjects
ns.AnchorResolver.IsLikelyAttachedWidgetVisual = IsLikelyAttachedWidgetVisual
ns.AnchorResolver.GetFrameWidgetID = GetFrameWidgetID
