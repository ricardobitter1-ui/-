## ADDED Requirements

### Requirement: Provider Riverpod para stream de grupos
O sistema SHALL expor `groupsStreamProvider` como `StreamProvider<List<GroupModel>>` em `lib/business_logic/providers/group_provider.dart`.

O provider SHALL observar `firebaseServiceProvider` via `ref.watch` para reagir automaticamente a mudanças no estado de autenticação (ex: logout limpa a lista de grupos).

#### Scenario: Usuário autenticado recebe lista de grupos em tempo real
- **WHEN** `ref.watch(groupsStreamProvider)` é chamado em um widget com usuário autenticado
- **THEN** o widget recebe `AsyncData<List<GroupModel>>` com os grupos do usuário, e é notificado de qualquer mudança no Firestore em tempo real

#### Scenario: Usuário não autenticado não recebe grupos
- **WHEN** `ref.watch(groupsStreamProvider)` é chamado em um widget com usuário deslogado
- **THEN** o widget recebe `AsyncData<[]>` (lista vazia, sem erros)

### Requirement: Providers para streams de tarefas especializados
O sistema SHALL expor os seguintes providers adicionais em `lib/business_logic/providers/task_provider.dart`:
- `atemporalTasksStreamProvider` → `StreamProvider<List<TaskModel>>`
- `scheduledTasksStreamProvider` → `StreamProvider.family<List<TaskModel>, DateTime>`
- `groupTasksStreamProvider` → `StreamProvider.family<List<TaskModel>, String>`

Estes providers NÃO devem substituir o `tasksStreamProvider` existente, que deve permanecer inalterado para compatibilidade com o `HomeScreen` atual.

#### Scenario: Consumir tarefas atemporais de forma reativa
- **WHEN** `ref.watch(atemporalTasksStreamProvider)` é chamado
- **THEN** retorna um `AsyncValue<List<TaskModel>>` com tarefas sem dueDate

#### Scenario: Consumir tarefas de uma data com family provider
- **WHEN** `ref.watch(scheduledTasksStreamProvider(DateTime.now()))` é chamado
- **THEN** retorna tarefas agendadas para hoje de forma reativa

#### Scenario: Consumir tarefas de um grupo com family provider
- **WHEN** `ref.watch(groupTasksStreamProvider('groupId'))` é chamado
- **THEN** retorna tarefas associadas ao grupo especificado
