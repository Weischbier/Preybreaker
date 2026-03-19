-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

ns.DetachedPosition = {}

function ns.DetachedPosition.GetFrameOffset(frame, parentFrame, roundFn)
    if not frame then
        return nil, nil
    end

    local frameX, frameY = frame:GetCenter()
    local parentX, parentY = parentFrame:GetCenter()
    local parentScale = parentFrame:GetEffectiveScale() or 1
    if not frameX or not frameY or not parentX or not parentY or parentScale == 0 then
        return nil, nil
    end

    return roundFn((frameX - parentX) / parentScale), roundFn((frameY - parentY) / parentScale)
end
