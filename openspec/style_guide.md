# 🎨 Visual Style Guide: Premium Task App

Este documento serve como a "estrela guia" para a estética visual do app, garantindo consistência em cores, tipografia e elementos de interface (UI).

## 1. Paleta de Cores (Theming)

A paleta transita entre o profissionalismo do Azul Royal e a sofisticação do Dark Mode pontual.

### 🔵 Cores Primárias (Ação & Foco)
- **Primary Blue**: `#0052FF` - Vibrante, moderno, usado para botões principais e charts.
- **Accent Indigo**: `#5A189A` - Tom de elegância, usado para categorias e detalhes.
- **Success Cyan**: `#00F5D4` - Usado para indicadores de 100% de conclusão.

### 🌑 Tons Neutros & Superfícies
- **Background Light**: `#F8F9FF` - Um branco com "gelo" azulado, muito mais limpo que o cinza padrão.
- **Dark Surface**: `#121212` - Para os "Focus Cards" (cards pretos de destaque).
- **Soft Border**: `rgba(0, 0, 0, 0.05)` - Bordas quase invisíveis para separação.

---

## 2. Tipografia (Typography)

Foco em hierarquia clara e leitura rápida.

- **Fonte Recomendada**: `Inter` ou `Outfit` (Google Fonts).
- **Headings**:
  - `Display` (Hello, User): Bold/ExtraBold, Letter spacing -1.0.
  - `Title`: SemiBold, Cor: `#2B2D42`.
- **Body**:
  - `Medium`: Regular, Cor: `#6C757D`, Linha: 1.5.
  - `Small`: Medium, Cor: `#A0AEC0` (para legendas e datas).

---

## 3. Elementos Visuais (UI Atoms)

A "assinatura" visual do app é baseada em curvas suaves e profundidade.

### 📐 Formas (Shapes)
- **Standard Radius**: `24px` (Cards, Modais).
- **Hero Radius**: `32px` (Elementos de cabeçalho ou FAB).
- **Pill Radius**: `50px` (Tags e indicadores de status).

### 🌫️ Profundidade & Efeitos
- **Soft Shadows**: Sombras largas com blur de 20px a 30px, mas opacidade baixíssima (3-5%).
- **Glassmorphism**: 
  - `BackdropFilter` com blur de 10px.
  - Opacidade de 70-80% em modais sobrepostos.
- **Gradients**:
  - Linear (Top to Bottom): `#0052FF` -> `#5A189A` (para cards de progresso).

---

## 4. Iconografia & Micro-interações

- **Style**: Line icons com cantos levemente arredondados (`Round` ou `Soft`).
- **Estados**:
  - **Check**: Quando marcado, o ícone deve "explodir" levemente (Scale animation) antes de mudar de cor.
  - **Progress**: Barras de progresso devem ter o preenchimento arredondado e brilho sutil.

---

## 5. Group Rail Cards (aba **Hoje**)

Carrossel horizontal de mini-cards por grupo — alinhado ao fundo claro do app; **não** usar `#121212` como fundo único destes cards.

| Elemento | Regra |
|----------|--------|
| **Cor base** | Hex do grupo (`GroupModel.color`). Parsing centralizado com fallback **Primary Blue** se inválido. |
| **Contraste** | Se a luminância relativa (WCAG sRGB) for alta (cor clara), fazer **lerp** em direção a `#2B2D42` até \(L \leq 0{,}40\), garantindo **texto branco** legível. |
| **Gradiente** | `LinearGradient` `topLeft` → `bottomRight`: topo com ~14% de mix com branco; base = cor normalizada. |
| **Ícone** | Círculo 40px, fundo branco **α 18%**, ícone branco **α 95%**. Mapear `group` / `work` / `home` / `fitness_center` / `school` → ícones Material `*_rounded`; fallback `groups_rounded`. |
| **Tipografia** | Nome: branco, **w800**, ~15px, até 2 linhas. Linha de estatísticas: branco **α 72%**, 12px, **w600**. |
| **Progresso** | Track: branco **α 22%**. Preenchimento: **Success Cyan** `#00F5D4` (regra única no rail). |
| **Sombra** | Preta **α 7%**, blur ~18px, offset Y 6px. |
| **Raio** | `20px` no card (alinhado ao rail atual). |

Implementação de referência: `lib/ui/widgets/group_rail_card.dart`, `lib/ui/theme/color_utils.dart`, `lib/ui/theme/group_icon.dart`.

---

## 📊 Aplicação Sugerida (Layout)

```text
┌──────────────────────────┐
│ [Avatar]   [Notif Icon]  │  <-- Header limpo, fundo #F8F9FF
│                          │
│ HELLO, OLIVIA            │  <-- Inter ExtraBold
│ [===== 80% =====]        │  <-- Gradiente Blue -> Indigo
│                          │
│ [Colored Group][ Group ] │  <-- Cor do grupo + ícone; texto branco (secção 5)
│                          │
│ [ Task list / Inbox... ] │
└──────────────────────────┘
```
