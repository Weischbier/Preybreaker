-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "ruRU" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Трекер",
    ["Placement"] = "Розташування",
    ["Readout"] = "Показник",
    ["Text style"] = "Стиль тексту",
    ["Quest help"] = "Допомога завдань",
    ["Audio & feedback"] = "Аудіо та зворотний зв'язок",
    ["Profile"] = "Профіль",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Оберіть стиль трекера та розмір, що найкраще пасує вашому екрану.",
    ["Keep the tracker attached to the prey icon and nudge it into place."] = "Тримайте трекер прикріпленим до іконки здобичі та підсуньте його на місце.",
    ["Choose which cues appear around the tracker while you hunt."] = "Оберіть, які підказки з'являються навколо трекера під час полювання.",
    ["Adjust tracker text styling without adding a hard dependency. LibSharedMedia fonts appear automatically when the library is installed."] = "Налаштуйте стиль тексту трекера без жорсткої залежності. Шрифти LibSharedMedia з'являються автоматично, коли бібліотека встановлена.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Тримайте активне завдання здобичі на видному місці під час полювання.",
    ["Control sound cues that fire when your hunt phase changes."] = "Керуйте звуковими сигналами, що лунають при зміні фази полювання.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Оберіть, чи цей персонаж використовує власні налаштування, чи загальні для облікового запису.",

    -- Field titles
    ["Enable tracker"] = "Увімкнути трекер",
    ["Display style"] = "Стиль відображення",
    ["Display size"] = "Розмір відображення",
    ["Hide Blizzard prey icon"] = "Сховати іконку здобичі Blizzard",
    ["Horizontal position"] = "Горизонтальна позиція",
    ["Vertical position"] = "Вертикальна позиція",
    ["Show progress number"] = "Показати число прогресу",
    ["Show stage badge"] = "Показати значок фази",
    ["Font face"] = "Шрифт",
    ["Outline"] = "Обведення",
    ["Shadow"] = "Тінь",
    ["Number size"] = "Розмір числа",
    ["Badge size"] = "Розмір значка",
    ["Add prey quest to tracker"] = "Додати завдання здобичі до відстеження",
    ["Focus the prey quest"] = "Сфокусувати завдання здобичі",
    ["Auto turn-in prey quest"] = "Автозавершення завдання здобичі",
    ["Play sound on phase change"] = "Відтворити звук при зміні фази",
    ["Sound theme"] = "Звукова тема",
    ["Death cue during hunt"] = "Сигнал смерті під час полювання",
    ["Use character profile"] = "Використовувати профіль персонажа",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Увімкніть або вимкніть Preybreaker, не втрачаючи розташування.",
    ["Choose the shape that best fits your UI."] = "Оберіть форму, яка найкраще пасує вашому інтерфейсу.",
    ["Make the current style bigger or smaller."] = "Збільшіть або зменшіть поточний стиль.",
    ["Show only Preybreaker while the prey hunt is active."] = "Показувати лише Preybreaker, поки полювання активне.",
    ["Show a simple number inside the tracker."] = "Показувати просте число всередині трекера.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Показувати ХОЛОДНО, ТЕПЛО, ГАРЯЧЕ або ФІНАЛ під трекером.",
    ["Stage badges are available in ring and orb styles."] = "Значки фаз доступні у стилях кільце та сфера.",
    ["Choose a Blizzard font by default, or pick a LibSharedMedia font when one is available."] = "Використовуйте стандартний шрифт Blizzard або оберіть шрифт LibSharedMedia, якщо доступний.",
    ["Override the text outline used by the tracker readouts."] = "Перевизначити обведення тексту, що використовується показниками трекера.",
    ["Override the text shadow used by the tracker readouts."] = "Перевизначити тінь тексту, що використовується показниками трекера.",
    ["Scale the progress number and the text-only readout without changing the tracker frame itself."] = "Масштабувати число прогресу та текстовий показник без зміни рамки трекера.",
    ["Scale the stage badge text separately from the main progress number."] = "Масштабувати текст значка фази окремо від основного числа прогресу.",
    ["Automatically place the active prey quest in your watch list."] = "Автоматично додати активне завдання здобичі до списку спостереження.",
    ["Keep the active prey quest selected for your objective arrow."] = "Тримати активне завдання здобичі обраним для стрілки цілі.",
    ["Automatically complete the prey quest when it pops up, unless a reward choice is required."] = "Автоматично завершити завдання здобичі, коли воно з'являється, якщо не потрібен вибір нагороди.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Почути звуковий сигнал, коли полювання переходить до нової фази.",
    ["Select the active sound pack used for prey hunt audio cues."] = "Оберіть активний звуковий пакет для сигналів полювання на здобич.",
    ["Play a death cue when you die during an active prey hunt in the hunt zone."] = "Відтворити сигнал смерті, коли ви гинете під час активного полювання в зоні полювання.",
    ["Store a separate set of settings for this character."] = "Зберегти окремий набір налаштувань для цього персонажа.",
    ["Nudge the tracker left or right around the prey icon."] = "Зсунути трекер ліворуч або праворуч навколо іконки здобичі.",
    ["Nudge the tracker up or down around the prey icon."] = "Зсунути трекер вгору або вниз навколо іконки здобичі.",

    -- Display mode labels
    ["Ring"] = "Кільце",
    ["Orbs"] = "Сфери",
    ["Bar"] = "Смуга",
    ["Text"] = "Текст",

    -- Sound theme labels
    ["Among Us"] = "Among Us",
    ["Generic"] = "Загальний",
    ["Jurassic Park"] = "Jurassic Park",
    ["Pokemon"] = "Pokemon",
    ["Predator"] = "Predator",
    ["Stranger Things"] = "Stranger Things",
    ["Random"] = "Випадковий",

    -- Stage labels
    ["COLD"] = "ХОЛОДНО",
    ["WARM"] = "ТЕПЛО",
    ["HOT"] = "ГАРЯЧЕ",
    ["FINAL"] = "ФІНАЛ",

    -- State labels
    ["On"] = "Увімк.",
    ["Off"] = "Вимк.",
    ["Unavailable"] = "Недоступно",
    ["Default"] = "Стандартно",
    ["None"] = "Жодного",
    ["Thick outline"] = "Товсте обведення",

    -- Summary / sidebar labels
    ["Current setup"] = "Поточна конфігурація",
    ["Preview"] = "Попередній перегляд",
    ["Quick actions"] = "Швидкі дії",
    ["Style"] = "Стиль",
    ["Blizzard UI"] = "Інтерфейс Blizzard",
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

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Налаштування скинуто до стандартних.",
    ["Refreshed prey widget state."] = "Стан віджета здобичі оновлено.",
    ["Tracker enabled."] = "Трекер увімкнено.",
    ["Tracker disabled."] = "Трекер вимкнено.",
    ["Debug tracing enabled."] = "Відстеження зневадження увімкнено.",
    ["Debug tracing disabled."] = "Відстеження зневадження вимкнено.",
    ["Standalone hunt panel shown."] = "Окрему панель полювання показано.",
    ["Standalone hunt panel hidden."] = "Окрему панель полювання приховано.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Компактний трекер полювання, прив'язаний до віджета Blizzard.",
    ["Status: disabled"] = "Статус: вимкнено",
    ["Status: idle"] = "Статус: очікування",
    ["Status: %s (%d%%)"] = "Статус: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Лівий клік: увімкнути або вимкнути трекер",
    ["Shift-left-click: Open settings"] = "Shift-лівий клік: відкрити налаштування",
    ["Right-click: Force a tracker refresh"] = "Правий клік: примусово оновити трекер",
    ["Shift-right-click: Open hunt panel"] = "Shift-правий клік: відкрити панель полювання",

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

    -- Hunt panel settings
    ["Hunt panel"] = "Панель охоты",
    ["Control the hunt list panel that docks beside the Adventure Map."] = "Управляет панелью списка охот, которая крепится рядом с Картой приключений.",
    ["Enable hunt panel"] = "Включить панель охоты",
    ["Show the hunt list panel when the Adventure Map is open and allow standalone use."] = "Показывать панель списка охот, когда открыта Карта приключений, и разрешить автономное использование.",
    ["Hunt panel disabled."] = "Панель охоты отключена.",

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

    -- Tab labels
    ["Settings"] = "Налаштування",
    ["Changelog"] = "Журнал змін",
    ["Social"] = "Соціальне",
    ["Roadmap"] = "План розвитку",
    ["Select"] = "Обрати",
    ["Select URL text and copy it."] = "Оберіть текст URL та скопіюйте.",
    ["Known issues"] = "Відомі проблеми",
    ["Planned features"] = "Заплановані функції",
    ["Items tracked for upcoming releases."] = "Елементи, відстежувані для наступних випусків.",
    ["No known issues currently listed."] = "Наразі відомих проблем не зазначено.",
    ["No planned features currently listed."] = "Наразі запланованих функцій не зазначено.",
}
