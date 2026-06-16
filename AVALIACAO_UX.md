# Avaliação de Usabilidade — Exm to do

**Data:** 11/06/2026 · **Método:** análise heurística do código-fonte (Flutter/Firebase) + benchmark de mercado
**Escopo:** página inicial, categorização de grupos, fluxo de criação (escrever/ditar), navegação e mensagens

---

## 1. Resumo executivo

O app tem uma base sólida: navegação simples de 3 abas, fluxo de voz com preview editável (acima da média do mercado), etiquetas, recorrência, lembrete por localização e colaboração por grupos. Os problemas centrais não são de "polimento", são de **modelo conceitual**: o app trata tudo como "tarefa com data", mas metade do uso real (lista de supermercado) é outra coisa — uma **lista contínua sem data**. Disso derivam quase todos os sintomas que você sentiu.

**Os 5 pontos mais importantes:**

1. **Grupos precisam de um tipo explícito.** Hoje o tipo "supermercado" é inferido por regex no nome do grupo (`voice_shopping_list_context.dart`) — uma heurística oculta e frágil. Criar o campo `type` no `GroupModel`, com comportamentos derivados de *flags* (e não hardcode por tipo), resolve isso de forma escalável. → seção 4.B

2. **Atrasadas devem aparecer na home, não atrás de um card.** Você mesmo sentiu isso, e é o padrão consagrado (Things 3 e Todoist mostram atrasadas dentro da visão "Hoje", destacadas em vermelho). → seção 4.A

3. **O card "Todas" mistura conceitos** — conta itens de supermercado e tarefas concluídas junto com tarefas reais. O número não significa nada e infla a sensação de pendência. → seção 4.A

4. **Lista contínua precisa de "recompra com 1 toque".** No supermercado, item comprado não é tarefa morta: é item que volta. O padrão do Bring! ("recently used" em tiles re-adicionáveis) é a referência ideal. → seção 4.B

5. **Criar tarefa exige 2 toques e uma decisão prévia** (Escrever vs Ditar). Reduzir para 1 toque: FAB abre direto o formulário (que já foca o título) com mic embutido; long-press no FAB inicia o ditado. → seção 4.C

**Sequência sugerida:** correções rápidas na home (fase 1) → tipo de grupo + comportamento de lista contínua (fase 2) → fluxo de entrada (fase 3) → notificações de atribuição/menção via FCM (fase 4 — é o coração do caso de uso original e ainda não está ativo). Detalhe na seção 6.

---

## 2. Como o app está hoje (mapa rápido)

- **Shell:** 3 abas — Grupos · Início (padrão) · Perfil (`main_shell.dart`).
- **Início:** saudação + grid 2×2 de cards (Hoje, Agendadas, Todas, Atrasadas) + lista "Próximas tarefas" (até 5 de hoje, até 5 de amanhã) + FAB expansível (`home_screen.dart`).
- **Cards → `FilteredTaskListScreen`:** "Hoje" mostra timeline de calendário navegável; os outros, listas simples.
- **Grupos:** cards com cor/ícone, contagem "X tarefas · Y concluídas" e barra de progresso. Detalhe do grupo: lista seccionada por etiqueta, membros, convites por e-mail/link, gestão de etiquetas.
- **Criação:** FAB → "Escrever" (modal com título, descrição, grupo, etiquetas, responsáveis, agendamento/recorrência/local) ou "Ditar" (grava → transcreve via Groq → extrai tarefas via LLM → preview editável → confirma).
- **Modelo de dados:** `GroupModel` não tem tipo/categoria; `TaskModel` cobre data/hora, recorrência, geofence, responsáveis e etiquetas.
- **Pendente:** notificações de atribuição entre membros (FCM) ainda não funcionam.

---

## 3. O que já está bom (manter)

- **Preview editável do ditado antes de salvar** — confirmação antes de ação é a recomendação nº 1 de guias de voice UI. Poucos apps fazem isso bem.
- **Adaptação do ditado ao contexto do grupo** (títulos viram itens de compra em grupo de supermercado) — a ideia é ótima; só o mecanismo de detecção (regex no nome) precisa mudar.
- **Undo ao apagar tarefa** via snackbar.
- **Estados vazios** com ilustração, mensagem e ação ("Ver tarefas agendadas").
- **Aba padrão = Início**, lembrete em contexto dentro do formulário, etiquetas com cor por grupo.

---

## 4. Achados detalhados

