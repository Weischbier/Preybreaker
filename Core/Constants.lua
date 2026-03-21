-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local ADDON_NAME, ns = ...

ns.Constants = {
    WidgetTypePrey = (Enum and Enum.UIWidgetVisualizationType and Enum.UIWidgetVisualizationType.PreyHuntProgress) or 31,
    WidgetShown = (Enum and Enum.WidgetShownState and Enum.WidgetShownState.Shown) or 1,

    DisplayMode = {
        Radial = "radial",
        Orbs = "orbs",
        Bar = "bar",
        Text = "text",
    },

    Anchor = {
        Point = "CENTER",
        RelativePoint = "CENTER",
        OffsetX = 0,
        OffsetY = 0,
        ContainerFallbackOffsetX = 0,
        ContainerFallbackOffsetY = 0,
        FallbackY = -150,
    },

    Layout = {
        RingSize = 130,
        ProgressSize = 130,
        OrbFrameWidth = 96,
        OrbFrameHeight = 80,
        OrbGlowScale = 1.25,
        OrbSpacing = 4,
        OrbInactiveAlpha = 0.28,
        OrbGlowAlpha = 0.22,
        OrbInactiveGlowAlpha = 0.08,
        OrbSizeByState = {
            [0] = 12,
            [1] = 16,
            [2] = 20,
            [3] = 24,
        },
        OrbValueTextOffsetX = 0,
        OrbValueTextOffsetY = 18,
        ValueTextOffsetX = 0,
        ValueTextOffsetY = 25,
        ValueTextFontDelta = -4,
        BarWidth = 132,
        BarHeight = 27,
        BarBackgroundAlpha = 0.70,
        BarBackgroundInsetX = 6,
        BarBackgroundInsetY = 7,
        BarFillInsetX = 6,
        BarFillInsetY = 7,
        BarVisibleOffsetY = -8,
        StageBadgeWidth = 76,
        StageBadgeHeight = 30,
        StageBadgeOffsetX = 0,
        StageBadgeOffsetY = -4,
        StageBadgeCompactOffsetY = -10,
        FrameLevelOffset = 32,
        FrameStrata = "MEDIUM",
    },

    SettingsPanel = {
        Width = 890,
        Height = 730,
        Padding = 18,
        HeaderHeight = 72,
        SidebarWidth = 234,
        ContentInset = 16,
        SectionSpacing = 12,
        SectionHeaderHeight = 54,
        RowHeight = 62,
        ChoiceRowHeight = 88,
        SliderRowHeight = 94,
        DropdownRowHeight = 100,
        ActionRowHeight = 72,
        ChoiceButtonWidth = 104,
        ChoiceButtonHeight = 24,
        SummaryCardHeight = 228,
        PreviewCardHeight = 252,
        ActionCardHeight = 110,
        PreviewWidgetScale = 0.52,
        AccentColor = { 0.86, 0.66, 0.28 },
        AccentSoftColor = { 0.53, 0.33, 0.08 },
        TitleColor = { 0.94, 0.86, 0.72 },
        BodyColor = { 0.77, 0.72, 0.66 },
        MutedColor = { 0.58, 0.54, 0.49 },
        PositiveColor = { 0.82, 0.90, 0.63 },
        SurfaceColor = { 0.08, 0.06, 0.05, 0.96 },
        SurfaceRaisedColor = { 0.11, 0.08, 0.06, 0.98 },
        SurfaceInsetColor = { 0.12, 0.09, 0.07, 0.84 },
        BorderColor = { 0.66, 0.49, 0.21, 1.00 },
        BorderSoftColor = { 0.66, 0.49, 0.21, 0.34 },
    },

    Debug = {
        Enabled = false,
    },

    ProgressByState = {
        [0] = 0.00,
        [1] = 0.34,
        [2] = 0.67,
        [3] = 1.00,
    },

    ColorByState = {
        [0] = { 0.72, 0.72, 0.76 },
        [1] = { 0.95, 0.78, 0.25 },
        [2] = { 0.97, 0.50, 0.12 },
        [3] = { 0.93, 0.21, 0.18 },
    },

    StageLabelByState = {
        [0] = "COLD",
        [1] = "WARM",
        [2] = "HOT",
        [3] = "FINAL",
    },

    Media = {
        RadialProgress = "Interface\\AddOns\\Preybreaker\\Media\\Assets\\ProgressBar-Radial-WarWithin",
        StageBadge = "Interface\\AddOns\\Preybreaker\\Media\\Assets\\uiwowlabsactionbar",
        AddonIcon = "Interface\\AddOns\\Preybreaker\\Media\\Assets\\Preybreaker-Icon",
        PreyWidgetTexture = "Interface\\Prey\\UIPrey2x",
        -- Atlases verified against Blizzard's widget status bar set via TextureAtlasViewer.
        WidgetStatusBarAtlas = {
            BackgroundLeft = "widgetstatusbar-bgleft",
            BackgroundCenter = "widgetstatusbar-bgcenter",
            BackgroundRight = "widgetstatusbar-bgright",
            BorderLeft = "widgetstatusbar-borderleft",
            BorderCenter = "widgetstatusbar-bordercenter",
            BorderRight = "widgetstatusbar-borderright",
            Fill = "widgetstatusbar-fill-white",
            Spark = "widgetstatusbar-spark",
        },
        -- Neutral circular atlases verified in the local TextureAtlasViewer data set.
        WidgetOrbAtlas = {
            Fill = "common-radiobutton-dot",
            Glow = "common-roundhighlight",
        },
        -- Current Retail PreyHuntProgress uses the final atlas for both Hot and Final.
        PreyWidgetAtlasByState = {
            [0] = "ui-prey-targeticon-regular",
            [1] = "ui-prey-targeticon-inprogress",
            [2] = "ui-prey-targeticon-final",
            [3] = "ui-prey-targeticon-final",
        },
        PreyWidgetAtlasFallback = {
            ["ui-prey-targeticon-final"] = {
                width = 110,
                height = 138,
                left = 0.001953125,
                right = 0.216796875,
                top = 0.380859375,
                bottom = 0.650390625,
            },
            ["ui-prey-targeticon-inprogress"] = {
                width = 110,
                height = 138,
                left = 0.220703125,
                right = 0.435546875,
                top = 0.380859375,
                bottom = 0.650390625,
            },
            ["ui-prey-targeticon-regular"] = {
                width = 110,
                height = 138,
                left = 0.220703125,
                right = 0.435546875,
                top = 0.654296875,
                bottom = 0.923828125,
            },
        },
        Sounds = {
            HuntStart = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\AmongUs\\hunt_start.ogg",
            HuntEnd = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\AmongUs\\hunt_end.ogg",
            Ambush = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\AmongUs\\ambush.ogg",
            Riposte = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\AmongUs\\riposte.ogg",
            Kill = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\AmongUs\\kill.ogg",
            Interaction = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\AmongUs\\interaction.ogg",
            -- Legacy aliases kept for compatibility with older code paths.
            ColdToWarm = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\AmongUs\\ambush.ogg",
            WarmToHot = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\AmongUs\\riposte.ogg",
            PhaseChange = "Interface\\AddOns\\Preybreaker\\Media\\Sounds\\AmongUs\\interaction.ogg",
        },
        StageBadgeTexCoord = {
            left = 1038 / 2048,
            right = 1236 / 2048,
            top = 1481 / 2048,
            bottom = 1559 / 2048,
        },
    },

    Hunt = {
        AstalorNpcID = 253513,
        RemnantCurrencyID = 3392,
        Cost = 50,
        Difficulty = {
            Normal = "normal",
            Hard = "hard",
            Nightmare = "nightmare",
        },
        RewardType = {
            Dawncrest = "dawncrest",
            Remnant = "remnant",
            Gold = "gold",
            Marl = "marl",
        },
        DawncrestCurrencyIDs = { 3391, 3341 },
        VoidlightMarlCurrencyID = 3316,
        RewardPatterns = {
            dawncrest = { "dawncrest", "crest" },
            remnant = { "remnant", "anguish" },
            gold = { "gold", "coin" },
            marl = { "marl", "voidlight" },
        },
        LocalePatterns = {
            enUS = {
                difficulty = {
                    normal = { "normal" },
                    hard = { "hard" },
                    nightmare = { "nightmare" },
                },
                random = { "random" },
            },
            enGB = {
                difficulty = {
                    normal = { "normal" },
                    hard = { "hard" },
                    nightmare = { "nightmare" },
                },
                random = { "random" },
            },
            deDE = {
                difficulty = {
                    normal = { "normal" },
                    hard = { "schwer" },
                    nightmare = { "albtraum" },
                },
                random = { "zufall", "zufallig", "zufällig" },
            },
            frFR = {
                difficulty = {
                    normal = { "normal" },
                    hard = { "difficile" },
                    nightmare = { "cauchemar" },
                },
                random = { "aleatoire", "aléatoire" },
            },
            esES = {
                difficulty = {
                    normal = { "normal" },
                    hard = { "dificil", "difícil" },
                    nightmare = { "pesadilla" },
                },
                random = { "aleatorio", "aleatoria" },
            },
            esMX = {
                difficulty = {
                    normal = { "normal" },
                    hard = { "dificil", "difícil" },
                    nightmare = { "pesadilla" },
                },
                random = { "aleatorio", "aleatoria" },
            },
            itIT = {
                difficulty = {
                    normal = { "normale", "normal" },
                    hard = { "difficile" },
                    nightmare = { "incubo" },
                },
                random = { "casuale" },
            },
            ptBR = {
                difficulty = {
                    normal = { "normal" },
                    hard = { "dificil", "difícil" },
                    nightmare = { "pesadelo" },
                },
                random = { "aleatorio", "aleatória", "aleatoria" },
            },
            ruRU = {
                difficulty = {
                    normal = { "обыч", "обычный" },
                    hard = { "слож", "сложный" },
                    nightmare = { "кошмар" },
                },
                random = { "случайн" },
            },
            koKR = {
                difficulty = {
                    normal = { "일반" },
                    hard = { "어려움", "어려운" },
                    nightmare = { "악몽" },
                },
                random = { "무작위" },
            },
            zhCN = {
                difficulty = {
                    normal = { "普通" },
                    hard = { "困难" },
                    nightmare = { "梦魇" },
                },
                random = { "随机" },
            },
            zhTW = {
                difficulty = {
                    normal = { "普通" },
                    hard = { "困難" },
                    nightmare = { "夢魘" },
                },
                random = { "隨機" },
            },
        },
        DifficultyPatterns = nil,
        RandomPatterns = nil,
        -- Renown faction that gates difficulty unlocks.
        -- Level 1 = Hard, Level 4 = Nightmare (sourced from Plumber MID_Activity.lua).
        RenownFactionID = 2764,
        RenownHardThreshold = 1,
        RenownNightmareThreshold = 4,
        -- Zone order for display sorting.
        Zones = { "Eversong Woods", "Zul'Aman", "Harandar", "Voidstorm" },
    },
}

