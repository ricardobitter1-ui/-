# Guia de Implementação — Redesign Exm ToDo (Eximium Design System em Flutter)

> Contrato compartilhado entre todos os agentes. **Leia este arquivo inteiro antes de tocar em qualquer código.**
> Fonte de verdade visual: `Redesign Exm ToDo/Exm to do - Eximium Redesign.dc.html` e os tokens em
> `Redesign Exm ToDo/_ds/eximium-design-system-b4169c89-e697-488c-8b40-0c57353921d9/tokens/*.css`.

## Regras de ouro (não negociáveis)

1. **NÃO mudar funcionalidade.** Só UI. Mesma lógica, mesmos providers, mesmos métodos, mesmos nomes de
   parâmetros, mesma navegação, mesmos serviços. Se um widget tem callbacks/estado, preserve-os 100%.
2. **Dark é o padrão.** Light é cidadão de primeira classe (par, não afterthought). Há um **toggle de tema**
   no Perfil. Implementado via `themeModeProvider` (Riverpod) + persistência em `shared_preferences`.
3. **Verde é acento cirúrgico (~20%).** Nunca preenchimento grande. CTAs, bordas ativas, ícones ativos, foco,
   glows, FAB. Em fundo claro, **texto verde** usa `#1A9E85` (já tratado pelo token `textAccent`).
4. **Nunca cores hardcoded** que dependam de tema. Sempre use `context.ex` (ExColors) e os helpers de tipo.
   Cores de marca invariantes (verde, lavanda, status) podem ser constantes.
5. **Linguagem cápsula/arredondada.** Botões/tags/toggles = pill (9999). Cards/painéis = 20. Inputs = 12.
   Modais/sheets = 32 no topo. Chips compactos = 6.
6. **Fonte:** Red Hat Display (UI) via `google_fonts`, Red Hat Mono (horários, contagens, timestamps).
7. **Movimento sutil:** 150ms hover/cor, 250ms padrão/tema, 400ms modais. Sem bounce, sem escala no press.
8. **Glows verdes só em elementos interativos ativos** — nunca decorativos.
9. PT-BR em toda a copy (já está). Não inventar textos novos; manter os existentes.
10. Rodar `flutter analyze` ao final de cada fase e corrigir erros/warnings introduzidos.

---

## 1. Tokens → Flutter (Fundação)

Crie os arquivos abaixo. **Estes nomes de API são contrato** — as telas dependem deles.

### `lib/ui/theme/eximium_colors.dart`
`class ExColors extends ThemeExtension<ExColors>` com os campos de superfície/texto/borda (variam por tema)
e constantes estáticas de marca (invariantes).

Campos de instância (variam dark/light):
```
surface0, surface1, surface2, surface3,
textPrimary, textSecondary, textMuted, textAccent,
border, borderAccent,
shadowCard (List<BoxShadow>), shadowFloat (List<BoxShadow>),
```

Valores **dark** (padrão):
| token | valor |
|---|---|
| surface0 | #0A0A0A |
| surface1 | #141414 |
| surface2 | #1E1E1E |
| surface3 | #2A2A2A |
| textPrimary | #FFFFFF |
| textSecondary | #999999 |
| textMuted | #666666 |
| textAccent | #6DE2C0 |
| border | #2A2A2A |
| borderAccent | rgba(109,226,192,.25) |
| shadowCard | 0 2px 12px rgba(0,0,0,.40) |
| shadowFloat | 0 8px 32px rgba(0,0,0,.60) |

Valores **light**:
| token | valor |
|---|---|
| surface0 | #F9F9F9 |
| surface1 | #FFFFFF |
| surface2 | #F3F3F3 |
| surface3 | #E8E8E8 |
| textPrimary | #111111 |
| textSecondary | #555555 |
| textMuted | #999999 |
| textAccent | #1A9E85 |
| border | #E5E5E5 |
| borderAccent | rgba(109,226,192,.60) |
| shadowCard | 0 1px 4px rgba(0,0,0,.08), 0 4px 16px rgba(0,0,0,.06) |
| shadowFloat | 0 8px 32px rgba(0,0,0,.15) |

