## Why

O carrossel de grupos na aba **Hoje** usa hoje `Dark Surface` (#121212) em todos os cards, com apenas uma faixa lateral na cor do grupo. Isso destoa do restante da UI (fundo claro, cards claros, gradientes premium) e **não aproveita** os campos já existentes no modelo de grupo (**cor** e **ícone**).

## What Changes

- Redesenhar os **cards horizontais** do rail de grupos para que o **fundo principal** reflita a cor do grupo (com tratamento de contraste), alinhado ao `openspec/style_guide.md`.
- Exibir o **ícone configurado** do grupo no card (mapeamento estável `icon` string → `IconData`).
- Garantir **texto branco / off-white** legível sobre **qualquer** cor escolhida pelo usuário no CRUD de grupo (paleta atual de swatches + hex livre no futuro): via **ajuste automático** (escurecer/clarear, gradiente scrim ou blend) até atingir contraste mínimo.
- **Complementar** `openspec/style_guide.md` com uma subseção documentando padrões dos **Group Rail Cards** (cores, tipografia sobre cor, progresso, ícone).

## Capabilities

### New Capabilities

- `hoje-group-rail-visual`: Aparência e acessibilidade visual dos mini-cards de grupo no rail da tela Hoje.

### Modified Capabilities

<!-- (vazio) -->

## Impact

- UI: `HomeScreen` (`_buildGroupProgressRail`) e/ou novo widget dedicado (ex.: `GroupRailCard`).
- Lógica: utilitário de cor/contraste reutilizável (ex.: `lib/ui/theme/` ou `lib/business_logic/`).
- Documentação: `openspec/style_guide.md`.
