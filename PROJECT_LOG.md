# PROJECT_LOG — Exm to do

Registro pessoal de decisões e estado do projeto.

---

## Log de decisões

### 2026-06-20 — Unificar branch redesign com trabalho recente (limpeza automática + ditado)

**O que mudou**
- Estava na branch `ux-review` (sem o redesign visual). Mudei para `redesign` e reapliquei o trabalho desta sessão: limpeza automática, fix de tags/dedup no ditado, modelo OpenRouter.
- Resolvi conflito em `partitioned_group_task_list.dart` — mantive o UI Eximium da redesign **e** o botão **A** de limpeza automática.

**Por que mudou**
- O redesign estava salvo na branch `redesign`, mas eu rodava `ux-review` — por isso a interface antiga continuava aparecendo.

**O que aprendi**
- `git stash` + `checkout redesign` + `stash pop` é o caminho certo para juntar trabalho local com outra branch. Hot reload não reflete mudanças de branch — precisa recompilar.

---

### 2026-06-12 — Redesign UI Fase 2: todas as telas no Eximium Design System

**O que mudou**
- Migrei todas as telas/sheets para os tokens/primitivos da Fase 1, em 3 frentes paralelas:
  - **Entrada & dia**: Login (fundo glow, campos DS, "Continuar com Google"), Home (header "Olá", chips rápidos, seção Atrasadas, divisor Amanhã, FAB com glow), Grupos (cards com tile do ícone na cor do grupo + barra de progresso fina, FAB estendido "Novo grupo").
  - **Detalhe & criação**: Detalhe do grupo (anel de progresso, avatares), Nova tarefa (sheet com input grande + foco verde), Agendar lembrete (mini-calendário + lista agrupada), Recorrência, Localização (mapa intacto), Voz (sheet com borda verde pulsante + waveform verde).
  - **Buscar / Calendário / Perfil**: Busca (campo focado verde), Agenda (`EasyDateTimeLine` recolorido), Perfil (toggle de tema ligado ao `themeModeProvider`), + sheets de grupo/tag/notificação.
- `flutter analyze`: nenhum erro/warning novo (os 27 issues restantes são pré-existentes).

**Por que mudou**
- Concluir o redesign visual completo seguindo o `FLUTTER_IMPLEMENTATION_GUIDE.md`, sem tocar em funcionalidade.

**O que aprendi**
- Fixar o contrato de API (tokens + primitivos) na Fase 1 deixou as 3 frentes de telas rodarem em paralelo sem divergir de estilo.
- Dois pontos do mockup ficaram de fora por exigirem mudar dados/API (proibido): realce do termo na busca e timeline por hora na agenda — candidatos a iteração futura.

**Decisões em aberto (revisar)**
- Botão de busca nos Grupos foi ligado à tela de busca existente.
- Realce do termo na busca e timeline por hora da agenda: implementar depois?

---

### 2026-06-12 — Redesign UI Fase 1: fundação do Eximium Design System

**O que mudou**
- Criei a camada de tokens em `lib/ui/theme/`: `eximium_colors.dart` (`ExColors` como `ThemeExtension` dark+light + `context.ex`), `eximium_typography.dart` (`ExText`, Red Hat Display/Mono), `eximium_spacing.dart` (`ExSpace`/`ExRadius`), `eximium_effects.dart` (glows, focus ring, `ExAppBackground`).
- Reescrevi `app_theme.dart` com `darkTheme` + `lightTheme` Material3; **dark virou o padrão**. Mantive `AppTheme.brandPrimary/cardSurface/backgroundLight` como aliases de compat para não quebrar as telas ainda não migradas.
- `themeModeProvider` (Riverpod Notifier, default dark) persistido em shared_preferences (`eximium-theme`). `MyApp` virou `ConsumerWidget`.
- Primitivos reutilizáveis em `lib/ui/widgets/eximium/`: `ExCard`, `ExButton`, `ExBadge`, `ExGroupChip/ExDot/ExMetaChip/ExRecurrenceChip`, `ExSectionLabel`, `ExGlowFab`, `ExBottomNav` (+ barrel `eximium.dart`).
- `main_shell.dart` agora usa a bottom nav flutuante (`ExBottomNav`), mantendo a mesma lógica/destinos.
- `task_card.dart` redesenhado para o tratamento "A · Acento mínimo" (surface1, radius 20, checkbox circular, hora em mono à direita, chips via primitivos). **API pública do `TaskCard` preservada 100%.**

**Por que mudou**
- Começo do redesign visual completo seguindo o contrato `FLUTTER_IMPLEMENTATION_GUIDE.md`. Fase 1 = só fundação (tokens, tema, primitivos, casca), sem mexer em funcionalidade.

**O que aprendi**
- Manter aliases de compat no `AppTheme` deixa migrar telas em fases sem quebrar build (muitos call-sites usam `brandPrimary`).
- `ThemeExtension` + `context.ex` é o jeito limpo de ter dark/light como cidadãos de 1ª classe e animar a troca de tema.
- Preservar a assinatura do `TaskCard` exige só reescrever a árvore visual interna; toda a lógica de swipe/callbacks fica intacta.

---

### 2026-06-11 — Ditado: criar tags + confirmação editável + meta vs conteúdo

