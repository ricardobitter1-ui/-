# Spec: Premium UI Interactions

## ADDED Requirements

### Requirement: Daily Progress Calculation
O sistema deve calcular a porcentagem de tarefas concluídas especificamente para o dia atual (hoje).
- **GIVEN** 10 tarefas agendadas para hoje.
- **WHEN** 8 forem marcadas como concluídas.
- **THEN** O `DailyProgressIndicator` deve exibir 80%.

### Requirement: User Avatar Fallback
O avatar no cabeçalho deve ser resiliente à falta de foto de perfil.
#### Scenario: Usuário com Foto
- **WHEN** `user.photoURL` é válido.
- **THEN** Exibir a imagem circular do perfil.
#### Scenario: Usuário sem Foto
- **WHEN** `user.photoURL` é `null`.
- **THEN** Exibir a primeira letra do `displayName` (ex: "R" para Ricardo) em um fundo de cor acentuada.

### Requirement: Horizontal Date Selection
O seletor de data deve filtrar as tarefas exibidas na lista.
- **WHEN** O usuário seleciona o dia "22".
- **THEN** A lista de tarefas abaixo deve exibir apenas as tarefas cujo `dueDate` pertença ao dia 22.