Constantes de marca **invariantes** (static const):
```
brandGreen     = #6DE2C0   // acento primário
brandGreenLt   = #AEF7E4   // hover / glow suave
brandGreenDk   = #014751   // gradiente profundo
brandGreenTxt  = #1A9E85   // texto verde em fundo claro
lavender       = #7C82D6   // secundário / informativo
onBrandGreen   = #04201A   // texto/ícone sobre fill verde (ver mockup)
success=#6DE2C0  info=#7C82D6  error=#FF6B6B  warning=#FFC457   (dark)
// versões de TEXTO em light: success#1A9E85 info#5C63B8 error#CC4444 warning#A06010
successBg=rgba(success,.12) infoBg=... errorBg=... warningBg=...
gradientBrand = LinearGradient(135deg, [#014751, #6DE2C0])
```
Implemente `lerp`, `copyWith`, e expositores estáticos `ExColors.dark` / `ExColors.light`.

Helper de acesso (no mesmo arquivo):
```dart
extension ExColorsX on BuildContext {
  ExColors get ex => Theme.of(this).extension<ExColors>()!;
}
```

### `lib/ui/theme/eximium_typography.dart`
Use `google_fonts`. Família UI: `GoogleFonts.redHatDisplay`; mono: `GoogleFonts.redHatMono`.
Escala (todas as cores recebidas por parâmetro ou via tema):
| nome | size | weight | uso |
|---|---|---|---|
| display | 28 | 700 | nome do app, splash, títulos hero | tracking -0.02em |
| h1 | 22 | 700 | títulos de seção | tracking -0.02em |
| h2 | 18 | 700 | subtítulos de painel |
| h3 | 15 | 700 | rótulos de card |
| bodyLg | 15 | 400 | corpo principal |
| body | 13 | 400 | metadados, descrições |
| small | 11 | 300 | timestamps, footnotes |
| label | 11 | 700 | UPPERCASE, letterSpacing 0.08em |
| mono | (15/14/13/12) | 500 | horários/contagens — `GoogleFonts.redHatMono` |

Exponha como `ExText` com métodos estáticos, ex.: `ExText.display(color)`, `ExText.mono(size, color, weight)`.
**Importante:** registrar `GoogleFonts.redHatDisplayTextTheme` como textTheme base nos dois ThemeData.

### `lib/ui/theme/eximium_spacing.dart`
```
class ExSpace { static const s1=4, s2=8, s3=12, s4=16, s5=20, s6=24, s8=32, s12=48; }
class ExRadius { static const sm=6.0, md=12.0, lg=20.0, xl=32.0, pill=9999.0; }
```

### `lib/ui/theme/eximium_effects.dart`
Helpers de glow (List<BoxShadow>) com verde:
```
glowSm = 0 0 12px rgba(green,.20)
glowMd = 0 0 20px rgba(green,.30)
glowLg = 0 0 40px rgba(green,.45)
focusRing = 0 0 0 3px rgba(green,.12)   // usar como Border/box em inputs focados
```
Background do app (radial glow duplo, sutil) como widget/decoration reutilizável `ExAppBackground`
(verde top-right ~6%, lavanda bottom-left ~5%) sobre `surface0`. Usado nos Scaffolds principais e no login.

### `lib/ui/theme/app_theme.dart` (reescrever)
- `static ThemeData darkTheme` e `static ThemeData lightTheme`, ambos Material3, com:
  - `extensions: [ExColors.dark / ExColors.light]`
  - `scaffoldBackgroundColor: surface0`
  - `textTheme` = Red Hat Display
  - `colorScheme`: primary = brandGreen, error = error, surface = surface1, brightness correta
  - AppBar transparente/sem elevação, título h1.
  - Input/elevatedButton themes alinhados (radius pill p/ botões, 12 p/ inputs).
- **Manter** `AppTheme.brandPrimary` como alias deprecado **apontando para `brandGreen`** para não quebrar
  imports existentes durante a migração (remova usos gradualmente). Idem `cardSurface`, `backgroundLight`
  podem virar getters de compat se necessário — prefira migrar os call-sites.

