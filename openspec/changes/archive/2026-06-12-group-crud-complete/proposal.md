# Proposal: CRUD completo de Grupos Elite (UI + regras)

## Why

O roadmap (Fase 2 e continuação da Fase 3) ainda lista **CRUD visual completo** como pendente: hoje existe **criação** de grupos e o `FirebaseService` já expõe `updateGroup` (metadados) e `deleteGroup` (apenas dono), mas **não há fluxo de produto** na UI para editar nome/cor/ícone nem para apagar com clareza de papéis. Além disso, o produto desejado é que **administradores** possam **eliminar** grupos colaborativos (não só o dono), alinhando com a gestão de equipa — isto exige **Firestore Rules** e cliente em sincronia. Grupos **pessoais** devem permanecer protegidos contra eliminação acidental.

## What Changes

- **UI:** Ecrã ou sheet de **edição** de grupo (nome, ícone, cor) acessível a partir do detalhe do grupo ou lista, visível apenas a **admins** (e bloqueado para `isPersonal` onde aplicável).
- **UI:** Fluxo de **eliminar grupo** (confirmação, mensagem de erro clara) para **dono ou admin**, com **proibição explícita** para grupo pessoal.
- **Serviço:** Ajustar `deleteGroup` para permitir **admin** (além do dono), mantendo validação de `isPersonal` e consistência com as rules.
- **Segurança:** Atualizar `firestore.rules` — `allow delete` em `groups/{id}` para **dono OU membro de `admins`**, exceto quando `isPersonal == true` (ninguém apaga via regra; ou só edge case documentado).
- **Deploy:** Republicar rules após alteração.

## Capabilities

### New Capabilities

- `elite-group-crud`: Comportamento de produto e requisitos para editar metadados do grupo, apagar grupo, papéis (dono/admin), e proteção do grupo pessoal.

### Modified Capabilities

- (Nenhuma spec em `openspec/specs/` além de navegação; requisitos novos ficam na spec desta change.)

## Impact

- `lib/ui/screens/group_detail_screen.dart`, possivelmente `groups_screen.dart`, novo widget sheet/modal de edição.
- `lib/data/services/firebase_service.dart` (`deleteGroup` e validações).
- `firestore.rules` (delete em `groups`).
- `firebase/README.md` ou nota de deploy se necessário.
- `openspec/roadmap.md` (marcar item CRUD quando a change for aplicada/arquivada).
