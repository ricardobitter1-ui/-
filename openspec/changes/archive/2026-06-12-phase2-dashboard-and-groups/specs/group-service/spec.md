## ADDED Requirements

### Requirement: CRUD completo de grupos no FirebaseService
O `FirebaseService` SHALL expor os seguintes métodos para grupos:
- `getGroupsStream()` → `Stream<List<GroupModel>>`: retorna apenas grupos onde `uid` está presente no array `members`.
- `addGroup(GroupModel group)` → `Future<void>`: persiste o grupo, adicionando `ownerId = uid` e `members = [uid]` automaticamente, ignorando os valores passados pelo cliente.
- `updateGroup(GroupModel group)` → `Future<void>`: atualiza documento pelo `id`. Somente o dono pode chamar (validação na camada de serviço: `group.ownerId == uid`).
- `deleteGroup(String groupId)` → `Future<void>`: deleta o documento.

#### Scenario: Listar grupos do usuário autenticado
- **WHEN** `getGroupsStream()` é chamado com `uid != null`
- **THEN** retorna stream de grupos onde o array `members` contém o uid do usuário

#### Scenario: Listar grupos sem autenticação
- **WHEN** `getGroupsStream()` é chamado com `uid == null`
- **THEN** retorna `Stream.value([])` imediatamente

#### Scenario: Criar grupo novo
- **WHEN** `addGroup(group)` é chamado com usuário autenticado
- **THEN** documento é criado na collection `groups` com `ownerId == uid` e `members == [uid]`

#### Scenario: Impedir criação sem autenticação
- **WHEN** `addGroup(group)` é chamado com `uid == null`
- **THEN** lança `Exception('Usuário não autenticado')`

#### Scenario: Atualizar grupo como dono
- **WHEN** `updateGroup(group)` é chamado e `group.ownerId == uid`
- **THEN** documento é atualizado com os novos dados

#### Scenario: Impedir atualização por não-dono
- **WHEN** `updateGroup(group)` é chamado e `group.ownerId != uid`
- **THEN** lança `Exception('Apenas o dono pode editar o grupo')`

#### Scenario: Deletar grupo existente
- **WHEN** `deleteGroup(groupId)` é chamado com `uid != null`
- **THEN** documento é removido da collection `groups`
