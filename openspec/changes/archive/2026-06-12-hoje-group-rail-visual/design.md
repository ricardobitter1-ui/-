## Context

- Cada `GroupModel` expõe `color` (hex string) e `icon` (string: `group`, `work`, `home`, `fitness_center`, `school`, etc.).
- O style guide atual menciona **Dark Surface** para “Focus Cards” pretos; o rail de grupos **não** deve reutilizar esse padrão de forma genérica — deve parecer **colorido, premium e coerente** com o fundo claro da app.
- Referência visual: `openspec/style_guide.md` (Primary Blue, Accent Indigo, Success Cyan, raios 24px, sombras suaves).

## Goals / Non-Goals

**Goals:**

- Fundo do card **dominado pela cor do grupo**, com hierarquia clara (nome, stats, barra).
- **Ícone** visível e reconhecível, estilo alinhado à iconografia **round** do Material.
- **Texto principal em branco** (e secundário em branco com opacidade controlada), com **contraste mínimo** aceitável (alvo: WCAG **AA** para texto grande ~≥3:1 onde aplicável; se impossível com hex extremo, priorizar legibilidade com blend/scrim documentado).
- Barra de progresso legível sobre o fundo (track + fill harmoniosos).
- Atualizar o **style guide** com regras explícitas para este componente.

**Non-Goals:**

- Alterar modelo Firestore, CRUD de grupos ou lista da aba Grupos (exceto se extrair widget compartilhado for desejável numa iteração futura).
- Suporte a temas dinâmicos completos (dark mode global) — apenas este componente na Hoje.

## Decisions

| Tópico | Decisão | Racional |
|--------|---------|----------|
| Base da cor | Usar o hex do grupo como **cor base**; aplicar **normalização** se luminância relativa for alta (cores “pastel”) | Texto deve permanecer **branco**; fundos claros exigem escurecimento ou overlay |
| Normalização | Calcular **luminância relativa** (sRGB); se \(L > 0.55\) (ajustável), fazer **lerp** em direção a `#2B2D42` ou preto até \(L \leq 0.45\), **ou** aplicar **gradiente** `groupColor` → `groupColor` com stop inferior escuro (scrim) | Mantém identidade da cor sem sacrificar leitura |
| Superfície extra | Opcional: **gradiente linear** leve (top-left → bottom-right) entre duas variações da mesma matiz para profundidade “premium” | Alinha com diretriz de gradientes do style guide |
| Ícone | Mapa explícito `icon` → `IconData` + fallback `Icons.groups_rounded` | Compatível com valores atuais do modal de criação |
| Círculo do ícone | Fundo `white` com **alpha ~12–18%**; ícone branco **alpha ~95%** | Contraste estável independente do matiz |
| Tipografia | Nome: **w800**, branco; subtítulo stats: branco **72%** | Hierarquia do style guide (título forte, legenda mais suave) |
| Progresso | Track: branco **~20%** alpha; Fill: **Success Cyan** `#00F5D4` ou branco quando o fundo for muito saturado (escolher uma regra única e documentar) | Destaque sem “sumir” no fundo |
| Sombra | `BoxShadow` blur 16–20, alpha baixa (4–8%), offset Y 6 | Consistente com “Soft Shadows” |

## Risks / Trade-offs

- [Hex inválido ou edge] → Mitigação: fallback para **Primary Blue** (`#0052FF`) já usado no app.
- [Cor muito saturada + fill cyan] → Mitigação: testar combinações da paleta de criação de grupo; ajustar espessura da barra ou fill branco.
- [Duplicação de `_hexToColor`] → Mitigação: centralizar em util compartilhado se já existir padrão no projeto.

## Migration Plan

- Substituir implementação visual no rail; nenhuma migração de dados.
- Revisar screenshots / smoke test na aba Hoje com **cada** cor do seletor atual de grupos.

## Open Questions

- Se no futuro o usuário puder digitar **qualquer** hex, repetir teste automatizado visual ou golden test (fora do escopo mínimo desta change).