Severidade: 🔴 alta (compromete o uso) · 🟡 média (gera fricção/confusão) · ⚪ baixa (polimento).

### A. Página inicial

**A1 🔴 Tarefas atrasadas escondidas atrás de um card.**
Hoje a home lista só "hoje" e "amanhã"; atrasadas exigem perceber o número no card rosa e tocar nele. Atrasada é a informação mais urgente da tela — é exatamente o que não pode depender de um toque extra.
*Referência:* Things 3 mostra atrasadas dentro de Hoje com bandeira vermelha; Todoist idem, com ação de reagendar em lote.
*Recomendação:* seção "Atrasadas (N)" no topo de "Próximas tarefas", com acento vermelho e ação "Reagendar todas" (para amanhã / escolher data). O card pode até sumir.

**A2 🔴 Card "Todas" conta tudo, inclusive supermercado e concluídas.**
`allCount: allTasks.length` usa o stream completo (`tasksStreamProvider`): cada item de compra já comprado, cada tarefa concluída antiga, tudo vira "Todas: 247". O número não orienta nenhuma decisão e cria ansiedade visual.
*Recomendação:* curto prazo, contar só tarefas ativas e excluir grupos de lista contínua. Médio prazo, repensar se "Todas" merece um quadrante (ver A5) — talvez virar busca.

**A3 🟡 Números dos cards não batem com as listas.**
O card "Hoje" conta tarefas visíveis no dia *incluindo concluídas* (`todayTasks.length`), mas a lista "Próximas tarefas" mostra só ativas (`todayActive`). O usuário vê "Hoje: 8" e 3 itens na lista. Inconsistência mina a confiança no sistema (heurística de consistência, NN/g).
*Recomendação:* todo número visível = tarefas *pendentes* daquele recorte.

**A4 🟡 Card "Hoje" abre um navegador de calendário.**
O rótulo promete "as tarefas de hoje", mas a tela traz uma timeline para navegar entre dias. É útil — mas é outra coisa (uma visão "Agenda"). O descompasso rótulo↔conteúdo é a confusão que você relatou.
*Recomendação:* separar conceitos. "Hoje" já é a lista da home (ver A5); a timeline vira uma visão "Calendário/Agenda" própria, acessível por ícone no topo da home ou fundida com "Agendadas".

**A5 🟡 O grid 2×2 duplica a própria home.**
"Hoje" no card = a lista logo abaixo. Na prática só "Agendadas" leva a conteúdo que não está na tela. O grid ocupa ~30% da tela acima da dobra para repetir informação.
*Recomendação (nova hierarquia da home):*
1. Header compacto (saudação + ícone calendário + avatar→perfil)
2. **Atrasadas** (se houver, em destaque)
3. **Hoje** (lista completa, com concluídas colapsadas no fim)
4. **Amanhã** (prévia)
5. Chips/linha compacta: Agendadas · Calendário (em vez do grid 2×2)
Resultado: a primeira tela responde "o que eu preciso fazer agora?" sem nenhum toque.

**A6 ⚪ Logout direto no header da home.**
Ícone de sair sem confirmação, na posição mais nobre da tela. Ação destrutiva e raríssima não merece esse lugar.
*Recomendação:* mover para a aba Perfil (já existe) com confirmação.

**A7 ⚪ Pedido de permissão bloqueante na primeira abertura.**
Sheet `isDismissible: false` antes de o usuário ver qualquer valor. Pedidos em contexto têm aceitação muito maior.
*Recomendação:* pedir permissão de notificação no momento em que o usuário cria o primeiro lembrete (já há um gancho natural no formulário).

### B. Grupos e categorização (seu ponto nº 1)

**B1 🔴 Não existe tipo de grupo — e o app já precisa dele.**
`GroupModel` só tem nome/ícone/cor/membros. A prova de que o tipo é necessário: `VoiceShoppingListContext` detecta "grupo de compras" por regex no nome (supermercado|mercado|compras|feira|...). Isso quebra com "Padaria", "Costco", nomes em inglês, e é invisível/inexplicável para o usuário.
*Recomendação — modelo escalável:* adicionar `type` ao `GroupModel`, escolhido na criação via templates, onde **o tipo define um conjunto de flags de comportamento** (em vez de `if (type == 'shopping')` espalhado pelo código):

