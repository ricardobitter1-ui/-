# Tasks: group-task-tags

## 1. Firestore e segurança

- [x] 1.1 Estender `firestore.rules` para `groups/{groupId}/tags/{tagId}`: leitura/escrita apenas se `isGroupMember(groupId)`; validar shape (`name` string com limite, `color` int).
- [x] 1.2 Estender validação de `tasks` em create/update: se `groupId` ausente ou null, `tagIds` ausente ou lista vazia; se `groupId` presente, `tagIds` opcional com tamanho ≤ 10 e cada id existente em `groups/{groupId}/tags/{id}` (funções auxiliares sem loops dinâmicos, padrão similar a `assigneesSubsetMembers`).
- [x] 1.3 Documentar deploy das rules em `firebase/README.md` se necessário; adicionar índices em `firestore.indexes.json` apenas se novas queries o exigirem.

## 2. Modelo e serviço Dart

- [x] 2.1 Criar `TagModel` (ou equivalente) com `id`, `groupId`, `name`, `color` (`int`), `fromMap`/`toMap`.
- [x] 2.2 Adicionar `List<String> tagIds` a `TaskModel`, `copyWith`, `toMap` e parsing a partir de Firestore (default `[]` se campo ausente).
- [x] 2.3 Implementar em `FirebaseService` (ou serviço dedicado): `streamGroupTags(groupId)`, `addGroupTag`, `updateGroupTag`, `deleteGroupTag`; em `deleteGroupTag`, remover o id das tarefas do grupo que o referenciam (batch em chunks de 500) conforme `design.md`.
- [x] 2.4 Garantir `addTask`/`updateTask` persistem `tagIds` e que streams de tarefas do grupo entreguem o novo campo.

## 3. UI — formulário de tarefa (grupo)

- [x] 3.1 Em `TaskFormModal`, quando `forcedGroupId`/`collaborationGroup` indicar tarefa de grupo, exibir seletor multi-tag (chips) ligado a `tagIds`.
- [x] 3.2 Permitir criar tag nova (nome + cor) inline e atualizar lista local/stream.
- [x] 3.3 Implementar secção colapsável ou passo “Sugestões de outros grupos”: carregar tags dos outros grupos do utilizador e, ao escolher, chamar `addGroupTag` no grupo atual com cópia de nome/cor (spec `group-tag-suggestions`).

## 4. UI — detalhe do grupo

- [x] 4.1 Em `group_detail_screen.dart` (ou widget extraído), para tarefas **pendentes**, agrupar por tag resolvida: secções ordenadas alfabeticamente por nome da tag; secção **Sem tag** por último.
- [x] 4.2 Para tarefas com múltiplas tags, duplicar a linha da tarefa em cada secção correspondente (ou componente reutilizável que preserve o mesmo `TaskModel`).
- [x] 4.3 Garantir que ids de tag órfãos não geram secção fantasma; tarefa cai em **Sem tag** se nenhum id resolver.
- [x] 4.4 Manter comportamento aceitável para tarefas concluídas (sem exigir novo agrupamento por tag nesta change, conforme spec).

## 5. Providers e polimento

- [x] 5.1 Adicionar `Provider`/Riverpod para tags do grupo atual se simplificar o modal e o detalhe (opcional mas recomendado).
- [x] 5.2 `flutter analyze` sem novos erros; testar criar/editar tarefa, criar tag, sugestão, delete de tag com tarefas associadas.

## 6. Roadmap

- [x] 6.1 Após implementação validada, atualizar `openspec/roadmap.md` (Fase 5) com itens entregues e arquivar a change quando aplicável.
