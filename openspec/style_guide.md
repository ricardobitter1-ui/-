# Visual Style Guide: Premium Task App

Este documento serve como referência para a estética visual do app: cores, tipografia e padrões de UI.

## 1. Paleta de Cores (Theming)

### Ações e foco (marca)

- **Brand primary** `#5F6FCE` — Lavanda profunda, alinhada aos quadrantes pastel (`AppTheme.brandPrimary`). FAB, `ElevatedButton`, foco de `TextField`, `ColorScheme.primary`, ícones/labels selecionados na barra inferior.
- **Brand secondary** `#9B8AD4` — Roxo suave para gradientes com a marca (ex. cabeçalho de listas filtradas, avatar sem foto).

O azul elétrico `#0052FF` deixou de ser cor de produto; só aparece em dados legados (ex. migração de cores de grupo no Firestore).

### Quadrantes da home (summary cards)

Gradientes em `_DashboardTile` em `lib/ui/screens/home_screen.dart` — estilo pastel, texto branco sobre o gradiente:

| Card        | Gradiente (início → fim)   | Uso                          |
| ----------- | -------------------------- | ---------------------------- |
| Hoje        | `#7B8CDE` → `#9FAEE6`      | Tarefas com data para hoje   |
| Agendadas   | `#E8C547` → `#F0D86E`      | Outras datas futuras         |
| Todas       | `#7DCFB6` → `#A0DFCD`      | Inventário completo          |
| Atrasadas   | `#E8A0BF` → `#F0BDD4`      | Pendentes com prazo passado  |

Sombra: `gradient.first` com α ~0,25, blur ~12, offset Y 4.

### Cores de grupo (presets v2)

Os grupos usam **um hex sólido** (`GroupModel.color`), alinhado à mesma família pastel dos quadrantes. Lista canónica em `lib/constants/group_color_presets.dart` (`kGroupColorPresets`):

- `#7B8CDE` — lavanda (referência “Hoje”)
- `#9B8AD4` — roxo suave
- `#E8A0BF` — rosa/coral (referência “Atrasadas”)
- `#7DCFB6` — menta (referência “Todas”)
- `#E8C547` — âmbar (referência “Agendadas”)
- `#8B95B5` — ardósia / neutro frio
- `#A0DFCD` — menta claro
- `#F0D86E` — amarelo claro

Fallback quando o documento Firestore não tem `color`: `kDefaultGroupColorHex` (`#7B8CDE`). Cores antigas do picker v1 (`#0052FF`, `#5A189A`, etc.) são migradas uma vez por instalação para estes presets quando o utilizador é admin do grupo.

### Accent e sucesso (legado / detalhes)

- **Indigo forte** `#5A189A` — legado; gradientes de UI usam `brandPrimary` + `brandSecondary`.
- **Success Cyan** `#00F5D4` — preenchimento da barra de progresso nos **Group Rail Cards** e extremo do gradiente no indicador de progresso diário (`AppTheme.successCyan`).

### Tons neutros e superfícies

- **Background Light**: `#F8F9FF` — branco com gelo azulado.
- **Dark Surface**: `#121212` — focus cards escuros (não como fundo único do rail de grupos).
- **Texto títulos**: `#2B2D42`.
- **Soft Border**: `rgba(0, 0, 0, 0.05)`.

---

## 2. Tipografia (Typography)

- **Fonte global**: **Nunito** (`GoogleFonts.nunitoTextTheme` em `lib/ui/theme/app_theme.dart`) — forma arredondada e legível em UI densa.
- **Headings**: pesos 800/600, cor `#2B2D42`, letter spacing ~-1,0 onde aplicável.
- **Body**: cor `#6C757D`, ~16px; app bar título com Nunito bold ~24px.

---

## 3. Navegação inferior (Main shell)

Material 3 `NavigationBar` em `lib/ui/screens/main_shell.dart`:

- **Topo**: `ClipRRect` com raio 20px nos cantos superiores.
- **Superfície**: branco (`AppTheme.cardSurface`), `surfaceTintColor: transparent` na barra para evitar lavado azulado do M3.
- **Tema** (`navigationBarTheme` em `app_theme.dart`): indicador do item ativo com `brandPrimary` α ~0,14 e pill arredondado; ícone e rótulo selecionados em `brandPrimary`; não selecionados em cinza `#6C757D`; sombra discreta; `labelBehavior: alwaysShow`.

---

## 4. Elementos Visuais (UI Atoms)

### Formas (Shapes)

- **Standard Radius**: `24px` (cards, modais).
- **Hero Radius**: `32px`.
- **Pill**: `50px` (tags / status).

### Profundidade

- Sombras suaves, blur 20–30px, opacidade baixa (3–5%).
- **Glassmorphism**: blur ~10px, opacidade 70–80% em modais.

---

## 5. Iconografia e micro-interações

- Estilo: ícones Material **rounded** onde aplicável.
- Check e progresso: animações subtis e barras com cantos arredondados.

---

## 6. Group Rail Cards (aba Hoje)

Carrossel horizontal de mini-cards por grupo — fundo claro do app; **não** usar `#121212` como fundo único destes cards.

| Elemento      | Regra |
| ------------- | ----- |
| **Cor base**  | Hex do grupo (`GroupModel.color`). Parsing com `parseAppHexColor`; fallback `kDefaultGroupColorHex` se inválido. |
| **Contraste** | Se luminância alta, **lerp** em direção a `#2B2D42` até texto branco legível (`railCardSurfaceForWhiteText` em `color_utils.dart`). |
| **Gradiente** | `LinearGradient` topLeft → bottomRight: topo ~14% mix com branco; base = cor normalizada. |
| **Ícone**     | Círculo 40px, fundo branco α 18%, ícone branco α 95%. Chaves em `kGroupIconChoices` / `groupIconFromKey` (`lib/ui/theme/group_icon.dart`): `group`, `work`, `home`, `cottage`, `grocery`, `fitness_center`, `school`, `flight_takeoff`, `pets`, `restaurant`, `music_note`, `attach_money`; desconhecido → `groups_rounded`. |
| **Tipografia**| Nome: branco w800 ~15px, até 2 linhas. Estatísticas: branco α 72%, 12px, w600. |
| **Progresso** | Track: branco α 22%. Preenchimento: **Success Cyan** `#00F5D4`. |
| **Sombra**    | Preta α ~7%, blur ~18px, offset Y 6px. |
| **Raio**      | `20px` no card. |

Implementação: `lib/ui/widgets/group_rail_card.dart`, `lib/ui/theme/color_utils.dart`, `lib/ui/theme/group_icon.dart`.

---

## 7. Aplicação sugerida (layout)

```text
┌──────────────────────────┐
│ [Avatar]   [Notif Icon]  │  Header, fundo #F8F9FF
│                          │
│ Olá, …                   │  Título escuro #2B2D42
│                          │
│ [Hoje][Agendadas]        │  Quadrantes pastel (secção 1)
│ [Todas][Atrasadas]       │
│                          │
│ [Grupo A][ Grupo B ]     │  Cor sólida do grupo + ícone; texto branco (secção 5)
│                          │
│ [ Lista de tarefas… ]    │
└──────────────────────────┘
```
