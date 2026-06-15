# Eximium Design System

> **Eximium Digital** — *Produtos digitais para negócios em evolução.*
> Version 1.0 · derived from the Eximium Dictate style guide + Eximium Digital brand manual.

Eximium Digital is a **digital-product creation studio / hub** ("empresa e hub de criação de produtos digitais"). It ships products under the `Eximium [ProductName]` naming pattern. The flagship — and the product this system is modelled on — is **Eximium Dictate**, a desktop voice-transcription app. The system is built to be reused across every future Eximium product with the brand staying constant and only product-specific surfaces changing.

This design system is a faithful re-authoring of the attached `eximium-design-system/` codebase into the compiler's structure (token CSS, React components, UI kit, specimen cards).

## Sources

The system was derived from a single attached codebase (read-only, mounted locally):

| Source file | What it gave us |
|-------------|-----------------|
| `eximium-design-system/EXIMIUM_DS.md` | Full brand + system spec (colors, type, spacing, components, principles, per-product adaptation) |
| `eximium-design-system/tokens.css` | The canonical CSS custom properties (dark + light) — split here into `tokens/*.css` |
| `eximium-design-system/EximiumUI.jsx` | React component library — split here into `components/<group>/` |
| `eximium-design-system/tailwind-preset.js` | Tailwind mapping of the same tokens (reference only) |
| `eximium-design-system/reference.html` | Living style guide (reference for the specimen cards) |

No Figma, decks, or external repos were provided. There is one product surface (Eximium Dictate); the system is otherwise product-agnostic.

---

## Brand identity

- **Company:** Eximium Digital
- **Tagline:** *Produtos digitais para negócios em evolução.*
- **Naming:** products are `Eximium [Product]` — "Eximium" in **bold**, the product name in light weight at `--ex-text-secondary` (e.g. **Eximium** Dictate).
- **Mark:** four stacked rounded-pill rectangles forming a stylised `≡` (viewBox `0 0 369 422`). Brand green on dark surfaces, white on colored/photographic fills. Files: `assets/eximium-mark.svg`, `assets/eximium-mark-white.svg`.

---

## CONTENT FUNDAMENTALS

How Eximium writes.

- **Language:** primary UI copy is **Brazilian Portuguese (pt-BR)**. Documentation/spec is bilingual (pt-BR prose, English token names).
- **Voice:** calm, competent, peer-level. It speaks *to* the user about *their* work, not about itself. Short imperative labels for actions ("Nova gravação", "Entrar", "Copiar", "Exportar"), plain descriptive nouns for places ("Histórico", "Biblioteca", "Configurações").
- **Person:** addresses the user informally as **você** ("Bem-vindo de volta", "Suas transcrições"). First-person plural ("a gente", "nós") appears only inside product *content* (e.g. transcript text), never in chrome.
- **Casing:** **Sentence case** everywhere for titles, buttons and body. The one exception is the **UPPERCASE micro-label** (11px/700, `letter-spacing: 0.08em`) used for field labels and section eyebrows ("EMAIL", "PASTAS", "TRANSCRIÇÃO"). Never Title Case headlines.
- **Tone words:** precise, light, unfussy. Avoids hype, exclamation marks, and marketing adjectives. "Plano Pro", not "Plano Profissional Premium 🚀".
- **Numbers & time:** monospaced (`Red Hat Mono`) for anything tabular or temporal — durations `14:32`, timestamps `2026-06-12 14:32:01`, counts. Localised (`2.480 palavras`, `pt-BR`).
- **Status language:** one or two words, often with a leading glyph — "● Gravando", "⟳ Processando", "Concluída", "Falhou", "Rascunho".
- **Emoji:** **not** part of the brand. Status uses simple unicode marks (●, ⟳, ✓) and stroke icons, not emoji.
- **Examples:**
  - Empty/primary CTA: *"Nova gravação"*
  - Auth: *"Bem-vindo de volta" / "Entre para acessar suas transcrições."*
  - Meta line: *"14:32 · 2.480 palavras · Hoje, 09:41"*
  - Upsell: *"Sincronizar na nuvem — Disponível no plano Pro."*

---

## VISUAL FOUNDATIONS

The look and feel, exhaustively.

