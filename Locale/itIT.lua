-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "itIT" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Tracciatore",
    ["Placement"] = "Posizionamento",
    ["Readout"] = "Lettura",
    ["Text style"] = "Stile testo",
    ["Quest help"] = "Aiuto missione",
    ["Audio & feedback"] = "Audio e feedback",
    ["Profile"] = "Profilo",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Scegli lo stile del tracciatore e la dimensione adatta al tuo schermo.",
    ["Keep the tracker attached to the prey icon and nudge it into place."] = "Tieni il tracciatore agganciato all'icona preda e regolalo nella posizione giusta.",
    ["Choose which cues appear around the tracker while you hunt."] = "Scegli quali indicatori appaiono attorno al tracciatore durante la caccia.",
    ["Adjust tracker text styling without adding a hard dependency. LibSharedMedia fonts appear automatically when the library is installed."] = "Regola lo stile del testo del tracciatore senza aggiungere una dipendenza obbligatoria. I font di LibSharedMedia appaiono automaticamente quando la libreria è installata.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Mantieni la missione preda attiva ben visibile durante la caccia.",
    ["Control sound cues that fire when your hunt phase changes."] = "Controlla i segnali sonori emessi al cambio di fase.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Scegli se questo personaggio usa le proprie impostazioni o i valori predefiniti dell'account.",

    -- Field titles
    ["Enable tracker"] = "Attiva tracciatore",
    ["Display style"] = "Stile di visualizzazione",
    ["Display size"] = "Dimensione di visualizzazione",
    ["Hide Blizzard prey icon"] = "Nascondi icona preda di Blizzard",
    ["Horizontal position"] = "Posizione orizzontale",
    ["Vertical position"] = "Posizione verticale",
    ["Show progress number"] = "Mostra numero progresso",
    ["Show stage badge"] = "Mostra emblema di fase",
    ["Font face"] = "Carattere",
    ["Outline"] = "Contorno",
    ["Shadow"] = "Ombra",
    ["Number size"] = "Dimensione numero",
    ["Badge size"] = "Dimensione emblema",
    ["Add prey quest to tracker"] = "Aggiungi missione preda al tracciamento",
    ["Focus the prey quest"] = "Focalizza la missione preda",
    ["Auto turn-in prey quest"] = "Consegna automatica missione preda",
    ["Play sound on phase change"] = "Riproduci suono al cambio di fase",
    ["Sound theme"] = "Tema sonoro",
    ["Death cue during hunt"] = "Segnale di morte durante la caccia",
    ["Use character profile"] = "Usa profilo personaggio",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Attiva o disattiva Preybreaker senza perdere il tuo layout.",
    ["Choose the shape that best fits your UI."] = "Scegli la forma che meglio si adatta alla tua interfaccia.",
    ["Make the current style bigger or smaller."] = "Ingrandisci o rimpicciolisci lo stile attuale.",
    ["Show only Preybreaker while the prey hunt is active."] = "Mostra solo Preybreaker mentre la caccia è attiva.",
    ["Show a simple number inside the tracker."] = "Mostra un numero semplice nel tracciatore.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Mostra FREDDO, TIEPIDO, CALDO o FINALE sotto il tracciatore.",
    ["Stage badges are available in ring and orb styles."] = "Gli emblemi di fase sono disponibili negli stili anello e sfera.",
    ["Choose a Blizzard font by default, or pick a LibSharedMedia font when one is available."] = "Usa un font Blizzard per impostazione predefinita, o scegli un font LibSharedMedia se disponibile.",
    ["Override the text outline used by the tracker readouts."] = "Sovrascrivere il contorno del testo utilizzato dalle letture del tracciatore.",
    ["Override the text shadow used by the tracker readouts."] = "Sovrascrivere l'ombra del testo utilizzata dalle letture del tracciatore.",
    ["Scale the progress number and the text-only readout without changing the tracker frame itself."] = "Ridimensiona il numero di progresso e la lettura solo testo senza modificare il riquadro del tracciatore.",
    ["Scale the stage badge text separately from the main progress number."] = "Ridimensiona il testo dell'emblema di fase separatamente dal numero di progresso principale.",
    ["Automatically place the active prey quest in your watch list."] = "Posiziona automaticamente la missione preda attiva nella tua lista di controllo.",
    ["Keep the active prey quest selected for your objective arrow."] = "Mantieni la missione preda attiva selezionata per la freccia dell'obiettivo.",
    ["Automatically complete the prey quest when it pops up, unless a reward choice is required."] = "Completa automaticamente la missione preda quando appare, a meno che non sia richiesta una scelta di ricompensa.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Ascolta un segnale sonoro quando la caccia passa a una nuova fase.",
    ["Select the active sound pack used for prey hunt audio cues."] = "Seleziona il pacchetto sonoro attivo per i segnali di caccia.",
    ["Play a death cue when you die during an active prey hunt in the hunt zone."] = "Riproduci un segnale di morte quando muori durante una caccia attiva nella zona di caccia.",
    ["Store a separate set of settings for this character."] = "Memorizza un set separato di impostazioni per questo personaggio.",
    ["Nudge the tracker left or right around the prey icon."] = "Sposta il tracciatore a sinistra o destra attorno all'icona preda.",
    ["Nudge the tracker up or down around the prey icon."] = "Sposta il tracciatore in alto o in basso attorno all'icona preda.",

    -- Display mode labels
    ["Ring"] = "Anello",
    ["Orbs"] = "Sfere",
    ["Bar"] = "Barra",
    ["Text"] = "Testo",

    -- Sound theme labels
    ["Among Us"] = "Among Us",
    ["Generic"] = "Generico",
    ["Jurassic Park"] = "Jurassic Park",
    ["Pokemon"] = "Pokemon",
    ["Predator"] = "Predator",
    ["Stranger Things"] = "Stranger Things",
    ["Random"] = "Casuale",

    -- Stage labels
    ["COLD"] = "FREDDO",
    ["WARM"] = "TIEPIDO",
    ["HOT"] = "CALDO",
    ["FINAL"] = "FINALE",

    -- State labels
    ["On"] = "Attivo",
    ["Off"] = "Disattivo",
    ["Unavailable"] = "Non disponibile",
    ["Default"] = "Predefinito",
    ["None"] = "Nessuno",
    ["Thick outline"] = "Contorno spesso",

    -- Summary / sidebar labels
    ["Current setup"] = "Configurazione attuale",
    ["Preview"] = "Anteprima",
    ["Quick actions"] = "Azioni rapide",
    ["Style"] = "Stile",
    ["Blizzard UI"] = "Interfaccia Blizzard",
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

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Impostazioni ripristinate ai valori predefiniti.",
    ["Refreshed prey widget state."] = "Stato del widget preda aggiornato.",
    ["Tracker enabled."] = "Tracciatore attivato.",
    ["Tracker disabled."] = "Tracciatore disattivato.",
    ["Debug tracing enabled."] = "Tracciamento di debug attivato.",
    ["Debug tracing disabled."] = "Tracciamento di debug disattivato.",
    ["Standalone hunt panel shown."] = "Pannello di caccia autonomo mostrato.",
    ["Standalone hunt panel hidden."] = "Pannello di caccia autonomo nascosto.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Tracciatore di caccia compatto ancorato al widget Blizzard.",
    ["Status: disabled"] = "Stato: disattivato",
    ["Status: idle"] = "Stato: inattivo",
    ["Status: %s (%d%%)"] = "Stato: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Clic sinistro: attiva o disattiva il tracciatore",
    ["Shift-left-click: Open settings"] = "Maiusc-clic sinistro: apri impostazioni",
    ["Right-click: Force a tracker refresh"] = "Clic destro: forza aggiornamento del tracciatore",
    ["Shift-right-click: Open hunt panel"] = "Maiusc-clic destro: apri pannello di caccia",

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

    -- Hunt panel settings
    ["Hunt panel"] = "Pannello cacce",
    ["Control the hunt list panel that docks beside the Adventure Map."] = "Controlla il pannello della lista cacce che si aggancia accanto alla Mappa delle avventure.",
    ["Enable hunt panel"] = "Attiva pannello cacce",
    ["Show the hunt list panel when the Adventure Map is open and allow standalone use."] = "Mostra il pannello della lista cacce quando la Mappa delle avventure è aperta e consenti l'uso autonomo.",
    ["Hunt panel disabled."] = "Pannello cacce disattivato.",

    -- Random hunt settings
    ["Random hunt"] = "Caccia casuale",
    ["Automate randomized hunt purchasing from Astalor Bloodsworn."] = "Automatizza l'acquisto di cacce casuali da Astalor Giurasangue.",
    ["Auto-purchase random hunt"] = "Acquisto auto caccia casuale",
    ["Automatically request a randomized hunt from Astalor Bloodsworn when you open his gossip window."] = "Richiedi automaticamente una caccia casuale da Astalor Giurasangue quando apri la sua finestra di dialogo.",
    ["Hunt difficulty"] = "Difficoltà di caccia",
    ["Choose which difficulty to purchase when auto-buying a randomized hunt."] = "Scegli la difficoltà da acquistare durante l'acquisto automatico di una caccia casuale.",
    ["Normal"] = "Normale",
    ["Hard"] = "Difficile",
    ["Nightmare"] = "Incubo",
    ["Remnant reserve"] = "Riserva di vestigia",
    ["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."] = "Acquista una caccia solo quando hai almeno questa quantità di Vestigia d'Angoscia più il costo di 50.",

    -- Hunt rewards settings
    ["Hunt rewards"] = "Ricompense di caccia",
    ["Automatically choose rewards when completing a prey hunt."] = "Scegli automaticamente le ricompense al completamento di una caccia alla preda.",
    ["Auto-select hunt reward"] = "Selezione auto ricompensa",
    ["Automatically pick a reward when a completed hunt offers multiple choices."] = "Scegli automaticamente una ricompensa quando una caccia completata offre più opzioni.",
    ["Preferred reward"] = "Ricompensa preferita",
    ["The reward type to pick first when completing a hunt."] = "Il tipo di ricompensa da scegliere per primo al completamento di una caccia.",
    ["Fallback reward"] = "Ricompensa alternativa",
    ["The reward to pick if your preferred choice is unavailable or its currency is capped."] = "La ricompensa da scegliere se l'opzione preferita non è disponibile o la sua valuta è al massimo.",
    ["Gear upgrade currency"] = "Valuta potenziamento equipaggiamento",
    ["Remnant of Anguish"] = "Vestigia d'Angoscia",
    ["Gold"] = "Oro",
    ["Voidlight Marl"] = "Marna di luce del Vuoto",

    -- Tab labels
    ["Settings"] = "Impostazioni",
    ["Changelog"] = "Registro modifiche",
    ["Social"] = "Social",
    ["Roadmap"] = "Roadmap",
    ["Select"] = "Seleziona",
    ["Select URL text and copy it."] = "Seleziona il testo dell'URL e copialo.",
    ["Known issues"] = "Problemi noti",
    ["Planned features"] = "Funzionalità previste",
    ["Items tracked for upcoming releases."] = "Elementi tracciati per le prossime versioni.",
    ["No known issues currently listed."] = "Nessun problema noto attualmente elencato.",
    ["No planned features currently listed."] = "Nessuna funzionalità prevista attualmente elencata.",
}
