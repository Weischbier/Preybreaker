-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "esMX" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Rastreador",
    ["Placement"] = "Ubicación",
    ["Readout"] = "Indicador",
    ["Quest help"] = "Ayuda de misión",
    ["Audio & feedback"] = "Audio y respuesta",
    ["Drag & grid"] = "Arrastrar y cuadrícula",
    ["Profile"] = "Perfil",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Elige el estilo del rastreador y el tamaño que mejor se adapte a tu pantalla.",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "Mantén el rastreador en el ícono de presa o cámbialo a un diseño flotante.",
    ["Choose which cues appear around the tracker while you hunt."] = "Elige qué indicadores aparecen alrededor del rastreador durante la cacería.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Mantén la misión de presa activa bien visible durante la cacería.",
    ["Control sound cues that fire when your hunt phase changes."] = "Controla las señales de sonido que se emiten al cambiar de fase.",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "Ajusta el comportamiento del rastreador flotante al reposicionarlo.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Elige si este personaje usa sus propios ajustes o los predeterminados de la cuenta.",

    -- Field titles
    ["Enable tracker"] = "Activar rastreador",
    ["Display style"] = "Estilo de visualización",
    ["Display size"] = "Tamaño de visualización",
    ["Detach from prey icon"] = "Separar del ícono de presa",
    ["Lock floating position"] = "Bloquear posición flotante",
    ["Reset floating position"] = "Restablecer posición flotante",
    ["Hide Blizzard prey icon"] = "Ocultar ícono de presa de Blizzard",
    ["Horizontal position"] = "Posición horizontal",
    ["Vertical position"] = "Posición vertical",
    ["Show progress number"] = "Mostrar número de progreso",
    ["Show stage badge"] = "Mostrar emblema de fase",
    ["Add prey quest to tracker"] = "Agregar misión de presa al seguimiento",
    ["Focus the prey quest"] = "Enfocar la misión de presa",
    ["Play sound on phase change"] = "Reproducir sonido al cambiar de fase",
    ["Snap to grid"] = "Ajustar a la cuadrícula",
    ["Grid size"] = "Tamaño de cuadrícula",
    ["Use character profile"] = "Usar perfil de personaje",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Activa o desactiva Preybreaker sin perder tu diseño.",
    ["Choose the shape that best fits your UI."] = "Elige la forma que mejor se adapte a tu interfaz.",
    ["Make the current style bigger or smaller."] = "Haz el estilo actual más grande o más pequeño.",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "Convierte el rastreador en un elemento flotante que puedes colocar donde quieras.",
    ["Keep the floating tracker fixed once it is where you want it."] = "Fija el rastreador flotante una vez que esté donde lo quieras.",
    ["Available after you switch the tracker to the floating layout."] = "Disponible después de cambiar al diseño flotante.",
    ["Bring the floating tracker back to the center of your screen."] = "Regresa el rastreador flotante al centro de la pantalla.",
    ["Show only Preybreaker while the prey hunt is active."] = "Mostrar solo Preybreaker mientras la cacería esté activa.",
    ["Show a simple number inside the tracker."] = "Mostrar un número simple dentro del rastreador.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Mostrar FRÍO, TIBIO, CALIENTE o FINAL debajo del rastreador.",
    ["Stage badges are available in ring and orb styles."] = "Los emblemas de fase están disponibles en estilos anillo y orbe.",
    ["Automatically place the active prey quest in your watch list."] = "Colocar automáticamente la misión de presa activa en tu lista de seguimiento.",
    ["Keep the active prey quest selected for your objective arrow."] = "Mantener la misión de presa activa seleccionada para tu flecha de objetivo.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Escuchar una señal sonora cuando la cacería pase a una nueva fase.",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "Alinear el rastreador flotante a una cuadrícula de píxeles invisible al soltarlo.",
    ["Spacing of the snap grid in pixels."] = "Espaciado de la cuadrícula de ajuste en píxeles.",
    ["Store a separate set of settings for this character."] = "Guardar un conjunto separado de ajustes para este personaje.",
    ["Reset position"] = "Restablecer posición",
    ["Nudge the tracker left or right around the prey icon."] = "Desplazar el rastreador a izquierda o derecha alrededor del ícono de presa.",
    ["Move the floating tracker left or right on the screen."] = "Mover el rastreador flotante a izquierda o derecha en la pantalla.",
    ["Nudge the tracker up or down around the prey icon."] = "Desplazar el rastreador arriba o abajo alrededor del ícono de presa.",
    ["Move the floating tracker up or down on the screen."] = "Mover el rastreador flotante arriba o abajo en la pantalla.",

    -- Display mode labels
    ["Ring"] = "Anillo",
    ["Orbs"] = "Orbes",
    ["Bar"] = "Barra",
    ["Text"] = "Texto",

    -- Stage labels
    ["COLD"] = "FRÍO",
    ["WARM"] = "TIBIO",
    ["HOT"] = "CALIENTE",
    ["FINAL"] = "FINAL",

    -- State labels
    ["On"] = "Activado",
    ["Off"] = "Desactivado",
    ["Unavailable"] = "No disponible",

    -- Summary / sidebar labels
    ["Current setup"] = "Configuración actual",
    ["Preview"] = "Vista previa",
    ["Quick actions"] = "Acciones rápidas",
    ["Style"] = "Estilo",
    ["Blizzard UI"] = "Interfaz de Blizzard",
    ["Floating"] = "Flotante",
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
    ["DRAG TO MOVE"] = "ARRASTRA PARA MOVER",
    ["DRAGGING"] = "ARRASTRANDO",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Ajustes restablecidos a los valores predeterminados.",
    ["Refreshed prey widget state."] = "Estado del widget de presa actualizado.",
    ["Tracker enabled."] = "Rastreador activado.",
    ["Tracker disabled."] = "Rastreador desactivado.",
    ["Debug tracing enabled."] = "Rastreo de depuración activado.",
    ["Debug tracing disabled."] = "Rastreo de depuración desactivado.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Rastreador compacto de cacería anclado al widget de Blizzard.",
    ["Status: disabled"] = "Estado: desactivado",
    ["Status: idle"] = "Estado: inactivo",
    ["Status: %s (%d%%)"] = "Estado: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Clic izquierdo: activar o desactivar el rastreador",
    ["Shift-left-click: Open settings"] = "Mayús-clic izquierdo: abrir ajustes",
    ["Right-click: Force a tracker refresh"] = "Clic derecho: forzar actualización del rastreador",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "Configura el rastreador de presa en tu HUD con vista previa en vivo y secciones claras.",
    ["Live state shows up here as soon as a prey hunt starts."] = "El estado en vivo aparece aquí en cuanto comienza una cacería.",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "Abre este panel con /pb o haciendo Mayús-clic en el ícono del compartimento.",

    -- Settings panel status
    ["DISABLED"] = "DESACTIVADO",
    ["SAMPLE"] = "EJEMPLO",
    ["ACTIVE"] = "ACTIVO",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker está desactivado. Tu diseño actual permanece guardado.",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "Cacería de presa detectada. La vista previa refleja el estado actual del rastreador.",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "No hay cacería activa ahorita, así que la vista previa muestra un estado de ejemplo.",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "La vista previa sigue disponible con el rastreador desactivado.",
    ["Floating layout locked. Unlock it to drag the live tracker."] = "Diseño flotante bloqueado. Desbloquea para arrastrar el rastreador.",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "Diseño flotante listo. Arrastra el rastreador cuando una cacería esté activa.",
    ["Text view without the Blizzard prey icon."] = "Vista de texto sin el ícono de presa de Blizzard.",
    ["Text view attached to the Blizzard prey icon."] = "Vista de texto adjunta al ícono de presa de Blizzard.",
    ["Bar view without the Blizzard prey icon."] = "Vista de barra sin el ícono de presa de Blizzard.",
    ["Bar view anchored below the Blizzard prey icon."] = "Vista de barra anclada debajo del ícono de presa de Blizzard.",
    ["Orb view without the Blizzard prey icon."] = "Vista de orbe sin el ícono de presa de Blizzard.",
    ["Orb view attached to the Blizzard prey icon."] = "Vista de orbe adjunta al ícono de presa de Blizzard.",
    ["Ring view without the Blizzard prey icon."] = "Vista de anillo sin el ícono de presa de Blizzard.",
    ["Ring sample without the Blizzard prey icon."] = "Ejemplo de anillo sin el ícono de presa de Blizzard.",
    ["Ring view attached to the Blizzard prey icon."] = "Vista de anillo adjunta al ícono de presa de Blizzard.",
    ["Ring sample attached to the Blizzard prey icon."] = "Ejemplo de anillo adjunto al ícono de presa de Blizzard.",

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
    ["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."] = "Comprar una cacería solo cuando tengas al menos esta cantidad de Vestigios de Angustia más el costo de 50.",

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
}