### Color & chromatic ratio
- **~50% neutral** (near-black `#0A0A0A`→graphite in dark; off-white `#F9F9F9`→white in light), **~30% surface** (cards/panels), **~20% green** — and green is **accent only**.
- **Brand green `#6DE2C0`** is surgical: CTAs, active borders, icons, waveforms, focus rings, glows. **Never** a large fill/background. On light backgrounds, green *text* switches to `#1A9E85` (`--ex-brand-green-txt`) for WCAG AA.
- **Lavender `#7C82D6`** is the sparing secondary — informational badges, occasional accents only.
- Deep accent gradient `linear-gradient(135deg, #014751 → #6DE2C0)` for avatars, brand moments, hero fills — used rarely.

### Dual mode (first-class)
- **Dark is default**; light is a peer, never an afterthought. Toggled by `.dark`/`.light` on `<html>`, persisted to `localStorage["eximium-theme"]`, with an anti-flash inline script.
- **Three surface levels** in either mode: `surface-0` (window) → `surface-1` (cards) → `surface-2` (inputs/hover) → `surface-3` (borders). Hierarchy is by surface, not by heavy shadow.

### Type
- **Red Hat Display** for all UI; **Red Hat Mono** for code/time/counts. (Both shipped via Google Fonts — see Substitutions.)
- Weights: **300 Light** (secondary labels, product name), **400 Regular** (body), **500 Medium** (key caps), **700 Bold** (titles, CTAs, brand, important values).
- Scale: display 28 / h1 22 / h2 18 / h3 15 / body-lg 15 / body 13 / small 11. Display & h1 carry tight tracking `-0.02em`.

### Shape language
- **Rounded / capsule everywhere.** Radii: sm 6 (chips) · md 12 (inputs, tooltips) · lg 20 (cards, panels) · xl 32 (modals) · **pill 9999** (buttons, tags, toggles, scrollbar thumb). Buttons and badges are always full pills.

### Backgrounds
- Mostly **flat surfaces**. The only decoration is a **very subtle dual radial glow** behind app/auth backdrops (green at top-right ~6%, lavender at bottom-left ~5%). No photographic backgrounds, no patterns, no textures, no heavy gradients in chrome.

### Borders, cards & shadows
- **Cards:** `surface-1`, `1px` border (`--ex-border`), radius **20**, soft card shadow. Hover (for clickable cards) swaps the border to a **green accent** (`--ex-border-accent`) and lifts the shadow slightly. No colored left-border-only cards.
- **Shadows are restrained.** Dark: `0 2px 12px rgba(0,0,0,.4)`. Light: layered soft `0 1px 4px / 0 4px 16px` low-alpha. Float: `0 8px 32px`.
- **Glows** are green halos (`--ex-glow-sm/md/lg`) reserved for **active interactive elements only** — never decorative.

### Hover / press / focus states
- **Hover:** primary button → lighter green `#AEF7E4` + soft glow; ghost → 8% green wash; subtle → step up one surface; nav item → 4% white (dark) / 4% black (light) wash; card → green border accent.
- **Focus:** brand-green border + **`0 0 0 3px` green ring** (`--ex-focus-ring`); error focus uses the same ring in red.
- **Press:** state is communicated by color, not by scale — the system does **not** shrink/scale on press (the only scale animation is `ex-ring-in` for elements appearing).

### Transparency & blur
- Reserved for **floating, always-dark elements** (recording bar, overlays, toasts): `rgba(14,14,14,0.92)` + `backdrop-filter: blur(20px)`. These ignore the theme and stay dark on any background for maximum legibility, framed by a green border that intensifies (and pulses) when active.

### Motion
- **Subtle, fast, functional.** `150ms` (hover/color), `250ms` ease (default, theme), `400ms` (modals/sidebars).
- Keyframes: `ex-fade-up` (7px rise + fade, entrances), `ex-glow-pulse` / `ex-bar-pulse` (active recording/processing), `ex-ring-in` (appear), `ex-spin` (loader). No bouncy easings, no parallax, no looping decorative motion.

### Imagery
- The product is text/voice-first — there is **little to no photography**. When color imagery appears it leans **cool and calm** to sit beside the green. The brand gradient is the main "image."

### Layout
- App shell = fixed left **nav rail** (248px) + flexible main column. Desktop window chrome (traffic-light dots) on product surfaces. Sticky headers. Content max-widths (~640–760) keep reading lines comfortable. Custom thin pill scrollbar (8px) that turns green on `:active`.

### Eight principles (from the brand)
1. Dual mode native · 2. Green as surgical accent (~20%) · 3. Rounded/capsule language · 4. Hierarchy by surfaces · 5. Subtle motion (250ms) · 6. Red Hat Display throughout · 7. Floating elements always dark · 8. Green glows only on active interactive elements.

