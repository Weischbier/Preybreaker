-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "zhTW" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "追蹤器",
    ["Placement"] = "放置",
    ["Readout"] = "讀數",
    ["Quest help"] = "任務幫助",
    ["Audio & feedback"] = "音效與回饋",
    ["Drag & grid"] = "拖曳與格線",
    ["Profile"] = "設定檔",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "選擇適合你螢幕的追蹤器樣式和整體大小。",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "將追蹤器保持在獵物圖示上，或切換為可移動的浮動配置。",
    ["Choose which cues appear around the tracker while you hunt."] = "選擇狩獵期間追蹤器周圍顯示的提示。",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "狩獵期間保持活躍獵物任務易於發現。",
    ["Control sound cues that fire when your hunt phase changes."] = "控制狩獵階段變化時播放的音效提示。",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "微調浮動追蹤器重新定位時的行為。",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "選擇此角色使用自身設定還是帳號預設值。",

    -- Field titles
    ["Enable tracker"] = "啟用追蹤器",
    ["Display style"] = "顯示樣式",
    ["Display size"] = "顯示大小",
    ["Detach from prey icon"] = "從獵物圖示分離",
    ["Lock floating position"] = "鎖定浮動位置",
    ["Reset floating position"] = "重設浮動位置",
    ["Hide Blizzard prey icon"] = "隱藏暴雪獵物圖示",
    ["Horizontal position"] = "水平位置",
    ["Vertical position"] = "垂直位置",
    ["Show progress number"] = "顯示進度數字",
    ["Show stage badge"] = "顯示階段徽章",
    ["Add prey quest to tracker"] = "將獵物任務加入追蹤",
    ["Focus the prey quest"] = "聚焦獵物任務",
    ["Play sound on phase change"] = "階段變化時播放音效",
    ["Snap to grid"] = "對齊格線",
    ["Grid size"] = "格線大小",
    ["Use character profile"] = "使用角色設定檔",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "在不遺失配置的情況下開啟或關閉 Preybreaker。",
    ["Choose the shape that best fits your UI."] = "選擇最適合你介面的形狀。",
    ["Make the current style bigger or smaller."] = "放大或縮小目前樣式。",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "將追蹤器變為可放置在任意位置的自由浮動元素。",
    ["Keep the floating tracker fixed once it is where you want it."] = "將浮動追蹤器固定在你想要的位置。",
    ["Available after you switch the tracker to the floating layout."] = "切換到浮動配置後可用。",
    ["Bring the floating tracker back to the center of your screen."] = "將浮動追蹤器恢復到螢幕中央。",
    ["Show only Preybreaker while the prey hunt is active."] = "獵物狩獵活躍時只顯示 Preybreaker。",
    ["Show a simple number inside the tracker."] = "在追蹤器內顯示一個簡單的數字。",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "在追蹤器下方顯示冷、溫、熱或最終。",
    ["Stage badges are available in ring and orb styles."] = "階段徽章可用於環形和球形樣式。",
    ["Automatically place the active prey quest in your watch list."] = "自動將活躍獵物任務加入監視清單。",
    ["Keep the active prey quest selected for your objective arrow."] = "保持活躍獵物任務為目標箭頭的選取狀態。",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "獵物狩獵進入新階段時聽到音效提示。",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "放下浮動追蹤器時對齊到不可見的像素格線。",
    ["Spacing of the snap grid in pixels."] = "對齊格線的像素間距。",
    ["Store a separate set of settings for this character."] = "為此角色儲存一套單獨的設定。",
    ["Reset position"] = "重設位置",
    ["Nudge the tracker left or right around the prey icon."] = "在獵物圖示周圍左右微調追蹤器。",
    ["Move the floating tracker left or right on the screen."] = "在螢幕上左右移動浮動追蹤器。",
    ["Nudge the tracker up or down around the prey icon."] = "在獵物圖示周圍上下微調追蹤器。",
    ["Move the floating tracker up or down on the screen."] = "在螢幕上上下移動浮動追蹤器。",

    -- Display mode labels
    ["Ring"] = "環形",
    ["Orbs"] = "球形",
    ["Bar"] = "條形",
    ["Text"] = "文字",

    -- Stage labels
    ["COLD"] = "冷",
    ["WARM"] = "溫",
    ["HOT"] = "熱",
    ["FINAL"] = "最終",

    -- State labels
    ["On"] = "開",
    ["Off"] = "關",
    ["Unavailable"] = "不可用",

    -- Summary / sidebar labels
    ["Current setup"] = "目前設定",
    ["Preview"] = "預覽",
    ["Quick actions"] = "快速操作",
    ["Style"] = "樣式",
    ["Blizzard UI"] = "暴雪介面",
    ["Floating"] = "浮動",
    ["Attached"] = "附著",
    ["Overlay only"] = "僅疊加",
    ["Show both"] = "同時顯示",
    ["Number on"] = "數字開",
    ["Number off"] = "數字關",
    ["Badge on"] = "徽章開",
    ["Badge off"] = "徽章關",
    ["Watch + waypoint focus"] = "監視 + 路徑點聚焦",
    ["Watch list only"] = "僅監視清單",
    ["Waypoint focus only"] = "僅路徑點聚焦",
    ["Orb strip"] = "球形條",
    ["Text only"] = "僅文字",
    ["Reset all"] = "全部重設",
    ["Refresh now"] = "立即重新整理",
    ["DRAG TO MOVE"] = "拖曳移動",
    ["DRAGGING"] = "拖曳中",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "設定已重設為預設值。",
    ["Refreshed prey widget state."] = "獵物元件狀態已重新整理。",
    ["Tracker enabled."] = "追蹤器已啟用。",
    ["Tracker disabled."] = "追蹤器已停用。",
    ["Debug tracing enabled."] = "除錯追蹤已啟用。",
    ["Debug tracing disabled."] = "除錯追蹤已停用。",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "錨定在暴雪元件上的精巧獵物狩獵追蹤器。",
    ["Status: disabled"] = "狀態：已停用",
    ["Status: idle"] = "狀態：閒置",
    ["Status: %s (%d%%)"] = "狀態：%s（%d%%）",
    ["Left-click: Enable or disable the tracker"] = "左鍵點擊：啟用或停用追蹤器",
    ["Shift-left-click: Open settings"] = "Shift-左鍵點擊：開啟設定",
    ["Right-click: Force a tracker refresh"] = "右鍵點擊：強制重新整理追蹤器",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "透過即時預覽和清晰的分區圍繞你的HUD設定獵物追蹤器。",
    ["Live state shows up here as soon as a prey hunt starts."] = "獵物狩獵開始後，即時狀態將在此顯示。",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "使用 /pb 或 Shift-左鍵點擊隔間圖示開啟此面板。",

    -- Settings panel status
    ["DISABLED"] = "已停用",
    ["SAMPLE"] = "範例",
    ["ACTIVE"] = "活躍",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker 已關閉。你目前的配置保持已儲存狀態。",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "偵測到即時獵物狩獵。預覽反映目前追蹤器狀態。",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "目前沒有活躍的獵物狩獵，預覽顯示範例狀態。",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "追蹤器關閉時預覽仍然可用。",
    ["Floating layout locked. Unlock it to drag the live tracker."] = "浮動配置已鎖定。解鎖以拖曳追蹤器。",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "浮動配置就緒。狩獵活躍時拖曳追蹤器。",
    ["Text view without the Blizzard prey icon."] = "不含暴雪獵物圖示的文字檢視。",
    ["Text view attached to the Blizzard prey icon."] = "附著於暴雪獵物圖示的文字檢視。",
    ["Bar view without the Blizzard prey icon."] = "不含暴雪獵物圖示的條形檢視。",
    ["Bar view anchored below the Blizzard prey icon."] = "錨定在暴雪獵物圖示下方的條形檢視。",
    ["Orb view without the Blizzard prey icon."] = "不含暴雪獵物圖示的球形檢視。",
    ["Orb view attached to the Blizzard prey icon."] = "附著於暴雪獵物圖示的球形檢視。",
    ["Ring view without the Blizzard prey icon."] = "不含暴雪獵物圖示的環形檢視。",
    ["Ring sample without the Blizzard prey icon."] = "不含暴雪獵物圖示的環形範例。",
    ["Ring view attached to the Blizzard prey icon."] = "附著於暴雪獵物圖示的環形檢視。",
    ["Ring sample attached to the Blizzard prey icon."] = "附著於暴雪獵物圖示的環形範例。",

    -- Random hunt settings
    ["Random hunt"] = "隨機狩獵",
    ["Automate randomized hunt purchasing from Astalor Bloodsworn."] = "自動從阿斯塔洛血誓處購買隨機狩獵。",
    ["Auto-purchase random hunt"] = "自動購買隨機狩獵",
    ["Automatically request a randomized hunt from Astalor Bloodsworn when you open his gossip window."] = "開啟阿斯塔洛血誓的對話視窗時自動請求隨機狩獵。",
    ["Hunt difficulty"] = "狩獵難度",
    ["Choose which difficulty to purchase when auto-buying a randomized hunt."] = "自動購買隨機狩獵時選擇購買的難度。",
    ["Normal"] = "普通",
    ["Hard"] = "困難",
    ["Nightmare"] = "夢魘",
    ["Remnant reserve"] = "殘餘儲備",
    ["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."] = "僅在擁有至少此數量的痛苦殘餘加上50購買費用時才購買狩獵。",

    -- Hunt rewards settings
    ["Hunt rewards"] = "狩獵獎勵",
    ["Automatically choose rewards when completing a prey hunt."] = "完成獵物狩獵時自動選擇獎勵。",
    ["Auto-select hunt reward"] = "自動選擇狩獵獎勵",
    ["Automatically pick a reward when a completed hunt offers multiple choices."] = "完成的狩獵提供多個選擇時自動選取獎勵。",
    ["Preferred reward"] = "首選獎勵",
    ["The reward type to pick first when completing a hunt."] = "完成狩獵時優先選擇的獎勵類型。",
    ["Fallback reward"] = "備選獎勵",
    ["The reward to pick if your preferred choice is unavailable or its currency is capped."] = "首選不可用或貨幣已達上限時選擇的獎勵。",
    ["Gear upgrade currency"] = "裝備升級貨幣",
    ["Remnant of Anguish"] = "痛苦殘餘",
    ["Gold"] = "金幣",
    ["Voidlight Marl"] = "虛光泥灰",
}