### `lib/ui/theme/theme_mode_provider.dart`
- `themeModeProvider` = `NotifierProvider<ThemeModeNotifier, ThemeMode>` default `ThemeMode.dark`.
- Persistir em `shared_preferences` chave `eximium-theme` ('dark'/'light'). Carregar no init.
- Método `toggle()` e `set(ThemeMode)`.

### `lib/main.dart` (ajustar)
`MyApp` vira `ConsumerWidget`; `MaterialApp(theme: AppTheme.lightTheme, darkTheme: AppTheme.darkTheme,
themeMode: ref.watch(themeModeProvider), ...)`. Manter todo o resto igual.

---

## 2. Primitivos reutilizáveis — `lib/ui/widgets/eximium/`

Crie estes widgets (contrato de API). Telas devem usá-los em vez de recriar estilos.

- **`ExCard`** (`ex_card.dart`): container `surface1`, `border` 1px, radius `lg`(20), `shadowCard`.
  Props: `child`, `padding` (default 16), `onTap` (se houver → no hover/press a borda vira `borderAccent`),
  `accentBorderLeft` (Color? p/ tratamento B opcional). Usa `context.ex`.
- **`ExButton`** (`ex_button.dart`): variantes `primary` (fill verde, texto `onBrandGreen`, glowSm),
  `secondary` (surface2 + border, texto primary), `ghost` (transparente, texto/borda verde), `danger`
  (texto/borda error). Props: `label`, `icon?`, `onPressed`, `variant`, `expand`, `size`. Radius pill.
- **`ExBadge`** (`ex_badge.dart`): pill com `xBg` (12% tint) + texto cor de status. `variant`:
  success/info/error/warning/neutral. UPPERCASE opcional (`emphatic`).
- **`ExGroupChip`** (`ex_chip.dart`): pill com dot colorido (6px) + label (cor do grupo). Também exporte
  `ExDot` (ponto colorido) e `ExMetaChip` (ícone + texto, cor custom) e `ExRecurrenceChip`.
- **`ExSectionLabel`** (`ex_section_label.dart`): rótulo UPPERCASE 11/700/0.08em em `textSecondary`,
  com contagem opcional.
- **`ExGlowFab`** (`ex_glow_fab.dart`): FAB quadrado arredondado (radius 20, ~58px), fill verde, ícone
  `onBrandGreen`, sombra + glowMd. Variante estendida (pill com label, ex. "Novo grupo").
- **`ExBottomNav`** (`ex_bottom_nav.dart`): barra **flutuante** (margin 16, height ~64, surface1, border,
  radius 26, shadowFloat). Item ativo = pílula `rgba(green,.14)` + ícone/label verde; inativos = textMuted.
  Mesma ordem/destinos atuais (Grupos · Início · Perfil). Recebe `currentIndex` + `onTap`.
- **`ExStatusBar`** (opcional, só se alguma tela mock exige) — **NÃO** replicar a status bar 9:41 do mockup;
  isso é chrome de protótipo. O app usa a status bar real do device.

> O mockup envolve cada tela num "frame de celular" (notch, 9:41, etc.). **Isso é só apresentação do
> protótipo. Ignore o frame.** Implemente apenas o conteúdo interno de cada tela.

---

## 3. Especificações por tela

Cada item referencia a seção correspondente no HTML. Reproduza espaçamentos, raios, cores via tokens.
Mantenha 100% da lógica existente — apenas reconstrua a árvore visual.

### A. Entrada & dia

**Login (`lib/ui/screens/login_screen.dart`)** — HTML "Autenticação".
Fundo `ExAppBackground`. Logo em tile gradiente (62px, radius 20, glow). Título display "Bem-vindo de volta",
subtítulo secondary. Campos com label UPPERCASE; input `surface2`+border 12; ícone à esquerda (verde quando
foco). Campo focado mostra borda verde + focusRing. Botão primário "Entrar" (pill verde). Divisor "OU".
Botão "Continuar com Google" (secondary, com logo Google). Rodapé "Não tem conta? **Cadastre-se**".
Preserve toda a lógica de auth/validação existente.

