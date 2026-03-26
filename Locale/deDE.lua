-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "deDE" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Tracker",
    ["Placement"] = "Platzierung",
    ["Readout"] = "Anzeige",
    ["Text style"] = "Textstil",
    ["Quest help"] = "Questhilfe",
    ["Audio & feedback"] = "Audio & Feedback",
    ["Profile"] = "Profil",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Wähle den Trackerstil und die Gesamtgröße, die auf deinem Bildschirm am besten passt.",
    ["Keep the tracker attached to the prey icon and nudge it into place."] = "Halte den Tracker am Beutesymbol fest und verschiebe ihn in die richtige Position.",
    ["Choose which cues appear around the tracker while you hunt."] = "Wähle, welche Hinweise während der Jagd um den Tracker erscheinen.",
    ["Adjust tracker text styling without adding a hard dependency. LibSharedMedia fonts appear automatically when the library is installed."] = "Passe die Textstile des Trackers an, ohne eine feste Abhängigkeit hinzuzufügen. LibSharedMedia-Schriften erscheinen automatisch, wenn die Bibliothek installiert ist.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Die aktive Beutequest bleibt während der Jagd gut sichtbar.",
    ["Control sound cues that fire when your hunt phase changes."] = "Steuere Tonhinweise, die beim Phasenwechsel ertönen.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Wähle, ob dieser Charakter eigene Einstellungen oder die kontoweiten Standardwerte nutzt.",

    -- Field titles
    ["Enable tracker"] = "Tracker aktivieren",
    ["Display style"] = "Anzeigestil",
    ["Display size"] = "Anzeigegröße",
    ["Hide Blizzard prey icon"] = "Blizzard-Beutesymbol ausblenden",
    ["Horizontal position"] = "Horizontale Position",
    ["Vertical position"] = "Vertikale Position",
    ["Show progress number"] = "Fortschrittszahl anzeigen",
    ["Show stage badge"] = "Stufenabzeichen anzeigen",
    ["Font face"] = "Schriftart",
    ["Outline"] = "Umriss",
    ["Shadow"] = "Schatten",
    ["Number size"] = "Zahlengröße",
    ["Badge size"] = "Abzeichengröße",
    ["Add prey quest to tracker"] = "Beutequest zum Tracker hinzufügen",
    ["Focus the prey quest"] = "Beutequest fokussieren",
    ["Auto turn-in prey quest"] = "Beutequest automatisch abgeben",
    ["Play sound on phase change"] = "Ton bei Phasenwechsel abspielen",
    ["Sound theme"] = "Klangthema",
    ["Death cue during hunt"] = "Todessignal während der Jagd",
    ["Use character profile"] = "Charakterprofil verwenden",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Preybreaker ein- oder ausschalten, ohne dein Layout zu verlieren.",
    ["Choose the shape that best fits your UI."] = "Wähle die Form, die am besten zu deiner Oberfläche passt.",
    ["Make the current style bigger or smaller."] = "Den aktuellen Stil vergrößern oder verkleinern.",
    ["Show only Preybreaker while the prey hunt is active."] = "Nur Preybreaker anzeigen, solange die Beutejagd aktiv ist.",
    ["Show a simple number inside the tracker."] = "Eine einfache Zahl im Tracker anzeigen.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "KALT, WARM, HEISS oder FINAL unter dem Tracker anzeigen.",
    ["Stage badges are available in ring and orb styles."] = "Stufenabzeichen sind in Ring- und Kugelstilen verfügbar.",
    ["Choose a Blizzard font by default, or pick a LibSharedMedia font when one is available."] = "Standardmäßig eine Blizzard-Schrift verwenden oder eine LibSharedMedia-Schrift wählen, wenn verfügbar.",
    ["Override the text outline used by the tracker readouts."] = "Den Textumriss der Trackeranzeigen überschreiben.",
    ["Override the text shadow used by the tracker readouts."] = "Den Textschatten der Trackeranzeigen überschreiben.",
    ["Scale the progress number and the text-only readout without changing the tracker frame itself."] = "Die Fortschrittszahl und die Textanzeige skalieren, ohne den Trackerrahmen zu ändern.",
    ["Scale the stage badge text separately from the main progress number."] = "Den Text des Stufenabzeichens separat von der Fortschrittszahl skalieren.",
    ["Automatically place the active prey quest in your watch list."] = "Die aktive Beutequest automatisch in deine Beobachtungsliste setzen.",
    ["Keep the active prey quest selected for your objective arrow."] = "Die aktive Beutequest für deinen Zielpfeil ausgewählt lassen.",
    ["Automatically complete the prey quest when it pops up, unless a reward choice is required."] = "Die Beutequest automatisch abschließen, wenn sie erscheint, es sei denn eine Belohnungsauswahl ist erforderlich.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Einen Ton hören, wenn die Beutejagd in eine neue Phase wechselt.",
    ["Select the active sound pack used for prey hunt audio cues."] = "Das aktive Soundpaket für Beutejagd-Audiosignale auswählen.",
    ["Play a death cue when you die during an active prey hunt in the hunt zone."] = "Ein Todessignal abspielen, wenn du während einer aktiven Beutejagd im Jagdgebiet stirbst.",
    ["Store a separate set of settings for this character."] = "Einen eigenen Satz Einstellungen für diesen Charakter speichern.",
    ["Nudge the tracker left or right around the prey icon."] = "Den Tracker um das Beutesymbol nach links oder rechts verschieben.",
    ["Nudge the tracker up or down around the prey icon."] = "Den Tracker um das Beutesymbol nach oben oder unten verschieben.",

    -- Display mode labels
    ["Ring"] = "Ring",
    ["Orbs"] = "Kugeln",
    ["Bar"] = "Balken",
    ["Text"] = "Text",

    -- Sound theme labels
    ["Among Us"] = "Among Us",
    ["Generic"] = "Allgemein",
    ["Jurassic Park"] = "Jurassic Park",
    ["Pokemon"] = "Pokemon",
    ["Predator"] = "Predator",
    ["Stranger Things"] = "Stranger Things",
    ["Random"] = "Zufällig",

    -- Stage labels
    ["COLD"] = "KALT",
    ["WARM"] = "WARM",
    ["HOT"] = "HEISS",
    ["FINAL"] = "FINAL",

    -- State labels
    ["On"] = "An",
    ["Off"] = "Aus",
    ["Unavailable"] = "Nicht verfügbar",
    ["Default"] = "Standard",
    ["None"] = "Keine",
    ["Thick outline"] = "Dicker Umriss",

    -- Summary / sidebar labels
    ["Current setup"] = "Aktuelle Konfiguration",
    ["Preview"] = "Vorschau",
    ["Quick actions"] = "Schnellaktionen",
    ["Style"] = "Stil",
    ["Blizzard UI"] = "Blizzard-Oberfläche",
    ["Attached"] = "Angeheftet",
    ["Overlay only"] = "Nur Overlay",
    ["Show both"] = "Beides anzeigen",
    ["Number on"] = "Zahl an",
    ["Number off"] = "Zahl aus",
    ["Badge on"] = "Abzeichen an",
    ["Badge off"] = "Abzeichen aus",
    ["Watch + waypoint focus"] = "Beobachten + Wegpunktfokus",
    ["Watch list only"] = "Nur Beobachtungsliste",
    ["Waypoint focus only"] = "Nur Wegpunktfokus",
    ["Orb strip"] = "Kugelleiste",
    ["Text only"] = "Nur Text",
    ["Reset all"] = "Alles zurücksetzen",
    ["Refresh now"] = "Jetzt aktualisieren",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Einstellungen auf Standard zurückgesetzt.",
    ["Refreshed prey widget state."] = "Beute-Widget-Status aktualisiert.",
    ["Tracker enabled."] = "Tracker aktiviert.",
    ["Tracker disabled."] = "Tracker deaktiviert.",
    ["Debug tracing enabled."] = "Debug-Protokollierung aktiviert.",
    ["Debug tracing disabled."] = "Debug-Protokollierung deaktiviert.",
    ["Standalone hunt panel shown."] = "Eigenständiges Jagdfenster angezeigt.",
    ["Standalone hunt panel hidden."] = "Eigenständiges Jagdfenster ausgeblendet.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Kompakter Beutejagd-Tracker am Blizzard-Widget verankert.",
    ["Status: disabled"] = "Status: deaktiviert",
    ["Status: idle"] = "Status: bereit",
    ["Status: %s (%d%%)"] = "Status: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Linksklick: Tracker ein- oder ausschalten",
    ["Shift-left-click: Open settings"] = "Umschalt-Linksklick: Einstellungen öffnen",
    ["Right-click: Force a tracker refresh"] = "Rechtsklick: Tracker-Aktualisierung erzwingen",
    ["Shift-right-click: Open hunt panel"] = "Umschalt-Rechtsklick: Jagdfenster öffnen",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "Passe den Beutetracker an dein HUD an, mit Live-Vorschau und klaren Abschnitten.",
    ["Live state shows up here as soon as a prey hunt starts."] = "Der Live-Status erscheint hier, sobald eine Beutejagd beginnt.",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "Öffne dieses Fenster mit /pb oder durch Umschalt-Linksklick auf das Fachsymbol.",

    -- Settings panel status
    ["DISABLED"] = "DEAKTIVIERT",
    ["SAMPLE"] = "BEISPIEL",
    ["ACTIVE"] = "AKTIV",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker ist ausgeschaltet. Dein aktuelles Layout bleibt gespeichert.",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "Live-Beutejagd erkannt. Die Vorschau spiegelt den aktuellen Tracker-Status.",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "Gerade ist keine Beutejagd aktiv, daher zeigt die Vorschau einen Beispielstatus.",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "Die Vorschau bleibt verfügbar, solange der Tracker ausgeschaltet ist.",
    ["Text view without the Blizzard prey icon."] = "Textansicht ohne das Blizzard-Beutesymbol.",
    ["Text view attached to the Blizzard prey icon."] = "Textansicht am Blizzard-Beutesymbol angeheftet.",
    ["Bar view without the Blizzard prey icon."] = "Balkenansicht ohne das Blizzard-Beutesymbol.",
    ["Bar view anchored below the Blizzard prey icon."] = "Balkenansicht unterhalb des Blizzard-Beutesymbols verankert.",
    ["Orb view without the Blizzard prey icon."] = "Kugelansicht ohne das Blizzard-Beutesymbol.",
    ["Orb view attached to the Blizzard prey icon."] = "Kugelansicht am Blizzard-Beutesymbol angeheftet.",
    ["Ring view without the Blizzard prey icon."] = "Ringansicht ohne das Blizzard-Beutesymbol.",
    ["Ring sample without the Blizzard prey icon."] = "Ring-Beispiel ohne das Blizzard-Beutesymbol.",
    ["Ring view attached to the Blizzard prey icon."] = "Ringansicht am Blizzard-Beutesymbol angeheftet.",
    ["Ring sample attached to the Blizzard prey icon."] = "Ring-Beispiel am Blizzard-Beutesymbol angeheftet.",

    -- Hunt panel settings
    ["Hunt panel"] = "Jagdfenster",
    ["Control the hunt list panel that docks beside the Adventure Map."] = "Steuere das Jagdlistenfenster, das neben der Abenteuerkarte andockt.",
    ["Enable hunt panel"] = "Jagdfenster aktivieren",
    ["Show the hunt list panel when the Adventure Map is open and allow standalone use."] = "Zeige das Jagdlistenfenster, wenn die Abenteuerkarte geöffnet ist, und erlaube eigenständige Nutzung.",
    ["Hunt panel disabled."] = "Jagdfenster deaktiviert.",

    -- Random hunt settings
    ["Random hunt"] = "Zufällige Jagd",
    ["Automate randomized hunt purchasing from Astalor Bloodsworn."] = "Automatisiere den Kauf zufälliger Jagden bei Astalor Blutgeschworen.",
    ["Auto-purchase random hunt"] = "Zufällige Jagd automatisch kaufen",
    ["Automatically request a randomized hunt from Astalor Bloodsworn when you open his gossip window."] = "Fordere automatisch eine zufällige Jagd bei Astalor Blutgeschworen an, wenn du sein Gesprächsfenster öffnest.",
    ["Hunt difficulty"] = "Jagdschwierigkeit",
    ["Choose which difficulty to purchase when auto-buying a randomized hunt."] = "Wähle den Schwierigkeitsgrad beim automatischen Kauf einer zufälligen Jagd.",
    ["Normal"] = "Normal",
    ["Hard"] = "Schwer",
    ["Nightmare"] = "Albtraum",
    ["Remnant reserve"] = "Überrestreserve",
    ["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."] = "Kaufe eine Jagd nur, wenn du mindestens so viele Überreste der Qual plus die 50 Kaufkosten besitzt.",

    -- Hunt rewards settings
    ["Hunt rewards"] = "Jagdbelohnungen",
    ["Automatically choose rewards when completing a prey hunt."] = "Wähle Belohnungen beim Abschluss einer Beutejagd automatisch.",
    ["Auto-select hunt reward"] = "Jagdbelohnung automatisch wählen",
    ["Automatically pick a reward when a completed hunt offers multiple choices."] = "Wähle automatisch eine Belohnung, wenn eine abgeschlossene Jagd mehrere Optionen bietet.",
    ["Preferred reward"] = "Bevorzugte Belohnung",
    ["The reward type to pick first when completing a hunt."] = "Der Belohnungstyp, der beim Abschluss einer Jagd zuerst gewählt wird.",
    ["Fallback reward"] = "Ersatzbelohnung",
    ["The reward to pick if your preferred choice is unavailable or its currency is capped."] = "Die Belohnung, die gewählt wird, wenn die bevorzugte Option nicht verfügbar oder die Währung am Limit ist.",
    ["Gear upgrade currency"] = "Ausrüstungs-Aufwertungswährung",
    ["Remnant of Anguish"] = "Überrest der Qual",
    ["Gold"] = "Gold",
    ["Voidlight Marl"] = "Leerenlichtmergel",

    -- Tab labels
    ["Settings"] = "Einstellungen",
    ["Changelog"] = "Änderungsprotokoll",
    ["Social"] = "Sozial",
    ["Roadmap"] = "Fahrplan",
    ["Select"] = "Auswählen",
    ["Select URL text and copy it."] = "URL-Text auswählen und kopieren.",
    ["Known issues"] = "Bekannte Probleme",
    ["Planned features"] = "Geplante Funktionen",
    ["Items tracked for upcoming releases."] = "Elemente, die für kommende Veröffentlichungen verfolgt werden.",
    ["No known issues currently listed."] = "Keine bekannten Probleme aktuell aufgeführt.",
    ["No planned features currently listed."] = "Keine geplanten Funktionen aktuell aufgeführt.",
}
