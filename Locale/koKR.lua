-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "koKR" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "추적기",
    ["Placement"] = "배치",
    ["Readout"] = "표시",
    ["Text style"] = "텍스트 스타일",
    ["Quest help"] = "퀘스트 도움",
    ["Audio & feedback"] = "소리 및 피드백",
    ["Profile"] = "프로필",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "화면에 맞는 추적기 스타일과 전체 크기를 선택하세요.",
    ["Keep the tracker attached to the prey icon and nudge it into place."] = "추적기를 먹이 아이콘에 부착하고 위치를 미세 조정합니다.",
    ["Choose which cues appear around the tracker while you hunt."] = "사냥 중 추적기 주변에 표시할 단서를 선택하세요.",
    ["Adjust tracker text styling without adding a hard dependency. LibSharedMedia fonts appear automatically when the library is installed."] = "추적기 텍스트 스타일을 하드 의존성 없이 조정합니다. LibSharedMedia 글꼴은 라이브러리 설치 시 자동으로 표시됩니다.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "사냥 중 활성 먹이 퀘스트를 쉽게 볼 수 있도록 유지합니다.",
    ["Control sound cues that fire when your hunt phase changes."] = "사냥 단계 변경 시 재생되는 소리 신호를 제어합니다.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "이 캐릭터가 자체 설정을 사용할지 계정 기본값을 사용할지 선택하세요.",

    -- Field titles
    ["Enable tracker"] = "추적기 활성화",
    ["Display style"] = "표시 스타일",
    ["Display size"] = "표시 크기",
    ["Hide Blizzard prey icon"] = "블리자드 먹이 아이콘 숨기기",
    ["Horizontal position"] = "수평 위치",
    ["Vertical position"] = "수직 위치",
    ["Show progress number"] = "진행 숫자 표시",
    ["Show stage badge"] = "단계 배지 표시",
    ["Font face"] = "글꼴",
    ["Outline"] = "외곽선",
    ["Shadow"] = "그림자",
    ["Number size"] = "숫자 크기",
    ["Badge size"] = "배지 크기",
    ["Add prey quest to tracker"] = "먹이 퀘스트를 추적에 추가",
    ["Focus the prey quest"] = "먹이 퀘스트 집중",
    ["Auto turn-in prey quest"] = "먹이 퀘스트 자동 완료",
    ["Play sound on phase change"] = "단계 변경 시 소리 재생",
    ["Sound theme"] = "소리 테마",
    ["Death cue during hunt"] = "사냥 중 사망 신호",
    ["Use character profile"] = "캐릭터 프로필 사용",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "배치를 잃지 않고 Preybreaker를 켜거나 끕니다.",
    ["Choose the shape that best fits your UI."] = "인터페이스에 가장 적합한 형태를 선택하세요.",
    ["Make the current style bigger or smaller."] = "현재 스타일을 크거나 작게 만듭니다.",
    ["Show only Preybreaker while the prey hunt is active."] = "먹이 사냥이 활성화된 동안 Preybreaker만 표시합니다.",
    ["Show a simple number inside the tracker."] = "추적기 안에 간단한 숫자를 표시합니다.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "추적기 아래에 차가움, 따뜻함, 뜨거움 또는 최종을 표시합니다.",
    ["Stage badges are available in ring and orb styles."] = "단계 배지는 고리 및 구체 스타일로 사용할 수 있습니다.",
    ["Choose a Blizzard font by default, or pick a LibSharedMedia font when one is available."] = "기본적으로 블리자드 글꼴을 사용하거나 LibSharedMedia 글꼴이 있으면 선택합니다.",
    ["Override the text outline used by the tracker readouts."] = "추적기 표시에 사용되는 텍스트 외곽선을 덮어씁니다.",
    ["Override the text shadow used by the tracker readouts."] = "추적기 표시에 사용되는 텍스트 그림자를 덮어씁니다.",
    ["Scale the progress number and the text-only readout without changing the tracker frame itself."] = "추적기 프레임을 변경하지 않고 진행 숫자와 텍스트 전용 표시를 조절합니다.",
    ["Scale the stage badge text separately from the main progress number."] = "주 진행 숫자와 별도로 단계 배지 텍스트를 조절합니다.",
    ["Automatically place the active prey quest in your watch list."] = "활성 먹이 퀘스트를 자동으로 감시 목록에 추가합니다.",
    ["Keep the active prey quest selected for your objective arrow."] = "활성 먹이 퀘스트를 목표 화살표에 선택된 상태로 유지합니다.",
    ["Automatically complete the prey quest when it pops up, unless a reward choice is required."] = "보상 선택이 필요하지 않은 한, 먹이 퀘스트가 나타나면 자동으로 완료합니다.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "먹이 사냥이 새 단계로 이동할 때 소리 신호를 듣습니다.",
    ["Select the active sound pack used for prey hunt audio cues."] = "먹이 사냥 소리 신호에 사용되는 활성 사운드 팩을 선택합니다.",
    ["Play a death cue when you die during an active prey hunt in the hunt zone."] = "사냥 구역에서 활성 먹이 사냥 중 사망 시 사망 신호를 재생합니다.",
    ["Store a separate set of settings for this character."] = "이 캐릭터에 대한 별도의 설정을 저장합니다.",
    ["Nudge the tracker left or right around the prey icon."] = "먹이 아이콘 주변에서 추적기를 좌우로 이동합니다.",
    ["Nudge the tracker up or down around the prey icon."] = "먹이 아이콘 주변에서 추적기를 상하로 이동합니다.",

    -- Display mode labels
    ["Ring"] = "고리",
    ["Orbs"] = "구체",
    ["Bar"] = "바",
    ["Text"] = "텍스트",

    -- Sound theme labels
    ["Among Us"] = "Among Us",
    ["Generic"] = "일반",
    ["Jurassic Park"] = "Jurassic Park",
    ["Pokemon"] = "Pokémon",
    ["Predator"] = "Predator",
    ["Stranger Things"] = "Stranger Things",
    ["Random"] = "무작위",

    -- Stage labels
    ["COLD"] = "차가움",
    ["WARM"] = "따뜻함",
    ["HOT"] = "뜨거움",
    ["FINAL"] = "최종",

    -- State labels
    ["On"] = "켜짐",
    ["Off"] = "꺼짐",
    ["Unavailable"] = "사용 불가",
    ["Default"] = "기본",
    ["None"] = "없음",
    ["Thick outline"] = "굵은 외곽선",

    -- Summary / sidebar labels
    ["Current setup"] = "현재 설정",
    ["Preview"] = "미리보기",
    ["Quick actions"] = "빠른 작업",
    ["Style"] = "스타일",
    ["Blizzard UI"] = "블리자드 UI",
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

    -- Chat / slash messages
    ["Settings reset to defaults."] = "설정이 기본값으로 초기화되었습니다.",
    ["Refreshed prey widget state."] = "먹이 위젯 상태가 새로고침되었습니다.",
    ["Tracker enabled."] = "추적기가 활성화되었습니다.",
    ["Tracker disabled."] = "추적기가 비활성화되었습니다.",
    ["Debug tracing enabled."] = "디버그 추적이 활성화되었습니다.",
    ["Debug tracing disabled."] = "디버그 추적이 비활성화되었습니다.",
    ["Standalone hunt panel shown."] = "독립형 사냥 패널이 표시되었습니다.",
    ["Standalone hunt panel hidden."] = "독립형 사냥 패널이 숨겨졌습니다.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "블리자드 위젯에 고정된 컴팩트 먹이 사냥 추적기.",
    ["Status: disabled"] = "상태: 비활성화됨",
    ["Status: idle"] = "상태: 대기 중",
    ["Status: %s (%d%%)"] = "상태: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "좌클릭: 추적기 활성화 또는 비활성화",
    ["Shift-left-click: Open settings"] = "Shift-좌클릭: 설정 열기",
    ["Right-click: Force a tracker refresh"] = "우클릭: 추적기 강제 새로고침",
    ["Shift-right-click: Open hunt panel"] = "Shift-우클릭: 사냥 패널 열기",

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

    -- Hunt panel settings
    ["Hunt panel"] = "사냥 패널",
    ["Control the hunt list panel that docks beside the Adventure Map."] = "모험 지도 옆에 도킹되는 사냥 목록 패널을 제어합니다.",
    ["Enable hunt panel"] = "사냥 패널 활성화",
    ["Show the hunt list panel when the Adventure Map is open and allow standalone use."] = "모험 지도가 열려 있을 때 사냥 목록 패널을 표시하고 독립 사용을 허용합니다.",
    ["Hunt panel disabled."] = "사냥 패널이 비활성화되었습니다.",

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

    -- Tab labels
    ["Settings"] = "설정",
    ["Changelog"] = "변경 기록",
    ["Social"] = "소셜",
    ["Roadmap"] = "로드맵",
    ["Select"] = "선택",
    ["Select URL text and copy it."] = "URL 텍스트를 선택하고 복사하세요.",
    ["Known issues"] = "알려진 문제",
    ["Planned features"] = "계획된 기능",
    ["Items tracked for upcoming releases."] = "다가오는 릴리스를 위해 추적 중인 항목.",
    ["No known issues currently listed."] = "현재 나열된 알려진 문제가 없습니다.",
    ["No planned features currently listed."] = "현재 나열된 계획된 기능이 없습니다.",
}
