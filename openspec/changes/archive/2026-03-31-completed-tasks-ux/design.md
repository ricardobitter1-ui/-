## Context

O app já persiste conclusão via `isCompleted` e `toggleTaskCompletion`. A UI atual (`TaskCard`) aplica riscado e estilo esmaecido **no mesmo índice da lista** nas telas da aba **Hoje** (inbox sem data e lista do dia) e no **detalhe do grupo**. A Fase 6 do roadmap pede um bloco dedicado às concluídas (tipicamente ao final), colapsável, com transição ao marcar como concluída e respeito a **reduced motion**. A integração com **tags** (Fase 5) fica deliberadamente em segunda fase nas tasks.

## Goals / Non-Goals

**Goals:**

- Particionar a lista apresentada em **ativas** e **concluídas**, mantendo ordem estável dentro de cada grupo (definir na spec se a ordem relativa entre itens concluídos segue a ordem de dados atual).
- Renderizar concluídas numa **seção dedicada** com cabeçalho claro e **colapso** (expandir/recolher).
- Ao alternar para concluída, dar **feedback visual** (ex.: animação de deslocamento, fade, ou realce curto) que comunique a mudança de contexto sem confundir.
- Quando o SO sinalizar redução de movimento, **não** executar animações decorativas longas ou deslocamentos chamativos; usar transição instantânea ou mínima equivalente em significado.

**Non-Goals:**

- Novo modelo Firestore ou Cloud Function só para “mover” tarefas concluídas.
- **Filtro por tag / chips nas concluídas** nesta entrega (depende da change de tags; ver tasks fase opcional).
- Alterar regras de quem pode concluir tarefa (permanece o comportamento atual).

## Decisions

1. **Partição no cliente** — Filtrar/particionar `List<TaskModel>` em `active` e `completed` onde as listas são montadas (ou num widget reutilizável), sem query extra no Firestore. *Racional:* `isCompleted` já existe; menos risco e deploy mais rápido.

2. **Seção ao final** — Concluídas aparecem **depois** das ativas em Hoje (inbox e dia) e no detalhe do grupo. *Alternativa considerada:* seção no topo — rejeitada pelo desejo de produto no roadmap (foco em ativas primeiro).

3. **Colapso** — Cabeçalho da seção com chevron ou equivalente; estado expandido/recolhido persistido com **`SharedPreferences`** (ou mecanismo já usado no app para prefs) por **chave composta** lógica (ex.: `completed_section_expanded_hoje` e `completed_section_expanded_group_{id}`) para não misturar contextos. *Alternativa:* sempre expandido — rejeitada; o roadmap pede colapsável.

4. **Animação** — Preferir **`SliverAnimatedList`** / `AnimatedList` **ou** `AnimatedSwitcher` + chave estável por `task.id` apenas na transição de conclusão, conforme complexidade da lista atual (CustomScrollView vs ListView). Se a lista for sliver-based, alinhar com padrão existente na tela. *Reduced motion:* consultar `MediaQuery.disableAnimationsOf(context)` ou `SchedulerBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations` e, se verdadeiro, duração zero ou troca imediata.

5. **Desmarcar conclusão** — Tratar simetricamente: tarefa volta ao bloco de ativas com feedback consistente (pode ser animação curta ou instantânea com reduced motion).

## Risks / Trade-offs

- **[Risco] Listas longas + animação** — Pode haver custo de frame ao animar muitos itens. *Mitigação:* animar só o item que mudou de estado; evitar rebuild completo desnecessário; testar em dispositivo médio.
- **[Risco] Duplicação de lógica** entre Hoje e grupo — *Mitigação:* extrair widget “lista de tarefas com seção de concluídas” ou mixin/helper de partição + seção, mantendo parâmetros (prefs key, callbacks).
- **[Trade-off] Persistência local do colapso** — Não sincroniza entre dispositivos; aceitável para preferência de UI.

## Migration Plan

- Deploy apenas de cliente; sem migração de dados. Rollback: reverter commit da UI.

## Open Questions

- Texto exato do cabeçalho (“Concluídas”, contagem, etc.) — definir na implementação alinhado ao design system.
- Se inbox “sem data” e lista do dia compartilham a mesma chave de colapso ou chaves separadas — a spec de agrupamento deve fixar um comportamento.
