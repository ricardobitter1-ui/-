## 1. Data Layer — Modelos

- [x] 1.1 Criar arquivo `lib/data/models/group_model.dart` com a classe `GroupModel` (campos: id, name, icon, color, ownerId, members, createdAt)
- [x] 1.2 Implementar `GroupModel.fromMap(String id, Map<String, dynamic> data)` com defaults defensivos para campos ausentes (icon: 'group', color: '#0052FF', members: [])
- [x] 1.3 Implementar `GroupModel.toMap()` sem o campo `id`, convertendo `createdAt` para `Timestamp`
- [x] 1.4 Implementar `GroupModel.copyWith({...})` com todos os parâmetros opcionais
- [x] 1.5 Adicionar `copyWith` em `TaskModel` (`lib/data/models/task_model.dart`) com suporte a limpeza de campos nullable (ex: `dueDate: null` deve resultar em `dueDate == null` na cópia)

## 2. Service Layer — CRUD de Grupos

- [ ] 2.1 Adicionar `CollectionReference get _groupsCollection` em `FirebaseService`
- [ ] 2.2 Implementar `Stream<List<GroupModel>> getGroupsStream()` usando `where('members', arrayContains: uid)`
- [ ] 2.3 Implementar `Future<void> addGroup(GroupModel group)` com injeção automática de `ownerId = uid` e `members = [uid]`, verificando autenticação
- [ ] 2.4 Implementar `Future<void> updateGroup(GroupModel group)` com validação `group.ownerId == uid` antes do update
- [ ] 2.5 Implementar `Future<void> deleteGroup(String groupId)` verificando autenticação

## 3. Service Layer — Streams Especializados de Tarefas

- [ ] 3.1 Implementar `Stream<List<TaskModel>> getAtemporalTasksStream()` com query `where('ownerId', isEqualTo: uid).where('dueDate', isNull: true)`
- [ ] 3.2 Implementar `Stream<List<TaskModel>> getScheduledTasksStream(DateTime date)` com range `[startOfDay, startOfNextDay)` usando `isGreaterThanOrEqualTo` / `isLessThan` no `dueDate`
- [ ] 3.3 Implementar `Stream<List<TaskModel>> getTasksByGroupStream(String groupId)` com query `where('groupId', isEqualTo: groupId)`
- [ ] 3.4 Garantir que os 3 novos streams retornam `Stream.value([])` quando `uid == null`

## 4. Business Logic Layer — Providers Riverpod

- [ ] 4.1 Criar `lib/business_logic/providers/group_provider.dart` com `groupsStreamProvider` como `StreamProvider<List<GroupModel>>`
- [ ] 4.2 Adicionar `atemporalTasksStreamProvider` em `task_provider.dart` como `StreamProvider<List<TaskModel>>`
- [ ] 4.3 Adicionar `scheduledTasksStreamProvider` em `task_provider.dart` como `StreamProvider.family<List<TaskModel>, DateTime>`
- [ ] 4.4 Adicionar `groupTasksStreamProvider` em `task_provider.dart` como `StreamProvider.family<List<TaskModel>, String>`
- [ ] 4.5 Confirmar que `tasksStreamProvider` existente não foi alterado (zero regressão)

## 5. Infraestrutura — Firestore Indexes

- [ ] 5.1 Acessar o Firebase Console → Firestore → Indexes e criar índice composto: collection `tasks`, campos `ownerId (ASC)` + `dueDate (ASC)`
- [ ] 5.2 Aguardar build do índice (pode levar alguns minutos) antes de testar `getScheduledTasksStream`

## 6. Validação

- [ ] 6.1 Criar um grupo via `addGroup` e verificar que aparece no `getGroupsStream()` em tempo real
- [ ] 6.2 Criar uma tarefa sem `dueDate` e confirmar que aparece em `getAtemporalTasksStream()` mas NÃO em `getScheduledTasksStream`
- [ ] 6.3 Criar uma tarefa com `dueDate` de hoje e confirmar que aparece em `getScheduledTasksStream(DateTime.now())` mas NÃO em `getAtemporalTasksStream()`
- [ ] 6.4 Criar uma tarefa com `groupId` e confirmar que aparece em `getTasksByGroupStream(groupId)`
- [ ] 6.5 Confirmar que o `HomeScreen` existente continua funcionando sem alterações (tasksStreamProvider inalterado)
- [ ] 6.6 Testar `updateGroup` como dono → deve suceder; como não-dono → deve lançar exception
