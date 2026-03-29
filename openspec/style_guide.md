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

## 📊 Aplicação Sugerida (Layout)

```text
┌──────────────────────────┐
│ [Avatar]   [Notif Icon]  │  <-- Header limpo, fundo #F8F9FF
│                          │
│ HELLO, OLIVIA            │  <-- Inter ExtraBold
│ [===== 80% =====]        │  <-- Gradiente Blue -> Indigo
│                          │
│ [ BLACK CARD - FOCUS ]   │  <-- #121212 com texto branco
│                          │
│ [ Group Card ] [ Group ] │  <-- White Cards com Soft Shadows
└──────────────────────────┘
```
