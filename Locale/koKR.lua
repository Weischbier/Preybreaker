-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "koKR" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "추적기",
    ["Placement"] = "배치",
    ["Readout"] = "표시",
    ["Quest help"] = "퀘스트 도움",
    ["Audio & feedback"] = "소리 및 피드백",
    ["Drag & grid"] = "드래그 및 격자",
    ["Profile"] = "프로필",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "화면에 맞는 추적기 스타일과 전체 크기를 선택하세요.",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "추적기를 먹이 아이콘에 유지하거나 이동 가능한 부유 배치로 전환하세요.",
    ["Choose which cues appear around the tracker while you hunt."] = "사냥 중 추적기 주변에 표시할 단서를 선택하세요.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "사냥 중 활성 먹이 퀘스트를 쉽게 볼 수 있도록 유지합니다.",
    ["Control sound cues that fire when your hunt phase changes."] = "사냥 단계 변경 시 재생되는 소리 신호를 제어합니다.",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "부유 추적기의 재배치 동작을 세밀하게 조정합니다.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "이 캐릭터가 자체 설정을 사용할지 계정 기본값을 사용할지 선택하세요.",

    -- Field titles
    ["Enable tracker"] = "추적기 활성화",
    ["Display style"] = "표시 스타일",
    ["Display size"] = "표시 크기",
    ["Detach from prey icon"] = "먹이 아이콘에서 분리",
    ["Lock floating position"] = "부유 위치 잠금",
    ["Reset floating position"] = "부유 위치 초기화",
    ["Hide Blizzard prey icon"] = "블리자드 먹이 아이콘 숨기기",
    ["Horizontal position"] = "수평 위치",
    ["Vertical position"] = "수직 위치",
    ["Show progress number"] = "진행 숫자 표시",
    ["Show stage badge"] = "단계 배지 표시",
    ["Add prey quest to tracker"] = "먹이 퀘스트를 추적에 추가",
    ["Focus the prey quest"] = "먹이 퀘스트 집중",
    ["Play sound on phase change"] = "단계 변경 시 소리 재생",
    ["Snap to grid"] = "격자에 맞추기",
    ["Grid size"] = "격자 크기",
    ["Use character profile"] = "캐릭터 프로필 사용",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "배치를 잃지 않고 Preybreaker를 켜거나 끕니다.",
    ["Choose the shape that best fits your UI."] = "인터페이스에 가장 적합한 형태를 선택하세요.",
    ["Make the current style bigger or smaller."] = "현재 스타일을 크거나 작게 만듭니다.",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "추적기를 어디든 배치할 수 있는 자유 부유 요소로 전환합니다.",
    ["Keep the floating tracker fixed once it is where you want it."] = "부유 추적기를 원하는 위치에 고정합니다.",
    ["Available after you switch the tracker to the floating layout."] = "부유 배치로 전환한 후 사용할 수 있습니다.",
    ["Bring the floating tracker back to the center of your screen."] = "부유 추적기를 화면 중앙으로 되돌립니다.",
    ["Show only Preybreaker while the prey hunt is active."] = "먹이 사냥이 활성화된 동안 Preybreaker만 표시합니다.",
    ["Show a simple number inside the tracker."] = "추적기 안에 간단한 숫자를 표시합니다.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "추적기 아래에 차가움, 따뜻함, 뜨거움 또는 최종을 표시합니다.",
    ["Stage badges are available in ring and orb styles."] = "단계 배지는 고리 및 구체 스타일로 사용할 수 있습니다.",
    ["Automatically place the active prey quest in your watch list."] = "활성 먹이 퀘스트를 자동으로 감시 목록에 추가합니다.",
    ["Keep the active prey quest selected for your objective arrow."] = "활성 먹이 퀘스트를 목표 화살표에 선택된 상태로 유지합니다.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "먹이 사냥이 새 단계로 이동할 때 소리 신호를 듣습니다.",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "부유 추적기를 놓을 때 보이지 않는 픽셀 격자에 맞춥니다.",
    ["Spacing of the snap grid in pixels."] = "맞춤 격자의 픽셀 간격.",
    ["Store a separate set of settings for this character."] = "이 캐릭터에 대한 별도의 설정을 저장합니다.",
    ["Reset position"] = "위치 초기화",
    ["Nudge the tracker left or right around the prey icon."] = "먹이 아이콘 주변에서 추적기를 좌우로 이동합니다.",
    ["Move the floating tracker left or right on the screen."] = "화면에서 부유 추적기를 좌우로 이동합니다.",
    ["Nudge the tracker up or down around the prey icon."] = "먹이 아이콘 주변에서 추적기를 상하로 이동합니다.",
    ["Move the floating tracker up or down on the screen."] = "화면에서 부유 추적기를 상하로 이동합니다.",

    -- Display mode labels
    ["Ring"] = "고리",
    ["Orbs"] = "구체",
    ["Bar"] = "바",
    ["Text"] = "텍스트",

    -- Stage labels
    ["COLD"] = "차가움",
    ["WARM"] = "따뜻함",
    ["HOT"] = "뜨거움",
    ["FINAL"] = "최종",

    -- State labels
    ["On"] = "켜짐",
    ["Off"] = "꺼짐",
    ["Unavailable"] = "사용 불가",

    -- Summary / sidebar labels
    ["Current setup"] = "현재 설정",
    ["Preview"] = "미리보기",
    ["Quick actions"] = "빠른 작업",
    ["Style"] = "스타일",
    ["Blizzard UI"] = "블리자드 UI",
    ["Floating"] = "부유",
    ["Attached"] = "부착됨",
    ["Overlay only"] = "오버레이만",
    ["Show both"] = "둘 다 표시",
    ["Number on"] = "숫자 켜짐",
    ["Number off"] = "숫자 꺼짐",
    ["Badge on"] = "배지 켜짐",
    ["Badge off"] = "배지 꺼짐",
    ["Watch + waypoint focus"] = "감시 + 경유점 집중",
    ["Watch list only"] = "감시 목록만",
    ["Waypoint focus only"] = "경유점 집중만",
    ["Orb strip"] = "구체 띠",
    ["Text only"] = "텍스트만",
    ["Reset all"] = "모두 초기화",
    ["Refresh now"] = "지금 새로고침",
    ["DRAG TO MOVE"] = "드래그하여 이동",
    ["DRAGGING"] = "이동 중",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "설정이 기본값으로 초기화되었습니다.",
    ["Refreshed prey widget state."] = "먹이 위젯 상태가 새로고침되었습니다.",
    ["Tracker enabled."] = "추적기가 활성화되었습니다.",
    ["Tracker disabled."] = "추적기가 비활성화되었습니다.",
    ["Debug tracing enabled."] = "디버그 추적이 활성화되었습니다.",
    ["Debug tracing disabled."] = "디버그 추적이 비활성화되었습니다.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "블리자드 위젯에 고정된 컴팩트 먹이 사냥 추적기.",
    ["Status: disabled"] = "상태: 비활성화됨",
    ["Status: idle"] = "상태: 대기 중",
    ["Status: %s (%d%%)"] = "상태: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "좌클릭: 추적기 활성화 또는 비활성화",
    ["Shift-left-click: Open settings"] = "Shift-좌클릭: 설정 열기",
    ["Right-click: Force a tracker refresh"] = "우클릭: 추적기 강제 새로고침",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "실시간 미리보기와 명확한 섹션으로 HUD 주변의 먹이 추적기를 구성하세요.",
    ["Live state shows up here as soon as a prey hunt starts."] = "먹이 사냥이 시작되면 실시간 상태가 여기에 표시됩니다.",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "/pb를 입력하거나 구획 아이콘을 Shift-좌클릭하여 이 패널을 엽니다.",

    -- Settings panel status
    ["DISABLED"] = "비활성화됨",
    ["SAMPLE"] = "샘플",
    ["ACTIVE"] = "활성",
    ["Preybreaker is turned off. Your current layout stays saved."] = "Preybreaker가 꺼져 있습니다. 현재 배치는 저장된 상태로 유지됩니다.",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "실시간 먹이 사냥이 감지되었습니다. 미리보기가 현재 추적기 상태를 반영합니다.",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "현재 활성 사냥이 없으므로 미리보기에 샘플 상태가 표시됩니다.",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "추적기가 꺼져 있는 동안에도 미리보기를 사용할 수 있습니다.",
    ["Floating layout locked. Unlock it to drag the live tracker."] = "부유 배치가 잠겨 있습니다. 잠금 해제하여 추적기를 드래그하세요.",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "부유 배치가 준비되었습니다. 사냥이 활성화되면 추적기를 드래그하세요.",
    ["Text view without the Blizzard prey icon."] = "블리자드 먹이 아이콘 없는 텍스트 보기.",
    ["Text view attached to the Blizzard prey icon."] = "블리자드 먹이 아이콘에 부착된 텍스트 보기.",
    ["Bar view without the Blizzard prey icon."] = "블리자드 먹이 아이콘 없는 바 보기.",
    ["Bar view anchored below the Blizzard prey icon."] = "블리자드 먹이 아이콘 아래에 고정된 바 보기.",
    ["Orb view without the Blizzard prey icon."] = "블리자드 먹이 아이콘 없는 구체 보기.",
    ["Orb view attached to the Blizzard prey icon."] = "블리자드 먹이 아이콘에 부착된 구체 보기.",
    ["Ring view without the Blizzard prey icon."] = "블리자드 먹이 아이콘 없는 고리 보기.",
    ["Ring sample without the Blizzard prey icon."] = "블리자드 먹이 아이콘 없는 고리 샘플.",
    ["Ring view attached to the Blizzard prey icon."] = "블리자드 먹이 아이콘에 부착된 고리 보기.",
    ["Ring sample attached to the Blizzard prey icon."] = "블리자드 먹이 아이콘에 부착된 고리 샘플.",

    -- Random hunt settings
    ["Random hunt"] = "무작위 사냥",
    ["Automate randomized hunt purchasing from Astalor Bloodsworn."] = "아스탈로르 블러드스원에게서 무작위 사냥 구매를 자동화합니다.",
    ["Auto-purchase random hunt"] = "무작위 사냥 자동 구매",
    ["Automatically request a randomized hunt from Astalor Bloodsworn when you open his gossip window."] = "아스탈로르 블러드스원의 대화 창을 열면 자동으로 무작위 사냥을 요청합니다.",
    ["Hunt difficulty"] = "사냥 난이도",
    ["Choose which difficulty to purchase when auto-buying a randomized hunt."] = "무작위 사냥 자동 구매 시 구매할 난이도를 선택합니다.",
    ["Normal"] = "일반",
    ["Hard"] = "어려움",
    ["Nightmare"] = "악몽",
    ["Remnant reserve"] = "잔재 비축량",
    ["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."] = "고뇌의 잔재가 이 수량 이상에 구매 비용 50을 더한 만큼 있을 때만 사냥을 구매합니다.",

    -- Hunt rewards settings
    ["Hunt rewards"] = "사냥 보상",
    ["Automatically choose rewards when completing a prey hunt."] = "먹이 사냥 완료 시 자동으로 보상을 선택합니다.",
    ["Auto-select hunt reward"] = "사냥 보상 자동 선택",
    ["Automatically pick a reward when a completed hunt offers multiple choices."] = "완료된 사냥에 여러 선택지가 있을 때 자동으로 보상을 선택합니다.",
    ["Preferred reward"] = "선호 보상",
    ["The reward type to pick first when completing a hunt."] = "사냥 완료 시 우선 선택할 보상 유형.",
    ["Fallback reward"] = "대체 보상",
    ["The reward to pick if your preferred choice is unavailable or its currency is capped."] = "선호 보상을 사용할 수 없거나 화폐가 상한에 도달했을 때 선택할 보상.",
    ["Gear upgrade currency"] = "장비 강화 화폐",
    ["Remnant of Anguish"] = "고뇌의 잔재",
    ["Gold"] = "골드",
    ["Voidlight Marl"] = "공허빛 이회암",
}