---

## ICONOGRAPHY

- **System:** a custom **Lucide-style** stroke set — 24px viewBox, `fill: none`, `stroke: currentColor`, `stroke-width: 1.7` at UI sizes, round caps/joins. Icons inherit text color and so adapt to theme automatically.
- **Delivery:** as **React components**, not a font or sprite — `Icons.<Name>` from `components/brand/Icon.jsx` (40+ glyphs: Mic, Stop, Waveform, Sparkle, Search, Settings, User, History, Layers, Book, Copy, Check, Clock, File, Command, Keyboard, Clipboard, Volume, Eye/EyeOff, Lock, Mail, Plus, X, Chevron/Arrow, More, Trash, Pencil, Refresh, Download, Upload, Tag, Bell, Home, Help, Logout, Message, Filter, ExternalLink). Build one-offs with the base `<Icon>`.
- **Color:** icons are usually `--ex-text-secondary`/`muted`; they go **brand-green** only when active/accented (focused input icon, waveform, active nav). Lavender for the occasional informational glyph (Sparkle/AI).
- **Brand mark:** the only "logo" asset — inline SVG (`assets/eximium-mark*.svg`) or the `Brand` component. Never redraw or recolor it arbitrarily.
- **Emoji & unicode:** emoji are **not** used. A few **unicode marks** stand in as status glyphs in copy (● recording, ⟳ processing, ✓ done) and keycaps (⌘ ⇧). Everything else is a stroke icon.
- **Substitution note:** the original set is bespoke Lucide-style paths; this system ships those exact paths inline (no CDN icon dependency). If you need a glyph that isn't included, match the Lucide stroke style (1.7 weight, round caps) or pull from [lucide.dev](https://lucide.dev).

### Font substitution
**None required.** Red Hat Display and Red Hat Mono are both official Google Fonts and are loaded from Google Fonts (the `@import` in `tokens/typography.css` carries the `@font-face` rules). If you need them self-hosted/offline, download from Google Fonts and add local `@font-face` rules — flag this to the design team if offline use is a requirement.

---

## Index / manifest

Root files:

| Path | What |
|------|------|
| `styles.css` | **Entry point** — `@import`s every token + base file. Consumers link this one file. |
| `tokens/typography.css` | Fonts (`@import` Google Fonts), families, type scale, weights, tracking |
| `tokens/colors.css` | Brand, status, dark + light surfaces/text/borders |
| `tokens/spacing.css` | Spacing scale + radius |
| `tokens/effects.css` | Glows, focus ring, transitions, gradients, theme shadows |
| `tokens/base.css` | Resets, scrollbar, keyframes, utility classes (`.ex-glow-hover`, `.ex-label`, `.ex-always-dark`, …) |
| `assets/` | `eximium-mark.svg`, `eximium-mark-white.svg` |
| `readme.md` | This guide |
| `SKILL.md` | Agent-Skills front-matter wrapper |

Components (`components/<group>/` — each `.jsx` + `.d.ts` + `.prompt.md`, one `.card.html` per group):

| Group | Components |
|-------|-----------|
| `brand/` | `Brand`, `Icon` (+ `Icons` set) |
| `buttons/` | `Button`, `ThemeToggle` |
| `forms/` | `Input`, `Toggle` |
| `feedback/` | `Badge`, `Spinner` |
| `surfaces/` | `Card`, `Kbd`, `Divider`, `PageHeader` |

Reach components at runtime via `window.EximiumDesignSystem_b4169c.<Name>` after loading `_ds_bundle.js`.

UI kits (`ui_kits/<product>/`):

| Kit | What |
|-----|------|
| `ui_kits/dictate/` | **Eximium Dictate** — interactive desktop transcription app (login → history → transcript → recording → settings). See its `README.md`. |

Foundation specimen cards live in `guidelines/*.card.html` (Colors, Type, Spacing, Brand) and render in the Design System tab.

---

## Using this system

**Plain HTML/CSS:**
```html
<link rel="stylesheet" href="styles.css">
<html class="dark"> … </html>
```

**With the components (in a card / page that loads the bundle):**
```html
<link rel="stylesheet" href="styles.css">
<script src="_ds_bundle.js"></script>
<script type="text/babel">
  const { Button, Card, Badge, Brand, Icons } = window.EximiumDesignSystem_b4169c;
</script>
```

Keep the brand constant; for a new Eximium product change only the product name and product-specific surfaces — never the surfaces, type, or the green-as-accent rule.
