## ADDED Requirements

### Requirement: Group rail cards SHALL use the group color as the primary surface
Cada card do carrossel horizontal na tela **Hoje** SHALL usar a cor do grupo (`GroupModel.color`) como base visual dominante do cartão, em vez de uma superfície fixa escura genérica (ex.: `#121212` em todo o card).

#### Scenario: Colored card per group
- **WHEN** o utilizador visualiza o rail com pelo menos um grupo
- **THEN** cada card apresenta fundo derivado da cor desse grupo de forma claramente perceptível

### Requirement: Cards SHALL display the group icon
Cada card SHALL exibir o ícone associado ao campo `GroupModel.icon`, com mapeamento estável para ícones da UI (com fallback definido para valores desconhecidos).

#### Scenario: Icon visible
- **WHEN** o grupo tem `icon` igual a um valor suportado pelo app
- **THEN** o card mostra o ícone correspondente de forma reconhecível

### Requirement: Primary label text SHALL be white and readable on all preset group colors
O nome do grupo e a hierarquia tipográfica principal no card SHALL usar texto branco (ou off-white documentado) e SHALL manter legibilidade para **todas** as opções de cor atualmente oferecidas ao criar/editar grupo (swatches existentes), após o algoritmo de normalização de contraste.

#### Scenario: Light group color
- **WHEN** a cor do grupo é uma tonalidade clara (alta luminância)
- **THEN** o sistema aplica ajuste (blend, escurecimento ou scrim) de forma que o texto branco permaneça legível

### Requirement: Progress indicator SHALL remain visible on the card background
A barra de progresso no card SHALL manter track e preenchimento distinguíveis do fundo colorido, seguindo as diretrizes documentadas no style guide para este componente.

#### Scenario: Progress on saturated background
- **WHEN** o utilizador vê o progresso do grupo no dia selecionado
- **THEN** a barra não se confunde com o fundo (contraste visual suficiente)

### Requirement: Style guide SHALL document Group Rail Card rules
O ficheiro `openspec/style_guide.md` SHALL ser atualizado com uma secção que descreva cores, contraste, ícone, tipografia e progresso dos cards do rail na aba Hoje.

#### Scenario: Guide updated
- **WHEN** a change é concluída
- **THEN** o style guide contém regras explícitas para **Group Rail Cards** alinhadas à implementação
