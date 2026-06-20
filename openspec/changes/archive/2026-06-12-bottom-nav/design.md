## Context

- Hoje o app oferece acesso à tela de grupos via um elemento no topo da UI. Esse padrão está interferindo no layout (overlap/posição indevida) e não escala bem conforme o app ganha mais áreas principais.
- Precisamos de um padrão de navegação previsível e “app padrão”: **bottom nav** com 3 destinos principais (Grupos, Calendário, Perfil).

## Goals / Non-Goals

**Goals:**
- Introduzir navegação principal via **bottom navigation** com 3 abas: Grupos / Calendário / Perfil.
- Corrigir o problema de layout da tela de grupos ao garantir renderização dentro de um `Scaffold` consistente.
- Manter boa UX ao alternar abas (preservar estado/scroll quando possível).

**Non-Goals:**
- Não alterar regras de negócio de tarefas, Firestore, autenticação ou modelo de dados.
- Não redesenhar os componentes visuais (apenas encaixar as telas no novo padrão).

## Decisions

- Usar um `Scaffold` raiz com `NavigationBar` (Material 3) ou `BottomNavigationBar` (Material 2) e um `IndexedStack` para preservar estado das abas.
  - Alternativas consideradas:
    - Rotas nomeadas + push/pop: simplifica deep-link, mas tende a perder estado ao trocar abas (a menos de controle extra).
    - `PageView`: pode conflitar com gestos e não é o padrão para bottom nav.
  - Racional: `IndexedStack` é o caminho mais simples para manter estado e evitar “rebuild” agressivo.

- Definir 3 telas destino:
  - **Grupos**: `GroupsScreen` (já existe)
  - **Calendário**: `HomeScreen`/dashboard atual (ou uma tela `CalendarScreen` se já existir no projeto)
  - **Perfil**: nova tela `ProfileScreen` (inicialmente simples, com avatar/nome e ações básicas)

- Migrar o acesso atual à tela de grupos (top action) para a aba **Grupos** e remover/neutralizar o elemento que causava o layout quebrado.

## Risks / Trade-offs

- [Estado por aba] → Mitigação: usar `IndexedStack` e manter `ScrollController`/state local por tela.
- [Inconsistência Material 2 vs 3] → Mitigação: escolher o componente alinhado ao `ThemeData` atual (se `useMaterial3` estiver ativo, preferir `NavigationBar`).
- [Telas com AppBar própria] → Mitigação: padronizar `Scaffold` por tela (cada aba gerencia sua `AppBar` internamente, sem sobreposição).
