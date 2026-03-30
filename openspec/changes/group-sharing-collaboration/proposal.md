# Proposal: Colaboração em grupos — convites, papéis, responsáveis e segurança

## Why

O app já tem grupos (`members`, `ownerId`) e tarefas com `groupId`, mas não há convites com aceite, papéis de admin além do dono, responsáveis por tarefa nem garantias no servidor. Sem **Firestore Security Rules** (e, onde necessário, **Cloud Functions** com Admin SDK), qualquer cliente pode contornar a UI e alterar `members`, roubar acesso a grupos ou atribuir tarefas a quem não é membro. Esta mudança entrega o fluxo de produto (CRUD social + responsáveis + notificações) com **mitigações explícitas** dos riscos de segurança.

## What Changes

- Modelo de **convites** (pendente → aceito/recusado) com entrada por busca no app, link e email; o utilizador **só entra em `members` após aceitar**.
- Papéis: **admins** (editar metadados do grupo, adicionar/remover pessoas, criar convites) vs **membros** (criar tarefas no grupo). O **owner** permanece como fonte de verdade para casos extremos (ex.: último admin).
- Tarefas em grupo com **`assigneeIds`** (subconjunto de membros); notificações aos responsáveis (nova tarefa + lembrete) via **push (FCM)** complementando lembretes locais.
- **`firestore.rules`** (e opcionalmente funções callable) alinhados ao modelo acima — **não** depender só da UI.
- Tratamento explícito de grupo **Pessoal** / default: sem convites ou colaboração.

## Security: risks and mitigations

Esta secção detalha **como** cada risco é endereçado na arquitetura alvo. A implementação concreta das rules e funções fica em `design.md` e nas specs; aqui ficam os compromissos e invariantes.

### S1 — Cliente malicioso altera `members` ou `admins` diretamente

**Risco:** Com rules permissivas ou ausentes, qualquer utilizador autenticado pode escrever `arrayUnion` em `members` e obter acesso a dados do grupo.

**Mitigação:**

1. **Invariante:** O documento `groups/{groupId}` **não** pode permitir que um utilizador acrescente a si próprio (ou a terceiros) a `members` sem um **convite válido** ou sem ser **admin** a convidar (conforme política escolhida).
2. **Abordagem recomendada (duas camadas, escolher uma como principal):**
   - **2a — Rules-only para aceite:** Permitir **apenas** `arrayUnion(request.auth.uid)` em `members` quando existir documento de convite `pending` cujo `inviteeUid` (ou email resolvido para o mesmo utilizador) corresponde a `request.auth.uid`, e numa mesma transação o cliente atualiza o convite para `accepted`. Todas as outras alterações a `members` e `admins` **negadas** no cliente.
   - **2b — Cloud Functions (Admin SDK):** Todas as alterações a `members` / `admins` passam por **callable functions** (`inviteUser`, `removeMember`, `acceptInvite`, `promoteAdmin`, etc.). O documento `groups/*` nas rules **não** permite escrita nesses campos pelo cliente. **Maior custo operacional, maior clareza e menos edge cases nas rules.**
3. **Remoção de membros e promoção/rebaixamento de admin:** Apenas **admins** (e regras especiais para **owner**), via mesma função ou rules com `get()` ao grupo e verificação de `request.auth.uid in resource.data.admins` (ou equivalente).

### S2 — Utilizador não membro lê ou escreve tarefas de um grupo

**Risco:** `tasks` com `groupId` visíveis ou editáveis por quem não está em `members`.

**Mitigação:**

- **Leitura:** `allow read` em `tasks/{taskId}` se `resource.data.groupId == null` e `resource.data.ownerId == request.auth.uid` **ou** se `groupId != null` e `request.auth.uid` está em `get(/databases/$(database)/documents/groups/$(groupId)).data.members`.
- **Criação:** `groupId == null` implica `ownerId == request.auth.uid`. Se `groupId` presente, exigir que `request.auth.uid` ∈ `members` do grupo e que `ownerId` (ou `createdBy`) seja o utilizador autenticado (ou outra regra explícita documentada).
- **Atualização / exclusão:** Definir se só o criador, todos os membros ou só admins podem apagar; a spec de tarefas em grupo **deve** fixar isso e as rules **devem** espelhar.

### S3 — `assigneeIds` com UIDs fora do grupo ou injeção de notificações