| Flag | Tarefas (padrão) | Lista contínua (compras) | Projeto | Rotina/hábitos |
|---|---|---|---|---|
| `continuous` (itens voltam) | não | **sim** | não | sim (por recorrência) |
| `defaultDueDate` | opcional | **nunca** | opcional | recorrente |
| `countsInHome` (Hoje/Todas) | sim | **não** | sim | sim |
| `completionLabel` | "Concluídas" | **"Comprados"** | "Concluídas" | "Feitos hoje" |
| `progressCard` (barra no card) | sim | **não — "N itens a comprar"** | sim + prazo | streak |
| `voiceMode` | tarefas | **itens** | tarefas | tarefas |
| `reAdd` (recompra 1 toque) | não | **sim** | não | — |

Novos tipos futuros (ex.: "Viagem/checklist", "Filmes para ver") viram só uma nova combinação de flags — é isso que torna escalável. A UI de criação vira: "Que tipo de lista é essa?" com 3–4 templates ilustrados + "Personalizada".

**B2 🔴 Item comprado morre; recomprar exige recriar.**
Numa lista contínua, concluir ≠ encerrar: é "comprei, e em breve preciso de novo". Hoje o item vai para "Concluídas" para sempre.
*Referência:* Bring! — abaixo da lista ativa há a seção "recently used": tiles dos itens já comprados, re-adicionáveis com 1 toque. AnyList tem "favoritos/itens recorrentes" para a compra semanal.
*Recomendação:* em grupos `continuous`, a seção de concluídas vira **"Comprados recentemente"** em grade de chips/tiles — tocar devolve o item à lista. Ordenar por frequência de recompra. (Os dados já existem: são as tarefas concluídas do grupo.)

**B3 🟡 Card do grupo com semântica errada para lista contínua.**
"32 tarefas · 28 concluídas" + barra de progresso não significa nada num supermercado — o progresso nunca converge e as concluídas acumulam para sempre.
*Recomendação:* por tipo — card de compras mostra "4 itens para comprar"; card de projeto mantém progresso; card de rotina pode mostrar o dia ("3 de 5 hoje").

**B4 🟡 Itens de lista contínua vazam para contagens globais.**
Causa direta do A2. A flag `countsInHome` resolve na origem.

**B5 ⚪ Fluxo "Copiar link de convite" invertido.**
Copiar link exige antes criar um convite por e-mail ("Crie um convite por e-mail primeiro..."). O modelo mental dominante (WhatsApp) é: gerar link → compartilhar.
*Recomendação:* "Convidar" gera link direto; e-mail vira opcional.

### C. Criação de tarefas (escrever + ditar)

**C1 🟡 Decisão prévia "Escrever vs Ditar" a cada criação.**
O FAB expansível custa: toque → ler 2 pills → escolher → toque. Para a ação mais frequente do app, isso é caro. Você disse que usa muito o ditado — mas o overlay pune os dois caminhos igualmente.
*Referências:* Todoist — tap abre o quick add com o teclado pronto e o mic dentro do campo; Google Keep — barra com atalhos diretos.
*Recomendação:* **tap no FAB → abre direto o `TaskFormModal`** (que já auto-foca o título) com **botão de mic dentro do campo de título** disparando o fluxo de ditado; **long-press no FAB → ditar direto** (atalho para o seu uso pesado). Ambos os fluxos caem para 1 gesto. O FAB já é estilo Google Agenda — o long-press é coerente com a família.

**C2 ✅ Preview do ditado: manter e refinar.**
O pipeline gravar → transcrever → extrair → revisar → confirmar segue as melhores práticas de VUI (confirmação antes de ação, correção fácil). Refinos:
- **Feedback de etapa** durante o processamento ("Transcrevendo…" → "Identificando tarefas…") — espera percebida cai muito quando o usuário vê progresso.
- Mostrar a **transcrição bruta** no preview (colapsada) — ajuda a entender por que a extração veio errada e dá confiança.
- No preview, deixar **trocar o grupo de destino** de cada tarefa (hoje o contexto resolve, mas errar grupo no ditado é comum).

**C3 🟡 Gravação inicia sozinha ao abrir o sheet.**
Bom para velocidade, mas se o toque foi acidental o usuário já está gravando. Aceitável **se** o estado for inequívoco (waveform já ajuda) e cancelar for um toque óbvio. Validar com uso real; alternativa: iniciar só após o sheet assentar + haptic.

**C4 ⚪ Para grupos de compras, ditado deveria pular o formulário de "tarefa".**
Com o tipo de grupo (B1), o ditado em contexto de compras pode usar um preview simplificado (só itens + quantidade), sem campos de data/responsável que não fazem sentido ali.

### D. Outros achados

