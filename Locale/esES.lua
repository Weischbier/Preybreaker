-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "esES" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Rastreador",
    ["Placement"] = "Ubicación",
    ["Readout"] = "Indicador",
    ["Text style"] = "Estilo de texto",
    ["Quest help"] = "Ayuda de misión",
    ["Audio & feedback"] = "Audio y respuesta",
    ["Profile"] = "Perfil",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Elige el estilo del rastreador y el tamaño que mejor se adapte a tu pantalla.",
    ["Keep the tracker attached to the prey icon and nudge it into place."] = "Mantén el rastreador unido al icono de presa y ajústalo en su posición.",
    ["Choose which cues appear around the tracker while you hunt."] = "Elige qué indicadores aparecen alrededor del rastreador durante la cacería.",
    ["Adjust tracker text styling without adding a hard dependency. LibSharedMedia fonts appear automatically when the library is installed."] = "Ajusta el estilo del texto del rastreador sin añadir una dependencia obligatoria. Las fuentes de LibSharedMedia aparecen automáticamente cuando la biblioteca está instalada.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Mantén la misión de presa activa bien visible durante la cacería.",
    ["Control sound cues that fire when your hunt phase changes."] = "Controla las señales de sonido que se emiten al cambiar de fase.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Elige si este personaje usa sus propios ajustes o los predeterminados de la cuenta.",

    -- Field titles
    ["Enable tracker"] = "Activar rastreador",
    ["Display style"] = "Estilo de visualización",
    ["Display size"] = "Tamaño de visualización",
    ["Hide Blizzard prey icon"] = "Ocultar icono de presa de Blizzard",
    ["Horizontal position"] = "Posición horizontal",
    ["Vertical position"] = "Posición vertical",
    ["Show progress number"] = "Mostrar número de progreso",
    ["Show stage badge"] = "Mostrar emblema de fase",
    ["Font face"] = "Tipo de fuente",
    ["Outline"] = "Contorno",
    ["Shadow"] = "Sombra",
    ["Number size"] = "Tamaño de número",
    ["Badge size"] = "Tamaño de emblema",
    ["Add prey quest to tracker"] = "Añadir misión de presa al seguimiento",
    ["Focus the prey quest"] = "Enfocar la misión de presa",
    ["Auto turn-in prey quest"] = "Entregar misión de presa automáticamente",
    ["Play sound on phase change"] = "Reproducir sonido al cambiar de fase",
    ["Sound theme"] = "Tema de sonido",
    ["Death cue during hunt"] = "Señal de muerte durante la cacería",
    ["Use character profile"] = "Usar perfil de personaje",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Activa o desactiva Preybreaker sin perder tu disposición.",
    ["Choose the shape that best fits your UI."] = "Elige la forma que mejor se adapte a tu interfaz.",
    ["Make the current style bigger or smaller."] = "Haz el estilo actual más grande o más pequeño.",
    ["Show only Preybreaker while the prey hunt is active."] = "Mostrar solo Preybreaker mientras la cacería esté activa.",
    ["Show a simple number inside the tracker."] = "Mostrar un número simple dentro del rastreador.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Mostrar FRÍO, TEMPLADO, CALIENTE o FINAL bajo el rastreador.",
    ["Stage badges are available in ring and orb styles."] = "Los emblemas de fase están disponibles en estilos anillo y orbe.",
    ["Choose a Blizzard font by default, or pick a LibSharedMedia font when one is available."] = "Usar una fuente de Blizzard por defecto, o elegir una fuente de LibSharedMedia cuando esté disponible.",
    ["Override the text outline used by the tracker readouts."] = "Anular el contorno de texto utilizado por los indicadores del rastreador.",
    ["Override the text shadow used by the tracker readouts."] = "Anular la sombra de texto utilizada por los indicadores del rastreador.",
    ["Scale the progress number and the text-only readout without changing the tracker frame itself."] = "Escalar el número de progreso y el indicador de solo texto sin cambiar el marco del rastreador.",
    ["Scale the stage badge text separately from the main progress number."] = "Escalar el texto del emblema de fase por separado del número de progreso principal.",
    ["Automatically place the active prey quest in your watch list."] = "Colocar automáticamente la misión de presa activa en tu lista de seguimiento.",
    ["Keep the active prey quest selected for your objective arrow."] = "Mantener la misión de presa activa seleccionada para tu flecha de objetivo.",
    ["Automatically complete the prey quest when it pops up, unless a reward choice is required."] = "Completar automáticamente la misión de presa cuando aparezca, salvo que se requiera elegir recompensa.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Escuchar una señal sonora cuando la cacería pase a una nueva fase.",
    ["Select the active sound pack used for prey hunt audio cues."] = "Seleccionar el paquete de sonido activo para las señales de cacería.",
    ["Play a death cue when you die during an active prey hunt in the hunt zone."] = "Reproducir una señal de muerte al morir durante una cacería activa en la zona de caza.",
    ["Store a separate set of settings for this character."] = "Guardar un conjunto separado de ajustes para este personaje.",
    ["Nudge the tracker left or right around the prey icon."] = "Desplazar el rastreador a izquierda o derecha alrededor del icono de presa.",
    ["Nudge the tracker up or down around the prey icon."] = "Desplazar el rastreador arriba o abajo alrededor del icono de presa.",

    -- Display mode labels
    ["Ring"] = "Anillo",
    ["Orbs"] = "Orbes",
    ["Bar"] = "Barra",
    ["Text"] = "Texto",

    -- Sound theme labels
    ["Among Us"] = "Among Us",
    ["Generic"] = "Genérico",
    ["Jurassic Park"] = "Jurassic Park",
    ["Pokemon"] = "Pokemon",
    ["Predator"] = "Predator",
    ["Stranger Things"] = "Stranger Things",
    ["Random"] = "Aleatorio",

    -- Stage labels
    ["COLD"] = "FRÍO",
    ["WARM"] = "TEMPLADO",
    ["HOT"] = "CALIENTE",
    ["FINAL"] = "FINAL",

    -- State labels
    ["On"] = "Activado",
    ["Off"] = "Desactivado",
    ["Unavailable"] = "No disponible",
    ["Default"] = "Predeterminado",
    ["None"] = "Ninguno",
    ["Thick outline"] = "Contorno grueso",

    -- Summary / sidebar labels
    ["Current setup"] = "Configuración actual",
    ["Preview"] = "Vista previa",
    ["Quick actions"] = "Acciones rápidas",
    ["Style"] = "Estilo",
    ["Blizzard UI"] = "Interfaz de Blizzard",
    ["Attached"] = "Adjunto",
    ["Overlay only"] = "Solo superposición",
    ["Show both"] = "Mostrar ambos",
    ["Number on"] = "Número activado",
    ["Number off"] = "Número desactivado",
    ["Badge on"] = "Emblema activado",
    ["Badge off"] = "Emblema desactivado",
    ["Watch + waypoint focus"] = "Seguimiento + punto de ruta",
    ["Watch list only"] = "Solo lista de seguimiento",
    ["Waypoint focus only"] = "Solo punto de ruta",
    ["Orb strip"] = "Tira de orbes",
    ["Text only"] = "Solo texto",
    ["Reset all"] = "Restablecer todo",
    ["Refresh now"] = "Actualizar ahora",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Ajustes restablecidos a los valores predeterminados.",
    ["Refreshed prey widget state."] = "Estado del widget de presa actualizado.",
    ["Tracker enabled."] = "Rastreador activado.",
    ["Tracker disabled."] = "Rastreador desactivado.",
    ["Debug tracing enabled."] = "Rastreo de depuración activado.",
    ["Debug tracing disabled."] = "Rastreo de depuración desactivado.",
    ["Standalone hunt panel shown."] = "Panel de cacería independiente mostrado.",
    ["Standalone hunt panel hidden."] = "Panel de cacería independiente oculto.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Rastreador compacto de cacería anclado al widget de Blizzard.",
    ["Status: disabled"] = "Estado: desactivado",
    ["Status: idle"] = "Estado: inactivo",
    ["Status: %s (%d%%)"] = "Estado: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Clic izquierdo: activar o desactivar el rastreador",
    ["Shift-left-click: Open settings"] = "Mayús-clic izquierdo: abrir ajustes",
    ["Right-click: Force a tracker refresh"] = "Clic derecho: forzar actualización del rastreador",
    ["Shift-right-click: Open hunt panel"] = "Mayús-clic derecho: abrir panel de cacería",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "Configura el rastreador de presa en tu HUD con vista previa en vivo y secciones claras.",
    ["Live state shows up here as soon as a prey hunt starts."] = "El estado en vivo aparece aquí en cuanto comienza una cacería.",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "Abre este panel con /pb o haciendo Mayús-clic en el icono del compartimento.",

    -- Settings panel status
    ["DISABLED"] = "DESACTIVADO",
    ["SAMPLE"] = "EJEMPLO",
    ["ACTIVE"] = "ACTIVO",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker está desactivado. Tu disposición actual permanece guardada.",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "Cacería de presa detectada. La vista previa refleja el estado actual del rastreador.",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "No hay cacería activa ahora mismo, así que la vista previa muestra un estado de ejemplo.",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "La vista previa sigue disponible con el rastreador desactivado.",
    ["Text view without the Blizzard prey icon."] = "Vista de texto sin el icono de presa de Blizzard.",
    ["Text view attached to the Blizzard prey icon."] = "Vista de texto adjunta al icono de presa de Blizzard.",
    ["Bar view without the Blizzard prey icon."] = "Vista de barra sin el icono de presa de Blizzard.",
    ["Bar view anchored below the Blizzard prey icon."] = "Vista de barra anclada bajo el icono de presa de Blizzard.",
    ["Orb view without the Blizzard prey icon."] = "Vista de orbe sin el icono de presa de Blizzard.",
    ["Orb view attached to the Blizzard prey icon."] = "Vista de orbe adjunta al icono de presa de Blizzard.",
    ["Ring view without the Blizzard prey icon."] = "Vista de anillo sin el icono de presa de Blizzard.",
    ["Ring sample without the Blizzard prey icon."] = "Ejemplo de anillo sin el icono de presa de Blizzard.",
    ["Ring view attached to the Blizzard prey icon."] = "Vista de anillo adjunta al icono de presa de Blizzard.",
    ["Ring sample attached to the Blizzard prey icon."] = "Ejemplo de anillo adjunto al icono de presa de Blizzard.",

    -- Hunt panel settings
    ["Hunt panel"] = "Panel de cacerías",
    ["Control the hunt list panel that docks beside the Adventure Map."] = "Controla el panel de lista de cacerías que se acopla junto al Mapa de Aventuras.",
    ["Enable hunt panel"] = "Activar panel de cacerías",
    ["Show the hunt list panel when the Adventure Map is open and allow standalone use."] = "Muestra el panel de lista de cacerías cuando el Mapa de Aventuras está abierto y permite su uso independiente.",
    ["Hunt panel disabled."] = "Panel de cacerías desactivado.",

    -- Random hunt settings
    ["Random hunt"] = "Cacería aleatoria",
    ["Automate randomized hunt purchasing from Astalor Bloodsworn."] = "Automatizar la compra de cacerías aleatorias de Astalor Juradesangre.",
    ["Auto-purchase random hunt"] = "Compra automática de cacería aleatoria",
    ["Automatically request a randomized hunt from Astalor Bloodsworn when you open his gossip window."] = "Solicitar automáticamente una cacería aleatoria a Astalor Juradesangre al abrir su ventana de diálogo.",
    ["Hunt difficulty"] = "Dificultad de cacería",
    ["Choose which difficulty to purchase when auto-buying a randomized hunt."] = "Elige la dificultad al comprar automáticamente una cacería aleatoria.",
    ["Normal"] = "Normal",
    ["Hard"] = "Difícil",
    ["Nightmare"] = "Pesadilla",
    ["Remnant reserve"] = "Reserva de vestigios",
    ["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."] = "Comprar una cacería solo cuando tengas al menos esta cantidad de Vestigios de Angustia más el coste de 50.",

    -- Hunt rewards settings
    ["Hunt rewards"] = "Recompensas de cacería",
    ["Automatically choose rewards when completing a prey hunt."] = "Elegir recompensas automáticamente al completar una cacería de presa.",
    ["Auto-select hunt reward"] = "Selección automática de recompensa",
    ["Automatically pick a reward when a completed hunt offers multiple choices."] = "Elegir automáticamente una recompensa cuando la cacería completada ofrezca varias opciones.",
    ["Preferred reward"] = "Recompensa preferida",
    ["The reward type to pick first when completing a hunt."] = "El tipo de recompensa a elegir primero al completar una cacería.",
    ["Fallback reward"] = "Recompensa alternativa",
    ["The reward to pick if your preferred choice is unavailable or its currency is capped."] = "La recompensa a elegir si tu opción preferida no está disponible o su moneda está al máximo.",
    ["Gear upgrade currency"] = "Moneda de mejora de equipo",
    ["Remnant of Anguish"] = "Vestigio de Angustia",
    ["Gold"] = "Oro",
    ["Voidlight Marl"] = "Marga de luz del vacío",

    -- Tab labels
    ["Settings"] = "Ajustes",
    ["Changelog"] = "Registro de cambios",
    ["Social"] = "Social",
    ["Roadmap"] = "Hoja de ruta",
    ["Select"] = "Seleccionar",
    ["Select URL text and copy it."] = "Selecciona el texto de la URL y cópialo.",
    ["Known issues"] = "Problemas conocidos",
    ["Planned features"] = "Funciones previstas",
    ["Items tracked for upcoming releases."] = "Elementos rastreados para próximas versiones.",
    ["No known issues currently listed."] = "No hay problemas conocidos actualmente.",
    ["No planned features currently listed."] = "No hay funciones previstas actualmente.",
}
