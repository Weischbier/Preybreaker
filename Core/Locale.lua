-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten
--
-- Locale bootstrap. Defines enUS base strings and the L lookup table.
-- Per-language translation files in Locale/ load after this and register
-- their tables via ns._activeTranslation when the client locale matches.

local _, ns = ...

local L = {}
ns.L = L

ns._clientLocale = GetLocale and GetLocale() or "enUS"
ns._activeTranslation = nil

local baseStrings = {
    -- Section titles
    ["Tracker"] = "Tracker",
    ["Placement"] = "Placement",
    ["Readout"] = "Readout",
    ["Text style"] = "Text style",
    ["Quest help"] = "Quest help",
    ["Audio & feedback"] = "Audio & feedback",
    ["Drag & grid"] = "Drag & grid",
    ["Profile"] = "Profile",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Pick the tracker style and the overall size that feels right on your screen.",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "Keep the tracker on the prey icon or switch it to a movable floating layout.",
    ["Choose which cues appear around the tracker while you hunt."] = "Choose which cues appear around the tracker while you hunt.",
    ["Adjust tracker text styling without adding a hard dependency. LibSharedMedia fonts appear automatically when the library is installed."] = "Adjust tracker text styling without adding a hard dependency. LibSharedMedia fonts appear automatically when the library is installed.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Keep the active prey quest easy to spot while the hunt is running.",
    ["Control sound cues that fire when your hunt phase changes."] = "Control sound cues that fire when your hunt phase changes.",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "Fine-tune how the floating tracker behaves when you reposition it.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Choose whether this character uses its own settings or the account-wide defaults.",

    -- Field titles
    ["Enable tracker"] = "Enable tracker",
    ["Display style"] = "Display style",
    ["Display size"] = "Display size",
    ["Detach from prey icon"] = "Detach from prey icon",
    ["Lock floating position"] = "Lock floating position",
    ["Reset floating position"] = "Reset floating position",
    ["Hide Blizzard prey icon"] = "Hide Blizzard prey icon",
    ["Horizontal position"] = "Horizontal position",
    ["Vertical position"] = "Vertical position",
    ["Show progress number"] = "Show progress number",
    ["Show stage badge"] = "Show stage badge",
    ["Font face"] = "Font face",
    ["Outline"] = "Outline",
    ["Shadow"] = "Shadow",
    ["Number size"] = "Number size",
    ["Badge size"] = "Badge size",
    ["Add prey quest to tracker"] = "Add prey quest to tracker",
    ["Focus the prey quest"] = "Focus the prey quest",
    ["Play sound on phase change"] = "Play sound on phase change",
    ["Snap to grid"] = "Snap to grid",
    ["Grid size"] = "Grid size",
    ["Use character profile"] = "Use character profile",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Turn Preybreaker on or off without losing your layout.",
    ["Choose the shape that best fits your UI."] = "Choose the shape that best fits your UI.",
    ["Make the current style bigger or smaller."] = "Make the current style bigger or smaller.",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "Turn the tracker into a free-floating element you can place anywhere.",
    ["Keep the floating tracker fixed once it is where you want it."] = "Keep the floating tracker fixed once it is where you want it.",
    ["Available after you switch the tracker to the floating layout."] = "Available after you switch the tracker to the floating layout.",
    ["Bring the floating tracker back to the center of your screen."] = "Bring the floating tracker back to the center of your screen.",
    ["Show only Preybreaker while the prey hunt is active."] = "Show only Preybreaker while the prey hunt is active.",
    ["Show a simple number inside the tracker."] = "Show a simple number inside the tracker.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Display COLD, WARM, HOT, or FINAL below the tracker.",
    ["Stage badges are available in ring and orb styles."] = "Stage badges are available in ring and orb styles.",
    ["Choose a Blizzard font by default, or pick a LibSharedMedia font when one is available."] = "Choose a Blizzard font by default, or pick a LibSharedMedia font when one is available.",
    ["Override the text outline used by the tracker readouts."] = "Override the text outline used by the tracker readouts.",
    ["Override the text shadow used by the tracker readouts."] = "Override the text shadow used by the tracker readouts.",
    ["Scale the progress number and the text-only readout without changing the tracker frame itself."] = "Scale the progress number and the text-only readout without changing the tracker frame itself.",
    ["Scale the stage badge text separately from the main progress number."] = "Scale the stage badge text separately from the main progress number.",
    ["Automatically place the active prey quest in your watch list."] = "Automatically place the active prey quest in your watch list.",
    ["Keep the active prey quest selected for your objective arrow."] = "Keep the active prey quest selected for your objective arrow.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Hear an audio cue when the prey hunt moves to a new stage.",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "Align the floating tracker to an invisible pixel grid when you drop it.",
    ["Spacing of the snap grid in pixels."] = "Spacing of the snap grid in pixels.",
    ["Store a separate set of settings for this character."] = "Store a separate set of settings for this character.",
    ["Reset position"] = "Reset position",
    ["Nudge the tracker left or right around the prey icon."] = "Nudge the tracker left or right around the prey icon.",
    ["Move the floating tracker left or right on the screen."] = "Move the floating tracker left or right on the screen.",
    ["Nudge the tracker up or down around the prey icon."] = "Nudge the tracker up or down around the prey icon.",
    ["Move the floating tracker up or down on the screen."] = "Move the floating tracker up or down on the screen.",

    -- Display mode labels
    ["Ring"] = "Ring",
    ["Orbs"] = "Orbs",
    ["Bar"] = "Bar",
    ["Text"] = "Text",

    -- Stage labels
    ["COLD"] = "COLD",
    ["WARM"] = "WARM",
    ["HOT"] = "HOT",
    ["FINAL"] = "FINAL",

    -- State labels
    ["On"] = "On",
    ["Off"] = "Off",
    ["Unavailable"] = "Unavailable",
    ["Default"] = "Default",
    ["None"] = "None",
    ["Outline"] = "Outline",
    ["Thick outline"] = "Thick outline",

    -- Summary / sidebar labels
    ["Current setup"] = "Current setup",
    ["Preview"] = "Preview",
    ["Quick actions"] = "Quick actions",
    ["Style"] = "Style",
    ["Blizzard UI"] = "Blizzard UI",
    ["Floating"] = "Floating",
    ["Attached"] = "Attached",
    ["Overlay only"] = "Overlay only",
    ["Show both"] = "Show both",
    ["Number on"] = "Number on",
    ["Number off"] = "Number off",
    ["Badge on"] = "Badge on",
    ["Badge off"] = "Badge off",
    ["Watch + waypoint focus"] = "Watch + waypoint focus",
    ["Watch list only"] = "Watch list only",
    ["Waypoint focus only"] = "Waypoint focus only",
    ["Orb strip"] = "Orb strip",
    ["Text only"] = "Text only",
    ["Reset all"] = "Reset all",
    ["Refresh now"] = "Refresh now",
    ["DRAG TO MOVE"] = "DRAG TO MOVE",
    ["DRAGGING"] = "DRAGGING",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Settings reset to defaults.",
    ["Refreshed prey widget state."] = "Refreshed prey widget state.",
    ["Tracker enabled."] = "Tracker enabled.",
    ["Tracker disabled."] = "Tracker disabled.",
    ["Debug tracing enabled."] = "Debug tracing enabled.",
    ["Debug tracing disabled."] = "Debug tracing disabled.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Compact prey-hunt tracker anchored to the Blizzard widget.",
    ["Status: disabled"] = "Status: disabled",
    ["Status: idle"] = "Status: idle",
    ["Status: %s (%d%%)"] = "Status: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Left-click: Enable or disable the tracker",
    ["Shift-left-click: Open settings"] = "Shift-left-click: Open settings",
    ["Right-click: Force a tracker refresh"] = "Right-click: Force a tracker refresh",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "Shape the prey tracker around your HUD with a live preview and clear sections.",
    ["Live state shows up here as soon as a prey hunt starts."] = "Live state shows up here as soon as a prey hunt starts.",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "Open this panel with /pb or by shift-left-clicking the compartment icon.",

    -- Settings panel status
    ["DISABLED"] = "DISABLED",
    ["SAMPLE"] = "SAMPLE",
    ["ACTIVE"] = "ACTIVE",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker is turned off. Your current layout stays saved.",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "Live prey hunt detected. The preview mirrors the current tracker state.",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "No prey hunt is active right now, so the preview shows a sample state.",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "Preview stays available while the tracker is turned off.",
    ["Floating layout locked. Unlock it to drag the live tracker."] = "Floating layout locked. Unlock it to drag the live tracker.",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "Floating layout ready. Drag the live tracker when a hunt is active.",
    ["Text view without the Blizzard prey icon."] = "Text view without the Blizzard prey icon.",
    ["Text view attached to the Blizzard prey icon."] = "Text view attached to the Blizzard prey icon.",
    ["Bar view without the Blizzard prey icon."] = "Bar view without the Blizzard prey icon.",
    ["Bar view anchored below the Blizzard prey icon."] = "Bar view anchored below the Blizzard prey icon.",
    ["Orb view without the Blizzard prey icon."] = "Orb view without the Blizzard prey icon.",
    ["Orb view attached to the Blizzard prey icon."] = "Orb view attached to the Blizzard prey icon.",
    ["Ring view without the Blizzard prey icon."] = "Ring view without the Blizzard prey icon.",
    ["Ring sample without the Blizzard prey icon."] = "Ring sample without the Blizzard prey icon.",
    ["Ring view attached to the Blizzard prey icon."] = "Ring view attached to the Blizzard prey icon.",
    ["Ring sample attached to the Blizzard prey icon."] = "Ring sample attached to the Blizzard prey icon.",
}

setmetatable(L, {
    __index = function(_, key)
        local translation = ns._activeTranslation
        if translation and translation[key] then
            return translation[key]
        end
        return baseStrings[key] or key
    end,
})
