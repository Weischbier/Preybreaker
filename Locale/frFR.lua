-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "frFR" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Traqueur",
    ["Placement"] = "Placement",
    ["Readout"] = "Affichage",
    ["Quest help"] = "Aide aux quêtes",
    ["Audio & feedback"] = "Audio et retour",
    ["Drag & grid"] = "Glisser et grille",
    ["Profile"] = "Profil",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Choisissez le style du traqueur et la taille qui convient le mieux à votre écran.",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "Gardez le traqueur sur l'icône de proie ou passez à une disposition flottante déplaçable.",
    ["Choose which cues appear around the tracker while you hunt."] = "Choisissez les indicateurs qui apparaissent autour du traqueur pendant la chasse.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Gardez la quête de proie active bien visible pendant la chasse.",
    ["Control sound cues that fire when your hunt phase changes."] = "Contrôlez les signaux sonores émis lors du changement de phase de chasse.",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "Ajustez le comportement du traqueur flottant lors du repositionnement.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Choisissez si ce personnage utilise ses propres paramètres ou les valeurs par défaut du compte.",

    -- Field titles
    ["Enable tracker"] = "Activer le traqueur",
    ["Display style"] = "Style d'affichage",
    ["Display size"] = "Taille d'affichage",
    ["Detach from prey icon"] = "Détacher de l'icône de proie",
    ["Lock floating position"] = "Verrouiller la position flottante",
    ["Reset floating position"] = "Réinitialiser la position flottante",
    ["Hide Blizzard prey icon"] = "Masquer l'icône de proie Blizzard",
    ["Horizontal position"] = "Position horizontale",
    ["Vertical position"] = "Position verticale",
    ["Show progress number"] = "Afficher le nombre de progression",
    ["Show stage badge"] = "Afficher le badge d'étape",
    ["Add prey quest to tracker"] = "Ajouter la quête de proie au suivi",
    ["Focus the prey quest"] = "Cibler la quête de proie",
    ["Play sound on phase change"] = "Jouer un son au changement de phase",
    ["Snap to grid"] = "Aligner sur la grille",
    ["Grid size"] = "Taille de la grille",
    ["Use character profile"] = "Utiliser le profil du personnage",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Activez ou désactivez Preybreaker sans perdre votre disposition.",
    ["Choose the shape that best fits your UI."] = "Choisissez la forme qui s'adapte le mieux à votre interface.",
    ["Make the current style bigger or smaller."] = "Agrandissez ou réduisez le style actuel.",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "Transformez le traqueur en élément flottant que vous pouvez placer n'importe où.",
    ["Keep the floating tracker fixed once it is where you want it."] = "Fixez le traqueur flottant une fois qu'il est à l'endroit souhaité.",
    ["Available after you switch the tracker to the floating layout."] = "Disponible après le passage à la disposition flottante.",
    ["Bring the floating tracker back to the center of your screen."] = "Ramenez le traqueur flottant au centre de votre écran.",
    ["Show only Preybreaker while the prey hunt is active."] = "N'afficher que Preybreaker pendant la chasse à la proie.",
    ["Show a simple number inside the tracker."] = "Afficher un nombre simple dans le traqueur.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Afficher FROID, TIÈDE, CHAUD ou FINAL sous le traqueur.",
    ["Stage badges are available in ring and orb styles."] = "Les badges d'étape sont disponibles en styles anneau et orbe.",
    ["Automatically place the active prey quest in your watch list."] = "Placer automatiquement la quête de proie active dans votre liste de suivi.",
    ["Keep the active prey quest selected for your objective arrow."] = "Garder la quête de proie active sélectionnée pour votre flèche d'objectif.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Entendre un signal sonore quand la chasse passe à une nouvelle étape.",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "Aligner le traqueur flottant sur une grille de pixels invisible lors du dépôt.",
    ["Spacing of the snap grid in pixels."] = "Espacement de la grille d'alignement en pixels.",
    ["Store a separate set of settings for this character."] = "Enregistrer un jeu de paramètres séparé pour ce personnage.",
    ["Reset position"] = "Réinitialiser la position",
    ["Nudge the tracker left or right around the prey icon."] = "Décaler le traqueur à gauche ou à droite autour de l'icône de proie.",
    ["Move the floating tracker left or right on the screen."] = "Déplacer le traqueur flottant à gauche ou à droite sur l'écran.",
    ["Nudge the tracker up or down around the prey icon."] = "Décaler le traqueur vers le haut ou le bas autour de l'icône de proie.",
    ["Move the floating tracker up or down on the screen."] = "Déplacer le traqueur flottant vers le haut ou le bas sur l'écran.",

    -- Display mode labels
    ["Ring"] = "Anneau",
    ["Orbs"] = "Orbes",
    ["Bar"] = "Barre",
    ["Text"] = "Texte",

    -- Stage labels
    ["COLD"] = "FROID",
    ["WARM"] = "TIÈDE",
    ["HOT"] = "CHAUD",
    ["FINAL"] = "FINAL",

    -- State labels
    ["On"] = "Activé",
    ["Off"] = "Désactivé",
    ["Unavailable"] = "Indisponible",

    -- Summary / sidebar labels
    ["Current setup"] = "Configuration actuelle",
    ["Preview"] = "Aperçu",
    ["Quick actions"] = "Actions rapides",
    ["Style"] = "Style",
    ["Blizzard UI"] = "Interface Blizzard",
    ["Floating"] = "Flottant",
    ["Attached"] = "Attaché",
    ["Overlay only"] = "Superposition seule",
    ["Show both"] = "Afficher les deux",
    ["Number on"] = "Nombre activé",
    ["Number off"] = "Nombre désactivé",
    ["Badge on"] = "Badge activé",
    ["Badge off"] = "Badge désactivé",
    ["Watch + waypoint focus"] = "Suivi + point de passage",
    ["Watch list only"] = "Liste de suivi seule",
    ["Waypoint focus only"] = "Point de passage seul",
    ["Orb strip"] = "Bande d'orbes",
    ["Text only"] = "Texte seul",
    ["Reset all"] = "Tout réinitialiser",
    ["Refresh now"] = "Actualiser maintenant",
    ["DRAG TO MOVE"] = "GLISSER POUR DÉPLACER",
    ["DRAGGING"] = "DÉPLACEMENT",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Paramètres réinitialisés aux valeurs par défaut.",
    ["Refreshed prey widget state."] = "État du widget de proie actualisé.",
    ["Tracker enabled."] = "Traqueur activé.",
    ["Tracker disabled."] = "Traqueur désactivé.",
    ["Debug tracing enabled."] = "Traçage de débogage activé.",
    ["Debug tracing disabled."] = "Traçage de débogage désactivé.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Traqueur de chasse compact ancré au widget Blizzard.",
    ["Status: disabled"] = "Statut : désactivé",
    ["Status: idle"] = "Statut : en attente",
    ["Status: %s (%d%%)"] = "Statut : %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Clic gauche : activer ou désactiver le traqueur",
    ["Shift-left-click: Open settings"] = "Maj-clic gauche : ouvrir les paramètres",
    ["Right-click: Force a tracker refresh"] = "Clic droit : forcer une actualisation du traqueur",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "Configurez le traqueur de proie autour de votre ATH avec un aperçu en direct et des sections claires.",
    ["Live state shows up here as soon as a prey hunt starts."] = "L'état en direct apparaît ici dès qu'une chasse commence.",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "Ouvrez ce panneau avec /pb ou en Maj-cliquant sur l'icône du compartiment.",

    -- Settings panel status
    ["DISABLED"] = "DÉSACTIVÉ",
    ["SAMPLE"] = "EXEMPLE",
    ["ACTIVE"] = "ACTIF",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker est désactivé. Votre disposition actuelle reste sauvegardée.",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "Chasse à la proie détectée. L'aperçu reflète l'état actuel du traqueur.",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "Aucune chasse n'est active actuellement, l'aperçu montre un état d'exemple.",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "L'aperçu reste disponible lorsque le traqueur est désactivé.",
    ["Floating layout locked. Unlock it to drag the live tracker."] = "Disposition flottante verrouillée. Déverrouillez pour déplacer le traqueur.",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "Disposition flottante prête. Glissez le traqueur quand une chasse est active.",
    ["Text view without the Blizzard prey icon."] = "Vue texte sans l'icône de proie Blizzard.",
    ["Text view attached to the Blizzard prey icon."] = "Vue texte attachée à l'icône de proie Blizzard.",
    ["Bar view without the Blizzard prey icon."] = "Vue barre sans l'icône de proie Blizzard.",
    ["Bar view anchored below the Blizzard prey icon."] = "Vue barre ancrée sous l'icône de proie Blizzard.",
    ["Orb view without the Blizzard prey icon."] = "Vue orbe sans l'icône de proie Blizzard.",
    ["Orb view attached to the Blizzard prey icon."] = "Vue orbe attachée à l'icône de proie Blizzard.",
    ["Ring view without the Blizzard prey icon."] = "Vue anneau sans l'icône de proie Blizzard.",
    ["Ring sample without the Blizzard prey icon."] = "Exemple anneau sans l'icône de proie Blizzard.",
    ["Ring view attached to the Blizzard prey icon."] = "Vue anneau attachée à l'icône de proie Blizzard.",
    ["Ring sample attached to the Blizzard prey icon."] = "Exemple anneau attaché à l'icône de proie Blizzard.",
}