do
    local preyState = Enum and Enum.PreyHuntProgressState
    local function BuildOrderedStates()
        if not preyState then
            return { 0, 1, 2, 3 }
        end

        return {
            preyState.Cold or 0,
            preyState.Warm or 1,
            preyState.Hot or 2,
            preyState.Final or 3,
        }
    end

    ns.Constants.OrderedStates = BuildOrderedStates()
end

do
    local hunt = ns.Constants and ns.Constants.Hunt
    local locale = ns._clientLocale or (type(GetLocale) == "function" and GetLocale()) or "enUS"
    local localePatterns = nil
    if hunt and hunt.LocalePatterns then
        localePatterns = hunt.LocalePatterns[locale]
        if not localePatterns and type(locale) == "string" then
            localePatterns = hunt.LocalePatterns[strsub(locale, 1, 4)]
        end
        if not localePatterns then
            localePatterns = hunt.LocalePatterns.enUS
        end
    end
    if hunt and localePatterns then
        hunt.DifficultyPatterns = localePatterns.difficulty or hunt.LocalePatterns.enUS.difficulty
        hunt.RandomPatterns = localePatterns.random or hunt.LocalePatterns.enUS.random
    end
end

-- Re-key lookup tables by enum name so values stay correct if numeric IDs differ from hardcoded defaults.
do
    local preyState = Enum and Enum.PreyHuntProgressState
    if preyState then
        ns.Constants.ProgressByState[preyState.Cold] = 0.00
        ns.Constants.ProgressByState[preyState.Warm] = 0.34
        ns.Constants.ProgressByState[preyState.Hot] = 0.67
        ns.Constants.ProgressByState[preyState.Final] = 1.00

        ns.Constants.Layout.OrbSizeByState[preyState.Cold] = 12
        ns.Constants.Layout.OrbSizeByState[preyState.Warm] = 16
        ns.Constants.Layout.OrbSizeByState[preyState.Hot] = 20
        ns.Constants.Layout.OrbSizeByState[preyState.Final] = 24

        ns.Constants.ColorByState[preyState.Cold] = { 0.72, 0.72, 0.76 }
        ns.Constants.ColorByState[preyState.Warm] = { 0.95, 0.78, 0.25 }
        ns.Constants.ColorByState[preyState.Hot] = { 0.97, 0.50, 0.12 }
        ns.Constants.ColorByState[preyState.Final] = { 0.93, 0.21, 0.18 }

        ns.Constants.StageLabelByState[preyState.Cold] = "COLD"
        ns.Constants.StageLabelByState[preyState.Warm] = "WARM"
        ns.Constants.StageLabelByState[preyState.Hot] = "HOT"
        ns.Constants.StageLabelByState[preyState.Final] = "FINAL"
    end
end