**Home (`lib/ui/screens/home_screen.dart` + `home_task_card_with_tags.dart`, `daily_progress_indicator.dart`,
`group_rail_card.dart`, `home_completed_tag_filter_bar.dart`, `expandable_create_task_fab.dart`)** — HTML "Início".
- Header: "Olá, {nome}" (display) + subtítulo; botão circular calendário à direita.
- Chips de navegação rápida (Agendadas · N, Calendário, Buscar) em pills `surface2`.
- Seção **Atrasadas**: cabeçalho com ícone alerta vermelho + "Atrasadas · N" + ação "Reagendar todas".
  Cards atrasados = ExCard com borda `rgba(error,.35)`, time mono em vermelho, badge "Atrasada".
- Seção **Hoje**: título h2; lista de TaskCard. Card concluído = opacity .7 + check verde + line-through.
- Divisor "Amanhã" (linha + label centralizado).
- FAB com glow (canto inf. dir.) acima da bottom nav.
- Bottom nav flutuante (`ExBottomNav`).

**Grupos (`lib/ui/screens/groups_screen.dart` + `group_rail_card.dart`)** — HTML "Grupos · listas".
- Título h1 "Grupos" + botão busca circular.
- Cards de grupo: ExCard com tile do ícone (46px, radius 14, fundo = cor do grupo @14%, ícone na cor do grupo),
  nome (h3) + "N tarefas · M concluídas", chevron. Barra de progresso fina (6px, pill) na cor do grupo.
  Grupos contínuos (lista de compras) mostram "N itens na lista" sem barra.
- FAB estendido "Novo grupo".

### B. Detalhe & criação

**Detalhe do grupo (`lib/ui/screens/group_detail_screen.dart` + `partitioned_group_task_list.dart`,
`group_activity_section.dart`, `daily_progress_indicator.dart`)** — HTML "Detalhe do grupo".
- App bar: voltar (circular), tile do ícone do grupo + nome (h2), menu (3 pontos).
- Card de progresso: anel circular (CustomPaint ou fl_chart) com % no centro (mono), "X de Y concluídas",
  "N pendentes hoje", stack de avatares + "+N".
- Section label "PENDENTES · N"; lista de TaskCard.
- Linha "Concluídas · N" colapsável (chevron).
- FAB com glow.

**Nova tarefa (`lib/ui/widgets/task_form_modal.dart`)** — HTML "Nova tarefa".
Bottom sheet `surface1`, radius topo 32, handle (40x5 pill). Header "Nova tarefa" + botão fechar circular.
Input de título grande (foco verde + focusRing). Linha de chips de ação (Descrição/Etiquetas/Responsáveis).
Section "GRUPO": seletor (tile ícone + nome + chevron). Section "LEMBRETE": linha com ícone relógio + texto +
chip "repetir". Rodapé: botão circular de microfone (ghost verde) + "Salvar tarefa" (primário). Preserve
TODOS os campos, callbacks e validações.

**Agendar lembrete (`lib/ui/widgets/task_schedule_dialog.dart`)** — HTML "Agendar lembrete".
Sheet alto. Chip-resumo verde ("Sex, 12 jun · 16:30 · Semanal"). Mini-calendário do mês (nav ← →, cabeçalho
dias SEG..DOM em label muted, dia selecionado = círculo verde com glow, dias com evento = ponto colorido).
Lista agrupada (Hora/Repetição/Localização) em container `surface2` radius 16 com divisores. Botão "Limpar
agendamento" (danger ghost). Rodapé Cancelar / Concluído.

**Recorrência (`lib/ui/screens/task_recurrence_screen.dart`)** e **Localização
(`lib/ui/screens/location_picker_screen.dart`)**: aplicar tokens/estilo DS (cards, botões, labels). Sem
mockup dedicado → seguir o estilo. Mapa mantém função; aplicar chrome DS nos controles/sheets.

