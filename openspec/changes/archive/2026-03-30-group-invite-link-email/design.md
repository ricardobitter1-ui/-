# Design: Convites — link + e-mail (**Firebase Spark**)

## Context

- Plano **Spark**: Firestore + Auth + alojamento do app; **sem** Cloud Functions.
- Convites atuais: muitas vezes `groupId_inviteeUid`; proposta Spark generaliza para docs com `shareToken` e/ou `inviteeEmailLower`.
- O **e-mail** do utilizador tem de existir no **JWT** do Auth (`request.auth.token.email`) para as rules filtrarem convites — utilizadores só com telefone ou provedores sem e-mail precisam de fluxo alternativo (fora de escopo ou mensagem na UI).

## Goals / Non-Goals

**Goals:**

- Link partilhável com token forte → app → modal → aceitar/recusar.
- Admin introduz e-mail → documento `pending` → convidado, **ao abrir ou retomar o app** já autenticado com esse e-mail, vê **de imediato o modal** de convite (mesmo componente que o deep link); **inbox** no perfil para reabrir ou ver lista se houver vários.
- Tudo implementável com **cliente + Firestore + rules** deployados no Spark.

**Non-Goals (esta fase):**

- E-mail transacional, FCM server-side para convites, Callable `getUserByEmail`, rate limit no servidor (apenas mitigações client-side / quotas Firestore).
- App Check, lembretes servidor assignees.

## Decisions

### D1 — Link

Manter recomendação: **custom scheme** primeiro (`exmtodo://invite?token=`), `intent-filter` Android, URL types iOS.

### D2 — Documento de convite

- **Por link:** campo `shareToken` único; query `where('shareToken', isEqualTo: token)` com `status == pending` (índice composto).
- **Por e-mail:** `inviteeEmailLower` normalizado; `inviteeUid` opcional/vazio até ao aceite (ou preenchido se no futuro houver Blaze).
- **ID do documento:** preferir **ID aleatório** Firestore para não expor UID no path; regras de `create` exigem `invitedBy`, `groupId`, etc.

### D3 — E-mail sem servidor (Spark)

- **Sem** resolver UID à criação: o convidado faz login com Google/e-mail; o cliente subscreve ou consulta `groupInvites` onde `inviteeEmailLower == auth.token.email.toLowerCase()` e `status == pending`.
- **Modal ao entrar na app:** após a árvore autenticada estar pronta (`AuthWrapper` / shell), se existir pelo menos um pendente, mostrar o **mesmo** sheet/modal que o deep link (aceitar/recusar). **Prioridade:** se houver deep link pendente na mesma sessão, resolver esse fluxo primeiro ou empilhar de forma definida na implementação. **Vários pendentes:** mostrar em sequência (ordenar por `createdAt` ascendente) até esgotar ou o utilizador fechar (detalhe UX: “mais tarde” pode adiar à inbox).
- **Rules:** `allow read` em convite se `resource.data.inviteeEmailLower == request.auth.token.email.lower()` **ou** (fluxo link) utilizador autenticado e token válido conforme política definida — cuidado para não permitir enumeração: leitura por `shareToken` deve exigir que o utilizador seja o convidado **ou** que o token seja apresentado e o utilizador coincida com `inviteeEmailLower` quando o convite foi “by email”, ou só permitir `get` após verificação. **Detalhe crítico na implementação:** para convite **só por link** sem e-mail, pode haver convite só com `shareToken` e sem `inviteeEmailLower`; qualquer utilizador autenticado que abre o link poderia aceitar — produto pode aceitar “link secreto” ou exigir e-mail no doc na criação. **Recomendação MVP Spark:** convites por link incluem opcionalmente `inviteeEmailLower` se o admin souber o e-mail; senão, link “aberto” é mais fraco — documentar na UI (“qualquer pessoa com o link pode aceitar se estiver logada”) **ou** obrigar e-mail também para link. **Proposta:** dois tipos: (1) convite **dirigido** (e-mail obrigatório, link opcional para cópia), (2) convite **só link** só para grupos de confiança — implementação escolhe (1) primeiro por segurança.

### D4 — Aceitar / recusar

Reutilizar lógica atual em dois passos se necessário: atualizar estado do convite + `arrayUnion` em `members`, coerente com rules existentes (`addedOnlySelfToMembers` + convite `accepted`).

### D5 — Rate limiting

Sem Functions: limitar no cliente (debounce) e opcionalmente contagem de pendentes por grupo nas rules (difícil); aceitar risco moderado em Spark ou documentar upgrade para Blaze.

## Risks / Trade-offs

| Risco | Mitigação |
|--------|-----------|
| Utilizador sem e-mail no token | Mensagem na UI; só login com e-mail |
| Link partilhado sem e-mail vinculado | Preferir convite dirigido por e-mail + link como atalho |
| Spam de convites | UX limites; Blaze depois com quota |

## Migration Plan

1. Novos campos nos docs; convites antigos por UID podem continuar a funcionar com compatibilidade no cliente.
2. Deploy rules antes de ativar UI nova.

## Extensão Blaze (futuro)

Quando o projeto passar a Blaze: Callable `createInviteByEmail`, `getUserByEmail`, FCM + e-mail no `onCreate` de `groupInvites`; manter o mesmo modelo de dados onde possível.
