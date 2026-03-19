-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

local atlasCache = {}

local function GetAtlasInfo(atlasName)
    if atlasName == nil then
        return nil
    end

    local cached = atlasCache[atlasName]
    if cached ~= nil then
        return cached or nil
    end

    local atlasInfo
    if type(C_Texture) == "table" and type(C_Texture.GetAtlasInfo) == "function" then
        atlasInfo = C_Texture.GetAtlasInfo(atlasName)
    end

    atlasCache[atlasName] = atlasInfo or false
    return atlasInfo
end

local function ApplyAtlas(texture, atlasName)
    if type(texture.SetAtlas) == "function" then
        texture:SetAtlas(atlasName, true)
        return
    end

    local atlasInfo = GetAtlasInfo(atlasName)
    if not atlasInfo then
        texture:SetColorTexture(1, 0, 1, 0.75)
        texture:SetSize(8, 8)
        return
    end

    texture:SetTexture(atlasInfo.file)
    texture:SetTexCoord(
        atlasInfo.leftTexCoord,
        atlasInfo.rightTexCoord,
        atlasInfo.topTexCoord,
        atlasInfo.bottomTexCoord
    )
    texture:SetSize(atlasInfo.width, atlasInfo.height)
end

ns.AtlasUtil = {
    GetAtlasInfo = GetAtlasInfo,
    ApplyAtlas = ApplyAtlas,
}
