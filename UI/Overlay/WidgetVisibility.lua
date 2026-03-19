-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local Util = ns.Util

ns.WidgetVisibility = {}

function ns.WidgetVisibility.CreateWeakStore()
    return setmetatable({}, { __mode = "k" })
end

function ns.WidgetVisibility.BuildFrameEffectInfo(frame)
    local effectID = frame and frame.scriptedAnimationEffectID or nil
    local modelSceneLayer = frame and frame.modelSceneLayer or nil
    if not effectID or effectID == 0 or modelSceneLayer == nil then
        return nil
    end

    if Enum and Enum.UIWidgetModelSceneLayer and modelSceneLayer == Enum.UIWidgetModelSceneLayer.None then
        return nil
    end

    return {
        scriptedAnimationEffectID = effectID,
        modelSceneLayer = modelSceneLayer,
    }
end

function ns.WidgetVisibility.CancelFrameEffect(frame)
    local effectController = frame and frame.effectController or nil
    if not effectController or type(effectController.CancelEffect) ~= "function" then
        return false
    end

    Util.SafeCall(effectController.CancelEffect, effectController)
    frame.effectController = nil
    return true
end

function ns.WidgetVisibility.RestoreFrameEffect(frame)
    if not frame or frame.effectController or not frame.widgetContainer then
        return false
    end

    local effectInfo = ns.WidgetVisibility.BuildFrameEffectInfo(frame)
    if not effectInfo then
        return false
    end

    if type(frame.ApplyEffects) == "function" then
        Util.SafeCall(frame.ApplyEffects, frame, effectInfo)
        return frame.effectController ~= nil
    end

    if type(frame.ApplyEffectToFrame) == "function" then
        Util.SafeCall(frame.ApplyEffectToFrame, frame, effectInfo, frame.widgetContainer, frame)
        return frame.effectController ~= nil
    end

    return false
end
