## ADDED Requirements

### Requirement: Single focus card SHALL be replaced by a horizontal group rail
A tela principal SHALL NOT exibir o card único “Tarefa em Foco” como mecanismo principal de destaque. Em seu lugar SHALL existir uma faixa **horizontal com scroll** contendo **um card por grupo** do usuário.

#### Scenario: Horizontal rail is present
- **WHEN** o usuário visualiza a tela principal com pelo menos um grupo
- **THEN** aparece uma lista horizontal rolável com um card por grupo

#### Scenario: Empty groups
- **WHEN** o usuário não possui grupos
- **THEN** a faixa SHALL exibir estado vazio ou cópia orientando criação de grupo, sem quebrar o layout

### Requirement: Each group card SHALL show progress for the selected day
Cada card SHALL exibir o **progresso do grupo** calculado apenas com tarefas que possuem `groupId` igual ao grupo **e** `dueDate` no **mesmo dia** que o selecionado no date picker (razão concluídas/total ou equivalente visual).

#### Scenario: Progress matches selected day
- **WHEN** o usuário altera o dia selecionado no date picker
- **THEN** os indicadores de progresso nos cards de grupo atualizam para refletir apenas tarefas daquele dia naquele grupo

#### Scenario: No tasks for group on that day
- **WHEN** um grupo não tem tarefas com data no dia selecionado
- **THEN** o card SHALL exibir estado explícito de vazio ou progresso zero sem erro

### Requirement: Tapping a group card SHALL navigate to group detail
Ao tocar num card de grupo, o app SHALL navegar para a tela de detalhe daquele grupo (equivalente a abrir o grupo a partir da lista de grupos).

#### Scenario: Navigate to group
- **WHEN** o usuário toca no card de um grupo válido
- **THEN** o app exibe a tela de detalhe desse grupo
