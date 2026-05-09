-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...

ns.RoadmapData = ns.RoadmapData or {
    KnownIssues = {
        "Combat lockdown can still prevent opening Blizzard quest dialogs; the Hunt Console now reports this instead of silently failing.",
        "Roster data is local-only and only updates after each character is seen by the addon.",
    },
    PlannedFeatures = {
        "More account dashboard filters once Blizzard exposes richer reward metadata in live hunt dialogs.",
        "Optional export of Hunt OS history for players who want external farming logs after v4.",
        "Expanded Goal Engine scoring as new Midnight hunt achievements and rewards are discovered.",
    },
}

