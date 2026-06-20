# Design: Colaboração em grupos com segurança no servidor

## Context

- Hoje: `GroupModel` com `ownerId` e `members`; `updateGroup` no cliente só verifica dono; não há `admins` separados, nem convites, nem `assigneeIds` em tarefas.
- Notificações: apenas locais no dispositivo do utilizador que agenda o lembrete.
- A proposta (`proposal.md`) fixa mitigações S1–S7; este documento escolhe padrões implementáveis.

## Goals / Non-Goals

**Goals:**

- Modelo de dados que as Firestore Rules consigam validar (ou que Functions administrem com regras mínimas).
- Fluxo de convite com aceite antes de aparecer em `members`.
- Tarefas de grupo com `assigneeIds` validados contra `members`.
- Push aos responsáveis via backend.

**Non-Goals:**

- UI final polida de cada ecrã (pode seguir em iterções).
- Geofencing ou lembretes por localização para assignees (mantém-se o comportamento atual onde aplicável).

## Decisions

### D1 — Membership: Rules-first vs Functions-first

**Decisão:** Preferir **Cloud Functions + Callable** para `inviteUser`, `acceptInvite`, `declineInvite`, `removeMember`, `updateGroupAdmins` na primeira versão que exige robustez máxima. **Alternativa** rules-only com transação convite+`arrayUnion` é viável mas propensa a edge cases (múltiplos admins, remoções, rebaixamento).

**Rationale:** Menos superfície de ataque nas rules; validação centralizada; mais fácil rate-limit e auditoria.

**Se Functions forem adiadas:** Implementar subconjunto rules-only documentado na spec `firestore-rules-collaboration` (aceite apenas `arrayUnion(self)` com convite `pending`).

### D2 — Estrutura de convites

**Decisão:** Subcoleção `groups/{groupId}/invites/{inviteId}` com campos: `invitedBy`, `inviteeUid` (opcional até aceitar), `inviteeEmailLower` (opcional), `status` (`pending` | `accepted` | `declined` | `revoked`), `tokenHash` ou token opaco para deep link (armazenar hash se o token for secreto), `createdAt`, `expiresAt`.

**Alternativa:** Coleção top-level `groupInvites` com `groupId` — melhor para queries “meus convites pendentes” por `inviteeUid == auth.uid`.

**Recomendação:** Coleção top-level `groupInvites/{id}` com índices `inviteeUid + status` para inbox do utilizador; `groupId` para admins listarem pendentes do grupo.

### D3 — Papéis no documento `groups`

**Decisão:** `admins: array<string>` com invariante `admins ⊆ members`, `ownerId in admins`. Criação do grupo: `members = [ownerId]`, `admins = [ownerId]`.

### D4 — Tarefas: `createdBy` e permissões de edição

**Decisão:** Adicionar `createdBy` em tarefas de grupo para auditoria e rules opcionais (“só criador ou admin pode apagar”). A spec `group-task-assignees` deve alinhar com o produto (membro apaga só próprias vs qualquer membro).

### D5 — Push e lembretes

**Decisão:** `users/{uid}/private/fcm` ou `users/{uid}/devices/{deviceId}` com tokens; **somente** Functions escrevem filas ou enviam FCM. `onWrite` em `tasks` dispara notificação de “nova tarefa” para assignees. Lembretes agendados: Cloud Scheduler + fila ou função agendada que consulta tarefas com `dueDate` próximo (detalhe de implementação na fase de build).

### D6 — Grupo pessoal

**Decisão:** Campo `isPersonal: true` no grupo; rules negam convites e fixam `members` ao dono.

## Risks / Trade-offs

| Risco | Mitigação |
|--------|-----------|
| Custos e complexidade de Functions | Começar com callables mínimas; rules estritas em leitura de tarefas/grupos sempre. |
| Rules difíceis de manter | Testes no emulator; spec com cenários obrigatórios. |
| Duplo lembrete (local + push) | UX: opcional desativar local para assignees que não são criador, ou documentar sobreposição. |

## Migration Plan

1. Adicionar campos `admins`, `isPersonal` com defaults nas rules (grupos antigos: tratar `admins` ausente como `[ownerId]` no cliente na primeira leitura + migração one-shot ou lazy write via Function).
2. Deploy das rules antes de expor UI de convites em produção.
3. Backfill opcional: marcar grupo “Pessoal” existente com `isPersonal: true`.

## Open Questions

- Transferência de **ownership** explícita vs só “sair do grupo”.
- Limite máximo de membros por grupo (produto + performance de rules com `get()`).
