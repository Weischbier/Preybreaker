-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "zhCN" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "追踪器",
    ["Placement"] = "放置",
    ["Readout"] = "读数",
    ["Quest help"] = "任务帮助",
    ["Audio & feedback"] = "音效与反馈",
    ["Drag & grid"] = "拖拽与网格",
    ["Profile"] = "配置",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "选择适合你屏幕的追踪器样式和整体大小。",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "将追踪器保持在猎物图标上，或切换为可移动的浮动布局。",
    ["Choose which cues appear around the tracker while you hunt."] = "选择狩猎期间追踪器周围显示的提示。",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "狩猎期间保持活跃猎物任务易于发现。",
    ["Control sound cues that fire when your hunt phase changes."] = "控制狩猎阶段变化时播放的音效提示。",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "微调浮动追踪器重新定位时的行为。",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "选择此角色使用自身设置还是账号默认值。",

    -- Field titles
    ["Enable tracker"] = "启用追踪器",
    ["Display style"] = "显示样式",
    ["Display size"] = "显示大小",
    ["Detach from prey icon"] = "从猎物图标分离",
    ["Lock floating position"] = "锁定浮动位置",
    ["Reset floating position"] = "重置浮动位置",
    ["Hide Blizzard prey icon"] = "隐藏暴雪猎物图标",
    ["Horizontal position"] = "水平位置",
    ["Vertical position"] = "垂直位置",
    ["Show progress number"] = "显示进度数字",
    ["Show stage badge"] = "显示阶段徽章",
    ["Add prey quest to tracker"] = "将猎物任务添加到追踪",
    ["Focus the prey quest"] = "聚焦猎物任务",
    ["Play sound on phase change"] = "阶段变化时播放音效",
    ["Snap to grid"] = "对齐到网格",
    ["Grid size"] = "网格大小",
    ["Use character profile"] = "使用角色配置",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "在不丢失布局的情况下开启或关闭 Preybreaker。",
    ["Choose the shape that best fits your UI."] = "选择最适合你界面的形状。",
    ["Make the current style bigger or smaller."] = "放大或缩小当前样式。",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "将追踪器变为可放置在任意位置的自由浮动元素。",
    ["Keep the floating tracker fixed once it is where you want it."] = "将浮动追踪器固定在你想要的位置。",
    ["Available after you switch the tracker to the floating layout."] = "切换到浮动布局后可用。",
    ["Bring the floating tracker back to the center of your screen."] = "将浮动追踪器恢复到屏幕中央。",
    ["Show only Preybreaker while the prey hunt is active."] = "猎物狩猎活跃时只显示 Preybreaker。",
    ["Show a simple number inside the tracker."] = "在追踪器内显示一个简单的数字。",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "在追踪器下方显示冷、温、热或最终。",
    ["Stage badges are available in ring and orb styles."] = "阶段徽章可用于环形和球形样式。",
    ["Automatically place the active prey quest in your watch list."] = "自动将活跃猎物任务添加到监视列表。",
    ["Keep the active prey quest selected for your objective arrow."] = "保持活跃猎物任务为目标箭头的选中状态。",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "猎物狩猎进入新阶段时听到音效提示。",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "放下浮动追踪器时对齐到不可见的像素网格。",
    ["Spacing of the snap grid in pixels."] = "对齐网格的像素间距。",
    ["Store a separate set of settings for this character."] = "为此角色存储一套单独的设置。",
    ["Reset position"] = "重置位置",
    ["Nudge the tracker left or right around the prey icon."] = "在猎物图标周围左右微调追踪器。",
    ["Move the floating tracker left or right on the screen."] = "在屏幕上左右移动浮动追踪器。",
    ["Nudge the tracker up or down around the prey icon."] = "在猎物图标周围上下微调追踪器。",
    ["Move the floating tracker up or down on the screen."] = "在屏幕上上下移动浮动追踪器。",

    -- Display mode labels
    ["Ring"] = "环形",
    ["Orbs"] = "球形",
    ["Bar"] = "条形",
    ["Text"] = "文本",

    -- Stage labels
    ["COLD"] = "冷",
    ["WARM"] = "温",
    ["HOT"] = "热",
    ["FINAL"] = "最终",

    -- State labels
    ["On"] = "开",
    ["Off"] = "关",
    ["Unavailable"] = "不可用",

    -- Summary / sidebar labels
    ["Current setup"] = "当前设置",
    ["Preview"] = "预览",
    ["Quick actions"] = "快速操作",
    ["Style"] = "样式",
    ["Blizzard UI"] = "暴雪界面",
    ["Floating"] = "浮动",
    ["Attached"] = "附着",
    ["Overlay only"] = "仅叠加",
    ["Show both"] = "同时显示",
    ["Number on"] = "数字开",
    ["Number off"] = "数字关",
    ["Badge on"] = "徽章开",
    ["Badge off"] = "徽章关",
    ["Watch + waypoint focus"] = "监视 + 路径点聚焦",
    ["Watch list only"] = "仅监视列表",
    ["Waypoint focus only"] = "仅路径点聚焦",
    ["Orb strip"] = "球形条",
    ["Text only"] = "仅文本",
    ["Reset all"] = "全部重置",
    ["Refresh now"] = "立即刷新",
    ["DRAG TO MOVE"] = "拖拽移动",
    ["DRAGGING"] = "拖拽中",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "设置已重置为默认值。",
    ["Refreshed prey widget state."] = "猎物组件状态已刷新。",
    ["Tracker enabled."] = "追踪器已启用。",
    ["Tracker disabled."] = "追踪器已禁用。",
    ["Debug tracing enabled."] = "调试追踪已启用。",
    ["Debug tracing disabled."] = "调试追踪已禁用。",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "锚定在暴雪组件上的紧凑型猎物狩猎追踪器。",
    ["Status: disabled"] = "状态：已禁用",
    ["Status: idle"] = "状态：空闲",
    ["Status: %s (%d%%)"] = "状态：%s（%d%%）",
    ["Left-click: Enable or disable the tracker"] = "左键点击：启用或禁用追踪器",
    ["Shift-left-click: Open settings"] = "Shift-左键点击：打开设置",
    ["Right-click: Force a tracker refresh"] = "右键点击：强制刷新追踪器",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "通过实时预览和清晰的分区围绕你的HUD配置猎物追踪器。",
    ["Live state shows up here as soon as a prey hunt starts."] = "猎物狩猎开始后，实时状态将在此显示。",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "使用 /pb 或 Shift-左键点击隔间图标打开此面板。",

    -- Settings panel status
    ["DISABLED"] = "已禁用",
    ["SAMPLE"] = "示例",
    ["ACTIVE"] = "活跃",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker 已关闭。你的当前布局保持已保存状态。",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "检测到实时猎物狩猎。预览反映当前追踪器状态。",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "当前没有活跃的猎物狩猎，预览显示示例状态。",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "追踪器关闭时预览仍然可用。",
    ["Floating layout locked. Unlock it to drag the live tracker."] = "浮动布局已锁定。解锁以拖拽追踪器。",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "浮动布局就绪。狩猎活跃时拖拽追踪器。",
    ["Text view without the Blizzard prey icon."] = "不含暴雪猎物图标的文本视图。",
    ["Text view attached to the Blizzard prey icon."] = "附着于暴雪猎物图标的文本视图。",
    ["Bar view without the Blizzard prey icon."] = "不含暴雪猎物图标的条形视图。",
    ["Bar view anchored below the Blizzard prey icon."] = "锚定在暴雪猎物图标下方的条形视图。",
    ["Orb view without the Blizzard prey icon."] = "不含暴雪猎物图标的球形视图。",
    ["Orb view attached to the Blizzard prey icon."] = "附着于暴雪猎物图标的球形视图。",
    ["Ring view without the Blizzard prey icon."] = "不含暴雪猎物图标的环形视图。",
    ["Ring sample without the Blizzard prey icon."] = "不含暴雪猎物图标的环形示例。",
    ["Ring view attached to the Blizzard prey icon."] = "附着于暴雪猎物图标的环形视图。",
    ["Ring sample attached to the Blizzard prey icon."] = "附着于暴雪猎物图标的环形示例。",

    -- Random hunt settings
    ["Random hunt"] = "随机狩猎",
    ["Automate randomized hunt purchasing from Astalor Bloodsworn."] = "自动从阿斯塔洛血誓处购买随机狩猎。",
    ["Auto-purchase random hunt"] = "自动购买随机狩猎",
    ["Automatically request a randomized hunt from Astalor Bloodsworn when you open his gossip window."] = "打开阿斯塔洛血誓的对话窗口时自动请求随机狩猎。",
    ["Hunt difficulty"] = "狩猎难度",
    ["Choose which difficulty to purchase when auto-buying a randomized hunt."] = "自动购买随机狩猎时选择购买的难度。",
    ["Normal"] = "普通",
    ["Hard"] = "困难",
    ["Nightmare"] = "噩梦",
    ["Remnant reserve"] = "残余储备",
    ["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."] = "仅在拥有至少此数量的痛苦残余加上50购买费用时才购买狩猎。",

    -- Hunt rewards settings
    ["Hunt rewards"] = "狩猎奖励",
    ["Automatically choose rewards when completing a prey hunt."] = "完成猎物狩猎时自动选择奖励。",
    ["Auto-select hunt reward"] = "自动选择狩猎奖励",
    ["Automatically pick a reward when a completed hunt offers multiple choices."] = "完成的狩猎提供多个选择时自动选取奖励。",
    ["Preferred reward"] = "首选奖励",
    ["The reward type to pick first when completing a hunt."] = "完成狩猎时优先选择的奖励类型。",
    ["Fallback reward"] = "备选奖励",
    ["The reward to pick if your preferred choice is unavailable or its currency is capped."] = "首选不可用或货币已达上限时选择的奖励。",
    ["Gear upgrade currency"] = "装备升级货币",
    ["Remnant of Anguish"] = "痛苦残余",
    ["Gold"] = "金币",
    ["Voidlight Marl"] = "虚光泥灰",
}