**FAB expansível (`lib/ui/widgets/expandable_create_task_fab.dart`)**: usar `ExGlowFab`; ações expandidas em
pills `surface1` com glow. Mantém os destinos/ações atuais (nova tarefa, voz, etc.).

**Voz — gravação (`lib/ui/widgets/voice_task_recording_sheet.dart` + `voice_amplitude_waveform.dart`)** —
HTML "Ditado por voz". Sheet `surface1` com **borda verde pulsante** + glow (segue o tema). Handle. Pill
"● Gravando · 00:12" (vermelho). Botão circular grande verde com microfone (glow). Waveform verde animada
(use o waveform real existente, recolorido p/ verde). Texto exemplo. Rodapé Cancelar / Concluir.

**Voz — preview (`lib/ui/widgets/voice_extraction_preview_sheet.dart`)**: sheet DS, cards das tarefas
extraídas no estilo TaskCard, botões DS. Preserva lógica de confirmação.

### C. Buscar, planejar & perfil

**Buscar (`lib/ui/screens/task_search_screen.dart`)** — HTML "Buscar tarefas". Campo de busca focado (ícone
verde, borda verde, focusRing) + "Cancelar" (texto verde). Label "N resultados". Resultados = TaskCard com
**realce do termo** (fundo `rgba(green,.22)`). "BUSCAS RECENTES" como pills com ícone de histórico.

**Calendário/Agenda (`lib/ui/screens/calendar_agenda_screen.dart`)** — HTML "Calendário · agenda". App bar
"Mês AAAA". Faixa da semana (SEG..SÁB, dia selecionado = círculo verde com glow, dias com evento = ponto
colorido). Timeline vertical: coluna de horas (mono, muted) + linha vertical com nós (ponto colorido; o "agora"
= verde com glow) + ExCard com **barra lateral esquerda colorida** (3px, cor do grupo) por evento. Bottom nav.
> Usa `easy_date_timeline`/`fl_chart` se já estiver no fluxo — recolorir conforme DS, sem trocar libs.

**Perfil (`lib/ui/screens/profile_screen.dart`)** — HTML "Perfil & configurações". Título h1. Header: avatar
gradiente (inicial), nome (h2) + e-mail, botão "Nome" (editar). Cards de config (ExCard): **Aparência** com
o **toggle de tema** (liga `themeModeProvider`), Permissões de lembrete (chevron), Ditado por voz (toggle).
Botão "Sair da conta" (danger ghost). Bottom nav. Toggle visual = trilho pill verde quando ativo + glow.

### D. Sistema aplicado (referência)
HTML seção 04 define: TaskCard tem 3 tratamentos — **A: acento mínimo (dot) = recomendado/padrão**,
B: barra lateral colorida (usar na agenda/timeline), C: glyph do grupo. Acentos de grupo = só ponto/glyph/barra
fina, nunca preenchimento. Verde permanece o acento de ação.

---

## 4. Widgets utilitários e sheets restantes (estilo DS)
Aplicar tokens/estilo a: `create_group_sheet.dart`, `edit_group_sheet.dart`, `group_type_picker.dart`,
`group_tag_name_color_dialog.dart`, `notification_permission_sheet.dart`, `completed_tasks_section_header.dart`,
`completed_section_tag_filter_bar.dart`, `home_completed_tag_filter_bar.dart`, `custom_avatar.dart`,
`group_icon.dart`, `daily_progress_indicator.dart`, `task_card.dart` (tratamento A), `home_task_card_with_tags.dart`,
`group_rail_card.dart`, `task_appear_motion.dart` (ajustar curva/duração p/ 250ms se necessário).
Sem mockup → seguir o design system.

## 5. Checklist de qualidade por arquivo
- [ ] Nenhuma cor de tema hardcoded; usa `context.ex` / tokens.
- [ ] Raios/espacamentos do DS.
- [ ] Funciona em dark **e** light (testar mentalmente os dois).
- [ ] Funcionalidade idêntica (callbacks, navegação, providers intactos).
- [ ] `flutter analyze` sem novos erros.
