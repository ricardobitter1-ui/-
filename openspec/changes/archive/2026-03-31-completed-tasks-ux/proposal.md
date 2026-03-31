## Why

Hoje, ao marcar uma tarefa como concluída na aba **Hoje** e no detalhe de grupo, ela permanece na mesma lista com riscado e estilo “concluída”, o que dilui o foco nas tarefas ativas. O roadmap (Fase 6) define que o produto deve priorizar um **agrupamento dedicado** às concluídas, com transição perceptível e acessível — alinhado à excelência visual e à clareza de uso sem mudar o modelo de dados de conclusão.

## What Changes

- **Lista (Hoje e detalhe de grupo):** separar visualmente tarefas **ativas** e **concluídas**; concluídas em bloco dedicado (ex.: ao final), com cabeçalho/seção **colapsável** (comportamento exato e persistência de “aberto/fechado” na spec).
- **Feedback ao concluir:** animação ou transição ao marcar como concluída (mover/realçar até o bloco de concluídas conforme design); respeitar **pref. de redução de movimento** do sistema.
- **Integração com tags (Fase 5):** **uma área geral de concluídas** com **chips** por etiqueta nos cartões concluídos e **filtro horizontal** (Todas + etiquetas em uso) na seção de concluídas — Hoje (inbox e dia, com chave composta grupo+tag) e detalhe de grupo (spec `completed-tasks-tag-chips-filter`).

## Capabilities

### New Capabilities

- `completed-tasks-grouping`: Onde e como as tarefas concluídas aparecem em relação às ativas (ordem, seção dedicada, colapso, estados vazios).
- `task-completion-feedback`: Animação/transição ao concluir e requisitos de acessibilidade (reduced motion, sem causar perda de foco indevida).
- `completed-tasks-tag-chips-filter`: Chips de etiqueta nos cartões da seção concluídas e filtro por etiqueta sem subseções por tag na lista ativa.

### Modified Capabilities

- *(Nenhuma alteração de requisitos em specs canônicas existentes em `openspec/specs/`; o escopo é UI/UX sobre o fluxo atual de `isCompleted`.)*

## Impact

- **Flutter:** `TaskCard`, telas que montam listas de tarefas (`home_screen`, `group_detail_screen`), possivelmente widgets de lista/seção compartilhados.
- **Dados / backend:** nenhuma mudança obrigatória de modelo Firestore para o MVP desta change (continua `isCompleted`); persistência de “seção expandida” pode ser local (spec decide).
- **Dependência de produto:** chips/filtro assumem o modelo `tagIds` + `groups/{id}/tags/` da change de tags (Fase 5).