**D1 🟡 Fricção dupla ao apagar: dialog + undo.**
Material Design recomenda *ou* confirmação *ou* undo — os dois juntos punem o caso comum para proteger o caso raro. Como o undo já existe e funciona, remover o dialog (mantê-lo só para ações em lote ou apagar grupo).

**D2 ⚪ Mensagens com jargão de sistema.**
Ex.: "Esta série não tem ocorrência neste dia. Abra Hoje e selecione a data." · "Grupo inválido. Atualize e tente novamente." Falar a língua do usuário: "Essa tarefa não se repete neste dia. Toque no dia certo no calendário para concluí-la."

**D3 ⚪ Mistura pt-PT / pt-BR.**
"Gerir etiquetas", "A carregar…", "Guardar", "só para si" convivem com pt-BR. Padronizar (pt-BR, presumo) — inconsistência de idioma passa sensação de app não terminado.

**D4 ℹ️ Notificações de atribuição (FCM) — o coração do produto.**
O caso de uso fundador ("ela me atribui, eu recebo notificação") ainda não funciona. Nenhuma melhoria de UI substitui isso: é o que diferencia o app de qualquer lista local. Está como fase 4 no roadmap só por dependência técnica — em valor, é nº 1.

---

## 5. Referências de mercado (o que copiar de quem)

| App / fonte | O que aprender |
|---|---|
| **Things 3** | Atrasadas dentro de "Hoje" com destaque vermelho; estrutura Hoje/Em breve/A qualquer momento/Algum dia; transição suave de tarefas não feitas para o dia seguinte. |
| **Todoist** | Today view como tela única de decisão; reagendar atrasadas em lote ("Todoist Zero"); quick add com mic embutido e linguagem natural. |
| **Bring!** | O padrão definitivo de lista contínua: "recently used" como tiles re-adicionáveis; níveis de urgência por item; compartilhamento familiar simples. |
| **AnyList** | Favoritos/recorrentes para compra semanal; agrupamento por corredor/categoria. |
| **Guias de Voice UI** (Aufait UX, ParallelHQ) | Confirmação antes de executar; feedback multimodal; correção fácil; mostrar o que foi entendido. Seu preview já cumpre o essencial. |
| **Heurísticas de Nielsen (NN/g)** | As violações mapeadas aqui: visibilidade de status (A1), consistência (A3, D3), correspondência sistema↔mundo real (A4, B3, D2), prevenção vs. recuperação de erro (D1). |

---

## 6. Roadmap sugerido (impacto × esforço)

**Fase 1 — Correções rápidas na home (dias)**
Atrasadas inline no topo com "Reagendar todas" (A1) · corrigir contagens para "pendentes" (A3) · "Todas" sem concluídas/compras ou removido (A2) · logout → Perfil (A6) · remover dialog de apagar, manter undo (D1) · revisar textos (D2, D3).

**Fase 2 — Tipo de grupo (a mudança estrutural, ~1-2 semanas)**
Campo `type` + flags no `GroupModel` com migração (grupos existentes = "tarefas"; detectar compras pelo regex atual **uma vez** na migração e sugerir conversão) · templates na criação de grupo · comportamento lista contínua: "Comprados recentemente" com re-add (B2), card sem progresso (B3), fora das contagens da home (B4) · `VoiceShoppingListContext` passa a ler o `type` (B1).

**Fase 3 — Fluxo de entrada (~1 semana)**
FAB: tap → formulário com mic no campo de título; long-press → ditar (C1) · feedback de etapas no processamento do ditado + transcrição visível no preview (C2) · preview simplificado para compras (C4).

**Fase 4 — Colaboração de verdade**
FCM: notificação ao ser atribuído/mencionado (D4) · atividade do grupo ("Fulana adicionou 3 itens") · repensar visão Calendário/Agenda separada do rótulo "Hoje" (A4/A5).

**Como validar (barato e suficiente nesta fase):**
- Teste de corredor com 2–3 pessoas (a namorada primeiro): "adicione leite à lista do mercado", "veja o que está atrasado", "crie uma tarefa para mim para sábado" — cronometrar toques e anotar hesitações.
- Medir: toques até criar tarefa (meta: 1 gesto + digitação), % de criações por voz, % de itens recomprados via re-add (pós fase 2).
- Repetir o corredor após cada fase.

---

*Avaliação baseada na leitura do código em `lib/` (16,4 mil linhas) — telas, widgets, modelos e lógica de negócio — em 11/06/2026. Nenhuma alteração foi feita no código.*
