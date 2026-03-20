-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Danny Patten

local _, ns = ...
if ns._clientLocale ~= "ptBR" then return end

ns._activeTranslation = {
    -- Section titles
    ["Tracker"] = "Rastreador",
    ["Placement"] = "Posicionamento",
    ["Readout"] = "Indicador",
    ["Quest help"] = "Ajuda de missão",
    ["Audio & feedback"] = "Áudio e retorno",
    ["Drag & grid"] = "Arrastar e grade",
    ["Profile"] = "Perfil",

    -- Section descriptions
    ["Pick the tracker style and the overall size that feels right on your screen."] = "Escolha o estilo do rastreador e o tamanho que fica melhor na sua tela.",
    ["Keep the tracker on the prey icon or switch it to a movable floating layout."] = "Mantenha o rastreador no ícone de presa ou mude para um layout flutuante.",
    ["Choose which cues appear around the tracker while you hunt."] = "Escolha quais indicadores aparecem ao redor do rastreador durante a caçada.",
    ["Keep the active prey quest easy to spot while the hunt is running."] = "Mantenha a missão de presa ativa bem visível durante a caçada.",
    ["Control sound cues that fire when your hunt phase changes."] = "Controle os sinais sonoros emitidos quando a fase muda.",
    ["Fine-tune how the floating tracker behaves when you reposition it."] = "Ajuste o comportamento do rastreador flutuante ao reposicioná-lo.",
    ["Choose whether this character uses its own settings or the account-wide defaults."] = "Escolha se este personagem usa suas próprias configurações ou os padrões da conta.",

    -- Field titles
    ["Enable tracker"] = "Ativar rastreador",
    ["Display style"] = "Estilo de exibição",
    ["Display size"] = "Tamanho de exibição",
    ["Detach from prey icon"] = "Separar do ícone de presa",
    ["Lock floating position"] = "Travar posição flutuante",
    ["Reset floating position"] = "Redefinir posição flutuante",
    ["Hide Blizzard prey icon"] = "Ocultar ícone de presa da Blizzard",
    ["Horizontal position"] = "Posição horizontal",
    ["Vertical position"] = "Posição vertical",
    ["Show progress number"] = "Mostrar número de progresso",
    ["Show stage badge"] = "Mostrar emblema de fase",
    ["Add prey quest to tracker"] = "Adicionar missão de presa ao rastreamento",
    ["Focus the prey quest"] = "Focar na missão de presa",
    ["Play sound on phase change"] = "Tocar som ao mudar de fase",
    ["Snap to grid"] = "Alinhar à grade",
    ["Grid size"] = "Tamanho da grade",
    ["Use character profile"] = "Usar perfil do personagem",

    -- Field descriptions
    ["Turn Preybreaker on or off without losing your layout."] = "Ative ou desative o Preybreaker sem perder seu layout.",
    ["Choose the shape that best fits your UI."] = "Escolha a forma que melhor se adapta à sua interface.",
    ["Make the current style bigger or smaller."] = "Aumente ou diminua o estilo atual.",
    ["Turn the tracker into a free-floating element you can place anywhere."] = "Transforme o rastreador em um elemento flutuante que você pode colocar em qualquer lugar.",
    ["Keep the floating tracker fixed once it is where you want it."] = "Fixe o rastreador flutuante quando ele estiver onde você quer.",
    ["Available after you switch the tracker to the floating layout."] = "Disponível após mudar para o layout flutuante.",
    ["Bring the floating tracker back to the center of your screen."] = "Traga o rastreador flutuante de volta ao centro da tela.",
    ["Show only Preybreaker while the prey hunt is active."] = "Mostrar apenas o Preybreaker enquanto a caçada estiver ativa.",
    ["Show a simple number inside the tracker."] = "Mostrar um número simples dentro do rastreador.",
    ["Display COLD, WARM, HOT, or FINAL below the tracker."] = "Exibir FRIO, MORNO, QUENTE ou FINAL abaixo do rastreador.",
    ["Stage badges are available in ring and orb styles."] = "Os emblemas de fase estão disponíveis nos estilos anel e orbe.",
    ["Automatically place the active prey quest in your watch list."] = "Colocar automaticamente a missão de presa ativa na sua lista de acompanhamento.",
    ["Keep the active prey quest selected for your objective arrow."] = "Manter a missão de presa ativa selecionada para sua seta de objetivo.",
    ["Hear an audio cue when the prey hunt moves to a new stage."] = "Ouvir um sinal sonoro quando a caçada passar para uma nova fase.",
    ["Align the floating tracker to an invisible pixel grid when you drop it."] = "Alinhar o rastreador flutuante a uma grade de pixels invisível ao soltá-lo.",
    ["Spacing of the snap grid in pixels."] = "Espaçamento da grade de alinhamento em pixels.",
    ["Store a separate set of settings for this character."] = "Armazenar um conjunto separado de configurações para este personagem.",
    ["Reset position"] = "Redefinir posição",
    ["Nudge the tracker left or right around the prey icon."] = "Mover o rastreador para esquerda ou direita ao redor do ícone de presa.",
    ["Move the floating tracker left or right on the screen."] = "Mover o rastreador flutuante para esquerda ou direita na tela.",
    ["Nudge the tracker up or down around the prey icon."] = "Mover o rastreador para cima ou baixo ao redor do ícone de presa.",
    ["Move the floating tracker up or down on the screen."] = "Mover o rastreador flutuante para cima ou baixo na tela.",

    -- Display mode labels
    ["Ring"] = "Anel",
    ["Orbs"] = "Orbes",
    ["Bar"] = "Barra",
    ["Text"] = "Texto",

    -- Stage labels
    ["COLD"] = "FRIO",
    ["WARM"] = "MORNO",
    ["HOT"] = "QUENTE",
    ["FINAL"] = "FINAL",

    -- State labels
    ["On"] = "Ligado",
    ["Off"] = "Desligado",
    ["Unavailable"] = "Indisponível",

    -- Summary / sidebar labels
    ["Current setup"] = "Configuração atual",
    ["Preview"] = "Pré-visualização",
    ["Quick actions"] = "Ações rápidas",
    ["Style"] = "Estilo",
    ["Blizzard UI"] = "Interface da Blizzard",
    ["Floating"] = "Flutuante",
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
    ["DRAG TO MOVE"] = "ARRASTE PARA MOVER",
    ["DRAGGING"] = "ARRASTANDO",

    -- Chat / slash messages
    ["Settings reset to defaults."] = "Configurações redefinidas para os padrões.",
    ["Refreshed prey widget state."] = "Estado do widget de presa atualizado.",
    ["Tracker enabled."] = "Rastreador ativado.",
    ["Tracker disabled."] = "Rastreador desativado.",
    ["Debug tracing enabled."] = "Rastreamento de depuração ativado.",
    ["Debug tracing disabled."] = "Rastreamento de depuração desativado.",

    -- Compartment tooltip
    ["Compact prey-hunt tracker anchored to the Blizzard widget."] = "Rastreador compacto de caçada ancorado ao widget da Blizzard.",
    ["Status: disabled"] = "Status: desativado",
    ["Status: idle"] = "Status: inativo",
    ["Status: %s (%d%%)"] = "Status: %s (%d%%)",
    ["Left-click: Enable or disable the tracker"] = "Clique esquerdo: ativar ou desativar o rastreador",
    ["Shift-left-click: Open settings"] = "Shift-clique esquerdo: abrir configurações",
    ["Right-click: Force a tracker refresh"] = "Clique direito: forçar atualização do rastreador",

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
    ["Floating layout locked. Unlock it to drag the live tracker."] = "Layout flutuante travado. Destrave para arrastar o rastreador.",
    ["Floating layout ready. Drag the live tracker when a hunt is active."] = "Layout flutuante pronto. Arraste o rastreador quando uma caçada estiver ativa.",
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
}