**O que mudou**
- Campo `tagExplicit` no JSON/DTO: quando peço explicitamente uma tag/categoria/etiqueta, o pipeline pode **criar** se não existir (via `addGroupTag`).
- Bottom sheet **Confirmar ditado**: mostra tarefas e categorias a criar, editáveis; confirmar ou cancelar.
- Toggle no **Perfil** → "Confirmar antes de salvar" (padrão ligado; `voice_capture_prefs.dart`).
- Prompts com blocos **Meta vs Conteúdo** e **Tag/Categoria** (sinónimos tag/categoria/etiqueta); `note_capture` deixa de forçar `tagName: null`.
- Plano local `voice_extraction_plan.dart` — sem chamada LLM extra.

**Por que mudou**
- Em Melhorias pedia "cria tag X e adiciona item" e nada acontecia — só ligava tags existentes.
- Quero rever o que será gravado antes de criar categorias novas.
- "Adicione arroz à lista" ≠ "me lembre de adicionar arroz na receita" — o verbo às vezes é conteúdo, às vezes comando ao assistente.

**O que aprendi**
- Criar tag é **persistência**, não LLM extra — mantém velocidade.
- `tagExplicit` separa pedido meu de inferência do modelo (compras continuam só com tags existentes).
- `copyWith` com `??` não limpa campos nullable — precisei de sentinel `_unset` no DTO.

---

### 2026-05-26 — Ditado em modo nota (`note_capture`)

**O que mudou**
- Novo modo de ditado: título **Área: problema** + **descrição** com polimento leve (mesma chamada LLM).
- Router: lembrete → nota → compras → general; grupo fixo já não assume compras.
- Grupos tipo Melhorias/Bugs/Ideias ou fala longa narrativa activam nota; supermercado mantém lista de produtos.

**Por que mudou**
- Melhorias e pontos pessoais precisam de contexto na descrição, não só título curto.
- Velocidade: zero chamadas LLM extra.

**O que aprendi**
- Router por nome de grupo + sinais na fala resolve sem multi-agente.

---

### 2026-05-26 — Ditado em lista de compras: título só com o produto

**O que mudou**
- Prompt específico para grupos de supermercado/mercado/compras quando uso o ditado dentro do grupo.
- Regra clara: cada tarefa criada deve ter só o nome do item ("Arroz", "Feijão"), nunca "Comprar arroz".
- Sanitizador depois do modelo que remove verbos como comprar, pegar, adicionar se o LLM ainda errar.
- Detecção automática pelo nome do grupo (supermercado, mercado, compras, feira, hortifruti, mercearia, etc.).

**Por que mudou**
- Uso muito o ditado no grupo de supermercado para falar vários itens de uma vez.
- Frases do tipo "adicione à lista arroz, macarrão e feijão" geravam tarefas "Comprar macarrão", "Comprar feijão" — ruim para lista de compras.
- O grupo já é o contexto de compra; o título precisa ser o produto em si.

**O que aprendi**
- O prompt genérico tende a transformar fala em "tarefa de ação" (verbo + objeto). Em lista de compras o formato certo é substantivo puro.
- Duas camadas ajudam: instrução forte no prompt + limpeza local depois, porque o modelo às vezes insiste no verbo.
- Não dá para tratar todo ditado com grupo fixo como compras — só grupos com nome de lista, senão estrago lembretes em outros grupos (ex.: "Comprar ração pro Chico").

---

## Estado atual

**Branch ativa:** `redesign` (unificada com trabalho de 2026-06-20). Alterações locais **não commitadas**: limpeza automática, fix ditado/tags, modelo OpenRouter.

**App:** to-do com grupos, ditado por voz, etiquetas por grupo, lista particionada.

**Redesign (Eximium DS):** **concluído** (Fase 1 fundação + Fase 2 todas as telas). Dark é o padrão, com toggle de tema no Perfil. Tokens/primitivos em `lib/ui/theme/` e `lib/ui/widgets/eximium/`; todas as telas/sheets migradas para `context.ex`. **Rodar a partir da branch `redesign`.** Pendente de validação no telefone.

**Limpeza automática (novo, local):** botão **A** em grupos de supermercado — LLM categoriza itens sem tag, remove duplicados, bottom sheet de revisão antes de salvar. Requer `OPENROUTER_API_KEY` e recompilação com `secrets.json`.

**Ditado por voz:**
- Lembrete com data/hora (fluxo próprio).
- Supermercado/mercado/compras: título = nome do produto; tags só existentes (`tagExplicit=false`).
- Nota/melhoria (Melhorias, Bugs, narrativa longa): título `Área: problema` + descrição polida; tags explícitas permitidas.
- Confirmação editável antes de gravar (toggle no Perfil; padrão ON).
- Criação de tag/categoria só quando peço explicitamente na fala.

**Validar no telefone (pendente):** ditado em Melhorias com "cria tag Exm App"; preview + confirmar; compras e lembrete sem regressão; toggle OFF grava direto.

**Arquivos principais (voz):**
- `lib/business_logic/voice_extraction_plan.dart`
- `lib/business_logic/voice_note_capture_context.dart`
- `lib/business_logic/voice_intent_router.dart`
- `lib/constants/voice_task_extraction_prompt.dart`
- `lib/data/local/voice_capture_prefs.dart`
- `lib/data/services/voice_task_pipeline.dart`
- `lib/ui/widgets/voice_extraction_preview_sheet.dart`
- `lib/ui/widgets/voice_task_recording_sheet.dart`
