## ADDED Requirements

### Requirement: Main tab SHALL be renamed from Calendário
A aba principal da bottom navigation SHALL usar um rótulo que reflita visão diária (ex.: **Hoje** ou **Agenda**, conforme decisão fixada na implementação) e SHALL NOT exibir o rótulo “Calendário” após esta change.

#### Scenario: Bottom nav label updated
- **WHEN** o usuário autenticado visualiza a bottom navigation
- **THEN** o item da aba principal exibe o novo rótulo escolhido e permanece selecionável

### Requirement: Screen SHALL show tasks for the selected calendar day
A tela principal SHALL listar tarefas cujo `dueDate` corresponde ao **dia selecionado** no seletor de datas (comportamento de filtro por dia preservado).

#### Scenario: Change selected day updates list
- **WHEN** o usuário seleciona outro dia no date picker
- **THEN** a lista de tarefas exibida reflete apenas tarefas com data naquele dia

### Requirement: Screen SHALL expose undated tasks in a dedicated inbox section
A mesma tela SHALL exibir uma seção dedicada para tarefas **sem data** (`dueDate` nulo), distinta da lista filtrada por dia, para que o usuário consiga ver e agir sobre atemporais sem sair da aba.

#### Scenario: Undated tasks visible on main tab
- **WHEN** existem tarefas sem data pertencentes ao usuário
- **THEN** a seção de inbox exibe essas tarefas (ou estado vazio explícito quando não houver nenhuma)

### Requirement: Inbox section SHALL remain reachable without changing tabs
A seção de tarefas sem data SHALL permanecer acessível na mesma hierarquia de scroll da tela principal (ex.: rolagem vertical), sem exigir navegação para outra aba.

#### Scenario: Scroll reaches inbox
- **WHEN** o usuário rola a tela principal verticalmente
- **THEN** consegue alcançar a seção de tarefas sem data junto com o restante do conteúdo do dia
