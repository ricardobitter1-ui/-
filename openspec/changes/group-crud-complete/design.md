# Design: CRUD completo de grupos

## Context

- `updateGroup` já faz `update` só de `name`, `icon`, `color` e o cliente verifica `group.isAdmin(uid)`. As Firestore Rules já permitem `metadataOnlyGroupUpdate()` para admins.
- `deleteGroup` no cliente só permite `ownerId == uid`; as rules fazem `allow delete: if ... resource.data.ownerId == request.auth.uid`.
- Grupos com `isPersonal: true` (ex. "Pessoal") não devem ser apagados pelo utilizador através deste fluxo.

## Goals / Non-Goals

**Goals:**

- UI polida para **editar** nome, ícone e cor (reutilizar padrões de `CreateGroupSheet` onde fizer sentido).
- UI para **apagar** com diálogo de confirmação; executável por **dono ou qualquer admin** em grupos não pessoais.
- Rules e cliente alinhados na política de delete.

**Non-Goals:**

- Apagar tarefas do grupo em cascata no Firestore (sem Cloud Function batch). O MVP pode **deixar órfãs** tarefas com `groupId` antigo ou documentar limpeza manual — **decisão D2** abaixo.
- Transferência de ownership.
- Editar lista de membros através do mesmo sheet de “definições do grupo” (já existe convite/remover noutro sítio).

## Decisions

### D1 — Quem pode apagar

**Decisão:** Qualquer utilizador em `admins` pode apagar o documento `groups/{id}`, **e** o `ownerId` (sempre admin na invariante atual). **Negar** delete se `isPersonal == true`.

**Rationale:** Alinha com o roadmap (“criador e admins”) e equipas sem bloquear no único dono.

**Rules:** `allow delete: if signedIn() && resource.data.isPersonal != true && isGroupAdmin(groupId) && resource.data.ownerId == resource.data.ownerId` — na prática `isGroupAdmin` já implica membro; garantir que dono continua coberto.

Simplificar: `allow delete: if signedIn() && resource.data.get('isPersonal', false) != true && isGroupAdmin(groupId);`

### D2 — Tarefas ao apagar grupo

**Decisão (MVP):** Não implementar cascade delete. Ao apagar o grupo, as tarefas com esse `groupId` podem ficar; o utilizador deixa de ser membro e **não lê** essas tarefas pelas rules atuais (membro do grupo). Opcional: mostrar aviso na confirmação — “Tarefas deste grupo deixarão de ser acessíveis.”

**Alternativa futura:** Callable Function que apaga em batch ou move tarefas para inbox pessoal.

### D3 — Onde vive a ação “Editar / Apagar”

**Decisão:** Menu `AppBar` no `GroupDetailScreen` (ícone mais opções) com “Editar grupo” e “Apagar grupo”, condicionado a `isAdmin` e `!isPersonal` para apagar; editar metadados: admin pode editar até grupo pessoal **nome**? Roadmap diz editar nome — para **pessoal**, permitir só renomear visualmente ou bloquear: **bloquear edição de metadados para pessoal** simplifica (evita renomear “Pessoal” para confundir). **Exceção:** permitir editar cor/ícone do pessoal para UX — produto pode querer personalizar. **Proposta:** `isPersonal` → permitir **apenas** `name` opcional ou desabilitar todo o edit para pessoal. **MVP:** desabilitar **apagar** pessoal; **permitir editar** nome/cor/ícone do pessoal só para o dono (admin) para consistência com “meu espaço”.

**Refinamento:** Apagar: só `!isPersonal`. Editar: `isAdmin` sempre (inclui pessoal).

## Risks / Trade-offs

| Risco | Mitigação |
|--------|-----------|
| Órfãs `tasks` com `groupId` inválido | Aviso na UI; backlog Function de limpeza |
| Admin apaga grupo com outros membros | Confirmação explícita com texto forte |

## Migration Plan

1. Deploy `firestore.rules` antes de distribuir build com botão apagar para admins.
2. Utilizadores com app antigo: rules antigas podem ainda exigir só dono — sem breaking de dados.

## Open Questions

- Se o **último admin** não-dono remove a si próprio — fora de escopo desta change.
