-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "itIT" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Tracciatore",
    ["Placement"] = "Posizionamento",
    ["Readout"] = "Lettura",
    ["Quest help"] = "Aiuto missione",
    ["Audio & feedback"] = "Audio e feedback",
    ["Drag & grid"] = "Trascina e griglia",
    ["Profile"] = "Profilo",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Scegli lo stile del tracciatore e la dimensione adatta al tuo schermo.",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "Tieni il tracciatore sull'icona preda o passa a un layout mobile flottante.",
    ["Choose which cues appear around the tracker while you hunt."] = "Scegli quali indicatori appaiono attorno al tracciatore durante la caccia.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Mantieni la missione preda attiva ben visibile durante la caccia.",
    ["Control sound cues that fire when your hunt phase changes."] = "Controlla i segnali sonori emessi al cambio di fase.",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "Regola il comportamento del tracciatore flottante durante il riposizionamento.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Scegli se questo personaggio usa le proprie impostazioni o i valori predefiniti dell'account.",

    -- Field titles
    ["Enable tracker"] = "Attiva tracciatore",
    ["Display style"] = "Stile di visualizzazione",
    ["Display size"] = "Dimensione di visualizzazione",
    ["Detach from prey icon"] = "Stacca dall'icona preda",
    ["Lock floating position"] = "Blocca posizione flottante",
    ["Reset floating position"] = "Reimposta posizione flottante",
    ["Hide Blizzard prey icon"] = "Nascondi icona preda di Blizzard",
    ["Horizontal position"] = "Posizione orizzontale",
    ["Vertical position"] = "Posizione verticale",
    ["Show progress number"] = "Mostra numero progresso",
    ["Show stage badge"] = "Mostra emblema di fase",
    ["Add prey quest to tracker"] = "Aggiungi missione preda al tracciamento",
    ["Focus the prey quest"] = "Focalizza la missione preda",
    ["Play sound on phase change"] = "Riproduci suono al cambio di fase",
    ["Snap to grid"] = "Allinea alla griglia",
    ["Grid size"] = "Dimensione griglia",
    ["Use character profile"] = "Usa profilo personaggio",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Attiva o disattiva Preybreaker senza perdere il tuo layout.",
    ["Choose the shape that best fits your UI."] = "Scegli la forma che meglio si adatta alla tua interfaccia.",
    ["Make the current style bigger or smaller."] = "Ingrandisci o rimpicciolisci lo stile attuale.",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "Trasforma il tracciatore in un elemento flottante posizionabile ovunque.",
    ["Keep the floating tracker fixed once it is where you want it."] = "Fissa il tracciatore flottante nella posizione desiderata.",
    ["Available after you switch the tracker to the floating layout."] = "Disponibile dopo il passaggio al layout flottante.",
    ["Bring the floating tracker back to the center of your screen."] = "Riporta il tracciatore flottante al centro dello schermo.",
    ["Show only Preybreaker while the prey hunt is active."] = "Mostra solo Preybreaker mentre la caccia è attiva.",
    ["Show a simple number inside the tracker."] = "Mostra un numero semplice nel tracciatore.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Mostra FREDDO, TIEPIDO, CALDO o FINALE sotto il tracciatore.",
    ["Stage badges are available in ring and orb styles."] = "Gli emblemi di fase sono disponibili negli stili anello e sfera.",
    ["Automatically place the active prey quest in your watch list."] = "Posiziona automaticamente la missione preda attiva nella tua lista di controllo.",
    ["Keep the active prey quest selected for your objective arrow."] = "Mantieni la missione preda attiva selezionata per la freccia dell'obiettivo.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Ascolta un segnale sonoro quando la caccia passa a una nuova fase.",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "Allinea il tracciatore flottante a una griglia di pixel invisibile al rilascio.",
    ["Spacing of the snap grid in pixels."] = "Spaziatura della griglia di allineamento in pixel.",
    ["Store a separate set of settings for this character."] = "Memorizza un set separato di impostazioni per questo personaggio.",
    ["Reset position"] = "Reimposta posizione",
    ["Nudge the tracker left or right around the prey icon."] = "Sposta il tracciatore a sinistra o destra attorno all'icona preda.",
    ["Move the floating tracker left or right on the screen."] = "Sposta il tracciatore flottante a sinistra o destra sullo schermo.",
    ["Nudge the tracker up or down around the prey icon."] = "Sposta il tracciatore in alto o in basso attorno all'icona preda.",
    ["Move the floating tracker up or down on the screen."] = "Sposta il tracciatore flottante in alto o in basso sullo schermo.",

    -- Display mode labels
    ["Ring"] = "Anello",
    ["Orbs"] = "Sfere",
    ["Bar"] = "Barra",
    ["Text"] = "Testo",

    -- Stage labels
    ["COLD"] = "FREDDO",
    ["WARM"] = "TIEPIDO",
    ["HOT"] = "CALDO",
    ["FINAL"] = "FINALE",

    -- State labels
    ["On"] = "Attivo",
    ["Off"] = "Disattivo",
    ["Unavailable"] = "Non disponibile",

    -- Summary / sidebar labels
    ["Current setup"] = "Configurazione attuale",
    ["Preview"] = "Anteprima",
    ["Quick actions"] = "Azioni rapide",
    ["Style"] = "Stile",
    ["Blizzard UI"] = "Interfaccia Blizzard",
    ["Floating"] = "Flottante",
    ["Attached"] = "Agganciato",
    ["Overlay only"] = "Solo sovrapposizione",
    ["Show both"] = "Mostra entrambi",
    ["Number on"] = "Numero attivo",
    ["Number off"] = "Numero disattivo",
    ["Badge on"] = "Emblema attivo",
    ["Badge off"] = "Emblema disattivo",
    ["Watch + waypoint focus"] = "Controllo + punto di via",
    ["Watch list only"] = "Solo lista di controllo",
    ["Waypoint focus only"] = "Solo punto di via",
    ["Orb strip"] = "Striscia di sfere",
    ["Text only"] = "Solo testo",
    ["Reset all"] = "Reimposta tutto",
    ["Refresh now"] = "Aggiorna ora",
    ["DRAG TO MOVE"] = "TRASCINA PER SPOSTARE",
    ["DRAGGING"] = "TRASCINAMENTO",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Impostazioni ripristinate ai valori predefiniti.",
    ["Refreshed prey widget state."] = "Stato del widget preda aggiornato.",
    ["Tracker enabled."] = "Tracciatore attivato.",
    ["Tracker disabled."] = "Tracciatore disattivato.",
    ["Debug tracing enabled."] = "Tracciamento di debug attivato.",
    ["Debug tracing disabled."] = "Tracciamento di debug disattivato.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Tracciatore di caccia compatto ancorato al widget Blizzard.",
    ["Status: disabled"] = "Stato: disattivato",
    ["Status: idle"] = "Stato: inattivo",
    ["Status: %s (%d%%)"] = "Stato: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Clic sinistro: attiva o disattiva il tracciatore",
    ["Shift-left-click: Open settings"] = "Maiusc-clic sinistro: apri impostazioni",
    ["Right-click: Force a tracker refresh"] = "Clic destro: forza aggiornamento del tracciatore",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "Configura il tracciatore preda nel tuo HUD con anteprima dal vivo e sezioni chiare.",
    ["Live state shows up here as soon as a prey hunt starts."] = "Lo stato dal vivo appare qui non appena inizia una caccia.",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "Apri questo pannello con /pb o con Maiusc-clic sull'icona del compartimento.",

    -- Settings panel status
    ["DISABLED"] = "DISATTIVATO",
    ["SAMPLE"] = "ESEMPIO",
    ["ACTIVE"] = "ATTIVO",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker è disattivato. Il tuo layout attuale resta salvato.",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "Caccia preda rilevata. L'anteprima rispecchia lo stato attuale del tracciatore.",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "Nessuna caccia è attiva al momento, l'anteprima mostra uno stato di esempio.",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "L'anteprima resta disponibile con il tracciatore disattivato.",
    ["Floating layout locked. Unlock it to drag the live tracker."] = "Layout flottante bloccato. Sbloccalo per trascinare il tracciatore.",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "Layout flottante pronto. Trascina il tracciatore quando una caccia è attiva.",
    ["Text view without the Blizzard prey icon."] = "Vista testo senza l'icona preda di Blizzard.",
    ["Text view attached to the Blizzard prey icon."] = "Vista testo agganciata all'icona preda di Blizzard.",
    ["Bar view without the Blizzard prey icon."] = "Vista barra senza l'icona preda di Blizzard.",
    ["Bar view anchored below the Blizzard prey icon."] = "Vista barra ancorata sotto l'icona preda di Blizzard.",
    ["Orb view without the Blizzard prey icon."] = "Vista sfera senza l'icona preda di Blizzard.",
    ["Orb view attached to the Blizzard prey icon."] = "Vista sfera agganciata all'icona preda di Blizzard.",
    ["Ring view without the Blizzard prey icon."] = "Vista anello senza l'icona preda di Blizzard.",
    ["Ring sample without the Blizzard prey icon."] = "Esempio anello senza l'icona preda di Blizzard.",
    ["Ring view attached to the Blizzard prey icon."] = "Vista anello agganciata all'icona preda di Blizzard.",
    ["Ring sample attached to the Blizzard prey icon."] = "Esempio anello agganciato all'icona preda di Blizzard.",
}