**Risco:** Criador da tarefa define responsáveis que não são membros; ou escreve em documentos de fila de notificação de outros utilizadores.

**Mitigação:**

- Nas **rules** de `create`/`update` de tarefa com `groupId`, exigir que **cada** entrada em `assigneeIds` (se presente) pertença a `members` do grupo (validação por função auxiliar em rules ou validação na Function se escrita for via backend).
- **Filas ou tokens FCM:** Utilizadores só podem **ler/escrever o próprio** documento `users/{uid}/fcmTokens/*` (ou equivalente). **Apenas** o backend (Cloud Function com Admin SDK) cria registos de “enviar push para utilizador X” em resposta a eventos de tarefa — o cliente **não** escreve notificações arbitrárias para terceiros.

### S4 — Convites abusivos (spam, enumeração de emails)

**Risco:** Admins criam convites em massa; atacantes enumeram utilizadores.

**Mitigação:**

- **Rate limiting** nas callables (por `uid` e por `groupId`) e/ou quotas de convites pendentes por grupo.
- **Tokens de link** opacos, com **expiração** e **revogação**; não expor listagens globais de utilizadores sem **opt-in** de descoberta no perfil (`allowSearch`, `displayName` indexado).
- Email: não revelar na UI se o email “existe” ou não quando possível (mensagem neutra).

### S5 — Grupo Pessoal / default tratado como colaborativo

**Risco:** Convites ou `assigneeIds` em grupo que deve ser só do utilizador.

**Mitigação:**

- Campo explícito `isPersonal` ou `isDefault` no documento do grupo; **rules** que **proíbem** subcoleção de convites, alteração de `members` (além do próprio dono singleton) e `groupId` em fluxos de equipa para esse tipo.
- Garantir que `_ensureDefaultGroup` e migrações marcam esse grupo de forma consistente.

### S6 — Regras complexas demais ou inconsistentes com a UI

**Risco:** Rules frágeis, difíceis de testar, divergentes do comportamento esperado.

**Mitigação:**

- **Suíte de testes** das Firestore Rules (Firebase emulator) cobrindo: membro vs não-membro, admin vs membro, aceite de convite, tarefa com assignees válidos/ inválidos, grupo pessoal.
- Documentar na spec `firestore-rules-collaboration` os casos obrigatórios; bloquear merge sem rules atualizadas quando o modelo de dados mudar.

### S7 — App Check / abuso de APIs públicas

**Risco:** Chamadas repetidas a callables de convite ou registo de token a partir de clientes não oficiais.

**Mitigação:**

- Ativar **Firebase App Check** para Firestore e para Functions quando as callables forem introduzidas; monitorização e quotas no console.

---

**Resumo:** A segurança assenta em **invariantes no servidor** (rules +, se necessário, Functions), **validação de membership em todas as leituras/escritas de tarefas de grupo**, **assignees ⊆ members**, **convite obrigatório antes de `members`**, e **push apenas pelo backend** para terceiros.

## Capabilities

### New Capabilities

- `firestore-rules-collaboration`: Requisitos normativos para Firestore Security Rules (grupos, convites, tarefas, tokens FCM).
- `group-invites`: Ciclo de vida do convite, aceite obrigatório, canais (busca, link, email) ao nível de comportamento.
- `group-roles`: Admins vs membros; quem pode editar grupo e gerir pessoas; owner.
- `group-task-assignees`: Campo `assigneeIds`, validação contra membros, regras de edição de tarefa em grupo.
- `assignee-push-notifications`: Eventos que disparam FCM aos responsáveis (criação e lembrete), sem o cliente escrever para terceiros.

### Modified Capabilities

- (Nenhuma spec em `openspec/specs/` além de `app_navigation.md` exige delta obrigatório para este escopo; comportamento de navegação pode ser tocado só na implementação.)

## Impact

- **`firestore.rules`**: Novo ou atualizado — crítico.
- **`lib/data/models/`**: `GroupModel`, `TaskModel`, modelos de convite.
- **`lib/data/services/firebase_service.dart`** (e/ou novos serviços): convites, papéis, assignees.
- **Cloud Functions** (projeto Firebase): recomendado para convites complexos, membership e FCM.
- **`flutter` / plugins**: `firebase_messaging`, possivelmente `cloud_functions`.
- **Índices Firestore** e, se aplicável, **extensão de email** ou provedor transacional.
