-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "ptBR" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Rastreador",
    ["Placement"] = "Posicionamento",
    ["Readout"] = "Indicador",
    ["Text style"] = "Estilo de texto",
    ["Quest help"] = "Ajuda de missão",
    ["Audio & feedback"] = "Áudio e retorno",
    ["Profile"] = "Perfil",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Escolha o estilo do rastreador e o tamanho que fica melhor na sua tela.",
    ["Keep the tracker attached to the prey icon and nudge it into place."] = "Mantenha o rastreador anexado ao ícone de presa e ajuste sua posição.",
    ["Choose which cues appear around the tracker while you hunt."] = "Escolha quais indicadores aparecem ao redor do rastreador durante a caçada.",
    ["Adjust tracker text styling without adding a hard dependency. LibSharedMedia fonts appear automatically when the library is installed."] = "Ajuste o estilo de texto do rastreador sem adicionar uma dependência obrigatória. As fontes do LibSharedMedia aparecem automaticamente quando a biblioteca está instalada.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Mantenha a missão de presa ativa bem visível durante a caçada.",
    ["Control sound cues that fire when your hunt phase changes."] = "Controle os sinais sonoros emitidos quando a fase muda.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Escolha se este personagem usa suas próprias configurações ou os padrões da conta.",

    -- Field titles
    ["Enable tracker"] = "Ativar rastreador",
    ["Display style"] = "Estilo de exibição",
    ["Display size"] = "Tamanho de exibição",
    ["Hide Blizzard prey icon"] = "Ocultar ícone de presa da Blizzard",
    ["Horizontal position"] = "Posição horizontal",
    ["Vertical position"] = "Posição vertical",
    ["Show progress number"] = "Mostrar número de progresso",
    ["Show stage badge"] = "Mostrar emblema de fase",
    ["Font face"] = "Fonte",
    ["Outline"] = "Contorno",
    ["Shadow"] = "Sombra",
    ["Number size"] = "Tamanho do número",
    ["Badge size"] = "Tamanho do emblema",
    ["Add prey quest to tracker"] = "Adicionar missão de presa ao rastreamento",
    ["Focus the prey quest"] = "Focar na missão de presa",
    ["Auto turn-in prey quest"] = "Entregar missão de presa automaticamente",
    ["Play sound on phase change"] = "Tocar som ao mudar de fase",
    ["Sound theme"] = "Tema sonoro",
    ["Death cue during hunt"] = "Sinal de morte durante a caçada",
    ["Use character profile"] = "Usar perfil do personagem",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Ative ou desative o Preybreaker sem perder seu layout.",
    ["Choose the shape that best fits your UI."] = "Escolha a forma que melhor se adapta à sua interface.",
    ["Make the current style bigger or smaller."] = "Aumente ou diminua o estilo atual.",
    ["Show only Preybreaker while the prey hunt is active."] = "Mostrar apenas o Preybreaker enquanto a caçada estiver ativa.",
    ["Show a simple number inside the tracker."] = "Mostrar um número simples dentro do rastreador.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Exibir FRIO, MORNO, QUENTE ou FINAL abaixo do rastreador.",
    ["Stage badges are available in ring and orb styles."] = "Os emblemas de fase estão disponíveis nos estilos anel e orbe.",
    ["Choose a Blizzard font by default, or pick a LibSharedMedia font when one is available."] = "Use uma fonte da Blizzard por padrão, ou escolha uma fonte do LibSharedMedia quando disponível.",
    ["Override the text outline used by the tracker readouts."] = "Substituir o contorno de texto usado pelas leituras do rastreador.",
    ["Override the text shadow used by the tracker readouts."] = "Substituir a sombra de texto usada pelas leituras do rastreador.",
    ["Scale the progress number and the text-only readout without changing the tracker frame itself."] = "Redimensionar o número de progresso e a leitura somente texto sem alterar o quadro do rastreador.",
    ["Scale the stage badge text separately from the main progress number."] = "Redimensionar o texto do emblema de fase separadamente do número de progresso principal.",
    ["Automatically place the active prey quest in your watch list."] = "Colocar automaticamente a missão de presa ativa na sua lista de acompanhamento.",
    ["Keep the active prey quest selected for your objective arrow."] = "Manter a missão de presa ativa selecionada para sua seta de objetivo.",
    ["Automatically complete the prey quest when it pops up, unless a reward choice is required."] = "Completar automaticamente a missão de presa quando ela aparecer, a menos que uma escolha de recompensa seja necessária.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Ouvir um sinal sonoro quando a caçada passar para uma nova fase.",
    ["Select the active sound pack used for prey hunt audio cues."] = "Selecionar o pacote sonoro ativo para sinais de caçada.",
    ["Play a death cue when you die during an active prey hunt in the hunt zone."] = "Tocar um sinal de morte quando você morrer durante uma caçada ativa na zona de caça.",
    ["Store a separate set of settings for this character."] = "Armazenar um conjunto separado de configurações para este personagem.",
    ["Nudge the tracker left or right around the prey icon."] = "Mover o rastreador para esquerda ou direita ao redor do ícone de presa.",
    ["Nudge the tracker up or down around the prey icon."] = "Mover o rastreador para cima ou baixo ao redor do ícone de presa.",

    -- Display mode labels
    ["Ring"] = "Anel",
    ["Orbs"] = "Orbes",
    ["Bar"] = "Barra",
    ["Text"] = "Texto",

    -- Sound theme labels
    ["Among Us"] = "Among Us",
    ["Generic"] = "Genérico",
    ["Jurassic Park"] = "Jurassic Park",
    ["Pokemon"] = "Pokémon",
    ["Predator"] = "Predator",
    ["Stranger Things"] = "Stranger Things",
    ["Random"] = "Aleatório",

    -- Stage labels
    ["COLD"] = "FRIO",
    ["WARM"] = "MORNO",
    ["HOT"] = "QUENTE",
    ["FINAL"] = "FINAL",

    -- State labels
    ["On"] = "Ligado",
    ["Off"] = "Desligado",
    ["Unavailable"] = "Indisponível",
    ["Default"] = "Padrão",
    ["None"] = "Nenhum",
    ["Thick outline"] = "Contorno grosso",

    -- Summary / sidebar labels
    ["Current setup"] = "Configuração atual",
    ["Preview"] = "Pré-visualização",
    ["Quick actions"] = "Ações rápidas",
    ["Style"] = "Estilo",
    ["Blizzard UI"] = "Interface da Blizzard",
    ["Attached"] = "Anexado",
    ["Overlay only"] = "Apenas sobreposição",
    ["Show both"] = "Mostrar ambos",
    ["Number on"] = "Número ligado",
    ["Number off"] = "Número desligado",
    ["Badge on"] = "Emblema ligado",
    ["Badge off"] = "Emblema desligado",
    ["Watch + waypoint focus"] = "Acompanhamento + ponto de rota",
    ["Watch list only"] = "Apenas lista de acompanhamento",
    ["Waypoint focus only"] = "Apenas ponto de rota",
    ["Orb strip"] = "Faixa de orbes",
    ["Text only"] = "Apenas texto",
    ["Reset all"] = "Redefinir tudo",
    ["Refresh now"] = "Atualizar agora",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Configurações redefinidas para os padrões.",
    ["Refreshed prey widget state."] = "Estado do widget de presa atualizado.",
    ["Tracker enabled."] = "Rastreador ativado.",
    ["Tracker disabled."] = "Rastreador desativado.",
    ["Debug tracing enabled."] = "Rastreamento de depuração ativado.",
    ["Debug tracing disabled."] = "Rastreamento de depuração desativado.",
    ["Standalone hunt panel shown."] = "Painel de caçada autônomo exibido.",
    ["Standalone hunt panel hidden."] = "Painel de caçada autônomo oculto.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Rastreador compacto de caçada ancorado ao widget da Blizzard.",
    ["Status: disabled"] = "Status: desativado",
    ["Status: idle"] = "Status: inativo",
    ["Status: %s (%d%%)"] = "Status: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Clique esquerdo: ativar ou desativar o rastreador",
    ["Shift-left-click: Open settings"] = "Shift-clique esquerdo: abrir configurações",
    ["Right-click: Force a tracker refresh"] = "Clique direito: forçar atualização do rastreador",
    ["Shift-right-click: Open hunt panel"] = "Shift-clique direito: abrir painel de caçada",

    -- Settings panel chrome
    ["Shape the prey tracker around your HUD with a live preview and clear sections."] = "Configure o rastreador de presa no seu HUD com pré-visualização ao vivo e seções claras.",
    ["Live state shows up here as soon as a prey hunt starts."] = "O estado ao vivo aparece aqui assim que uma caçada começa.",
    ["Open this panel with /pb or by shift-left-clicking the compartment icon."] = "Abra este painel com /pb ou fazendo Shift-clique no ícone do compartimento.",

    -- Settings panel status
    ["DISABLED"] = "DESATIVADO",
    ["SAMPLE"] = "EXEMPLO",
    ["ACTIVE"] = "ATIVO",
    ["Preybreaker is turned off. Your current layout stays saved."] = "O Preybreaker está desligado. Seu layout atual permanece salvo.",
    ["Live prey hunt detected. The preview mirrors the current tracker state."] = "Caçada de presa detectada. A pré-visualização reflete o estado atual do rastreador.",
    ["No prey hunt is active right now, so the preview shows a sample state."] = "Nenhuma caçada está ativa agora, então a pré-visualização mostra um estado de exemplo.",

    -- Preview notes
    ["Preview stays available while the tracker is turned off."] = "A pré-visualização continua disponível com o rastreador desligado.",
    ["Text view without the Blizzard prey icon."] = "Visualização de texto sem o ícone de presa da Blizzard.",
    ["Text view attached to the Blizzard prey icon."] = "Visualização de texto anexada ao ícone de presa da Blizzard.",
    ["Bar view without the Blizzard prey icon."] = "Visualização de barra sem o ícone de presa da Blizzard.",
    ["Bar view anchored below the Blizzard prey icon."] = "Visualização de barra ancorada abaixo do ícone de presa da Blizzard.",
    ["Orb view without the Blizzard prey icon."] = "Visualização de orbe sem o ícone de presa da Blizzard.",
    ["Orb view attached to the Blizzard prey icon."] = "Visualização de orbe anexada ao ícone de presa da Blizzard.",
    ["Ring view without the Blizzard prey icon."] = "Visualização de anel sem o ícone de presa da Blizzard.",
    ["Ring sample without the Blizzard prey icon."] = "Exemplo de anel sem o ícone de presa da Blizzard.",
    ["Ring view attached to the Blizzard prey icon."] = "Visualização de anel anexada ao ícone de presa da Blizzard.",
    ["Ring sample attached to the Blizzard prey icon."] = "Exemplo de anel anexado ao ícone de presa da Blizzard.",

    -- Hunt panel settings
    ["Hunt panel"] = "Painel de caçadas",
    ["Control the hunt list panel that docks beside the Adventure Map."] = "Controla o painel de lista de caçadas que se acopla ao lado do Mapa de Aventuras.",
    ["Enable hunt panel"] = "Ativar painel de caçadas",
    ["Show the hunt list panel when the Adventure Map is open and allow standalone use."] = "Mostra o painel de lista de caçadas quando o Mapa de Aventuras está aberto e permite uso independente.",
    ["Hunt panel disabled."] = "Painel de caçadas desativado.",

    -- Random hunt settings
    ["Random hunt"] = "Caçada aleatória",
    ["Automate randomized hunt purchasing from Astalor Bloodsworn."] = "Automatizar a compra de caçadas aleatórias de Astalor Juradesangue.",
    ["Auto-purchase random hunt"] = "Compra automática de caçada aleatória",
    ["Automatically request a randomized hunt from Astalor Bloodsworn when you open his gossip window."] = "Solicitar automaticamente uma caçada aleatória de Astalor Juradesangue ao abrir sua janela de diálogo.",
    ["Hunt difficulty"] = "Dificuldade da caçada",
    ["Choose which difficulty to purchase when auto-buying a randomized hunt."] = "Escolha a dificuldade ao comprar automaticamente uma caçada aleatória.",
    ["Normal"] = "Normal",
    ["Hard"] = "Difícil",
    ["Nightmare"] = "Pesadelo",
    ["Remnant reserve"] = "Reserva de vestígios",
    ["Only purchase a hunt when you have at least this many Remnants of Anguish plus the 50 purchase cost."] = "Comprar uma caçada apenas quando tiver pelo menos esta quantidade de Vestígios de Angústia mais o custo de 50.",

    -- Hunt rewards settings
    ["Hunt rewards"] = "Recompensas de caçada",
    ["Automatically choose rewards when completing a prey hunt."] = "Escolher recompensas automaticamente ao completar uma caçada de presa.",
    ["Auto-select hunt reward"] = "Seleção automática de recompensa",
    ["Automatically pick a reward when a completed hunt offers multiple choices."] = "Escolher automaticamente uma recompensa quando a caçada completada oferecer várias opções.",
    ["Preferred reward"] = "Recompensa preferida",
    ["The reward type to pick first when completing a hunt."] = "O tipo de recompensa a escolher primeiro ao completar uma caçada.",
    ["Fallback reward"] = "Recompensa alternativa",
    ["The reward to pick if your preferred choice is unavailable or its currency is capped."] = "A recompensa a escolher se sua opção preferida estiver indisponível ou sua moeda estiver no limite.",
    ["Gear upgrade currency"] = "Moeda de melhoria de equipamento",
    ["Remnant of Anguish"] = "Vestígio de Angústia",
    ["Gold"] = "Ouro",
    ["Voidlight Marl"] = "Marga de luz do Vazio",

    -- Tab labels
    ["Settings"] = "Configurações",
    ["Changelog"] = "Registro de alterações",
    ["Social"] = "Social",
    ["Roadmap"] = "Roteiro",
    ["Select"] = "Selecionar",
    ["Select URL text and copy it."] = "Selecione o texto da URL e copie.",
    ["Known issues"] = "Problemas conhecidos",
    ["Planned features"] = "Funcionalidades planejadas",
    ["Items tracked for upcoming releases."] = "Itens rastreados para próximas versões.",
    ["No known issues currently listed."] = "Nenhum problema conhecido listado atualmente.",
    ["No planned features currently listed."] = "Nenhuma funcionalidade planejada listada atualmente.",
}
