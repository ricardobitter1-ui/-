# Proposal: Tags por grupo e agrupamento de tarefas (Fase 5 do roadmap)

## Why

Tarefas em grupos (ex.: lista de compras) ficam difíceis de escanear sem categorias. O roadmap **Fase 5** define tags **por grupo**, opcionais, com cor, múltiplas por tarefa e reuso de **rótulo** entre grupos (nova entidade no grupo atual). Sem isso, o detalhe do grupo continua como uma lista plana e não aproveita o modelo mental do utilizador (corredores, temas, etc.).

## What Changes

- **Dados:** Novo documento (ou subcoleção) de **tag** escopado a `groupId` — campos mínimos: identificador, **nome** (rótulo), **cor** (livre, ex. ARGB/int ou string normalizada).
- **Dados:** Tarefas com `groupId` passam a suportar **lista opcional de ids de tag** (`tagIds`); tarefas sem grupo ou lista vazia = sem tags (comportamento atual preservado onde aplicável).
- **Segurança:** `firestore.rules` — membros do grupo podem ler tags do grupo; **qualquer membro** pode criar tag; atualizar/apagar tag conforme regra definida na spec (ex.: criador ou qualquer membro — a fechar na spec).
- **Cliente:** `TaskModel` + `FirebaseService` (map, streams, writes) com `tagIds`; CRUD ou operações mínimas de tags por grupo.
- **UI — formulário de tarefa:** Seletor multi-tag para tarefas de grupo (opcional); criar tag nova no grupo; secção **sugestões** com rótulos (e opcionalmente cor) de **outros grupos em que o utilizador é membro** — ao escolher, **cria nova tag no grupo atual** (mesmo nome, novo id), sem referência cruzada.
- **UI — detalhe do grupo:** Lista de tarefas **agrupada** por tag: secções por tag (ordem definida na spec, ex. alfabética), mais secção **Sem tag** para tarefas sem `tagIds`; tarefa com **várias tags** aparece **em cada** secção correspondente (duplicação visual aceite para clareza).
- **Fora de escopo desta change:** Fase 6 do roadmap (secção global só de concluídas, animações de conclusão) — pode interagir depois com a mesma lista, mas não é requisito desta proposta.

## Capabilities

### New Capabilities

- `group-tags`: Modelo e regras de **tags por grupo** (criação por membro, cor, leitura, operações de escrita); **não** existe tag global partilhada entre grupos.
- `group-task-tag-assignment`: **Atribuição opcional** de **múltiplas** tags a tarefas de grupo; validação de que cada `tagId` pertence ao mesmo `groupId` da tarefa; persistência e leitura no cliente.
- `group-tag-suggestions`: Fluxo de **sugestões** a partir de tags de outros grupos do utilizador; **modelo A** — ao aplicar, instancia nova tag no grupo atual.
- `group-detail-task-list-by-tag`: **Agrupamento visual** da lista de tarefas no detalhe do grupo (por tag + “Sem tag”; tarefa multi-tag em várias secções).

### Modified Capabilities

- (Nenhuma spec formal em `openspec/specs/` além de `app_navigation.md`; requisitos novos vivem nas specs desta change.)

## Impact

- `firestore.rules` — novos paths para tags; validação em `tasks` para `tagIds` coerentes com `groupId`.
- `lib/data/models/task_model.dart`, `firebase_service.dart`, possivelmente `group_model.dart` (se índice ou cache).
- `lib/ui/widgets/task_form_modal.dart`, `lib/ui/screens/group_detail_screen.dart` (e widgets auxiliares).
- Índices Firestore compostos se novas queries o exigirem.
- `openspec/roadmap.md` — marcar entregas da Fase 5 quando a change for concluída/arquivada.
