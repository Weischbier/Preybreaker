-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "deDE" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Tracker",
    ["Placement"] = "Platzierung",
    ["Readout"] = "Anzeige",
    ["Quest help"] = "Questhilfe",
    ["Audio & feedback"] = "Audio & Feedback",
    ["Drag & grid"] = "Ziehen & Raster",
    ["Profile"] = "Profil",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Wähle den Trackerstil und die Gesamtgröße, die auf deinem Bildschirm am besten passt.",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "Behalte den Tracker am Beutesymbol oder wechsle zu einem verschiebbaren Layout.",
    ["Choose which cues appear around the tracker while you hunt."] = "Wähle, welche Hinweise während der Jagd um den Tracker erscheinen.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Die aktive Beutequest bleibt während der Jagd gut sichtbar.",
    ["Control sound cues that fire when your hunt phase changes."] = "Steuere Tonhinweise, die beim Phasenwechsel ertönen.",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "Passe an, wie sich der schwebende Tracker beim Verschieben verhält.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Wähle, ob dieser Charakter eigene Einstellungen oder die kontoweiten Standardwerte nutzt.",

    -- Field titles
    ["Enable tracker"] = "Tracker aktivieren",
    ["Display style"] = "Anzeigestil",
    ["Display size"] = "Anzeigegröße",
    ["Detach from prey icon"] = "Vom Beutesymbol lösen",
    ["Lock floating position"] = "Schwebende Position sperren",
    ["Reset floating position"] = "Schwebende Position zurücksetzen",
    ["Hide Blizzard prey icon"] = "Blizzard-Beutesymbol ausblenden",
    ["Horizontal position"] = "Horizontale Position",
    ["Vertical position"] = "Vertikale Position",
    ["Show progress number"] = "Fortschrittszahl anzeigen",
    ["Show stage badge"] = "Stufenabzeichen anzeigen",
    ["Add prey quest to tracker"] = "Beutequest zum Tracker hinzufügen",
    ["Focus the prey quest"] = "Beutequest fokussieren",
    ["Play sound on phase change"] = "Ton bei Phasenwechsel abspielen",
    ["Snap to grid"] = "Am Raster ausrichten",
    ["Grid size"] = "Rastergröße",
    ["Use character profile"] = "Charakterprofil verwenden",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Preybreaker ein- oder ausschalten, ohne dein Layout zu verlieren.",
    ["Choose the shape that best fits your UI."] = "Wähle die Form, die am besten zu deiner Oberfläche passt.",
    ["Make the current style bigger or smaller."] = "Den aktuellen Stil vergrößern oder verkleinern.",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "Den Tracker in ein frei schwebendes Element verwandeln.",
    ["Keep the floating tracker fixed once it is where you want it."] = "Den schwebenden Tracker fixieren, sobald er an der gewünschten Stelle ist.",
    ["Available after you switch the tracker to the floating layout."] = "Verfügbar, nachdem du zum schwebenden Layout gewechselt hast.",
    ["Bring the floating tracker back to the center of your screen."] = "Den schwebenden Tracker zurück in die Bildschirmmitte bringen.",
    ["Show only Preybreaker while the prey hunt is active."] = "Nur Preybreaker anzeigen, solange die Beutejagd aktiv ist.",
    ["Show a simple number inside the tracker."] = "Eine einfache Zahl im Tracker anzeigen.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "KALT, WARM, HEISS oder FINAL unter dem Tracker anzeigen.",
    ["Stage badges are available in ring and orb styles."] = "Stufenabzeichen sind in Ring- und Kugelstilen verfügbar.",
    ["Automatically place the active prey quest in your watch list."] = "Die aktive Beutequest automatisch in deine Beobachtungsliste setzen.",
    ["Keep the active prey quest selected for your objective arrow."] = "Die aktive Beutequest für deinen Zielpfeil ausgewählt lassen.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Einen Ton hören, wenn die Beutejagd in eine neue Phase wechselt.",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "Den schwebenden Tracker beim Ablegen an einem unsichtbaren Pixelraster ausrichten.",
    ["Spacing of the snap grid in pixels."] = "Abstand des Einrastrasters in Pixeln.",
    ["Store a separate set of settings for this character."] = "Einen eigenen Satz Einstellungen für diesen Charakter speichern.",
    ["Reset position"] = "Position zurücksetzen",
    ["Nudge the tracker left or right around the prey icon."] = "Den Tracker um das Beutesymbol nach links oder rechts verschieben.",
    ["Move the floating tracker left or right on the screen."] = "Den schwebenden Tracker auf dem Bildschirm nach links oder rechts bewegen.",
    ["Nudge the tracker up or down around the prey icon."] = "Den Tracker um das Beutesymbol nach oben oder unten verschieben.",
    ["Move the floating tracker up or down on the screen."] = "Den schwebenden Tracker auf dem Bildschirm nach oben oder unten bewegen.",

    -- Display mode labels
    ["Ring"] = "Ring",
    ["Orbs"] = "Kugeln",
    ["Bar"] = "Balken",
    ["Text"] = "Text",

    -- Stage labels
    ["COLD"] = "KALT",
    ["WARM"] = "WARM",
    ["HOT"] = "HEISS",
    ["FINAL"] = "FINAL",

    -- State labels
    ["On"] = "An",
    ["Off"] = "Aus",
    ["Unavailable"] = "Nicht verfügbar",

    -- Summary / sidebar labels
    ["Current setup"] = "Aktuelle Konfiguration",
    ["Preview"] = "Vorschau",
    ["Quick actions"] = "Schnellaktionen",
    ["Style"] = "Stil",
    ["Blizzard UI"] = "Blizzard-Oberfläche",
    ["Floating"] = "Schwebend",
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
    ["DRAG TO MOVE"] = "ZIEHEN ZUM BEWEGEN",
    ["DRAGGING"] = "WIRD BEWEGT",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Einstellungen auf Standard zurückgesetzt.",
    ["Refreshed prey widget state."] = "Beute-Widget-Status aktualisiert.",
    ["Tracker enabled."] = "Tracker aktiviert.",
    ["Tracker disabled."] = "Tracker deaktiviert.",
    ["Debug tracing enabled."] = "Debug-Protokollierung aktiviert.",
    ["Debug tracing disabled."] = "Debug-Protokollierung deaktiviert.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Kompakter Beutejagd-Tracker am Blizzard-Widget verankert.",
    ["Status: disabled"] = "Status: deaktiviert",
    ["Status: idle"] = "Status: bereit",
    ["Status: %s (%d%%)"] = "Status: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Linksklick: Tracker ein- oder ausschalten",
    ["Shift-left-click: Open settings"] = "Umschalt-Linksklick: Einstellungen öffnen",
    ["Right-click: Force a tracker refresh"] = "Rechtsklick: Tracker-Aktualisierung erzwingen",

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
    ["Floating layout locked. Unlock it to drag the live tracker."] = "Schwebendes Layout gesperrt. Entsperren, um den Live-Tracker zu ziehen.",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "Schwebendes Layout bereit. Ziehe den Live-Tracker, wenn eine Jagd aktiv ist.",
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
}
