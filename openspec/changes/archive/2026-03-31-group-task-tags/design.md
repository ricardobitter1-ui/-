# Design: Tags por grupo e agrupamento de tarefas

## Context

- Hoje as tarefas (`TaskModel` / `tasks` no Firestore) têm `groupId`, `assigneeIds`, etc., mas **não** têm categorização por tags.
- As regras já expõem `isGroupMember(gid)` e padrões similares para tarefas de grupo; devemos reutilizar o mesmo critério para **tags** escopadas ao grupo.
- O roadmap (Fase 5) exige tags **por grupo**, cor livre, múltiplas tags opcionais por tarefa, e **reuso** apenas como cópia de rótulo (nova entidade no grupo atual).

## Goals / Non-Goals

**Goals:**

- Persistir tags em Firestore de forma que **só membros do grupo** leiam/escrevam.
- Associar às tarefas de grupo uma lista opcional `tagIds` validada contra tags **daquele** `groupId`.
- UI de seleção com criação inline e sugestões a partir de **outros grupos do utilizador**.
- Lista no detalhe do grupo agrupada por tag + secção **Sem tag**.

**Non-Goals:**

- Tag global partilhada entre grupos (mesmo documento).
- Fase 6: secção exclusiva de concluídas e animações (pode coexistir depois).
- Cloud Functions obrigatórias para manutenção de integridade (pode ficar para iteração futura).

## Decisions

### 1. Onde vivem as tags no Firestore

**Decisão:** Subcoleção `groups/{groupId}/tags/{tagId}`.

**Rationale:** O path já fixa o `groupId`; as rules podem exigir `isGroupMember(groupId)` sem path extra. Evita coleção raiz `tags` com campo `groupId` duplicado e validação mais frágil.

**Alternativa considerada:** Coleção top-level `groupTags/{id}` com `groupId` — útil para queries globais, mas rules mais verbosas e risco de inconsistência.

### 2. Formato da cor

**Decisão:** Campo `color` como **inteiro de 32 bits** no mesmo sentido que `Color.value` do Flutter (`0xAARRGGBB`), documentado na spec.

**Rationale:** Tipagem simples no Firestore, serialização direta para `Color`.

**Alternativa:** String hex — mais parsing no cliente.

### 3. Limite de `tagIds` por tarefa (rules)

**Decisão:** Máximo **10** tags por tarefa, espelhando o padrão de `assigneeIds` nas rules (validação por tamanho e por pertença ao grupo via funções auxiliares).                                                

**Rationale:** Evita listas arbitrárias e mantém rules sem loops dinâmicos.

### 4. Unicidade do nome da tag

**Decisão:** **Não** exigir unicidade do rótulo por grupo no MVP (duas tags podem chamar-se "Verduras" com cores diferentes).

**Rationale:** Menos queries e conflitos; utilizador distingue por cor ou contexto.

### 5. Eliminação de tag

**Decisão:** Permitir **delete** do documento da tag por membro do grupo (conforme spec alinhada à proposta). O cliente **remove o `tagId` das tarefas** do grupo que o referenciam antes ou em seguida via batch no `FirebaseService` (listar tarefas do grupo já é padrão da app). Se alguma escrita falhar a meio, tarefas podem reter ids órfãos — a UI **ignora ids sem documento de tag** ao renderizar chips e agrupamentos.

**Rationale:** Evita lixo visual sem exigir Functions.

### 6. Sugestões “de outros grupos”

**Decisão:** No cliente, para o utilizador autenticado, iterar **grupos onde é membro** (exceto o atual) e carregar tags (streams ou get once ao abrir o picker). Mostrar rótulo + cor como preview; ao toque, **`addTag` no grupo atual** com novo `tagId` e mesmo `name`/`color` (utilizador pode editar cor antes de confirmar, opcional na spec de UI).

**Rationale:** Modelo A — nenhum `foreign key` entre grupos.

### 7. Agrupamento com múltiplas tags

**Decisão:** A mesma tarefa **aparece em cada secção** de tag correspondente. Secção **Sem tag** apenas se `tagIds` vazio ou só contiver ids órfãos após resolução.

**Rationale:** Alinhado à conversa de produto; mais claro do que escolher “tag primária”.

### 8. Tarefas pessoais / sem `groupId`

**Decisão:** `tagIds` **só aplicável** quando `groupId != null`; formulário não mostra seletor de tags fora de grupo; rules rejeitam `tagIds` não vazio se `groupId` ausente.

## Risks / Trade-offs

- **[Risco] Leituras extra** ao abrir sugestões (vários grupos) → **Mitigação:** carregar sob demanda (expander) ou cache em memória na sessão.
- **[Risco] Batch ao apagar tag** com muitas tarefas → **Mitigação:** batches de 500 (limite Firestore) no serviço; ou desativar delete até segunda fase (se a spec permitir apenas “arquivar” — ajustar na implementação conforme tasks).
- **[Risco] Índices** para queries novas → **Mitigação:** se a lista continuar a ser stream por `groupId` existente + resolução de tags em memória, pode não ser necessário índice composto novo.

## Migration Plan

1. Deploy **rules** e estrutura de dados (tags vazias OK).
2. Publicar app com `tagIds` opcional default `[]` / omitido — tarefas antigas sem campo tratadas como sem tags.
3. Não é obrigatório backfill de dados.

## Open Questions

- Editar **nome/cor** de tag existente: qualquer membro vs só criador (recomendação inicial: qualquer membro, alinhado à criação).
- Ordenação exata das secções (alfabética por nome vs ordem manual futura) — fechado como alfabética + “Sem tag” por último na spec, salvo revisão.
