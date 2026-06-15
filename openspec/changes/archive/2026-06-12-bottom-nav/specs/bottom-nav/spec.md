## ADDED Requirements

### Requirement: App MUST provide bottom navigation with three destinations
O app MUST exibir uma barra de navegação inferior persistente com exatamente 3 destinos principais: **Grupos**, **Calendário** e **Perfil**.

#### Scenario: Bottom nav visible and labeled
- **WHEN** o usuário abre a área principal do app após estar autenticado
- **THEN** o app exibe a bottom nav com 3 itens (Grupos, Calendário, Perfil) e um item está selecionado. 

### Requirement: Selecting a destination SHALL switch the visible screen
Ao selecionar um item da bottom nav, o app SHALL trocar a tela visível para o destino selecionado.

#### Scenario: Switch to Groups
- **WHEN** o usuário toca em **Grupos**
- **THEN** o app exibe a tela de grupos como conteúdo principal

#### Scenario: Switch to Calendar
- **WHEN** o usuário toca em **Calendário**
- **THEN** o app exibe a tela de calendário/dashboard como conteúdo principal

#### Scenario: Switch to Profile
- **WHEN** o usuário toca em **Perfil**
- **THEN** o app exibe a tela de perfil como conteúdo principal

### Requirement: The Groups screen MUST render inside the standard layout
A tela de **Grupos** MUST ser renderizada dentro de um layout padrão de tela (ex.: `Scaffold`/conteúdo principal), sem ficar “ancorada” no topo de forma a quebrar o layout.

#### Scenario: Groups layout is not clipped/overlapping
- **WHEN** o usuário navega para **Grupos**
- **THEN** o conteúdo de grupos é exibido com espaçamento e posicionamento corretos dentro do layout padrão

### Requirement: Tab state SHOULD be preserved when switching between destinations
Ao alternar entre destinos, o app SHOULD preservar o estado local das telas (ex.: scroll, seleção de dia), evitando recarregamentos desnecessários.

#### Scenario: Returning to a tab restores the previous state
- **WHEN** o usuário alterna de uma aba para outra e depois volta para a aba anterior
- **THEN** o app mantém o estado local da tela anterior sempre que possível
