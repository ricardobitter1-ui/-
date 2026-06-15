## ADDED Requirements

### Requirement: Stream de tarefas atemporais (sem dueDate)
O `FirebaseService` SHALL expor `getAtemporalTasksStream() → Stream<List<TaskModel>>` que retorna todas as tarefas do usuário onde `dueDate == null` (campo ausente ou nulo no Firestore), ordenadas por data de criação decrescente.

A query SHALL filtrar por `ownerId == uid` para garantir isolamento de dados entre usuários.

#### Scenario: Usuário tem tarefas sem data
- **WHEN** `getAtemporalTasksStream()` é chamado e existem tarefas com `dueDate == null` para o uid
- **THEN** o stream emite uma lista com essas tarefas, excluindo qualquer tarefa com `dueDate` definido

#### Scenario: Usuário não tem tarefas atemporais
- **WHEN** `getAtemporalTasksStream()` é chamado e todas as tarefas têm `dueDate` definido
- **THEN** o stream emite uma lista vazia `[]`

#### Scenario: Stream sem autenticação
- **WHEN** `getAtemporalTasksStream()` é chamado com `uid == null`
- **THEN** retorna `Stream.value([])` imediatamente sem consultar o Firestore

### Requirement: Stream de tarefas agendadas por data
O `FirebaseService` SHALL expor `getScheduledTasksStream(DateTime date) → Stream<List<TaskModel>>` que retorna tarefas do usuário cujo `dueDate` cai dentro do dia especificado (meia-noite do dia até 23:59:59.999 do mesmo dia).

A query SHALL usar `isGreaterThanOrEqualTo` e `isLessThan` no campo `dueDate`, combinado com filtro por `ownerId`.

**Nota de infraestrutura:** Esta query requer um índice composto Firestore em `tasks`: `ownerId (ASC) + dueDate (ASC)`. O índice deve ser criado manualmente no Console do Firebase antes de ativar este stream na UI.

#### Scenario: Buscar tarefas para uma data específica com tarefas
- **WHEN** `getScheduledTasksStream(DateTime(2026, 3, 28))` é chamado
- **THEN** o stream emite tarefas cujo `dueDate` está entre `2026-03-28T00:00:00` e `2026-03-28T23:59:59.999`

#### Scenario: Buscar tarefas para data sem tarefas agendadas
- **WHEN** `getScheduledTasksStream(date)` é chamado para dia sem tarefas
- **THEN** o stream emite `[]`

#### Scenario: Stream sem autenticação
- **WHEN** `getScheduledTasksStream(date)` é chamado com `uid == null`
- **THEN** retorna `Stream.value([])` imediatamente

### Requirement: Stream de tarefas filtrado por grupo
O `FirebaseService` SHALL expor `getTasksByGroupStream(String groupId) → Stream<List<TaskModel>>` que retorna todas as tarefas onde `groupId == groupId`, independente de `dueDate`.

#### Scenario: Buscar tarefas de um grupo existente
- **WHEN** `getTasksByGroupStream('grupo-abc')` é chamado com usuário autenticado
- **THEN** o stream emite todas as tarefas com `groupId == 'grupo-abc'`

#### Scenario: Grupo sem tarefas
- **WHEN** `getTasksByGroupStream(groupId)` é chamado para grupo sem tarefas
- **THEN** o stream emite `[]`
