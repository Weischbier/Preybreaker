-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "ruRU" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Трекер",
    ["Placement"] = "Розташування",
    ["Readout"] = "Показник",
    ["Quest help"] = "Допомога завдань",
    ["Audio & feedback"] = "Аудіо та зворотний зв'язок",
    ["Drag & grid"] = "Перетягування та сітка",
    ["Profile"] = "Профіль",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Оберіть стиль трекера та розмір, що найкраще пасує вашому екрану.",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "Тримайте трекер на іконці здобичі або перемкніть на плаваюче розміщення.",
    ["Choose which cues appear around the tracker while you hunt."] = "Оберіть, які підказки з'являються навколо трекера під час полювання.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Тримайте активне завдання здобичі на видному місці під час полювання.",
    ["Control sound cues that fire when your hunt phase changes."] = "Керуйте звуковими сигналами, що лунають при зміні фази полювання.",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "Налаштуйте поведінку плаваючого трекера під час переміщення.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Оберіть, чи цей персонаж використовує власні налаштування, чи загальні для облікового запису.",

    -- Field titles
    ["Enable tracker"] = "Увімкнути трекер",
    ["Display style"] = "Стиль відображення",
    ["Display size"] = "Розмір відображення",
    ["Detach from prey icon"] = "Від'єднати від іконки здобичі",
    ["Lock floating position"] = "Зафіксувати плаваючу позицію",
    ["Reset floating position"] = "Скинути плаваючу позицію",
    ["Hide Blizzard prey icon"] = "Сховати іконку здобичі Blizzard",
    ["Horizontal position"] = "Горизонтальна позиція",
    ["Vertical position"] = "Вертикальна позиція",
    ["Show progress number"] = "Показати число прогресу",
    ["Show stage badge"] = "Показати значок фази",
    ["Add prey quest to tracker"] = "Додати завдання здобичі до відстеження",
    ["Focus the prey quest"] = "Сфокусувати завдання здобичі",
    ["Play sound on phase change"] = "Відтворити звук при зміні фази",
    ["Snap to grid"] = "Прив'язати до сітки",
    ["Grid size"] = "Розмір сітки",
    ["Use character profile"] = "Використовувати профіль персонажа",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Увімкніть або вимкніть Preybreaker, не втрачаючи розташування.",
    ["Choose the shape that best fits your UI."] = "Оберіть форму, яка найкраще пасує вашому інтерфейсу.",
    ["Make the current style bigger or smaller."] = "Збільшіть або зменшіть поточний стиль.",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "Перетворіть трекер на вільний плаваючий елемент, який можна розмістити будь-де.",
    ["Keep the floating tracker fixed once it is where you want it."] = "Зафіксуйте плаваючий трекер, коли він у потрібному місці.",
    ["Available after you switch the tracker to the floating layout."] = "Доступно після переходу до плаваючого розміщення.",
    ["Bring the floating tracker back to the center of your screen."] = "Поверніть плаваючий трекер до центру екрана.",
    ["Show only Preybreaker while the prey hunt is active."] = "Показувати лише Preybreaker, поки полювання активне.",
    ["Show a simple number inside the tracker."] = "Показувати просте число всередині трекера.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Показувати ХОЛОДНО, ТЕПЛО, ГАРЯЧЕ або ФІНАЛ під трекером.",
    ["Stage badges are available in ring and orb styles."] = "Значки фаз доступні у стилях кільце та сфера.",
    ["Automatically place the active prey quest in your watch list."] = "Автоматично додати активне завдання здобичі до списку спостереження.",
    ["Keep the active prey quest selected for your objective arrow."] = "Тримати активне завдання здобичі обраним для стрілки цілі.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Почути звуковий сигнал, коли полювання переходить до нової фази.",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "Вирівняти плаваючий трекер по невидимій піксельній сітці при відпусканні.",
    ["Spacing of the snap grid in pixels."] = "Крок сітки прив'язки у пікселях.",
    ["Store a separate set of settings for this character."] = "Зберегти окремий набір налаштувань для цього персонажа.",
    ["Reset position"] = "Скинути позицію",
    ["Nudge the tracker left or right around the prey icon."] = "Зсунути трекер ліворуч або праворуч навколо іконки здобичі.",
    ["Move the floating tracker left or right on the screen."] = "Перемістити плаваючий трекер ліворуч або праворуч на екрані.",
    ["Nudge the tracker up or down around the prey icon."] = "Зсунути трекер вгору або вниз навколо іконки здобичі.",
    ["Move the floating tracker up or down on the screen."] = "Перемістити плаваючий трекер вгору або вниз на екрані.",

    -- Display mode labels
    ["Ring"] = "Кільце",
    ["Orbs"] = "Сфери",
    ["Bar"] = "Смуга",
    ["Text"] = "Текст",

    -- Stage labels
    ["COLD"] = "ХОЛОДНО",
    ["WARM"] = "ТЕПЛО",
    ["HOT"] = "ГАРЯЧЕ",
    ["FINAL"] = "ФІНАЛ",

    -- State labels
    ["On"] = "Увімк.",
    ["Off"] = "Вимк.",
    ["Unavailable"] = "Недоступно",

    -- Summary / sidebar labels
    ["Current setup"] = "Поточна конфігурація",
    ["Preview"] = "Попередній перегляд",
    ["Quick actions"] = "Швидкі дії",
    ["Style"] = "Стиль",
    ["Blizzard UI"] = "Інтерфейс Blizzard",
    ["Floating"] = "Плаваючий",
    ["Attached"] = "Прикріплений",
    ["Overlay only"] = "Лише накладення",
    ["Show both"] = "Показати обидва",
    ["Number on"] = "Число увімк.",
    ["Number off"] = "Число вимк.",
    ["Badge on"] = "Значок увімк.",
    ["Badge off"] = "Значок вимк.",
    ["Watch + waypoint focus"] = "Спостереження + точка маршруту",
    ["Watch list only"] = "Лише список спостереження",
    ["Waypoint focus only"] = "Лише точка маршруту",
    ["Orb strip"] = "Смуга сфер",
    ["Text only"] = "Лише текст",
    ["Reset all"] = "Скинути все",
    ["Refresh now"] = "Оновити зараз",
    ["DRAG TO MOVE"] = "ПЕРЕТЯГНІТЬ ДЛЯ ПЕРЕМІЩЕННЯ",
    ["DRAGGING"] = "ПЕРЕМІЩЕННЯ",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Налаштування скинуто до стандартних.",
    ["Refreshed prey widget state."] = "Стан віджета здобичі оновлено.",
    ["Tracker enabled."] = "Трекер увімкнено.",
    ["Tracker disabled."] = "Трекер вимкнено.",
    ["Debug tracing enabled."] = "Відстеження зневадження увімкнено.",
    ["Debug tracing disabled."] = "Відстеження зневадження вимкнено.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Компактний трекер полювання, прив'язаний до віджета Blizzard.",
    ["Status: disabled"] = "Статус: вимкнено",
    ["Status: idle"] = "Статус: очікування",
    ["Status: %s (%d%%)"] = "Статус: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Лівий клік: увімкнути або вимкнути трекер",
    ["Shift-left-click: Open settings"] = "Shift-лівий клік: відкрити налаштування",
    ["Right-click: Force a tracker refresh"] = "Правий клік: примусово оновити трекер",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "Налаштуйте трекер здобичі навколо вашого HUD із попереднім переглядом та зрозумілими секціями.",
    ["Live state shows up here as soon as a prey hunt starts."] = "Стан наживо з'являється тут, щойно починається полювання.",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "Відкрийте цю панель через /pb або Shift-кліком на іконці відсіку.",

    -- Settings panel status
    ["DISABLED"] = "ВИМКНЕНО",
    ["SAMPLE"] = "ЗРАЗОК",
    ["ACTIVE"] = "АКТИВНО",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker вимкнено. Ваше поточне розташування залишається збереженим.",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "Виявлено активне полювання. Попередній перегляд відображає поточний стан трекера.",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "Зараз полювання не активне, тому показано зразковий стан.",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "Попередній перегляд залишається доступним, поки трекер вимкнено.",
    ["Floating layout locked. Unlock it to drag the live tracker."] = "Плаваюче розміщення заблоковано. Розблокуйте, щоб перетягнути трекер.",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "Плаваюче розміщення готове. Перетягніть трекер, коли полювання активне.",
    ["Text view without the Blizzard prey icon."] = "Текстовий вигляд без іконки здобичі Blizzard.",
    ["Text view attached to the Blizzard prey icon."] = "Текстовий вигляд, прикріплений до іконки здобичі Blizzard.",
    ["Bar view without the Blizzard prey icon."] = "Вигляд смуги без іконки здобичі Blizzard.",
    ["Bar view anchored below the Blizzard prey icon."] = "Вигляд смуги, закріплений під іконкою здобичі Blizzard.",
    ["Orb view without the Blizzard prey icon."] = "Вигляд сфери без іконки здобичі Blizzard.",
    ["Orb view attached to the Blizzard prey icon."] = "Вигляд сфери, прикріплений до іконки здобичі Blizzard.",
    ["Ring view without the Blizzard prey icon."] = "Вигляд кільця без іконки здобичі Blizzard.",
    ["Ring sample without the Blizzard prey icon."] = "Зразок кільця без іконки здобичі Blizzard.",
    ["Ring view attached to the Blizzard prey icon."] = "Вигляд кільця, прикріплений до іконки здобичі Blizzard.",
    ["Ring sample attached to the Blizzard prey icon."] = "Зразок кільця, прикріплений до іконки здобичі Blizzard.",

    -- Random hunt settings
    ["Random hunt"] = "Випадкове полювання",
    ["Automate randomized hunt purchasing from Astalor Bloodsworn."] = "Автоматизувати покупку випадкових полювань у Асталора Кривавоклятого.",
    ["Auto-purchase random hunt"] = "Автопокупка випадкового полювання",
    ["Automatically request a randomized hunt from Astalor Bloodsworn when you open his gossip window."] = "Автоматично запитувати випадкове полювання у Асталора Кривавоклятого при відкритті вікна діалогу.",
    ["Hunt difficulty"] = "Складність полювання",
    ["Choose which difficulty to purchase when auto-buying a randomized hunt."] = "Оберіть складність при автоматичній покупці випадкового полювання.",
    ["Normal"] = "Звичайна",
    ["Hard"] = "Складна",
    ["Nightmare"] = "Кошмарна",
    ["Remnant reserve"] = "Запас залишків",
    ["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."] = "Купувати полювання лише коли маєте щонайменше стільки Залишків муки плюс 50 вартості покупки.",

    -- Hunt rewards settings
    ["Hunt rewards"] = "Нагороди полювання",
    ["Automatically choose rewards when completing a prey hunt."] = "Автоматично обирати нагороди при завершенні полювання на здобич.",
    ["Auto-select hunt reward"] = "Автовибір нагороди",
    ["Automatically pick a reward when a completed hunt offers multiple choices."] = "Автоматично обирати нагороду, коли завершене полювання пропонує кілька варіантів.",
    ["Preferred reward"] = "Бажана нагорода",
    ["The reward type to pick first when completing a hunt."] = "Тип нагороди для першочергового вибору при завершенні полювання.",
    ["Fallback reward"] = "Запасна нагорода",
    ["The reward to pick if your preferred choice is unavailable or its currency is capped."] = "Нагорода для вибору, якщо бажаний варіант недоступний або валюта досягла ліміту.",
    ["Gear upgrade currency"] = "Валюта покращення спорядження",
    ["Remnant of Anguish"] = "Залишок муки",
    ["Gold"] = "Золото",
    ["Voidlight Marl"] = "Порожнечосвітній мергель",
}
