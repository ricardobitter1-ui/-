## Why

A navegação atual para a tela de grupos fica no canto superior e está quebrando o layout, gerando uma experiência inconsistente e menos intuitiva para alternar entre áreas principais do app.

## What Changes

- Adicionar uma **barra de navegação inferior (bottom navigation)** com 3 abas fixas: **Grupos**, **Calendário** e **Perfil**.
- Transformar a navegação principal em um fluxo por abas (preservando estado por aba quando possível).
- Garantir que a tela de **Grupos** seja renderizada dentro do layout padrão (Scaffold) e não “flutuando” no topo, corrigindo o problema de UI mostrado no print.

## Capabilities

### New Capabilities
- `bottom-nav`: Navegação inferior com 3 abas (Grupos/Calendário/Perfil) como ponto central de navegação do app.

### Modified Capabilities
<!-- (vazio) -->

## Impact

<!-- Affected code, APIs, dependencies, systems -->
- UI/Flutter: `Scaffold`, `BottomNavigationBar`/`NavigationBar`, rotas e gerenciamento de estado entre abas.
- Telas: `home_screen` (Calendário/Dashboard), `groups_screen`, nova tela de `profile`.
- Navegação: possíveis ajustes em rotas existentes (ex.: remoção/relocação do acesso “canto superior” para grupos).
